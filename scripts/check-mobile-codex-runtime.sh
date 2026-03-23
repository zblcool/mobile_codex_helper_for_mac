#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"

node_bin="$(mobile_codex_resolve_node || true)"
npm_bin="$(mobile_codex_resolve_npm || true)"
caddy_bin="$(mobile_codex_resolve_caddy || true)"
tailscale_bin="$(mobile_codex_resolve_tailscale || true)"
python_bin="$(command -v python3 || true)"

cat <<EOF
Workspace            = ${mobile_codex_workspace_root}
UpstreamExists       = $( [[ -d "${mobile_codex_vendor_dir}" ]] && echo True || echo False )
UpstreamPath         = ${mobile_codex_vendor_dir}
Node                 = ${node_bin:-}
NodeVersion          = $( [[ -n "${node_bin}" ]] && "${node_bin}" --version || true )
npm                  = ${npm_bin:-}
Caddy                = ${caddy_bin:-}
Tailscale            = ${tailscale_bin:-}
Python               = ${python_bin:-}
AppPort              = ${mobile_codex_app_port}
ProxyPort            = ${mobile_codex_proxy_port}
AuthDbCandidates     = ${mobile_codex_vendor_dir}/server/database/auth.db, \$HOME/.codex/auth.db
EOF

