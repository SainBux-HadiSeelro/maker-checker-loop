# Maker-Checker Bugfix Loop

A demo of one of loop engineering's most important ideas: **the agent that writes the fix must never be the agent that approves it.**

---

## 🌐 Interactive Frontend / Visualizer

An interactive single-page web visualizer is available in `index.html`. It demonstrates the full Maker-Checker lifecycle visually:

- **Live Flow Stages:** Test Failure ➔ Maker Worktree ➔ Checker LLM Judge ➔ Merge Decision
- **Simulations:** Run `good` (general fix ➔ PASS ➔ merged to `main`) and `bad` (hardcoded cheat ➔ FAIL ➔ blocked & discarded)
- **Code Diff & Terminal Logs:** Real-time bash and git worktree simulation output
- **Interactive Calculator Sandbox:** Test float drift (`0.1 + 0.2`), zero multiplication, and division by zero live

### How to Open:
1. **Directly in Browser:** Double-click or open `index.html` in any web browser.
2. **GitHub Pages:** Enable GitHub Pages on this repository (`Settings` > `Pages` > select `main` branch root `/`) to view it live on the web.

---

## What it does
- `calculator.py` + `test_calculator.py` — buggy functions with failing tests as the starting point.
- `.opencode/skills/fix-bug/SKILL.md` — the procedure an implementer agent follows: read the failing test, fix only the source file, never touch the tests, no hardcoded fixes.
- `.opencode/agent/reviewer.md` — a separate, read-only reviewer subagent. It cannot edit code — its only job is to grade the fix and reply **PASS** or **FAIL** with specific reasons.
- `run_bugfix_loop.sh` — orchestrates one full run: creates an isolated git worktree for the fix, invokes the implementer, then invokes the reviewer. Merges to `main` only on PASS.

## Why this matters
This is Concept 11 of loop engineering (maker-checker / LLM-as-judge): a model grading its own work tends to approve it too easily. A separate checker, with different instructions (and often a different, cheaper model), catches what the maker missed.

## Proof included
Two test runs are baked into this repo's history:
- `./run_bugfix_loop.sh good` — a real, general fix. Reviewer replies **PASS**, and the branch merges to `main`.
- `./run_bugfix_loop.sh bad` — a deliberately hardcoded, fake fix (passes the test suite by cheating, not by actually fixing the bug). Reviewer replies **FAIL**, explains why (hardcoded, not general, still fails on other inputs), and nothing merges.
If the reviewer ever passes the bad fix, the checker is too soft — a checker that approves everything is no checker at all.

## Run it in CLI
```bash
./run_bugfix_loop.sh good
./run_bugfix_loop.sh bad
```
Compare `main`'s git log against the untouched `fix-bad` branch to see the difference.