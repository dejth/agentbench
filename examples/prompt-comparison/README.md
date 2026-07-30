# Reproducible Prompt Comparison

Copy this directory outside the AgentBench repository so it becomes its own Git project:

```bash
example_dir="$(mktemp -d)/prompt-comparison"
cp -R examples/prompt-comparison "$example_dir"
cp agentbench.sh "$example_dir/agentbench.sh"
cd "$example_dir"
git init
git add .
git commit -m "example fixture"

./agentbench.sh run --setup baseline --agent-command "./fake-agent.sh" --runs 3 --timeout 10 || true
./agentbench.sh run --setup candidate --agent-command "./fake-agent.sh" --runs 3 --timeout 10
./agentbench.sh compare baseline candidate
```

The fake agent follows the setup instruction embedded in its prompt. The benchmark deterministically expects `candidate`, so baseline fails and candidate passes.
