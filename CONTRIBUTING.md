# Contributing to LLM Wiki

Thanks for your interest in contributing! LLM Wiki is a Claude Code skill that builds persistent,
interlinked knowledge bases from source documents.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Please read it before participating.

## How to Contribute

### Reporting Bugs

1. Search [existing issues](../../issues) to avoid duplicates
2. Use the **Bug Report** template (`.github/ISSUE_TEMPLATE/bug_report.md`)
3. Include: steps to reproduce, expected vs actual behavior, environment (OS, Claude Code version)

### Suggesting Features

1. Search [existing issues](../../issues) for similar ideas
2. Use the **Feature Request** template
3. Describe the use case and how it fits the LLM Wiki philosophy

### Pull Requests

1. **Fork the repo** and create a branch from `main`
2. **Follow Conventional Commits** for commit messages:

   ```text
   feat(ingest): add support for .rst sources
   fix(lint): handle empty index gracefully
   docs: add FAQ about RAG vs LLM Wiki
   ```

3. **Run shellcheck** on any modified `.sh` scripts:

   ```bash
   shellcheck llm-wiki/scripts/*.sh llm-wiki/hooks/*.sh install.sh
   ```

4. **Test your changes**:

   ```bash
   # Install the skill
   ./llm-wiki/install.sh --force
   # Set up a test wiki
   ~/.claude/skills/llm-wiki/scripts/setup-project.sh /tmp/test-wiki
   # Run quick lint on the test wiki
   ~/.claude/skills/llm-wiki/scripts/validate-frontmatter.sh /tmp/test-wiki
   ~/.claude/skills/llm-wiki/scripts/find-broken-links.sh /tmp/test-wiki
   ```

5. **Keep PRs focused**: one feature or fix per PR
6. **Update relevant docs**: workflows, SKILL.md, README if behavior changes

### Development Setup

```bash
git clone https://github.com/<your-org>/llmwiki.git
cd llmwiki
./llm-wiki/install.sh --force
```

The skill files are plain text markdown and bash scripts — no build step, no language runtime needed.

## Project Structure

```text
llm-wiki/
├── SKILL.md              # Skill manifest (read by Claude Code)
├── WIKI_SCHEMA.md        # Page type definitions & conventions
├── WIKI.md               # CLAUDE.md template for projects
├── commands/             # Slash command definitions (.md)
├── workflows/            # Deep workflow procedures (.md)
├── scripts/              # Deterministic bash operations (.sh)
├── hooks/                # Session lifecycle hooks (.sh)
├── templates/            # Page templates (.md)
└── install.sh            # Global installation script
```

## Design Principles

Before contributing, understand these principles:

- **LLM is the runtime**: All content work (extraction, synthesis, cross-referencing) is done by Claude.
  Bash scripts only for deterministic operations (hashing, file listing, grep).
- **Workflow files are executable documentation**: Each `workflows/*.md` is both human-readable
  documentation and machine-followable instructions.
- **Index-first architecture**: All queries should go through `index.md` first, not directly reading
  pages. This ensures O(1) lookup regardless of wiki size.
- **Two-phase ingest**: Phase 1 (analysis / what to extract) is always separated from Phase 2
  (generation / how to write pages), with a human checkpoint in between.

## Good First Issues

Look for issues labeled [`good first issue`](../../labels/good%20first%20issue) — these are
specifically curated for new contributors.

Some ideas:

- Improve English documentation quality
- Add more Edge Case handling to a workflow file
- Write tests for a bash script
- Add support for a new source format (e.g., `.epub`, `.rst`)

## Questions?

Open a [GitHub Discussion](../../discussions) for questions, ideas, or general conversation.
