from __future__ import annotations
import json
from dataclasses import asdict
from pathlib import Path
from typing import Dict, List

import numpy as np
import faiss

from .chunker import Chunk

# 负责保存/加载文本分块数据，以及构建、保存、加载 FAISS 向量索引


# 把 Chunk 列表写成 jsonl（一行就是一个完整的 JSON 对象（或数组），行与行之间用换行符分隔）
# 这样可以很方便地按行读取、逐条还原
def save_chunks_jsonl(chunks: List[Chunk], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        for c in chunks:
            f.write(json.dumps(asdict(c), ensure_ascii=False) + "\n")


# 读取 jsonl 文件，每一行 JSON 转回 Chunk 对象
def load_chunks_jsonl(path: Path) -> List[Chunk]:
    chunks: List[Chunk] = []
    if not path.exists():
        return chunks
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            obj = json.loads(line)
            if "namespace" not in obj:
                obj["namespace"] = "default"
            chunks.append(Chunk(**obj))
    return chunks


# 用向量 vectors 创建 FAISS 索引，这里使用 IndexFlatIP（内积检索）要求输入向量是归一化过的（这样内积≈余弦相似度）
def build_faiss_index(vectors: np.ndarray) -> faiss.Index:
    """
    vectors: (N, dim), 已 normalize，适合 IndexFlatIP
    """
    if vectors.ndim != 2:
        raise ValueError("vectors must be 2D array")
    dim = vectors.shape[1]
    # 不做压缩/聚类，保存全部向量，用内积做精确相似度检索，适合小规模知识库
    index = faiss.IndexFlatIP(dim)
    index.add(vectors)
    return index


# 先尝试 faiss.write_index() 直接写文件
# 如果失败（Windows 中文路径常见问题），就改用 faiss.serialize_index() 得到字节，再手动写入文件
def save_index(index: faiss.Index, index_path: Path) -> None:
    index_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        faiss.write_index(index, str(index_path))
    except Exception:
        data = faiss.serialize_index(index)
        with index_path.open("wb") as f:
            f.write(data)


# 先尝试 faiss.read_index() 读取，失败时读取字节并用 faiss.deserialize_index() 还原
# 这里用 np.frombuffer(..., dtype="uint8")
# 是为了满足 FAISS 反序列化对输入类型的要求
def load_index(index_path: Path) -> faiss.Index:
    try:
        return faiss.read_index(str(index_path))
    except Exception:
        data = index_path.read_bytes()
        return faiss.deserialize_index(np.frombuffer(data, dtype="uint8"))


# 保存索引的元信息（如模型名、chunk 数量）以 JSON 文件形式写入
def save_index_meta(meta: Dict, meta_path: Path) -> None:
    meta_path.parent.mkdir(parents=True, exist_ok=True)
    meta_path.write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )


# 读取索引元信息
def load_index_meta(meta_path: Path) -> Dict:
    if not meta_path.exists():
        return {}
    return json.loads(meta_path.read_text(encoding="utf-8"))
