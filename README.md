# ⚠️ Evo Demo Enablement — INTENTIONALLY INSECURE ⚠️

> **This repository is a collection of deliberately unsafe test fixtures. It is the
> software equivalent of an [EICAR test string](https://en.wikipedia.org/wiki/EICAR_test_file).
> Nothing here is meant to run against real systems, and nothing here does real harm.**

_Last updated: 2026-08-11_

## What this is

Demo material used by **Snyk Solutions Engineers** to demonstrate **Snyk Evo**.

Each demo lives in its own directory and is designed to make a security control **fire
on purpose** so an SE can show it working live.

## What this is NOT

- ❌ **Not malware.** It performs no real attack.
- ❌ **Not real credentials.** Every secret here is a fake, clearly-labeled placeholder.
- ❌ **Not a working exfiltration tool.** External hosts use the reserved, non-resolving
  `.invalid` TLD — nothing can actually leave a machine.
- ❌ **Not for production, real systems, or any non-demo use.**

## Why it's "insecure" on purpose

To demo a security product catching bad behavior, you need bad behavior to catch. These
fixtures intentionally include things like fake secrets in files and prompts that direct
an AI agent to read sensitive files or attempt to send a (fake) secret to a (dead) host.
The "badness" is the point — do not "fix" it.

## Who it's for

Snyk Solutions Engineers running Evo demos. If you found this repo and you're not doing
that, there's nothing useful here for you.

## Ground rules for anyone using these demos

1. Run only in a throwaway/local environment you control.
2. Never substitute a real credential for the fake placeholders.
3. Never repoint a demo at a real/resolvable host.
4. Treat every finding a demo produces as expected and intentional.

## Demos

| Directory | Demonstrates |
|---|---|
| [`agentguard-sensitive-data/`](agentguard-sensitive-data/) | Evo / AgentGuard detecting sensitive-data access and an attempted secret→public-sink exfil |
| [`agent-supply-chain-skill-risk/`](agent-supply-chain-skill-risk/) | Evo / Agent Supply Chain Security scanning installed agent skills and flagging a malicious one (7 High findings) |

_More demos are added as separate directories over time._

## Troubleshooting — demo runs but nothing shows up?

If a demo runs cleanly (hooks fire, no errors) but **no findings appear in your Evo dashboard**, your Agent Guard push key has most likely gone stale — an org-wide install issue in early Aug 2026 invalidated many keys. Re-run your Agent Guard install to refresh the key, restart your agent (Claude Code loads hooks at startup), then re-run the demo and confirm a real event lands. A "200 OK" from the hook is *not* proof events are visible — only seeing one in the dashboard is.
