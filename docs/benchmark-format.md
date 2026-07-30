# Benchmark Format v1

AgentBench uses exact level-two Markdown headings for machine-consumed sections. Unknown sections are allowed and ignored by v0.1.0.

## Metadata

Place metadata before the first level-two heading:

```text
Format-Version: 1
Benchmark-ID: authentication-refresh
```

`Format-Version: 1` is required. `Benchmark-ID` should be stable across setup runs.

## Required Sections

```text
## Task
## Instructions
## Allowed Scope
## Required Files
## Validation
## Success Criteria
## Critical Failures
## Scoring
## Pass Conditions
```

Allowed scope and required files are bullet lists. Paths may use Markdown code spans. Absolute paths and `..` traversal are rejected. Use `None` when no required file exists.

Allowed-scope items use shell-style glob matching. For example, `src/**` allows files beneath `src/`.

## Validation

The first fenced `bash` or `sh` block directly under `Validation` is machine-consumed:

````markdown
## Validation

```bash
npm test
npm run typecheck
npm run lint
```
````

Each non-empty, non-comment line is one command. Put a compound command on one line. Commands run sequentially in the post-agent worktree and use the configured timeout independently.

## Scoring and Pass Conditions

The four category headings are required and must total 100 points:

```text
### Correctness — 50 points
### Regression Safety — 20 points
### Instruction Compliance — 20 points
### Efficiency — 10 points
```

Set the threshold with prose matching:

```text
- Total score is at least 70.
```

See [scoring.md](scoring.md) for exact v1 evidence mapping. Start from [`templates/BENCHMARK.md`](../templates/BENCHMARK.md) for a complete definition.
