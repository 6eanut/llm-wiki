# Support

## Getting Help

### Documentation

- **[README](README.md)** — Overview, quick start, architecture, all commands
- **[CONTRIBUTING](CONTRIBUTING.md)** — How to contribute
- **[FAQ](FAQ.md)** — Frequently asked questions
- **[WIKI_SCHEMA](llm-wiki/WIKI_SCHEMA.md)** — Page types, fields, conventions

### Community

- **[GitHub Discussions](../../discussions)** — Ask questions, share ideas, show your wiki setups
- **[GitHub Issues](../../issues)** — Bug reports and feature requests
  - Use the Bug Report template for bugs
  - Use the Feature Request template for ideas

### Common Issues

#### "Wiki not found" or "No index.md"

Run `setup-project.sh` in your project directory:

```bash
~/.claude/skills/llm-wiki/scripts/setup-project.sh ./wiki
```

#### Skill commands not working

Make sure the skill is installed globally:

```bash
./llm-wiki/install.sh --force
```

#### Shell scripts fail with "command not found"

Ensure you have these dependencies:

- `bash` (4.0+)
- GNU `find`, `grep`, `sed`, `sort`, `sha256sum`
- `jq` (for JSON processing in hooks)

On macOS, install GNU tools via Homebrew:

```bash
brew install coreutils grep jq
```

### Still Stuck?

Open a [GitHub Discussion](../../discussions) with:

- What you're trying to do
- What command you ran
- The exact error message
- Your OS and Claude Code version
