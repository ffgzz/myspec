from __future__ import annotations
from pathlib import Path
from typing import Optional
import typer
from rich.console import Console
from rich.table import Table

from .paths import KBPaths, ensure_dirs
from .chunker import collect_chunks
from .embedder import Embedder
from .index import (
    save_chunks_jsonl,
    build_faiss_index,
    save_index,
    save_index_meta,
)
from .pack import retrieve, write_pack_and_trace
from .bm25 import build_bm25_corpus, save_bm25_corpus
# 命令行入口：构建向量索引、查询相似内容、生成知识包文件

console = Console()
kb_app = typer.Typer(help="Knowledge Base (RAG) commands", add_completion=False)


# 构建索引：把 raw 里的文档切块、向量化、写入 FAISS 索引
@kb_app.command("build")
def kb_build(
    root: Optional[Path] = typer.Option(
        None, "--root", help="Project root, default is current directory"
    ),
    model: str = typer.Option(
        "intfloat/multilingual-e5-small", "--model", help="Embedding model name"
    ),
):
    """
    把 raw 目录中的 *.md 和 *.txt 文件构建本地 FAISS 索引
    """
    project_root = root or Path.cwd()
    paths = KBPaths(project_root)
    ensure_dirs(paths)

    # if not paths.myspec_dir.exists():
    #     raise typer.BadParameter(
    #         "No .myspec directory found. Run `myspec init` in this project first."
    #     )

    console.print(f"[bold]Indexing knowledge from:[/bold] {paths.kb_raw}")
    chunks = collect_chunks(paths.kb_raw)

    if not chunks:
        console.print(
            "[yellow]No documents found in .myspec/kb/raw. Add some .md/.txt first.[/yellow]"
        )
        raise typer.Exit(code=1)

    # 向量化文本并构建索引
    embedder = Embedder(model_name=model)
    vectors = embedder.encode([f"passage: {c.content}" for c in chunks])

    index = build_faiss_index(vectors)
    save_index(index, paths.index_faiss)
    save_chunks_jsonl(chunks, paths.chunks_jsonl)

    # 保存索引元信息
    meta = {
        "model": model,
        "num_chunks": len(chunks),
        "kb_raw": str(paths.kb_raw.as_posix()),
    }
    save_index_meta(meta, paths.index_meta)

    bm25_corpus = build_bm25_corpus(chunks)
    save_bm25_corpus(bm25_corpus, chunks, paths.bm25_corpus_jsonl)

    console.print(f"[green]OK[/green] Built index with {len(chunks)} chunks.")
    console.print(f"- {paths.index_faiss}")
    console.print(f"- {paths.chunks_jsonl}")
    console.print(f"- {paths.index_meta}")
    console.print(f"- {paths.bm25_corpus_jsonl}")


# 输入一段查询语句，输出最相似的文本块列表。主要用于调试检索效果。
@kb_app.command("query")
def kb_query(
    query: str = typer.Argument(..., help="Feature request or requirement text"),
    topk: int = typer.Option(6, "--topk", help="Top K evidence chunks"),
    namespaces: str = typer.Option(
        "",
        "--namespaces",
        help="Comma-separated namespaces to search, e.g. domain,project. Empty means all.",
    ),
    root: Optional[Path] = typer.Option(
        None, "--root", help="Project root, default is current directory"
    ),
):
    project_root = root or Path.cwd()
    paths = KBPaths(project_root)

    embedder = Embedder()

    ns_list = None
    if namespaces.strip():
        ns_list = [x.strip() for x in namespaces.split(",") if x.strip()]

    hits = retrieve(
        query=query,
        embedder=embedder,
        index_path=paths.index_faiss,
        chunks_path=paths.chunks_jsonl,
        bm25_corpus_path=paths.bm25_corpus_jsonl,
        topk=topk,
        namespaces=ns_list,
    )

    table = Table(title="KB Query Results")
    table.add_column("#", style="cyan", width=4)
    table.add_column("Score", style="magenta", width=10)
    table.add_column("Heading", style="white")
    table.add_column("Source", style="dim")

    for i, h in enumerate(hits, start=1):
        table.add_row(
            str(i), f"{h.fused_score:.4f}", h.chunk.heading, h.chunk.source_path
        )

    console.print(table)


# 生成知识包文件：根据查询从知识库检索相关内容，生成 knowledge-pack.md 和 trace.json
@kb_app.command("pack")
@kb_app.command("pack")
def kb_pack(
    query: str = typer.Argument(..., help="Feature request or requirement text"),
    topk: int = typer.Option(6, "--topk", help="Top K evidence chunks"),
    namespaces: str = typer.Option(
        "",
        "--namespaces",
        help="Comma-separated namespaces to search, e.g. domain,project. Empty means all.",
    ),
    root: Optional[Path] = typer.Option(
        None, "--root", help="Project root, default is current directory"
    ),
):
    """
    生成 .myspec/context/knowledge-pack.md 和 trace.json 给 Claude Code 的/specify 使用。
    """
    project_root = root or Path.cwd()
    paths = KBPaths(project_root)
    ensure_dirs(paths)

    if not paths.index_faiss.exists() or not paths.chunks_jsonl.exists():
        console.print(
            "[yellow]Index not found. Running `myspec kb build` first...[/yellow]"
        )
        kb_build(root=project_root)

    embedder = Embedder()

    ns_list = None
    if namespaces.strip():
        ns_list = [x.strip() for x in namespaces.split(",") if x.strip()]

    hits = retrieve(
        query=query,
        embedder=embedder,
        index_path=paths.index_faiss,
        chunks_path=paths.chunks_jsonl,
        bm25_corpus_path=paths.bm25_corpus_jsonl,
        topk=topk,
        namespaces=ns_list,
    )

    write_pack_and_trace(paths, query=query, hits=hits)

    console.print("[green]OK[/green] Knowledge pack generated:")
    console.print(f"- {paths.knowledge_pack_md}")
    console.print(f"- {paths.trace_json}")
