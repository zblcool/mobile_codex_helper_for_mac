#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"

source_root="${mobile_codex_workspace_root}/upstream-overrides/claudecodeui-1.25.2"
target_root="${mobile_codex_vendor_dir}"

if [[ ! -d "${source_root}" ]]; then
  echo "Override source not found: ${source_root}" >&2
  exit 1
fi

if [[ ! -d "${target_root}" ]]; then
  echo "Upstream checkout not found: ${target_root}" >&2
  exit 1
fi

rsync -a "${source_root}/" "${target_root}/"

copied_count="$(find "${source_root}" -type f | wc -l | tr -d '[:space:]')"
echo "Applied ${copied_count} override files to ${target_root}"

