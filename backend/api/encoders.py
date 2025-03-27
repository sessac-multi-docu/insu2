"""
UTF-8 인코딩 관련 헬퍼 모듈
한글 텍스트의 올바른 처리를 보장하기 위한 유틸리티 함수
"""
import json
from typing import Any, Dict
from datetime import datetime
from fastapi.responses import JSONResponse


class UTF8JSONEncoder(json.JSONEncoder):
    """UTF-8 문자열 처리 및 특수 객체 변환을 위한 JSON 인코더"""
    
    def default(self, obj):
        """객체 타입 별 직렬화 처리"""
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)


def utf8_json_response(content: Dict[str, Any], status_code: int = 200) -> JSONResponse:
    """
    UTF-8 인코딩을 명시적으로 포함한 JSON 응답 헬퍼
    
    Args:
        content: 응답 컨텐츠 (dict)
        status_code: HTTP 상태 코드
        
    Returns:
        한글 처리를 위한 인코딩 헤더가 포함된 JSONResponse
    """
    return JSONResponse(
        content=content,
        status_code=status_code,
        headers={"Content-Type": "application/json; charset=utf-8"},
    )


def ensure_utf8_encoding(text: str) -> str:
    """
    문자열이 UTF-8로 올바르게 인코딩되었는지 확인하고 필요시 변환
    
    Args:
        text: 입력 텍스트
        
    Returns:
        UTF-8로 인코딩된 텍스트
    """
    try:
        # 문자열이 이미 UTF-8인지 확인
        text.encode('utf-8').decode('utf-8')
        return text
    except UnicodeError:
        # 다른 인코딩에서 변환 시도
        try:
            # CP949 (한국어 윈도우 인코딩)에서 변환 시도
            return text.encode('cp949').decode('utf-8', errors='replace')
        except Exception:
            # 모든 방법 실패 시 최선의 방법으로 대체 문자 사용
            return text.encode('utf-8', errors='replace').decode('utf-8')
