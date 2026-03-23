#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stop-mobile-caddy.sh" >/dev/null 2>&1 || true
mobile_codex_stop_pid "${mobile_codex_app_pid_file}"

for port in "${mobile_codex_app_port}" "${mobile_codex_proxy_port}"; do
  if lsof -nP -tiTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1; then
    while IFS= read -r pid; do
      [[ -n "${pid}" ]] && kill "${pid}" >/dev/null 2>&1 || true
    done < <(lsof -nP -tiTCP:"${port}" -sTCP:LISTEN)
    sleep 1
    if lsof -nP -tiTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1; then
      while IFS= read -r pid; do
        [[ -n "${pid}" ]] && kill -9 "${pid}" >/dev/null 2>&1 || true
      done < <(lsof -nP -tiTCP:"${port}" -sTCP:LISTEN)
    fi
  fi
done

tailscale_bin="$(mobile_codex_resolve_tailscale || true)"
if [[ -n "${tailscale_bin}" ]]; then
  "${tailscale_bin}" serve reset >/dev/null 2>&1 || true
fi

rm -f "${mobile_codex_remote_state_file}"

echo "Stopped Mobile Codex stack"
