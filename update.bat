@echo off
setlocal enabledelayedexpansion

for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "BLUE=%ESC%[94m"
set "NC=%ESC%[0m"

set "REPO_URL=https://github.com/SunriseCommunity/Solar-System"
set "RELEASES_URL=%REPO_URL%/releases/tag"

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

:is_valid_version_tag

set "tag=%~1"
set "tag_cleaned=!tag:v=!"
echo !tag_cleaned! | findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
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

:main
call :print_info "Checking repository state..."

docker --version >nul 2>&1
if !errorlevel! equ 0 (
    call :detect_docker_compose
    if "!DOCKER_COMPOSE_CMD!"=="" (
        call :print_error "Docker Compose is not available"
        call :print_info "Please install Docker Compose from: https://www.docker.com/get-started/"
    ) else (
        call :print_success "Docker Compose is available (!DOCKER_COMPOSE_CMD!)"
    )
)

for /f "delims=" %%i in ('git rev-parse HEAD') do set "CURRENT_COMMIT=%%i"

for /f "delims=" %%i in ('git describe --tags --abbrev=0 2^>nul') do set "LATEST_LOCAL_TAG=%%i"

if defined LATEST_LOCAL_TAG (
    git ls-remote --tags origin "!LATEST_LOCAL_TAG!" 2>nul | findstr "!LATEST_LOCAL_TAG!" >nul
    if !errorlevel! neq 0 (
        for /f "delims=" %%i in ('git rev-list -n 1 "!LATEST_LOCAL_TAG!" 2^>nul') do set "TAG_COMMIT=%%i"
        if defined TAG_COMMIT (
            git merge-base --is-ancestor "!TAG_COMMIT!" "!CURRENT_COMMIT!" 2>nul
            if !errorlevel! equ 0 (
                call :print_info "Pushing tag !LATEST_LOCAL_TAG! to remote..."
                git push origin "!LATEST_LOCAL_TAG!" 2>nul || call :print_warning "Tag push failed or already exists"
            ) else if "!CURRENT_COMMIT!"=="!TAG_COMMIT!" (
                call :print_info "Pushing tag !LATEST_LOCAL_TAG! to remote..."
                git push origin "!LATEST_LOCAL_TAG!" 2>nul || call :print_warning "Tag push failed or already exists"
            )
        )
    )
)

call :print_info "Fetching latest changes..."
git fetch --tags --all
if !errorlevel! neq 0 (
    call :print_error "Failed to fetch changes"
    exit /b 1
)

for /f "delims=" %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%i"
if "!CURRENT_BRANCH!"=="HEAD" set "CURRENT_BRANCH="

if defined CURRENT_BRANCH (
    call :print_info "Pulling changes with submodules..."
    git pull --recurse-submodules
    if !errorlevel! neq 0 (
        call :print_error "Failed to pull changes. Please resolve conflicts manually."
        exit /b 1
    )
) else (
    call :print_info "On detached HEAD (tag), skipping pull..."
)

call :print_info "Updating submodules..."
git submodule update --init --recursive --remote || call :print_warning "Some submodules may have failed to update"

set "tag_count=0"
for /f "delims=" %%i in ('git tag -l "v*.*.*"') do (
    call :is_valid_version_tag "%%i"
    if !errorlevel! equ 0 (
        set "all_tags[!tag_count!]=%%i"
        set /a tag_count+=1
    )
)

set /a last=tag_count-1
for /l %%i in (0,1,!last!) do (
    set /a inner_last=tag_count-%%i-1
    for /l %%j in (0,1,!inner_last!) do (
        set /a next=%%j+1
        call :is_version_newer "!all_tags[%%j]!" "!all_tags[!next!]!"
        if !errorlevel! equ 0 (
            set "temp=!all_tags[%%j]!"
            set "all_tags[%%j]=!all_tags[!next!]!"
            set "all_tags[!next!]=!temp!"
        )
    )
)

for /f "delims=" %%i in ('git describe --tags --exact-match HEAD 2^>nul') do set "CURRENT_TAG=%%i"
if not defined CURRENT_TAG (
    for /f "delims=" %%i in ('git describe --tags --abbrev=0 HEAD 2^>nul') do set "CURRENT_TAG=%%i"
)

set "new_tag_count=0"
for /l %%i in (0,1,!last!) do (
    set "tag=!all_tags[%%i]!"
    if not defined LATEST_LOCAL_TAG (
        set "new_tags[!new_tag_count!]=!tag!"
        set /a new_tag_count+=1
    ) else (
        call :is_version_newer "!LATEST_LOCAL_TAG!" "!tag!"
        if !errorlevel! equ 0 (
            set "new_tags[!new_tag_count!]=!tag!"
            set /a new_tag_count+=1
        )
    )
)

if !new_tag_count! equ 0 (
    call :print_success "No new tags found. You are up to date!"
    exit /b 0
)

call :print_info "New tags found:"
set /a new_last=new_tag_count-1
for /l %%i in (0,1,!new_last!) do (
    set "tag=!new_tags[%%i]!"
    set "tag_version=!tag:v=!"
    echo   %GREEN%[+]%NC% !RELEASES_URL!/!tag! (new tag !tag_version!)
)

if defined CURRENT_TAG (
    set "PREVIOUS_TAG=!CURRENT_TAG!"
) else (
    set "PREVIOUS_TAG=!LATEST_LOCAL_TAG!"
)

set "major_minor_count=0"
for /l %%i in (0,1,!new_last!) do (
    set "tag=!new_tags[%%i]!"
    
    if not defined PREVIOUS_TAG (
        call :get_version_parts "!tag!"
        if !major! gtr 0 (
            set "major_minor_tags[!major_minor_count!]=!tag!"
            set /a major_minor_count+=1
        ) else if !minor! gtr 0 (
            set "major_minor_tags[!major_minor_count!]=!tag!"
            set /a major_minor_count+=1
        )
    ) else (
        call :get_version_parts "!PREVIOUS_TAG!"
        set "prev_major=!major!"
        set "prev_minor=!minor!"
        set "prev_patch=!patch!"
        
        call :get_version_parts "!tag!"
        set "curr_major=!major!"
        set "curr_minor=!minor!"
        set "curr_patch=!patch!"
        
        if !curr_major! gtr !prev_major! (
            set "major_minor_tags[!major_minor_count!]=!tag!"
            set /a major_minor_count+=1
        ) else if !curr_minor! gtr !prev_minor! (
            set "major_minor_tags[!major_minor_count!]=!tag!"
            set /a major_minor_count+=1
        )
    )
    set "PREVIOUS_TAG=!tag!"
)

set /a mm_last=major_minor_count-1
if !major_minor_count! gtr 0 (
    for /l %%i in (0,1,!mm_last!) do (
        set "tag=!major_minor_tags[%%i]!"
        call :get_version_parts "!tag!"
        
        if !major! gtr 0 (
            set "VERSION_TYPE=major"
        ) else (
            set "VERSION_TYPE=minor"
        )
        
        set "tag_version=!tag:v=!"
        call :print_warning "The !VERSION_TYPE! version has updated to !tag_version!"
        call :print_info "Please review the changelog: !RELEASES_URL!/!tag!"
        echo.
        
        call :prompt_yes_no "Do you want to continue with this !VERSION_TYPE! version update?"
        if !errorlevel! neq 0 (
            call :print_warning "Skipping !VERSION_TYPE! version update to !tag_version!"
            
            set "updated_tag_count=0"
            set "skip_mode=0"
            for /l %%j in (0,1,!new_last!) do (
                if "!new_tags[%%j]!"=="!tag!" set "skip_mode=1"
                if !skip_mode! equ 0 (
                    set "updated_tags[!updated_tag_count!]=!new_tags[%%j]!"
                    set /a updated_tag_count+=1
                )
            )
            
            set "new_tag_count=!updated_tag_count!"
            set /a new_last=new_tag_count-1
            for /l %%j in (0,1,!new_last!) do (
                set "new_tags[%%j]=!updated_tags[%%j]!"
            )
            
            if !new_tag_count! equ 0 exit /b 0
        )
        echo.
    )
)

set /a latest_idx=new_tag_count-1
set "LATEST_TAG=!new_tags[%latest_idx%]!"
call :print_info "Checking out tag: !LATEST_TAG!"

for /f "delims=" %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%i"
if not defined CURRENT_BRANCH set "CURRENT_BRANCH=HEAD"

git checkout "!LATEST_TAG!"
if !errorlevel! neq 0 (
    call :print_error "Failed to checkout tag !LATEST_TAG!"
    exit /b 1
)

call :print_info "Updating submodules..."
git submodule update --init --recursive || call :print_warning "Some submodules may have failed to update"

call :print_success "Successfully updated to tag !LATEST_TAG!"
if "!CURRENT_BRANCH!" neq "HEAD" if "!CURRENT_BRANCH!" neq "!LATEST_TAG!" (
    call :print_info "Note: You were on branch '!CURRENT_BRANCH!', now on tag '!LATEST_TAG!' (detached HEAD)"
)

echo.
call :print_info "Update process completed!"
echo.

call :prompt_yes_no "Do you want to rebuild the Docker containers to the newer version?"
if !errorlevel! equ 0 (
    if "!DOCKER_COMPOSE_CMD!"=="" (
        call :print_error "Docker Compose is not available. Please install Docker Compose first."
        exit /b 1
    )
    call :print_info "Rebuilding Docker containers..."
    call :run_docker_compose up -d --build
    if !errorlevel! neq 0 (
        call :print_error "Failed to rebuild Docker containers"
        exit /b 1
    )
    call :print_success "Docker containers rebuilt successfully!"
) else (
    call :print_info "Skipping Docker container rebuild"
)

call :print_success "Update script completed successfully!"
exit /b 0
