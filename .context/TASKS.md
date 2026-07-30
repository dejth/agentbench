# Task Register

Status: active

| Task | Scope | Depends on | State |
|---|---|---|---|
| T-001 | CDD foundation and quality gates | none | in progress (Issue #1) |
| T-002 | CLI, init, and Markdown parser | T-001 | planned |
| T-003 | Git worktree isolation and custom adapter | T-001, T-002 | planned |
| T-004 | Validation, scope checks, scoring, and result schema | T-002, T-003 | planned |
| T-005 | Repeated runs, comparison, and reporters | T-004 | planned |
| T-006 | Automated tests, fixtures, and CI | T-002 through T-005 | planned |
| T-007 | Examples, user documentation, and security | T-002 through T-005 | planned |
| T-008 | Release readiness and v0.1.0 | T-006, T-007 | planned |

## Task Rules

- One GitHub Issue is the source of truth for each task.
- Every implementation branch names its Issue.
- Pull Requests include acceptance criteria, validation evidence, risks, and CDD impact.
- Reproducible critical or high-impact review findings block merge.
- `.context/STATUS.md` changes whenever delivered capability or material risk changes.
