#!/usr/bin/env bash

AB_SCORE_TOTAL=0
AB_SCORE_CORRECTNESS=0
AB_SCORE_REGRESSION_SAFETY=0
AB_SCORE_INSTRUCTION_COMPLIANCE=0
AB_SCORE_EFFICIENCY=0
AB_SCORE_THRESHOLD=70
AB_SCORE_STATUS="FAIL"

ab_calculate_score() {
  local benchmark_file="$1"
  local validation_total="$2"
  local validation_passed="$3"
  local required_files_ok="$4"
  local scope_ok="$5"
  local agent_ok="$6"
  local critical_failure_count="$7"
  local correctness_weight
  local regression_weight
  local instruction_weight
  local efficiency_weight
  local required_weight
  local scope_weight

  correctness_weight="$(ab_scoring_weight "$benchmark_file" "Correctness")"
  regression_weight="$(ab_scoring_weight "$benchmark_file" "Regression Safety")"
  instruction_weight="$(ab_scoring_weight "$benchmark_file" "Instruction Compliance")"
  efficiency_weight="$(ab_scoring_weight "$benchmark_file" "Efficiency")"
  AB_SCORE_THRESHOLD="$(ab_pass_threshold "$benchmark_file")"

  AB_SCORE_CORRECTNESS=0
  if [[ "$validation_total" -gt 0 && "$validation_passed" -eq "$validation_total" ]]; then
    AB_SCORE_CORRECTNESS="$correctness_weight"
  fi

  AB_SCORE_REGRESSION_SAFETY=0
  if [[ "$validation_total" -gt 0 ]]; then
    AB_SCORE_REGRESSION_SAFETY=$((regression_weight * validation_passed / validation_total))
  fi

  required_weight=$((instruction_weight / 2))
  scope_weight=$((instruction_weight - required_weight))
  AB_SCORE_INSTRUCTION_COMPLIANCE=0
  if [[ "$required_files_ok" == "true" ]]; then
    AB_SCORE_INSTRUCTION_COMPLIANCE=$((AB_SCORE_INSTRUCTION_COMPLIANCE + required_weight))
  fi
  if [[ "$scope_ok" == "true" ]]; then
    AB_SCORE_INSTRUCTION_COMPLIANCE=$((AB_SCORE_INSTRUCTION_COMPLIANCE + scope_weight))
  fi

  AB_SCORE_EFFICIENCY=0
  if [[ "$agent_ok" == "true" ]]; then
    AB_SCORE_EFFICIENCY="$efficiency_weight"
  fi

  AB_SCORE_TOTAL=$((
    AB_SCORE_CORRECTNESS +
    AB_SCORE_REGRESSION_SAFETY +
    AB_SCORE_INSTRUCTION_COMPLIANCE +
    AB_SCORE_EFFICIENCY
  ))

  AB_SCORE_STATUS="FAIL"
  if [[ "$critical_failure_count" -eq 0 && \
        "$validation_total" -gt 0 && \
        "$validation_passed" -eq "$validation_total" && \
        "$AB_SCORE_TOTAL" -ge "$AB_SCORE_THRESHOLD" ]]; then
    AB_SCORE_STATUS="PASS"
  fi
}
