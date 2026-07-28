# Rig Reference

General rig info that doesn't live in `picoscope.md` (scope specifics there).

## Port enumeration (Linux)

```bash
ls -l /dev/ttyAMA* /dev/ttyACM* /dev/ttyUSB* 2>/dev/null
lsusb
udevadm info -n /dev/ttyACM0 | grep -E "ID_VENDOR|ID_MODEL|ID_SERIAL"
```

MicroPython-capable boards show up on:

- `/dev/ttyACM*` — ESP32-S2 / S3 with native USB, or ESP32-C3. **Most common for MicroPython.**
- `/dev/ttyUSB*` — ESP32 (classic) with a USB-serial bridge (CP210x, CH340). The bridge presents as a different VID/PID than the native-USB boards.
- `/dev/ttyAMA*` — Raspberry Pi GPIO UART. **Not a USB connection** — only seen when an ESP32 is wired to the Pi header.

Port indices are not stable across replug. Always re-check `ls -l /dev/ttyACM* /dev/ttyUSB*` before connecting; do not hardcode a port that worked last session.

If multiple boards are plugged in, identify by serial: `mpremote connect list` shows the port-to-board mapping. Pin the port to a board by its USB serial (in `idf.py` / `mpremote` config) if you have more than one on the bench.

## MicroPython workflow (`mpremote`)

`mpremote` is the official CLI; use it for everything except the one-time firmware flash.

```bash
mpremote connect /dev/ttyACM0                                # enter REPL
mpremote connect /dev/ttyACM0 exec "import sys; print(sys.implementation)"
mpremote connect /dev/ttyACM0 reset                          # soft reset, runs boot.py + main.py
mpremote connect /dev/ttyACM0 fs ls                          # list files on device FS
mpremote connect /dev/ttyACM0 fs cat :main.py                # read a file from the device
mpremote connect /dev/ttyACM0 fs cp ./src/main.py :main.py   # upload a file
mpremote connect /dev/ttyACM0 fs rm :stale_module.py         # delete a file
mpremote connect /dev/ttyACM0 fs mkdir :data                 # create a directory
mpremote connect /dev/ttyACM0 run ./scratch.py               # upload + run a script (no FS write)
```

The `:` prefix on a path means "device side". Without it, mpremote treats the path as host-side. Mixing them up silently uploads the wrong direction.

`mpremote` (no args) connects to the only board if exactly one is plugged in — but **don't rely on this** in a multi-board rig. Always pass `--port` / `connect <port>` explicitly.

### REPL discipline

- The REPL is single-threaded; a hung main.py blocks the REPL. If `mpremote exec` times out, the board is probably running a tight loop. `Ctrl-C` over the serial line interrupts Python; `Ctrl-D` does a soft reset.
- `mpremote` on a hung board may need a hard reset (EN button or power cycle). After a hard reset, re-verify the file state — power-cycling doesn't touch the FS, but you should still confirm.

## One-time firmware flash (esptool)

`mpremote` does not flash the MicroPython firmware itself. Use `esptool.py` for that, once per board (or when upgrading MicroPython).

```bash
esptool.py --port /dev/ttyACM0 --chip esp32 erase_flash
esptool.py --port /dev/ttyACM0 --chip esp32 write_flash -z 0x1000 \
  ~/Downloads/ESP32_GENERIC-20240602-v1.23.0.bin
```

- Always `erase_flash` first when changing firmware version or board variant — leaving old NVS / partition data can wedge the new firmware.
- Pin the firmware version in the project (e.g. `firmware/esp32-v1.23.0.bin` checked in or downloaded to a known path). Don't assume the host has the right `.bin` from `~/Downloads`.
- The port during a flash is **not** the same port the MicroPython REPL will appear on. After the flash, the board may re-enumerate on a different `/dev/ttyACM*` index.

## ESP32 voltage and pin limits

These are silicon-level, framework-independent. MicroPython doesn't change them.

- **Logic level: 3.3 V.** GPIO pins are **NOT 5 V-tolerant.** Driving 5 V into an ESP32 GPIO can damage the silicon.
- **ADC: 3.3 V reference by default.** `machine.ADC` returns raw counts; divide by the attenuation's full-scale to get volts. `ADC.atten(ADC.ATTN_11DB)` gives the full ~3.3 V range; below that, use `ATTN_6DB` / `ATTN_2_5DB` / `ATTN_0DB` for finer resolution on smaller signals.
- **Strapping pins:** GPIO0, GPIO2, GPIO15, GPIO5. Avoid for application signals unless the boot-time implications are understood.
- **Input-only pins:** GPIO34, GPIO35, GPIO36, GPIO39. No internal pull-up / pull-down, no output drive — use only as inputs.

## Pin change checklist (the common "I moved a wire" loop)

When the GPIO map changes mid-session:

1. Update the rig announcement.
2. Stop any in-flight test — the previous wiring is now wrong.
3. Get explicit user confirmation of the new map before re-running.
4. If main.py references the changed pins, re-upload the file with `mpremote fs cp` and reset the board.
