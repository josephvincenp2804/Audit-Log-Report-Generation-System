@echo off
title Audit Log System - Flutter Frontend
echo ===================================================
echo Starting Audit Log System - Flutter Frontend (Chrome)
echo ===================================================
cd /d "%~dp0frontend"
flutter run -d chrome
pause

