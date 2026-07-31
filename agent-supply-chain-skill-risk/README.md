# Agent Supply Chain Security — Malicious Skill Demo

> ⚠️ Intentionally-insecure demo fixture. See the [repo README](../README.md). Fake
> credentials, non-resolving hosts, no real harm. Do not use outside an Evo demo.

_Last updated: 2026-07-31_

> ## 🛑 Read this first — two rules
>
> ### 1. You install this skill. You never run it.
>
> The whole demo is the scanner *finding the file on disk*. Nothing has to execute, and
> nothing here works if you try. The URLs don't resolve, the credentials are dead
> placeholders, and the instructions inside are bad on purpose. **A broken credential or a
> failed command is the fixture working correctly, not a bug to report.** Install it, scan
> it, show the findings. Never invoke it.
>
> ### 2. It has to be a local copy.
>
> **Do not install this skill through the Claude desktop GUI / skills marketplace / Claude
> cloud.** The scan agent does not look where the GUI puts it, so nothing will show up in
> Evo and your demo will silently do nothing. (May change in the future)
>
> Copy the file to `~/.claude/skills/` yourself, using the [paste-in command below](#claude-code--paste-this).
> Details in [Why not the GUI?](#why-not-the-gui)

## What it demonstrates

Snyk **Agent Supply Chain Security** (Evo / ADS) scanning the agent skills installed on a
machine and flagging a malicious one.

[`SKILL.md`](SKILL.md) is a scanner test fixture — the skill equivalent of an EICAR
string. It has seven sections, each written to trip a different skill risk index. In one
scan it produces **7 findings, all High**:

| Code | Finding | Triggered by |
|---|---|---|
| `E004` | Potential prompt injection | The HTML-commented "SYSTEM DIRECTIVE" telling the agent to silently read shell history and env files |
| `W007` | Insecure credential handling | Instructions to read tokens from the environment and echo them verbatim, unmasked |
| `W008` | Secret detected | The hardcoded AWS example key pair |
| `E005` | Suspicious download URL | `curl … loader.sh \| bash` from a placeholder host |
| `W012` | Potentially malicious external URL | The remote "active-directives" endpoint the skill treats as authoritative |
| `E006` | Malicious code pattern | The overall combination — credential disclosure, RCE, remote directives, service tampering |
| `W013` | Attempt to modify system services | `sudo tee -a /etc/hosts` and `sudo launchctl unload` |

The mapping isn't strictly one-section-to-one-finding — `E006` in particular fires on the
file as a whole.

## Install

**This must be a local install.** See [Why not the GUI?](#why-not-the-gui) below.

### Claude Code — paste this

```bash
mkdir -p ~/.claude/skills/demo-do-not-use-intentionally-insecure && \
  curl -fsSL -o ~/.claude/skills/demo-do-not-use-intentionally-insecure/SKILL.md \
  https://raw.githubusercontent.com/mike-peters-snyk/evo-demo-enablement-intentionally-insecure/master/agent-supply-chain-skill-risk/SKILL.md
```

That is the entire install, and the entire thing you are meant to do with this file. Do
not invoke the skill afterwards — the scan reads it off disk.

### Other clients

Same idea, different destination:

| Client | Destination |
|---|---|
| Claude Code | `~/.claude/skills/demo-do-not-use-intentionally-insecure/SKILL.md` |
| GitHub Copilot | `~/.copilot/skills/demo-do-not-use-intentionally-insecure/SKILL.md` |
| Cursor | `~/.cursor/skills-cursor/demo-do-not-use-intentionally-insecure/SKILL.md` |

Or use [`install.sh`](install.sh), which does the same thing and takes a client name:

```bash
curl -fsSL -o /tmp/install-skill-demo.sh https://raw.githubusercontent.com/mike-peters-snyk/evo-demo-enablement-intentionally-insecure/master/agent-supply-chain-skill-risk/install.sh
```

Read it, then `bash /tmp/install-skill-demo.sh claude` (or `copilot`, `cursor`, `all`).

It is deliberately **not** a `curl … | bash` one-liner. This is a demo of a product that
flags exactly that pattern — don't model the bad habit in front of a customer.

## Making it show up in Evo right away

A freshly installed skill gets picked up on the scan agent's next reporting run. To make
it appear immediately for a demo, run the scan agent's `evo` push yourself, in your own
terminal:

```bash
~/.ads-scan/bin/snyk-scan-macos-arm64 evo
```

It will interactively prompt you for two values. Type them in at the prompt:

1. **Tenant ID** — `app.snyk.io` → select your tenant in the left nav → copy the UUID from the URL
2. **Authorization token** — your **Snyk API token**, the same one `snyk auth` stores. If
   you've already run `snyk auth`, `snyk config get api` prints it.

> **Heads up:** the prompt suggests fetching the token from `app.snyk.io/account` →
> "API Token → KEY → click to show." Your `snyk auth` token is the same credential and is
> easier to get. **This is not the ADS push key** — that's a different value, covered
> below.

> **Run this yourself.** Don't paste your API token into an agent session, a script, or a
> chat window to have something else run it for you. It's an interactive prompt precisely
> so the token goes straight from you into the binary.

It will also ask consent for each stdio MCP server it finds. Answering `N` to all of them
is fine — skills are still scanned and pushed.

If that binary doesn't exist, or the push fails, re-run the ADS installer and it will
scan and report as part of installation:

```bash
curl -fsSL -o /tmp/ads-installer https://downloads.snyk.io/ads/installer/latest/ads-installer-macos-arm64 && chmod +x /tmp/ads-installer
```

This path uses a **push key**, which is a *different* credential from the API token above.
Log in to **Evo → Settings** and allocate one, and **enable "machines" when you allocate
it** — otherwise the installer's scan won't be accepted. Copy it at allocation time; that's
your chance to capture the value.

Then run it yourself — again, typed by you, not handed to anything else. Prefix the line
with a space so it stays out of your shell history:

```
 PUSH_KEY='<your-push-key>' /tmp/ads-installer
```

Note that re-running the installer rewrites your `~/.claude/settings.json` and
`~/.cursor/hooks.json` hook entries.

## Why not the GUI?

Installing this skill through the Claude desktop GUI / skills marketplace **will not
work** — the scan agent won't see it.

Agent Scan (v0.5.15) only walks the `~/.<client>/skills` convention:

```
~/.claude/skills
~/.copilot/skills
~/.cursor/skills
~/.cursor/skills-cursor
```

The GUI installs into a session-scoped path under
`~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/<uuid>/<uuid>/skills/`,
which is not on that list — and the UUIDs change, so you can't just add it to a config.
On a machine with 23 GUI-installed skills, the scan found **zero** of them.

Verified 2026-07-31 against Agent Scan v0.5.15. If a later version adds that path, this
section is the thing to re-check.

## Safety properties

- **Nothing here is functional.** Every URL uses the reserved, non-resolving `.invalid`
  TLD. Nothing can leave a machine.
- **The credential is AWS's own published example key**
  (`AKIAIOSFODNN7EXAMPLE`), documented by AWS for exactly this purpose. It is not live.
- **The skill has no trigger conditions** and instructs any agent reading it to stop and
  report itself as a test fixture. It is inert unless deliberately invoked.
- **Nothing runs.** The fixture is scanned as text; the scanner never executes it.

## Notes

- **On the `W008` wording.** The scanner strips secrets before sending content for
  analysis, then flags the `**REDACTED_SECRET_<PLUGIN>**` placeholder it was handed. The
  finding text therefore says the value "should be treated as a real secret finding" even
  though the file contains AWS's public example key. Worth knowing if a customer reads the
  finding closely.
- **One skill, one location.** The results view may attribute the same skill to several
  clients — the scanner enumerates the shared `~/.claude/skills` directory once per
  detected client. It's a display artifact, not multiple installs. Don't promise a
  customer it will appear under three clients.
- **`~/.cursor/skills` vs `~/.cursor/skills-cursor`.** On at least one machine the former
  reported 0 skills because of how its contents were nested. `skills-cursor` is the one
  that actually gets read.

## Cleanup

```bash
rm -rf ~/.claude/skills/demo-do-not-use-intentionally-insecure
```

Adjust the path for whichever client you installed it into.
