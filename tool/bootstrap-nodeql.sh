#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
revision="$(cat nodeql-revision)"
if [[ ! "$revision" =~ ^[a-f0-9]{40}$ ]]; then
  echo "nodeql-revision must contain one full Git commit SHA." >&2
  exit 1
fi
patch="$PWD/tool/nodeql-patches/workshop-palette.patch"

checkout=.nodeql
if [[ ! -e .nodeql ]]; then
  checkout="$(mktemp -d .nodeql-fetch.XXXXXXXX)"
  trap 'rm -rf -- "$checkout"' EXIT
  git init --quiet "$checkout"
elif [[ ! -d .nodeql/.git ]]; then
  echo ".nodeql must be a Git checkout." >&2
  exit 1
fi

# The overlay uses the checked-in LF line endings on every runner.
git -C "$checkout" config --local core.autocrlf false
if ! git -C "$checkout" cat-file -e "${revision}^{commit}" 2>/dev/null; then
  git -C "$checkout" fetch --depth=1 "${NODEQL_SOURCE_URL:-https://github.com/Kartoffelspalt/NodeQL.git}" "$revision"
fi
applied_patch="$PWD/$checkout/.git/workshop-admin-overlay.patch"
# Keep the last overlay so updates can remove it without resetting the checkout.
if [[ -f "$applied_patch" && "$(git -C "$checkout" rev-parse HEAD)" == "$revision" ]] &&
   cmp -s "$applied_patch" "$patch" &&
   git -C "$checkout" apply --reverse --check "$applied_patch" 2>/dev/null; then
  exit 0
fi
if [[ -f "$applied_patch" ]]; then
  if git -C "$checkout" apply --reverse --check "$applied_patch" 2>/dev/null; then
    git -C "$checkout" apply --reverse "$applied_patch"
  elif git -C "$checkout" apply --check "$applied_patch" 2>/dev/null; then
    :
  else
    echo "The Workshop Admin overlay in .nodeql has local changes." >&2
    exit 1
  fi
  rm -- "$applied_patch"
fi

GIT_LFS_SKIP_SMUDGE=1 git -C "$checkout" checkout --quiet --detach "$revision"
git -C "$checkout" apply "$patch"
cp -- "$patch" "$applied_patch"
if [[ "$checkout" != .nodeql ]]; then
  mv "$checkout" .nodeql
  trap - EXIT
fi
