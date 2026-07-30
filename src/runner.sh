#!/usr/bin/env bash

ab_run_setup() {
  local setup_id="$1"
  local agent_command="$2"
  local run_count="$3"
  local timeout_seconds="$4"
  local revision="$5"
  local project_root
  local benchmark_file
  local setup_file
  local starting_commit
  local experiment_id
  local setup_results_dir
  local experiment_results_file
  local index_file
  local run_number=0
  local failed_runs=0
  local run_id
  local run_output_dir
  local prompt_file
  local agent_stdout_file
  local agent_stderr_file
  local agent_exit_code
  local agent_duration_seconds
  local agent_timed_out
  local result_path
  local result_status
  local relative_result_path

  ab_require_command git
  ab_require_command jq
  ab_validate_identifier "$setup_id" "setup" || return 1
  [[ "$run_count" =~ ^[1-9][0-9]*$ ]] || ab_die "--runs must be a positive integer"
  [[ "$timeout_seconds" =~ ^[1-9][0-9]*$ ]] || ab_die "--timeout must be a positive integer"
  [[ -n "$(ab_trim "$agent_command")" ]] || ab_die "--agent-command must not be empty"

  project_root="$(ab_project_root)" || ab_die "run must execute inside a Git repository"
  benchmark_file="$project_root/.agentbench/BENCHMARK.md"
  setup_file="$project_root/.agentbench/setups/$setup_id/CONTEXT.md"
  ab_validate_benchmark "$benchmark_file" >/dev/null
  ab_validate_setup "$setup_id" "$project_root"
  starting_commit="$(ab_resolve_revision "$project_root" "$revision")"
  experiment_id="$(ab_generate_id "$setup_id")"
  setup_results_dir="$project_root/.agentbench/results/$setup_id"
  experiment_results_file="$setup_results_dir/$experiment_id.runs.json"
  index_file="$setup_results_dir/runs.json"
  mkdir -p "$setup_results_dir"
  printf '[]\n' > "$experiment_results_file.next"

  printf 'AgentBench — Running setup %s (%s run(s))\n' "$setup_id" "$run_count"
  printf 'Starting commit: %s\n\n' "$starting_commit"

  while [[ "$run_number" -lt "$run_count" ]]; do
    run_number=$((run_number + 1))
    run_id="$(ab_generate_id "$setup_id-$run_number")"
    run_output_dir="$setup_results_dir/$run_id"
    mkdir -p "$run_output_dir"

    ab_workspace_create "$project_root" "$starting_commit" "$run_id"
    ab_workspace_install_cleanup_trap "$project_root"
    prompt_file="$AB_WORKSPACE_CONTROL/prompt.md"
    agent_stdout_file="$AB_WORKSPACE_CONTROL/agent.stdout"
    agent_stderr_file="$AB_WORKSPACE_CONTROL/agent.stderr"
    ab_build_agent_prompt "$benchmark_file" "$setup_file" "$prompt_file"
    ab_run_custom_agent \
      "$AB_WORKSPACE_PATH" \
      "$agent_command" \
      "$prompt_file" \
      "$timeout_seconds" \
      "$agent_stdout_file" \
      "$agent_stderr_file"
    agent_exit_code="$AB_AGENT_EXIT_CODE"
    agent_duration_seconds="$AB_AGENT_DURATION_SECONDS"
    agent_timed_out="$AB_AGENT_TIMED_OUT"

    result_path="$(ab_evaluate_run \
      "$project_root" \
      "$AB_WORKSPACE_PATH" \
      "$benchmark_file" \
      "$setup_file" \
      "$setup_id" \
      "$run_id" \
      "$starting_commit" \
      "$agent_command" \
      "$agent_exit_code" \
      "$agent_duration_seconds" \
      "$agent_timed_out" \
      "$agent_stdout_file" \
      "$agent_stderr_file" \
      "$timeout_seconds" \
      "$run_output_dir")"

    ab_workspace_cleanup "$project_root"
    ab_workspace_clear_cleanup_trap

    relative_result_path="${result_path#"$project_root/"}"
    jq --arg result_path "$relative_result_path" \
      '. + {result_path: $result_path}' "$result_path" > "$run_output_dir/index-item.json"
    jq --slurpfile item "$run_output_dir/index-item.json" \
      '. + $item' "$experiment_results_file.next" > "$experiment_results_file.append"
    mv "$experiment_results_file.append" "$experiment_results_file.next"
    rm -f "$run_output_dir/index-item.json"

    result_status="$(jq -r '.status' "$result_path")"
    [[ "$result_status" == "PASS" ]] || failed_runs=$((failed_runs + 1))
    printf 'Run %s/%s  %-4s  score %s  %ss  %s\n' \
      "$run_number" \
      "$run_count" \
      "$result_status" \
      "$(jq -r '.score' "$result_path")" \
      "$(jq -r '.agent.duration_seconds' "$result_path")" \
      "$run_id"
  done

  jq -n \
    --arg schema_version "1" \
    --arg experiment_id "$experiment_id" \
    --arg setup_id "$setup_id" \
    --arg benchmark_id "$(ab_metadata_value "$benchmark_file" "Benchmark-ID")" \
    --arg benchmark_hash "$(ab_hash_file "$benchmark_file")" \
    --arg starting_commit "$starting_commit" \
    --arg created_at "$(ab_now_iso8601)" \
    --argjson timeout_seconds "$timeout_seconds" \
    --argjson requested_runs "$run_count" \
    --rawfile benchmark_definition "$benchmark_file" \
    --rawfile setup_definition "$setup_file" \
    --slurpfile results "$experiment_results_file.next" \
    '{
      schema_version: $schema_version,
      experiment_id: $experiment_id,
      setup_id: $setup_id,
      benchmark_id: $benchmark_id,
      benchmark_content_hash: $benchmark_hash,
      starting_commit: $starting_commit,
      created_at: $created_at,
      timeout_seconds: $timeout_seconds,
      requested_runs: $requested_runs,
      benchmark_definition: $benchmark_definition,
      setup_definition: $setup_definition,
      results: $results[0]
    }' > "$experiment_results_file"
  rm -f "$experiment_results_file.next"
  cp "$experiment_results_file" "$index_file.next"
  mv "$index_file.next" "$index_file"

  printf '\nCompleted %s run(s): %s passed, %s failed.\n' \
    "$run_count" "$((run_count - failed_runs))" "$failed_runs"
  printf 'Run index: %s\n' "$index_file"

  [[ "$failed_runs" -eq 0 ]]
}
