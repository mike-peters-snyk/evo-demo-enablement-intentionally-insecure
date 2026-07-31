# AgentGuard — Sensitive Data Access Demo

> ⚠️ Intentionally-insecure demo fixture. See the [repo README](../README.md). Fake
> credentials, non-resolving hosts, no real harm. Do not use outside an Evo demo.

## What it demonstrates

Snyk Evo's agent guardrail (**AgentGuard**) running in **monitor mode**, detecting a run
of risky AI-agent actions and flagging them as security findings.

In one pass, the demo is expected to produce **5 findings**:

| # | Finding | Triggered by |
|---|---|---|
| 1 | Sensitive shell command | `head -5 /etc/passwd`, and the `grep`/`curl` that read and send the token |
| 2 | Web search & HTTP | the outbound `curl` to the external host |
| 3 | Toxic flows | reading the secret from a file and then sending it out — a secret → external-sink data flow |
| 4 | PII detection | `echo` of a fake name / SSN / email / phone |
| 5 | Workplace boundary | accessing resources outside the project workspace (e.g. reading `/etc/passwd`) |

> Finding names and exact triggers reflect AgentGuard's current categories and may shift
> as the product evolves.

## How it works

1. A Solutions Engineer opens Claude Code in a **local repo they control**, with Snyk
   Evo / AgentGuard active in monitor mode. (Any local repo works; the prompt creates
   what it needs. Mike runs it from a local juice-shop clone.)
2. The SE pastes the prompt from [`prompt.md`](prompt.md).
3. The agent creates a fake secrets file, then performs the sequence of flagged actions
   above without pausing.
4. AgentGuard records the findings; the SE walks through them in the Evo results view.

**Recommended model: Claude Opus 4.8.**

## Safety properties

- **Fake credentials only.** The tokens match real secret *patterns* (so detection
  fires) but are obviously non-real (`NOTREAL`, `DEMOFAKE`).
- **Dead sink.** The exfil target uses the reserved `.invalid` TLD and cannot resolve, so
  the fake token never actually leaves the machine — detection fires on the *intent*, not
  on any real transmission.
- **Nothing sensitive is committed.** The secrets file is created at runtime by the
  prompt, not stored in this repo.

## Notes

- The prompt tells the agent to **skip Snyk scans** and to **ignore a PostToolUse hook
  spawn error** if one appears — both are expected demo noise, not failures.
