#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=tests/test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
# shellcheck source=src/utils.sh
source "$TEST_ROOT/src/utils.sh"
# shellcheck source=src/workspace.sh
source "$TEST_ROOT/src/workspace.sh"
test_setup
trap test_teardown EXIT

make_git_repo "$TEST_TMP/project"
mkdir -p "$TEST_TMP/project/.agentbench/tmp/unmanaged"
revision="$(git -C "$TEST_TMP/project" rev-parse HEAD)"
ab_workspace_create "$TEST_TMP/project" "$revision" clean-test
managed_parent="$AB_WORKSPACE_PARENT"

(
  cd "$TEST_TMP/project"
  "$TEST_ROOT/agentbench.sh" clean >/dev/null
)
assert_not_exists "$managed_parent"
[[ -d "$TEST_TMP/project/.agentbench/tmp/unmanaged" ]] || fail "clean removed an unmanaged directory"

printf 'ok - clean removes only marker-owned workspaces\n'
