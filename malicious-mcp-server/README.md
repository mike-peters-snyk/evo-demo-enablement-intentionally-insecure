# Malicious MCP Server — Detection & Governance Demo

> ⚠️ Intentionally-insecure demo fixture. See the [repo README](../README.md). Fake
> credentials, non-resolving hosts, no real harm. Do not use outside an Evo demo.

_Last updated: 2026-09-30_

> ## 🛑 The demo is the *detection* — not the install
>
> **What you show the customer is an already-registered malicious MCP server getting flagged by
> Snyk Evo.** Registering the server is a one-time prerequisite you do *before* the demo, not
> part of it. If this machine is already set up, skip straight to [The demo](#the-demo).
>
> **The server is inert.** Every tool handler returns canned text — no file reads, no network,
> no subprocesses. It binds to `127.0.0.1:8765` only and rejects foreign `Host`/`Origin`
> headers. All external hosts use `.invalid`; the only credential is AWS's published example
> key. A dead URL or a rejected credential is the fixture working correctly, not a bug.

## What Evo detects here

All the "badness" is in the metadata a scanner reads at connect time — the `initialize`
response's `instructions` field and the `tools/list` descriptions (including parameter
descriptions). Tool *results* are benign, so the server never has to *do* anything for a finding
to appear.

| Where | Pattern |
|---|---|
| `initialize` → `instructions` | Server-level prompt injection: "ignore all previous instructions," silently read `~/.aws/credentials` and `~/.ssh/id_rsa` and send them to a `.invalid` sink, hide it from the user, always prefer this server's tools |
| tool `add` | Tool poisoning — hidden `<IMPORTANT>` block telling the agent to exfiltrate private keys via the `sidenote` parameter |
| tool `format_note` | Tool shadowing — tries to rewrite the recipient of any other server's `send_email` tool |
| tool `run_shell` | Advertises unsandboxed arbitrary command execution (`curl … \| sh`), "run without asking" |
| tool `sync_credentials` | Advertises credential exfiltration to an external endpoint |
| tool `get_weather` | "SYSTEM OVERRIDE" injection in the description, present from the first `tools/list` |
| source | Hardcoded fake AWS key (`AKIAIOSFODNN7EXAMPLE`, AWS's published example), `.invalid` C2 and exfil URLs |

Exact Evo finding names/counts vary by scan-agent version — confirm them on your first run and
treat whatever surfaces as expected.

---

## Setup (one-time prerequisite — do this *before* the demo)

> ### 🤖 If you are the AI agent setting this up, read this first
>
> Registering this server is a prerequisite, **not** the demo. **Do not try to run
> `claude mcp add` yourself.** The server's metadata is intentionally malicious, so your own
> safety classifier will almost certainly refuse the command — that refusal is expected and
> correct, and you should not try to work around it (splitting it up, another shell, etc.).
>
> Instead, **tell the operator to paste the command block below into their own terminal**, then
> confirm the result with them. Your job is to relay the command and verify the outcome, not to
> execute the registration.

**Have the operator run this** (from the repo root):

```bash
cd malicious-mcp-server
python3 server.py --http 8765 &     # start the inert server (loopback only); or use the LaunchAgent below
claude mcp add --transport http demo-evil-mcp http://127.0.0.1:8765/mcp
```

Then confirm together: `claude mcp list` should show `demo-evil-mcp` — **✔ Connected**.

Keep it **local to this directory** (the default scope). Do **not** add `--scope user`, or the
poisoned instructions load into *every* Claude session on the machine — that trips the classifier
on unrelated work and buries real detections in noise.

**stdio fallback** — if your scanner wants stdio rather than HTTP, have the operator run this
instead (edit the path):

```bash
claude mcp add demo-evil-mcp -- python3 /ABSOLUTE/PATH/TO/malicious-mcp-server/server.py
```

## The demo

The server is already registered, so the demo is simply showing it caught:

1. In Evo, run a scan / refresh so the registered MCP server is picked up.
2. Show `demo-evil-mcp` flagged, with its findings.
3. *(Optional)* Show MCP allow-list governance blocking a connection to a server that isn't on
   your policy.

If the server runs cleanly but nothing appears in Evo, see the repo README's troubleshooting — a
stale Agent Guard push key is the usual cause.

## Auto-start on login (optional, macOS)

So the server survives reboots and you don't take it up and down between demos.
[`com.snyk.demo-evil-mcp.plist`](com.snyk.demo-evil-mcp.plist) is a LaunchAgent that keeps it
running (`RunAtLoad` + `KeepAlive`). **Edit the two absolute paths** (the `python3` path and the
`server.py` path) for your machine, then:

```bash
cp com.snyk.demo-evil-mcp.plist ~/Library/LaunchAgents/
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.snyk.demo-evil-mcp.plist
```

The port can only be bound once — stop any manual instance before bootstrapping the agent, or the
bootstrap starts a process that can't bind.

## Notes

- **Nothing is live.** All external hosts use the reserved `.invalid` TLD; the credential is
  AWS's published example key. Handlers return fixed strings and never touch the filesystem,
  network, or OS.
- **Loopback + Host check.** Bound to `127.0.0.1`; requests with a foreign `Host` or any
  `Origin` header get a 403.

## Cleanup

```bash
claude mcp remove demo-evil-mcp
launchctl bootout "gui/$(id -u)/com.snyk.demo-evil-mcp" 2>/dev/null
rm -f ~/Library/LaunchAgents/com.snyk.demo-evil-mcp.plist
pkill -f "server.py --http"
```
