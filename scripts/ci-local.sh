#!/bin/bash
# ci-local.sh — Run all CI checks locally before pushing
# Usage: ./scripts/ci-local.sh
# Mirrors the 3 jobs in .github/workflows/ci.yml:
#   1. ShellCheck (on llm-wiki/**/*.sh + uninstall.sh)
#   2. markdownlint (on MD files matching CI globs)
#   3. Integration tests (temp wiki, run all scripts)
# Exit: 0 = all passed, 1 = one or more checks failed

set -euo pipefail

# ── Colour helpers ──────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

success() { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}!${NC} %s\n" "$*"; }
error()   { printf "${RED}✗${NC} %s\n" "$*" >&2; }
header()  { echo ""; echo "${BOLD}$*${NC}"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

PASS=0
FAIL=0

# Resolve project root (where this script lives, one level up)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# ── 1. ShellCheck ───────────────────────────────────────────────────────────

header "1/3 — ShellCheck"

if command -v shellcheck &>/dev/null; then
    echo "Running shellcheck on llm-wiki/**/*.sh + uninstall.sh..."

    SH_FILES=()
    while IFS= read -r -d '' f; do
        SH_FILES+=("$f")
    done < <(find llm-wiki -name "*.sh" -print0 2>/dev/null)
    SH_FILES+=("uninstall.sh")

    if [ "${#SH_FILES[@]}" -eq 0 ]; then
        warn "No .sh files found to check."
        PASS=$((PASS + 1))
    else
        SHELLCHECK_OK=true
        for shf in "${SH_FILES[@]}"; do
            if [ -f "$shf" ]; then
                if shellcheck -x "$shf"; then
                    success "  $shf"
                else
                    error "  $shf — shellcheck found issues"
                    SHELLCHECK_OK=false
                fi
            fi
        done

        if [ "$SHELLCHECK_OK" = true ]; then
            success "ShellCheck passed (${#SH_FILES[@]} file(s))"
            PASS=$((PASS + 1))
        else
            error "ShellCheck failed"
            FAIL=$((FAIL + 1))
        fi
    fi
else
    warn "shellcheck is not installed."
    echo "  Install it via your package manager, e.g.:"
    echo "    apt install shellcheck     (Debian/Ubuntu)"
    echo "    brew install shellcheck    (macOS)"
    echo "    dnf install ShellCheck     (Fedora)"
    echo "  Skipping ShellCheck — this will NOT cause a failure."
    PASS=$((PASS + 1))
fi

# ── 2. markdownlint ─────────────────────────────────────────────────────────

header "2/3 — markdownlint"

if command -v markdownlint-cli2 &>/dev/null; then
    echo "Running markdownlint-cli2 on MD files matching CI globs..."

    # Same globs as .github/workflows/ci.yml markdownlint job
    if markdownlint-cli2 \
        README.md \
        CONTRIBUTING.md \
        CODE_OF_CONDUCT.md \
        SECURITY.md \
        CHANGELOG.md \
        SUPPORT.md \
        "llm-wiki/**/*.md" \
        ".github/**/*.md" \
        FAQ.md \
        2>&1; then
        success "markdownlint passed"
        PASS=$((PASS + 1))
    else
        error "markdownlint found issues"
        FAIL=$((FAIL + 1))
    fi
else
    warn "markdownlint-cli2 is not installed."
    echo "  Install it via npm:"
    echo "    npm install -g markdownlint-cli2"
    echo "  Or run without global install:"
    echo "    npx markdownlint-cli2 '**/*.md'"
    echo "  Skipping markdownlint — this will NOT cause a failure."
    PASS=$((PASS + 1))
fi

# ── 3. Integration tests ────────────────────────────────────────────────────

header "3/3 — Integration Tests"

echo "Creating temporary wiki and running all scripts..."

INTEGRATION_OK=true
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

(
    cd "$TMPDIR"

    # Test init-wiki.sh
    echo ""
    echo "--- Testing init-wiki.sh ---"
    if bash "$PROJECT_ROOT/llm-wiki/scripts/init-wiki.sh" --force; then
        success "  init-wiki.sh"
    else
        error "  init-wiki.sh failed"
        INTEGRATION_OK=false
    fi

    # Test hash-files.sh
    echo ""
    echo "--- Testing hash-files.sh ---"
    if bash "$PROJECT_ROOT/llm-wiki/scripts/hash-files.sh" ./wiki; then
        success "  hash-files.sh"
    else
        error "  hash-files.sh failed"
        INTEGRATION_OK=false
    fi

    # Create test pages
    echo ""
    echo "--- Creating test pages ---"

    cat > ./wiki/test-concept.md << 'EOF'
---
title: "Test Concept"
type: concept
language: en
created: "2026-04-30"
modified: "2026-04-30"
tags: [test, example]
summary: "A test page for CI validation"
---
# Test Concept
This is a test page. See [[other-page]] for more.
EOF

    cat > ./wiki/other-page.md << 'EOF'
---
title: "Other Page"
type: article
language: en
created: "2026-04-30"
modified: "2026-04-30"
tags: [test]
summary: "Another test page"
---
# Other Page
This links back to [[test-concept]].
EOF

    success "  test pages created"

    # Test validate-frontmatter.sh
    echo ""
    echo "--- Testing validate-frontmatter.sh ---"
    if bash "$PROJECT_ROOT/llm-wiki/scripts/validate-frontmatter.sh" ./wiki; then
        success "  validate-frontmatter.sh"
    else
        error "  validate-frontmatter.sh failed"
        INTEGRATION_OK=false
    fi

    # Test find-broken-links.sh
    echo ""
    echo "--- Testing find-broken-links.sh ---"
    bash "$PROJECT_ROOT/llm-wiki/scripts/find-broken-links.sh" ./wiki || true
    success "  find-broken-links.sh (completed)"

    # Test find-orphans.sh
    echo ""
    echo "--- Testing find-orphans.sh ---"
    bash "$PROJECT_ROOT/llm-wiki/scripts/find-orphans.sh" ./wiki || true
    success "  find-orphans.sh (completed)"

    # Test check-stale.sh
    if [ -f "$PROJECT_ROOT/llm-wiki/scripts/check-stale.sh" ]; then
        echo ""
        echo "--- Testing check-stale.sh ---"
        bash "$PROJECT_ROOT/llm-wiki/scripts/check-stale.sh" ./wiki || true
        success "  check-stale.sh (completed)"
    fi

    # Test install.sh --help
    echo ""
    echo "--- Testing install.sh --help ---"
    if bash "$PROJECT_ROOT/llm-wiki/install.sh" --help; then
        success "  install.sh --help"
    else
        error "  install.sh --help failed"
        INTEGRATION_OK=false
    fi

    # Test uninstall.sh --help
    echo ""
    echo "--- Testing uninstall.sh --help ---"
    if bash "$PROJECT_ROOT/uninstall.sh" --help; then
        success "  uninstall.sh --help"
    else
        error "  uninstall.sh --help failed"
        INTEGRATION_OK=false
    fi

    if [ "$INTEGRATION_OK" = true ]; then
        echo ""
        success "All integration tests passed"
    else
        echo ""
        error "Some integration tests failed"
    fi
)

INTEGRATION_EXIT=$?
if [ "$INTEGRATION_OK" = true ]; then
    PASS=$((PASS + 1))
else
    FAIL=$((FAIL + 1))
fi

# ── Summary ─────────────────────────────────────────────────────────────────

header "Results"

printf "  ${GREEN}%d passed${NC}, ${RED}%d failed${NC}\n" "$PASS" "$FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
    success "All CI checks passed — ready to push!"
    exit 0
else
    error "$FAIL check(s) failed — review the output above before pushing."
    exit 1
fi
