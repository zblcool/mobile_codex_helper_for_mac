#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"

mobile_codex_stop_pid "${mobile_codex_caddy_pid_file}"

if lsof -nP -tiTCP:"${mobile_codex_proxy_port}" -sTCP:LISTEN >/dev/null 2>&1; then
  while IFS= read -r pid; do
    [[ -n "${pid}" ]] && kill "${pid}" >/dev/null 2>&1 || true
  done < <(lsof -nP -tiTCP:"${mobile_codex_proxy_port}" -sTCP:LISTEN)
  sleep 1
  if lsof -nP -tiTCP:"${mobile_codex_proxy_port}" -sTCP:LISTEN >/dev/null 2>&1; then
    while IFS= read -r pid; do
      [[ -n "${pid}" ]] && kill -9 "${pid}" >/dev/null 2>&1 || true
    done < <(lsof -nP -tiTCP:"${mobile_codex_proxy_port}" -sTCP:LISTEN)
  fi
fi

echo "Stopped Mobile Codex reverse proxy"
