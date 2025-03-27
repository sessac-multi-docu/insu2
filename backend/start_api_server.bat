@echo off
echo 보험상담 API 서버 시작...
cd /d %~dp0
python -m api.main
echo 서버가 종료되었습니다.
pause
