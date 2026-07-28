#!/usr/bin/env bash
set -euo pipefail

greeting="Hello"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --greeting)
      if [[ $# -lt 2 ]]; then
        echo "error: --greeting requires a value" >&2
        exit 1
      fi
      greeting="$2"
      shift 2
      ;;
    --)
      shift
      ;;
    --*)
      echo "error: unknown option: $1" >&2
      exit 1
      ;;
    *)
      echo "error: unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

main() {
  echo "${greeting}, world!"
}

main "$@"
