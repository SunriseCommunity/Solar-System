@echo off
setlocal enabledelayedexpansion

powershell -NoProfile -ExecutionPolicy Bypass -Command "$envPath = Join-Path (Get-Location) '.env'; $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create(); $bytes = New-Object byte[] 32; $rng.GetBytes($bytes); $rng.Dispose(); $token = ([System.BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant(); $content = Get-Content -LiteralPath $envPath -ErrorAction SilentlyContinue; $found = $false; $newContent = $content | ForEach-Object { if ($_ -match '^OBSERVATORY_IGNORE_RATELIMIT_KEY=') { $found = $true; \"OBSERVATORY_IGNORE_RATELIMIT_KEY=$token\" } else { $_ } }; if (-not $found) { $newContent += \"OBSERVATORY_IGNORE_RATELIMIT_KEY=$token\" }; [System.IO.File]::WriteAllLines($envPath, @($newContent), [System.Text.UTF8Encoding]::new($false))"

exit /b 0
