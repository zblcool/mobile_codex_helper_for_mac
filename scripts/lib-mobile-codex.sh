#!/usr/bin/env bash

set -euo pipefail

mobile_codex_script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

mobile_codex_workspace() {
  cd "$(mobile_codex_script_dir)/.." && pwd
}

mobile_codex_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64) echo "x64" ;;
    *)
      echo "Unsupported CPU architecture: $(uname -m)" >&2
      return 1
      ;;
  esac
}

mobile_codex_caddy_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64) echo "amd64" ;;
    *)
      echo "Unsupported CPU architecture: $(uname -m)" >&2
      return 1
      ;;
  esac
}

mobile_codex_workspace_root="$(mobile_codex_workspace)"
mobile_codex_runtime_dir="${mobile_codex_workspace_root}/.runtime"
mobile_codex_tools_dir="${mobile_codex_runtime_dir}/tools"
mobile_codex_log_dir="${mobile_codex_workspace_root}/tmp/logs"
mobile_codex_vendor_dir="${MOBILE_CODEX_UPSTREAM_DIR:-${mobile_codex_workspace_root}/vendor/claudecodeui-1.25.2}"
mobile_codex_app_port="${MOBILE_CODEX_APP_PORT:-3001}"
mobile_codex_proxy_port="${MOBILE_CODEX_PROXY_PORT:-8080}"
mobile_codex_app_pid_file="${mobile_codex_runtime_dir}/mobile-codex-app.pid"
mobile_codex_caddy_pid_file="${mobile_codex_runtime_dir}/mobile-codex-caddy.pid"
mobile_codex_caddy_root="${mobile_codex_runtime_dir}/caddy"
mobile_codex_caddy_config="${mobile_codex_caddy_root}/Caddyfile"
mobile_codex_caddy_stdout_log="${mobile_codex_log_dir}/mobile-codex-caddy.stdout.log"
mobile_codex_caddy_stderr_log="${mobile_codex_log_dir}/mobile-codex-caddy.stderr.log"
mobile_codex_caddy_access_log="${mobile_codex_caddy_root}/logs/mobile-codex.access.json"
mobile_codex_app_stdout_log="${mobile_codex_log_dir}/mobile-codex-app.stdout.log"
mobile_codex_app_stderr_log="${mobile_codex_log_dir}/mobile-codex-app.stderr.log"
mobile_codex_remote_state_file="${mobile_codex_runtime_dir}/mobile-codex-remote-state.json"
mobile_codex_remote_target="http://127.0.0.1:${mobile_codex_app_port}"

export mobile_codex_workspace_root
export mobile_codex_runtime_dir
export mobile_codex_tools_dir
export mobile_codex_log_dir
export mobile_codex_vendor_dir
export mobile_codex_app_port
export mobile_codex_proxy_port
export mobile_codex_app_pid_file
export mobile_codex_caddy_pid_file
export mobile_codex_caddy_root
export mobile_codex_caddy_config
export mobile_codex_caddy_stdout_log
export mobile_codex_caddy_stderr_log
export mobile_codex_caddy_access_log
export mobile_codex_app_stdout_log
export mobile_codex_app_stderr_log
export mobile_codex_remote_state_file
export mobile_codex_remote_target

mobile_codex_require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    return 1
  fi
}

mobile_codex_ensure_dirs() {
  mkdir -p \
    "${mobile_codex_runtime_dir}" \
    "${mobile_codex_tools_dir}" \
    "${mobile_codex_log_dir}" \
    "${mobile_codex_caddy_root}/logs"
}

mobile_codex_node_major() {
  "$1" -p "process.versions.node.split('.')[0]" 2>/dev/null
}

mobile_codex_resolve_node() {
  if [[ -n "${MOBILE_CODEX_NODE:-}" && -x "${MOBILE_CODEX_NODE}" ]]; then
    echo "${MOBILE_CODEX_NODE}"
    return 0
  fi

  local local_node="${mobile_codex_tools_dir}/node/current/bin/node"
  if [[ -x "${local_node}" ]]; then
    echo "${local_node}"
    return 0
  fi

  if command -v node >/dev/null 2>&1; then
    local system_node
    system_node="$(command -v node)"
    local major
    major="$(mobile_codex_node_major "${system_node}" || true)"
    if [[ "${major}" =~ ^[0-9]+$ && "${major}" -ge 22 ]]; then
      echo "${system_node}"
      return 0
    fi
  fi

  return 1
}

mobile_codex_resolve_npm() {
  local node_bin
  node_bin="$(mobile_codex_resolve_node)"
  local npm_bin
  npm_bin="$(cd "$(dirname "${node_bin}")" && pwd)/npm"
  if [[ -x "${npm_bin}" ]]; then
    echo "${npm_bin}"
    return 0
  fi

  if command -v npm >/dev/null 2>&1; then
    echo "$(command -v npm)"
    return 0
  fi

  echo "npm executable not found for ${node_bin}" >&2
  return 1
}

mobile_codex_download_node() {
  mobile_codex_require_command curl
  mobile_codex_require_command tar
  mobile_codex_ensure_dirs

  local arch
  arch="$(mobile_codex_caddy_arch)"

  local shasums_url="https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt"
  local archive_name
  archive_name="$(curl -fsSL "${shasums_url}" | awk '/darwin-'"${arch}"'\.tar\.gz$/ {print $2; exit}')"

  if [[ -z "${archive_name}" ]]; then
    echo "Unable to resolve a Node.js 22 download for darwin-${arch}" >&2
    return 1
  fi

  local version
  version="$(sed -E 's#^node-(v[0-9.]+)-darwin-'"${arch}"'\.tar\.gz$#\1#' <<<"${archive_name}")"
  local target_dir="${mobile_codex_tools_dir}/node/${version}"
  local current_link="${mobile_codex_tools_dir}/node/current"

  if [[ ! -x "${target_dir}/bin/node" ]]; then
    local tmp_dir="${mobile_codex_tools_dir}/node/.download-${version}"
    rm -rf "${tmp_dir}"
    mkdir -p "${tmp_dir}"
    curl -fsSL "https://nodejs.org/dist/latest-v22.x/${archive_name}" -o "${tmp_dir}/${archive_name}"
    tar -xzf "${tmp_dir}/${archive_name}" -C "${tmp_dir}"
    mv "${tmp_dir}/node-${version}-darwin-${arch}" "${target_dir}"
    rm -rf "${tmp_dir}"
  fi

  mkdir -p "$(dirname "${current_link}")"
  rm -f "${current_link}"
  ln -s "${target_dir}" "${current_link}"
  echo "${current_link}/bin/node"
}

mobile_codex_resolve_caddy() {
  if [[ -n "${MOBILE_CODEX_CADDY:-}" && -x "${MOBILE_CODEX_CADDY}" ]]; then
    echo "${MOBILE_CODEX_CADDY}"
    return 0
  fi

  local local_caddy="${mobile_codex_tools_dir}/caddy/current/caddy"
  if [[ -x "${local_caddy}" ]]; then
    echo "${local_caddy}"
    return 0
  fi

  if command -v caddy >/dev/null 2>&1; then
    echo "$(command -v caddy)"
    return 0
  fi

  return 1
}

mobile_codex_download_caddy() {
  mobile_codex_require_command curl
  mobile_codex_require_command tar
  mobile_codex_ensure_dirs

  local arch
  arch="$(mobile_codex_arch)"

  local asset_url
  asset_url="$(python3 - "${arch}" <<'PY'
import json
import sys
import urllib.request

arch = sys.argv[1]
with urllib.request.urlopen("https://api.github.com/repos/caddyserver/caddy/releases/latest") as response:
    data = json.load(response)

for asset in data.get("assets", []):
    name = asset.get("name", "")
    if name.endswith(f"mac_{arch}.tar.gz"):
        print(asset["browser_download_url"])
        break
PY
)"

  if [[ -z "${asset_url}" ]]; then
    echo "Unable to resolve a Caddy download for mac-${arch}" >&2
    return 1
  fi

  local filename
  filename="$(basename "${asset_url}")"
  local version
  version="$(sed -E 's#^caddy_([0-9.]+)_mac_'"${arch}"'\.tar\.gz$#\1#' <<<"${filename}")"
  local target_dir="${mobile_codex_tools_dir}/caddy/${version}"
  local current_link="${mobile_codex_tools_dir}/caddy/current"

  if [[ ! -x "${target_dir}/caddy" ]]; then
    local tmp_dir="${mobile_codex_tools_dir}/caddy/.download-${version}"
    rm -rf "${tmp_dir}"
    mkdir -p "${tmp_dir}"
    curl -LfsS "${asset_url}" -o "${tmp_dir}/${filename}"
    tar -xzf "${tmp_dir}/${filename}" -C "${tmp_dir}"
    mkdir -p "${target_dir}"
    mv "${tmp_dir}/caddy" "${target_dir}/caddy"
    chmod +x "${target_dir}/caddy"
    rm -rf "${tmp_dir}"
  fi

  mkdir -p "$(dirname "${current_link}")"
  rm -f "${current_link}"
  ln -s "${target_dir}" "${current_link}"
  echo "${current_link}/caddy"
}

mobile_codex_resolve_tailscale() {
  if [[ -n "${MOBILE_CODEX_TAILSCALE:-}" && -x "${MOBILE_CODEX_TAILSCALE}" ]]; then
    echo "${MOBILE_CODEX_TAILSCALE}"
    return 0
  fi

  if command -v tailscale >/dev/null 2>&1; then
    echo "$(command -v tailscale)"
    return 0
  fi

  local app_cli="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
  if [[ -x "${app_cli}" ]]; then
    echo "${app_cli}"
    return 0
  fi

  return 1
}

mobile_codex_pid_is_running() {
  local pid="${1:-}"
  [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null
}

mobile_codex_read_pid() {
  local pid_file="${1:-}"
  if [[ -f "${pid_file}" ]]; then
    tr -d '[:space:]' < "${pid_file}"
  fi
}

mobile_codex_stop_pid() {
  local pid_file="${1:-}"
  local pid
  pid="$(mobile_codex_read_pid "${pid_file}")"
  if [[ -z "${pid}" ]]; then
    return 0
  fi

  if mobile_codex_pid_is_running "${pid}"; then
    kill "${pid}" 2>/dev/null || true
    sleep 1
    if mobile_codex_pid_is_running "${pid}"; then
      kill -9 "${pid}" 2>/dev/null || true
    fi
  fi

  rm -f "${pid_file}"
}

mobile_codex_timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}
