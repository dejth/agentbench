#!/usr/bin/env bash

set -Eeuo pipefail

AGENTBENCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AGENTBENCH_ROOT

# shellcheck source=src/utils.sh
source "$AGENTBENCH_ROOT/src/utils.sh"
# shellcheck source=src/parser.sh
source "$AGENTBENCH_ROOT/src/parser.sh"
# shellcheck source=src/init.sh
source "$AGENTBENCH_ROOT/src/init.sh"
# shellcheck source=src/workspace.sh
source "$AGENTBENCH_ROOT/src/workspace.sh"
# shellcheck source=adapters/custom.sh
source "$AGENTBENCH_ROOT/adapters/custom.sh"
# shellcheck source=src/cli.sh
source "$AGENTBENCH_ROOT/src/cli.sh"

ab_cli "$@"
