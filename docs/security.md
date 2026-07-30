# Security Guide

Read [SECURITY.md](../SECURITY.md) before running an unfamiliar agent or benchmark.

Practical guidance:

1. Inspect the agent and validation commands.
2. Use least-privilege credentials and a disposable environment for untrusted commands.
3. Keep secrets out of command arguments and Markdown.
4. Review `.agentbench/results/` before sharing it.
5. Treat stored patches and output as private project data.
6. Use containers or virtual machines when worktree isolation is insufficient.
7. Run `./agentbench.sh clean` only from the intended project; it removes marker-owned AgentBench worktrees and leaves unmanaged directories intact.

AgentBench does not add telemetry or external transmission. The configured agent command may do so according to its own provider and settings.
