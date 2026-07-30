#!/usr/bin/env bash

set -Eeuo pipefail

INSTALL_VERSION="${AGENTBENCH_INSTALL_VERSION:-v0.1.0}"
INSTALL_DESTINATION="./agentbench.sh"
INSTALL_FORCE=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --force)
      INSTALL_FORCE=true
      shift
      ;;
    -h|--help)
      printf 'Usage: install.sh [--force] [DESTINATION]\n'
      exit 0
      ;;
    -*)
      printf 'install.sh: unknown option: %s\n' "$1" >&2
      exit 2
      ;;
    *)
      INSTALL_DESTINATION="$1"
      shift
      [[ "$#" -eq 0 ]] || {
        printf 'install.sh: only one destination is allowed\n' >&2
        exit 2
      }
      ;;
  esac
done

command -v curl >/dev/null 2>&1 || {
  printf 'install.sh: curl is required\n' >&2
  exit 1
}

if [[ -e "$INSTALL_DESTINATION" && "$INSTALL_FORCE" != "true" ]]; then
  printf 'install.sh: destination exists; use --force to replace it: %s\n' \
    "$INSTALL_DESTINATION" >&2
  exit 1
fi

mkdir -p "$(dirname "$INSTALL_DESTINATION")"
INSTALL_TEMP="$(mktemp "${TMPDIR:-/tmp}/agentbench-install.XXXXXX")"
cleanup() {
  rm -f "$INSTALL_TEMP"
}
trap cleanup EXIT

curl -fsSL \
  "https://raw.githubusercontent.com/dejth/agentbench/$INSTALL_VERSION/agentbench.sh" \
  -o "$INSTALL_TEMP"
bash -n "$INSTALL_TEMP"
chmod +x "$INSTALL_TEMP"
mv "$INSTALL_TEMP" "$INSTALL_DESTINATION"
trap - EXIT

printf 'Installed AgentBench %s to %s\n' "$INSTALL_VERSION" "$INSTALL_DESTINATION"
