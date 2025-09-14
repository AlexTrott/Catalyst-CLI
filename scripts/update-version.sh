#!/bin/bash

# Catalyst CLI Version Update Script
# Updates version across all relevant files

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Get project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Show usage
show_usage() {
    echo "Catalyst CLI Version Update Script"
    echo ""
    echo "Usage: $0 <new_version>"
    echo ""
    echo "Examples:"
    echo "  $0 1.1.0           # Update to version 1.1.0"
    echo "  $0 v2.0.0-beta.1   # Update to pre-release version"
    echo ""
    echo "This script will:"
    echo "  • Update version in CatalystCLI.swift"
    echo "  • Update CHANGELOG.md with new version section"
    echo "  • Show files that were modified"
}

# Validate version format
validate_version() {
    local version="$1"

    # Remove 'v' prefix if present
    version="${version#v}"

    # Check semantic version format
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9\.-]+)?$ ]]; then
        log_error "Invalid version format. Use semantic versioning (e.g., 1.0.0, 2.1.0-beta.1)"
    fi

    echo "$version"
}

# Update version in CatalystCLI.swift
update_cli_version() {
    local new_version="$1"
    local cli_file="$PROJECT_DIR/Sources/CatalystCLI/CatalystCLI.swift"

    if [[ ! -f "$cli_file" ]]; then
        log_error "CatalystCLI.swift not found at $cli_file"
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
    local changelog_file="$PROJECT_DIR/CHANGELOG.md"
    local date
    date=$(date +%Y-%m-%d)

    if [[ ! -f "$changelog_file" ]]; then
        log_warning "CHANGELOG.md not found, skipping changelog update"
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

        # Add rest of file, but update the links at the bottom
        sed -n '/^## \[/,$p' "$changelog_file" | sed '1d'
    } > "$changelog_file.tmp"

    # Update version links at bottom
    local repo_url="https://github.com/alextrott/Catalyst-CLI"
    sed -i '' "s|\[Unreleased\]: .*|\[Unreleased\]: $repo_url/compare/v$new_version...HEAD|" "$changelog_file.tmp"

    # Add new version link
    echo "[$new_version]: $repo_url/releases/tag/v$new_version" >> "$changelog_file.tmp"

    mv "$changelog_file.tmp" "$changelog_file"
    rm "$changelog_file.backup"

    log_success "Updated CHANGELOG.md with version $new_version"
}

# Show summary of changes
show_summary() {
    local new_version="$1"

    echo ""
    log_success "🎉 Version updated to $new_version!"
    echo ""

    log_info "Modified files:"
    echo "  📝 Sources/CatalystCLI/CatalystCLI.swift"
    echo "  📝 CHANGELOG.md"

    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Review and edit CHANGELOG.md to add specific changes"
    echo "  2. Test the build: swift build"
    echo "  3. Commit changes: git add -A && git commit -m 'Bump version to $new_version'"
    echo "  4. Create tag: git tag v$new_version"
    echo "  5. Push: git push origin main --tags"
    echo ""
    echo -e "${YELLOW}Note: Edit CHANGELOG.md to add your actual changes before committing!${NC}"
}

# Main function
main() {
    if [[ $# -ne 1 ]]; then
        show_usage
        exit 1
    fi

    local input_version="$1"

    # Handle help
    if [[ "$input_version" == "-h" || "$input_version" == "--help" ]]; then
        show_usage
        exit 0
    fi

    # Validate and normalize version
    local new_version
    new_version=$(validate_version "$input_version")

    # Change to project directory
    cd "$PROJECT_DIR"

    # Get current version
    local current_version
    current_version=$(grep 'version:' Sources/CatalystCLI/CatalystCLI.swift | sed 's/.*version: "\([^"]*\)".*/\1/')

    log_info "Current version: $current_version"
    log_info "New version: $new_version"

    # Confirm with user
    echo -n "Update version from $current_version to $new_version? (y/N): "
    read -r confirmation

    if [[ "$confirmation" != "y" && "$confirmation" != "Y" && "$confirmation" != "yes" ]]; then
        log_info "Version update cancelled"
        exit 0
    fi

    # Perform updates
    update_cli_version "$new_version"
    update_changelog "$new_version"

    # Show summary
    show_summary "$new_version"
}

# Run main function
main "$@"