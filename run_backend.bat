@echo off
title Audit Log System - FastAPI Backend
echo ===================================================
echo Starting Audit Log System - FastAPI Backend
echo Port: 8000
echo Swagger Docs: http://127.0.0.1:8000/docs
echo ===================================================
cd /d "%~dp0backend"
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
pause

