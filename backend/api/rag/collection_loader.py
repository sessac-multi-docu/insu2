import os
import json
import faiss
import numpy as np
from typing import Dict, Any, Optional
from .config import Config
from .document import Document

class CollectionLoader:
    def __init__(self):
        self.collections = []
        self.cached_embeddings = {}
        self.base_path = Config.VECTOR_DB_PATH
    
    def load_collection(self, collection_name: str) -> bool:
        try:
            # 이미 로드된 컬렉션 확인
            for coll in self.collections:
                if coll["name"] == collection_name:
                    return True
            
            # 컬렉션 이름 매핑 적용
            actual_collection_name = Config.COLLECTION_MAPPING.get(collection_name, collection_name)
            
            collection_dir = os.path.join(self.base_path, actual_collection_name)
            index_path = self._find_index_file(collection_dir)
            metadata_path = os.path.join(collection_dir, "metadata.json")
            
            if not os.path.exists(index_path) or not os.path.exists(metadata_path):
                raise FileNotFoundError(f"Required files not found in {collection_dir}")
            
            index = faiss.read_index(index_path)
            with open(metadata_path, 'r', encoding='utf-8') as f:
                metadata = json.load(f)
            
            self.collections.append({
                "name": collection_name,
                "index": index,
                "metadata": metadata
            })
            
            return True
            
        except Exception as e:
            print(f"Error loading collection {collection_name}: {e}")
            return False
    
    def _find_index_file(self, collection_dir: str) -> str:
        possible_index_files = ["index.faiss", "faiss.index", "index"]
        for idx_file in possible_index_files:
            temp_path = os.path.join(collection_dir, idx_file)
            if os.path.exists(temp_path):
                return temp_path
        raise FileNotFoundError(f"No index file found in {collection_dir}")
    
    def search(self, query_vector: np.ndarray, k: int = 5) -> list[Document]:
        results = []
        for collection in self.collections:
            index = collection["index"]
            metadata = collection["metadata"]
            
            # 검색 수행
            distances, indices = index.search(query_vector.reshape(1, -1), k)
            
            # 결과 처리
            for i, (distance, idx) in enumerate(zip(distances[0], indices[0])):
                if idx < len(metadata):
                    doc = Document(
                        id=f"{collection['name']}_{idx}",
                        content=metadata[idx]["content"],
                        metadata=metadata[idx]["metadata"],
                        score=float(1 / (1 + distance))
                    )
                    results.append(doc)
        
        return sorted(results, key=lambda x: x.score, reverse=True) 