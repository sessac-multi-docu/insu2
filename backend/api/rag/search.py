from typing import List, Dict, Any
import numpy as np
from .config import Config
from .collection_loader import CollectionLoader
from .embedding import EmbeddingService
from .document import Document
from .schema import SearchQuery

class SearchService:
    def __init__(self):
        self.collection_loader = CollectionLoader()
        self.embedding_service = EmbeddingService()
    
    def search(self, query: SearchQuery) -> Dict[str, Any]:
        try:
            # 컬렉션 로드
            if query.collections:
                for collection in query.collections:
                    self.collection_loader.load_collection(collection)
            
            # 쿼리 임베딩 생성
            query_vector = np.array(self.embedding_service.get_embedding(query.query_text))
            
            # 검색 수행
            results = self.collection_loader.search(query_vector, k=Config.MAX_SEARCH_RESULTS)
            
            # 결과 필터링 (유사도 임계값 적용)
            filtered_results = [
                doc for doc in results 
                if doc.score >= Config.SIMILARITY_THRESHOLD
            ]
            
            return {
                "success": True,
                "results": [doc.to_dict() for doc in filtered_results]
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            } 