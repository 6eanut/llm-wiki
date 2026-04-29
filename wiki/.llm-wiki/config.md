# Wiki Configuration

## Wiki Settings
wiki_name: "My Wiki"
wiki_root: "./wiki"
language: "bilingual"       # en | zh | bilingual

## Ingest Settings
auto_index: true             # Auto-regenerate index after each change
two_phase: true              # Use two-phase ingest (Phase 1 analysis, Phase 2 generation)
require_review: true         # Require user review of Phase 1 analysis before Phase 2

## Query Settings
max_pages_to_read: 5         # Maximum pages to read per query
prefer_language_match: true  # Prefer pages in query language

## Lint Settings
lint_on_startup: false       # Run quick lint on session start
full_lint_frequency: 10      # Suggest full lint every N ingests
