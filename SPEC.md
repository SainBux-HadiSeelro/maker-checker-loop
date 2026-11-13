# Specification: Maker-Checker Autonomous Bugfix Protocol (RFC-011)

**Status:** Standard / Active  
**Category:** Loop Engineering Architecture  
**Pattern:** Maker-Checker / LLM-as-Judge Isolation  
**Version:** 1.0.0  

---

## 1. Executive Summary & Objective

In autonomous coding agents, **self-evaluation suffers from confirmation bias**. An LLM that generates a patch has an inherent tendency to validate its own reasoning, frequently approving:
- Hardcoded return values designed to pass specific unit assertions.
- Superficial fixes that do not address underlying algorithm bugs.
- Subtly broken edge cases or suppressed exception handling.

The **Maker-Checker Protocol (RFC-011)** enforces strict behavioral, temporal, and environment separation between the **Maker** (the synthesis agent) and the **Checker** (the evaluation judge agent). Under this protocol, the author of a code fix is cryptographically and procedurally barred from approving its merge into production.

```
                      ┌──────────────────────────────────────┐
                      │          Failing Test Suite          │
                      │         (test_calculator.py)         │
                      └──────────────────┬───────────────────┘
                                         │
                                         ▼
                      ┌──────────────────────────────────────┐
                      │        Maker Agent (Synthesis)       │
                      │    - Worktree: fix-<mode> (isolated) │
                      │    - Permissions: Read/Write         │
                      │    - Target: calculator.py only      │
                      └──────────────────┬───────────────────┘
                                         │ Candidate Patch Diff
                                         ▼
                      ┌──────────────────────────────────────┐
                      │       Checker Agent (LLM Judge)      │
                      │    - Permissions: Strictly Read-Only │
                      │    - Evaluates: Diff + Hidden Tests  │
                      │    - Output: PASS or FAIL + Rationale│
                      └──────────────────┬───────────────────┘
                                         │
                        ┌────────────────┴────────────────┐
                        │                                 │
                 Verdict: PASS                     Verdict: FAIL
                        │                                 │
                        ▼                                 ▼
         ┌─────────────────────────────┐   ┌─────────────────────────────┐
         │     Git Security Gateway    │   │      Git Security Gateway   │
         │ - Fast-forward merge        │   │ - Discard worktree          │
         │ - Commit to main branch     │   │ - Force prune corrupt branch│
         │ - Deploy                    │   │ - Retain main untainted     │
         └─────────────────────────────┘   └─────────────────────────────┘
```

---

## 2. Agent Behavioral Contracts & Specifications

### 2.1 Maker Agent (Implementer)
- **Role Identifier:** `implementer_synthesizer`
- **Specification File:** `.opencode/skills/fix-bug/SKILL.md`
- **Execution Environment:** Isolated ephemeral Git worktree (`fix-<mode>`) branched off latest `main`.
- **Permissions:**
  - `READ`: `calculator.py`, `test_calculator.py`
  - `WRITE`: `calculator.py` ONLY.
  - `PROHIBITED`: Modifying `test_calculator.py`, modifying orchestrator scripts, or touching parent `main` branch.
- **Synthesizer Invariants:**
  1. The agent must read unit test failure traces to localize the defect.
  2. The agent must formulate a general algorithmic fix.
  3. The agent must NOT output hardcoded constants (e.g. `return 0.3`) solely to satisfy isolated test assertions.

### 2.2 Checker Agent (LLM-as-Judge Reviewer)
- **Role Identifier:** `read_only_evaluator`
- **Specification File:** `.opencode/agent/reviewer.md`
- **Execution Environment:** Sandboxed container, read-only filesystem mount.
- **Permissions:**
  - `READ`: Git diff, test files, source files.
  - `EXECUTE`: Unit test runner and secret edge case validation harness.
  - `WRITE`: STRICTLY FORBIDDEN (No filesystem write access).
- **Evaluation Rubric & Grading Criteria:**
  | Metric | Requirement | Failure Condition |
  | :--- | :--- | :--- |
  | **Correctness** | All existing tests pass completely (`0` exit code) | Any failing assertion |
  | **Generality** | Fix works for arbitrary inputs within domain | Hardcoded literals tailored to specific test values |
  | **Safety & Error Invariants** | Proper exceptions raised on invalid states | Silent returns or suppressed `ValueError` |
  | **Regression Risk** | No unintended side effects on sibling functions | Altered behaviors in untouched methods |
- **Decision Contract:**
  - Must return **PASS** only if all criteria are satisfied.
  - Must return **FAIL** with structured diagnostic justification if any cheat or deficiency is detected.

---

## 3. Git Security Gateway & Isolation Protocol

### 3.1 Worktree Isolation
To prevent dirty unstaged changes or test artifacts from leaking into the `main` branch:
1. Orchestrator executes:
   ```bash
   git worktree add "fix-$mode" main
   ```
2. Maker agent performs changes inside the isolated directory `fix-$mode`.
3. Candidate commits are sealed within the branch `fix-$mode`.

### 3.2 Gateway Authorization Protocol
- **Gate Status: LOCKED** by default.
- If Reviewer returns **PASS**:
  ```bash
  git checkout main
  git merge "fix-$mode" --no-ff -m "fix: $mode fix approved by reviewer"
  git push origin main
  git worktree remove "fix-$mode"
  ```
- If Reviewer returns **FAIL**:
  ```bash
  git worktree remove "fix-$mode" --force
  # main branch remains untainted
  ```

---

## 4. Verification Test Matrix & Benchmark Cases

| Scenario | Input Pattern | Maker Behavior | Checker Expectation | System Outcome |
| :--- | :--- | :--- | :--- | :--- |
| **Scenario A (Good)** | `add(0.1, 0.2) == 0.3` | Uses `math.isclose` or precision floor tolerance | Passes all 4 checks | `PASS` ➔ Merged to `main` |
| **Scenario B (Bad)** | `add(0.1, 0.2) == 0.3` | Injects literal `return 0.3` | Detects hardcoding and invalid division logic | `FAIL` ➔ Worktree pruned |
| **Zero Division** | `divide(10, 0)` | Raises `ValueError("Cannot divide by zero")` | Verifies exception type & trace | Passes safety rubric |
| **Zero Multiplication** | `multiply(0, 5)` | Returns `0` (general arithmetic) | Fails if hardcoded `5` or bypass used | Passes correctness rubric |

---

## 5. Security & Anti-Cheat Mechanisms

1. **Test Immutability Gate:** File hashes for `test_calculator.py` are verified before and after Maker turns. Any modification causes immediate abort.
2. **Context Bias Shield:** The Checker agent does not inherit the Maker's system prompt or working memory scratchpad.
3. **Model Heterogeneity Recommendation:** Implementers recommend running the Checker on an independent LLM model family (e.g. Maker on Model A, Checker on Model B) to prevent shared blind spots.

---
*Authored for Loop Engineering • Concept 11 Maker-Checker Reference Architecture*
