#!/bin/bash

# Catalyst CLI Release Build Script
# This script builds release binaries for local testing or manual distribution

set -e

# Configuration
BINARY_NAME="catalyst"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
RELEASE_DIR="$PROJECT_DIR/release"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
    echo "║           Catalyst CLI Builder             ║"
    echo "║         Release Binary Creation            ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Get version from git tag or prompt user
get_version() {
    local version

    # Try to get version from git tag
    if git describe --tags --exact-match HEAD 2>/dev/null; then
        version=$(git describe --tags --exact-match HEAD 2>/dev/null)
        log_info "Using git tag version: $version"
    else
        # Prompt user for version
        echo -n "Enter version (e.g., v1.0.0): "
        read -r version

        if [[ -z "$version" ]]; then
            log_error "Version is required"
        fi

        # Add 'v' prefix if not present
        if [[ ! "$version" =~ ^v ]]; then
            version="v$version"
        fi

        log_warning "Using manual version: $version (consider tagging: git tag $version)"
    fi

    echo "$version"
}

# Validate Swift environment
validate_environment() {
    log_info "Validating build environment..."

    # Check Swift version
    if ! command -v swift >/dev/null 2>&1; then
        log_error "Swift is not installed. Please install Xcode Command Line Tools."
    fi

    local swift_version
    swift_version=$(swift --version | head -1)
    log_info "Swift version: $swift_version"

    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_DIR/Package.swift" ]]; then
        log_error "Package.swift not found. Please run this script from the project root."
    fi

    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        log_warning "Git not found. Version detection may not work correctly."
    fi
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    rm -rf "$BUILD_DIR"
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
}

# Build for specific architecture
build_architecture() {
    local arch="$1"
    local target="$2"

    log_info "Building for $arch ($target)..."

    # Build the binary
    swift build -c release --arch "$arch"

    # Verify binary was created
    local binary_path="$BUILD_DIR/$target/release/$BINARY_NAME"
    if [[ ! -f "$binary_path" ]]; then
        log_error "Failed to build binary for $arch"
    fi

    # Get binary info
    local binary_size
    binary_size=$(du -h "$binary_path" | cut -f1)
    log_info "Built binary: $binary_size ($binary_path)"

    echo "$binary_path"
}

# Create release archive
create_archive() {
    local binary_path="$1"
    local version="$2"
    local arch="$3"
    local target="$4"

    local filename="${BINARY_NAME}-${version}-${target}.tar.gz"
    local archive_path="$RELEASE_DIR/$filename"

    log_info "Creating archive: $filename"

    # Copy binary to release directory with standard name
    cp "$binary_path" "$RELEASE_DIR/$BINARY_NAME"

    # Create tarball
    cd "$RELEASE_DIR"
    tar -czf "$filename" "$BINARY_NAME"

    # Generate checksum
    shasum -a 256 "$filename" > "$filename.sha256"

    # Clean up temporary binary
    rm "$BINARY_NAME"

    # Get archive info
    local archive_size
    archive_size=$(du -h "$archive_path" | cut -f1)
    log_success "Created archive: $archive_size ($archive_path)"

    cd "$PROJECT_DIR"
}

# Test binary functionality
test_binary() {
    local binary_path="$1"

    log_info "Testing binary functionality..."

    # Test version command
    if ! "$binary_path" --version >/dev/null 2>&1; then
        log_error "Binary failed version test"
    fi

    # Test help command
    if ! "$binary_path" --help >/dev/null 2>&1; then
        log_error "Binary failed help test"
    fi

    log_success "Binary passed basic functionality tests"
}

# Show build summary
show_summary() {
    local version="$1"

    echo ""
    log_success "🎉 Release build completed!"
    echo ""
    echo -e "${CYAN}Release Summary:${NC}"
    echo "  Version: $version"
    echo "  Location: $RELEASE_DIR"
    echo ""

    log_info "Generated files:"
    cd "$RELEASE_DIR"
    for file in *.tar.gz*; do
        if [[ -f "$file" ]]; then
            local size
            size=$(du -h "$file" | cut -f1)
            echo "  📦 $file ($size)"
        fi
    done
    cd "$PROJECT_DIR"

    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  • Test archives with: tar -tzf release/*.tar.gz"
    echo "  • Create git tag: git tag $version && git push origin $version"
    echo "  • Publish to GitHub: Upload files to GitHub releases"
    echo "  • Test installation: ./install.sh $version"
}

# Main build function
main() {
    local build_archs=()
    local version=""
    local clean=true
    local test=true

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --arch)
                case $2 in
                    arm64)
                        build_archs+=("arm64:arm64-apple-macos")
                        ;;
                    x86_64)
                        build_archs+=("x86_64:x86_64-apple-macos")
                        ;;
                    all)
                        build_archs+=("arm64:arm64-apple-macos" "x86_64:x86_64-apple-macos")
                        ;;
                    *)
                        log_error "Unsupported architecture: $2. Use arm64, x86_64, or all"
                        ;;
                esac
                shift 2
                ;;
            --version)
                version="$2"
                shift 2
                ;;
            --no-clean)
                clean=false
                shift
                ;;
            --no-test)
                test=false
                shift
                ;;
            -h|--help)
                echo "Catalyst CLI Release Build Script"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --arch ARCH      Build for specific architecture (arm64, x86_64, all)"
                echo "                   Default: current architecture"
                echo "  --version VER    Use specific version (default: auto-detect from git)"
                echo "  --no-clean       Don't clean build directory"
                echo "  --no-test        Skip binary functionality tests"
                echo "  -h, --help       Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                      # Build for current architecture"
                echo "  $0 --arch all           # Build for all architectures"
                echo "  $0 --version v1.0.0     # Build with specific version"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done

    print_banner

    # Set defaults
    if [[ ${#build_archs[@]} -eq 0 ]]; then
        # Default to current architecture
        local current_arch
        current_arch=$(uname -m)
        case $current_arch in
            arm64)
                build_archs+=("arm64:arm64-apple-macos")
                ;;
            x86_64)
                build_archs+=("x86_64:x86_64-apple-macos")
                ;;
            *)
                log_error "Unsupported current architecture: $current_arch"
                ;;
        esac
    fi

    # Get version
    if [[ -z "$version" ]]; then
        version=$(get_version)
    fi

    # Validate environment
    validate_environment

    # Clean if requested
    if [[ "$clean" == true ]]; then
        clean_build
    fi

    # Build for each architecture
    for arch_target in "${build_archs[@]}"; do
        IFS=':' read -ra PARTS <<< "$arch_target"
        local arch="${PARTS[0]}"
        local target="${PARTS[1]}"

        local binary_path
        binary_path=$(build_architecture "$arch" "$target")

        if [[ "$test" == true ]]; then
            test_binary "$binary_path"
        fi

        create_archive "$binary_path" "$version" "$arch" "$target"
    done

    # Show summary
    show_summary "$version"
}

# Change to project directory
cd "$PROJECT_DIR"

# Run main function with all arguments
main "$@"