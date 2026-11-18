@echo off
title Launch All Services
echo ===================================================
echo Launching Backend and Frontend in separate terminals...
echo ===================================================

echo [1/2] Launching FastAPI Backend on http://127.0.0.1:8000 ...
start "FastAPI Backend Server" cmd /k "cd /d %~dp0backend && python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000"

echo Waiting 3 seconds for backend to initialize...
timeout /t 3 /nobreak >nul

echo [2/2] Launching Flutter Frontend (Chrome)...
start "Flutter Frontend App" cmd /k "cd /d %~dp0frontend && flutter run -d chrome"

echo.
echo All services launched!
echo - Swagger Docs: http://127.0.0.1:8000/docs
echo - ReDoc:        http://127.0.0.1:8000/redoc
echo.

