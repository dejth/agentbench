# Result Format v1

Each run writes `.agentbench/results/<setup>/<run-id>/result.json`. The normative schema is [`schemas/result.schema.json`](../schemas/result.schema.json).

Top-level fields include:

- `schema_version`, `run_id`, `status`, `score`, and `pass_threshold`
- Benchmark/setup identifiers and content hashes
- Starting commit, lockfile hash when available, and workspace identifier
- Redacted agent command/output, exit, timeout, duration, and unavailable provider metrics
- Environment fingerprint
- Category score breakdown
- Validation evidence
- Required-file checks
- Changed files and tracked Git diff summary
- Scope violations and critical failures

JSON `null` means unavailable. It never means zero.

Evidence files under the run directory include redacted command output, validation output, changed-file lists, and a tracked binary-capable Git patch. Results remain local and may contain sensitive project information.

Setup run indexes and comparison JSON use schema version `1` but are separate contracts from the individual result schema.
