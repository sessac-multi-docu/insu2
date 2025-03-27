from pydantic import BaseModel
from typing import List, Union

class NestedQuery(BaseModel):
    query: str

class SearchQuery(BaseModel):
    query: Union[str, NestedQuery]
    collections: List[str] = None

    class Config:
        schema_extra = {
            "example": {
                "query": "삼성화재 암보험에 대해 알려줘",
                "collections": ["Samsung_YakMu2404103NapHae20250113"]
            }
        }
        
    @property
    def query_text(self) -> str:
        if isinstance(self.query, str):
            return self.query
        return self.query.query 