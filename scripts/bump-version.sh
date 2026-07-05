#!/usr/bin/env bash
#
# bump-version.sh — set the package version using CalVer `YYYY.XX.PATCH`, where
# XX is the zero-padded release number within the year (starts at 01 each year),
# and write it into both manifests (src/rust/Cargo.toml, src/python/pyproject.toml).
#
# Usage:
#   scripts/bump-version.sh [minor]     # next release this year: YYYY.(XX+1).0
#                                        #   (or YYYY.01.0 when the year rolled over)
#   scripts/bump-version.sh patch       # patch the current release: YYYY.XX.(PATCH+1)
#   scripts/bump-version.sh <version>   # set an explicit YYYY.XX.PATCH
#
# Defaults to `minor`. Only edits the manifests; commit/tag separately.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUST_MANIFEST="$REPO_ROOT/src/rust/Cargo.toml"
PY_MANIFEST="$REPO_ROOT/src/python/pyproject.toml"

MODE="${1:-minor}"

# First `version = "x"` line (the [package]/[project] version, not rust-version).
read_version() {
    sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n1
}

# Replace the quoted value on the first `version =` line only.
write_version() {
    local file="$1" new="$2" tmp
    tmp="$(mktemp)"
    awk -v v="$new" '
        /^version[[:space:]]*=/ && !done { sub(/"[^"]*"/, "\"" v "\""); done=1 }
        { print }
    ' "$file" >"$tmp"
    mv "$tmp" "$file"
}

CUR="$(read_version "$RUST_MANIFEST")"
if [ -z "$CUR" ]; then
    echo "error: could not read current version from $RUST_MANIFEST" >&2
    exit 1
fi

YEAR="$(date -u +%Y)"
IFS=. read -r cy cx cp <<<"$CUR"

case "$MODE" in
    minor)
        # 10# forces base 10 so a zero-padded XX (e.g. 09) isn't read as octal.
        if [ "$cy" = "$YEAR" ]; then
            next=$((10#$cx + 1))
        else
            next=1
        fi
        NEW="$YEAR.$(printf '%02d' "$next").0"
        ;;
    patch)
        if [ "$cy" != "$YEAR" ]; then
            echo "error: current version $CUR is not from $YEAR; cut a 'minor' instead" >&2
            exit 1
        fi
        NEW="$cy.$cx.$((10#$cp + 1))"
        ;;
    *)
        # explicit version — must be YYYY.XX.PATCH (all numeric)
        if ! printf '%s' "$MODE" | grep -Eq '^[0-9]{4}\.[0-9]+\.[0-9]+$'; then
            echo "error: '$MODE' is not a valid YYYY.XX.PATCH version" >&2
            exit 2
        fi
        NEW="$MODE"
        ;;
esac

if [ "$NEW" = "$CUR" ]; then
    echo "error: new version equals current ($CUR)" >&2
    exit 1
fi

write_version "$RUST_MANIFEST" "$NEW"
write_version "$PY_MANIFEST" "$NEW"

echo "$CUR -> $NEW"
