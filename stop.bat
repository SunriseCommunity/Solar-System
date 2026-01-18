@echo off
setlocal enabledelayedexpansion

for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "BLUE=%ESC%[94m"
set "NC=%ESC%[0m"

goto :main

:print_info
echo %BLUE%[i]%NC% %~1
exit /b

:print_success
echo %GREEN%[+]%NC% %~1
exit /b

:print_warning
echo %YELLOW%[!]%NC% %~1
exit /b

:print_error
echo %RED%[x]%NC% %~1
exit /b

:detect_docker_compose
docker compose version >nul 2>&1
if !errorlevel! equ 0 (
    set "DOCKER_COMPOSE_CMD=docker compose"
    exit /b 0
)
docker-compose version >nul 2>&1
if !errorlevel! equ 0 (
    set "DOCKER_COMPOSE_CMD=docker-compose"
    exit /b 0
)
set "DOCKER_COMPOSE_CMD="
exit /b 1

:run_docker_compose
if "!DOCKER_COMPOSE_CMD!"=="docker compose" (
    docker compose %*
) else (
    docker-compose %*
)
exit /b

:main
set "missing_tools_count=0"

call :print_info "Checking for required tools..."

docker --version >nul 2>&1
if !errorlevel! neq 0 (
    set "missing_tools[!missing_tools_count!]=docker"
    set /a missing_tools_count+=1
    call :print_error "Docker is not installed"
    call :print_info "Please install Docker from: https://www.docker.com/get-started/"
) else (
    call :print_success "Docker is installed"
)

set "DOCKER_COMPOSE_CMD="
docker --version >nul 2>&1
if !errorlevel! equ 0 (
    call :detect_docker_compose
    if "!DOCKER_COMPOSE_CMD!"=="" (
        call :print_error "Docker Compose is not available"
        call :print_info "Please install Docker Compose from: https://www.docker.com/get-started/"
        set "missing_tools[!missing_tools_count!]=docker-compose"
        set /a missing_tools_count+=1
    ) else (
        call :print_success "Docker Compose is available (!DOCKER_COMPOSE_CMD!)"
    )
)

echo.

if !missing_tools_count! gtr 0 (
    call :print_error "Some required tools are missing. Please install them before continuing."
    exit /b 1
)

call :print_info "Stopping Docker containers..."
call :run_docker_compose stop
if !errorlevel! neq 0 (
    call :print_error "Failed to stop Docker containers"
    exit /b 1
)
call :print_success "Docker containers stopped successfully!"

exit /b 0
