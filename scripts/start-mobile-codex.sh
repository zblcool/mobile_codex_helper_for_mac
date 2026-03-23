#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"

mobile_codex_ensure_dirs

if [[ ! -d "${mobile_codex_vendor_dir}" ]]; then
  echo "Upstream checkout not found: ${mobile_codex_vendor_dir}" >&2
  echo "Run scripts/setup-upstream-mac.sh first." >&2
  exit 1
fi

node_bin="$(mobile_codex_resolve_node || true)"
if [[ -z "${node_bin}" ]]; then
  echo "Node.js 22 not found. Run scripts/setup-upstream-mac.sh first." >&2
  exit 1
fi

npm_bin="$(cd "$(dirname "${node_bin}")" && pwd)/npm"
node_bin_dir="$(cd "$(dirname "${node_bin}")" && pwd)"

if [[ ! -f "${mobile_codex_vendor_dir}/dist/index.html" ]]; then
  if [[ ! -x "${npm_bin}" ]]; then
    echo "Frontend build not found and npm is unavailable. Run scripts/setup-upstream-mac.sh first." >&2
    exit 1
  fi

  echo "Frontend build missing; running a local production build..."
  (
    cd "${mobile_codex_vendor_dir}"
    PATH="${node_bin_dir}:${PATH}" npm_config_cache="${mobile_codex_runtime_dir}/npm-cache" "${npm_bin}" run build
  )
fi

existing_pid="$(mobile_codex_read_pid "${mobile_codex_app_pid_file}")"
if [[ -n "${existing_pid}" ]] && mobile_codex_pid_is_running "${existing_pid}"; then
  echo "Mobile Codex app is already running (PID ${existing_pid})."
  exit 0
fi

printf '\n==== START %s ====\n' "$(mobile_codex_timestamp)" >> "${mobile_codex_app_stdout_log}"
printf '\n==== START %s ====\n' "$(mobile_codex_timestamp)" >> "${mobile_codex_app_stderr_log}"

(
  cd "${mobile_codex_vendor_dir}"
  export NODE_ENV=production
  export HOST=127.0.0.1
  export PORT="${mobile_codex_app_port}"
  export CODEX_ONLY_HARDENED_MODE=true
  export VITE_CODEX_ONLY_HARDENED_MODE=true
  export ALLOW_QUERY_TOKEN_WS_FALLBACK=false
  export DISABLE_PROJECT_WATCHERS=true
  export DATABASE_PATH="${mobile_codex_vendor_dir}/server/database/auth.db"
  nohup "${node_bin}" server/index.js >> "${mobile_codex_app_stdout_log}" 2>> "${mobile_codex_app_stderr_log}" < /dev/null &
  echo $! > "${mobile_codex_app_pid_file}"
)

echo "Started Mobile Codex app on 127.0.0.1:${mobile_codex_app_port}"
