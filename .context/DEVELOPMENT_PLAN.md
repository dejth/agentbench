# Development Plan

Status: active

## Workstreams

1. Establish CDD, contracts, quality gates, and task dependencies.
2. Build CLI scaffolding, initialization, and Markdown parsing.
3. Build safe workspace isolation and the custom command adapter.
4. Add deterministic evaluation, scope checks, scoring, and result JSON.
5. Add repeated-run orchestration, comparison statistics, and reports.
6. Add fixtures, automated tests, portability validation, and CI.
7. Complete documentation, examples, security review, and release preparation.

Each workstream uses a focused Issue and branch, includes tests or documentary checks, opens a PR with evidence, receives review, resolves reproducible findings, and merges only after its gates pass.

## Dependency Order

```text
CDD/contracts
  -> CLI/parser
  -> workspace/adapter
  -> evaluator/scoring/schema
  -> orchestration/comparison/reporting
  -> full QA/docs/release
```

Independent documentation and fixture work may proceed once its contract dependency is merged.

## Release Sequence

1. Run local syntax, ShellCheck when installed, unit, integration, and end-to-end gates.
2. Confirm CI on `main`.
3. Reproduce the quick start from a clean temporary repository.
4. Audit result schema, generated report, install path, security guidance, and changelog.
5. Confirm Issues and PRs reflect completion.
6. Tag and publish `v0.1.0` with evidence-backed release notes.
