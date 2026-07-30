# AgentBench

> Test your AI context like you test your code.

[![test](https://github.com/dejth/agentbench/actions/workflows/test.yml/badge.svg)](https://github.com/dejth/agentbench/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

AgentBench is a local-first shell runner for comparing prompts, project context, `AGENTS.md`, CDD, skills, models, providers, harnesses, and agent workflows against real tasks from your own Git project.

AI agents are non-deterministic. AgentBench does not try to change that. It starts every run from the same commit, applies deterministic checks, repeats the experiment, and produces inspectable evidence.

> Stop guessing whether your prompt works. Benchmark it.

> Non-deterministic agents. Deterministic checks. Repeated evidence.

## What v0.1.0 Measures

- Required validation command results
- Required-file presence
- Allowed-scope compliance
- Git changed files and tracked diff summaries
- Deterministic scores and critical failures
- Pass rate, median/minimum/maximum score, and score spread
- Duration and changed-file counts
- Token usage, cost, attempts, tool calls, and human intervention only when available; v0.1.0 reports them as unavailable

Semantic code quality is intentionally outside the deterministic v0.1.0 score.

## Requirements

- Git
- Bash 3.2 or newer
- `jq`
- Standard macOS or Linux command-line tools
- A custom agent command that reads its prompt from standard input and edits its current directory

## Install

Download the standalone runner into an existing Git project:

```bash
curl -fsSL https://raw.githubusercontent.com/dejth/agentbench/main/agentbench.sh \
  -o agentbench.sh
chmod +x agentbench.sh
```

For a pinned release, use `install.sh` or replace `main` with `v0.1.0` in the URL:

```bash
curl -fsSL https://raw.githubusercontent.com/dejth/agentbench/main/install.sh | bash
```

The downloaded `agentbench.sh` is standalone. It does not require this repository's `src/` or `templates/` directories.

## Quick Start

Run inside the project you want to benchmark:

```bash
./agentbench.sh init
```

Edit:

```text
.agentbench/
├── BENCHMARK.md
├── cases/
├── setups/
│   ├── baseline/
│   │   ├── CONTEXT.md
│   │   └── SETUP.md
│   └── candidate/
│       ├── CONTEXT.md
│       └── SETUP.md
├── results/
└── reports/
```

Validate the benchmark:

```bash
./agentbench.sh validate
```

Run both setups from the same Git revision:

```bash
./agentbench.sh run \
  --setup baseline \
  --agent-command "codex exec" \
  --runs 5 \
  --timeout 900

./agentbench.sh run \
  --setup candidate \
  --agent-command "codex exec" \
  --runs 5 \
  --timeout 900
```

Compare the latest experiment for each setup:

```bash
./agentbench.sh compare baseline candidate
```

AgentBench writes individual JSON results under `.agentbench/results/` and a comparison under `.agentbench/reports/<comparison-id>/`.

## CLI

```text
agentbench.sh help
agentbench.sh version
agentbench.sh init
agentbench.sh validate [--benchmark PATH]
agentbench.sh run --setup ID --agent-command COMMAND [--runs N] [--timeout SECONDS] [--revision REF]
agentbench.sh compare BASELINE CANDIDATE
agentbench.sh report COMPARISON_ID
agentbench.sh clean
```

`run` returns non-zero when one or more completed benchmark runs fail, while preserving every result. Runner/configuration errors also return non-zero. `compare` returns zero when a valid report is generated; it does not declare a winner beyond measured evidence.

## How It Works

```text
Benchmark + setup context
  -> resolve one Git commit
  -> isolated detached worktree per run
  -> custom agent command
  -> timeout-bounded deterministic validation
  -> required-file and allowed-scope checks
  -> versioned result JSON
  -> repeated-run statistics
  -> terminal + Markdown + JSON comparison
```

The original checkout is never reset, cleaned, or switched. Only marker-owned AgentBench worktrees can be removed by `clean`.

## Documentation

- [Getting started](docs/getting-started.md)
- [Benchmark format v1](docs/benchmark-format.md)
- [Scoring](docs/scoring.md)
- [Comparison methodology](docs/comparison-methodology.md)
- [Custom agent adapter](docs/agent-adapters.md)
- [Result format v1](docs/result-format.md)
- [Architecture](docs/architecture.md)
- [Security model](docs/security.md)
- [Reproducible examples](examples/README.md)

## Development

The repository uses Markdown-first Context-Driven Development under [`.context/`](.context/PRODUCT.md). Edit modular source files, then regenerate the standalone runner:

```bash
./scripts/build-standalone.sh
bash -n agentbench.sh src/*.sh adapters/*.sh scripts/*.sh tests/*.sh tests/fixtures/*.sh
shellcheck agentbench.sh src/*.sh adapters/*.sh scripts/*.sh tests/*.sh tests/fixtures/*.sh
./tests/run.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the Issue and Pull Request workflow.

## Security and Privacy

AgentBench itself does not transmit project data or telemetry. Your configured agent command may use a network or external service. Commands execute arbitrary shell code inside an isolated worktree and should be reviewed before use. See [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © 2026 Theeradej Thisthasa
