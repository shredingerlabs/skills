---
name: hardware-in-loop
description: Use when the user works with a hardware rig — ESP32 (MicroPython), oscilloscope, Picoscope, or any bench setup connected to the host. Forces the agent to announce the rig, get user confirmation, and verify the MCU's file state before any flash, upload, or test. Trigger on: flashing, probing, scope, GPIO, rig, or bench setup.
---

# Hardware in the Loop

The **rig** is the live hardware on the bench: MCU(s), scope, probes, wiring, voltages. Code that compiles is not code that runs, and code that runs is not code that runs on the right pins with the right wiring. This skill makes the rig visible before anything touches it.

## The loop

Before any flash, upload, or test that targets the rig — and after any change to the rig — run all three steps in order.

### 1. Announce the rig

State the current setup, fully, as a fenced block. The user can't see your rig.

```
ESP32-DevKitC (MicroPython v1.23.0)
  USB:      /dev/ttyACM0
  3V3 rail: on, measured 3.31 V
  GPIO map: GPIO25 -> LED; GPIO26 -> scope CH A
  Entry:    main.py (auto-boot)
  Files:    main.py, driver.py, config.json
Picoscope PS2204A
  USB:      lsusb -d 0ce9:1007 -> bus 7, dev 088
  CH A:     x10 probe on GPIO26, 1 V/div, DC
  CH B:     off
  AWG:      off
Ground:    ESP32.GND shared with scope.GND
```

Be exact: GPIO numbers, voltage rails, scope channel and V/div, ground reference. Vague rig = wrong test.

### 2. Confirm with the user

Ask: **"Has the rig changed since the last confirmation?"**

- First run, or user says yes → wait for them to walk through the new state. Don't assume.
- User says no → the previous confirmation stands. Note that in the announcement ("unchanged from previous confirmation").

The agent never runs the rig after a change without confirmation. A probe moved to the wrong pin is a debugging session nobody wants.

### 3. Verify the rig's file state

For each programmed device on the rig, confirm what's actually on it matches what you think is on it.

- **MCU reachable** — `mpremote connect <port> exec "import sys; print(sys.implementation.version)"` returns a MicroPython version. No response = board is wedged or wrong port.
- **MicroPython firmware** — version on the device matches the expected one for this project. If it doesn't, flash with esptool before continuing.
- **Application files** — `mpremote connect <port> fs ls` shows the expected `main.py`, modules, and data files. `mpremote fs cat :main.py` shows the expected source. A stale file (old copy from a prior run) is a silent test failure.
- **Scope reachable** — `lsusb -d 0ce9:1007` shows the device, and the project's `picoscope.md` health check opens the unit.

If anything is stale, stop. Don't run a test against a device that doesn't have the code you think it does. Re-flash firmware, re-upload files, then continue.

For the scope specifically, **read `picoscope.md` (project root) before the first scope call** — it documents the library + sample-limit gotchas that bite silently (wrong `.so`, `run_block` returning 0, 3968-sample cap, broken python binding).

## After the run

Note any rig change in the session record — GPIO map updated, probe moved, scope channel swapped. Next run's confirmation has something concrete to compare against.

## Reference

- `picoscope.md` (project root) — Picoscope 2204A specifics: lib, block-mode cap, ctypes example, health check, pitfalls. Read it before any scope call.
- [rig-reference.md](rig-reference.md) — port enumeration, MicroPython upload / REPL workflow, ESP32 voltage / pin limits, esptool firmware flash.
