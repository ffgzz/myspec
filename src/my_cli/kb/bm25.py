from __future__ import annotations
import json
from pathlib import Path
from typing import List, Tuple

from rank_bm25 import BM25Okapi

from .chunker import Chunk
from .tokenizer import tokenize

#  BM25 关键词检索


# 构建 BM25 语料库
# 把每个 chunk 的内容用 tokenize() 分词，返回分词后的二维列表


def build_bm25_corpus(chunks: List[Chunk]) -> List[List[str]]:
    # 与 chunks 顺序严格对齐，保证 idx 可映射到同一 chunk
    return [tokenize(c.content) for c in chunks]


# 保存为 JSONL 格式，用于持久化,避免每次重建索引
def save_bm25_corpus(
    corpus: List[List[str]], chunks: List[Chunk], out_path: Path
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        for tokens, chunk in zip(corpus, chunks):
            f.write(
                json.dumps(
                    {
                        "chunk_id": chunk.chunk_id,
                        "namespace": chunk.namespace,
                        "tokens": tokens,
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )


# 从 JSONL 文件读取。返回三个对齐的列表: (corpus_tokens, chunk_ids, namespaces)
def load_bm25_corpus(path: Path) -> Tuple[List[List[str]], List[str], List[str]]:
    """
    return: (corpus_tokens, chunk_ids, namespaces) 都按行对齐
    """
    corpus: List[List[str]] = []
    chunk_ids: List[str] = []
    namespaces: List[str] = []
    if not path.exists():
        return corpus, chunk_ids, namespaces

    with path.open("r", encoding="utf-8") as f:
        for line in f:
            obj = json.loads(line)
            corpus.append(obj.get("tokens", []))
            chunk_ids.append(obj.get("chunk_id", ""))
            namespaces.append(obj.get("namespace", "default"))
    return corpus, chunk_ids, namespaces


# 对查询词分词 → 使用 BM25Okapi 计算得分，返回 topk 个最相关的文档索引和分数
def bm25_search(
    query: str,
    corpus_tokens: List[List[str]],
    topk: int = 20,
) -> List[Tuple[int, float]]:
    """
    返回: [(chunk_index, score), ...] 其中 chunk_index 对应 chunks 的下标
    """
    q_tokens = tokenize(query)
    if not q_tokens:
        return []

    bm25 = BM25Okapi(corpus_tokens)
    scores = bm25.get_scores(q_tokens)

    scored = list(enumerate(scores))
    scored.sort(key=lambda x: x[1], reverse=True)
    return [(idx, float(score)) for idx, score in scored[:topk]]
