# Deterministic Quality Gates

Status: active

## Per-Change Gates

```bash
git diff --check
./scripts/build-standalone.sh
git diff --exit-code -- agentbench.sh
bash -n agentbench.sh
bash -n src/*.sh
bash -n adapters/*.sh
```

When ShellCheck is installed:

```bash
shellcheck agentbench.sh install.sh src/*.sh adapters/*.sh scripts/*.sh tests/*.sh tests/fixtures/*.sh examples/prompt-comparison/fake-agent.sh
```

Run the full test harness:

```bash
./tests/run.sh
```

Validate the JSON schema fixtures:

```bash
./tests/test-schema.sh
```

## Pull Request Gates

- Issue acceptance criteria are demonstrably met.
- All changed shell files pass syntax checks.
- Relevant unit and integration tests pass in isolated temporary repositories.
- No test changes the AgentBench checkout or unrelated user paths.
- Generated JSON validates and comparison calculations match expected fixtures.
- Documentation and CDD match the implemented behavior.
- The diff contains no unrelated files or whitespace errors.
- CI passes on Linux and macOS.
- No unresolved reproducible critical or high-impact review finding remains.

## Release Gates

- All MVP commands pass their end-to-end fixtures.
- Initialization is non-destructive.
- Missing sections, invalid setup, failed commands, timeout, scope violation, and missing required files fail predictably.
- Every run starts at the same resolved commit and cleans its worktree on success, failure, timeout, and interruption.
- Terminal, Markdown, and JSON outputs agree.
- README quick start succeeds in a fresh temporary Git repository.
- `main` is clean and healthy after all delivery PRs merge.
- Changelog and release notes describe only verified functionality.

ShellCheck is a required CI gate. Local absence is reported, never represented as a pass.
