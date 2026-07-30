# Project Status

Last updated: 2026-07-30

Target: v0.1.0

Overall state: v0.1.0 release candidate validated

## Current State

- Repository identity, visibility, default branch, license, remote, active GitHub account, and clean worktree have been verified.
- Product, requirements, architecture, decisions, plan, task dependencies, and deterministic quality gates are defined and merged through PR #2.
- CLI initialization and Markdown parsing are merged through PR #10.
- Git worktree isolation and the custom agent adapter are merged through PR #11.
- Deterministic validation, scope evaluation, scoring, and result JSON are merged through PR #12.
- Repeated runs, comparison statistics, and reporting are merged through PR #13.
- Comprehensive failure fixtures, portability checks, ShellCheck, and Linux/macOS CI are merged through PR #14.
- Standalone packaging, user documentation, examples, and security guidance are merged through PR #17.
- The complete local suite and Linux/macOS CI pass on `main`.
- The raw `main` standalone runner matches the local artifact and passes version, initialization, and benchmark validation smoke checks.
- No `v0.1.0` tag or GitHub release exists yet.

## Active Work

- Issue #8: validate release readiness and publish AgentBench v0.1.0.

## Known Risks

- Shell portability across macOS Bash 3.2 and Linux requires explicit CI coverage.
- User-provided agent and validation commands execute arbitrary shell code inside generated worktrees.
- Timeout cleanup must be tested for child processes and interrupted runs.
- Markdown parsing must reject ambiguous machine-consumed structures rather than silently misread them.
- Benchmark score customization needs a narrow, documented syntax to prevent report/evaluator disagreement.

## Next Milestone

Merge the release-readiness evidence, publish and verify v0.1.0, then record final release status and close Issue #8.
