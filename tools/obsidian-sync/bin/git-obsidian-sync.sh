#!/bin/bash
#
# git-obsidian-sync.sh
# Bash version for synchronization between Git repository and Obsidian Vault
#
# Version: 2.0.3
# Date: 2025-09-10
#

set -euo pipefail

# Global variables
# SCRIPT_DIR="$(cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" && pwd)"  # Unused
CONFIG_PATH="${1:-.git-obsidian-sync.json}"
VERBOSE=false
# LOG_LEVEL="INFO"  # Unused

# Helper functions
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
        "WARNING")
            echo "[${timestamp}] [WARNING] ${message}" >&2
            ;;
        "ERROR")
            echo "[${timestamp}] [ERROR] ${message}" >&2
            ;;
    esac
}

normalize_path() {
    local path="${1}"

    # Convert Windows paths (e.g. C:/Users/...) to Git-Bash paths (/c/Users/...)
    if [[ "${path}" =~ ^([A-Za-z]):(.*) ]]; then
        local drive_letter="${BASH_REMATCH[1],,}" # to lowercase
        local rest_of_path="${BASH_REMATCH[2]}"
        path="/${drive_letter}${rest_of_path}"
    fi

    # Convert relative path to absolute if it wasn't a Windows path
    if [[ ! "${path}" = /* ]]; then
        path="$(pwd)/${path}"
    fi

    # Normalize path (removes ./ and ../)
    realpath -m "${path}" 2>/dev/null || echo "${path}"
}

# Load and validate configuration
load_config() {
    local config_path="${1}"

    if [[ ! -f "${config_path}" ]]; then
        log "ERROR" "Configuration file not found: ${config_path}"
        exit 1
    fi

    # Validate JSON
    if ! jq empty "${config_path}" 2>/dev/null; then
        log "ERROR" "Invalid JSON configuration: ${config_path}"
        exit 1
    fi

    # Check required fields
    local target_vault
    target_vault=$(jq -r '.targetVault // empty' "${config_path}")
    local mappings
    mappings=$(jq -r '.mappings // empty' "${config_path}")

    if [[ -z "${target_vault}" ]]; then
        log "ERROR" "Configuration error: targetVault not defined"
        exit 1
    fi

    if [[ "${mappings}" == "null" || -z "${mappings}" ]]; then
        log "ERROR" "Configuration error: No mappings defined"
        exit 1
    fi

    log "DEBUG" "Configuration loaded successfully: ${config_path}"
}

# Git functions
get_all_memory_bank_files() {
    local source_dir="${1}"
    if [[ ! -d "${source_dir}" ]]; then
        log "WARNING" "Source directory '${source_dir}' not found."
        echo ""
        return
    fi
    find "${source_dir}" -type f -name "*.md"
}

get_git_commit_metadata() {
    if ! command -v git >/dev/null 2>&1; then
        log "ERROR" "Git is not installed or not in PATH"
        exit 1
    fi

    local commit_hash
    commit_hash=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local author
    author=$(git log -1 --pretty=format:"%an" 2>/dev/null || echo "unknown")
    local timestamp
    timestamp=$(git log -1 --pretty=format:"%ad" --date=iso 2>/dev/null || date -Iseconds)
    local message
    message=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "unknown")

    echo "{\"commitHash\":\"${commit_hash}\",\"author\":\"${author}\",\"timestamp\":\"${timestamp}\",\"message\":\"${message}\"}"
}

# File synchronization
copy_file_with_utf8() {
    local source_path="${1}"
    local target_path="${2}"

    # Create target directory
    local target_dir
    target_dir=$(dirname "${target_path}")
    mkdir -p "${target_dir}"

    # Copy file with UTF-8 preservation
    if cp "${source_path}" "${target_path}" 2>/dev/null; then
        log "DEBUG" "File synchronized: ${source_path} -> ${target_path}"
        return 0
    else
        log "ERROR" "Error copying file: ${source_path} -> ${target_path}"
        return 1
    fi
}

add_metadata() {
    local file_path="${1}"
    local metadata="${2}"
    local add_metadata="${3}"
    local add_git_metadata="${4}"
    local add_sync_timestamp="${5}"

    # Only for Markdown files
    if [[ ! "${file_path}" =~ \.md$ ]]; then
        return 0
    fi

    # Only add metadata if enabled
    if [[ "${add_metadata}" != "true" ]]; then
        return 0
    fi

    # Temporary file for frontmatter
    local temp_file
    temp_file=$(mktemp)
    local original_content
    original_content=$(cat "${file_path}")

    # Create frontmatter
    echo "---" > "${temp_file}"

    if [[ "${add_git_metadata}" == "true" ]]; then
        local commit_hash
        commit_hash=$(echo "${metadata}" | jq -r '.commitHash')
        local author
        author=$(echo "${metadata}" | jq -r '.author')
        local timestamp
        timestamp=$(echo "${metadata}" | jq -r '.timestamp')
        local message
        message=$(echo "${metadata}" | jq -r '.message')

        {
            echo "git-commit: ${commit_hash}"
            echo "git-author: ${author}"
            echo "git-timestamp: ${timestamp}"
            echo "git-message: ${message}"
        } >> "${temp_file}"
    fi

    if [[ "${add_sync_timestamp}" == "true" ]]; then
        echo "sync-timestamp: $(date -Iseconds)" >> "${temp_file}"
    fi

    {
        echo "---"
        echo ""
        echo "${original_content}"
    } >> "${temp_file}"

    # Save new file with metadata
    mv "${temp_file}" "${file_path}"
    log "DEBUG" "Metadata added: ${file_path}"
}

# Main synchronization
sync_files() {
    local config_path="${1}"
    local changed_files="${2}"

    # Parse configuration
    local target_vault
    target_vault=$(jq -r '.targetVault' "${config_path}")
    local add_metadata
    add_metadata=$(jq -r '.options.addMetadata // false' "${config_path}")
    local add_git_metadata
    add_git_metadata=$(jq -r '.options.metadataTemplate.addGitMetadata // false' "${config_path}")
    local add_sync_timestamp
    add_sync_timestamp=$(jq -r '.options.metadataTemplate.addSyncTimestamp // false' "${config_path}")

    # Normalize path
    target_vault=$(normalize_path "${target_vault}")

    # Get commit metadata
    local commit_metadata
    commit_metadata=$(get_git_commit_metadata)

    # For each mapping
    local mapping_count
    mapping_count=$(jq '.mappings | length' "${config_path}")
    for ((i=0; i<mapping_count; i++)); do
        local mapping
        mapping=$(jq ".mappings[${i}]" "${config_path}")
        local source
        source=$(echo "${mapping}" | jq -r '.source // .repoPath')
        local target
        target=$(echo "${mapping}" | jq -r '.target // .vaultPath')

        log "DEBUG" "Mapping ${i}: source='${source}', target='${target}'"

        # Filter relevant files for this mapping (supports directory and single-file mappings)
        while IFS= read -r file; do
            [[ -z "${file}" ]] && continue
            [[ "${file}" != *.md ]] && continue

            local relative_path=""
            if [[ -d "${source}" ]]; then
                # Directory mapping: file must be inside source
                if [[ "${file}" == "${source}"* ]]; then
                    relative_path="${file#"${source}"}"
                else
                    continue
                fi
            elif [[ -f "${source}" ]]; then
                # Single-file mapping: file must exactly match source
                if [[ "${file}" == "${source}" ]]; then
                    relative_path="$(basename "${file}")"
                else
                    continue
                fi
            else
                # Invalid mapping source
                continue
            fi

            # Compose target path: always treat mapping target as a directory base
            local target_dir="${target_vault}/${target}"
            target_dir=$(normalize_path "${target_dir}")
            [[ "${target_dir}" != */ ]] && target_dir="${target_dir}/"
            # Enforce subfolder for memory-bank when source is a directory and mapping target doesn't already include it
            if [[ -d "${source}" ]]; then
                local src_base
                src_base=$(basename "${source%/}")
                if [[ "${src_base}" == "memory-bank" && "${target_dir}" != */memory-bank/ ]]; then
                    target_dir="${target_dir}memory-bank/"
                fi
            fi

            local target_path="${target_dir}${relative_path}"

            # Copy file and optionally add metadata
            if copy_file_with_utf8 "${file}" "${target_path}"; then
                add_metadata "${target_path}" "${commit_metadata}" "${add_metadata}" "${add_git_metadata}" "${add_sync_timestamp}"
            fi
        done <<< "${changed_files}"
    done
}

# Main function
main() {
    # Process parameters
    while [[ ${#} -gt 0 ]]; do
        case ${1} in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -c|--config)
                CONFIG_PATH="${2}"
                shift 2
                ;;
            -h|--help)
                echo "Usage: ${0} [-v|--verbose] [-c|--config CONFIG_PATH] [CONFIG_PATH]"
                echo "  -v, --verbose    Verbose output"
                echo "  -c, --config     Configuration file path"
                echo "  -h, --help       Show this help"
                exit 0
                ;;
            *)
                CONFIG_PATH="${1}"
                shift
                ;;
        esac
    done

    # Check dependencies
    if ! command -v jq >/dev/null 2>&1; then
        log "ERROR" "jq is not installed. Please install: sudo apt-get install jq"
        exit 1
    fi

    # Normalize paths
    CONFIG_PATH=$(normalize_path "${CONFIG_PATH}")

    log "INFO" "Synchronization started"
    log "DEBUG" "Configuration file: ${CONFIG_PATH}"

    # Load configuration
    load_config "${CONFIG_PATH}"

    # Find all relevant files across ALL mappings (directories and single files)
    local mapping_count
    mapping_count=$(jq '.mappings | length' "${CONFIG_PATH}")
    local all_files=""
    for ((i=0; i<mapping_count; i++)); do
        local src
        src=$(jq -r ".mappings[${i}].source // .mappings[${i}].repoPath" "${CONFIG_PATH}")

        if [[ -d "${src}" ]]; then
            # Directory mapping: collect all Markdown files
            while IFS= read -r f; do
                [[ -n "${f}" ]] && all_files+="${f}"$'\n'
            done < <(find "${src}" -type f -name "*.md" 2>/dev/null || true)
        elif [[ -f "${src}" ]]; then
            # Single file mapping
            all_files+="${src}"$'\n'
        else
            log "WARNING" "Source not found: ${src}"
        fi
    done

    # Deduplicate and count
    all_files=$(printf "%s" "${all_files}" | awk 'NF' | sort -u)
    local file_count
    file_count=$(printf "%s\n" "${all_files}" | grep -c . || echo "0")

    log "INFO" "Files found for synchronization: ${file_count}"

    # Exit if no files were found
    if [[ "${file_count}" -eq 0 ]]; then
        log "INFO" "No matching files found, synchronization skipped"
        exit 0
    fi

    # Synchronize files
    sync_files "${CONFIG_PATH}" "${all_files}"

    log "INFO" "Synchronization completed successfully"
}

# Execute script
main "${@}"
