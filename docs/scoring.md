# Deterministic Scoring

Every run produces `PASS` or `FAIL` and an integer score from 0 through 100.

## v1 Evidence Mapping

| Category | Evidence |
|---|---|
| Correctness | Full category weight when every validation command passes; otherwise zero |
| Regression Safety | Category weight multiplied by the fraction of validation commands that pass, rounded down |
| Instruction Compliance | Half for all required files existing and half for zero scope violations; odd points assign the remainder to scope |
| Efficiency | Full category weight when the agent exits zero before timeout; otherwise zero |

Benchmarks can change category weights while preserving this mapping. Category weights must total 100.

## PASS Rules

A run passes only when:

- The score reaches the configured threshold
- At least one validation command exists
- Every validation command passes
- No critical failure occurs

Deterministically detected critical failures are agent timeout/failure, validation failure, missing required file, and allowed-scope violation. Critical failures override the numeric score.

The prose under `Critical Failures` documents benchmark intent. v0.1.0 does not semantically interpret arbitrary prose.
