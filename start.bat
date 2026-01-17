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

:get_version_parts
set "ver=%~1"
set "ver=!ver:v=!"
for /f "tokens=1-3 delims=." %%a in ("!ver!") do (
    set "major=%%a"
    set "minor=%%b"
    set "patch=%%c"
)
exit /b

:is_version_newer
set "v1=%~1"
set "v2=%~2"
set "v1=!v1:v=!"
set "v2=!v2:v=!"

for /f "tokens=1-3 delims=." %%a in ("!v1!") do (
    set "v1_major=%%a"
    set "v1_minor=%%b"
    set "v1_patch=%%c"
)
for /f "tokens=1-3 delims=." %%a in ("!v2!") do (
    set "v2_major=%%a"
    set "v2_minor=%%b"
    set "v2_patch=%%c"
)

if not defined v1_major set "v1_major=0"
if not defined v1_minor set "v1_minor=0"
if not defined v1_patch set "v1_patch=0"
if not defined v2_major set "v2_major=0"
if not defined v2_minor set "v2_minor=0"
if not defined v2_patch set "v2_patch=0"

if !v1_major! lss !v2_major! exit /b 0
if !v1_major! gtr !v2_major! exit /b 1
if !v1_minor! lss !v2_minor! exit /b 0
if !v1_minor! gtr !v2_minor! exit /b 1
if !v1_patch! lss !v2_patch! exit /b 0
exit /b 1

:prompt_yes_no
set "prompt_text=%~1"
:prompt_loop
set /p "response=%prompt_text% (yes/no): "
if /i "!response!"=="yes" exit /b 0
if /i "!response!"=="y" exit /b 0
if /i "!response!"=="no" exit /b 1
if /i "!response!"=="n" exit /b 1
call :print_error "Please answer yes or no"
goto :prompt_loop

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

:check_version
git --version >nul 2>&1
if !errorlevel! neq 0 exit /b 0

if not exist ".git" exit /b 0

call :print_info "Checking for updates..."

git fetch --tags --quiet >nul 2>&1

for /f "delims=" %%i in ('git describe --tags --exact-match HEAD 2^>nul') do set "CURRENT_TAG=%%i"
if not defined CURRENT_TAG (
    for /f "delims=" %%i in ('git describe --tags --abbrev=0 HEAD 2^>nul') do set "CURRENT_TAG=%%i"
)

set "tag_count=0"
for /f "delims=" %%i in ('git tag -l "v*.*.*" 2^>nul') do (
    set "all_tags[!tag_count!]=%%i"
    set /a tag_count+=1
)

if !tag_count! equ 0 exit /b 0

set /a last_idx=tag_count-1
set /a last=tag_count-1
for /l %%i in (0,1,!last!) do (
    set /a inner_last=tag_count-%%i-1
    for /l %%j in (0,1,!inner_last!) do (
        set /a next=%%j+1
        if defined all_tags[!next!] (
            call :is_version_newer "!all_tags[%%j]!" "!all_tags[!next!]!"
            if !errorlevel! equ 0 (
                set "temp=!all_tags[%%j]!"
                set "all_tags[%%j]=!all_tags[!next!]!"
                set "all_tags[!next!]=!temp!"
            )
        )
    )
)

set "LATEST_TAG=!all_tags[%last_idx%]!"

if not defined CURRENT_TAG (
    set "latest_version=!LATEST_TAG:v=!"
    call :print_warning "New version available: (no version) -> !latest_version!"
    exit /b 0
)

call :is_version_newer "!CURRENT_TAG!" "!LATEST_TAG!"
if !errorlevel! equ 0 (
    set "current_version=!CURRENT_TAG:v=!"
    set "latest_version=!LATEST_TAG:v=!"
    call :print_warning "New version available: !current_version! -> !latest_version!"
)

exit /b 0

:main
set "missing_files_count=0"
set "missing_tools_count=0"

call :print_info "Checking for required files..."

if not exist ".env" (
    set "missing_files[!missing_files_count!]=.env"
    set /a missing_files_count+=1
    call :print_warning ".env file not found"
) else (
    call :print_success ".env file exists"
)

if not exist "Sunrise.Config.Production.json" (
    set "missing_files[!missing_files_count!]=Sunrise.Config.Production.json"
    set /a missing_files_count+=1
    call :print_warning "Sunrise.Config.Production.json file not found"
) else (
    call :print_success "Sunrise.Config.Production.json file exists"
)

call :print_info "Checking for required tools..."

git --version >nul 2>&1
if !errorlevel! neq 0 (
    set "missing_tools[!missing_tools_count!]=git"
    set /a missing_tools_count+=1
    call :print_error "Git is not installed"
    call :print_info "Please install Git from: https://git-scm.com/"
) else (
    call :print_success "Git is installed"
)

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

if !missing_files_count! gtr 0 (
    call :print_warning "Some required files are missing:"
    set /a mf_last=missing_files_count-1
    for /l %%i in (0,1,!mf_last!) do (
        echo   %YELLOW%- !missing_files[%%i]!%NC%
    )
    echo.
    
    set "has_env=0"
    set "has_config=0"
    set /a mf_last=missing_files_count-1
    for /l %%i in (0,1,!mf_last!) do (
        if "!missing_files[%%i]!"==".env" set "has_env=1"
        if "!missing_files[%%i]!"=="Sunrise.Config.Production.json" set "has_config=1"
    )
    
    if !has_env! equ 1 (
        call :print_info "You can create .env by running: copy .env.example .env"
    )
    
    if !has_config! equ 1 (
        call :print_info "You can create Sunrise.Config.Production.json by running: copy Sunrise.Config.Production.json.example Sunrise.Config.Production.json"
    )
    echo.
)

if !missing_tools_count! gtr 0 (
    call :print_error "Some required tools are missing. Please install them before continuing."
    exit /b 1
)

if !missing_files_count! gtr 0 (
    call :print_error "Please create the missing files before starting the setup."
    exit /b 1
)

call :check_version
echo.

call :print_info "Do you want to build the setup?"
call :print_info "Note: You should run this if you updated .env, config, or any other configuration files."
echo.

call :prompt_yes_no "Do you want to build and start the Docker containers?"
if !errorlevel! equ 0 (
    call :print_info "Building and starting Docker containers..."
    call :run_docker_compose up -d --build
    if !errorlevel! neq 0 (
        call :print_error "Failed to build and start Docker containers"
        exit /b 1
    )
    call :print_success "Docker containers built and started successfully!"
) else (
    call :print_info "Starting Docker containers without rebuild..."
    call :run_docker_compose up -d
    if !errorlevel! neq 0 (
        call :print_error "Failed to start Docker containers"
        exit /b 1
    )
    call :print_success "Docker containers started successfully!"
)

exit /b 0
