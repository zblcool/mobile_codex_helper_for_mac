#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-mobile-codex.sh"

mobile_codex_ensure_dirs
mkdir -p "${mobile_codex_caddy_root}/config" "${mobile_codex_caddy_root}/data"

caddy_bin="$(mobile_codex_resolve_caddy || true)"
if [[ -z "${caddy_bin}" ]]; then
  echo "Caddy not found; downloading a local Caddy runtime..."
  caddy_bin="$(mobile_codex_download_caddy)"
fi

existing_pid="$(mobile_codex_read_pid "${mobile_codex_caddy_pid_file}")"
if [[ -n "${existing_pid}" ]] && mobile_codex_pid_is_running "${existing_pid}"; then
  echo "Mobile Codex reverse proxy is already running (PID ${existing_pid})."
  exit 0
fi

cat > "${mobile_codex_caddy_config}" <<EOF
{
  auto_https off
  admin off
}

http://127.0.0.1:${mobile_codex_proxy_port} {
  encode zstd gzip

  header {
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
    Referrer-Policy "no-referrer"
    Permissions-Policy "camera=(), microphone=(), geolocation=()"
    Content-Security-Policy "default-src 'self'; base-uri 'self'; frame-ancestors 'none'; form-action 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' ws: wss: https:"
  }

  log {
    output file ${mobile_codex_caddy_access_log}
    format json
  }

  reverse_proxy 127.0.0.1:${mobile_codex_app_port}
}
EOF

printf '\n==== START %s ====\n' "$(mobile_codex_timestamp)" >> "${mobile_codex_caddy_stdout_log}"
printf '\n==== START %s ====\n' "$(mobile_codex_timestamp)" >> "${mobile_codex_caddy_stderr_log}"

XDG_CONFIG_HOME="${mobile_codex_caddy_root}/config" \
XDG_DATA_HOME="${mobile_codex_caddy_root}/data" \
HOME="${mobile_codex_caddy_root}" \
nohup "${caddy_bin}" run --config "${mobile_codex_caddy_config}" --adapter caddyfile >> "${mobile_codex_caddy_stdout_log}" 2>> "${mobile_codex_caddy_stderr_log}" < /dev/null &
echo $! > "${mobile_codex_caddy_pid_file}"

echo "Started Mobile Codex reverse proxy on 127.0.0.1:${mobile_codex_proxy_port}"
