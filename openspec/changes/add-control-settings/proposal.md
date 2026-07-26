## Why

Hard-coded keys do not suit every phone or emulator. Users need to see the current layout, remap game actions, and restore safe defaults.

## What Changes

- Add a screen for configuring directions, WASM-4 `BUTTON_1`, `BUTTON_2`, and the system-menu shortcut.
- Add a mode that captures the next physical key, supports cancellation, and clearly reports binding conflicts.
- Allow the entire layout to be reset to defaults.
- Persist the layout globally in RMS and apply it to the next frame without restarting the cartridge.
- Do not change on-screen touch-gamepad semantics; its layout is defined by a separate change package.

## Capabilities

### New Capabilities

- `control-settings`: viewing, remapping, conflict checking, and persistence for hardware keys.

### Modified Capabilities

- None.

## Impact

This affects `W4Canvas` input, the settings screen reached from the system menu, and a small versioned RMS settings store. The implementation must not depend on vendor-specific key codes without retaining functional MIDP game-action fallbacks.
