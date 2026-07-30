# Comparison Methodology

AI output varies, so preserve individual runs and compare distributions rather than one favorable result.

Recommended sample sizes:

- Development smoke check: 3 runs
- Normal comparison: 5 runs
- Higher-confidence comparison: 10 or more runs

AgentBench enforces matching benchmark content hash, starting commit, timeout, and run count. Users must also hold permissions, runtime dependencies, test data, and other external conditions constant.

Change one primary experimental variable at a time. Examples include prompt wording, `AGENTS.md`, CDD, a skill, model, provider, harness, or workflow.

## Reported Metrics

- Pass rate
- Median, minimum, maximum, and spread of scores
- Runs containing critical failures
- Total scope violations
- Median duration
- Median changed-file count
- Median category scores

First-pass success, tokens, cost, attempts, tool calls, and human intervention are `null` in v0.1.0 because the custom adapter cannot confirm them. AgentBench never estimates unavailable provider data.

Use median as the primary central tendency. Treat findings as evidence for this project, task, setup, and sample—not universal or causal claims.
