---
description: Save the current answer as a permanent synthesis page in the wiki
---

# Save Answer as Synthesis Page

The user ran `/wiki-save $ARGUMENTS`.

This saves the current conversation answer as a permanent `synthesis` page in the wiki. This is the **compounding mechanism** — good answers become part of the knowledge base.

## Procedure
Use `Skill("llm-wiki")` → `workflows/save-synthesis.md` for the full procedure:
1. Identify the query and answer from conversation context
2. Create `synth-YYYY-MM-DD-{slug}.md` using the synthesis template
3. Cross-link to all source pages via `based_on`
4. Regenerate the index
