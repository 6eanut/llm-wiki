#!/bin/bash
# _utils.sh — Shared utility functions for LLM Wiki scripts
# Source this file from other scripts to avoid duplicating common functions.
#
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"

# find_wiki_root — Locate the wiki directory
# Checks LLM_WIKI_ROOT env var first, then ./wiki as fallback.
# Returns the wiki root path, or empty string if not found.
find_wiki_root() {
    if [ -n "${LLM_WIKI_ROOT:-}" ] && [ -d "$LLM_WIKI_ROOT/.llm-wiki" ]; then
        echo "$LLM_WIKI_ROOT"
    elif [ -d "./wiki/.llm-wiki" ]; then
        echo "./wiki"
    else
        echo ""
    fi
}