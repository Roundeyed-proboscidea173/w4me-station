## 1. Audio control

- [x] 1.1 Add backend volume capability reporting and a silence operation with fallback semantics
- [x] 1.2 Implement master gain scaling in `Wasm4Apu` without changing other packed tone fields
- [x] 1.3 Separate persistent mute/gain from temporary system-menu suspension

## 2. Settings UI

- [x] 2.1 Add capability-aware Sound On/Off and volume controls
- [x] 2.2 Persist the setting in versioned settings RMS and apply it before the first tone
- [x] 2.3 Indicate session-only application after an RMS failure

## 3. Verification

- [x] 3.1 Add unit tests for gain boundaries, rounding, mute, resume, and unchanged parameters at gain 100
- [x] 3.2 Add KEmulator flows for active-tone mute, persisted mute, and backend capability fallback
- [x] 3.3 Run `just test`, `just build`, `tools/kemu/run.sh verify sound`, and `tools/kemu/run.sh verify sound-test`
- [x] 3.4 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized

## 4. Device-feedback fixes

- [x] 4.1 Initialize the volume Gauge from the persisted 0-100 gain after adding it to the Form
- [x] 4.2 Move the Automatic/Compatible selector into Audio Settings and remove the separate library command
- [x] 4.3 Verify the initial 100 percent value, mode persistence, release build, and KEmulator settings flow
