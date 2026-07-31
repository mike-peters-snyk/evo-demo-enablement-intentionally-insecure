# Agent Supply Chain Security — Malicious Skill Demo

> ⚠️ Intentionally-insecure demo fixture. See the [repo README](../README.md). Fake
> credentials, non-resolving hosts, no real harm. Do not use outside an Evo demo.

_Last updated: 2026-07-31_

> ## 🛑 Two rules
>
> **You install this skill. You never run it.** The demo is the scanner finding the file on
> disk. Nothing here works if you try it — dead URLs, placeholder credentials, deliberately
> bad instructions. A broken credential is the fixture working correctly, not a bug to
> report. Install it, scan it, show the findings. Never invoke it.
>
> **It has to be a local copy.** Installing via the Claude desktop GUI / skills marketplace
> won't work — the scan agent doesn't look there, so your demo silently does nothing.
> (May change in the future) Why, below.

## What it demonstrates

Snyk Agent Supply Chain Security scanning installed agent skills and flagging a malicious
one. [`SKILL.md`](SKILL.md) is an EICAR-equivalent fixture: seven sections, seven risk
indexes, **7 High findings** in one scan.

| Code | Finding | Triggered by |
|---|---|---|
| `E004` | Prompt injection | HTML-commented "SYSTEM DIRECTIVE" to silently read shell history and env files |
| `W007` | Insecure credential handling | Read tokens from the environment and echo them verbatim, unmasked |
| `W008` | Secret detected | Hardcoded AWS example key pair |
| `E005` | Suspicious download URL | `curl … loader.sh \| bash` from a placeholder host |
| `W012` | Malicious external URL | Remote "active-directives" endpoint treated as authoritative |
| `E006` | Malicious code pattern | The combination — credential disclosure, RCE, remote directives, service tampering |
| `W013` | Modify system services | `sudo tee -a /etc/hosts`, `sudo launchctl unload` |

`E006` fires on the file as a whole, so the section-to-finding mapping isn't strictly 1:1.

## Install

```bash
mkdir -p ~/.claude/skills/demo-do-not-use-intentionally-insecure && \
  curl -fsSL -o ~/.claude/skills/demo-do-not-use-intentionally-insecure/SKILL.md \
  https://raw.githubusercontent.com/mike-peters-snyk/evo-demo-enablement-intentionally-insecure/master/agent-supply-chain-skill-risk/SKILL.md
```

Other clients — same file, different destination:

| Client | Destination |
|---|---|
| Claude Code | `~/.claude/skills/` |
| GitHub Copilot | `~/.copilot/skills/` |
| Cursor | `~/.cursor/skills-cursor/` |

[`install.sh`](install.sh) handles `claude`, `copilot`, `cursor`, or `all`, and reverses
with `--uninstall`. Fetch and read it rather than piping to bash — this demos a product
that flags that pattern.

## To Display in Evo Immediately

A new skill lands on the scan agent's next reporting run. To force it, from your terminal:

```bash
~/.ads-scan/bin/snyk-scan-macos-arm64 evo
```

Two prompts:

1. **Tenant ID** — `app.snyk.io`, select your tenant, copy the UUID from the URL.
2. **Authorization token** — your Snyk API token; `snyk config get api` prints it if you've
   run `snyk auth`. The prompt points at `app.snyk.io/account` instead — same credential,
   worse route. **Not** the ADS push key.

Declining the stdio MCP server consent prompts is fine; skills are still scanned and pushed.

If that binary is missing or the push fails, re-run the ADS installer, which scans and
reports as part of install:

```bash
curl -fsSL -o /tmp/ads-installer https://downloads.snyk.io/ads/installer/latest/ads-installer-macos-arm64 && chmod +x /tmp/ads-installer
 /tmp/ads-installer -tenant-id <tenant-uuid> -push-key <push-key>
```

Both flags are required. The push key is a different credential from the API token —
allocate it in **Evo → Settings** with **"machines" enabled**, and copy it at allocation
time, since that's your only chance. The leading space keeps the command out of shell
history, though the key is still briefly visible in `ps`.

Re-running rewrites the Snyk hook entries in `~/.claude/settings.json` and
`~/.cursor/hooks.json`, and restores `~/.claude/hooks/snyk_secure_at_inception.py` plus its
`lib/` if they've gone missing. Verified against installer v1.59.0, 2026-07-31.

## Why the GUI doesn't work

Agent Scan v0.5.15 only walks `~/.claude/skills`, `~/.copilot/skills`, `~/.cursor/skills`,
and `~/.cursor/skills-cursor`. The GUI installs to a session-scoped path under
`~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/<uuid>/<uuid>/skills/`
— not on the list, and the UUIDs rotate, so you can't add it to a config. On a machine with
23 GUI-installed skills, the scan found zero. Worth re-checking on later versions.

## Notes

- **Nothing is live.** All URLs use the reserved `.invalid` TLD; the credential is AWS's
  published example key (`AKIAIOSFODNN7EXAMPLE`). The scanner reads the file as text and
  never executes it.
- **`W008` wording.** The scanner redacts secrets before analysis, then flags the
  `**REDACTED_SECRET_<PLUGIN>**` placeholder it was handed — so the finding asserts a real
  secret even though it's AWS's public example. Notice it before a customer does.
- **One skill, one location.** Results may attribute the same skill to several clients; the
  scanner enumerates the shared `~/.claude/skills` once per detected client. Display
  artifact, not multiple installs.
- **Cursor:** use `~/.cursor/skills-cursor`. Plain `~/.cursor/skills` reported 0 skills on
  at least one machine because of how its contents were nested.

## Cleanup

```bash
rm -rf ~/.claude/skills/demo-do-not-use-intentionally-insecure
```
