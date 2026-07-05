#!/usr/bin/env bash
#
# tag.sh — read the package version and create an annotated git tag
# `v<version>`, then push it (pushing a `v*` tag is what triggers the publish
# workflow). When tagging a minor release (YYYY.XX.0) it also creates the
# `release-vYYYY.XX` branch that later patch releases are tagged from.
#
# Assumes the Rust and Python versions already match, and that the current
# branch is valid for the version; run check-versions.sh / check-release-branch.sh
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

# A minor release (YYYY.XX.0) opens a release-vYYYY.XX branch for its patches.
IFS=. read -r year minor patch <<<"$VERSION"
BRANCH=""
if [ "$patch" -eq 0 ]; then
    BRANCH="release-v$year.$minor"
    if git rev-parse -q --verify "refs/heads/$BRANCH" >/dev/null; then
        echo "error: branch $BRANCH already exists" >&2
        exit 1
    fi
    echo "==> creating release branch $BRANCH"
    git branch "$BRANCH" "$TAG"
fi

if [ "$PUSH" -eq 1 ]; then
    echo "==> pushing tag $TAG"
    git push origin "$TAG"
    if [ -n "$BRANCH" ]; then
        echo "==> pushing release branch $BRANCH"
        git push origin "$BRANCH"
    fi
else
    echo "==> --no-push set; tag${BRANCH:+ and branch $BRANCH} created locally only"
fi
