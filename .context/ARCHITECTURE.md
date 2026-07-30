# Architecture

Status: accepted for v0.1.0

## Overview

`agentbench.sh` is a thin executable that loads small Bash modules. Data flows from Markdown definitions through parsing and isolated execution to versioned JSON, then from JSON to comparison and Markdown reporting.

```text
CLI -> parser -> workspace -> adapter -> evaluator -> scoring -> result JSON
                                                        |
run indexes -> comparison ------------------------------+-> terminal/Markdown report
```

## Components

- `src/cli.sh`: argument routing, validation, and exit codes
- `src/init.sh`: non-destructive project scaffolding
- `src/parser.sh`: predictable Markdown section and list extraction
- `src/workspace.sh`: Git validation and detached worktree lifecycle
- `adapters/custom.sh`: standard-input prompt delivery and timed command execution
- `src/evaluator.sh`: validation, file, scope, and critical-failure evidence
- `src/scoring.sh`: deterministic score and PASS/FAIL calculation
- `src/runner.sh`: repeated-run orchestration and result persistence
- `src/comparison.sh`: aggregation and statistics
- `src/reporter.sh`: terminal and Markdown rendering
- `src/utils.sh`: errors, identifiers, hashing, timing, JSON, and redaction helpers

## Run Lifecycle

1. Validate repository, benchmark, setup, command, run count, and timeout.
2. Resolve the requested revision once for the full experiment.
3. Create a temporary detached Git worktree for the run.
4. Build a prompt from the benchmark task, instructions, constraints, and setup context.
5. Execute the custom adapter in the isolated workspace with a timeout.
6. Capture the Git diff and changed-file list.
7. Execute each validation command in the same workspace.
8. Evaluate required files, allowed paths, command statuses, and critical failures.
9. Calculate category scores and final status.
10. Write atomic JSON output and remove the worktree through a trap.

## Isolation and Safety

Worktrees live under `.agentbench/tmp/` and include an AgentBench ownership marker. Cleanup validates both the directory prefix and marker before removal. `git worktree remove --force` applies only to a generated worktree; the original checkout is never reset, cleaned, or switched. Interrupted runs use the same cleanup path.

## Evaluation Model

v0.1.0 maps deterministic evidence into the default 50/20/20/10 categories. Benchmark text may override category totals and the overall threshold when it follows the documented scoring syntax. Failed mandatory validation or any critical failure produces FAIL regardless of numeric score.

Semantic observations may be included as unscored notes in future formats, but never alter the deterministic v0.1.0 score.

## Storage

```text
.agentbench/
  BENCHMARK.md
  cases/
  setups/<setup>/CONTEXT.md
  results/<setup>/<run-id>/result.json
  results/<setup>/runs.json
  reports/<comparison-id>/BENCHMARK.md
  reports/<comparison-id>/comparison.json
  tmp/
```

Generated paths use sanitized identifiers and random run suffixes. JSON writes use a temporary file followed by `mv`.

## Compatibility

The public contracts are the CLI, Markdown format version 1, result schema version 1, and on-disk paths above. Internal module functions are not public API in v0.1.0.
