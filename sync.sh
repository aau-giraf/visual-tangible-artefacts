#!/usr/bin/env bash
# sync.sh — Reset local dev-main to match upstream after a squash-merge.
#
# Usage:
#   ./sync.sh              # sync dev-main
#   ./sync.sh main         # sync main (or any branch)
#
# Why this exists:
#   When PRs are squash-merged on GitHub, the upstream branch gets a NEW commit
#   (different SHA) that replaces your original commits. Your local branch still
#   has the old commits, causing "divergent branches" errors on the next pull.
#   This script hard-resets your local branch to match upstream, then pushes to
#   your fork so both are in sync.

set -euo pipefail

BRANCH="${1:-dev-main}"
UPSTREAM="upstream"
FORK="origin"

# Ensure we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Not inside a git repository"
  exit 1
fi

# Ensure upstream remote exists
if ! git remote get-url "$UPSTREAM" &>/dev/null; then
  echo "❌ Remote '$UPSTREAM' not found. Add it with:"
  echo "   git remote add upstream https://github.com/aau-giraf/visual-tangible-artefacts.git"
  exit 1
fi

echo "🔄 Fetching $UPSTREAM..."
git fetch "$UPSTREAM"

# Stash any uncommitted changes
STASHED=false
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "📦 Stashing uncommitted changes..."
  git stash push -m "sync.sh auto-stash"
  STASHED=true
fi

echo "🔀 Switching to $BRANCH..."
git checkout "$BRANCH"

echo "⬇️  Resetting to $UPSTREAM/$BRANCH..."
git reset --hard "$UPSTREAM/$BRANCH"

echo "⬆️  Pushing to $FORK/$BRANCH..."
git push "$FORK" "$BRANCH" --force-with-lease

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
  echo "📦 Restoring stashed changes..."
  git stash pop
fi

echo "✅ $BRANCH is now in sync with $UPSTREAM/$BRANCH"
