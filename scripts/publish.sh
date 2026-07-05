#!/usr/bin/env bash
#
# publish.sh — build and publish the `polyxyr` packages to crates.io and PyPI.
#
# Layout (relative to repo root):
#   src/rust    -> Rust crate   (cargo)
#   src/python  -> Python package (uv / hatchling)
#
# Usage:
#   scripts/publish.sh [--dry-run] [rust|python|all]
#
# Auth (only needed for a real, non-dry-run publish):
#   crates.io : `cargo login` beforehand, or set CARGO_REGISTRY_TOKEN
#   PyPI      : set UV_PUBLISH_TOKEN, or set TRUSTED_PUBLISHING=1 to use OIDC
#               trusted publishing (from a CI job with `id-token: write`).
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUST_DIR="$REPO_ROOT/src/rust"
PY_DIR="$REPO_ROOT/src/python"

DRY_RUN=0
TARGET="all"

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        rust|python|all) TARGET="$arg" ;;
        -h|--help)
            sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "error: unknown argument '$arg'" >&2; exit 2 ;;
    esac
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }

publish_rust() {
    log "Rust crate: $RUST_DIR"
    if ! command -v cargo >/dev/null 2>&1; then
        warn "cargo not found — install Rust from https://rustup.rs and re-run. Skipping crate."
        return 1
    fi
    ( cd "$RUST_DIR" && cargo package )
    if [ "$DRY_RUN" -eq 1 ]; then
        log "[dry-run] cargo publish --dry-run"
        ( cd "$RUST_DIR" && cargo publish --dry-run )
    else
        log "cargo publish"
        ( cd "$RUST_DIR" && cargo publish )
    fi
}

publish_python() {
    log "Python package: $PY_DIR"
    if ! command -v uv >/dev/null 2>&1; then
        warn "uv not found — install from https://docs.astral.sh/uv. Skipping package."
        return 1
    fi
    ( cd "$PY_DIR" && rm -rf dist && uv build )
    if [ "$DRY_RUN" -eq 1 ]; then
        log "[dry-run] built artifacts (not uploaded):"
        ls -1 "$PY_DIR/dist"
    elif [ "${TRUSTED_PUBLISHING:-0}" = "1" ]; then
        log "uv publish (trusted publishing / OIDC)"
        ( cd "$PY_DIR" && uv publish --trusted-publishing always )
    else
        log "uv publish (token)"
        ( cd "$PY_DIR" && uv publish )
    fi
}

rc=0
case "$TARGET" in
    rust)   publish_rust   || rc=$? ;;
    python) publish_python || rc=$? ;;
    all)    publish_rust   || rc=$?; publish_python || rc=$? ;;
esac

if [ "$rc" -ne 0 ]; then
    warn "one or more targets were skipped or failed (see above)"
fi
exit "$rc"
