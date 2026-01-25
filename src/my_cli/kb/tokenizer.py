from __future__ import annotations
import re
from typing import List
import jieba

# 智能分词器，用于 BM25 关键词检索
# BM25 算法需要计算词频等信息来评估相关性
# 英文天然有空格分隔，但中文是连续字符
# 这个分词器统一处理中英文,让 BM25 能正确工作

# 检测文本中是否包含中文字符
_CJK_RE = re.compile(r"[\u4e00-\u9fff]")


def contains_cjk(text: str) -> bool:
    return bool(_CJK_RE.search(text))


# 根据语言自动选择分词策略
def tokenize(text: str) -> List[str]:
    text = (text or "").strip()
    if not text:
        return []

    # 中文：jieba 分词
    if contains_cjk(text):
        return [t.strip() for t in jieba.lcut(text) if t.strip()]

    # 英文：按单词抽取（兼容 snake_case）
    text = text.lower()
    return re.findall(r"[a-z0-9_]+", text)
