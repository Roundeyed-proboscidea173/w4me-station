## Why

During play, the only available action is an immediate exit to the library, which stops the runtime. A unified system screen is needed so users can safely pause, continue, and invoke other runtime functions.

## What Changes

- Add an in-game system menu with a true pause at a frame boundary.
- Define `Continue`, `Save State`, `Load State`, `Settings`, `Restart Cart`, and `Library` in the base menu model.
- Do not pass keys used for menu interaction to the cartridge.
- Show brief success and failure messages after the menu closes.
- Make the menu an extensible entry point for separate save-state, settings, disk-options, and netplay change packages.

## Capabilities

### New Capabilities

- `in-game-system-menu`: runtime pause, system-menu navigation, and safe Continue/Restart/Library transitions.

### Modified Capabilities

- None.

## Impact

This affects the `W4Canvas` frame loop and lifecycle, `W4MeMidlet` transitions, key/touch handling, rendering over the last frame, and `Wasm4Apu` control. The implementation must remain compatible with Java 1.3, CLDC 1.1, and MIDP 2.0.
