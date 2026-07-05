#!/usr/bin/env bash
#
# tag.sh — read the package version and create an annotated git tag
# `v<version>`, then push it (pushing a `v*` tag is what triggers the publish
# workflow).
#
# Assumes the Rust and Python versions already match; run check-versions.sh
# first if you need to confirm that.
#
# Usage:
#   scripts/tag.sh [--no-push]
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PUSH=1
for arg in "$@"; do
    case "$arg" in
        --no-push) PUSH=0 ;;
        -h|--help) sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "error: unknown argument '$arg'" >&2; exit 2 ;;
    esac
done

# Read the version from the Rust manifest (first `version = "x"` line, which is
# the [package] version, not `rust-version`).
VERSION="$(sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$REPO_ROOT/src/rust/Cargo.toml" | head -n1)"

if [ -z "$VERSION" ]; then
    echo "error: could not read version from src/rust/Cargo.toml" >&2
    exit 1
fi

TAG="v$VERSION"

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "error: tag $TAG already exists" >&2
    exit 1
fi

echo "==> creating tag $TAG"
git tag -a "$TAG" -m "polyxyr $VERSION"

if [ "$PUSH" -eq 1 ]; then
    echo "==> pushing tag $TAG"
    git push origin "$TAG"
else
    echo "==> --no-push set; tag created locally only"
fi
