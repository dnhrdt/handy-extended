#!/bin/bash
# Bash Linting Script for cline-init
# Version: 1.02
# Timestamp: 2025-08-26 13:35 CET

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
TARGET_FILES=""
VERBOSE=false

show_usage() {
    echo "Usage: ${0} [OPTIONS] FILES..."
    echo ""
    echo "Options:"
    echo "  --verbose       Show detailed output"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ${0} script.sh                    # Lint single file"
    echo "  ${0} tools/*/bin/*.sh             # Lint multiple files"
    echo "  ${0} --verbose scripts/*.sh       # Verbose linting"
}

# Parse arguments
while [[ ${#} -gt 0 ]]; do
    case ${1} in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            TARGET_FILES="${TARGET_FILES} ${1}"
            shift
            ;;
    esac
done

if [[ -z "${TARGET_FILES}" ]]; then
    echo -e "${RED}Error: No files specified${NC}"
    show_usage
    exit 1
fi

# Linting functions
check_shebang() {
    local file="${1}"
    local first_line
    first_line=$(head -n1 "${file}")

    if [[ ! "${first_line}" =~ ^#!/bin/bash$ ]] && [[ ! "${first_line}" =~ ^#!/usr/bin/env\ bash$ ]]; then
        echo -e "${YELLOW}Warning: Missing or incorrect shebang in ${file}${NC}"
        echo "  Expected: #!/bin/bash or #!/usr/bin/env bash"
        echo "  Found: ${first_line}"
        return 1
    fi
    return 0
}

check_set_options() {
    local file="${1}"

    if ! grep -q "set -euo pipefail" "${file}" && ! grep -q "set -e" "${file}"; then
        echo -e "${YELLOW}Warning: Missing 'set -euo pipefail' in ${file}${NC}"
        echo "  Recommendation: Add 'set -euo pipefail' for better error handling"
        return 1
    fi
    return 0
}

check_variable_quoting() {
    local file="${1}"

    echo -e "${CYAN}Checking variable quoting in ${file}...${NC}"

    # Einfach: Verwende grep direkt und zähle die Zeilen
    local grep_output
    grep_output=$(grep -n '\$[A-Za-z_][A-Za-z0-9_]*[^"]' "${file}" | grep -v '^\s*#' || true)

    if [[ -n "${grep_output}" ]]; then
        # Zeige alle Probleme an
        echo "${grep_output}" | while IFS=: read -r line_num line_content; do
            echo -e "${YELLOW}Warning: Potentially unquoted variable in ${file}:${line_num}${NC}"
            echo "  ${line_content}"
        done

        # Zähle die Probleme
        local issues
        issues=$(echo "${grep_output}" | wc -l)
        echo -e "${CYAN}Total unquoted variable issues in ${file}: ${issues}${NC}"
        return "${issues}"
    else
        echo -e "${GREEN}✓ No unquoted variables found${NC}"
        return 0
    fi
}

check_function_style() {
    local file="${1}"
    local issues=0

    # Check for function definitions without () style
    while IFS= read -r line_num; do
        local line
        line=$(sed -n "${line_num}p" "${file}")
        if [[ "${VERBOSE}" == true ]]; then
            echo -e "${CYAN}Info: Function definition style in ${file}:${line_num}${NC}"
            echo "  ${line}"
        fi
    done < <(grep -n '^[a-zA-Z_][a-zA-Z0-9_]*()' "${file}" | head -3 | cut -d: -f1)

    return 0
}

check_command_substitution() {
    local file="${1}"
    local issues=0

    # Check for old-style command substitution
    if grep -q "\`.*\`" "${file}"; then
        echo -e "${YELLOW}Warning: Old-style command substitution found in ${file}${NC}"
        echo "  Recommendation: Use \$(command) instead of \`command\`"
        ((issues++))
    fi

    return ${issues}
}

lint_file() {
    local file="${1}"
    local total_issues=0

    echo -e "\n${CYAN}Linting: ${file}${NC}"

    if [[ ! -f "${file}" ]]; then
        echo -e "${RED}Error: File not found: ${file}${NC}"
        return 1
    fi

    if [[ ! "${file}" =~ \.sh$ ]]; then
        echo -e "${YELLOW}Warning: File doesn't have .sh extension: ${file}${NC}"
    fi

    # Run checks
    check_shebang "${file}" || ((total_issues++))
    check_set_options "${file}" || ((total_issues++))
    check_variable_quoting "${file}"
    local var_issues=$?
    ((total_issues += var_issues))
    check_function_style "${file}"
    check_command_substitution "${file}"
    local cmd_issues=$?
    ((total_issues += cmd_issues))

    if [[ ${total_issues} -eq 0 ]]; then
        echo -e "${GREEN}✓ No major issues found${NC}"
    else
        echo -e "${YELLOW}⚠ Found ${total_issues} potential issues${NC}"
    fi

    return ${total_issues}
}

# Main execution
echo -e "${CYAN}===== Bash Linting Process =====${NC}"

total_files=0
total_issues=0

for file in ${TARGET_FILES}; do
    if [[ -f "${file}" ]]; then
        lint_file "${file}"
        file_issues=$?
        ((total_files++))
        ((total_issues += file_issues))
    else
        echo -e "${RED}Error: File not found: ${file}${NC}"
    fi
done

echo -e "\n${CYAN}===== Linting Summary =====${NC}"
echo -e "Files processed: ${total_files}"
echo -e "Total issues found: ${total_issues}"

if [[ ${total_issues} -eq 0 ]]; then
    echo -e "${GREEN}All files passed basic linting checks!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some issues were found. Consider reviewing the suggestions above.${NC}"
    exit 1
fi
