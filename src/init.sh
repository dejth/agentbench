#!/usr/bin/env bash

ab_init() {
  local project_root
  local state_dir
  local setup_id

  ab_require_command git
  project_root="$(ab_project_root)" || ab_die "init must run inside a Git repository"
  state_dir="$project_root/.agentbench"

  mkdir -p \
    "$state_dir/cases" \
    "$state_dir/results" \
    "$state_dir/reports" \
    "$state_dir/tmp"

  ab_copy_unless_exists \
    "$AGENTBENCH_ROOT/templates/BENCHMARK.md" \
    "$state_dir/BENCHMARK.md"

  for setup_id in baseline candidate; do
    mkdir -p "$state_dir/setups/$setup_id"
    ab_copy_unless_exists \
      "$AGENTBENCH_ROOT/templates/CONTEXT.md" \
      "$state_dir/setups/$setup_id/CONTEXT.md"
    ab_copy_unless_exists \
      "$AGENTBENCH_ROOT/templates/SETUP.md" \
      "$state_dir/setups/$setup_id/SETUP.md"
  done

  printf '\nAgentBench initialized in %s\n' "$state_dir"
  printf 'Next: edit BENCHMARK.md and setup CONTEXT.md files, then run validate.\n'
}
