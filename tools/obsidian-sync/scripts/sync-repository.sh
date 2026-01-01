#!/bin/bash
#
# sync-repository.sh
# Performs synchronization between Git repository and Obsidian Vault
# Bash version of the PowerShell script
#
# Version: 2.0.2
# Date: 2025-08-26
#

set -euo pipefail

# Default values
SCRIPT_DIR="$(cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" && pwd)"
CONFIG_PATH=".git-obsidian-sync.json"
MODULE_PATH="${SCRIPT_DIR}/../bin/git-obsidian-sync.sh"
VERBOSE=false

# Helper functions
show_help() {
    cat << EOF
Usage: ${0} [OPTIONS] [CONFIG_PATH]

Performs synchronization between Git repository and Obsidian Vault.

OPTIONS:
    -c, --config PATH    Path to configuration file (default: .git-obsidian-sync.json)
    -m, --module PATH    Path to sync module (default: ../bin/git-obsidian-sync.sh)
    -v, --verbose        Enable verbose output
    -h, --help           Show this help

EXAMPLES:
    ${0}                                    # Use default configuration
    ${0} -v                                 # With verbose output
    ${0} -c custom-config.json              # Custom configuration
    ${0} -v -c custom-config.json           # Verbose with custom configuration

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
        "DEBUG")
            [[ "${VERBOSE}" == "true" ]] && echo "[${timestamp}] [DEBUG] ${message}" >&2
            ;;
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
        -c|--config)
            CONFIG_PATH="${2}"
            shift 2
            ;;
        -m|--module)
            MODULE_PATH="${2}"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
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
            CONFIG_PATH="${1}"
            shift
            ;;
    esac
done

# Normalize paths
CONFIG_PATH=$(normalize_path "${CONFIG_PATH}")
MODULE_PATH=$(normalize_path "${MODULE_PATH}")

log "DEBUG" "Configuration file: ${CONFIG_PATH}"
log "DEBUG" "Module path: ${MODULE_PATH}"

# Check module file
if [[ ! -f "${MODULE_PATH}" ]]; then
    log "ERROR" "Bash module not found: ${MODULE_PATH}"
    exit 1
fi

# Check configuration file
if [[ ! -f "${CONFIG_PATH}" ]]; then
    log "ERROR" "Configuration file not found: ${CONFIG_PATH}"
    exit 1
fi

# Make module executable
chmod +x "${MODULE_PATH}"

# Perform synchronization
log "INFO" "Starting synchronization with configuration: ${CONFIG_PATH}"

# Forward verbose flag to module
if [[ "${VERBOSE}" == "true" ]]; then
    if "${MODULE_PATH}" --verbose --config "${CONFIG_PATH}"; then
        log "INFO" "Synchronization completed successfully"
        exit 0
    else
        log "ERROR" "Synchronization completed with errors"
        exit 1
    fi
else
    if "${MODULE_PATH}" --config "${CONFIG_PATH}"; then
        log "INFO" "Synchronization completed successfully"
        exit 0
    else
        log "ERROR" "Synchronization completed with errors"
        exit 1
    fi
fi
