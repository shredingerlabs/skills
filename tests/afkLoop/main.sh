#!/usr/bin/env bash
set -euo pipefail

greeting="Hello"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --greeting)
      greeting="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

main() {
  echo "${greeting}, world!"
}

main "$@"
