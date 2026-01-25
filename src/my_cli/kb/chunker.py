from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
import hashlib  # 生成稳定的 chunk_id
import re  # 解析 Markdown 标题
from typing import Iterable, List, Tuple

# 这个模块用于 将 Markdown 文档分块（chunking），是 RAG（检索增强生成）系统的核心组件
# 使用场景
# 在 RAG 系统中：
# 索引阶段：将文档分块 → 生成向量 → 存入 FAISS
# 检索阶段：根据 chunk_id 找到相关文档片段 → 提供给 LLM 作为上下文
# 这样可以避免一次性加载整个文档，提高检索效率。


# 存储文档片段的结构
@dataclass
class Chunk:
    # chunk_id: 基于路径/标题/内容片段生成的稳定标识
    chunk_id: str
    # source_path: 原始文件路径（用于追溯来源）
    source_path: str
    # heading: 命中的标题的层次路径
    heading: str
    # content: 对应标题下的正文内容
    content: str
    # namespace: 可选的命名空间，用于区分不同知识域
    namespace: str


# 匹配 Markdown 标题（# ~ ######）
_HEADING_RE = re.compile(r"^(#{1,6})\s+(.+)$", re.MULTILINE)


def _hash_id(text: str) -> str:
    # 使用 SHA1 生成短哈希，作为 chunk_id
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]


def _make_heading_path(stack: List[Tuple[int, str]]) -> str:
    # stack: [(level, title), ...]
    return " > ".join(title for _, title in stack) if stack else "Document"


def _infer_namespace(raw_root: Path, file_path: Path) -> str:
    rel = file_path.relative_to(raw_root)
    if len(rel.parts) >= 2:
        return rel.parts[0]
    return "default"


# 将单个 Markdown 文件按标题分块
def chunk_markdown_file(
    path: Path, namespace: str, max_chars: int = 1200
) -> List[Chunk]:
    raw = path.read_text(encoding="utf-8", errors="ignore").strip()
    if not raw:
        return []

    matches = list(_HEADING_RE.finditer(raw))
    chunks: List[Chunk] = []

    # 如果没有任何标题：整个文档当成一个 section
    if not matches:
        heading_path = "Document"
        body = raw
        parts = (
            [body]
            if len(body) <= max_chars
            else [body[i : i + max_chars] for i in range(0, len(body), max_chars)]
        )
        for part in parts:
            base = f"{path.as_posix()}::{heading_path}::{part[:200]}"
            cid = _hash_id(base)
            chunks.append(
                Chunk(
                    chunk_id=cid,
                    source_path=str(path.as_posix()),
                    heading=heading_path,
                    content=part.strip(),
                    namespace=namespace,
                )
            )
        return chunks

    # 维护标题层次栈：遇到新标题就按 level 出栈/入栈
    heading_stack: List[Tuple[int, str]] = []

    for i, m in enumerate(matches):
        level = len(m.group(1))  # '#' 数量
        title = m.group(2).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(raw)
        body = raw[start:end].strip()

        # 更新栈：同级或更深的旧标题需要弹出
        while heading_stack and heading_stack[-1][0] >= level:
            heading_stack.pop()
        heading_stack.append((level, title))

        if not body:
            continue

        heading_path = _make_heading_path(heading_stack)

        # 超长再硬切
        parts = (
            [body]
            if len(body) <= max_chars
            else [body[j : j + max_chars] for j in range(0, len(body), max_chars)]
        )
        for part in parts:
            base = f"{path.as_posix()}::{heading_path}::{part[:200]}"
            cid = _hash_id(base)
            chunks.append(
                Chunk(
                    chunk_id=cid,
                    source_path=str(path.as_posix()),
                    heading=heading_path,
                    content=part.strip(),
                    namespace=namespace,
                )
            )

    return chunks


# 递归扫描目录，收集所有文档的 chunks
# 返回所有 .md 和 .txt 文件的 chunk 列表
def collect_chunks(root: Path, exts: Iterable[str] = (".md", ".txt")) -> List[Chunk]:
    # 递归收集指定后缀的文档，并汇总所有 chunk
    all_chunks: List[Chunk] = []
    for p in root.rglob("*"):
        if p.is_file() and p.suffix.lower() in exts:
            ns = _infer_namespace(root, p)
            all_chunks.extend(chunk_markdown_file(p, namespace=ns))
    return all_chunks
