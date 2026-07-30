#!/usr/bin/env bash

AB_VERSION="0.1.0"
AB_BENCHMARK_FORMAT_VERSION="1"
AB_RESULT_FORMAT_VERSION="1"

ab_error() {
  printf 'agentbench: %s\n' "$*" >&2
}

ab_die() {
  ab_error "$*"
  exit 1
}

ab_require_command() {
  command -v "$1" >/dev/null 2>&1 || ab_die "required command not found: $1"
}

ab_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

ab_slug() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed 's/[^a-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

ab_project_root() {
  git rev-parse --show-toplevel 2>/dev/null || return 1
}

ab_ensure_parent() {
  mkdir -p "$(dirname "$1")"
}

ab_copy_unless_exists() {
  local source_path="$1"
  local destination_path="$2"

  if [[ -e "$destination_path" ]]; then
    printf 'kept     %s\n' "$destination_path"
    return 0
  fi

  ab_ensure_parent "$destination_path"
  cp "$source_path" "$destination_path"
  printf 'created  %s\n' "$destination_path"
}
