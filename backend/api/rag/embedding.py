import os
from typing import List
import numpy as np
from .config import Config

class EmbeddingService:
    def __init__(self, api_key: str = None):
        self.api_key = api_key or Config.UPSTAGE_API_KEY
        if not self.api_key:
            raise ValueError("Upstage API key is required")
    
    def get_embedding(self, text: str) -> List[float]:
        # Upstage API를 사용하여 텍스트 임베딩 생성
        # 실제 구현은 Upstage API 호출 로직으로 대체
        pass
    
    def get_embeddings(self, texts: List[str]) -> List[List[float]]:
        # 여러 텍스트의 임베딩을 한 번에 생성
        return [self.get_embedding(text) for text in texts] 