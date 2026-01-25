from __future__ import annotations
from dataclasses import dataclass
from typing import List
import numpy as np

# 本地 embedding（sentence-transformers）
from sentence_transformers import SentenceTransformer

# 这个文件负责把文本转成向量（embedding），给 FAISS 检索用


@dataclass
class Embedder:
    # 使用的模型名称
    model_name: str = "intfloat/multilingual-e5-small"

    # 对象创建后自动加载模型
    def __post_init__(self) -> None:
        # 加载 SentenceTransformer 文本向量模型
        self.model = SentenceTransformer(self.model_name)

    # 批量把文本转成向量
    def encode(self, texts: List[str]) -> np.ndarray:
        # 归一化后用内积检索≈余弦相似度，效果更稳定
        vecs = self.model.encode(
            texts,
            batch_size=32,
            show_progress_bar=False,
            normalize_embeddings=True,
        )
        # 确保返回 float32 类型，FAISS 要求
        return np.asarray(vecs, dtype="float32")
