#!/usr/bin/env bash

AB_AGENT_EXIT_CODE=""
AB_AGENT_DURATION_SECONDS=""
AB_AGENT_TIMED_OUT="false"

ab_process_children() {
  local parent_id="$1"

  ps -eo pid=,ppid= | awk -v wanted="$parent_id" '$2 == wanted { print $1 }'
}

ab_kill_process_tree() {
  local process_id="$1"
  local signal_name="$2"
  local child_id

  while IFS= read -r child_id; do
    if [[ -n "$child_id" ]]; then
      ab_kill_process_tree "$child_id" "$signal_name"
    fi
  done < <(ab_process_children "$process_id")

  kill "-$signal_name" "$process_id" 2>/dev/null || true
}

ab_build_agent_prompt() {
  local benchmark_file="$1"
  local context_file="$2"
  local output_file="$3"
  local section_name

  {
    printf '# AgentBench Task\n\n'
    printf 'Complete this task inside the current isolated Git workspace.\n'
    printf 'Do not modify files outside the allowed scope.\n\n'

    for section_name in Task Instructions "Allowed Scope" "Required Files" \
      "Success Criteria" "Critical Failures"; do
      printf '## %s\n\n' "$section_name"
      ab_section "$benchmark_file" "$section_name"
      printf '\n'
    done

    printf '## Setup Context\n\n'
    cat "$context_file"
    printf '\n'
  } > "$output_file"
}

ab_run_custom_agent() {
  local workspace_path="$1"
  local agent_command="$2"
  local prompt_file="$3"
  local timeout_seconds="$4"
  local stdout_file="$5"
  local stderr_file="$6"
  local started_at
  local ended_at
  local process_id
  local elapsed=0
  local exit_code=0

  AB_AGENT_EXIT_CODE=""
  AB_AGENT_DURATION_SECONDS=""
  AB_AGENT_TIMED_OUT="false"

  [[ "$timeout_seconds" =~ ^[1-9][0-9]*$ ]] || {
    ab_error "timeout must be a positive integer"
    return 1
  }
  [[ -n "$(ab_trim "$agent_command")" ]] || {
    ab_error "agent command must not be empty"
    return 1
  }

  ab_ensure_parent "$stdout_file"
  ab_ensure_parent "$stderr_file"
  started_at="$(date +%s)"

  (
    cd "$workspace_path"
    exec bash -lc "$agent_command"
  ) < "$prompt_file" > "$stdout_file" 2> "$stderr_file" &
  process_id=$!

  {
    while kill -0 "$process_id" 2>/dev/null; do
      if [[ "$elapsed" -ge "$timeout_seconds" ]]; then
        AB_AGENT_TIMED_OUT="true"
        ab_kill_process_tree "$process_id" TERM
        sleep 1
        if kill -0 "$process_id" 2>/dev/null; then
          ab_kill_process_tree "$process_id" KILL
        fi
        break
      fi
      sleep 1
      elapsed=$((elapsed + 1))
    done

    set +e
    wait "$process_id"
    exit_code=$?
    set -e
  } 2>/dev/null

  if [[ "$AB_AGENT_TIMED_OUT" == "true" ]]; then
    exit_code=124
  fi

  ended_at="$(date +%s)"
  AB_AGENT_EXIT_CODE="$exit_code"
  AB_AGENT_DURATION_SECONDS=$((ended_at - started_at))
  return 0
}
