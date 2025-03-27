import os
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import uvicorn
from datetime import datetime

# Import our encoding helpers
from .encoders import utf8_json_response, ensure_utf8_encoding

# Initialize FastAPI
app = FastAPI(
    title="Simple Korean Text API", 
    description="API for testing Korean character encoding", 
    version="1.0.0",
    default_response_class=JSONResponse
)

# Add UTF-8 encoding middleware
@app.middleware("http")
async def add_utf8_charset_header(request: Request, call_next):
    """Add UTF-8 charset header to all responses"""
    response = await call_next(request)
    content_type = response.headers.get("content-type", "")
    
    # Add charset=utf-8 to JSON responses
    if "application/json" in content_type and "charset" not in content_type:
        response.headers["content-type"] = "application/json; charset=utf-8"
    
    return response

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Define models
class ChatMessage(BaseModel):
    role: str
    content: str
    timestamp: Optional[str] = None

class ChatSession(BaseModel):
    session_id: str = Field(..., description="Session ID")
    message: str = Field(..., description="User message")
    chat_history: Optional[List[ChatMessage]] = Field(default=[], description="Chat history")

class ChatResponse(BaseModel):
    answer: str
    session_id: str
    chat_history: List[ChatMessage]

# Chat endpoint
@app.post("/chat")
async def chat(chat_session: ChatSession, request: Request):
    """Handle chat requests and test Korean character encoding"""
    try:
        # Log client information for debugging
        client_host = request.client.host if request.client else "unknown"
        print(f"[{datetime.now().isoformat()}] Chat API request from: {client_host}")
        
        # Log the Korean message for debugging
        print(f"Received message (original): {chat_session.message}")
        print(f"Received message (UTF-8): {ensure_utf8_encoding(chat_session.message)}")
        
        # Prepare response with Korean text
        korean_response = "안녕하세요! 한국어 응답이 정상적으로 표시됩니다. 메시지를 받았습니다: " + chat_session.message
        print(f"Responding with (UTF-8): {ensure_utf8_encoding(korean_response)}")
        
        # Create chat history
        timestamp = datetime.now().isoformat()
        
        # Add user message to history if not already there
        history = list(chat_session.chat_history) if chat_session.chat_history else []
        
        # Check if user message is already in history
        user_msg_exists = any(
            msg.role == "user" and msg.content == chat_session.message 
            for msg in history
        )
        
        if not user_msg_exists:
            history.append(ChatMessage(
                role="user",
                content=chat_session.message,
                timestamp=timestamp
            ))
        
        # Add assistant response to history
        history.append(ChatMessage(
            role="assistant",
            content=korean_response,
            timestamp=timestamp
        ))
        
        # Return the response with explicit UTF-8 encoding
        response_data = {
            "answer": korean_response,
            "session_id": chat_session.session_id,
            "chat_history": [msg.dict() for msg in history]
        }
        
        return utf8_json_response(response_data)
    
    except Exception as e:
        error_msg = f"Error processing chat: {str(e)}"
        print(error_msg)
        
        # Return error with UTF-8 encoding
        return utf8_json_response(
            {
                "error": ensure_utf8_encoding(error_msg),
                "session_id": chat_session.session_id
            },
            status_code=500
        )

# API health check endpoint
@app.get("/ping")
def ping():
    """Check if the API is running"""
    return utf8_json_response({"status": "ok", "message": "한글 인코딩 테스트: 정상 작동 중"})

# Run the server
if __name__ == "__main__":
    port = int(os.getenv("PORT", "8095"))
    print(f"[Korean encoding test] Starting server on port {port}")
    print("UTF-8 encoding is enabled")
    uvicorn.run("api.simple_server:app", host="0.0.0.0", port=port, reload=True)
