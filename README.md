# mobile_codex_helper_for_mac

[English](README.md) | [中文](README.zh-CN.md)

Turn the Codex sessions running on your Mac into a private, phone-friendly web control panel.

## Project Origin

This repository is based on the original [StarsTom/mobileCodexHelper](https://github.com/StarsTom/mobileCodexHelper) project.

The upstream project built a strong foundation:

- a phone-friendly web UI for local Codex sessions
- first-time device approval from the desktop
- a private-network-first deployment model
- a hardened single-user control surface instead of full public exposure

That upstream work primarily targeted Windows.

This fork keeps the same overall architecture and trust model, then adapts it for macOS.

## What This Fork Adds

On top of the original project, this fork adds:

- macOS setup, start, stop, status, and remote-publish shell scripts
- local runtime bootstrap for Node.js 22 and Caddy, so the Mac setup does not depend on global installs for those tools
- a Caddy-based reverse proxy flow for macOS instead of the original Windows nginx packaging path
- cross-platform updates to the desktop control tool so it can monitor and operate the stack on macOS
- a safer default for WebSocket auth fallback by disabling query-string token transport unless explicitly re-enabled
- a workspace-local database/runtime strategy for constrained environments
- an option to disable project watchers in environments where filesystem watcher limits are too restrictive

## What It Does

- view Codex projects, sessions, and messages from a phone browser
- send follow-up prompts from the phone and let Codex continue on the Mac
- require desktop approval before a new device can log in
- keep the system focused on phone viewing plus chat control rather than broad remote administration

## Recommended Architecture

```text
Phone browser
   ↓
Tailscale private HTTPS
   ↓
Local reverse proxy (Caddy on macOS)
   ↓
Local claudecodeui with this fork's patches
   ↓
Codex sessions on your Mac
```

## Interface Preview

The screenshot below comes from the original desktop control concept.  
This fork keeps that same operational model, with a macOS-compatible implementation.

![Mobile Codex control console preview](docs/assets/mobile-codex-control-console.png)

## Quick Start on macOS

1. Clone this repository.
2. Run `./scripts/setup-upstream-mac.sh`
3. Run `./scripts/check-mobile-codex-runtime.sh`
4. Run `./scripts/start-mobile-codex-stack.sh`
5. Open `http://127.0.0.1:8080`
6. Complete first-time registration in the browser
7. Optionally run `python3 mobile_codex_control.py` for the desktop control console
8. If you use Tailscale, run `./scripts/enable-mobile-codex-remote.sh` after both your Mac and phone join the same tailnet

## Documentation

- macOS deployment guide: [docs/MACOS.md](docs/MACOS.md)
- Chinese macOS guide: [docs/MACOS.zh-CN.md](docs/MACOS.zh-CN.md)
- Original Windows-oriented deployment docs kept from upstream: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
- Upstream project: [StarsTom/mobileCodexHelper](https://github.com/StarsTom/mobileCodexHelper)

## Security Notes

This project still controls high-trust local Codex sessions, so the safe operating model remains the same as upstream:

- keep the app bound locally
- prefer private networking such as Tailscale
- require desktop approval for first-time devices
- avoid direct public internet exposure

## Current Fork Scope

This fork is focused on making the upstream idea practical on macOS.  
It does not try to turn the project into a multi-user hosted platform or a general remote execution service.
