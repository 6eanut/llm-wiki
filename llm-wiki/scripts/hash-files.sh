#!/bin/bash
# hash-files.sh — Compute SHA-256 hash of a file or directory
# Usage: hash-files.sh <file|directory>
# Output: SHA-256 hash to stdout
# Exit: 0 on success, 1 on error

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: hash-files.sh <file|directory>"
    echo "Compute SHA-256 hash of a file or directory."
    echo "For directories, hashes all contained files and produces a combined hash."
    exit 0
fi

if [ $# -lt 1 ]; then
    echo "Usage: hash-files.sh <file|directory>" >&2
    exit 1
fi

TARGET="$1"

if [ ! -e "$TARGET" ]; then
    echo "ERROR: '$TARGET' does not exist" >&2
    exit 1
fi

if [ -f "$TARGET" ]; then
    # Single file: hash the content directly
    sha256sum "$TARGET" | cut -d' ' -f1
elif [ -d "$TARGET" ]; then
    # Directory: hash of sorted concatenation of all file hashes within
    # This makes the hash order-independent but content-sensitive
    find "$TARGET" -type f -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1
else
    echo "ERROR: '$TARGET' is neither a file nor a directory" >&2
    exit 1
fi
