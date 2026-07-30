# Architecture Decisions

Status: accepted for v0.1.0

## ADR-001: Bash with jq

Use portable Bash modules and require `jq` for reliable JSON creation and aggregation. This keeps the downloadable runner simple while avoiding unsafe hand-built JSON.

## ADR-002: Structured Markdown by named sections

Parse exact level-two section headings and constrained content shapes instead of attempting general Markdown parsing. Human prose remains readable while machine-consumed fields stay testable.

## ADR-003: Detached Git worktrees

Use one detached worktree per run, all resolved from one starting commit. Worktrees are faster than full clones and preserve the original workspace.

## ADR-004: Standard-input custom adapter

Run a user-provided shell command in the isolated workspace and send the assembled prompt on standard input. Provider-specific adapters can implement the same contract later.

## ADR-005: Evidence JSON before reports

Persist individual result JSON first. All comparisons and reports derive from stored results so statistics remain auditable and reports can be regenerated.

## ADR-006: Sequential repeated runs

Execute repeats sequentially in v0.1.0. This reduces resource contention and experimental noise; concurrent execution is deferred.

## ADR-007: Explicit unavailable metrics

Represent unavailable tokens, cost, model, and provider metadata as JSON `null`. Never infer provider data.

## ADR-008: Best-effort timeout portability

Use `timeout` on Linux or `gtimeout` on macOS when available, with a portable process-monitor fallback. Timeout status is normalized and recorded.

## ADR-009: No YAML

Do not add YAML configuration. GitHub Actions is the only unavoidable YAML file because GitHub requires that workflow format.

## ADR-010: Generated standalone distribution

Develop against focused modules and deterministically generate the repository-root `agentbench.sh` with embedded templates. CI rebuilds it and rejects a diff, ensuring the documented one-file download matches reviewed source.
