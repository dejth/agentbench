#!/usr/bin/env bash

ab_path_is_allowed() {
  local changed_path="$1"
  local allowed_file="$2"
  local pattern

  while IFS= read -r pattern; do
    pattern="$(ab_unquote_markdown_code "$pattern")"
    pattern="${pattern#./}"
    if [[ "$changed_path" == $pattern ]]; then
      return 0
    fi
  done < "$allowed_file"
  return 1
}

ab_collect_changed_files() {
  local workspace_path="$1"
  local starting_commit="$2"
  local output_file="$3"
  local tracked_file="$output_file.tracked"
  local untracked_file="$output_file.untracked"

  git -C "$workspace_path" diff --name-only "$starting_commit" > "$tracked_file"
  git -C "$workspace_path" ls-files --others --exclude-standard > "$untracked_file"
  { cat "$tracked_file"; cat "$untracked_file"; } |
    awk 'NF && !seen[$0]++' |
    LC_ALL=C sort > "$output_file"
  rm -f "$tracked_file" "$untracked_file"
}

ab_run_validations() {
  local workspace_path="$1"
  local benchmark_file="$2"
  local evidence_dir="$3"
  local result_file="$4"
  local timeout_seconds="$5"
  local command_text
  local command_index=0
  local command_status
  local command_duration
  local stdout_raw
  local stderr_raw
  local stdout_redacted
  local stderr_redacted
  local item_file
  local command_display

  printf '[]\n' > "$result_file"
  while IFS= read -r command_text; do
    command_text="$(ab_trim "$command_text")"
    [[ -n "$command_text" ]] || continue
    [[ "$command_text" == \#* ]] && continue
    command_index=$((command_index + 1))
    stdout_raw="$evidence_dir/validation-$command_index.stdout.raw"
    stderr_raw="$evidence_dir/validation-$command_index.stderr.raw"
    stdout_redacted="$evidence_dir/validation-$command_index.stdout"
    stderr_redacted="$evidence_dir/validation-$command_index.stderr"
    item_file="$evidence_dir/validation-$command_index.json"
    ab_run_custom_agent \
      "$workspace_path" \
      "$command_text" \
      /dev/null \
      "$timeout_seconds" \
      "$stdout_raw" \
      "$stderr_raw"
    command_status="$AB_AGENT_EXIT_CODE"
    command_duration="$AB_AGENT_DURATION_SECONDS"
    command_display="$(ab_redact_text "$command_text")"
    ab_redact_file "$stdout_raw" "$stdout_redacted"
    ab_redact_file "$stderr_raw" "$stderr_redacted"
    rm -f "$stdout_raw" "$stderr_raw"

    jq -n \
      --arg command "$command_display" \
      --argjson exit_code "$command_status" \
      --argjson duration_seconds "$command_duration" \
      --argjson timed_out "$AB_AGENT_TIMED_OUT" \
      --rawfile stdout "$stdout_redacted" \
      --rawfile stderr "$stderr_redacted" \
      '{
        command: $command,
        exit_code: $exit_code,
        passed: ($exit_code == 0),
        timed_out: $timed_out,
        duration_seconds: $duration_seconds,
        stdout: $stdout,
        stderr: $stderr
      }' > "$item_file"
    jq --slurpfile item "$item_file" '. + $item' "$result_file" \
      > "$result_file.next"
    mv "$result_file.next" "$result_file"
  done < <(ab_validation_commands "$benchmark_file")
}

ab_check_required_files() {
  local workspace_path="$1"
  local requirements_file="$2"
  local result_file="$3"
  local required_path
  local exists

  printf '[]\n' > "$result_file"
  while IFS= read -r required_path; do
    required_path="$(ab_unquote_markdown_code "$required_path")"
    [[ -n "$required_path" ]] || continue
    if [[ "$required_path" == "None" || "$required_path" == "None." ]]; then
      continue
    fi
    exists=false
    [[ -e "$workspace_path/$required_path" ]] && exists=true
    jq \
      --arg path "$required_path" \
      --argjson exists "$exists" \
      '. + [{path: $path, exists: $exists}]' \
      "$result_file" > "$result_file.next"
    mv "$result_file.next" "$result_file"
  done < "$requirements_file"
}

ab_check_scope() {
  local changed_file_list="$1"
  local allowed_file="$2"
  local violations_file="$3"
  local changed_path

  : > "$violations_file"
  while IFS= read -r changed_path; do
    [[ -n "$changed_path" ]] || continue
    if ! ab_path_is_allowed "$changed_path" "$allowed_file"; then
      printf '%s\n' "$changed_path" >> "$violations_file"
    fi
  done < "$changed_file_list"
}

ab_dependency_lock_hash() {
  local project_root="$1"
  local lock_name

  for lock_name in pnpm-lock.yaml package-lock.json yarn.lock poetry.lock Cargo.lock; do
    if [[ -f "$project_root/$lock_name" ]]; then
      ab_hash_file "$project_root/$lock_name"
      return 0
    fi
  done
  printf '\n'
}

ab_evaluate_run() {
  local project_root="$1"
  local workspace_path="$2"
  local benchmark_file="$3"
  local setup_file="$4"
  local setup_id="$5"
  local run_id="$6"
  local starting_commit="$7"
  local agent_command="$8"
  local agent_exit_code="$9"
  shift 9
  local agent_duration_seconds="$1"
  local agent_timed_out="$2"
  local agent_stdout_file="$3"
  local agent_stderr_file="$4"
  local timeout_seconds="$5"
  local output_dir="$6"
  local evidence_dir="$output_dir/evidence"
  local validations_json="$evidence_dir/validations.json"
  local allowed_file="$evidence_dir/allowed-scope.txt"
  local requirements_file="$evidence_dir/required-files.txt"
  local required_json="$evidence_dir/required-files.json"
  local changed_file_list="$evidence_dir/changed-files.txt"
  local violations_file="$evidence_dir/scope-violations.txt"
  local critical_file="$evidence_dir/critical-failures.txt"
  local git_diff_file="$evidence_dir/git.diff"
  local git_diff_stat_file="$evidence_dir/git-diff.stat"
  local agent_stdout_redacted="$evidence_dir/agent.stdout"
  local agent_stderr_redacted="$evidence_dir/agent.stderr"
  local result_file="$output_dir/result.json"
  local validation_total
  local validation_passed
  local required_missing
  local scope_violation_count
  local agent_ok=false
  local required_files_ok=false
  local scope_ok=false
  local critical_failure_count
  local setup_hash
  local lock_hash
  local benchmark_id
  local agent_command_display

  ab_require_command jq
  mkdir -p "$evidence_dir"
  ab_section_list "$benchmark_file" "Allowed Scope" > "$allowed_file"
  ab_section_list "$benchmark_file" "Required Files" > "$requirements_file"
  ab_run_validations \
    "$workspace_path" \
    "$benchmark_file" \
    "$evidence_dir" \
    "$validations_json" \
    "$timeout_seconds"
  ab_collect_changed_files "$workspace_path" "$starting_commit" "$changed_file_list"
  git -C "$workspace_path" diff --no-ext-diff --binary "$starting_commit" > "$git_diff_file"
  git -C "$workspace_path" diff --no-ext-diff --stat "$starting_commit" > "$git_diff_stat_file"
  ab_check_required_files "$workspace_path" "$requirements_file" "$required_json"
  ab_check_scope "$changed_file_list" "$allowed_file" "$violations_file"
  ab_redact_file "$agent_stdout_file" "$agent_stdout_redacted"
  ab_redact_file "$agent_stderr_file" "$agent_stderr_redacted"

  validation_total="$(jq 'length' "$validations_json")"
  validation_passed="$(jq '[.[] | select(.passed)] | length' "$validations_json")"
  required_missing="$(jq '[.[] | select(.exists == false)] | length' "$required_json")"
  scope_violation_count="$(awk 'NF { count++ } END { print count + 0 }' "$violations_file")"
  [[ "$required_missing" -eq 0 ]] && required_files_ok=true
  [[ "$scope_violation_count" -eq 0 ]] && scope_ok=true
  if [[ "$agent_exit_code" -eq 0 && "$agent_timed_out" == "false" ]]; then
    agent_ok=true
  fi

  : > "$critical_file"
  if [[ "$agent_timed_out" == "true" ]]; then
    printf 'Agent command timed out.\n' >> "$critical_file"
  elif [[ "$agent_exit_code" -ne 0 ]]; then
    printf 'Agent command failed with exit code %s.\n' "$agent_exit_code" >> "$critical_file"
  fi
  [[ "$validation_passed" -ne "$validation_total" ]] && printf 'One or more required validation commands failed.\n' >> "$critical_file"
  [[ "$required_missing" -ne 0 ]] && printf 'One or more required files are missing.\n' >> "$critical_file"
  [[ "$scope_violation_count" -ne 0 ]] && printf 'One or more files violate Allowed Scope.\n' >> "$critical_file"
  critical_failure_count="$(awk 'NF { count++ } END { print count + 0 }' "$critical_file")"

  ab_calculate_score \
    "$benchmark_file" \
    "$validation_total" \
    "$validation_passed" \
    "$required_files_ok" \
    "$scope_ok" \
    "$agent_ok" \
    "$critical_failure_count"

  setup_hash="$(ab_hash_file "$setup_file")"
  lock_hash="$(ab_dependency_lock_hash "$project_root")"
  benchmark_id="$(ab_metadata_value "$benchmark_file" "Benchmark-ID")"
  [[ -n "$benchmark_id" ]] || benchmark_id="unavailable"
  agent_command_display="$(ab_redact_text "$agent_command")"

  jq -n \
    --arg schema_version "$AB_RESULT_FORMAT_VERSION" \
    --arg agentbench_version "$AB_VERSION" \
    --arg benchmark_format_version "$AB_BENCHMARK_FORMAT_VERSION" \
    --arg benchmark_id "$benchmark_id" \
    --arg setup_id "$setup_id" \
    --arg setup_hash "$setup_hash" \
    --arg run_id "$run_id" \
    --arg starting_commit "$starting_commit" \
    --arg agent_command "$agent_command_display" \
    --arg timestamp "$(ab_now_iso8601)" \
    --arg os "$(uname -srm)" \
    --arg shell_version "$BASH_VERSION" \
    --arg git_version "$(git --version)" \
    --arg jq_version "$(jq --version)" \
    --arg lock_hash "$lock_hash" \
    --arg status "$AB_SCORE_STATUS" \
    --argjson timeout_seconds "$timeout_seconds" \
    --argjson agent_exit_code "$agent_exit_code" \
    --argjson agent_duration_seconds "$agent_duration_seconds" \
    --argjson agent_timed_out "$agent_timed_out" \
    --argjson score "$AB_SCORE_TOTAL" \
    --argjson threshold "$AB_SCORE_THRESHOLD" \
    --argjson correctness "$AB_SCORE_CORRECTNESS" \
    --argjson regression "$AB_SCORE_REGRESSION_SAFETY" \
    --argjson instruction "$AB_SCORE_INSTRUCTION_COMPLIANCE" \
    --argjson efficiency "$AB_SCORE_EFFICIENCY" \
    --slurpfile validations "$validations_json" \
    --slurpfile required_files "$required_json" \
    --argjson changed_files "$(ab_json_array_from_lines "$changed_file_list")" \
    --argjson scope_violations "$(ab_json_array_from_lines "$violations_file")" \
    --argjson critical_failures "$(ab_json_array_from_lines "$critical_file")" \
    --rawfile agent_stdout "$agent_stdout_redacted" \
    --rawfile agent_stderr "$agent_stderr_redacted" \
    --rawfile git_diff_stat "$git_diff_stat_file" \
    '{
      schema_version: $schema_version,
      run_id: $run_id,
      status: $status,
      score: $score,
      pass_threshold: $threshold,
      benchmark: {id: $benchmark_id, format_version: $benchmark_format_version},
      setup: {id: $setup_id, content_hash: $setup_hash},
      source: {
        starting_commit: $starting_commit,
        dependency_lock_hash: (if ($lock_hash | length) > 0 then $lock_hash else null end),
        workspace_identifier: $run_id
      },
      agent: {
        command: $agent_command,
        version: null,
        model: null,
        provider: null,
        exit_code: $agent_exit_code,
        timed_out: $agent_timed_out,
        duration_seconds: $agent_duration_seconds,
        stdout: $agent_stdout,
        stderr: $agent_stderr,
        attempt_count: null,
        tool_call_count: null,
        token_usage: null,
        cost: null
      },
      environment: {
        agentbench_version: $agentbench_version,
        operating_system: $os,
        shell_version: $shell_version,
        git_version: $git_version,
        jq_version: $jq_version,
        timestamp: $timestamp,
        timeout_seconds: $timeout_seconds
      },
      score_breakdown: {
        correctness: $correctness,
        regression_safety: $regression,
        instruction_compliance: $instruction,
        efficiency: $efficiency
      },
      validations: $validations[0],
      required_files: $required_files[0],
      changed_files: $changed_files,
      git_diff: {stat: $git_diff_stat, patch_path: "evidence/git.diff"},
      scope_violations: $scope_violations,
      critical_failures: $critical_failures,
      human_intervention_count: null
    }' > "$result_file.next"
  mv "$result_file.next" "$result_file"
  printf '%s\n' "$result_file"
}
