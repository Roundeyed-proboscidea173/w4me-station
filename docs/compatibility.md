# Compatibility

W4ME Station runs unmodified WASM-4 cartridges through a WebAssembly
interpreter on CLDC 1.1 / MIDP 2.0. Compatibility is verified against exact
framebuffer, input, disk, and audio oracles where available.

## Runtime

The runtime currently provides:

- fixed 64 KiB linear memory and the WASM-4 memory-mapped registers;
- structured control flow, multi-value block signatures, tables, indirect
  calls, `i32`, `i64`, `f32`, and `f64`;
- numeric conversions, saturating conversions, bulk memory operations, and
  passive data segments;
- `blit`, `blitSub`, primitives, text, palette changes, mouse input, and two
  gamepads;
- `tone`, a four-channel logical APU, sampled MMAPI output, one-player
  streamed MIDI compatibility output, `playTone` fallback, and silent
  fallback;
- the 1 KiB cartridge disk backed by checksummed RMS generations;
- validation before execution and a fixed-width W4IR cache stored in RMS;
- isolated loader failures and runtime traps that return to the library.

The implementation intentionally targets Java 1.3 language and classfile
compatibility. Production code must not depend on desktop-only Java APIs.

## Bundled cartridges

Both release JARs contain the same thirteen cartridges, packaged under
`cartridges/` inside the JAR. The library presents them in this order:

| # | Cartridge | Primary coverage |
| --- | --- | --- |
| 1 | Sokoban | turn-based puzzle; the frame changes only on a button press |
| 2 | Wasm Wars | turn-based strategy and `SYSTEM_PRESERVE_FRAMEBUFFER` |
| 3 | Annoying Robots | board game against a CPU opponent |
| 4 | Waternet | input, palette, audio, and disk lifecycle |
| 5 | Dragon Poker Draw | card game, static frame between actions |
| 6 | Tic Tac Toe | two players on one gamepad |
| 7 | Watris | real-time falling-block game |
| 8 | Glowfish Chess | board game, two players on one gamepad, static frame |
| 9 | Duck Maze | gamepad input and multi-frame state |
| 10 | Rubido | mixed pointer/gamepad input, palette, audio, and disk writes |
| 11 | Untangle | pointer dragging, rotated/flipped blits, disk, `f64`, and tables |
| 12 | Sound Demo | basic tone playback |
| 13 | Plasma Cube | floating-point computation and sustained rendering |

The order is a user-visible contract pinned by the KEmulator launcher scenario.
The first entries are the cartridges whose per-frame cost is low enough that the
handset limitation is not visible; pointer-driven cartridges sit below
keypad-driven ones, and the service and technical demos come last. Plasma Cube
is by far the most expensive cartridge of the set and stays at the end.

Mandelbrot, Sound Test, Tankle, and Game of Life: Zig Edition remain in
`cartridges/` as regression and benchmark fixtures but are not packaged in the
release JARs.

Glowfish Chess sits below the cartridges above it because its `VS CPU` mode does
not work within the per-frame budget described in the next section, and is not
expected to. The cartridge runs a complete alpha-beta search with an unbounded
quiescence search inside a single `update()` call. Measured over a scripted game,
six of ten engine turns exceeded the budget and aborted the cartridge, the first
search after leaving the opening book among them; the turns that completed cost
83 to 87 percent of the budget, which is minutes of frozen screen on a handset.
Treat `VS CPU` as unavailable.

`VS Player` never reaches the engine — the search is behind a
`mode == VsEngine` check — and stays at roughly 15,000 instructions per frame
for a whole game, so hot-seat chess for two players on one handset works
normally. That is why the cartridge is still bundled.

The per-turn figures are recorded in
[performance documentation](performance.md) as a standing interpreter
optimization target.

## Per-frame instruction budget

Every `update()` call is capped at 150,000,000 executed WebAssembly
instructions. A cartridge that exceeds it is stopped with a trap and the library
returns, rather than leaving the handset frozen with no way out.

This cap is a W4ME decision, not part of WASM-4; a browser runtime has no such
limit and would merely stutter. It matters because WASM-4 assumes `update()`
returns promptly at 60 Hz, so a cartridge is free to compute a whole engine move
or a whole generated level inside one frame. That is inexpensive on a native or
JIT host and unreachable on an interpreter: 150,000,000 instructions is on the
order of minutes of wall time on a handset, so a cartridge that needs them would
be unusable even if it were allowed to finish.

Cartridges that do bounded per-frame work are unaffected; the release catalog
sits between roughly 500 and 40,000 instructions per frame in normal play.

The files are unchanged upstream works and have their own licenses. See
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

## Loading external cartridges

Additional cartridges can be installed from HTTP(S), entered as a `file://`
URL, or selected through JSR-75 FileConnection when the device provides that
optional API. Installed cartridges are validated and copied into RMS, so the
original file or network connection is not needed for later launches.

The base JAR omits the JSR-75 adapter and remains usable on MIDP 2.0 devices
without FileConnection.

## Controls

| Input | Player 1 | Player 2 |
| --- | --- | --- |
| Movement | Arrow or directional phone keys | `E`, `S`, `D`, `F` |
| Button 1 | `X`, Fire, or `5` | `Tab` |
| Button 2 | `Z` or `0` | `Q` |

Touchscreen devices display an on-screen gamepad outside the 160×160
framebuffer whenever the screen provides enough space.

## Known limitations

- Performance depends heavily on the handset VM. Computationally expensive
  cartridges may not reach interactive frame rates on physical devices.
- Sampled MMAPI behavior and latency vary between phone implementations.
- Automatic audio uses sampled WAV Players only when MMAPI reports both WAV
  and mixing support, then falls back through a data-backed `audio/midi`
  Player, `Manager.playTone`, and silence as each tier proves unavailable.
- `Compatible` mode in `Sound settings` bypasses sampled Players and renders
  active WASM-4 channels into one Standard MIDI File Player. This avoids both
  concurrent-Player mixing and optional `device://midi` implementations that
  silently discard interactive events. MIDI preserves polyphony and timing but
  only approximates WASM-4 pulse, triangle, and noise waveforms.
- `Sound settings` provides Automatic/Compatible mode, a global hard mute and,
  when the active backend supports it, master volume from 0 through 100.
  Confirmed values are restored from RMS before a cartridge can submit its
  first tone. A mode change made during a game is used after reopening the
  cartridge.
- WebAssembly threads, SIMD, reference types beyond the supported table model,
  multiple memories, and memory growth are not supported.
- The current disk UI provides the cartridge's WASM-4 disk API; user-facing
  save-state slots are not implemented.
- Bluetooth play, workshop browsing, and the remaining menu work remain tracked
  in OpenSpec and are not part of the current release.

Exact regression fixtures live under `testdata/oracles/`. Generated logs,
screenshots, and benchmark receipts are local build output under
`build/reports/`.
