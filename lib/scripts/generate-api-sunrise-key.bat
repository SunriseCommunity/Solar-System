@echo off
setlocal enabledelayedexpansion

powershell -NoProfile -ExecutionPolicy Bypass -Command "$token = -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_}); $content = Get-Content -Path '.env' -ErrorAction SilentlyContinue; $found = $false; $newContent = $content | ForEach-Object { if ($_ -match '^SUNRISE_API_TOKEN_SECRET=') { $found = $true; \"SUNRISE_API_TOKEN_SECRET=$token\" } else { $_ } }; if (-not $found) { $newContent += \"SUNRISE_API_TOKEN_SECRET=$token\" }; $newContent | Set-Content -Path '.env' -NoNewline:$false"

exit /b 0
