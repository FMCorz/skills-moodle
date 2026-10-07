---
name: moodle-plugin-ci
description: Use when the user wants to reproduce Moodle plugin CI locally—typically moodle-plugin-ci in a dev container—not when explaining generic Docker or shell usage.
---

# moodle-plugin-ci (local Docker)

Replace **`<container>`** with the real container name (`docker ps`). Pass **absolute paths** for **`--standard`** and for each directory or file to scan. Examples use **illustrative paths**; substitute the paths that exist in that environment.

## Running checks

Invoke the **installed CLI by absolute path** (default install location below). Do not call **`vendor/bin/phpcs`** when you need **`--max-warnings`** or other **moodle-plugin-ci**-specific behaviour—use **`moodle-plugin-ci phpcs`**.

**PHPCS — example only:**

```bash
docker exec <container> /opt/moodle-plugin-ci/bin/moodle-plugin-ci phpcs --max-warnings=0 \
  --standard=/var/www/html/public/mod/mymod/phpcs.xml \
  /var/www/html/public/mod/mymod
```

Add more path arguments at the end if several trees share the same standard.

**Discover subcommands:**

```bash
docker exec <container> /opt/moodle-plugin-ci/bin/moodle-plugin-ci list
```

**Other jobs** (`install`, `phpunit`, `behat`, `grunt`, `mustache`, …) use the same binary after a full **`moodle-plugin-ci install`** layout; see [Moodle Plugin CI](https://moodlehq.github.io/moodle-plugin-ci/) and the plugin’s **`.github/workflows`** for order and flags. PHPCS alone does not need that install.

### Mustache prerequisites and diagnosis

The **`mustache`** command runs its bundled `vnu.jar` HTML validator through Java. When several unrelated templates report **`Problem calling HTML validator`**, check the runtime before editing templates:

```bash
docker exec <container> bash -c '
java -version
ls -lh /opt/moodle-plugin-ci/vendor/moodlehq/moodle-local_ci/node_modules/vnu-jar/build/dist/vnu.jar
'
```

If Java is missing on Debian/Ubuntu, install a headless runtime and rerun the check:

```bash
docker exec <container> bash -ec '
apt-get update -qq
apt-get install -y -qq default-jre-headless
java -version
'
```

Use `mustache -vvv` to expose the validator invocation. A generic validator warning means the tool did not receive valid validator JSON; only change a template after the runtime works and the linter reports a file-specific HTML problem. By contrast, **`Example context missing`** is template-specific: add the standard `@template` documentation section with valid **`Example context (json):`** data.

**`INFO: ESLint did not run`** is separate and non-fatal. With Moodle’s `public/` layout, Plugin CI may look for `public/node_modules/.bin/eslint` while dependencies are installed at the repository root. Compare both locations before blaming the template:

```bash
docker exec <container> bash -c '
ls -l /var/www/html/node_modules/.bin/eslint
ls -l /var/www/html/public/node_modules/.bin/eslint
'
```

If only the root executable exists, treat this as a Plugin CI layout issue. Verify JavaScript with the root Moodle toolchain as appropriate; do not alter templates or add `.mustachelintignore` entries merely to hide this message.

### Grunt and Browserslist

For **Grunt**, Plugin CI normally uses **cwd on the Moodle tree**, so **Browserslist** should resolve from **Moodle’s root `package.json`**, not from `/opt/moodle-plugin-ci`. If results look off, check **plugin-local `Gruntfile.js` / `package.json`**; use **`BROWSERSLIST`** only when intentionally overriding the query.

Grunt also enforces **Moodle’s Node engine** (see **Node.js** below); wrong versions fail before ESLint runs.

## Node.js (required for Grunt and Plugin CI install)

Moodle’s root **`package.json`** declares **`"engines": { "node": ">=22.11.0 <23" }`**. If **`node -v`** is outside that range, **`moodle-plugin-ci grunt`** exits with *Node version not satisfied*.

**Do not** rely on Debian/Ubuntu’s default **`apt install nodejs`** (e.g. Bookworm’s package is Node 18). Install **Node 22.x** instead.

**Debian / Ubuntu (NodeSource):**

```bash
docker exec <container> bash -ec '
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y -qq nodejs
node -v
'
```

The **`nodejs`** package from NodeSource includes **`npm`**. Run this **before** **`composer create-project moodlehq/moodle-plugin-ci`** (post-install may invoke npm) and before **`moodle-plugin-ci grunt`**.

If you only upgraded an existing container, **`docker exec`** the commands above; changes live in the container filesystem until the image is recreated—bake the same steps into your **Dockerfile** if you need them to persist.

## Installing moodle-plugin-ci in the container

Install per container (or bake into the image). **`/opt/moodle-plugin-ci`** lives in the **container layer**; recreating the container drops it unless the image includes these steps.

**Prerequisites:** **Node 22** (see **Node.js** above), PHP, curl, and a Java runtime for Mustache validation; permission to run **`apt-get`** and to write **`/opt`**. Install Node **before** this step so moodle-plugin-ci’s post-install **`npm`** step sees the right engine.

**Composer + moodle-plugin-ci:**

```bash
docker exec <container> bash -ec '
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
COMPOSER_ALLOW_SUPERUSER=1 composer create-project -n --no-dev --prefer-dist moodlehq/moodle-plugin-ci /opt/moodle-plugin-ci ^4
'
```

**Git safe.directory** (Composer/Git on a bind-mounted repo) — adjust the path to the repo root **inside** the container:

```bash
docker exec <container> git config --global --add safe.directory /var/www/html
```

---

## References

- [Moodle Plugin CI introduction](https://moodlehq.github.io/moodle-plugin-ci/)
- Each plugin’s **`.github/workflows/*.yml`** (when present) for how CI orders `create-project`, `install`, `moodle-plugin-ci phpcs`, and other jobs
