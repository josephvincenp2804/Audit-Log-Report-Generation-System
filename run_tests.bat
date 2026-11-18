@echo off
title Audit Log System - Automated Tests
echo ===================================================
echo 1. Running Backend Pytest Suite (11 tests)...
echo ===================================================
set PYTHONPATH=%~dp0backend
python -m pytest "%~dp0backend\tests" -v

echo.
echo ===================================================
echo 2. Running Frontend Flutter Widget Tests...
echo ===================================================
cd /d "%~dp0frontend"
call flutter test

echo.
echo ===================================================
echo 3. Running Frontend Static Analysis...
echo ===================================================
call flutter analyze

echo.
echo All test executions finished!
pause

