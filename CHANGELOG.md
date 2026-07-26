# Changelog

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
