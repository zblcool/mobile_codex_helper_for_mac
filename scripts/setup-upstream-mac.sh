#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"

mobile_codex_require_command git
mobile_codex_require_command python3

mkdir -p "$(dirname "${mobile_codex_vendor_dir}")"

if [[ ! -d "${mobile_codex_vendor_dir}/.git" && ! -f "${mobile_codex_vendor_dir}/package.json" ]]; then
  git clone --depth 1 --branch v1.25.2 https://github.com/siteboon/claudecodeui.git "${mobile_codex_vendor_dir}"
fi

"${mobile_codex_workspace_root}/scripts/apply-upstream-overrides.sh"

node_bin="$(mobile_codex_resolve_node || true)"
if [[ -z "${node_bin}" ]]; then
  echo "System Node.js 22 not found; downloading a local Node.js 22 runtime..."
  node_bin="$(mobile_codex_download_node)"
fi

npm_bin="$(cd "$(dirname "${node_bin}")" && pwd)/npm"
if [[ ! -x "${npm_bin}" ]]; then
  npm_bin="$(mobile_codex_resolve_npm)"
fi

node_bin_dir="$(cd "$(dirname "${node_bin}")" && pwd)"
npm_cache_dir="${mobile_codex_runtime_dir}/npm-cache"
mkdir -p "${npm_cache_dir}"

echo "Using Node: ${node_bin}"
echo "Using npm:  ${npm_bin}"
echo "Using npm cache: ${npm_cache_dir}"

(
  cd "${mobile_codex_vendor_dir}"
  PATH="${node_bin_dir}:${PATH}" npm_config_cache="${npm_cache_dir}" "${npm_bin}" install
  PATH="${node_bin_dir}:${PATH}" npm_config_cache="${npm_cache_dir}" "${npm_bin}" run build
)

echo "Upstream checkout is ready at ${mobile_codex_vendor_dir}"
