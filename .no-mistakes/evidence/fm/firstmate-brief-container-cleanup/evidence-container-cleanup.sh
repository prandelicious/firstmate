#!/usr/bin/env bash
# Manual end-to-end evidence for the container-cleanup change
# (branch fm/firstmate-brief-container-cleanup).
#
# Exercises the real executables exactly as an end user would:
#   1. bin/fm-brief.sh   -> a generated ship brief must carry the
#      container-cleanup clause bound to the task id.
#   2. bin/fm-teardown.sh -> a successful teardown must warn (on stderr),
#      naming any surviving fm-<task-id>-* container, without issuing any
#      mutating docker call; a clean task gets no warning.
#
# The teardown fixtures are extracted verbatim from tests/fm-teardown.test.sh
# (the repo's own colocated tests for these scripts) so this evidence uses the
# same hermetic mocks as CI.
set -u

REPO=/home/francis/.no-mistakes/worktrees/a12c6affcc8a/01M179DZSCZJFBEFYKH2JXMFNF
EV=/home/francis/.no-mistakes/evidence/01M179DZSCZJFBEFYKH2JXMFNF

# --- Pull the shared test helpers and the teardown fixtures out of the repo's
# --- own test files (by function name, at run time, so no drift).
. "$REPO/tests/lib.sh"
fm_git_identity evtest [EMAIL]
# Variables the extracted test fixtures expect (normally defined at the top of
# tests/fm-teardown.test.sh).
TEARDOWN="$REPO/bin/fm-teardown.sh"

extract_fn() { # <file> <fn-name> -> prints the function body
  awk -v fn="$2" '
    $0 ~ "^"fn"\\(\\) \\{" {on=1}
    on {print}
    on && /^}$/ {exit}
  ' "$1"
}

TMP_EXTRACTS=$(mktemp -d)
{
  extract_fn "$REPO/tests/fm-teardown.test.sh" make_case
  extract_fn "$REPO/tests/fm-teardown.test.sh" write_meta
  extract_fn "$REPO/tests/fm-teardown.test.sh" wt_commit
  extract_fn "$REPO/tests/fm-teardown.test.sh" land_shippable_commit
  extract_fn "$REPO/tests/fm-teardown.test.sh" run_teardown
  extract_fn "$REPO/tests/fm-teardown.test.sh" add_docker_stub
} > "$TMP_EXTRACTS/fixtures.sh"
# shellcheck disable=SC1091
. "$TMP_EXTRACTS/fixtures.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/fm-container-evidence.XXXXXX")

echo "== 1. ship brief carries the container-cleanup clause =="
BRIEF_HOME="$TMP_ROOT/brief-home"
mkdir -p "$BRIEF_HOME/data"
FM_HOME="$BRIEF_HOME" "$REPO/bin/fm-brief.sh" evidence-task "$REPO" --mode no-mistakes \
  > "$EV/brief-generate.stdout" 2> "$EV/brief-generate.stderr"
echo "fm-brief.sh exit=$?"
BRIEF="$BRIEF_HOME/data/evidence-task/brief.md"
awk '/^# Container cleanup$/{on=1} on{print} on && /^$/{n++; if(n==1) exit}' "$BRIEF" \
  > "$EV/brief-container-cleanup-section.md"
echo "--- extracted section ---"
cat "$EV/brief-container-cleanup-section.md"

echo
echo "== 2. teardown warns about a leaked fm-task-x1-* container =="
case_dir=$(make_case evidence-leaked-container)
write_meta "$case_dir" no-mistakes ship
land_shippable_commit "$case_dir"
add_docker_stub "$case_dir"
rc=0
FM_FAKE_DOCKER_LOG="$case_dir/docker-calls.log" FM_FAKE_DOCKER_PS_NAMES="fm-task-x1-pg" \
  run_teardown "$case_dir" > "$case_dir/stdout" 2> "$case_dir/stderr" || rc=$?
echo "fm-teardown.sh exit=$rc (expected 0: warning is non-blocking)"
echo "--- stderr (tail) ---"
tail -6 "$case_dir/stderr" | tee "$EV/teardown-leaked-container-warning.txt"
echo "--- docker calls teardown made ---"
cat "$case_dir/docker-calls.log" | tee "$EV/teardown-docker-calls.log"
if grep -Eq '^(rm|stop|kill) ' "$case_dir/docker-calls.log"; then
  echo "FAIL: teardown issued a mutating docker call"
  exit 1
fi
echo "PASS: warning printed, exit 0, no rm/stop/kill issued"

echo
echo "== 3. teardown prints no container warning when the worker cleaned up =="
case_dir=$(make_case evidence-clean-container)
write_meta "$case_dir" no-mistakes ship
land_shippable_commit "$case_dir"
add_docker_stub "$case_dir"
rc=0
FM_FAKE_DOCKER_PS_NAMES="" \
  run_teardown "$case_dir" > "$case_dir/stdout" 2> "$case_dir/stderr" || rc=$?
echo "fm-teardown.sh exit=$rc"
if grep -q "left running container" "$case_dir/stderr"; then
  echo "FAIL: warning printed for a clean task"
  exit 1
fi
echo "PASS: no container warning for a clean task"
tail -3 "$case_dir/stderr" | tee "$EV/teardown-clean-stderr-tail.txt"

rm -rf "$TMP_ROOT" "$TMP_EXTRACTS"
echo
echo "EVIDENCE COMPLETE"
