#!/bin/bash

# Catalyst CLI Enhanced Version Bump Script
# Supports semantic versioning with automatic calculation
# Integrates with GitHub Actions workflows

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════╗"
    echo "║         Catalyst CLI Version Manager       ║"
    echo "║           Enhanced Bump Script             ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Get project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Show usage
show_usage() {
    echo "Catalyst CLI Enhanced Version Bump Script"
    echo ""
    echo "Usage: $0 [OPTIONS] <VERSION_TYPE_OR_VERSION>"
    echo ""
    echo "VERSION_TYPE:"
    echo "  major       Increment major version (1.0.0 -> 2.0.0)"
    echo "  minor       Increment minor version (1.0.0 -> 1.1.0)"
    echo "  patch       Increment patch version (1.0.0 -> 1.0.1)"
    echo "  <version>   Set specific version (e.g., 2.1.0, 1.0.0-beta.1)"
    echo ""
    echo "OPTIONS:"
    echo "  --dry-run           Show what would be changed without making changes"
    echo "  --no-changelog      Skip CHANGELOG.md update"
    echo "  --no-commit         Skip creating git commit"
    echo "  --no-tag            Skip creating git tag"
    echo "  --push              Push commit and tag to origin"
    echo "  --trigger-release   Push tag to trigger release workflow"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 patch                    # 1.0.0 -> 1.0.1"
    echo "  $0 minor --push             # 1.0.0 -> 1.1.0 and push"
    echo "  $0 major --trigger-release  # 1.0.0 -> 2.0.0 and trigger release"
    echo "  $0 2.0.0-beta.1 --dry-run  # Preview custom version changes"
    echo ""
    echo "INTEGRATION:"
    echo "  This script works with GitHub Actions workflows:"
    echo "  • Use 'version-bump.yml' for automated PR-based updates"
    echo "  • Use 'release.yml' for automated releases"
}

# Get current version from CatalystCLI.swift
get_current_version() {
    local cli_file="$PROJECT_DIR/Sources/CatalystCLI/CatalystCLI.swift"

    if [[ ! -f "$cli_file" ]]; then
        log_error "CatalystCLI.swift not found at $cli_file"
    fi

    local version
    version=$(grep 'version:' "$cli_file" | sed 's/.*version: "\([^"]*\)".*/\1/')

    if [[ -z "$version" ]]; then
        log_error "Could not extract version from $cli_file"
    fi

    echo "$version"
}

# Parse semantic version
parse_version() {
    local version="$1"

    # Remove 'v' prefix if present
    version="${version#v}"

    # Split version parts
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-.*)?$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} ${BASH_REMATCH[4]}"
    else
        log_error "Invalid semantic version format: $version"
    fi
}

# Calculate new version based on type
calculate_new_version() {
    local current_version="$1"
    local bump_type="$2"

    read -r major minor patch prerelease <<< "$(parse_version "$current_version")"

    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            prerelease=""
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            prerelease=""
            ;;
        patch)
            patch=$((patch + 1))
            prerelease=""
            ;;
        *)
            log_error "Invalid bump type: $bump_type"
            ;;
    esac

    echo "${major}.${minor}.${patch}${prerelease}"
}

# Validate version format
validate_version() {
    local version="$1"

    # Remove 'v' prefix if present
    version="${version#v}"

    # Check semantic version format
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\.-]+)?$ ]]; then
        log_error "Invalid version format: $version. Use semantic versioning (e.g., 1.0.0, 2.1.0-beta.1)"
    fi

    echo "$version"
}

# Update version in CatalystCLI.swift
update_cli_version() {
    local new_version="$1"
    local dry_run="$2"
    local cli_file="$PROJECT_DIR/Sources/CatalystCLI/CatalystCLI.swift"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would update version in CatalystCLI.swift to: $new_version"
        return
    fi

    log_info "Updating version in CatalystCLI.swift..."

    # Create backup
    cp "$cli_file" "$cli_file.backup"

    # Update version
    sed -i '' "s/version: \"[^\"]*\"/version: \"$new_version\"/" "$cli_file"

    # Verify change was made
    if grep -q "version: \"$new_version\"" "$cli_file"; then
        log_success "Updated CatalystCLI.swift version to $new_version"
        rm "$cli_file.backup"
    else
        log_error "Failed to update version in CatalystCLI.swift"
        mv "$cli_file.backup" "$cli_file"
    fi
}

# Update CHANGELOG.md
update_changelog() {
    local new_version="$1"
    local dry_run="$2"
    local skip_changelog="$3"
    local changelog_file="$PROJECT_DIR/CHANGELOG.md"
    local date
    date=$(date +%Y-%m-%d)

    if [[ "$skip_changelog" == "true" ]]; then
        log_warning "Skipping CHANGELOG.md update"
        return
    fi

    if [[ ! -f "$changelog_file" ]]; then
        log_warning "CHANGELOG.md not found, skipping changelog update"
        return
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would update CHANGELOG.md with version: $new_version"
        return
    fi

    log_info "Updating CHANGELOG.md..."

    # Create backup
    cp "$changelog_file" "$changelog_file.backup"

    # Create new changelog content
    {
        # Keep header until [Unreleased]
        sed -n '1,/^## \[Unreleased\]/p' "$changelog_file"

        # Add new version section
        echo ""
        echo "## [$new_version] - $date"
        echo ""
        echo "### Added"
        echo "- New features and enhancements"
        echo ""
        echo "### Changed"
        echo "- Modified functionality"
        echo ""
        echo "### Fixed"
        echo "- Bug fixes"
        echo ""

        # Add rest of file
        sed -n '/^## \[/,$p' "$changelog_file" | sed '1d'
    } > "$changelog_file.tmp"

    mv "$changelog_file.tmp" "$changelog_file"
    rm "$changelog_file.backup"

    log_success "Updated CHANGELOG.md with version $new_version"
}

# Create git commit
create_commit() {
    local new_version="$1"
    local dry_run="$2"
    local skip_commit="$3"

    if [[ "$skip_commit" == "true" ]]; then
        log_warning "Skipping git commit creation"
        return
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would create git commit for version: $new_version"
        return
    fi

    # Check if there are changes to commit
    if git diff --quiet; then
        log_warning "No changes to commit"
        return
    fi

    log_info "Creating git commit..."

    git add -A
    git commit -m "Bump version to $new_version

- Updated version in CatalystCLI.swift
- Updated CHANGELOG.md with new version section"

    log_success "Created git commit for version $new_version"
}

# Create git tag
create_tag() {
    local new_version="$1"
    local dry_run="$2"
    local skip_tag="$3"
    local tag_name="v$new_version"

    if [[ "$skip_tag" == "true" ]]; then
        log_warning "Skipping git tag creation"
        return
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would create git tag: $tag_name"
        return
    fi

    # Check if tag already exists
    if git tag -l | grep -q "^$tag_name$"; then
        log_error "Tag $tag_name already exists"
    fi

    log_info "Creating git tag: $tag_name"
    git tag "$tag_name"
    log_success "Created git tag: $tag_name"
}

# Push changes
push_changes() {
    local new_version="$1"
    local dry_run="$2"
    local should_push="$3"
    local trigger_release="$4"
    local tag_name="v$new_version"

    if [[ "$should_push" != "true" && "$trigger_release" != "true" ]]; then
        return
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would push changes to origin"
        if [[ "$trigger_release" == "true" ]]; then
            log_info "[DRY RUN] Would trigger release by pushing tag: $tag_name"
        fi
        return
    fi

    log_info "Pushing changes to origin..."
    git push origin main

    if [[ "$trigger_release" == "true" ]]; then
        log_info "Pushing tag to trigger release: $tag_name"
        git push origin "$tag_name"
        log_success "🚀 Release workflow triggered! Check GitHub Actions for progress."
    elif git tag -l | grep -q "^$tag_name$"; then
        git push origin "$tag_name"
    fi

    log_success "Pushed changes to origin"
}

# Show summary of changes
show_summary() {
    local current_version="$1"
    local new_version="$2"
    local dry_run="$3"
    local changes_made="$4"

    echo ""
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${BLUE}🔍 DRY RUN SUMMARY${NC}"
    else
        log_success "🎉 Version bump completed!"
    fi

    echo ""
    echo -e "${CYAN}Version Change:${NC} $current_version → $new_version"
    echo ""

    if [[ "$dry_run" == "true" ]]; then
        echo -e "${CYAN}Changes that would be made:${NC}"
    else
        echo -e "${CYAN}Changes made:${NC}"
    fi

    if [[ "$changes_made" == *"cli"* ]]; then
        echo "  📝 Sources/CatalystCLI/CatalystCLI.swift"
    fi
    if [[ "$changes_made" == *"changelog"* ]]; then
        echo "  📝 CHANGELOG.md"
    fi
    if [[ "$changes_made" == *"commit"* ]]; then
        echo "  📦 Git commit created"
    fi
    if [[ "$changes_made" == *"tag"* ]]; then
        echo "  🏷️  Git tag created: v$new_version"
    fi
    if [[ "$changes_made" == *"push"* ]]; then
        echo "  🚀 Changes pushed to origin"
    fi

    if [[ "$dry_run" != "true" ]]; then
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo "  • Review CHANGELOG.md and add specific changes"
        echo "  • Test the build: swift build"
        echo "  • Push tag for release: git push origin v$new_version"
        echo ""
        echo -e "${BLUE}GitHub Actions Integration:${NC}"
        echo "  • Use \`gh workflow run version-bump.yml\` for automated PR workflow"
        echo "  • Push tags to trigger automated releases"
    fi
}

# Main function
main() {
    local input=""
    local dry_run=false
    local skip_changelog=false
    local skip_commit=false
    local skip_tag=false
    local should_push=false
    local trigger_release=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --no-changelog)
                skip_changelog=true
                shift
                ;;
            --no-commit)
                skip_commit=true
                shift
                ;;
            --no-tag)
                skip_tag=true
                shift
                ;;
            --push)
                should_push=true
                shift
                ;;
            --trigger-release)
                trigger_release=true
                should_push=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1. Use --help for usage information."
                ;;
            *)
                if [[ -z "$input" ]]; then
                    input="$1"
                else
                    log_error "Multiple version arguments provided. Use --help for usage."
                fi
                shift
                ;;
        esac
    done

    # Check if input is provided
    if [[ -z "$input" ]]; then
        show_usage
        exit 1
    fi

    print_banner

    # Change to project directory
    cd "$PROJECT_DIR"

    # Get current version
    local current_version
    current_version=$(get_current_version)
    log_info "Current version: $current_version"

    # Calculate or validate new version
    local new_version
    if [[ "$input" =~ ^(major|minor|patch)$ ]]; then
        new_version=$(calculate_new_version "$current_version" "$input")
        log_info "Calculating $input version bump: $new_version"
    else
        new_version=$(validate_version "$input")
        log_info "Using specified version: $new_version"
    fi

    # Check if version is actually changing
    if [[ "$current_version" == "$new_version" ]]; then
        log_warning "Version is already $new_version, no changes needed"
        exit 0
    fi

    # Confirm with user (skip in dry run)
    if [[ "$dry_run" != "true" ]]; then
        echo -n "Update version from $current_version to $new_version? (y/N): "
        read -r confirmation

        if [[ "$confirmation" != "y" && "$confirmation" != "Y" && "$confirmation" != "yes" ]]; then
            log_info "Version update cancelled"
            exit 0
        fi
    fi

    # Track changes for summary
    local changes_made=""

    # Perform updates
    update_cli_version "$new_version" "$dry_run"
    changes_made+="cli "

    if [[ "$skip_changelog" != "true" ]]; then
        update_changelog "$new_version" "$dry_run" "$skip_changelog"
        changes_made+="changelog "
    fi

    if [[ "$skip_commit" != "true" ]]; then
        create_commit "$new_version" "$dry_run" "$skip_commit"
        changes_made+="commit "
    fi

    if [[ "$skip_tag" != "true" ]]; then
        create_tag "$new_version" "$dry_run" "$skip_tag"
        changes_made+="tag "
    fi

    if [[ "$should_push" == "true" || "$trigger_release" == "true" ]]; then
        push_changes "$new_version" "$dry_run" "$should_push" "$trigger_release"
        changes_made+="push "
    fi

    # Show summary
    show_summary "$current_version" "$new_version" "$dry_run" "$changes_made"
}

# Run main function
main "$@"