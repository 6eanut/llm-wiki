---
description: Health check for the wiki — structural (quick) or semantic (full)
argument-hint: [--quick|--full]
---

# Wiki Health Check

The user ran `/wiki-lint $ARGUMENTS`. Default mode: `--quick`.

## Quick Mode (bash scripts, zero LLM cost)

Run these scripts from `~/.claude/skills/llm-wiki/scripts/`:

- `validate-frontmatter.sh` — Required field validation
- `find-broken-links.sh` — Dead wikilink detection
- `find-orphans.sh` — Pages with no incoming links
- `check-stale.sh` — Index freshness

## Full Mode (LLM semantic analysis)

Use `Skill("llm-wiki")` → `workflows/lint.md` for:

- Contradiction detection between pages
- Content quality assessment
- Language consistency check
- Staleness / drift detection
- Knowledge gap analysis
