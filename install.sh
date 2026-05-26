#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEST="$HOME/.agents/skills"

mkdir -p "$DEST"

for skill in "$ROOT"/*; do
    [ -d "$skill" ] || continue
    [ -f "$skill/SKILL.md" ] || continue

    name=$(basename -- "$skill")
    target="$DEST/$name"

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$(readlink -f -- "$target" 2>/dev/null || true)" != "$skill" ]; then
            printf '%s\n' "Skipping $name: $target already exists and does not point to $skill" >&2
        fi
        continue
    fi

    ln -s "$skill" "$target"
    printf '%s\n' "Linked $name"
done
