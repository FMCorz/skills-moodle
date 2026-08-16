---
name: moodle-pre-release
description: Use when the user requests pre-release or upgrade QA on plugins, release preparation testing, or similar and provides (or will provide) a plugin list. Do not use for general testing and integration review.
---

# moodle-pre-release

## When to use

Apply this skill when the user is **testing plugins before a plugin release** or **checking plugins against a new Moodle version**, and they supply the **list of plugin component names** (for example `block_xp`, `local_xp`) to exercise.

Do **not** create a new Moodle **mdk** instance if one does not exist: **abandon** and tell the user the instance is missing.

## Inputs

1. **Plugin list** — component names as used by `-s` / `@` tags (e.g. `block_xp`, `mod_forum`).
2. **Plugin paths inside the container** — usually under `/var/www/html/public/<plugintype>/<pluginname>`. If the Moodle tree has no `public/` directory (older layouts), infer the path from the local checkout (see [Notes](#notes)).

For each plugin, complete **PHPUnit → Behat → PHPCS** in order. **Re-run** PHPUnit and Behat until they pass. For PHPCS, run **phpcbf** where safe, then **phpcs** until clean (or stop on unfixable issues after manual edits).

---

## PHPUnit (mdk)

Ensure the **PHPUnit** environment is ready, then run tests with **`-k`** for speed.

**Bootstrap (once per environment):**

```bash
mdk phpunit
```

**Run tests for a component** (repeat until green):

```bash
mdk phpunit -rknw -s <component_name>
mdk phpunit -rknw -s block_xp
```

---

## Behat (mdk)

Ensure **Behat** is ready and **Selenium** is running, then run with **`-k`**.

**Bootstrap:**

```bash
mdk behat
mdk docker selenium up -t chrome
```

**Run all scenarios for a component** (repeat until green):

```bash
mdk behat -S -k -r -p chrome -t "@<component>"
mdk behat -S -k -r -p chrome -t "@block_xp"
```

**Rerun failures only:**

```bash
mdk behat -S -r -p chrome -t "@block_xp" --rerun
```

**Flaky or unclear failures:** before changing production or test logic, **run the scenario in isolation**:

```bash
mdk behat -k -S -r -p chrome -f public/path/to/example.feature
mdk behat -k -S -r -p chrome -f public/path/to/example.feature -n 'Exact name of scenario'
```

Adjust **`public/`** in `-f` if the instance uses a layout without `public/` (see [Notes](#notes)).

---

## PHPCS / phpcbf (moodle-plugin-ci in Docker)

**Requires** [moodle-plugin-ci](../moodle-plugin-ci/SKILL.md) installed **inside** the Moodle instance container. If it is missing, follow that skill to install it **in the container** — do **not** create a new instance; if the container or install cannot be used, **abandon** PHPCS for that environment and report it.

**Resolve the container identifier:**

```bash
mdk info -v identifier 2>/dev/null
```

Use the printed value as **`<identifier>`** in `docker exec` below.

**PHPCS** (fail on warnings; use **`--standard` only if** the plugin root contains **`phpcs.xml`**):

```bash
docker exec <identifier> bash -c '/opt/moodle-plugin-ci/bin/moodle-plugin-ci phpcs --max-warnings=0 /var/www/html/public/mod/example'
docker exec <identifier> bash -c '/opt/moodle-plugin-ci/bin/moodle-plugin-ci phpcs --max-warnings=0 --standard="/var/www/html/public/mod/example/phpcs.xml" /var/www/html/public/mod/example'
```

**Auto-fix** with **phpcbf** (same path; add **`--standard`** / `-s` **only when** `phpcs.xml` exists at the plugin root, mirroring PHPCS):

```bash
docker exec <identifier> bash -c '/opt/moodle-plugin-ci/bin/moodle-plugin-ci phpcbf /var/www/html/public/mod/example'
docker exec <identifier> bash -c '/opt/moodle-plugin-ci/bin/moodle-plugin-ci phpcbf --standard="/var/www/html/public/mod/example/phpcs.xml" /var/www/html/public/mod/example'
```

Then **re-run PHPCS** until it passes. **Manually** fix anything phpcbf cannot.

### Addressing PHPCS findings

For PHPDoc fixes:

- Read the implementation before writing the docblock. Use parent or interface documentation only to understand the contract; never copy it verbatim without checking that it describes the current implementation.
- Use one short title ending with a full stop: `Check access.`, `Get page URL.`, `Process the form submission.`, or `Validation.`
- Do not copy parent wording aimed at implementers, such as “stub”, “override this”, “used if”, or instructions about how an implementation should behave. Describe what the current method does.
- Keep tags minimal. Use short descriptions only when needed, such as `@param array $data The data.`, and prefer a bare return type such as `@return array`.
- Never add `@throws`.
- Do not surface `@deprecated` from a parent. Add it only when the current method itself is intentionally deprecated.
- Do not inherit prose or tags merely because they exist in the parent. Brevity is the default.

For intentional PHPCS suppressions, use the bare directive without a trailing explanation:

```php
// phpcs:disable PSR1.Classes.ClassDeclaration.MultipleClasses
```

---

## Ground rules

- **Compatibility:** Changes (if any) must remain valid for **Moodle 4.1 through 5.2** and **PHP 7.4** (4.1 baseline). Fixes for deprecations must be **backwards compatible**. **Do not change code** unless something is **actually broken** by a failing check or test.
- **Tests are assumed correct:** Failures are often small incompatibilities with a **newer Moodle**. **Do not change test logic.** If a logical failure has no simple fix, **stop** and **flag** the problem for a human.
- **Behat:** Prefer **version-agnostic** steps. **UI wording/layout** changes may need **small step** adjustments; if a step would break **older** Moodle (e.g. 4.1), prefer a **dedicated Behat step** in the plugin to handle the edge case rather than branching fragile scenarios.

## Agent: fixes and commits

**If and only if** the agent changes the codebase (any tracked file), they **must** `git commit` those changes. Do **not** accumulate multiple unrelated edits without committing.

**One item at a time:** fix **one** concrete failure before tackling the next (for example a single PHPUnit failure, a single Behat scenario, or one PHPCS issue / one tight cluster from the same sniff). Re-run the failing command, confirm it is addressed, then proceed.

**Commit message** (first line is the subject; the rest is the body). Replace placeholders with the actual command invocation and paste or summarise the tool output that motivated the fix:

```text
AGENT: Fix the thing that was broken

This is fixing the failure in <command> blah blah...

<error as described by command>
```

---

## Notes

- Some Moodle trees omit **`public/`**; align `-f` paths and `/var/www/html/...` plugin paths with the **actual** webroot and plugin layout in that instance and repo.
- Installing moodle-plugin-ci and other container setup details: **[../moodle-plugin-ci/SKILL.md](../moodle-plugin-ci/SKILL.md)**.
