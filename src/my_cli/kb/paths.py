from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path


# 这个文件定义了 知识库（KB）相关的路径配置。
@dataclass(frozen=True)
class KBPaths:
    project_root: Path

    # 该装饰器作用是把方法变成“只读属性”，调用时不用加括号
    @property
    def myspec_dir(self) -> Path:
        return self.project_root / ".myspec"

    @property
    def kb_root(self) -> Path:
        return self.myspec_dir / "kb"  # 知识库目录

    @property
    def kb_raw(self) -> Path:
        return self.kb_root / "raw"  # 原始文档存放目录

    @property
    def chunks_jsonl(self) -> Path:
        return self.kb_root / "chunks.jsonl"  # 文档分块数据

    @property
    def index_faiss(self) -> Path:
        return self.kb_root / "index.faiss"  # FAISS 向量索引

    @property
    def index_meta(self) -> Path:
        return self.kb_root / "index_meta.json"  # 索引元数据

    @property
    def context_dir(self) -> Path:
        return self.myspec_dir / "context"  # 上下文输出目录

    @property
    def knowledge_pack_md(self) -> Path:
        return self.context_dir / "knowledge-pack.md"  # 生成的知识包文档

    @property
    def trace_json(self) -> Path:
        return self.context_dir / "trace.json"  # 追踪/调试信息

    @property
    def bm25_corpus_jsonl(self) -> Path:
        return self.kb_root / "bm25_corpus.jsonl"

    @property
    def bm25_meta(self) -> Path:
        return self.kb_root / "bm25_meta.json"


# 确保 kb/raw/ 和 context/ 目录存在
def ensure_dirs(paths: KBPaths) -> None:
    paths.kb_raw.mkdir(parents=True, exist_ok=True)
    paths.context_dir.mkdir(parents=True, exist_ok=True)
