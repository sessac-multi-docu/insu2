from typing import List, Dict, Any
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
from .config import Config
from .document import Document
from .prompts import Prompts

class AnswerGenerator:
    def __init__(self):
        self.llm = ChatOpenAI(
            model="gpt-4-turbo-preview",
            temperature=0.7,
            api_key=Config.OPENAI_API_KEY
        )
    
    def generate_answer(self, query: str, documents: List[Document]) -> Dict[str, Any]:
        try:
            # 컨텍스트 생성
            context = "\n\n".join([
                f"문서 {i+1}:\n{doc.content}"
                for i, doc in enumerate(documents)
            ])
            
            # 프롬프트 생성
            messages = [
                SystemMessage(content=Prompts.SYSTEM_PROMPT),
                HumanMessage(content=Prompts.USER_PROMPT.format(
                    context=context,
                    query=query
                ))
            ]
            
            # 답변 생성
            response = self.llm.invoke(messages)
            
            return {
                "success": True,
                "answer": response.content,
                "sources": [doc.to_dict() for doc in documents]
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            } 