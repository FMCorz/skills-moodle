---
name: moodle-plugin-upgrade-assessor
description: Assess Moodle plugin upgrade impact for a target Moodle version by extracting notes from UPGRADING.md files, evaluating plugin relevance note by note, and producing per-plugin Markdown action reports for developers.
---

# Moodle Plugin Upgrade Assessor

## Purpose

Assess whether user-provided Moodle plugins likely need updates for a target Moodle version.

The workflow has three outputs:

1. A single compiled note file for the target version.
2. A per-note impact assessment against user-provided plugins.
3. One Markdown report per plugin with relevant upgrade notes and developer-ready context.

## Required Inputs

Collect these before starting:

- Target Moodle version (for example: `4.5`, `4.5.0`, or `405`).
- Plugin list from the user (component names and/or paths).
- Scope of source notes (usually all `UPGRADING.md` files in the Moodle codebase and included plugins).
- Output directory for generated Markdown files.

If any input is missing, ask concise clarifying questions before analysis.

## Output Files

Create these artifacts:

- `compiled-upgrading-notes-<target>.md`
- `plugin-upgrade-impact-<frankenstyle>.md` for each provided plugin

Use plugin frankenstyle names when possible (example: `block_xp`), otherwise normalize path names.

## Workflow

Copy this checklist and keep it updated while you work:

```text
Upgrade Assessment Progress
- [ ] Step 1: Normalize target version and plugin list
- [ ] Step 2: Collect all target-version notes from UPGRADING.md files
- [ ] Step 3: Write compiled notes file
- [ ] Step 4: Assess each compiled note against each plugin
- [ ] Step 5: Create per-plugin impact reports
- [ ] Step 6: Validate coverage and unresolved assumptions
```

### Step 1: Normalize target version and plugin list

- Convert the target version into comparable forms (for example `4.5`, `4.5.0`, numeric style if present).
- Normalize plugin identifiers:
  - Frankenstyle (`plugintype_pluginname`)
  - Path (`plugintype/pluginname` or subplugin path)
- Keep a mapping table so each plugin is tracked consistently across files.

### Step 2: Collect target-version upgrading notes

Search all `UPGRADING.md` files in scope and extract notes that apply to the target version.

For each extracted note, capture:

- Source file path
- Section heading/version heading
- Exact note text
- Nearby context needed to interpret impact (API names, deprecated methods, behavior changes, removed callbacks, DB changes, capability changes)

Do not rewrite or paraphrase during extraction; preserve source wording in the compiled file.

### Step 3: Write compiled notes file

Create `compiled-upgrading-notes-<target>.md` with this structure:

```markdown
# Compiled UPGRADING notes for Moodle <target>

## Scope
- Target version: <target>
- Files scanned: <count>
- Notes extracted: <count>

## Notes
### Note <N>
- Source: `<path>`
- Version section: `<heading>`
- Raw note:
  > <verbatim note text>
- Context:
  - <key API/symbol/change detail>
```

### Step 4: Assess impact note by note

For each compiled note, evaluate each plugin independently.

Use this decision scale:

- `Impacted` - plugin almost certainly needs changes.
- `Possibly impacted` - plausible link, requires targeted confirmation.
- `Not impacted` - no meaningful relation found.
- `Unknown` - insufficient evidence to decide.

Evaluation guidelines:

- Match mentioned APIs, callbacks, hooks, events, renderers, DB usage, capabilities, or config keys to plugin code.
- Treat direct references to plugin type/subplugin type as strong signals.
- Prefer concrete evidence (symbol/path usage) over assumptions.
- When uncertain, mark `Unknown` with a verification task.

### Step 5: Create per-plugin report files

Create one file per plugin: `plugin-upgrade-impact-<frankenstyle>.md`.

Each report must be directly actionable for a developer and contain enough context to start implementation.

Use this template:

```markdown
# Upgrade impact report: <plugin>

## Target Moodle version
<target>

## Verdict
<One-line overall outcome: impacted / possibly impacted / not impacted / unknown>

## Affected notes
### <Note ID or short title>
- Status: <Impacted|Possibly impacted|Not impacted|Unknown>
- Source: `<UPGRADING.md path>` (<version section>)
- Why this matters:
  - <evidence tied to plugin code or architecture>
- Plugin touchpoints:
  - `<file/path.ext>` - <symbol or behavior>
- Recommended changes:
  - [ ] <specific code action>
  - [ ] <specific test/update action>
- Verification:
  - [ ] <how to verify fix works>

## Non-affected notes reviewed
- <Note ID> - short rationale

## Open questions
- <unknowns needing user/dev decision>

## Handoff summary for implementation
- Risk level: <low|medium|high>
- Estimated effort: <S|M|L>
- First implementation step: <concrete starting action>
```

Report requirements:

- Include at least one rationale line for every note considered.
- For `Impacted` and `Possibly impacted`, include concrete file/symbol touchpoints whenever available.
- Add explicit TODO checkboxes for implementation and verification.
- Keep statements evidence-based; avoid definitive claims without code linkage.

### Step 6: Validate quality

Before finishing:

- Confirm every compiled note was assessed against every plugin.
- Confirm every plugin has exactly one report file.
- Confirm all `Unknown` outcomes include a specific follow-up check.
- Confirm wording is clear enough for a developer to implement without re-reading all source notes.

## Decision Rules

- If a note is about removed/deprecated APIs used by a plugin, default to `Impacted`.
- If a note is generic but nearby code patterns suggest relevance, use `Possibly impacted`.
- If no matching behavior/API/path exists after targeted checks, use `Not impacted`.
- If plugin code visibility is incomplete or references are ambiguous, use `Unknown`.

## Constraints

- Do not skip notes silently.
- Do not produce empty plugin reports.
- Do not collapse multiple independent notes into one blended item.
- Do not invent source notes; include only extracted text.

## Final Delivery

At completion, provide:

- Location of compiled notes file.
- List of generated per-plugin report files.
- Count summary:
  - total notes extracted
  - total plugin-note assessments
  - impacted / possibly impacted / not impacted / unknown totals
