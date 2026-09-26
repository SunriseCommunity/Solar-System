set -e

cd "$SCRIPT_DIR"

print_info() { printf 'ℹ %s\n' "$1"; }
print_error() { printf '✗ %s\n' "$1" >&2; }

is_version_tag() {
    [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$ ]]
}

is_stable_tag() {
    [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

is_older_stable() {
    local candidate="${1#v}" current="${2#v}"
    local a b c x y z
    IFS=. read -r a b c <<< "$candidate"
    IFS=. read -r x y z <<< "${current%%-rc.*}"
    (( 10#$a < 10#$x || (10#$a == 10#$x && 10#$b < 10#$y) || (10#$a == 10#$x && 10#$b == 10#$y && 10#$c < 10#$z) ))
}

is_newer_stable() {
    local candidate="${1#v}" current="${2#v}"
    local a b c x y z
    IFS=. read -r a b c <<< "$candidate"
    IFS=. read -r x y z <<< "${current%%-rc.*}"
    (( 10#$a > 10#$x || (10#$a == 10#$x && 10#$b > 10#$y) || (10#$a == 10#$x && 10#$b == 10#$y && 10#$c > 10#$z) )) || { [[ "$2" == *-rc.* && "$candidate" == "${current%%-rc.*}" ]]; }
}

choose_tag() {
    local prompt="$1" choice
    shift
    local tags=("$@")
    if [ "${#tags[@]}" -eq 0 ]; then
        print_info "No versions available for this option."
        return 1
    fi
    for (( i=0; i<${#tags[@]}; i++ )); do
        printf '%d) %s\n' "$((i+1))" "${tags[i]}"
    done
    read -r -p "$prompt (number, or 0 to cancel): " choice || return 1
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#tags[@]} )); then
        print_info "Cancelled."
        return 1
    fi
    TARGET_TAG="${tags[choice-1]}"
}

if [ "$#" -gt 0 ] && { [ "$#" -ne 2 ] || [ "$1" != "--version" ]; }; then
    print_error "Usage: $0 [--version vX.Y.Z[-rc.N]]"
    exit 1
fi

print_info "Fetching release tags..."
git fetch --tags origin

CURRENT_TAG=$(git describe --tags --abbrev=0 HEAD 2>/dev/null || true)
if ! is_version_tag "$CURRENT_TAG"; then
    CURRENT_TAG=""
fi
print_info "Current version: ${CURRENT_TAG:-untagged checkout}"

ALL_TAGS=()
STABLE_TAGS=()
while IFS= read -r tag; do
    if is_version_tag "$tag"; then
        ALL_TAGS+=("$tag")
        if is_stable_tag "$tag"; then
            STABLE_TAGS+=("$tag")
        fi
    fi
done < <(git tag -l 'v*' | sort -V)

LATEST_STABLE=""
if [ "${#STABLE_TAGS[@]}" -gt 0 ]; then
    LATEST_STABLE="${STABLE_TAGS[${#STABLE_TAGS[@]}-1]}"
fi
print_info "Latest stable: ${LATEST_STABLE:-none} (release candidates require explicit selection)"

TARGET_TAG=""
if [ "$#" -eq 2 ]; then
    TARGET_TAG="$2"
    if ! is_version_tag "$TARGET_TAG" || ! git show-ref --verify --quiet "refs/tags/$TARGET_TAG"; then
        print_error "Unknown release tag: $TARGET_TAG"
        exit 1
    fi
else
    printf '1) Update to latest stable\n2) Choose a version (including release candidates)\n3) Roll back to an older stable version\n4) Cancel\n'
    read -r -p "Select an option [1]: " option || exit 1
    case "${option:-1}" in
        1)
            if [ -n "$CURRENT_TAG" ] && [ -n "$LATEST_STABLE" ] && ! is_newer_stable "$LATEST_STABLE" "$CURRENT_TAG"; then
                print_info "No newer stable release is available. Choose a version explicitly to switch."
                exit 0
            fi
            TARGET_TAG="$LATEST_STABLE"
            ;;
        2) choose_tag "Choose a version" "${ALL_TAGS[@]}" || exit 0 ;;
        3)
            if [ -z "$CURRENT_TAG" ]; then
                print_error "Cannot identify the current version for rollback. Choose a version explicitly instead."
                exit 1
            fi
            OLDER_TAGS=()
            for tag in "${STABLE_TAGS[@]}"; do
                if is_older_stable "$tag" "$CURRENT_TAG"; then
                    OLDER_TAGS+=("$tag")
                fi
            done
            choose_tag "Roll back to" "${OLDER_TAGS[@]}" || exit 0
            ;;
        4) exit 0 ;;
        *) print_error "Invalid option"; exit 1 ;;
    esac
fi

if [ -z "$TARGET_TAG" ]; then
    print_info "No stable release is available."
    exit 0
fi
if [ "$TARGET_TAG" = "$CURRENT_TAG" ] && git describe --tags --exact-match HEAD 2>/dev/null | grep -qx "$TARGET_TAG"; then
    print_info "Already on $TARGET_TAG."
    exit 0
fi

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    print_error "The checkout has uncommitted changes. Save them before switching versions."
    exit 1
fi

print_info "Selected $TARGET_TAG: https://github.com/SunriseCommunity/Solar-System/releases/tag/$TARGET_TAG"
read -r -p "Switch to $TARGET_TAG? (yes/no): " confirm || exit 1
case "$confirm" in
    [Yy]|[Yy][Ee][Ss]) ;;
    *) print_info "Cancelled."; exit 0 ;;
esac

git -c advice.detachedHead=false checkout --detach "$TARGET_TAG"
git submodule update --init --recursive
print_info "Now on $TARGET_TAG."

read -r -p "Rebuild Docker containers using $COMPOSE_FILE? (yes/no): " rebuild || exit 0
case "$rebuild" in
    [Yy]|[Yy][Ee][Ss])
        if docker compose version >/dev/null 2>&1; then
            docker compose -f "$COMPOSE_FILE" up -d --build
        elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose -f "$COMPOSE_FILE" up -d --build
        else
            print_error "Docker Compose is unavailable; the checkout changed but containers were not rebuilt."
            exit 1
        fi
        print_info "Containers rebuilt using $TARGET_TAG."
        ;;
    *) print_info "Containers were not rebuilt." ;;
esac
