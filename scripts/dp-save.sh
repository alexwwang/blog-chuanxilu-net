#!/usr/bin/env bash
# dp-save.sh — Sync design docs between main worktree and local-assets worktree
# Usage:
#   dp-save.sh <commit message>    # main → local-assets (save, additive only)
#   dp-save.sh --prune <message>   # main → local-assets (save + remove stale files)
#   dp-save.sh --restore           # local-assets → main (restore after rebase)
#   dp-save.sh --force --restore   # local-assets → main (skip confirmation)
#   dp-save.sh --force <message>   # main → local-assets (skip uncommitted-changes warning)
#
# Customize via environment: DOCS_DIR, WORKTREE

set -euo pipefail

command -v rsync >/dev/null || { echo "Error: rsync is required but not found" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel)"
DOCS_DIR="${DOCS_DIR:-design_plan}"
WORKTREE="${WORKTREE:-$REPO_ROOT/../$(basename "$REPO_ROOT")-local-assets}"

# Guard: must run from main worktree, not from inside the worktree
BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$BRANCH" = "local-assets" ]; then
  echo "Error: run dp-save.sh from the main worktree, not from the worktree" >&2
  exit 1
fi

if [ ! -d "$WORKTREE/.git" ] && [ ! -f "$WORKTREE/.git" ]; then
  echo "Error: worktree not found at $WORKTREE" >&2
  echo "Run: git worktree add $(basename "$REPO_ROOT")-local-assets local-assets" >&2
  exit 1
fi

# Parse --force flag
FORCE=""
if [ "${1:-}" = "--force" ]; then
  FORCE=1
  shift
fi

# --- Restore mode: local-assets → main ---
if [ "${1:-}" = "--restore" ]; then
  if [ $# -gt 0 ]; then
    echo "Error: unexpected argument '$1' after --restore" >&2
    exit 1
  fi
  if [ ! -d "$WORKTREE/$DOCS_DIR" ]; then
    echo "Error: $DOCS_DIR/ not found in worktree" >&2
    exit 1
  fi
  if [ -z "$FORCE" ]; then
    if [ ! -t 0 ]; then
      echo "Error: --restore requires confirmation; use --force for non-interactive runs" >&2
      exit 1
    fi
    read -p "Restore will overwrite $DOCS_DIR/ in main. Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  fi
  rsync -a "$WORKTREE/$DOCS_DIR/" "$REPO_ROOT/$DOCS_DIR/"
  count=$(find "$REPO_ROOT/$DOCS_DIR" -type f -not -name '.DS_Store' | wc -l | tr -d ' ')
  echo "Restored $count files from local-assets."
  exit 0
fi

# --- Save mode: main → local-assets ---
RSYNC_FLAGS=(-a)
if [ "${1:-}" = "--prune" ]; then
  RSYNC_FLAGS=(-a --delete)
  shift
fi

# --prune and --restore are mutually exclusive
if [ "${1:-}" = "--restore" ]; then
  echo "Error: --prune and --restore are mutually exclusive" >&2
  exit 1
fi

MSG="${1:-update $DOCS_DIR $(date +%Y-%m-%d\ %H:%M)}"

if [[ "${MSG:-}" == --* ]]; then
  echo "Error: unknown flag $MSG" >&2
  exit 1
fi

if [ ! -d "$REPO_ROOT/$DOCS_DIR" ]; then
  echo "Error: $DOCS_DIR/ not found" >&2
  exit 1
fi

# Warn if worktree has uncommitted changes (would be overwritten by save)
if [ -z "$FORCE" ] && ! git -C "$WORKTREE" diff --quiet HEAD -- "$DOCS_DIR/" 2>/dev/null; then
  echo "Warning: worktree has uncommitted changes in $DOCS_DIR/ that may be overwritten." >&2
  echo "Use --force to proceed, or commit in the worktree first." >&2
  exit 1
fi

rsync "${RSYNC_FLAGS[@]}" "$REPO_ROOT/$DOCS_DIR/" "$WORKTREE/$DOCS_DIR/"
git -C "$WORKTREE" add -f "$DOCS_DIR/"

if git -C "$WORKTREE" diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

git -C "$WORKTREE" commit -m "$MSG"
echo "Saved to local-assets: $MSG"
