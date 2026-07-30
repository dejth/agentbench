# Security Policy

## Supported Versions

Security fixes are provided for the latest published release.

## Reporting a Vulnerability

Private vulnerability reporting is not currently enabled for `dejth/agentbench`. Contact the maintainer through a private channel listed on the [`dejth` GitHub profile](https://github.com/dejth) to request a secure reporting channel. Do not open a public Issue containing exploit details, secrets, or private project content.

Include the affected version, operating system, reproduction steps, impact, and any proposed mitigation. You should receive an acknowledgement within seven days.

## Threat Model

AgentBench assumes the local user intentionally selects the project, benchmark, setup context, starting revision, validation commands, and agent command. It does not sandbox arbitrary code from the configured agent or validations.

Primary risks include:

- A malicious or mistaken agent command reading local files or using the network
- Validation commands executing destructive shell operations
- Secrets appearing in command arguments, source changes, or process output
- Symlink and path traversal during cleanup
- Child processes surviving a timeout or interruption
- Results containing private source-derived evidence

## Safety Boundaries

- Every run uses a detached Git worktree from a resolved commit.
- The original checkout is not reset, cleaned, switched, or used as the agent working directory.
- Temporary cleanup requires a canonical path under `.agentbench/tmp/` and an ownership marker.
- Agent and validation timeouts terminate discovered descendant processes.
- Allowed-scope and required-file specifications reject absolute paths and parent traversal.
- Obvious token patterns are redacted from captured standard output, standard error, and recorded commands on a best-effort basis.
- Reports and raw results remain inside the local project.

## Important Limitations

Worktrees are isolation from the original Git checkout, not an operating-system sandbox. Commands can still access paths, credentials, environment variables, networks, and processes permitted to the current user. Best-effort redaction cannot recognize every secret format, and Git diff evidence may contain sensitive source content.

For untrusted agents or benchmarks, use a disposable account, container, virtual machine, restricted network, and least-privilege credentials. Review commands before execution and never place secrets directly in `--agent-command` or Markdown validation blocks.
