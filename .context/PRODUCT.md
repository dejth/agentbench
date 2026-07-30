# AgentBench Product Context

Status: approved for v0.1.0 implementation
Last updated: 2026-07-30

## Vision

AgentBench is a local-first benchmark runner for testing AI development context against real project tasks. It lets developers compare prompts, project instructions, CDD, skills, models, providers, harnesses, and workflows using repeated runs and deterministic checks.

Primary tagline:

> Test your AI context like you test your code.

Supporting principles:

> Stop guessing whether your prompt works. Benchmark it.

> Non-deterministic agents. Deterministic checks. Repeated evidence.

> Let AI think. Let the system decide.

> We do not make AI deterministic. We make its behavior measurable.

## Product Model

```text
Real project task
  -> selected AI setup
  -> isolated agent run
  -> deterministic evaluation
  -> repeated evidence
  -> statistical comparison
  -> human-readable report
```

## Users

- Developers and teams maintaining prompts, `AGENTS.md`, CDD, and skills
- Agent framework and harness developers
- Engineering leads and open-source maintainers
- Researchers evaluating agent workflows against real repositories

## v0.1.0 Outcome

A user can add one shell script to a Git repository, initialize `.agentbench/`, define a benchmark and setups in Markdown, execute repeated isolated runs through a custom agent command, evaluate outcomes deterministically, and compare setups through terminal, Markdown, and JSON output.

## Principles

1. Markdown for humans and agents; JSON for machines.
2. Source, prompts, context, skills, and results stay local unless the configured agent command transmits them.
3. Agent execution is provider-agnostic.
4. Commands, checks, scores, failures, and reports are inspectable.
5. Every run starts from the same known Git commit in its own workspace.
6. Conclusions use measured evidence and disclose unavailable metrics.
7. Deterministic checks decide PASS or FAIL; semantic review remains separate.
8. The original project workspace is never reset or mutated by run isolation.

## Out of Scope for v0.1.0

- Built-in provider SDK integrations
- Docker or remote execution
- Semantic or LLM-as-judge scoring
- Hosted dashboards or telemetry
- Automatic cost or token estimation when providers do not report it
- Concurrent benchmark execution
