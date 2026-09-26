@echo off
call "%~dp0lib\scripts\update-common.bat" "%~dp0" "docker-compose.local.yml" %*
exit /b %errorlevel%
