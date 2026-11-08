#!/usr/bin/env bash
# tests/run.sh - Regression tests for script wrappers (no credentials, no real PRs)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

assert_exit() {
  local label="$1"
  local expected="$2"
  shift 2
  set +e
  "$@" >/tmp/tf-test-out.txt 2>/tmp/tf-test-err.txt
  local code=$?
  set -e
  if [ "$code" -eq "$expected" ]; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label (expected exit $expected, got $code)" >&2
    echo "----- stdout -----" >&2
    cat /tmp/tf-test-out.txt >&2 || true
    echo "----- stderr -----" >&2
    cat /tmp/tf-test-err.txt >&2 || true
    FAIL=$((FAIL + 1))
  fi
}

assert_grep_err() {
  local label="$1"
  local pattern="$2"
  if grep -Eq "$pattern" /tmp/tf-test-err.txt; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label (stderr missing /$pattern/)" >&2
    cat /tmp/tf-test-err.txt >&2 || true
    FAIL=$((FAIL + 1))
  fi
}

run_in_repo() {
  local repo="$1"
  shift
  (cd "$repo" && "$@")
}

TMP_REPO=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_REPO"
  rm -f /tmp/tf-test-out.txt /tmp/tf-test-err.txt /tmp/tf-pr-body.md
}
trap cleanup EXIT

# --- issue-get: missing id ---
assert_exit "issue-get missing id" 1 "$ROOT/scripts/issue-get.sh"
assert_grep_err "issue-get missing id message" "No Ticket ID"

# --- issue-get: unconfigured ---
assert_exit "issue-get unconfigured" 2 "$ROOT/scripts/issue-get.sh" "PROJ-1"
assert_grep_err "issue-get unconfigured message" "not configured"

# --- notify-chat: missing channel ---
assert_exit "notify-chat missing channel" 1 "$ROOT/scripts/notify-chat.sh" "https://example.com/pr/1" "PROJ-1"
assert_grep_err "notify-chat channel message" "CHANNEL is required"

# --- notify-chat: unconfigured (must not claim sent) ---
assert_exit "notify-chat unconfigured" 2 "$ROOT/scripts/notify-chat.sh" "https://example.com/pr/1" "PROJ-1" "#dev"
assert_grep_err "notify-chat not sent" "not configured"
if grep -Eqi 'notification sent' /tmp/tf-test-out.txt /tmp/tf-test-err.txt; then
  echo "FAIL: notify-chat claimed sent while unconfigured" >&2
  FAIL=$((FAIL + 1))
else
  echo "PASS: notify-chat did not claim sent"
  PASS=$((PASS + 1))
fi

# --- git fixtures ---
git -C "$TMP_REPO" init -q -b main
git -C "$TMP_REPO" config user.email "test@example.com"
git -C "$TMP_REPO" config user.name "Test"
echo "hi" > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm "init"

# --- git-commit: empty message ---
assert_exit "git-commit empty message" 1 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-commit.sh" ""

# --- git-commit: protected branch ---
assert_exit "git-commit on main refused" 1 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-commit.sh" "PROJ-1: should fail"

# --- git-commit: no staged changes on feature branch ---
git -C "$TMP_REPO" checkout -q -b feature/PROJ-1
assert_exit "git-commit no staged" 1 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-commit.sh" "PROJ-1: should fail"
assert_grep_err "git-commit no staged message" "No staged changes"

# --- git-commit: sensitive path ---
echo "SECRET=1" > "$TMP_REPO/.env"
git -C "$TMP_REPO" add .env
assert_exit "git-commit sensitive .env" 1 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-commit.sh" "PROJ-1: should fail"
assert_grep_err "git-commit sensitive message" "sensitive"
git -C "$TMP_REPO" reset -q HEAD

# --- git-branch: dirty tree ---
echo "dirty" > "$TMP_REPO/WIP.md"
assert_exit "git-branch dirty tree" 1 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-branch.sh" "PROJ-2" "bug"
assert_grep_err "git-branch dirty message" "dirty"
rm -f "$TMP_REPO/WIP.md"

# --- git-pr: missing title/body ---
assert_exit "git-pr missing args" 1 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-pr.sh"
assert_grep_err "git-pr missing title" "title is required"

# --- git-pr: incomplete title ---
cat > /tmp/tf-pr-body.md <<'EOF'
## Summary
Fix timeout.

## Impact Area
- **App:** payments
- **Surfaces:** checkout API
- **Components / APIs:** charge()
- **Regression Risk:** low — narrow retry change
- **Tests:** tests/charge.test.ts

## Test plan
- [x] unit tests
EOF
assert_exit "git-pr incomplete title" 1 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-pr.sh" --title "PROJ-1: " --body-file /tmp/tf-pr-body.md --dry-run
assert_grep_err "git-pr incomplete title message" "incomplete|too short|Provide a short"

# --- git-pr: blank Impact Area ---
cat > /tmp/tf-pr-body.md <<'EOF'
## Summary
Something

## Impact Area
- **App:**
- **Surfaces:**
- **Components / APIs:**
- **Regression Risk:**
- **Tests:**

## Test plan
- [ ] tests
EOF
assert_exit "git-pr blank impact area" 1 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-pr.sh" --title "PROJ-1: real summary" --body-file /tmp/tf-pr-body.md --dry-run
assert_grep_err "git-pr blank fields message" "incomplete"

# --- git-pr: dry-run success (no PR created) ---
cat > /tmp/tf-pr-body.md <<'EOF'
## Summary
Fix timeout.

## Impact Area
- **App:** payments
- **Surfaces:** checkout API
- **Components / APIs:** charge()
- **Regression Risk:** low — narrow retry change
- **Tests:** tests/charge.test.ts

## Test plan
- [x] unit tests
EOF
assert_exit "git-pr dry-run ok" 0 \
  run_in_repo "$TMP_REPO" bash "$ROOT/scripts/git-pr.sh" \
    --title "PROJ-1: fix checkout timeout" \
    --body-file /tmp/tf-pr-body.md \
    --base main \
    --dry-run
if grep -Eqi 'no PR created|Dry-run OK' /tmp/tf-test-out.txt; then
  echo "PASS: git-pr dry-run stated no PR created"
  PASS=$((PASS + 1))
else
  echo "FAIL: git-pr dry-run output unclear" >&2
  cat /tmp/tf-test-out.txt >&2
  FAIL=$((FAIL + 1))
fi

echo
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
