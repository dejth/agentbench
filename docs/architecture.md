# Architecture

The repository keeps modular source for development and generates one downloadable `agentbench.sh` for users.

```text
CLI
 -> Markdown parser
 -> Git worktree manager
 -> custom command adapter
 -> deterministic evaluator
 -> scoring
 -> result JSON
 -> repeated-run index
 -> comparison
 -> terminal / Markdown / JSON reporters
```

Run evidence is created before the worktree is removed. Reports derive from stored JSON and execution-time snapshots rather than current benchmark/setup files.

See [`.context/ARCHITECTURE.md`](../.context/ARCHITECTURE.md) and [`.context/DECISIONS.md`](../.context/DECISIONS.md) for component and decision records.
