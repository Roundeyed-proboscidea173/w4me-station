## Why

Users need manual save/load from the system menu following the official web runtime model. The first version needs only one state for the current game session, without slots or a separate save manager.

## What Changes

- Add separate `Save State` and `Load State` actions to the system menu.
- Keep exactly one snapshot for the active cartridge session; another Save atomically replaces it.
- Restore state only at a frame boundary and clear the input that triggered the action.
- Show `State saved`, `State loaded`, or `Need to save a state first`.
- Treat the snapshot as temporary state for the current session: exiting to the library, closing the MIDlet, or restarting the cartridge removes it.
- Do not add slots, autosaves, previews, import/export, or restore after restart; those are separate future extensions.

## Capabilities

### New Capabilities

- `single-save-state`: one replaceable runtime snapshot and Save/Load menu actions.

### Modified Capabilities

- None.

## Impact

This affects `W4Canvas`, `WasmModule`, `WasmInterpreter`, `Wasm4Runtime`, APU state, and integration with `in-game-system-menu`. It requires a memory-bounded snapshot format suitable for CLDC 1.1 without Java serialization.
