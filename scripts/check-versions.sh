#!/usr/bin/env bash
#
# check-versions.sh — verify the Rust and Python package versions match.
#
# On success prints the shared version to stdout and exits 0.
# On mismatch (or an unreadable manifest) prints a diagnostic to stderr and
# exits 1.
#
# Usage:
#   scripts/check-versions.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUST_MANIFEST="$REPO_ROOT/src/rust/Cargo.toml"
PY_MANIFEST="$REPO_ROOT/src/python/pyproject.toml"

# First `version = "x"` line in a TOML file (matches [package]/[project],
# not `rust-version`).
extract_version() {
    sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -n1
}

RUST_VERSION="$(extract_version "$RUST_MANIFEST")"
PY_VERSION="$(extract_version "$PY_MANIFEST")"

if [ -z "$RUST_VERSION" ]; then
    echo "error: could not read version from $RUST_MANIFEST" >&2
    exit 1
fi
if [ -z "$PY_VERSION" ]; then
    echo "error: could not read version from $PY_MANIFEST" >&2
    exit 1
fi
if [ "$RUST_VERSION" != "$PY_VERSION" ]; then
    echo "error: version mismatch — rust=$RUST_VERSION python=$PY_VERSION" >&2
    exit 1
fi

echo "$RUST_VERSION"
