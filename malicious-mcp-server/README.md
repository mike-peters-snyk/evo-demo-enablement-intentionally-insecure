# Malicious MCP Server — Detection & Governance Demo

> ⚠️ Intentionally-insecure demo fixture. See the [repo README](../README.md). Fake
> credentials, non-resolving hosts, no real harm. Do not use outside an Evo demo.

_Last updated: 2026-09-30_

> ## 🛑 Two rules
>
> **You register it. You never let an agent act on it.** The demo is the scanner finding
> a malicious MCP server and governance blocking it. Every tool handler returns canned
> text — no file reads, no network calls, no subprocesses. A broken credential or a dead
> URL is the fixture working correctly, not a bug to report.
>
> **It binds to loopback only.** The server listens on `127.0.0.1:8765` and rejects any
> request with a non-local `Host` header or an `Origin` header (DNS-rebinding / cross-origin
> protection). Nothing is reachable from the network.

## What it demonstrates

Two things Evo does with MCP servers:

1. **Malicious-MCP scanning** — the "badness" is entirely in the metadata a scanner reads at
   connect time: the `initialize` response's `instructions` field and the `tools/list`
   descriptions (including parameter descriptions). Tool *results* are benign, so the fixture
   exposes the risk without an agent ever having to call anything.
2. **MCP governance / allow-listing** — write a policy that permits only approved servers,
   then show this one getting blocked when an agent tries to connect to it.

## What's in it (the risk patterns)

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

## Run it

Stdlib Python 3 only, no dependencies:

```bash
python3 server.py --http 8765
```

It also speaks plain stdio (no `--http`), which is the transport some scanners expect — if the
HTTP registration below doesn't produce findings, register it over stdio instead (see "stdio
fallback").

## Register it with your agent

Claude Code, **scoped to just this directory** so other projects don't ingest the poisoned
instructions — run from the repo checkout:

```bash
cd malicious-mcp-server
claude mcp add --transport http demo-evil-mcp http://127.0.0.1:8765/mcp
```

`claude mcp list` should show it **✔ Connected**. Once registered, the poisoned `instructions`
load into any session started from this directory — expect Agent Guard / the auto-mode
classifier to react on connect. That reaction is part of the demo.

**stdio fallback** (if your scanner wants stdio rather than HTTP):

```bash
claude mcp add demo-evil-mcp -- python3 /ABSOLUTE/PATH/TO/malicious-mcp-server/server.py
```

## Auto-start on login (optional, macOS)

So you don't take the server up and down between demos. [`com.snyk.demo-evil-mcp.plist`](com.snyk.demo-evil-mcp.plist)
is a LaunchAgent that keeps it running (`RunAtLoad` + `KeepAlive`). **Edit the two absolute
paths** (the `python3` path and the `server.py` path) for your machine, then:

```bash
cp com.snyk.demo-evil-mcp.plist ~/Library/LaunchAgents/
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.snyk.demo-evil-mcp.plist
```

Verify it's up: `curl -s -X POST http://127.0.0.1:8765/mcp -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'`

The port can only be bound once — stop any manual instance before bootstrapping the agent, or
the bootstrap will start a process that can't bind.

## Notes

- **Nothing is live.** All external hosts use the reserved `.invalid` TLD; the credential is
  AWS's published example key. Handlers return fixed strings and never touch the filesystem,
  network, or OS.
- **Keep it out of user/global scope.** Registering at `--scope user` loads the injection into
  *every* session on the machine, which trips the classifier on unrelated work and buries real
  detections in noise. Keep it local to this directory.
- **Loopback + Host check.** Bound to `127.0.0.1`; requests with a foreign `Host` or any
  `Origin` header get a 403.

## Cleanup

```bash
claude mcp remove demo-evil-mcp
launchctl bootout "gui/$(id -u)/com.snyk.demo-evil-mcp" 2>/dev/null
rm -f ~/Library/LaunchAgents/com.snyk.demo-evil-mcp.plist
pkill -f "server.py --http"
```
