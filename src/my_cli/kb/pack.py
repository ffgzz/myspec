from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from .paths import KBPaths, ensure_dirs
from .chunker import Chunk
from .embedder import Embedder
from .index import load_index, load_chunks_jsonl
from .bm25 import load_bm25_corpus, bm25_search

# pack.py - 知识包生成模块
# 核心功能: 混合检索(FAISS向量 + BM25关键词) → RRF融合排名  → 生成知识包
# 输出文件:
#   1. knowledge-pack.md  - 供 /specify 命令使用的检索证据
#   2. trace.json         - 检索过程的元数据追踪


# 检索命中结果的数据类
# 用于存储混合检索后每个文档的详细信息
@dataclass
class RetrievalHit:
    fused_score: float  # RRF 融合后的最终得分
    chunk: Chunk  # 文档块对象(包含内容、来源等)
    vec_rank: Optional[int] = None  # 在向量检索中的排名(1表示第一名,None表示未出现)
    bm25_rank: Optional[int] = None  # 在BM25检索中的排名(1表示第一名,None表示未出现)


# RRF 排名融合算法
# 作用: 把向量检索和 BM25 检索的结果合并成一个统一的排名
#
# 原理: 对每个文档,根据它在各个检索结果中的排名计算得分
#   score = Σ 1 / (k + rank)
#   其中 k=60 是平滑参数,防止第一名得分过高
#
# 示例:
#   向量检索: [doc1, doc2, doc3]  → doc1排名1, doc2排名2
#   BM25检索: [doc2, doc1, doc4]  → doc2排名1, doc1排名2
#
#   RRF得分:
#   doc1: 1/(60+1) + 1/(60+2) = 0.0164 + 0.0161 = 0.0325
#   doc2: 1/(60+2) + 1/(60+1) = 0.0161 + 0.0164 = 0.0325
#   doc3: 1/(60+3) = 0.0159
#   doc4: 1/(60+3) = 0.0159
#
# 返回: [(chunk_id, 融合得分), ...] 按得分降序排列
def _rrf_fuse(
    vec_ids: List[str], bm25_ids: List[str], k: int = 60
) -> List[Tuple[str, float]]:
    """
    Reciprocal Rank Fusion:
    score = Σ 1 / (k + rank)
    """
    scores: Dict[str, float] = {}

    # 累加向量检索的排名得分
    for rank, cid in enumerate(vec_ids, start=1):
        scores[cid] = scores.get(cid, 0.0) + 1.0 / (k + rank)

    # 累加 BM25 检索的排名得分
    for rank, cid in enumerate(bm25_ids, start=1):
        scores[cid] = scores.get(cid, 0.0) + 1.0 / (k + rank)

    # 按融合得分降序排列
    fused = list(scores.items())
    fused.sort(key=lambda x: x[1], reverse=True)
    return fused


# 混合检索核心函数
# 作用: 同时使用向量检索和 BM25 检索,然后用 RRF 算法融合结果
#
# 工作流程:
#   1. 加载所有文档块
#   2. 向量检索: 查询文本 → 向量化 → FAISS检索 → 过滤命名空间 → 记录排名
#   3. BM25检索: 查询文本 → 分词 → BM25检索 → 过滤命名空间 → 记录排名
#   4. RRF融合: 合并两个排名列表 → 按融合得分排序 → 取 topk
#
# 返回: RetrievalHit 列表,包含融合得分、原始排名、文档内容等
def retrieve(
    query: str,
    embedder: Embedder,
    index_path: Path,
    chunks_path: Path,
    bm25_corpus_path: Path,
    topk: int = 8,
    namespaces: Optional[List[str]] = None,
    vec_candidates: int = 30,
    bm25_candidates: int = 30,
) -> List[RetrievalHit]:
    """
    Hybrid retrieve = Vector + BM25 -> RRF fuse -> TopK

    namespaces:
      - None: 不过滤(全库)
      - ["domain", "project"]: 只保留对应 namespace
    """
    # 加载所有文档块
    chunks = load_chunks_jsonl(chunks_path)
    if not chunks:
        return []

    allowed_ns = set(namespaces) if namespaces else None

    # 构建 chunk_id -> chunk 的映射,方便后续快速查找
    id2chunk: Dict[str, Chunk] = {c.chunk_id: c for c in chunks}

    # 命名空间过滤函数
    def ns_allowed(c: Chunk) -> bool:
        return True if allowed_ns is None else (c.namespace in allowed_ns)

    # ========== 第一步: 向量检索 ==========
    vec_rank_map: Dict[str, int] = {}  # chunk_id -> 排名(1,2,3...)
    vec_id_list: List[str] = []  # 按排名顺序的 chunk_id 列表

    if index_path.exists():
        # 加载 FAISS 索引
        index = load_index(index_path)
        # 查询文本向量化(注意 E5 模型需要 "query: " 前缀)
        qvec = embedder.encode([f"query: {query}"])
        # 多取一些候选,因为命名空间过滤后可能不够
        fetch_k = min(len(chunks), max(vec_candidates, topk * 5))
        # FAISS检索: scores是相似度得分,ids是文档索引
        scores, ids = index.search(qvec, fetch_k)

        rank = 0  # 当前有效排名(过滤后的)
        for idx in ids[0].tolist():
            # 检查索引有效性
            if idx < 0 or idx >= len(chunks):
                continue
            c = chunks[idx]
            # 命名空间过滤
            if not ns_allowed(c):
                continue
            cid = c.chunk_id
            if cid in vec_rank_map:
                continue
            # 记录排名
            rank += 1
            vec_rank_map[cid] = rank
            vec_id_list.append(cid)
            # 达到候选数量就停止
            if rank >= vec_candidates:
                break

    # ========== 第二步: BM25检索 ==========
    bm25_rank_map: Dict[str, int] = {}
    bm25_id_list: List[str] = []

    # 加载 BM25 语料库(分词后的文档集合)
    corpus_tokens, _, _ = load_bm25_corpus(bm25_corpus_path)
    if corpus_tokens:
        # BM25 检索
        bm25_results = bm25_search(
            query, corpus_tokens, topk=max(bm25_candidates, topk * 5)
        )
        rank = 0
        for (
            idx,
            _score,
        ) in bm25_results:  # idx是文档索引，_score 是 BM25 得分(融合时不直接用)
            # 检查索引有效性
            if idx < 0 or idx >= len(chunks):
                continue
            c = chunks[idx]
            # 命名空间过滤
            if not ns_allowed(c):
                continue
            cid = c.chunk_id
            # 去重
            if cid in bm25_rank_map:
                continue
            # 记录排名
            rank += 1
            bm25_rank_map[cid] = rank
            bm25_id_list.append(cid)
            # 达到候选数量就停止
            if rank >= bm25_candidates:
                break

    # ========== 第三步: RRF融合 ==========
    # 输入: 向量排名列表 + BM25排名列表
    # 输出: [(chunk_id, 融合得分), ...] 按得分降序
    fused = _rrf_fuse(vec_id_list, bm25_id_list, k=60)

    # ========== 第四步: 构建最终结果 ==========
    hits: List[RetrievalHit] = []
    for cid, fused_score in fused[:topk]:  # 只取 topk 个
        c = id2chunk.get(cid)
        if not c:
            continue
        hits.append(
            RetrievalHit(
                fused_score=float(fused_score),  # RRF融合得分
                chunk=c,  # 文档块对象
                vec_rank=vec_rank_map.get(cid),  # 在向量检索中的排名
                bm25_rank=bm25_rank_map.get(cid),  # 在 BM25 检索中的排名
            )
        )

    return hits


def render_knowledge_pack(query: str, hits: List[RetrievalHit]) -> str:
    lines: List[str] = []
    lines.append("# Knowledge Pack (auto-generated)")
    lines.append("")
    lines.append(f"**Query**: {query}")
    lines.append("")

    lines.append("## Top Evidence (for Spec)")
    lines.append("")

    if not hits:
        lines.append(
            "> 未检索到相关证据。请仅基于用户输入生成规范，并把证据摘要写为“知识库未检索到相关证据”。"
        )
        return "\n".join(lines).strip() + "\n"

    for i, h in enumerate(hits, start=1):
        c = h.chunk
        lines.append(
            f"### [E{i}] {c.heading}  (hybrid={h.fused_score:.6f} | vec_rank={h.vec_rank} | bm25_rank={h.bm25_rank})"
        )
        lines.append(f"Namespace: `{c.namespace}`")
        lines.append(f"Source: `{c.source_path}`")
        lines.append(f"Chunk ID: `{c.chunk_id}`")
        lines.append("")
        lines.append(c.content.strip())
        lines.append("")

    # 直接给一个可复制的 Evidence Trace 模板
    lines.append("## Evidence Trace Template（可直接复制到 spec 末尾）")
    for i, h in enumerate(hits, start=1):
        c = h.chunk
        lines.append(f"- [E{i}] {c.heading} — {c.source_path}")
    lines.append("")

    return "\n".join(lines).strip() + "\n"


# 写入知识包和追踪文件
# 作用: 把检索结果保存到两个文件:
#   1. knowledge-pack.md  - Markdown 格式的检索证据(供 AI 阅读)
#   2. trace.json         - JSON 格式的元数据(供程序分析和调试)
#
# 工作流程:
#   1. 确保目录存在(.myspec/context/)
#   2. 调用 render_knowledge_pack() 生成 Markdown 内容
#   3. 写入 knowledge-pack.md
#   4. 构建 trace.json 的数据结构（包含查询、得分、排名等）并写入文件
#
# 参数:
#   paths: KBPaths 对象（包含各种文件路径）
#   query: 用户查询字符串
#   hits: 检索命中列表
def write_pack_and_trace(paths: KBPaths, query: str, hits: List[RetrievalHit]) -> None:
    # 确保输出目录存在
    ensure_dirs(paths)

    # 生成并写入 knowledge-pack.md
    pack_md = render_knowledge_pack(query, hits)
    paths.knowledge_pack_md.write_text(pack_md, encoding="utf-8")

    # 构建 trace.json 数据结构
    # 记录检索过程的详细信息，用于调试和分析
    trace: Dict[str, Any] = {
        "query": query,  # 用户查询
        "topk": len(hits),  # 返回的文档数量
        "hits": [
            {
                "evidence": f"E{i + 1}",  # 证据编号 E1, E2, ...
                "fused_score": h.fused_score,  # RRF 融合得分
                "vec_rank": h.vec_rank,  # 向量检索排名
                "bm25_rank": h.bm25_rank,  # BM25 检索排名
                "chunk_id": h.chunk.chunk_id,  # 文档块唯一 ID
                "heading": h.chunk.heading,  # 文档标题
                "namespace": h.chunk.namespace,  # 命名空间
                "source_path": h.chunk.source_path,  # 原始文件路径
            }
            for i, h in enumerate(hits)
        ],
    }

    paths.trace_json.write_text(
        json.dumps(trace, ensure_ascii=False, indent=2), encoding="utf-8"
    )
