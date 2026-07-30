#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=tests/test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
test_setup
trap test_teardown EXIT

jq -e '
  .["$schema"] == "https://json-schema.org/draft/2020-12/schema" and
  .properties.schema_version.const == "1" and
  (.required | index("critical_failures") != null)
' "$TEST_ROOT/schemas/result.schema.json" >/dev/null || fail "result schema contract is invalid"

jq -e . "$TEST_ROOT/tests/fixtures/result.valid.json" >/dev/null || fail "result fixture is not valid JSON"
if command -v check-jsonschema >/dev/null 2>&1; then
  check-jsonschema \
    --schemafile "$TEST_ROOT/schemas/result.schema.json" \
    "$TEST_ROOT/tests/fixtures/result.valid.json" >/dev/null || fail "result fixture does not match the schema"
fi

printf 'ok - result schema exposes required v1 contract\n'
