# AgentBench v0.1.0 Requirements

Status: approved for implementation
Format version: 1

## Functional Requirements

| ID | Requirement |
|---|---|
| FR-001 | `help` and `version` expose a stable CLI entrypoint. |
| FR-002 | `init` creates `.agentbench/` with benchmark, case, setup, result, and report scaffolding without overwriting user files. |
| FR-003 | `validate` parses the benchmark and reports missing or malformed required sections. |
| FR-004 | Benchmarks and setups use documented Markdown formats; YAML is not used. |
| FR-005 | `run` accepts a setup, custom agent command, run count, timeout, and optional starting revision. |
| FR-006 | Each run uses an isolated Git worktree created from the same resolved commit. |
| FR-007 | The agent receives benchmark task content and setup context through a documented prompt contract. |
| FR-008 | Validation commands execute after the agent command and preserve command, status, duration, stdout, and stderr evidence. |
| FR-009 | Evaluation checks required files and allowed-scope compliance against the starting commit. |
| FR-010 | Critical failures override numeric score; otherwise score and required checks determine PASS or FAIL. |
| FR-011 | Each run writes versioned JSON with metadata, checks, score breakdown, failures, changed files, and available efficiency metrics. |
| FR-012 | Repeated runs preserve individual results and create a setup-level run index. |
| FR-013 | `compare` calculates pass rate, median/minimum/maximum score, spread, critical failures, scope violations, and median duration. |
| FR-014 | Comparison creates a Markdown `BENCHMARK.md`, JSON summary, and terminal table using only measured data. |
| FR-015 | `report` locates or regenerates a stored comparison report. |
| FR-016 | `clean` removes only AgentBench-managed temporary workspaces after confirming their markers. |
| FR-017 | Environment metadata records available versions, hashes, timestamps, command, revision, and identifiers; unavailable values are `null`. |
| FR-018 | Examples demonstrate baseline-to-candidate use without requiring a specific provider. |

## Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-001 | Support macOS Bash 3.2 and current Linux Bash without non-portable Bash 4 features. |
| NFR-002 | Use strict mode, quoted paths, `mktemp`, cleanup traps, predictable exit codes, and actionable errors. |
| NFR-003 | Never reset, clean, or check out the user's original workspace during a run. |
| NFR-004 | Avoid persisting obvious secrets in captured output through best-effort redaction. |
| NFR-005 | JSON contracts validate against a versioned schema. |
| NFR-006 | Tests use temporary repositories and never modify unrelated workspaces. |
| NFR-007 | Shell sources pass `bash -n`; ShellCheck passes when available. |
| NFR-008 | CI runs deterministic tests on macOS and Linux. |

## Benchmark Contract

Required level-two sections:

- `Task`
- `Instructions`
- `Allowed Scope`
- `Required Files`
- `Validation`
- `Success Criteria`
- `Critical Failures`
- `Scoring`
- `Pass Conditions`

Validation commands are read only from the fenced `bash` or `sh` block directly under `Validation`. Allowed scopes and required files are bullet lists. The format is intentionally predictable; unknown sections are preserved but ignored by v0.1.0.

## CLI Contract

```text
agentbench.sh help
agentbench.sh version
agentbench.sh init
agentbench.sh validate [--benchmark PATH]
agentbench.sh run --setup ID --agent-command COMMAND [--runs N] [--timeout SECONDS] [--revision REF]
agentbench.sh compare BASELINE CANDIDATE
agentbench.sh report COMPARISON_ID
agentbench.sh clean
```

## Acceptance Criteria

The release is accepted only when the complete example workflow succeeds, invalid inputs fail with stable non-zero exits, isolated workspaces are cleaned safely, scope and required-file failures are detected, result JSON validates, comparison statistics match fixtures, tests pass on macOS and Linux, and documentation matches the implemented CLI.

## Assumptions

- The host project is a Git repository with at least one commit.
- `git`, POSIX utilities, Bash, and `jq` are installed.
- The configured agent command accepts a prompt on standard input and edits its current working directory.
- AgentBench cannot prevent an explicitly configured agent command from using its own network access.
