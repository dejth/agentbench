# Getting Started

## 1. Choose a Project and Revision

Use an existing Git repository with at least one commit. AgentBench resolves `HEAD` by default, or accepts `--revision REF`. Dirty changes in the original checkout are not copied into run worktrees.

## 2. Install and Initialize

```bash
curl -fsSL https://raw.githubusercontent.com/dejth/agentbench/main/agentbench.sh -o agentbench.sh
chmod +x agentbench.sh
./agentbench.sh init
```

`init` keeps existing files and creates baseline/candidate setup directories. Generated results, reports, and temporary workspaces are ignored by `.agentbench/.gitignore`; benchmark and setup definitions remain commit-ready.

## 3. Define the Experiment

Edit `.agentbench/BENCHMARK.md`. Keep the task, validation, inputs, revision, permissions, timeout, and run count constant. Change one primary setup variable in each `CONTEXT.md`.

Validate before running:

```bash
./agentbench.sh validate
```

## 4. Configure an Agent Command

The command runs from an isolated worktree and receives the assembled task and setup prompt on standard input. Examples:

```bash
--agent-command "codex exec"
--agent-command "claude -p"
--agent-command "./scripts/my-agent.sh"
```

Confirm the chosen command's non-interactive input contract. AgentBench does not add provider flags automatically.

## 5. Run and Compare

```bash
./agentbench.sh run --setup baseline --agent-command "codex exec" --runs 5 --timeout 900
./agentbench.sh run --setup candidate --agent-command "codex exec" --runs 5 --timeout 900
./agentbench.sh compare baseline candidate
```

Failed benchmark runs make `run` return non-zero without discarding evidence. If a shell script must continue to comparison, handle that outcome explicitly.

## 6. Inspect Evidence

- `.agentbench/results/<setup>/<run-id>/result.json`: individual result
- `.agentbench/results/<setup>/<run-id>/evidence/`: redacted output and Git evidence
- `.agentbench/results/<setup>/runs.json`: latest setup experiment
- `.agentbench/reports/<comparison-id>/comparison.json`: raw comparison
- `.agentbench/reports/<comparison-id>/BENCHMARK.md`: human-readable report

Use `./agentbench.sh report <comparison-id>` to print a stored Markdown report.

## CI Example

Because failed benchmark runs return non-zero, decide whether a run is a gate or evidence collection:

```bash
./agentbench.sh run --setup candidate --agent-command "./ci-agent.sh" --runs 3 --timeout 600
```

Commit benchmark/setup definitions, but do not commit generated results unless your project intentionally versions benchmark evidence.
