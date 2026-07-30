#!/usr/bin/env bash

ab_compare_setups() {
  local baseline_id="$1"
  local candidate_id="$2"
  local project_root
  local baseline_file
  local candidate_file
  local baseline_commit
  local candidate_commit
  local baseline_benchmark_hash
  local candidate_benchmark_hash
  local baseline_count
  local candidate_count
  local comparison_id
  local report_dir
  local comparison_file

  ab_require_command jq
  ab_validate_identifier "$baseline_id" "setup" || return 1
  ab_validate_identifier "$candidate_id" "setup" || return 1
  [[ "$baseline_id" != "$candidate_id" ]] || ab_die "compare requires two different setup identifiers"
  project_root="$(ab_project_root)" || ab_die "compare must execute inside a Git repository"
  baseline_file="$project_root/.agentbench/results/$baseline_id/runs.json"
  candidate_file="$project_root/.agentbench/results/$candidate_id/runs.json"
  [[ -f "$baseline_file" ]] || ab_die "run index not found for setup: $baseline_id"
  [[ -f "$candidate_file" ]] || ab_die "run index not found for setup: $candidate_id"

  baseline_commit="$(jq -r '.starting_commit' "$baseline_file")"
  candidate_commit="$(jq -r '.starting_commit' "$candidate_file")"
  [[ "$baseline_commit" == "$candidate_commit" ]] || ab_die "setups use different starting commits"
  baseline_benchmark_hash="$(jq -r '.benchmark_content_hash' "$baseline_file")"
  candidate_benchmark_hash="$(jq -r '.benchmark_content_hash' "$candidate_file")"
  [[ "$baseline_benchmark_hash" == "$candidate_benchmark_hash" ]] || ab_die "setups use different benchmark definitions"
  baseline_count="$(jq '.results | length' "$baseline_file")"
  candidate_count="$(jq '.results | length' "$candidate_file")"
  [[ "$baseline_count" -eq "$candidate_count" ]] || ab_die "setups use different run counts"
  [[ "$(jq '.timeout_seconds' "$baseline_file")" -eq "$(jq '.timeout_seconds' "$candidate_file")" ]] || \
    ab_die "setups use different timeouts"

  comparison_id="$(ab_generate_id "$baseline_id-vs-$candidate_id")"
  report_dir="$project_root/.agentbench/reports/$comparison_id"
  comparison_file="$report_dir/comparison.json"
  mkdir -p "$report_dir"

  jq -n \
    --arg schema_version "1" \
    --arg comparison_id "$comparison_id" \
    --arg created_at "$(ab_now_iso8601)" \
    --arg starting_commit "$baseline_commit" \
    --slurpfile baseline "$baseline_file" \
    --slurpfile candidate "$candidate_file" \
    '
      def median:
        sort as $values |
        ($values | length) as $count |
        if $count == 0 then null
        elif ($count % 2) == 1 then $values[($count / 2 | floor)]
        else (($values[$count / 2 - 1] + $values[$count / 2]) / 2)
        end;
      def metrics($index):
        $index.results as $runs |
        ($runs | length) as $count |
        ($runs | map(select(.status == "PASS")) | length) as $passes |
        {
          setup_id: $index.setup_id,
          experiment_id: $index.experiment_id,
          run_count: $count,
          pass_count: $passes,
          pass_rate: (($passes * 1000 / $count | round) / 10),
          median_score: ($runs | map(.score) | median),
          minimum_score: ($runs | map(.score) | min),
          maximum_score: ($runs | map(.score) | max),
          score_spread: (($runs | map(.score) | max) - ($runs | map(.score) | min)),
          first_pass_success_rate: null,
          critical_failure_count: ($runs | map(select((.critical_failures | length) > 0)) | length),
          scope_violation_count: ($runs | map(.scope_violations | length) | add),
          median_duration_seconds: ($runs | map(.agent.duration_seconds) | median),
          median_changed_file_count: ($runs | map(.changed_files | length) | median),
          median_correctness: ($runs | map(.score_breakdown.correctness) | median),
          median_regression_safety: ($runs | map(.score_breakdown.regression_safety) | median),
          median_instruction_compliance: ($runs | map(.score_breakdown.instruction_compliance) | median),
          median_efficiency: ($runs | map(.score_breakdown.efficiency) | median),
          median_token_usage: null,
          total_cost: null,
          cost_per_successful_run: null,
          human_intervention_count: null
        };
      {
        schema_version: $schema_version,
        comparison_id: $comparison_id,
        created_at: $created_at,
        benchmark_id: $baseline[0].benchmark_id,
        benchmark_content_hash: $baseline[0].benchmark_content_hash,
        benchmark_definition: $baseline[0].benchmark_definition,
        starting_commit: $starting_commit,
        timeout_seconds: $baseline[0].timeout_seconds,
        setups: {
          baseline: {id: $baseline[0].setup_id, definition: $baseline[0].setup_definition},
          candidate: {id: $candidate[0].setup_id, definition: $candidate[0].setup_definition}
        },
        baseline: metrics($baseline[0]),
        candidate: metrics($candidate[0]),
        runs: {
          baseline: $baseline[0].results,
          candidate: $candidate[0].results
        }
      }
    ' > "$comparison_file.next"
  mv "$comparison_file.next" "$comparison_file"
  ab_write_markdown_report "$comparison_file" "$report_dir/BENCHMARK.md"
  cp "$comparison_file" "$project_root/.agentbench/reports/latest.json.next"
  mv "$project_root/.agentbench/reports/latest.json.next" \
    "$project_root/.agentbench/reports/latest.json"
  ab_print_comparison_terminal "$comparison_file"
  printf '\nMarkdown report: %s\n' "$report_dir/BENCHMARK.md"
  printf 'Raw comparison: %s\n' "$comparison_file"
}
