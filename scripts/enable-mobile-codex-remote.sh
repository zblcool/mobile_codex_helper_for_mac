#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"
mobile_codex_ensure_dirs

tailscale_bin="$(mobile_codex_resolve_tailscale || true)"
if [[ -z "${tailscale_bin}" ]]; then
  echo "Tailscale CLI not found. Install Tailscale or set MOBILE_CODEX_TAILSCALE." >&2
  exit 1
fi

status_json="$("${tailscale_bin}" status --json)"
backend_state="$(STATUS_JSON="${status_json}" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["STATUS_JSON"])
print(data.get("BackendState", ""))
PY
)"

if [[ "${backend_state}" != "Running" ]]; then
  auth_url="$(STATUS_JSON="${status_json}" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["STATUS_JSON"])
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
serve_status_json="$("${tailscale_bin}" serve status --json)"

REMOTE_STATE_FILE="${mobile_codex_remote_state_file}" STATUS_JSON="${status_json}" SERVE_STATUS_JSON="${serve_status_json}" python3 - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

status = json.loads(os.environ["STATUS_JSON"])
serve = json.loads(os.environ["SERVE_STATUS_JSON"])
web_items = list((serve.get("Web") or {}).items())

host = ""
target = None
if web_items:
    host_and_port, config = web_items[0]
    host = str(host_and_port).replace(":443", "")
    target = ((((config or {}).get("Handlers") or {}).get("/") or {}).get("Proxy"))

dns_name = str(((status.get("Self") or {}).get("DNSName") or "")).rstrip(".")
url_host = host or dns_name
payload = {
    "published": bool(web_items),
    "url": f"https://{url_host}" if url_host else None,
    "target": target,
    "tailscale_dns_name": dns_name,
    "backend_state": status.get("BackendState"),
    "tailnet": (status.get("CurrentTailnet") or {}).get("Name"),
    "updated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
}

Path(os.environ["REMOTE_STATE_FILE"]).write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY

"${tailscale_bin}" serve status
