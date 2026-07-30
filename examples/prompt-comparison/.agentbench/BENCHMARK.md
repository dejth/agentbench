# Benchmark: Write the configured value

Format-Version: 1
Benchmark-ID: prompt-comparison-example

## Task

Create `output/result.txt` containing the value required by setup context.

## Instructions

- Follow setup context exactly.
- Do not change other files.

## Allowed Scope

- `output/**`

## Required Files

- `output/result.txt`

## Validation

```bash
grep -qx candidate output/result.txt
```

## Success Criteria

- The output contains the expected candidate value.

## Critical Failures

- Validation fails.
- Required output is missing.
- Scope is violated.

## Scoring

### Correctness — 50 points

- Validation passes.

### Regression Safety — 20 points

- Configured validation remains healthy.

### Instruction Compliance — 20 points

- Required output exists and scope is respected.

### Efficiency — 10 points

- The command completes before timeout.

## Pass Conditions

- Total score is at least 70.
- Every validation command passes.
- No critical failure occurs.
