#!/usr/bin/env bash
set -euo pipefail

main() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local main_sh="${script_dir}/main.sh"

  local failed=0

  assert_output() {
    local expected="$1"
    local actual="$2"
    local label="$3"
    if [[ "$actual" == "$expected" ]]; then
      echo "ok - $label"
    else
      echo "not ok - $label: expected '$expected', got '$actual'"
      failed=1
    fi
  }

  assert_exit_nonzero() {
    local label="$1"
    shift
    set +e
    "$@" >/dev/null 2>&1
    local rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
      echo "ok - $label"
    else
      echo "not ok - $label: expected non-zero exit"
      failed=1
    fi
  }

  assert_stderr_contains() {
    local needle="$1"
    local label="$2"
    shift 2
    local stderr_file
    stderr_file="$(mktemp)"
    set +e
    "$@" 2>"$stderr_file" >/dev/null
    set -e
    local stderr_actual
    stderr_actual="$(<"$stderr_file")"
    rm -f "$stderr_file"
    if [[ "$stderr_actual" == *"$needle"* ]]; then
      echo "ok - $label"
    else
      echo "not ok - $label: expected stderr to contain '$needle', got '$stderr_actual'"
      failed=1
    fi
  }

  assert_stdout_empty() {
    local label="$1"
    shift
    local stdout_file
    stdout_file="$(mktemp)"
    set +e
    "$@" >"$stdout_file" 2>/dev/null
    set -e
    local stdout_actual
    stdout_actual="$(<"$stdout_file")"
    rm -f "$stdout_file"
    if [[ -z "$stdout_actual" ]]; then
      echo "ok - $label"
    else
      echo "not ok - $label: expected no stdout, got '$stdout_actual'"
      failed=1
    fi
  }

  assert_output "Hello, world!" "$("$main_sh")" "default greeting"
  assert_output "Hi there, world!" "$("$main_sh" --greeting 'Hi there')" "custom greeting"
  assert_output "Howdy, world!" "$("$main_sh" --greeting 'Howdy')" "single-word greeting"

  assert_exit_nonzero "unknown flag exits non-zero" "$main_sh" --unknown
  assert_stderr_contains "unknown option" "unknown flag errors to stderr" "$main_sh" --unknown
  assert_stdout_empty "unknown flag produces no stdout" "$main_sh" --unknown

  assert_exit_nonzero "missing --greeting value exits non-zero" "$main_sh" --greeting
  assert_stderr_contains "requires a value" "missing --greeting value errors to stderr" "$main_sh" --greeting
  assert_stdout_empty "missing --greeting value produces no stdout" "$main_sh" --greeting

  assert_exit_nonzero "positional arg exits non-zero" "$main_sh" extra
  assert_stderr_contains "unexpected argument" "positional arg errors to stderr" "$main_sh" extra
  assert_stdout_empty "positional arg produces no stdout" "$main_sh" extra

  exit "$failed"
}

main "$@"
