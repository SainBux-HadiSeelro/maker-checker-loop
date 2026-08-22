# Maker-Checker Bugfix LoopA demo of one of loop engineering's most important ideas: **the agentthat writes the fix must never be the agent that approves it.**

## What it does
- `calc.py` + `test_calc.py` — a small buggy function (`divide`) with  failing tests as the starting point.
- `.opencode/skills/fix-bug/SKILL.md` — the procedure an implementer  agent follows: read the failing test, fix only the source file,  never touch the tests, no hardcoded fixes.
- `.opencode/agent/reviewer.md` — a separate, read-only reviewer  subagent. It cannot edit code — its only job is to grade the fix  and reply **PASS** or **FAIL** with specific reasons.
- `run_bugfix_loop.sh` — orchestrates one full run: creates an  isolated git worktree for the fix, invokes the implementer, then  invokes the reviewer. Merges to `main` only on PASS.

## Why this matters
This is Concept 11 of loop engineering (maker-checker / LLM-as-judge):a model grading its own work tends to approve it too easily. Aseparate checker, with different instructions (and often a different,cheaper model), catches what the maker missed.

## Proof included
Two test runs are baked into this repo's history:
- `./run_bugfix_loop.sh good` — a real, general fix. Reviewer replies  **PASS**, and the branch merges to `main`.
- `./run_bugfix_loop.sh bad` — a deliberately hardcoded, fake fix  (passes the test suite by cheating, not by actually fixing the bug).  Reviewer replies **FAIL**, explains why (hardcoded, not general,  still fails on other inputs), and nothing merges.
If the reviewer ever passes the bad fix, the checker is too soft —a checker that approves everything is no checker at all.

## Run it
```bash
./run_bugfix_loop.sh good
./run_bugfix_loop.sh bad
```
Compare `main`'s git log against the untouched `fix-bad` branch to seethe difference.