from dataclasses import dataclass
from typing import Optional, Dict, Any

@dataclass
class Document:
    id: str
    content: str
    metadata: Dict[str, Any]
    score: Optional[float] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "content": self.content,
            "metadata": self.metadata,
            "score": self.score
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Document':
        return cls(
            id=data["id"],
            content=data["content"],
            metadata=data["metadata"],
            score=data.get("score")
        ) 