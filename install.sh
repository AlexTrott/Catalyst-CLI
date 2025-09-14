#!/bin/bash

set -e

# Catalyst CLI Installation Script
# This script downloads and installs the latest Catalyst CLI binary

# Configuration
BINARY_NAME="catalyst"
REPO_OWNER="alextrott"  # Update with your GitHub username/org
REPO_NAME="Catalyst-CLI"
GITHUB_REPO="${REPO_OWNER}/${REPO_NAME}"
INSTALL_DIR="/usr/local/bin"
USER_INSTALL_DIR="$HOME/.local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
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

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════╗"
    echo "║        Catalyst CLI Installation           ║"
    echo "║    🚀 Swift CLI for iOS Module Generation  ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Detect architecture
detect_arch() {
    local arch
    arch=$(uname -m)
    case $arch in
        arm64|aarch64)
            echo "arm64-apple-macos"
            ;;
        x86_64|amd64)
            echo "x86_64-apple-macos"
            ;;
        *)
            log_error "Unsupported architecture: $arch. Catalyst CLI only supports macOS on Intel and Apple Silicon."
            ;;
    esac
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script only supports macOS. Catalyst CLI requires macOS 15.0+."
    fi

    # Check macOS version
    local os_version
    os_version=$(sw_vers -productVersion)
    local major_version
    major_version=$(echo "$os_version" | cut -d '.' -f 1)

    if [[ $major_version -lt 15 ]]; then
        log_error "Catalyst CLI requires macOS 15.0+. Your version: $os_version"
    fi

    log_info "Detected macOS $os_version"
}

# Get latest release version or use provided version
get_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        log_info "Fetching latest release version..."
        version=$(curl -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

        if [[ -z "$version" ]]; then
            log_error "Failed to fetch latest version. Please check your internet connection or specify a version manually."
        fi
    fi

    log_info "Target version: $version"
    echo "$version"
}

# Download and verify binary
download_binary() {
    local version="$1"
    local arch="$2"
    local temp_dir
    temp_dir=$(mktemp -d)

    local filename="${BINARY_NAME}-${version}-${arch}.tar.gz"
    local checksum_filename="${filename}.sha256"
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/${version}/${filename}"
    local checksum_url="https://github.com/${GITHUB_REPO}/releases/download/${version}/${checksum_filename}"

    log_info "Downloading $filename..."

    # Download binary tarball
    if ! curl -L -o "${temp_dir}/${filename}" "$download_url"; then
        log_error "Failed to download binary from $download_url"
    fi

    # Download checksum
    if ! curl -L -o "${temp_dir}/${checksum_filename}" "$checksum_url"; then
        log_error "Failed to download checksum from $checksum_url"
    fi

    # Verify checksum
    log_info "Verifying checksum..."
    cd "$temp_dir"
    if ! shasum -a 256 -c "$checksum_filename"; then
        log_error "Checksum verification failed. The download may be corrupted."
    fi

    # Extract binary
    log_info "Extracting binary..."
    if ! tar -xzf "$filename"; then
        log_error "Failed to extract binary archive"
    fi

    if [[ ! -f "${temp_dir}/${BINARY_NAME}" ]]; then
        log_error "Binary not found in archive"
    fi

    echo "$temp_dir"
}

# Determine install directory
get_install_dir() {
    local custom_prefix="$1"

    if [[ -n "$custom_prefix" ]]; then
        echo "$custom_prefix/bin"
        return
    fi

    # Try /usr/local/bin first, fallback to user directory
    if [[ -w "$INSTALL_DIR" ]] || [[ $(id -u) -eq 0 ]]; then
        echo "$INSTALL_DIR"
    else
        log_warning "/usr/local/bin is not writable. Installing to user directory: $USER_INSTALL_DIR"
        mkdir -p "$USER_INSTALL_DIR"
        echo "$USER_INSTALL_DIR"
    fi
}

# Install binary
install_binary() {
    local temp_dir="$1"
    local install_dir="$2"
    local target_path="${install_dir}/${BINARY_NAME}"

    # Backup existing installation
    if [[ -f "$target_path" ]]; then
        local backup_path="${target_path}.backup.$(date +%s)"
        log_warning "Backing up existing installation to $backup_path"
        cp "$target_path" "$backup_path"
    fi

    # Install binary
    log_info "Installing to $target_path..."

    if [[ "$install_dir" == "$INSTALL_DIR" ]] && [[ ! -w "$install_dir" ]]; then
        # Need sudo for system installation
        sudo cp "${temp_dir}/${BINARY_NAME}" "$target_path"
        sudo chmod +x "$target_path"
    else
        # User installation or writable system directory
        cp "${temp_dir}/${BINARY_NAME}" "$target_path"
        chmod +x "$target_path"
    fi

    # Cleanup
    rm -rf "$temp_dir"

    log_success "Binary installed successfully!"
}

# Update shell configuration
update_shell_config() {
    local install_dir="$1"

    # Skip if installing to system path
    if [[ "$install_dir" == "$INSTALL_DIR" ]]; then
        return
    fi

    # Update PATH in shell config files
    local shell_configs=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc")
    local path_export="export PATH=\"$install_dir:\$PATH\""

    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]] && ! grep -q "$install_dir" "$config_file"; then
            echo "" >> "$config_file"
            echo "# Added by Catalyst CLI installer" >> "$config_file"
            echo "$path_export" >> "$config_file"
            log_info "Updated $config_file"
        fi
    done

    # Export for current session
    export PATH="$install_dir:$PATH"
    log_info "Updated PATH for current session"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."

    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        local version
        version=$($BINARY_NAME --version 2>/dev/null | head -1 || echo "Unable to get version")
        log_success "Installation successful! $version"

        log_info "Running environment check..."
        "$BINARY_NAME" doctor
    else
        log_error "Installation failed. Binary not found in PATH."
    fi
}

# Print next steps
print_next_steps() {
    local install_dir="$1"

    echo ""
    log_success "🎉 Catalyst CLI is ready to use!"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"

    if [[ "$install_dir" != "$INSTALL_DIR" ]]; then
        echo "  1. Restart your terminal or run: source ~/.zshrc (or ~/.bashrc)"
    fi

    echo "  2. Get started: catalyst --help"
    echo "  3. Create your first module: catalyst new core MyCore"
    echo "  4. Install git hooks: catalyst install git-message"
    echo ""
    echo -e "${BLUE}📚 Documentation: https://github.com/${GITHUB_REPO}${NC}"
}

# Main installation function
main() {
    local version=""
    local custom_prefix=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prefix=*)
                custom_prefix="${1#*=}"
                shift
                ;;
            --prefix)
                custom_prefix="$2"
                shift 2
                ;;
            -v|--version)
                version="$2"
                shift 2
                ;;
            -h|--help)
                echo "Catalyst CLI Installation Script"
                echo ""
                echo "Usage: $0 [OPTIONS] [VERSION]"
                echo ""
                echo "Options:"
                echo "  --prefix PATH    Install to custom prefix (default: /usr/local or ~/.local)"
                echo "  -v, --version    Install specific version"
                echo "  -h, --help       Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                           # Install latest version"
                echo "  $0 v1.0.0                   # Install specific version"
                echo "  $0 --prefix=/opt/catalyst    # Install to custom prefix"
                exit 0
                ;;
            *)
                # Assume it's a version if it doesn't start with --
                if [[ "$1" != --* ]]; then
                    version="$1"
                fi
                shift
                ;;
        esac
    done

    print_banner

    # Detect system
    detect_os
    local arch
    arch=$(detect_arch)

    # Get version and install directory
    version=$(get_version "$version")
    local install_dir
    install_dir=$(get_install_dir "$custom_prefix")

    # Download and install
    local temp_dir
    temp_dir=$(download_binary "$version" "$arch")
    install_binary "$temp_dir" "$install_dir"

    # Update shell configuration if needed
    update_shell_config "$install_dir"

    # Verify and provide next steps
    verify_installation
    print_next_steps "$install_dir"
}

# Run main function with all arguments
main "$@"