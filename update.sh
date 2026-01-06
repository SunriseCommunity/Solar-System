#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/SunriseCommunity/Solar-System"
RELEASES_URL="${REPO_URL}/releases/tag"

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

get_version_parts() {
    local version="${1#v}"
    IFS='.' read -r -a parts <<< "$version"
    echo "${parts[0]} ${parts[1]} ${parts[2]}"
}

is_version_newer() {
    local v1="${1#v}"
    local v2="${2#v}"
    IFS='.' read -r -a v1_parts <<< "$v1"
    IFS='.' read -r -a v2_parts <<< "$v2"
    
    for i in 0 1 2; do
        local num1=${v1_parts[$i]:-0}
        local num2=${v2_parts[$i]:-0}
        [ "$num1" -lt "$num2" ] && return 0
        [ "$num1" -gt "$num2" ] && return 1
    done
    return 1
}

prompt_yes_no() {
    local prompt="$1"
    while true; do
        read -p "$prompt (yes/no): " response
        case "$response" in
            [Yy][Ee][Ss]|[Yy]) return 0 ;;
            [Nn][Oo]|[Nn]) return 1 ;;
            *) print_error "Please answer yes or no" ;;
        esac
    done
}

print_info "Checking repository state..."

CURRENT_COMMIT=$(git rev-parse HEAD)
LATEST_LOCAL_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LATEST_LOCAL_TAG" ]; then
    if ! git ls-remote --tags origin "$LATEST_LOCAL_TAG" | grep -q "$LATEST_LOCAL_TAG"; then
        TAG_COMMIT=$(git rev-list -n 1 "$LATEST_LOCAL_TAG" 2>/dev/null)
        if [ -n "$TAG_COMMIT" ]; then
            if [ "$CURRENT_COMMIT" == "$TAG_COMMIT" ] || git merge-base --is-ancestor "$TAG_COMMIT" "$CURRENT_COMMIT" 2>/dev/null; then
                print_info "Pushing tag $LATEST_LOCAL_TAG to remote..."
                git push origin "$LATEST_LOCAL_TAG" 2>/dev/null || print_warning "Tag push failed or already exists"
            fi
        fi
    fi
fi

print_info "Fetching latest changes..."
git fetch --tags --all

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$CURRENT_BRANCH" != "HEAD" ] && [ -n "$CURRENT_BRANCH" ]; then
    print_info "Pulling changes with submodules..."
    git pull --recurse-submodules || {
        print_error "Failed to pull changes. Please resolve conflicts manually."
        exit 1
    }
else
    print_info "On detached HEAD (tag), skipping pull..."
fi

print_info "Updating submodules..."
git submodule update --init --recursive --remote || print_warning "Some submodules may have failed to update"

ALL_TAGS=($(git tag -l "v*" | sort -V))
CURRENT_TAG=$(git describe --tags --exact-match HEAD 2>/dev/null || git describe --tags --abbrev=0 HEAD 2>/dev/null || echo "")

NEW_TAGS=()
for tag in "${ALL_TAGS[@]}"; do
    if [ -z "$LATEST_LOCAL_TAG" ]; then
        NEW_TAGS+=("$tag")
    elif is_version_newer "$LATEST_LOCAL_TAG" "$tag"; then
        NEW_TAGS+=("$tag")
    fi
done

if [ ${#NEW_TAGS[@]} -eq 0 ]; then
    print_success "No new tags found. You are up to date!"
    exit 0
fi

print_info "New tags found:"
for tag in "${NEW_TAGS[@]}"; do
    echo -e "  ${GREEN}+${NC} ${RELEASES_URL}/${tag} (new tag ${tag#v})"
done

PREVIOUS_TAG="${CURRENT_TAG:-$LATEST_LOCAL_TAG}"
MAJOR_MINOR_TAGS=()

for tag in "${NEW_TAGS[@]}"; do
    if [ -z "$PREVIOUS_TAG" ]; then
        read -r major minor patch <<< "$(get_version_parts "$tag")"
        if [ "$major" -gt 0 ] || [ "$minor" -gt 0 ]; then
            MAJOR_MINOR_TAGS+=("$tag")
        fi
    else
        read -r prev_major prev_minor prev_patch <<< "$(get_version_parts "$PREVIOUS_TAG")"
        read -r curr_major curr_minor curr_patch <<< "$(get_version_parts "$tag")"
        if [ "$curr_major" -gt "$prev_major" ] || [ "$curr_minor" -gt "$prev_minor" ]; then
            MAJOR_MINOR_TAGS+=("$tag")
        fi
    fi
    PREVIOUS_TAG="$tag"
done

for tag in "${MAJOR_MINOR_TAGS[@]}"; do
    read -r major minor patch <<< "$(get_version_parts "$tag")"
    VERSION_TYPE=$([ "$major" -gt 0 ] && echo "major" || echo "minor")
    
    print_warning "The ${VERSION_TYPE} version has updated to ${tag#v}"
    print_info "Please review the changelog: ${RELEASES_URL}/${tag}"
    echo ""
    
    if ! prompt_yes_no "Do you want to continue with this ${VERSION_TYPE} version update?"; then
        print_warning "Skipping ${VERSION_TYPE} version update to ${tag#v}"
        UPDATED_TAGS=()
        SKIP_NEXT=false
        for t in "${NEW_TAGS[@]}"; do
            [ "$t" == "$tag" ] && SKIP_NEXT=true && continue
            [ "$SKIP_NEXT" == true ] && continue
            UPDATED_TAGS+=("$t")
        done
        NEW_TAGS=("${UPDATED_TAGS[@]}")
        [ ${#NEW_TAGS[@]} -eq 0 ] && exit 0
    fi
    echo ""
done

LATEST_TAG="${NEW_TAGS[-1]}"
print_info "Checking out tag: $LATEST_TAG"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
git checkout "$LATEST_TAG" || {
    print_error "Failed to checkout tag $LATEST_TAG"
    exit 1
}

print_info "Updating submodules..."
git submodule update --init --recursive || print_warning "Some submodules may have failed to update"

print_success "Successfully updated to tag $LATEST_TAG"
[ "$CURRENT_BRANCH" != "HEAD" ] && [ "$CURRENT_BRANCH" != "$LATEST_TAG" ] && \
    print_info "Note: You were on branch '$CURRENT_BRANCH', now on tag '$LATEST_TAG' (detached HEAD)"

echo ""
print_info "Update process completed!"
echo ""

if prompt_yes_no "Do you want to rebuild the Docker containers to the newer version?"; then
    print_info "Rebuilding Docker containers..."
    docker compose up -d --build || {
        print_error "Failed to rebuild Docker containers"
        exit 1
    }
    print_success "Docker containers rebuilt successfully!"
else
    print_info "Skipping Docker container rebuild"
fi

print_success "Update script completed successfully!"
