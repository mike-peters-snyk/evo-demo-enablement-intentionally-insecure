#!/usr/bin/env bash
#
# Installs the Agent Supply Chain Security demo skill fixture into a local agent client.
#
# This is an INTENTIONALLY INSECURE scanner test fixture, the skill equivalent of an
# EICAR string. It is inert unless deliberately invoked. See README.md.
#
# Usage:
#   bash install.sh [claude|copilot|cursor|all]     # default: claude
#   bash install.sh --uninstall [claude|copilot|cursor|all]
#
# It must be a LOCAL copy. Installing this skill via the Claude desktop GUI / skills
# marketplace does not work — the scan agent does not walk that path.

set -euo pipefail

SKILL_NAME="demo-do-not-use-intentionally-insecure"
RAW_URL="https://raw.githubusercontent.com/mike-peters-snyk/evo-demo-enablement-intentionally-insecure/master/agent-supply-chain-skill-risk/SKILL.md"

target_dir_for() {
  case "$1" in
    claude)  printf '%s' "$HOME/.claude/skills" ;;
    copilot) printf '%s' "$HOME/.copilot/skills" ;;
    cursor)  printf '%s' "$HOME/.cursor/skills-cursor" ;;
    *) echo "Unknown client: $1 (expected claude, copilot, cursor, or all)" >&2; exit 1 ;;
  esac
}

install_one() {
  local client="$1" base dest
  base="$(target_dir_for "$client")"
  dest="${base}/${SKILL_NAME}"

  mkdir -p "$dest"

  # Prefer the copy sitting next to this script; fall back to fetching from the repo.
  local local_copy="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/SKILL.md"
  if [[ -f "$local_copy" ]]; then
    cp "$local_copy" "${dest}/SKILL.md"
    echo "installed ${client}: ${dest}/SKILL.md (from local copy)"
  else
    curl -fsSL -o "${dest}/SKILL.md" "$RAW_URL"
    echo "installed ${client}: ${dest}/SKILL.md (fetched from repo)"
  fi
}

uninstall_one() {
  local client="$1" dest
  dest="$(target_dir_for "$client")/${SKILL_NAME}"
  if [[ -d "$dest" ]]; then
    rm -rf "$dest"
    echo "removed ${client}: ${dest}"
  else
    echo "not present for ${client}: ${dest}"
  fi
}

main() {
  local action="install" clients=()

  if [[ "${1:-}" == "--uninstall" ]]; then
    action="uninstall"
    shift
  fi

  case "${1:-claude}" in
    all) clients=(claude copilot cursor) ;;
    *)   clients=("${1:-claude}") ;;
  esac

  for c in "${clients[@]}"; do
    if [[ "$action" == "install" ]]; then
      install_one "$c"
    else
      uninstall_one "$c"
    fi
  done

  if [[ "$action" == "install" ]]; then
    cat <<'NOTE'

Done. Installed only — do not invoke this skill. It is a scanner fixture and
has no working function.

To make it show up in Evo immediately rather than waiting for the scan agent's
next reporting run, run:

    ~/.ads-scan/bin/snyk-scan-macos-arm64 evo

Run that yourself in your own terminal. It prompts for a Tenant ID and an
"Authorization token" -- the latter is your Snyk API token, the same one
"snyk auth" stores ("snyk config get api" prints it). That is NOT the ADS push
key, which is a separate credential allocated in Evo -> Settings. Type both in
at the prompt rather than handing your token to a script or an agent. Declining
the MCP server consent prompts is fine; skills are still scanned and pushed.
NOTE
  fi
}

main "$@"
