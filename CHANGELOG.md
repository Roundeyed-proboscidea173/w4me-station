# Changelog

## 1.0.1 — 2026-07-27

This release improves the universal Java ME runtime without changing the
cartridge format, controls, storage, or installation requirements.

### Performance

- packed horizontal framebuffer spans replace per-pixel Java calls on common
  WASM-4 drawing paths;
- generic integer comparisons and common control-frame operations execute with
  fewer Java helper calls;
- distributable JARs compile diagnostic dispatch counters and opcode profiling
  out of production bytecode;
- sixteen balanced native i686 phoneME pairs per workload measured headless
  frame-time reductions of 35.753% in Waternet, 17.057% in Rubido, 65.151% in
  Untangle, and 10.826% in Game of Life compared with `main@8e85065`; all 64
  pairs favored 1.0.1 and matched exact oracle checkpoints.

These measurements use a CLDC 1.1 C interpreter without a JIT. They exclude
MIDP presentation and audio latency and are not physical-device FPS figures.

### Runtime integrity

- removed the cartridge-fingerprinted Plasma Cube Java replacement so every
  bundled and external cartridge now follows the universal interpreter path;
- expanded exact framebuffer, interpreter, production-bytecode, and
  counterless-build verification;
- reduced the full release JAR from about 275 KB to 270 KB.

Plasma Cube may run slower than in 1.0.0 because it now exercises the actual
universal interpreter instead of a cartridge-specific replacement. It remains
a technical stress workload rather than a representative game.

## 1.0.0 — 2026-07-26

The first public W4ME Station release targets CLDC 1.1 / MIDP 2.0 phones with
Java 1.3-compatible bytecode.

### Included

- WebAssembly interpreter and persistent W4IR cache for unmodified WASM-4
  cartridges;
- native LCDUI library, file picker, sound settings, and in-game system menu;
- thirteen bundled cartridges ordered for keypad usability and handset frame
  cost;
- HTTP(S), URL, RMS, and optional JSR-75 cartridge installation;
- latched gamepad input for slow frames, pointer input, and an on-screen touch
  controller;
- graphics, audio, disk, tracing, and two-gamepad WASM-4 host APIs;
- full and base JAR variants, both below 300 KB; the base variant contains no
  JSR-75 classes or permission declaration;
- deterministic state, framebuffer, audio, storage, KEmulator, and optional
  native no-JIT phoneME verification.

### Known limitations

- Performance depends heavily on the handset VM. Plasma Cube is a technical
  stress workload, not a representative first cartridge.
- Glowfish Chess is practical in its two-player mode; its CPU opponent can
  exceed the per-frame instruction budget on current hardware.
- MMAPI implementations vary. On the tested Nokia E71, short sound effects
  work, but continuous music stutters. `Compatible` audio mode changes the
  backend path but does not guarantee gapless playback.
- Save-state slots, Bluetooth play, and the workshop catalog are not part of
  1.0.0.
- Physical-device coverage is limited and will be documented per handset as
  reports arrive.

Application source is MIT-licensed. Bundled cartridges and the console font
retain the separate licenses recorded in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
