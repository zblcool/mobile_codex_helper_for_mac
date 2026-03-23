#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"

tailscale_bin="$(mobile_codex_resolve_tailscale || true)"
if [[ -z "${tailscale_bin}" ]]; then
  echo "Tailscale CLI not found. Install Tailscale or set MOBILE_CODEX_TAILSCALE." >&2
  exit 1
fi

status_json="$("${tailscale_bin}" status --json)"
backend_state="$(python3 - <<'PY' <<<"${status_json}"
import json
import sys
data = json.load(sys.stdin)
print(data.get("BackendState", ""))
PY
)"

if [[ "${backend_state}" != "Running" ]]; then
  auth_url="$(python3 - <<'PY' <<<"${status_json}"
import json
import sys
data = json.load(sys.stdin)
print(data.get("AuthURL", ""))
PY
)"
  if [[ -n "${auth_url}" ]]; then
    echo "Tailscale login required: ${auth_url}" >&2
    exit 1
  fi

  echo "Tailscale is not running yet." >&2
  exit 1
fi

"${tailscale_bin}" serve --bg "${mobile_codex_remote_target}"
"${tailscale_bin}" serve status
