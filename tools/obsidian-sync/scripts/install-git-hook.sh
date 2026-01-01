#!/bin/bash
#
# install-git-hook.sh
# Installs the Git hook for synchronization between Git repository and Obsidian Vault
# Bash version of the PowerShell script
#
# Version: 2.0.3
# Date: 2025-08-26
#

set -euo pipefail

# Default values
SCRIPT_DIR="$(cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" && pwd)"
REPO_PATH="."
CONFIG_PATH=".git-obsidian-sync.json"
MODULE_PATH="${SCRIPT_DIR}/../bin/git-obsidian-sync.sh"
SYNC_SCRIPT_PATH="${SCRIPT_DIR}/sync-repository.sh"

# Helper functions
show_help() {
    cat << EOF
Usage: ${0} [OPTIONS]

Installs the Git hook for synchronization between Git repository and Obsidian Vault.

OPTIONS:
    -r, --repo PATH      Repository path (default: .)
    -c, --config PATH    Configuration file (default: .git-obsidian-sync.json)
    -m, --module PATH    Sync module path (default: ../bin/git-obsidian-sync.sh)
    -s, --script PATH    Sync script path (default: ./sync-repository.sh)
    -h, --help           Show this help

EXAMPLES:
    ${0}                                    # Standard installation
    ${0} -r /path/to/repo                   # Specific repository
    ${0} -c custom-config.json              # Custom configuration

EOF
}

normalize_path() {
    local path="${1}"

    # Convert relative path to absolute
    if [[ ! "${path}" = /* ]]; then
        path="$(pwd)/${path}"
    fi

    # Normalize path
    realpath "${path}" 2>/dev/null || echo "${path}"
}

log() {
    local level="${1}"
    local message="${2}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "${level}" in
        "INFO")
            echo "[${timestamp}] [INFO] ${message}"
            ;;
        "ERROR")
            echo "[${timestamp}] [ERROR] ${message}" >&2
            ;;
    esac
}

# Process parameters
while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -r|--repo)
            REPO_PATH="${2}"
            shift 2
            ;;
        -c|--config)
            CONFIG_PATH="${2}"
            shift 2
            ;;
        -m|--module)
            MODULE_PATH="${2}"
            shift 2
            ;;
        -s|--script)
            SYNC_SCRIPT_PATH="${2}"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: ${1}" >&2
            show_help
            exit 1
            ;;
        *)
            echo "Unexpected parameter: ${1}" >&2
            show_help
            exit 1
            ;;
    esac
done

# Change to repository directory
ORIGINAL_PATH=$(pwd)
if ! cd "${REPO_PATH}" 2>/dev/null; then
    log "ERROR" "Error changing to repository directory: ${REPO_PATH}"
    exit 1
fi

REPO_PATH=$(pwd)

# Normalize paths
CONFIG_PATH=$(normalize_path "${CONFIG_PATH}")
MODULE_PATH=$(normalize_path "${MODULE_PATH}")
SYNC_SCRIPT_PATH=$(normalize_path "${SYNC_SCRIPT_PATH}")

log "INFO" "Repository path: ${REPO_PATH}"
log "INFO" "Configuration file: ${CONFIG_PATH}"
log "INFO" "Sync module: ${MODULE_PATH}"
log "INFO" "Sync script: ${SYNC_SCRIPT_PATH}"

# Check configuration file
if [[ ! -f "${CONFIG_PATH}" ]]; then
    log "ERROR" "Configuration file not found: ${CONFIG_PATH}"
    cd "${ORIGINAL_PATH}"
    exit 1
fi

# Check module file
if [[ ! -f "${MODULE_PATH}" ]]; then
    log "ERROR" "Sync module not found: ${MODULE_PATH}"
    cd "${ORIGINAL_PATH}"
    exit 1
fi

# Check synchronization script
if [[ ! -f "${SYNC_SCRIPT_PATH}" ]]; then
    log "ERROR" "Synchronization script not found: ${SYNC_SCRIPT_PATH}"
    cd "${ORIGINAL_PATH}"
    exit 1
fi

# Check .git directory
if [[ ! -d ".git" ]]; then
    log "ERROR" "Git repository not found: .git"
    cd "${ORIGINAL_PATH}"
    exit 1
fi

# Create hook directory if it doesn't exist
mkdir -p ".git/hooks"

# Create post-commit hook
POST_COMMIT_PATH=".git/hooks/post-commit"

# Create Bash version of post-commit hook
cat > "${POST_COMMIT_PATH}" << EOF
#!/bin/bash
#
# Git Post-Commit Hook for git-obsidian-sync
# Automatically generated on $(date)
#

# Set a sane PATH for Git hooks on Windows
export PATH="\${PATH}:/usr/bin:/bin:/c/Windows/System32"

set -euo pipefail

# Paths
REPO_PATH="${REPO_PATH}"
SYNC_SCRIPT="${SYNC_SCRIPT_PATH}"
CONFIG_PATH="${CONFIG_PATH}"

# Check if sync script exists
if [[ ! -f "\${SYNC_SCRIPT}" ]]; then
    echo "Sync script not found: \${SYNC_SCRIPT}" >&2
    exit 1
fi

# Check if configuration exists
if [[ ! -f "\${CONFIG_PATH}" ]]; then
    echo "Configuration file not found: \${CONFIG_PATH}" >&2
    exit 1
fi

# Execute synchronization
echo "Git-Obsidian-Sync: Starting synchronization..."
LOG_FILE="\${REPO_PATH}/.git-obsidian-sync.error.log"
echo "Running sync at \$(date)" > "\${LOG_FILE}"
if "\${SYNC_SCRIPT}" --config "\${CONFIG_PATH}" --verbose >> "\${LOG_FILE}" 2>&1; then
    echo "Git-Obsidian-Sync: Synchronization successful"
    rm "\${LOG_FILE}" # Clean up log on success
else
    echo "Git-Obsidian-Sync: Synchronization failed. See \${LOG_FILE} for details." >&2
    exit 1
fi
EOF

# Set execution permissions
chmod +x "${POST_COMMIT_PATH}"

# Make sync module executable
chmod +x "${MODULE_PATH}"

# Make sync script executable
chmod +x "${SYNC_SCRIPT_PATH}"

log "INFO" "Git hook successfully installed: ${POST_COMMIT_PATH}"
log "INFO" "Hook type: Bash version"
log "INFO" "All scripts have been made executable"

# Return to original directory
cd "${ORIGINAL_PATH}"

log "INFO" "Installation completed!"
