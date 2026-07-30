# Custom Agent Adapter

v0.1.0 accepts a shell command through `--agent-command`.

## Contract

- Current directory: isolated detached Git worktree
- Standard input: assembled benchmark task, instructions, constraints, and setup context
- Standard output/error: captured, best-effort redacted, and stored locally
- Exit status: recorded; non-zero is a critical failure
- Timeout: positive integer seconds; timeout normalizes to exit 124
- Changes: agent edits the current worktree

AgentBench invokes the command with `bash -lc`. Quote the complete command as one shell argument:

```bash
./agentbench.sh run --setup baseline --agent-command "my-agent --non-interactive" --runs 5
```

The adapter records provider/model/version/token/cost fields as `null` because a generic command cannot verify them. Future built-in adapters can populate those fields without changing deterministic evaluation.

Do not place secrets directly in the command. Environment access and network behavior are controlled by the command and host, not AgentBench.
