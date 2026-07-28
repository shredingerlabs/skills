# tests/afkLoop

A tiny test project used to exercise the AFK Loop agent driver.

It is intentionally trivial: a single bash script that prints a greeting,
plus a bash test script. The point is not the program but the loop —
T-K01 through T-K04 each touch this directory in turn, letting the
agent prove it can clone, edit, test, and commit under a real driver.

## Contents

- `main.sh` — prints `Hello, world!` by default; accepts `--greeting <text>`.
- `test.sh` — twelve plain-bash assertions covering the default greeting,
  custom greetings, and the three error paths (unknown flag, missing
  `--greeting` value, unexpected positional argument).

## Setup

Requires `bash` (tested on bash 5). No other dependencies.

The scripts are executable; if yours are not:

```sh
chmod +x main.sh test.sh
```

## Usage

Run the program:

```sh
./main.sh                 # prints: Hello, world!
./main.sh --greeting Hi   # prints: Hi, world!
```

Run the test suite. The script uses the tap-ish `ok` / `not ok` format
and exits non-zero if any assertion fails:

```sh
./test.sh
```

All twelve assertions should print `ok -` and the script should exit 0.
