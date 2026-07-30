#!/usr/bin/env bash

AB_WORKSPACE_PARENT=""
AB_WORKSPACE_PATH=""
AB_WORKSPACE_PROJECT_ROOT=""

ab_resolve_revision() {
  local project_root="$1"
  local revision="${2:-HEAD}"

  git -C "$project_root" rev-parse --verify "${revision}^{commit}" 2>/dev/null || {
    ab_error "cannot resolve Git revision: $revision"
    return 1
  }
}

ab_workspace_create() {
  local project_root="$1"
  local revision="$2"
  local run_id="$3"
  local temp_root="$project_root/.agentbench/tmp"
  local safe_run_id

  safe_run_id="$(ab_slug "$run_id")"
  [[ -n "$safe_run_id" ]] || {
    ab_error "run identifier is empty or invalid"
    return 1
  }

  mkdir -p "$temp_root"
  AB_WORKSPACE_PARENT="$(mktemp -d "$temp_root/$safe_run_id.XXXXXX")"
  AB_WORKSPACE_PATH="$AB_WORKSPACE_PARENT/worktree"
  printf 'agentbench-workspace-v1\n' > "$AB_WORKSPACE_PARENT/OWNER"

  if ! git -C "$project_root" worktree add --quiet --detach \
    "$AB_WORKSPACE_PATH" "$revision"; then
    ab_workspace_discard_parent "$project_root" "$AB_WORKSPACE_PARENT"
    AB_WORKSPACE_PARENT=""
    AB_WORKSPACE_PATH=""
    return 1
  fi
}

ab_workspace_is_managed() {
  local project_root="$1"
  local parent_path="$2"
  local expected_root

  [[ -d "$parent_path" ]] || return 1
  expected_root="$(cd "$project_root/.agentbench/tmp" && pwd -P)"
  parent_path="$(cd "$parent_path" && pwd -P)"

  [[ "$parent_path" == "$expected_root/"* ]] || return 1
  [[ -f "$parent_path/OWNER" ]] || return 1
  [[ "$(cat "$parent_path/OWNER")" == "agentbench-workspace-v1" ]]
}

ab_workspace_discard_parent() {
  local project_root="$1"
  local parent_path="$2"
  local workspace_path

  if ! ab_workspace_is_managed "$project_root" "$parent_path"; then
    ab_error "refusing to clean unmanaged workspace: $parent_path"
    return 1
  fi

  parent_path="$(cd "$parent_path" && pwd -P)"
  workspace_path="$parent_path/worktree"

  if [[ -e "$workspace_path/.git" ]]; then
    git -C "$project_root" worktree remove --force "$workspace_path" >/dev/null 2>&1 || {
      ab_error "could not remove Git worktree: $workspace_path"
      return 1
    }
  fi

  rm -f "$parent_path/OWNER"
  rmdir "$parent_path" 2>/dev/null || {
    ab_error "managed workspace directory is not empty: $parent_path"
    return 1
  }
}

ab_workspace_cleanup() {
  local project_root="$1"

  if [[ -n "$AB_WORKSPACE_PARENT" ]]; then
    ab_workspace_discard_parent "$project_root" "$AB_WORKSPACE_PARENT"
    AB_WORKSPACE_PARENT=""
    AB_WORKSPACE_PATH=""
  fi
}

ab_workspace_trap_exit() {
  local exit_code="$1"

  trap - EXIT INT TERM HUP
  if [[ -n "$AB_WORKSPACE_PROJECT_ROOT" ]]; then
    ab_workspace_cleanup "$AB_WORKSPACE_PROJECT_ROOT" || true
  fi
  exit "$exit_code"
}

ab_workspace_install_cleanup_trap() {
  AB_WORKSPACE_PROJECT_ROOT="$1"
  trap 'ab_workspace_trap_exit $?' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP
}

ab_workspace_clear_cleanup_trap() {
  trap - EXIT INT TERM HUP
  AB_WORKSPACE_PROJECT_ROOT=""
}

ab_clean_managed_workspaces() {
  local project_root
  local temp_root
  local owner_file
  local cleaned=0

  project_root="$(ab_project_root)" || ab_die "clean must run inside a Git repository"
  temp_root="$project_root/.agentbench/tmp"
  [[ -d "$temp_root" ]] || {
    printf 'No AgentBench temporary workspaces found.\n'
    return 0
  }

  while IFS= read -r owner_file; do
    ab_workspace_discard_parent "$project_root" "$(dirname "$owner_file")"
    cleaned=$((cleaned + 1))
  done < <(find "$temp_root" -mindepth 2 -maxdepth 2 -type f -name OWNER -print)

  git -C "$project_root" worktree prune
  printf 'Cleaned %s AgentBench workspace(s).\n' "$cleaned"
}
