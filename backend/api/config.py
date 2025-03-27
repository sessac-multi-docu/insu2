"""
API 서버 설정을 위한 설정 파일
"""

class Config:
    # API 접두사 설정
    API_PREFIX = "/api"
    
    # CORS 설정
    CORS_ORIGINS = ["*"]  # 모든 출처 허용 (개발용)
    
    # 서버 설정
    HOST = "0.0.0.0"  # 모든 인터페이스에서 수신
    PORT = 8095      # 프록시 서버가 이 포트로 요청을 전달
    
    # 로깅 설정
    LOG_LEVEL = "INFO"
    
    # 응답 설정
    RESPONSE_CHARSET = "utf-8"  # 한글 응답 인코딩
    
    # 세션 관리 설정
    MAX_HISTORY_LENGTH = 10
    SESSION_CLEANUP_HOURS = 24
