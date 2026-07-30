#!/usr/bin/env bash

AB_REQUIRED_BENCHMARK_SECTIONS="Task
Instructions
Allowed Scope
Required Files
Validation
Success Criteria
Critical Failures
Scoring
Pass Conditions"

ab_unquote_markdown_code() {
  local value
  value="$(ab_trim "$1")"
  value="${value#\`}"
  value="${value%\`}"
  printf '%s\n' "$value"
}

ab_path_spec_is_safe() {
  local value="$1"

  [[ -n "$value" ]] || return 1
  [[ "$value" != /* ]] || return 1
  [[ "$value" != ".." && "$value" != ../* && "$value" != */../* && "$value" != */.. ]]
}

ab_section() {
  local file_path="$1"
  local section_name="$2"

  awk -v wanted="$section_name" '
    /^## / {
      heading = substr($0, 4)
      if (found) exit
      if (heading == wanted) {
        found = 1
        next
      }
    }
    found { print }
  ' "$file_path"
}

ab_section_exists() {
  local file_path="$1"
  local section_name="$2"

  awk -v wanted="$section_name" '
    /^## / && substr($0, 4) == wanted { found = 1; exit }
    END { exit(found ? 0 : 1) }
  ' "$file_path"
}

ab_section_list() {
  local file_path="$1"
  local section_name="$2"

  ab_section "$file_path" "$section_name" |
    awk '/^[[:space:]]*-[[:space:]]+/ {
      sub(/^[[:space:]]*-[[:space:]]+/, "")
      print
    }'
}

ab_validation_commands() {
  local file_path="$1"

  ab_section "$file_path" "Validation" |
    awk '
      !in_fence && /^```(bash|sh)[[:space:]]*$/ { in_fence = 1; next }
      in_fence && /^```[[:space:]]*$/ { exit }
      in_fence { print }
    '
}

ab_metadata_value() {
  local file_path="$1"
  local key="$2"

  awk -v wanted="$key" '
    index($0, wanted ":") == 1 {
      value = substr($0, length(wanted) + 2)
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      print value
      exit
    }
    /^## / { exit }
  ' "$file_path"
}

ab_scoring_weight() {
  local file_path="$1"
  local category="$2"

  ab_section "$file_path" "Scoring" |
    awk -v wanted="$category" '
      /^### / {
        heading = substr($0, 5)
        if (match(heading, /[0-9]+[[:space:]]+points/)) {
          weight = substr(heading, RSTART, RLENGTH)
          sub(/[[:space:]]+points$/, "", weight)
          name = substr(heading, 1, RSTART - 1)
          sub(/[[:space:]—-]+$/, "", name)
          if (name == wanted) {
            print weight
            exit
          }
        }
      }
    '
}

ab_pass_threshold() {
  local file_path="$1"
  local threshold

  threshold="$(ab_section "$file_path" "Pass Conditions" |
    sed -nE 's/.*[Tt]otal score is at least ([0-9]+).*/\1/p' |
    head -n 1)"
  printf '%s\n' "${threshold:-70}"
}

ab_validate_benchmark() {
  local file_path="$1"
  local section_name
  local missing=0
  local validation_commands
  local format_version
  local category
  local scoring_total=0
  local weight
  local pass_threshold
  local path_spec

  [[ -f "$file_path" ]] || {
    ab_error "benchmark not found: $file_path"
    return 1
  }

  format_version="$(ab_metadata_value "$file_path" "Format-Version")"
  if [[ "$format_version" != "$AB_BENCHMARK_FORMAT_VERSION" ]]; then
    ab_error "unsupported or missing Format-Version: ${format_version:-unavailable}"
    return 1
  fi

  while IFS= read -r section_name; do
    if ! ab_section_exists "$file_path" "$section_name"; then
      ab_error "missing required section: ## $section_name"
      missing=1
    fi
  done <<< "$AB_REQUIRED_BENCHMARK_SECTIONS"

  if [[ "$missing" -ne 0 ]]; then
    return 1
  fi

  validation_commands="$(ab_validation_commands "$file_path")"
  if [[ -z "$validation_commands" ]]; then
    ab_error "Validation must contain a non-empty fenced bash or sh block"
    return 1
  fi

  if [[ -z "$(ab_section_list "$file_path" "Allowed Scope")" ]]; then
    ab_error "Allowed Scope must contain at least one bullet item"
    return 1
  fi

  while IFS= read -r path_spec; do
    path_spec="$(ab_unquote_markdown_code "$path_spec")"
    if ! ab_path_spec_is_safe "$path_spec"; then
      ab_error "unsafe Allowed Scope path: $path_spec"
      return 1
    fi
  done < <(ab_section_list "$file_path" "Allowed Scope")

  while IFS= read -r path_spec; do
    path_spec="$(ab_unquote_markdown_code "$path_spec")"
    if [[ "$path_spec" != "None" && "$path_spec" != "None." ]] && \
       ! ab_path_spec_is_safe "$path_spec"; then
      ab_error "unsafe Required Files path: $path_spec"
      return 1
    fi
  done < <(ab_section_list "$file_path" "Required Files")

  for category in Correctness "Regression Safety" "Instruction Compliance" Efficiency; do
    weight="$(ab_scoring_weight "$file_path" "$category")"
    if [[ ! "$weight" =~ ^[0-9]+$ ]]; then
      ab_error "missing or invalid scoring category: $category"
      return 1
    fi
    scoring_total=$((scoring_total + weight))
  done

  if [[ "$scoring_total" -ne 100 ]]; then
    ab_error "scoring category weights must total 100, found: $scoring_total"
    return 1
  fi

  pass_threshold="$(ab_pass_threshold "$file_path")"
  if [[ ! "$pass_threshold" =~ ^[0-9]+$ || "$pass_threshold" -gt 100 ]]; then
    ab_error "pass threshold must be an integer from 0 through 100"
    return 1
  fi

  printf 'Benchmark format v%s is valid: %s\n' \
    "$AB_BENCHMARK_FORMAT_VERSION" "$file_path"
}

ab_validate_setup() {
  local setup_id="$1"
  local project_root="$2"
  local setup_dir

  setup_id="$(ab_slug "$setup_id")"
  [[ -n "$setup_id" ]] || {
    ab_error "setup identifier is empty or invalid"
    return 1
  }

  setup_dir="$project_root/.agentbench/setups/$setup_id"
  [[ -d "$setup_dir" ]] || {
    ab_error "setup not found: $setup_id"
    return 1
  }
  [[ -f "$setup_dir/CONTEXT.md" ]] || {
    ab_error "setup is missing CONTEXT.md: $setup_id"
    return 1
  }
}
