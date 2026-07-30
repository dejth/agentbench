#!/usr/bin/env bash

ab_help() {
  cat <<'EOF'
AgentBench — Test your AI context like you test your code.

Usage:
  ./agentbench.sh help
  ./agentbench.sh version
  ./agentbench.sh init
  ./agentbench.sh validate [--benchmark PATH]
  ./agentbench.sh run --setup ID --agent-command COMMAND [--runs N] [--timeout SECONDS] [--revision REF]
  ./agentbench.sh compare BASELINE CANDIDATE
  ./agentbench.sh report COMPARISON_ID
  ./agentbench.sh clean

Commands:
  help       Show this help.
  version    Print the AgentBench version.
  init       Create non-destructive .agentbench scaffolding.
  validate   Validate benchmark and optional setup definitions.
  run        Execute one setup in isolated workspaces.
  compare    Compare stored results for two setups.
  report     Print the path to a stored comparison report.
  clean      Remove AgentBench-managed temporary workspaces.
EOF
}

ab_cli_validate() {
  local benchmark_path=".agentbench/BENCHMARK.md"

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --benchmark)
        [[ "$#" -ge 2 ]] || ab_die "--benchmark requires a path"
        benchmark_path="$2"
        shift 2
        ;;
      -h|--help)
        printf 'Usage: ./agentbench.sh validate [--benchmark PATH]\n'
        return 0
        ;;
      *) ab_die "unknown validate argument: $1" ;;
    esac
  done

  ab_validate_benchmark "$benchmark_path"
}

ab_not_implemented() {
  ab_die "$1 is not implemented in this workstream"
}

ab_cli() {
  local command_name="${1:-help}"
  if [[ "$#" -gt 0 ]]; then
    shift
  fi

  case "$command_name" in
    help|-h|--help) ab_help ;;
    version|-V|--version) printf 'AgentBench %s\n' "$AB_VERSION" ;;
    init) ab_init "$@" ;;
    validate) ab_cli_validate "$@" ;;
    clean) ab_clean_managed_workspaces ;;
    run|compare|report) ab_not_implemented "$command_name" ;;
    *)
      ab_error "unknown command: $command_name"
      ab_help >&2
      return 2
      ;;
  esac
}
