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

  assert_output "Hello, world!" "$("$main_sh")" "default greeting"
  assert_output "Hi there, world!" "$("$main_sh" --greeting 'Hi there')" "custom greeting"
  assert_output "Howdy, world!" "$("$main_sh" --greeting 'Howdy')" "single-word greeting"

  exit "$failed"
}

main "$@"
