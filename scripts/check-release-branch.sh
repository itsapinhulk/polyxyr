#!/usr/bin/env bash
#
# check-release-branch.sh — verify the current branch is allowed to tag the
# package's current version:
#
#   * a minor release  YYYY.XX.0  must be tagged from `main`
#   * a patch release  YYYY.XX.N  must be tagged from `release-vYYYY.XX`
#
# The branch is taken from GITHUB_REF_NAME when set (CI), else the checked-out
# branch. Exits non-zero on a mismatch.
#
# Usage:
#   scripts/check-release-branch.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VERSION="$(sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$REPO_ROOT/src/rust/Cargo.toml" | head -n1)"

if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]{4}\.[0-9]+\.[0-9]+$'; then
    echo "error: version '$VERSION' is not YYYY.XX.PATCH CalVer" >&2
    exit 1
fi

IFS=. read -r year minor patch <<<"$VERSION"

BRANCH="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"

# 10# forces base 10 so a zero-padded patch isn't parsed as octal.
if [ "$((10#$patch))" -eq 0 ]; then
    expected="main"
else
    expected="release-v$year.$minor"
fi

if [ "$BRANCH" != "$expected" ]; then
    echo "error: version $VERSION must be tagged from '$expected', but branch is '$BRANCH'" >&2
    exit 1
fi

echo "ok: $VERSION may be tagged from '$BRANCH'"
