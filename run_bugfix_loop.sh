#!/bin/bash
set -e

LOOP_DIR="$(cd "$(dirname "$0")" && pwd)"
CALC="$LOOP_DIR/calculator.py"
TEST="$LOOP_DIR/test_calculator.py"
IMPLEMENTER_SKILL="$LOOP_DIR/.opencode/skills/fix-bug/SKILL.md"
REVIEWER="$LOOP_DIR/.opencode/agent/reviewer.md"

main() {
    local mode="$1"
    if [[ "$mode" != "good" && "$mode" != "bad" ]]; then
        echo "Usage: $0 good|bad"
        exit 1
    fi

    # Initialize git repo if needed
    if [[ ! -d .git ]]; then
        git init
        git config user.email "maker@loop engineering"
        git config user.name "Loop Engineering"
    fi

    # Create worktree for the fix
    git worktree add "fix-$mode" main 2>/dev/null || git worktree add "fix-$mode"

    # Save current state
    git checkout -b "main" 2>/dev/null

    # Implementer fixes the bug in isolation
    bash "$LOOP_DIR/.opencode/run_implementer.sh" "$mode"

    # Reviewer grades the fix
    local result
    result=$(bash "$LOOP_DIR/.opencode/run_reviewer.sh" "$mode")

    echo "Reviewer: $result"

    if [[ "$result" == "PASS" ]]; then
        git checkout main
        git merge "fix-$mode" --no-ff -m "fix: $mode fix approved by reviewer"
        git push
        echo "Merged to main: $mode fix PASS"
    else
        echo "Fix FAILED - not merged to main"
    fi

    # Clean up worktree
    git worktree remove "fix-$mode" 2>/dev/null || true
}

main "$@"