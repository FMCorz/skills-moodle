---
name: moodle-dev
description: Moodle development conventions. Use when editing Moodle code, or working on Moodle plugins.
---

# Moodle development (moodle-dev)

## Language string identifiers

Lang string identifiers **never contain special characters** (no underscores, hyphens, spaces). Use a single continuous word in lowercase.

```php
// BAD
$string['report_assignments'] = 'Assignments';
$string['my-custom-label'] = 'Label';
$string['some_key'] = 'Value';

// GOOD
$string['reportassignments'] = 'Assignments';
$string['mycustomlabel'] = 'Label';
$string['somekey'] = 'Value';
```

**Exceptions** (these use a specific pattern and may include colons or other characters):

- **Capabilities**: e.g. `muextension:manageextension`, `mod/assign:submit`
- **Message providers**: e.g. `messageprovider:notifications`
- **Other core/plugin naming schemes** that are explicitly documented (e.g. in lang pack docs)

When in doubt, follow existing strings in the same file or component; standard Moodle lang keys are alphanumeric only.

## Core string components

Use core frankenstyle component names, not legacy namespaces, in `get_string()`, `lang_string`, `moodle_exception`, …

- `langconfig` → `core_langconfig`
- `error` → `core_error`
- `moodle` → `core`

```php
get_string('strftimedatetime', 'core_langconfig');
new lang_string('yes', 'core');
throw new moodle_exception('unexpectederror', 'core_error');
```

## Database migrations

### General rules

- **Never run the Moodle upgrade script** (`admin/cli/upgrade.php`). The user will always run it themselves after reviewing your code.
- Changes in data fields must always be reflected in both `[component]/db/install.xml` and `[component]/db/upgrade.php`.
- Always add matching migrations in `db/upgrade.php` when modifying `install.xml`.
- Limit each migration to 1 single operation per version number in `db/upgrade.php`.

### install.xml

- When modifying `install.xml`, always update the date in the version attribute: `<XMLDB ... VERSION="[YYYYMMDD]" ... >` to the current date in YYYYMMDD format.
- Never add the `COMMENT` property to `FIELD` in `install.xml`, unless explicitly asked by the user.
- Always add the `COMMENT` property to `TABLE` as it is required, but keep it basic and short.

## Database queries and SQL functions

### Use database abstraction methods

**Always use database abstraction methods from `moodle_database`** (accessible via `$DB`) instead of raw SQL functions when they exist. Cross-database compatibility is primordial in Moodle.

```php
// BAD - raw SQL function (not portable across databases)
$sql = "SELECT CONCAT(field1, '-', field2) AS id FROM {table}";

// GOOD - use database abstraction
$sql = "SELECT " . $DB->sql_concat('field1', "'-'", 'field2') . " AS id FROM {table}";
```

Examples of database abstraction methods:
- `$DB->sql_concat(...)` - string concatenation
- `$DB->sql_substr(...)` - substring extraction
- `$DB->sql_like(...)` - LIKE operator

**See `lib/dml/moodle_database.php` for the complete list of available database abstraction methods.** When a database abstraction method exists, **always use it** instead of raw SQL functions to ensure compatibility across MySQL, PostgreSQL, SQL Server, Oracle, and other supported databases.

### First field must be unique

**The first field in a SELECT query must always be unique across the entire dataset.** This is required by Moodle's `get_records_*()` methods, which use the first column as the array key.

```php
// BAD - first field may have duplicates
$sql = "SELECT groupid, userid FROM {groups_members}";
$records = $DB->get_records_sql($sql); // Duplicate groupids will overwrite previous entries!
```

If you need to select non-unique fields, either:
1. Include the primary key (`id`) as the first field, or
2. Create a unique expression using database abstraction methods (e.g., `sql_concat`)

## Linting mismatches for renamed context classes

- Ignore IDE-only type warnings like:
  - `Expected type 'context'. Found 'core\\context\\course'.`
  - similar warnings for other renamed context classes.
- These are known false positives due to class renames and mixed type metadata in tooling.
- Do **not** add inline `@var` annotations purely to silence them.
- Do **not** rewrite valid code paths just to satisfy those lint warnings.
- Verify with syntax/runtime checks as needed, but treat those specific lint warnings as non-actionable.

## Parameter validation

- Almost never use `PARAM_TEXT` for validation. It has multilang filter exceptions that only rarely apply.
- For most text input, use `PARAM_RAW` or `PARAM_RAW_TRIMMED`.

## Moodle web services context rules

- In external/web service methods, do **not** call `require_login()`.
- Always use `static::validate_context($context)` after resolving the context.
- Do **not** add `if (!$context)` checks after `context_*::instance($id)` when using default behavior (`MUST_EXIST`).

## Running PHPUnit

Use **`mdk phpunit -r`** to run PHPUnit (not `php admin/tool/phpunit/cli/run.php` directly).

- **`-s [pluginname]`** – Run all tests in a plugin (component). Example: `mdk phpunit -r -s block_xp`
- **`-u [path_to_test_file]`** – Run all tests in a file. Example: `mdk phpunit -r -u blocks/xp/tests/test_something.php`
- **`-q`** – Stop execution on first failure
- **`-k`** – Quick run when tests are already initialised

Never run the unit tests yourself, unless explicitly asked to.

## Writing Behat tests

### General style

- **Use `@javascript` only when required**: add the tag only to scenarios that depend on browser JavaScript, such as dialogues or other JavaScript-only components. Omit it otherwise because JavaScript scenarios are slower.
- **Write tests from the user-visible UI**: prefer visible labels, button text, field labels, dialogue titles, and page content over implementation details, generated ids, or internal field names.
- **Use one `Given`/`When`/`Then` per scenario**: after the first one, continue with `And`.
- **Keep scenarios in the right feature file**: put a scenario where the feature belongs conceptually. Do not mix unrelated behaviours into a convenient file just because the setup is nearby.
- **Be thorough, but not repetitive**: cover distinct behaviours and edge cases, but avoid near-duplicate scenarios that only restate the same flow.

### Selectors and interactions

- **Prefer resilient selectors**: do not make selectors more specific than necessary. Match stable, user-facing text or broad stable containers before reaching for brittle DOM structure.
- **Do not guess UI labels**: confirm the actual label shown to the user before baking it into a scenario.
- **Use field labels where possible**: in form steps, prefer the visible field label over technical names or element ids.
- **Scope dialogue interactions to the dialogue**: when clicking a button or interacting with content inside a modal/dialogue, bind the step to that dialogue instead of clicking globally.
- **Extract repeated UI actions into custom Behat steps** when the raw selector sequence is brittle, repeated, or obscures the intent of the scenario.

### Assertions and flow

- **Assert what the UI actually shows, not what you expect it should show**: if the interface renders a table row, section empty state, or other alternate view, assert that exact outcome.
- **Differentiate immediate state from persisted state**: if the UI can show an optimistic or transitional state, assert the immediate result first, then reload or navigate away/back and assert the persisted result separately when relevant.
- **Exercise the real navigation needed to prove the behaviour**: if a rule or change matters only after revisiting a page, returning to a course, or reopening a screen, include that navigation in the scenario.
- **Test the correct level of specificity**: when similar rules or conditions can coexist, make sure the test proves the intended rule is the one taking effect, but do not overconstrain selectors unless disambiguation is genuinely needed.

## Writing PHPUnit tests

### Style

- **Verbosity beats abstraction in tests**: setup, permissions, generated users/courses/groups, and the key action should be readable in the `test_*` method itself. Prefer a few duplicated lines over a helper that forces the reader to jump around to understand the scenario.
- **Do not hide scenario context**: avoid broad setup helpers such as `create_environment()`, `create_fixture()`, `create_course_resolve_env()`, or helpers with boolean/config arguments that materially change the scenario. If a helper name does not make the generated data and permissions obvious, inline the setup.
- **One scenario per `test_*`**: keep each test focused; avoid loops that effectively test multiple scenarios at once.
- **Order of `test_*` methods (same unit under test)**: when several tests target the **same function or method**, order them so the **simplest, most central behaviour comes first**—what the API is fundamentally about (e.g. the main predicate or bound parameter). **Later tests add complexity**: extra filters, other contexts, other users, or alternate inputs. Do not lead with a structural concern (such as “another context”) if a more basic test (such as “the time bound is applied”) better expresses the method’s essence.
- **Minimal fixtures**: create only the data needed for the scenario inside that `test_*` method.
- **Deterministic assertions**: when the behavior is “select the right record”, ensure the test can only pass if the right record was selected.
  - Prefer asserting using **stable identifiers** like an inserted record ID (or another unique value), not only “some value looks correct”.
- When the behaviour is about **how many rows** exist in a **scope** (e.g. per `contextid`), use **`$this->assertEquals($expected, $DB->count_records($table, $conditions))`** before and after the action under test instead of tracking individual row ids.
- **Group equivalent inputs in one test**: when the only difference is passing a `context` instance vs a context id (or similar parallel forms), use a **single** `test_*`, compute **`$expected`** once, then **`assertEquals($expected, ...)`** for each form. Do not split into two tests that duplicate fixtures.
- **Prefer equality to the expected value** over `assertNotNull` followed by another assertion on the same return value. If you care about the value, set **`$expected`** and use **`assertEquals`** (or compare stable aspects such as a URL string from **`out_as_local_url(false)`**).
- When the expected result is **`null`** for two parallel inputs, use **`$expected = null`** and **`assertEquals($expected, ...)`** twice rather than pairing **`assertNull`** with a different style of assertion for the same scenario.
- At least one file, or each `test_`, must have a `@covers <fully qualified class/method>` PHP Doc.

### Helpers in test classes

- **Do not add a protected/private helper method** that is only called from **one** test; **inline** the few lines in that test instead. Extract helpers only when reused **multiple times** or when they genuinely reduce noise without hiding the scenario.
- **Do not extract scenario setup just to reduce line count**. Test helpers are acceptable for low-level mechanics or custom assertions; they are not acceptable when they hide which users, roles, capabilities, groups, contexts, or records are relevant to the behaviour.
- **Avoid helper arguments that act like hidden branches**, especially booleans or broad option arrays. If a test needs different generated users, groups, permissions, or contexts, create them explicitly in that test.
- **Slight duplication within a test class is preferable** to an abstraction that obscures why the test passes or fails.

### Mocks and fixtures

- **Prefer outcome-based tests**: assert the stored state, logged records, returned values, or persisted data rather than mirroring implementation details with extensive `createMock()` and `expects()` chains.
- **Prefer reusable test doubles over scenario-specific classes**: when a dedicated double is needed, create a general-purpose `*_mock` that can be configured with data rather than a one-off fixture for a single branch.
- **Constructor shape for test doubles**: prefer a single optional constructor argument such as `$deps = []` or `$spec = null`, then cast it to an object and read all configurable behaviour from that object.
- **Use one mock for several interfaces when practical**: if the same test double can reasonably implement multiple related interfaces, prefer that over creating many tiny classes.
- **Do not make mocks or fixtures `final`** unless there is a compelling reason already present in the code under test.
- **Use test autoloading**: when a plugin provides autoloaded `tests/mocks` or `tests/fixtures`, rely on that instead of manual `require_once`.

### PHPDoc (test classes and methods)

For test classes and for each `test_*` method, use a minimal docblock whose body is exactly **`Test.`** (no longer descriptions unless the current file already uses another pattern).

```php
/**
 * Tests.
 */
final class example_test extends advanced_testcase {

    /**
     * Test.
     */
    public function test_behaviour(): void {
```

### Data creation

- **Prefer plugin generators** over direct `$DB->insert_record()` when available.
- Use the **core data generator** for Moodle entities (courses, users, groups, etc.). Assign it to **`$dg`** once per test and call methods on that variable.
- **Variable names**: use short numbered names so relationships stay obvious—**`$c1`**, **`$c2`** for courses, **`$u1`**, **`$u2`** for users, and when several entities belong to the same course use a suffix such as **`$g1a`**, **`$g1b`** for two groups on course 1. Extend the same pattern to other types as needed.
- **Minimal generator data**: pass only the arguments (and array keys) required for the behaviour under test. Prefer defaults over custom fields unless the test depends on a specific value.
- **Use meaningful fixture values** when names, labels, identifiers, or other generated fields appear in assertions or search terms. Avoid opaque placeholder values unless the exact string is irrelevant to understanding the test.

```php
$dg = $this->getDataGenerator();
$c1 = $dg->create_course();
$u1 = $dg->create_user();
$g1a = $dg->create_group(['courseid' => $c1->id]);
$g1b = $dg->create_group(['courseid' => $c1->id]);
```

### Data providers

- Prefer **`@dataProvider`** when the test logic is identical across many cases and the data can be expressed as literals.
- When data must be generated (courses/contexts/etc.), either:
  - keep it generated inside a single `test_*` (still scenario-focused), or
  - use a provider for the *parameters* while generating the data in the test body.
- **Testing generated-data variations**: when scenarios depend on dynamically created records, use provider values as stable symbols for the generated fixtures and include the expected result in the provider row. In the test, create the fixtures once, map symbols to generated IDs/objects, and run the same assertion logic for every row. Avoid passing broad scenario names that make the test branch into separate mini-tests.
- **Naming**: Name the provider **`{name}_provider`**, where `{name}` is the consuming **`test_*` method’s name with the `test_` prefix removed** (e.g. `test_is_ruletype_reason_limit_reached_window` → `is_ruletype_reason_limit_reached_window_provider`).
- **Placement**: Each data provider method must sit **immediately above** the single `test_*` method that references it in `@dataProvider`. Do not group providers at the end of the class, above unrelated tests, or above the “first” consumer when only one test uses that provider.
- **Shared provider**: When **several** `test_*` methods cover the **same invalid-input intent** (e.g. falsy arguments and a non-resolving context id—not necessarily the **same** literal values in every case), define **one** provider with a **clear name** (e.g. **`invalid_context_value_provider`**) and place it **once** at the **top of the test class** (after the opening of the class). Each `@dataProvider` line references that method name.
- **PHPDoc on data-driven tests**: List other tags first (e.g. **`@param`**) and put **`@dataProvider`** **last** in the docblock.

### Testcase methods ordering

**Setup method**: Should be placed first. It needs good visibility.
**Several `test_*` methods for one function**: See **Order of `test_*` methods (same unit under test)** under Style above—core behaviour first, then increasing complexity.
**Custom assertions**: Custom assertion methods (e.g. `protected function assert_this_that(): bool`), are always placed at the end of the test class, they should not obstruct the natural flow of reading through the test cases.

## Built assets

Do **not** modify minified or built artifacts. Typical locations include `amd/build/` and `yui/build/` (and similar generated bundles under a plugin or component). Edit **source** files only.

Do **not** run npm, gulp, webpack, or other commands to compile or bundle JavaScript, CSS, or similar frontend assets unless the user explicitly asks you to. The user builds generated output (for example `amd/build/`, theme CSS, or other bundled artifacts) themselves after reviewing changes.
