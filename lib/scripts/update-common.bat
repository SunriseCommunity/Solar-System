@echo off
setlocal EnableDelayedExpansion
pushd "%~1" || exit /b 1
set "COMPOSE_FILE=%~2"

if not "%~3"=="" (
    if /i not "%~3"=="--version" goto :usage
    if "%~4"=="" goto :usage
    if not "%~5"=="" goto :usage
    set "TARGET_TAG=%~4"
)

echo Fetching release tags...
git fetch --tags origin
if errorlevel 1 exit /b 1

set "CURRENT_TAG="
for /f "delims=" %%i in ('git describe --tags --abbrev^=0 HEAD 2^>nul') do set "CURRENT_TAG=%%i"
call :tag_type "!CURRENT_TAG!"
if errorlevel 1 set "CURRENT_TAG="
if defined CURRENT_TAG (echo Current version: !CURRENT_TAG!) else (echo Current version: untagged checkout)

set "tag_count=0"
set "stable_count=0"
set "latest_index=-1"
for /f "delims=" %%i in ('git tag --sort^=version:refname -l "v*"') do (
    call :tag_type "%%i"
    if not errorlevel 1 (
        set "all_tags[!tag_count!]=%%i"
        set /a tag_count+=1
        if !tag_type! equ 0 (
            set "stable_tags[!stable_count!]=%%i"
            set /a stable_count+=1
        )
    )
)
set "LATEST_STABLE="
if !stable_count! gtr 0 (
    set /a latest_index=stable_count-1
    for %%i in (!latest_index!) do set "LATEST_STABLE=!stable_tags[%%i]!"
)
if defined LATEST_STABLE (echo Latest stable: !LATEST_STABLE! ^(release candidates require explicit selection^)) else (echo Latest stable: none)

if defined TARGET_TAG (
    call :tag_type "!TARGET_TAG!"
    if errorlevel 1 (
        echo Unknown release tag: !TARGET_TAG!
        exit /b 1
    )
    git show-ref --verify --quiet "refs/tags/!TARGET_TAG!"
    if errorlevel 1 (
        echo Unknown release tag: !TARGET_TAG!
        exit /b 1
    )
) else (
    echo 1^) Update to latest stable
    echo 2^) Choose a version ^(including release candidates^)
    echo 3^) Roll back to an older stable version
    echo 4^) Cancel
    set "option="
    set /p "option=Select an option [1]: "
    if not defined option set "option=1"
    if "!option!"=="1" (
        if defined CURRENT_TAG if defined LATEST_STABLE (
            call :is_newer_stable "!LATEST_STABLE!" "!CURRENT_TAG!"
            if errorlevel 1 (
                echo No newer stable release is available. Choose a version explicitly to switch.
                exit /b 0
            )
        )
        set "TARGET_TAG=!LATEST_STABLE!"
    )
    if "!option!"=="2" (
        set "choice_count=!tag_count!"
        for /l %%i in (0,1,!tag_count!) do set "choices[%%i]=!all_tags[%%i]!"
        call :choose_tag "Choose a version"
        if errorlevel 1 exit /b 0
    )
    if "!option!"=="3" (
        if not defined CURRENT_TAG (
            echo Cannot identify the current version for rollback. Choose a version explicitly instead.
            exit /b 1
        )
        if !stable_count! equ 0 (
            echo No stable releases are available for rollback.
            exit /b 1
        )
        set "choice_count=0"
        for /l %%i in (0,1,!latest_index!) do (
            call :is_older_stable "!stable_tags[%%i]!" "!CURRENT_TAG!"
            if not errorlevel 1 (
                set "choices[!choice_count!]=!stable_tags[%%i]!"
                set /a choice_count+=1
            )
        )
        call :choose_tag "Roll back to"
        if errorlevel 1 exit /b 0
    )
    if "!option!"=="4" exit /b 0
    if not "!option!"=="1" if not "!option!"=="2" if not "!option!"=="3" (
        echo Invalid option.
        exit /b 1
    )
)

if not defined TARGET_TAG (
    echo No stable release is available.
    exit /b 0
)
if "!TARGET_TAG!"=="!CURRENT_TAG!" (
    set "EXACT_TAG="
    for /f "delims=" %%i in ('git describe --tags --exact-match HEAD 2^>nul') do set "EXACT_TAG=%%i"
    if "!EXACT_TAG!"=="!TARGET_TAG!" (
        echo Already on !TARGET_TAG!.
        exit /b 0
    )
)

set "DIRTY="
for /f "delims=" %%i in ('git status --porcelain --untracked-files^=no') do set "DIRTY=1"
if defined DIRTY (
    echo The checkout has uncommitted changes. Save them before switching versions.
    exit /b 1
)

echo Selected !TARGET_TAG!: https://github.com/SunriseCommunity/Solar-System/releases/tag/!TARGET_TAG!
set "confirm="
set /p "confirm=Switch to !TARGET_TAG!? (yes/no): "
if /i not "!confirm!"=="yes" if /i not "!confirm!"=="y" (
    echo Cancelled.
    exit /b 0
)

git -c advice.detachedHead=false checkout --detach "!TARGET_TAG!"
if errorlevel 1 exit /b 1
git submodule update --init --recursive
if errorlevel 1 exit /b 1
echo Now on !TARGET_TAG!.

set "rebuild="
set /p "rebuild=Rebuild Docker containers using !COMPOSE_FILE!? (yes/no): "
if /i "!rebuild!"=="yes" goto :rebuild
if /i "!rebuild!"=="y" goto :rebuild
echo Containers were not rebuilt.
exit /b 0

:rebuild
docker compose version >nul 2>&1
if not errorlevel 1 (
    docker compose -f "!COMPOSE_FILE!" up -d --build
) else (
    docker-compose version >nul 2>&1
    if errorlevel 1 (
        echo Docker Compose is unavailable; the checkout changed but containers were not rebuilt.
        exit /b 1
    )
    docker-compose -f "!COMPOSE_FILE!" up -d --build
)
if errorlevel 1 exit /b 1
echo Containers rebuilt using !TARGET_TAG!.
exit /b 0

:choose_tag
if !choice_count! equ 0 (
    echo No versions available for this option.
    exit /b 1
)
set /a choice_last=choice_count-1
for /l %%i in (0,1,!choice_last!) do (
    set /a display_index=%%i+1
    echo !display_index!^) !choices[%%i]!
)
set "choice="
set /p "choice=%~1 (number, or 0 to cancel): "
echo(!choice!| findstr /r "^[1-9][0-9]* *$" >nul
if errorlevel 1 exit /b 1
if !choice! gtr !choice_count! exit /b 1
set /a selected_index=choice-1
set "TARGET_TAG=!choices[%selected_index%]!"
exit /b 0

:tag_type
set "tag_type=1"
echo(%~1| findstr /r /c:"^v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* *$" >nul
if not errorlevel 1 (
    set "tag_type=0"
    exit /b 0
)
echo(%~1| findstr /r /c:"^v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*-rc\.[0-9][0-9]* *$" >nul
if not errorlevel 1 exit /b 0
exit /b 1

:is_older_stable
for /f "tokens=1-3 delims=." %%a in ("%~1") do (
    set "candidate_major=%%a"
    set "candidate_minor=%%b"
    set "candidate_patch=%%c"
)
set "candidate_major=!candidate_major:v=!"
for /f "tokens=1-3 delims=." %%a in ("%~2") do (
    set "current_major=%%a"
    set "current_minor=%%b"
    set "current_patch=%%c"
)
set "current_major=!current_major:v=!"
for /f "tokens=1 delims=-" %%a in ("!current_patch!") do set "current_patch=%%a"
if !candidate_major! lss !current_major! exit /b 0
if !candidate_major! gtr !current_major! exit /b 1
if !candidate_minor! lss !current_minor! exit /b 0
if !candidate_minor! gtr !current_minor! exit /b 1
if !candidate_patch! lss !current_patch! exit /b 0
exit /b 1

:is_newer_stable
for /f "tokens=1-3 delims=." %%a in ("%~1") do (
    set "candidate_major=%%a"
    set "candidate_minor=%%b"
    set "candidate_patch=%%c"
)
set "candidate_major=!candidate_major:v=!"
for /f "tokens=1-3 delims=." %%a in ("%~2") do (
    set "current_major=%%a"
    set "current_minor=%%b"
    set "current_patch=%%c"
)
set "current_major=!current_major:v=!"
set "current_rc=0"
if not "!current_patch!"=="!current_patch:-rc.=!" set "current_rc=1"
for /f "tokens=1 delims=-" %%a in ("!current_patch!") do set "current_patch=%%a"
if !candidate_major! gtr !current_major! exit /b 0
if !candidate_major! lss !current_major! exit /b 1
if !candidate_minor! gtr !current_minor! exit /b 0
if !candidate_minor! lss !current_minor! exit /b 1
if !candidate_patch! gtr !current_patch! exit /b 0
if !candidate_patch! equ !current_patch! if !current_rc! equ 1 exit /b 0
exit /b 1

:usage
echo Usage: update.bat [--version vX.Y.Z[-rc.N]]
exit /b 1
