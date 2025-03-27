import os
import json
from typing import Dict, Any, List
from .document import Document

class Utils:
    @staticmethod
    def load_json(file_path: str) -> Dict[str, Any]:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    @staticmethod
    def save_json(data: Dict[str, Any], file_path: str) -> None:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    
    @staticmethod
    def ensure_dir(directory: str) -> None:
        if not os.path.exists(directory):
            os.makedirs(directory)
    
    @staticmethod
    def format_documents(documents: List[Document]) -> str:
        return "\n\n".join([
            f"문서 {i+1}:\n{doc.content}"
            for i, doc in enumerate(documents)
        ]) 