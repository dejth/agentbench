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
  report     Print a stored comparison report.
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

ab_cli_run() {
  local setup_id=""
  local agent_command=""
  local run_count=1
  local timeout_seconds=900
  local revision="HEAD"

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --setup)
        [[ "$#" -ge 2 ]] || ab_die "--setup requires an identifier"
        setup_id="$2"
        shift 2
        ;;
      --agent-command)
        [[ "$#" -ge 2 ]] || ab_die "--agent-command requires a command"
        agent_command="$2"
        shift 2
        ;;
      --runs)
        [[ "$#" -ge 2 ]] || ab_die "--runs requires a number"
        run_count="$2"
        shift 2
        ;;
      --timeout)
        [[ "$#" -ge 2 ]] || ab_die "--timeout requires seconds"
        timeout_seconds="$2"
        shift 2
        ;;
      --revision)
        [[ "$#" -ge 2 ]] || ab_die "--revision requires a Git reference"
        revision="$2"
        shift 2
        ;;
      -h|--help)
        printf 'Usage: ./agentbench.sh run --setup ID --agent-command COMMAND [--runs N] [--timeout SECONDS] [--revision REF]\n'
        return 0
        ;;
      *) ab_die "unknown run argument: $1" ;;
    esac
  done

  [[ -n "$setup_id" ]] || ab_die "run requires --setup"
  [[ -n "$agent_command" ]] || ab_die "run requires --agent-command"
  ab_run_setup "$setup_id" "$agent_command" "$run_count" "$timeout_seconds" "$revision"
}

ab_cli_compare() {
  [[ "$#" -eq 2 ]] || ab_die "Usage: ./agentbench.sh compare BASELINE CANDIDATE"
  ab_compare_setups "$1" "$2"
}

ab_cli_report() {
  [[ "$#" -eq 1 ]] || ab_die "Usage: ./agentbench.sh report COMPARISON_ID"
  ab_show_report "$1"
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
    run) ab_cli_run "$@" ;;
    compare) ab_cli_compare "$@" ;;
    report) ab_cli_report "$@" ;;
    clean) ab_clean_managed_workspaces ;;
    *)
      ab_error "unknown command: $command_name"
      ab_help >&2
      return 2
      ;;
  esac
}
