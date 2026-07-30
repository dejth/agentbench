# Benchmark: Replace with a clear task name

Format-Version: 1
Benchmark-ID: example-task

## Task

Describe the real project task. Link to details under `cases/` when useful.

## Instructions

- Identify the root cause or required behavior.
- Make the smallest complete change.
- Add or update regression tests.
- Run every validation command.

## Allowed Scope

- `src/**`
- `tests/**`

## Required Files

- `tests/example-test.sh`

## Validation

```bash
./tests/example-test.sh
```

## Success Criteria

- Required validation passes.
- Required files exist.
- Modified files remain inside the allowed scope.

## Critical Failures

- A required validation command fails.
- A file outside the allowed scope is modified.
- A required file is missing.

## Scoring

### Correctness — 50 points

- Required validation passes: 50

### Regression Safety — 20 points

- All configured validation commands pass: 20

### Instruction Compliance — 20 points

- Required files exist: 10
- Modified files remain inside the allowed scope: 10

### Efficiency — 10 points

- Agent command completes within the configured timeout: 10

## Pass Conditions

- Total score is at least 70.
- Every validation command passes.
- No critical failure occurs.
