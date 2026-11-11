#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
revision="$(cat nodeql-revision)"
if [[ ! "$revision" =~ ^[a-f0-9]{40}$ ]]; then
  echo "nodeql-revision must contain one full Git commit SHA." >&2
  exit 1
fi

checkout=.nodeql
if [[ ! -e .nodeql ]]; then
  checkout="$(mktemp -d .nodeql-fetch.XXXXXXXX)"
  trap 'rm -rf -- "$checkout"' EXIT
  git init --quiet "$checkout"
elif [[ ! -d .nodeql/.git ]]; then
  echo ".nodeql must be a Git checkout." >&2
  exit 1
fi

if ! git -C "$checkout" cat-file -e "${revision}^{commit}" 2>/dev/null; then
  git -C "$checkout" fetch --depth=1 "${NODEQL_SOURCE_URL:-https://github.com/Kartoffelspalt/NodeQL.git}" "$revision"
fi
GIT_LFS_SKIP_SMUDGE=1 git -C "$checkout" checkout --quiet --detach "$revision"
if [[ "$checkout" != .nodeql ]]; then
  mv "$checkout" .nodeql
  trap - EXIT
fi
