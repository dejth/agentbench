# Task Register

Status: active

| Task | Scope | Depends on | State |
|---|---|---|---|
| T-001 | CDD foundation and quality gates | none | complete (Issue #1, PR #2) |
| T-002 | CLI, init, and Markdown parser | T-001 | complete (Issue #5, PR #10) |
| T-003 | Git worktree isolation and custom adapter | T-001, T-002 | complete (Issue #9, PR #11) |
| T-004 | Validation, scope checks, scoring, and result schema | T-002, T-003 | in progress (Issue #7) |
| T-005 | Repeated runs, comparison, and reporters | T-004 | planned (Issue #4) |
| T-006 | Automated tests, fixtures, and CI | T-002 through T-005 | planned (Issue #3) |
| T-007 | Examples, user documentation, and security | T-002 through T-005 | planned (Issue #6) |
| T-008 | Release readiness and v0.1.0 | T-006, T-007 | planned (Issue #8) |

## Task Rules

- One GitHub Issue is the source of truth for each task.
- Every implementation branch names its Issue.
- Pull Requests include acceptance criteria, validation evidence, risks, and CDD impact.
- Reproducible critical or high-impact review findings block merge.
- `.context/STATUS.md` changes whenever delivered capability or material risk changes.
