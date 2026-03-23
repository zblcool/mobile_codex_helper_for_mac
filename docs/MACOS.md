# macOS Deployment Guide

This guide covers the macOS port in this fork.

It keeps the core behavior of the original project:

- browse Codex projects, sessions, and messages from a phone
- send follow-up prompts from the phone and let Codex continue on the Mac
- require desktop approval for first-time devices
- monitor local services, remote publish status, and trusted devices from the desktop control tool

Compared with the original Windows-oriented repository, this fork adds:

1. `sh`-based lifecycle scripts for macOS
2. a Caddy-based local reverse proxy flow
3. safer default WebSocket auth fallback behavior

## Project Origin

This fork is built on top of [StarsTom/mobileCodexHelper](https://github.com/StarsTom/mobileCodexHelper).

The upstream project established the core design, trust model, and UI patch layer.  
This fork mainly adapts that design for macOS operation and distribution.

## Prerequisites

Recommended:

- macOS
- Python 3.11+
- Git
- Codex desktop app or CLI already available
- Tailscale

Not required as global installs:

- Node.js 22
- Caddy

If Node.js 22 or Caddy are missing, the scripts in this fork can download local copies into `.runtime/tools/`.

## Step 1: Prepare the upstream panel

From the repository root, run:

```bash
./scripts/setup-upstream-mac.sh
```

This script:

1. clones `siteboon/claudecodeui` `v1.25.2`
2. applies this fork's override layer
3. ensures a Node.js 22 runtime is available
4. installs upstream dependencies
5. builds the frontend for local production use

## Step 2: Check the runtime

```bash
./scripts/check-mobile-codex-runtime.sh
```

Important fields:

- `UpstreamExists = True`
- `Node` has a value
- `Python` has a value
- `Tailscale` should have a value if you want remote private phone access

## Step 3: Start the stack

```bash
./scripts/start-mobile-codex-stack.sh
```

By default this starts:

- app service: `127.0.0.1:3001`
- Caddy reverse proxy: `127.0.0.1:8080`

## Step 4: Launch the desktop control tool

```bash
python3 mobile_codex_control.py
```

If you only want terminal status output:

```bash
python3 mobile_codex_control.py --json
```

## Step 5: Complete first-time registration

Open this in a desktop browser:

```text
http://127.0.0.1:8080
```

Create the first account.  
The first registered device is approved automatically.

## Step 6: Enable phone access

Make sure:

- your Mac is logged into Tailscale
- your phone is logged into the same tailnet

Then run:

```bash
./scripts/enable-mobile-codex-remote.sh
```

This publishes the local reverse proxy at `127.0.0.1:8080` through Tailscale Serve.

## Step 7: First-time phone approval

When a new phone logs in for the first time:

1. the phone waits for approval
2. `mobile_codex_control.py` shows a pending approval
3. you verify the device information
4. you approve it on the Mac
5. the phone continues the login flow

## Common Commands

Start:

```bash
./scripts/start-mobile-codex-stack.sh
```

Stop:

```bash
./scripts/stop-mobile-codex-stack.sh
```

Show current status:

```bash
python3 mobile_codex_control.py --json
```

## Log Files

- app stdout: `tmp/logs/mobile-codex-app.stdout.log`
- app stderr: `tmp/logs/mobile-codex-app.stderr.log`
- Caddy stdout: `tmp/logs/mobile-codex-caddy.stdout.log`
- Caddy stderr: `tmp/logs/mobile-codex-caddy.stderr.log`
- Caddy access log: `.runtime/caddy/logs/mobile-codex.access.json`

## Security Notes

This macOS fork disables WebSocket query-token fallback by default:

- the frontend no longer appends `?token=...` unless you explicitly re-enable it
- the backend no longer accepts query-token WebSocket auth unless you explicitly re-enable it

That reduces the chance of leaking a session token through proxy access logs.

If you absolutely need that compatibility mode, you can opt in:

```bash
export ALLOW_QUERY_TOKEN_WS_FALLBACK=true
export VITE_ENABLE_QUERY_TOKEN_WS_FALLBACK=true
```

Only do that if you understand the logging and proxy implications.
