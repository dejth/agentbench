# v0.1.0 Release Evidence

Status: release candidate validated; publication pending

Validated commit: `dc7fd9974d7a0a185fdddc88a3ae2f0b5669b3a1`

## Delivery Evidence

- CDD foundation: Issue #1, PR #2
- CLI, initialization, and parser: Issue #5, PR #10
- Worktree isolation and custom adapter: Issue #9, PR #11
- Deterministic evaluator, scoring, and result schema: Issue #7, PR #12
- Repeated runs, comparison, and reports: Issue #4, PR #13
- Comprehensive QA and CI: Issue #3, PR #14
- Standalone packaging, documentation, examples, and security: Issue #6, PR #17

PRs #15 and #16 were closed as superseded delivery attempts after GitHub did not enqueue synchronize checks. PR #17 contains the complete reviewed work and passed explicit release validation.

## Deterministic Gates

- Main CI run `30523746374`: Ubuntu PASS and macOS PASS
- Bash syntax: PASS
- ShellCheck: PASS on Ubuntu and macOS
- Standalone rebuild drift: PASS
- Result schema validation: PASS
- Full automated suite: 15 test files PASS locally and in CI
- Whitespace validation: PASS
- Working tree after validation: clean

## Download Smoke Test

- URL: `https://raw.githubusercontent.com/dejth/agentbench/main/agentbench.sh`
- SHA-256: `265da0ef9313c4caaee38b097435b6b44baf747929e9dd961853cf0fe002f25a`
- Standalone `version`: `AgentBench 0.1.0`
- Standalone `init`: PASS in a fresh temporary Git repository
- Standalone `validate`: PASS in the same repository

## Release Preconditions

- Repository is public, MIT-licensed, and defaults to `main`.
- Active GitHub account and repository admin access were verified.
- All MVP implementation/documentation Issues are closed; release Issue #8 remains open.
- No existing `v0.1.0` tag or GitHub release exists.
- `CHANGELOG.md`, `RELEASE_NOTES.md`, installer, standalone runner, and security policy are present.

## Publication Plan

1. Merge the release-readiness CDD update.
2. Confirm CI passes on the resulting `main` commit.
3. Create tag and GitHub release `v0.1.0` with standalone and installer assets.
4. Verify raw tag download, release assets, installer, and smoke workflow.
5. Update CDD status with published release evidence and close Issue #8 through a final PR.
