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

ab_hash_file() {
  local file_path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file_path" | awk '{ print $1 }'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file_path" | awk '{ print $1 }'
  else
    ab_error "required SHA-256 tool not found: sha256sum or shasum"
    return 1
  fi
}

ab_now_iso8601() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

ab_redact_stream() {
  sed -E \
    -e 's/(gh[pousr]_[A-Za-z0-9_]{8,})/[REDACTED]/g' \
    -e 's/((API_KEY|TOKEN|SECRET|PASSWORD|AUTHORIZATION)[=:][[:space:]]*)[^[:space:]]+/\1[REDACTED]/g' \
    -e 's/((api_key|token|secret|password|authorization)[=:][[:space:]]*)[^[:space:]]+/\1[REDACTED]/g'
}

ab_redact_file() {
  local input_file="$1"
  local output_file="$2"

  ab_redact_stream < "$input_file" > "$output_file"
}

ab_redact_text() {
  printf '%s' "$1" | ab_redact_stream
}

ab_json_array_from_lines() {
  jq -Rsc 'split("\n") | map(select(length > 0))' "$1"
}

ab_generate_id() {
  local prefix
  prefix="$(ab_slug "$1")"
  printf '%s-%s-%s-%s\n' \
    "$prefix" \
    "$(date -u '+%Y%m%dt%H%M%Sz')" \
    "$$" \
    "$RANDOM"
}

ab_validate_identifier() {
  local value="$1"
  local kind="$2"
  local safe_value

  safe_value="$(ab_slug "$value")"
  if [[ -z "$safe_value" || "$safe_value" != "$value" ]]; then
    ab_error "$kind identifier must use lowercase letters, numbers, dot, underscore, or hyphen: $value"
    return 1
  fi
}
