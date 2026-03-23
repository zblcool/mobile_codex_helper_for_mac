#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${script_dir}/start-mobile-codex.sh"
sleep 5
"${script_dir}/start-mobile-caddy.sh"

