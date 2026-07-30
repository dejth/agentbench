#!/usr/bin/env bash

# Markdown code spans require literal backticks in single-quoted printf formats.
# shellcheck disable=SC2016

ab_metric_display() {
  local comparison_file="$1"
  local side="$2"
  local metric="$3"

  jq -r --arg side "$side" --arg metric "$metric" \
    '.[$side][$metric] | if . == null then "unavailable" else tostring end' \
    "$comparison_file"
}

ab_print_comparison_terminal() {
  local comparison_file="$1"
  local baseline_name
  local candidate_name
  local baseline_pass_rate
  local candidate_pass_rate

  baseline_name="$(jq -r '.baseline.setup_id' "$comparison_file")"
  candidate_name="$(jq -r '.candidate.setup_id' "$comparison_file")"
  baseline_pass_rate="$(ab_metric_display "$comparison_file" baseline pass_rate)"
  candidate_pass_rate="$(ab_metric_display "$comparison_file" candidate pass_rate)"

  printf 'AgentBench — Setup Comparison\n\n'
  printf '%-30s %-16s %-16s\n' "Metric" "$baseline_name" "$candidate_name"
  printf '%-30s %-16s %-16s\n' "Pass rate" "$baseline_pass_rate%" "$candidate_pass_rate%"
  printf '%-30s %-16s %-16s\n' "Median score" \
    "$(ab_metric_display "$comparison_file" baseline median_score)" \
    "$(ab_metric_display "$comparison_file" candidate median_score)"
  printf '%-30s %-16s %-16s\n' "First-pass success" \
    "$(ab_metric_display "$comparison_file" baseline first_pass_success_rate)" \
    "$(ab_metric_display "$comparison_file" candidate first_pass_success_rate)"
  printf '%-30s %-16s %-16s\n' "Critical failure runs" \
    "$(ab_metric_display "$comparison_file" baseline critical_failure_count)" \
    "$(ab_metric_display "$comparison_file" candidate critical_failure_count)"
  printf '%-30s %-16s %-16s\n' "Scope violations" \
    "$(ab_metric_display "$comparison_file" baseline scope_violation_count)" \
    "$(ab_metric_display "$comparison_file" candidate scope_violation_count)"
  printf '%-30s %-16s %-16s\n' "Median duration (seconds)" \
    "$(ab_metric_display "$comparison_file" baseline median_duration_seconds)" \
    "$(ab_metric_display "$comparison_file" candidate median_duration_seconds)"

  printf '\nFinding:\n'
  jq -r '
    (if .candidate.pass_rate > .baseline.pass_rate then
      "In these runs, the candidate pass rate was \(.candidate.pass_rate - .baseline.pass_rate) percentage points higher."
    elif .candidate.pass_rate < .baseline.pass_rate then
      "In these runs, the candidate pass rate was \(.baseline.pass_rate - .candidate.pass_rate) percentage points lower."
    elif .candidate.median_score > .baseline.median_score then
      "Pass rates were equal; the candidate median score was \(.candidate.median_score - .baseline.median_score) points higher."
    elif .candidate.median_score < .baseline.median_score then
      "Pass rates were equal; the candidate median score was \(.baseline.median_score - .candidate.median_score) points lower."
    else
      "The measured pass rates and median scores were equal in these runs."
    end) as $outcome |
    (.candidate.median_duration_seconds - .baseline.median_duration_seconds) as $duration_delta |
    if $duration_delta > 0 then
      "\($outcome) Candidate median duration was \($duration_delta) seconds longer."
    elif $duration_delta < 0 then
      "\($outcome) Candidate median duration was \(-$duration_delta) seconds shorter."
    else "\($outcome) Median durations were equal." end
  ' "$comparison_file"
}

ab_write_run_table() {
  local comparison_file="$1"
  local side="$2"

  jq -r --arg side "$side" '
    .runs[$side][] |
    "| `\(.run_id)` | \(.status) | \(.score) | \(.agent.duration_seconds) | \(.critical_failures | length) | \(.scope_violations | length) |"
  ' "$comparison_file"
}

ab_write_validation_details() {
  local comparison_file="$1"

  jq -r '
    [(.runs.baseline[]), (.runs.candidate[])][] as $run |
    ($run.validations | length) as $total |
    ($run.validations | map(select(.passed)) | length) as $passed |
    "| `\($run.run_id)` | \($passed)/\($total) | \($run.required_files | map(select(.exists == false)) | length) | \($run.scope_violations | length) |"
  ' "$comparison_file"
}

ab_write_critical_details() {
  local comparison_file="$1"

  jq -r '
    [(.runs.baseline[]), (.runs.candidate[])][] |
    select((.critical_failures | length) > 0) |
    .run_id as $run_id |
    .critical_failures[] |
    "- `\($run_id)`: \(.)"
  ' "$comparison_file"
}

ab_write_diff_details() {
  local comparison_file="$1"

  jq -r '
    [(.runs.baseline[]), (.runs.candidate[])][] |
    "### `\(.run_id)`\n\n```text\n\(if (.git_diff.stat | length) > 0 then .git_diff.stat else "No tracked-file diff." end)\n```\n\nChanged files: \(.changed_files | length)."
  ' "$comparison_file"
}

ab_write_markdown_report() {
  local comparison_file="$1"
  local output_file="$2"
  local baseline_id
  local candidate_id
  local critical_details
  local finding

  baseline_id="$(jq -r '.baseline.setup_id' "$comparison_file")"
  candidate_id="$(jq -r '.candidate.setup_id' "$comparison_file")"
  finding="$(jq -r '
    (if .candidate.pass_rate > .baseline.pass_rate then
      "The candidate had a higher measured pass rate in these runs."
    elif .candidate.pass_rate < .baseline.pass_rate then
      "The candidate had a lower measured pass rate in these runs."
    elif .candidate.median_score > .baseline.median_score then
      "Pass rates were equal and the candidate had a higher median score."
    elif .candidate.median_score < .baseline.median_score then
      "Pass rates were equal and the candidate had a lower median score."
    else "Measured pass rates and median scores were equal."
    end) as $outcome |
    (.candidate.median_duration_seconds - .baseline.median_duration_seconds) as $duration_delta |
    if $duration_delta > 0 then
      "\($outcome) Candidate median duration was \($duration_delta) seconds longer."
    elif $duration_delta < 0 then
      "\($outcome) Candidate median duration was \(-$duration_delta) seconds shorter."
    else "\($outcome) Median durations were equal." end' "$comparison_file")"
  critical_details="$(ab_write_critical_details "$comparison_file")"

  {
    printf '# AgentBench Comparison: %s vs %s\n\n' "$baseline_id" "$candidate_id"
    printf 'Comparison ID: `%s`  \n' "$(jq -r '.comparison_id' "$comparison_file")"
    printf 'Created: `%s`\n\n' "$(jq -r '.created_at' "$comparison_file")"
    printf '## Executive Summary\n\n%s\n\n' "$finding"
    printf '| Metric | %s | %s |\n|---|---:|---:|\n' "$baseline_id" "$candidate_id"
    printf '| Pass rate | %s%% | %s%% |\n' \
      "$(ab_metric_display "$comparison_file" baseline pass_rate)" \
      "$(ab_metric_display "$comparison_file" candidate pass_rate)"
    printf '| Median score | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline median_score)" \
      "$(ab_metric_display "$comparison_file" candidate median_score)"
    printf '| Minimum / maximum | %s / %s | %s / %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline minimum_score)" \
      "$(ab_metric_display "$comparison_file" baseline maximum_score)" \
      "$(ab_metric_display "$comparison_file" candidate minimum_score)" \
      "$(ab_metric_display "$comparison_file" candidate maximum_score)"
    printf '| Score spread | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline score_spread)" \
      "$(ab_metric_display "$comparison_file" candidate score_spread)"
    printf '| First-pass success | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline first_pass_success_rate)" \
      "$(ab_metric_display "$comparison_file" candidate first_pass_success_rate)"
    printf '| Critical failure runs | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline critical_failure_count)" \
      "$(ab_metric_display "$comparison_file" candidate critical_failure_count)"
    printf '| Scope violations | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline scope_violation_count)" \
      "$(ab_metric_display "$comparison_file" candidate scope_violation_count)"
    printf '| Median duration (seconds) | %s | %s |\n\n' \
      "$(ab_metric_display "$comparison_file" baseline median_duration_seconds)" \
      "$(ab_metric_display "$comparison_file" candidate median_duration_seconds)"

    printf '## Benchmark Definition\n\n'
    jq -r '.benchmark_definition' "$comparison_file"
    printf '\n\n## Setup Definitions\n\n### %s\n\n' "$baseline_id"
    jq -r '.setups.baseline.definition' "$comparison_file"
    printf '\n\n### %s\n\n' "$candidate_id"
    jq -r '.setups.candidate.definition' "$comparison_file"
    printf '\n\n## Environment Fingerprint\n\n'
    printf '%s `%s`\n' '- Starting commit:' "$(jq -r '.starting_commit' "$comparison_file")"
    printf '%s `%s`\n' '- Benchmark hash:' "$(jq -r '.benchmark_content_hash' "$comparison_file")"
    printf '%s\n' "- Timeout: $(jq -r '.timeout_seconds' "$comparison_file") seconds"
    printf '| Environment | %s | %s |\n|---|---|---|\n' "$baseline_id" "$candidate_id"
    printf '| AgentBench | `%s` | `%s` |\n' \
      "$(jq -r '.runs.baseline[0].environment.agentbench_version' "$comparison_file")" \
      "$(jq -r '.runs.candidate[0].environment.agentbench_version' "$comparison_file")"
    printf '| Operating system | `%s` | `%s` |\n\n' \
      "$(jq -r '.runs.baseline[0].environment.operating_system' "$comparison_file")" \
      "$(jq -r '.runs.candidate[0].environment.operating_system' "$comparison_file")"

    printf '## Score Breakdown\n\n'
    printf '| Median category | %s | %s |\n|---|---:|---:|\n' "$baseline_id" "$candidate_id"
    printf '| Correctness | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline median_correctness)" \
      "$(ab_metric_display "$comparison_file" candidate median_correctness)"
    printf '| Regression safety | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline median_regression_safety)" \
      "$(ab_metric_display "$comparison_file" candidate median_regression_safety)"
    printf '| Instruction compliance | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline median_instruction_compliance)" \
      "$(ab_metric_display "$comparison_file" candidate median_instruction_compliance)"
    printf '| Efficiency | %s | %s |\n\n' \
      "$(ab_metric_display "$comparison_file" baseline median_efficiency)" \
      "$(ab_metric_display "$comparison_file" candidate median_efficiency)"

    printf '## Individual Run Results\n\n### %s\n\n' "$baseline_id"
    printf '| Run | Status | Score | Duration (s) | Critical failures | Scope violations |\n|---|---:|---:|---:|---:|---:|\n'
    ab_write_run_table "$comparison_file" baseline
    printf '\n### %s\n\n' "$candidate_id"
    printf '| Run | Status | Score | Duration (s) | Critical failures | Scope violations |\n|---|---:|---:|---:|---:|---:|\n'
    ab_write_run_table "$comparison_file" candidate

    printf '\n## Validation Results\n\n'
    printf '| Run | Passed commands | Missing required files | Scope violations |\n|---|---:|---:|---:|\n'
    ab_write_validation_details "$comparison_file"

    printf '\n## Critical Failures\n\n'
    if [[ -n "$critical_details" ]]; then
      printf '%s\n' "$critical_details"
    else
      printf 'No critical failures were measured.\n'
    fi

    printf '\n## Git Diff Summary\n\n'
    ab_write_diff_details "$comparison_file"

    printf '\n## Efficiency Metrics\n\n'
    printf '| Metric | %s | %s |\n|---|---:|---:|\n' "$baseline_id" "$candidate_id"
    printf '| Median duration (seconds) | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline median_duration_seconds)" \
      "$(ab_metric_display "$comparison_file" candidate median_duration_seconds)"
    printf '| Median changed files | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline median_changed_file_count)" \
      "$(ab_metric_display "$comparison_file" candidate median_changed_file_count)"
    printf '| Median token usage | %s | %s |\n' \
      "$(ab_metric_display "$comparison_file" baseline median_token_usage)" \
      "$(ab_metric_display "$comparison_file" candidate median_token_usage)"
    printf '| Total cost | %s | %s |\n\n' \
      "$(ab_metric_display "$comparison_file" baseline total_cost)" \
      "$(ab_metric_display "$comparison_file" candidate total_cost)"
    printf 'Attempts, tool calls, cost, token usage, and human intervention remain unavailable unless a future adapter reports them.\n\n'
    printf '## Findings\n\n%s Results describe this experiment and do not establish causation.\n\n' "$finding"
    printf '## Limitations\n\n'
    printf '%s\n' "- The sample contains $(jq -r '.baseline.run_count' "$comparison_file") runs per setup."
    printf '%s\n' '- Semantic quality is not included in the deterministic score.'
    printf '%s\n\n' '- Unavailable provider metrics are reported as unavailable rather than estimated.'
    printf '## Reproduction\n\n```bash\n'
    printf './agentbench.sh run --setup %s --agent-command %q --runs %s --timeout %s --revision %s\n' \
      "$baseline_id" \
      "$(jq -r '.runs.baseline[0].agent.command' "$comparison_file")" \
      "$(jq -r '.baseline.run_count' "$comparison_file")" \
      "$(jq -r '.timeout_seconds' "$comparison_file")" \
      "$(jq -r '.starting_commit' "$comparison_file")"
    printf './agentbench.sh run --setup %s --agent-command %q --runs %s --timeout %s --revision %s\n' \
      "$candidate_id" \
      "$(jq -r '.runs.candidate[0].agent.command' "$comparison_file")" \
      "$(jq -r '.candidate.run_count' "$comparison_file")" \
      "$(jq -r '.timeout_seconds' "$comparison_file")" \
      "$(jq -r '.starting_commit' "$comparison_file")"
    printf './agentbench.sh compare %s %s\n```\n' "$baseline_id" "$candidate_id"
  } > "$output_file"
}

ab_show_report() {
  local comparison_id="$1"
  local project_root
  local report_file

  ab_validate_identifier "$comparison_id" "comparison" || return 1
  project_root="$(ab_project_root)" || ab_die "report must execute inside a Git repository"
  report_file="$project_root/.agentbench/reports/$comparison_id/BENCHMARK.md"
  [[ -f "$report_file" ]] || ab_die "comparison report not found: $comparison_id"
  cat "$report_file"
}
