# AgentBench v0.1.0

AgentBench v0.1.0 is the first usable release of a local-first benchmark runner for AI development context.

## Highlights

- Markdown-first benchmark and setup definitions
- Standalone `agentbench.sh`
- Custom provider-agnostic agent commands
- Repeated isolated runs from one Git commit
- Timeout-bounded deterministic evaluation
- Required-file and allowed-scope enforcement
- Deterministic 0–100 scoring with critical-failure overrides
- Baseline-to-candidate statistics
- Terminal, Markdown, and JSON evidence
- macOS and Linux validation

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dejth/agentbench/v0.1.0/agentbench.sh \
  -o agentbench.sh
chmod +x agentbench.sh
./agentbench.sh version
```

## Known Limitations

- Runs execute sequentially.
- The custom adapter expects a prompt on standard input.
- Semantic quality is not scored.
- Provider token, cost, attempt, tool-call, and human-intervention metrics remain unavailable unless a future adapter supplies them.
- Worktrees are not an operating-system sandbox.
