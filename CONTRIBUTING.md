# Contributing to AgentBench

Thank you for helping make AI development workflows measurable.

## Workflow

1. Open or select a focused GitHub Issue.
2. Confirm relevant contracts under `.context/` and `docs/`.
3. Create a focused branch.
4. Change modular files under `src/`, `adapters/`, templates, tests, or docs.
5. Run `./scripts/build-standalone.sh` after shell-module or template changes.
6. Add isolated tests that use temporary Git repositories.
7. Run the quality gates below.
8. Open a Pull Request linked to the Issue with evidence, risks, and limitations.
9. Resolve every reproducible critical or high-impact review finding.

## Quality Gates

```bash
./scripts/build-standalone.sh
git diff --exit-code -- agentbench.sh
bash -n agentbench.sh src/*.sh adapters/*.sh scripts/*.sh tests/*.sh tests/fixtures/*.sh
shellcheck agentbench.sh src/*.sh adapters/*.sh scripts/*.sh tests/*.sh tests/fixtures/*.sh
./tests/run.sh
git diff --check
```

CI runs the same gates on Ubuntu and macOS and validates the result schema.

## Shell Guidelines

- Preserve macOS Bash 3.2 compatibility.
- Use strict mode and quote paths.
- Avoid Bash 4-only associative arrays.
- Use `mktemp` and marker-validated cleanup.
- Do not reset or clean a user's original checkout.
- Keep provider-specific behavior behind adapters.
- Record unavailable metrics as `null`; never estimate them.

## Commit Style

Use concise Conventional Commit messages and include the Issue number when practical, for example:

```text
feat: add comparison report (#123)
```
