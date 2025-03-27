import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # LangSmith 설정
    LANGCHAIN_API_KEY = os.getenv("LANGCHAIN_API_KEY", "")
    LANGCHAIN_PROJECT = os.getenv("LANGCHAIN_PROJECT", "insupanda")
    LANGCHAIN_ENDPOINT = os.getenv("LANGCHAIN_ENDPOINT", "https://api.smith.langchain.com")
    
    # OpenAI 설정
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
    
    # Upstage 설정
    UPSTAGE_API_KEY = os.getenv("UPSTAGE_API_KEY", "")
    
    # 벡터 DB 설정
    VECTOR_DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "vector_db")
    
    # 컬렉션 매핑
    COLLECTION_MAPPING = {
        "db손해보험": "DBSonBo_YakMu20250123",
        "DB손해보험": "DBSonBo_YakMu20250123",
        "db손보": "DBSonBo_YakMu20250123",
        "삼성화재": "Samsung_YakMu2404103NapHae20250113",
        "삼성": "Samsung_YakMu2404103NapHae20250113",
        "DBSonbo_Yakwan20250123": "DBSonBo_YakMu20250123"
    }
    
    # 검색 설정
    MAX_SEARCH_RESULTS = 5
    SIMILARITY_THRESHOLD = 0.7
    
    # API 설정
    API_PREFIX = "/api"
    CORS_ORIGINS = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:5500",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://localhost:8081",
        "http://127.0.0.1",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:5500",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:8081",
        "*"
    ] 