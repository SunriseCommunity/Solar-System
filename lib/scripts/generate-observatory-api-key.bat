@echo off
setlocal enabledelayedexpansion

powershell -NoProfile -ExecutionPolicy Bypass -Command "$token = -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_}); $content = Get-Content -Path '.env' -ErrorAction SilentlyContinue; $found = $false; $newContent = $content | ForEach-Object { if ($_ -match '^OBSERVATORY_IGNORE_RATELIMIT_KEY=') { $found = $true; \"OBSERVATORY_IGNORE_RATELIMIT_KEY=$token\" } else { $_ } }; if (-not $found) { $newContent += \"OBSERVATORY_IGNORE_RATELIMIT_KEY=$token\" }; $newContent | Set-Content -Path '.env' -NoNewline:$false"

exit /b 0
