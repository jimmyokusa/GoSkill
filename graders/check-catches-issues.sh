#!/bin/bash
# Deterministic grader for the "catches-issues" eval task.
# Expects review-output.txt at the workspace root containing the
# go-reviewer subagent's findings against the fixture's feature branch,
# which has an unchecked-error (errcheck) violation and no test for the
# new function.

total=3
passed=0

file_pass=false file_msg="review-output.txt missing"
lint_pass=false lint_msg="did not flag the unchecked os.WriteFile error"
test_pass=false test_msg="did not flag the missing test for Set"

if [ -s review-output.txt ]; then
  passed=$((passed + 1)); file_pass=true; file_msg="review-output.txt present and non-empty"

  if grep -Eqi "errcheck|WriteFile|not checked|unchecked" review-output.txt; then
    passed=$((passed + 1)); lint_pass=true; lint_msg="flagged the unchecked os.WriteFile error"
  fi

  if grep -Eqi "test" review-output.txt; then
    passed=$((passed + 1)); test_pass=true; test_msg="flagged missing test coverage"
  fi
fi

score=$(awk "BEGIN {printf \"%.2f\", $passed/$total}")

cat <<EOF
{"score":$score,"details":"$passed/$total checks passed","checks":[{"name":"output-file","passed":$file_pass,"message":"$file_msg"},{"name":"lint-finding","passed":$lint_pass,"message":"$lint_msg"},{"name":"test-coverage-finding","passed":$test_pass,"message":"$test_msg"}]}
EOF
