"""
API 서버 및 한글 인코딩 테스트 스크립트
"""
import requests
import json
import sys
import os

# 경로 설정
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from api.config import Config

def test_chat_endpoint():
    """채팅 엔드포인트 테스트 - 한글 메시지 포함"""
    url = f"http://localhost:{Config.PORT}/chat"
    
    # 한글이 포함된 테스트 메시지
    payload = {
        "session_id": "test_session_123",
        "message": "안녕하세요? 보험 상담해 주세요.",
        "chat_history": []
    }
    
    headers = {
        "Content-Type": "application/json; charset=utf-8"
    }
    
    print(f"요청 URL: {url}")
    print(f"요청 데이터: {json.dumps(payload, ensure_ascii=False)}")
    
    try:
        response = requests.post(
            url,
            headers=headers,
            data=json.dumps(payload, ensure_ascii=False).encode('utf-8')
        )
        
        print(f"상태 코드: {response.status_code}")
        print(f"응답 헤더: {response.headers}")
        
        # 응답이 UTF-8로 디코딩되었는지 확인
        response_text = response.text
        print(f"원본 응답: {response_text}")
        
        # JSON으로 파싱
        try:
            json_data = response.json()
            print("\n파싱된 응답:")
            print(json.dumps(json_data, indent=2, ensure_ascii=False))
            
            # 한글 응답 검증
            if "answer" in json_data and isinstance(json_data["answer"], str):
                print("\n한글 확인 성공: 응답에 answer 필드가 있고 문자열입니다.")
            else:
                print("\n한글 확인 실패: 응답에 answer 필드가 없거나 문자열이 아닙니다.")
            
            return True
        except json.JSONDecodeError as e:
            print(f"JSON 파싱 오류: {e}")
            return False
            
    except Exception as e:
        print(f"오류 발생: {e}")
        return False

def test_ping_endpoint():
    """API 서버 상태 확인"""
    url = f"http://localhost:{Config.PORT}/api/ping"
    
    try:
        response = requests.get(url)
        print(f"Ping 상태 코드: {response.status_code}")
        print(f"Ping 응답: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Ping 오류: {e}")
        return False

if __name__ == "__main__":
    print("=== 보험상담 API 서버 테스트 ===")
    
    # API 서버 상태 확인
    print("\n1. API 서버 상태 확인")
    if test_ping_endpoint():
        print("✓ API 서버가 정상적으로 응답합니다.")
    else:
        print("✗ API 서버 연결에 문제가 있습니다. 서버가 실행 중인지 확인하세요.")
        sys.exit(1)
    
    # 채팅 엔드포인트 테스트
    print("\n2. 채팅 엔드포인트 및 한글 인코딩 테스트")
    if test_chat_endpoint():
        print("✓ 채팅 엔드포인트가 정상적으로 작동합니다.")
    else:
        print("✗ 채팅 엔드포인트 테스트에 실패했습니다.")
