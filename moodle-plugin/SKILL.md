---
name: moodle-plugin
description: Moodle plugin development conventions, tips and important notes. Use when reviewing, analysing, editing, and working on Moodle plugins. This includes information about path resolution, git usage, etc.
---

# Moodle Plugin (moodle-plugin)

## Identifying the plugin

The user refers to a plugin by **folder path** (e.g. `mod/assign/submission/pluginname`) or **component name** (e.g. `assignsubmission_pluginname`). Map between them using Moodle conventions: component = `plugintype_pluginname`, path = `plugintype/pluginname` (subplugins: `plugintype/parent/pluginname`). If the Moodle tree is managed by MDK, you may use `mdk path` to resolve paths (for example `mdk path --component <component>`); read the `mdk` skill for usage examples. If resolving the plugin location is still tricky, the root file `/component.json` provides types and their folders. Plugins with subplugins also declare a `subplugins.json` file (e.g. `mod/assign/subplugins.json`).

**Plugin root** = directory containing the plugin's `version.php`. When in doubt, search for `version.php` containing the matching `$plugin->component`.

## Scope rules

1. **Plugin root is the repo root.**
   Assume the plugin has its own git repository. All file operations, git commands, diffs, and reviews are relative to the plugin directory.

2. **Do not change core.**
   No edits outside the plugin (`lib/`, `admin/`, etc.). If a core change is needed, say so and suggest alternatives or document it as a limitation.

3. **Other plugins are out of scope unless declared as dependencies.**
   Only reference or change another plugin if listed in the current plugin's `$plugin->dependencies` in `version.php`. Do not add or assume dependencies.

4. **Reuse existing lang strings.**
   Do not re-define strings that already exist in core (`lang/en/*.php`) or in a declared dependency's lang file. Reference them directly (e.g. `get_string('key', 'core')`). Only create new strings in the plugin's own `lang/en/` when no suitable string exists.

## Using git

When using `git` in a plugin, you must first assume that the plugin is its own separate git repository. You must always use `git -C <path-to-plugin>`.

```bash
git -C public/blocks/xp status
git -C public/local/example diff
```

## Version numbers

When bumping the `version` in `version.php`, you must never exceed today's date. Instead, you should increment the revision bit. For example, if today is 2025-03-25, the bumps should be 2025032500, 2025032501, 2025032502, ...
