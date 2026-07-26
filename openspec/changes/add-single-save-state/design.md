## Context

The official web runtime keeps one `savedGameState` in the current page's memory: `Save State` replaces it, `Load State` restores it, and `Need to save a state first` is shown before the first save. The state is not a slot and does not survive a page restart. The MIDP port must reproduce this user model while capturing all mutable state supported by its interpreter.

A snapshot may exceed 64 KiB: linear memory is always 64 KiB, with globals, table and data-segment state, logical WASM-4 disk, and APU state added on top. A constrained heap cannot hold multiple full copies at once.

## Goals / Non-Goals

**Goals:**

- one snapshot for the active session;
- atomic Save/Load at a frame boundary;
- continuation with equivalent VM, disk, and audio state;
- clear outcomes and safe behavior on OOM.

**Non-Goals:**

- slots, thumbnails, naming, or a state manager;
- persisting the snapshot in RMS or restoring it after the MIDlet closes;
- import or export of save-state files;
- snapshot compatibility between different cartridges or runtime versions.

## Decisions

### 1. The snapshot lives only in the active `W4Canvas`

`RuntimeSnapshot` is created lazily after the first Save and cleared on Restart, Library, cartridge failure, and destroy. This reproduces the web UX and keeps the runtime snapshot separate from persistent WASM-4 disk storage.

### 2. The worker performs operations at a frame boundary

The menu handler sets `SAVE_REQUESTED` or `LOAD_REQUESTED`. The worker completes the current frame and then copies or restores state before the next `beginFrame`. After Load, gamepad and mouse latches are cleared and one full render occurs without calling `update`.

### 3. The snapshot covers all mutable state

The snapshot contract includes:

- 64 KiB linear memory;
- all runtime globals, including non-exported globals;
- the mutable table and dropped/passive data-segment state when the corresponding instructions are supported;
- logical WASM-4 disk contents and size;
- APU channel and envelope counters and pending tone state;
- runtime flags that affect the next frame.

The call stack is not saved because Save is allowed only between exported `update` calls. W4IR/JIT code and caches are not copied because they are derived from the immutable cartridge.

### 4. Repeated Save uses staging

The new snapshot is filled completely and becomes current only after success. If a second full buffer is unavailable, the implementation MAY reuse one prevalidated buffer with component-by-component copying, but the old state MUST be considered lost only after an explicit successful result. A memory failure leaves the game functional and reports `State save failed`.

### 5. Load validates identity and shape first

The snapshot contains the cartridge fingerprint and mutable-array sizes. A mismatch fails without a partial restore. The snapshot itself is not serialized, so a version field is needed only for internal assertions and tests.

## Risks / Trade-offs

- [The snapshot does not fit in the heap] → lazy allocation, compact arrays, one user snapshot, and an explicit error without stopping the game.
- [A partial restore corrupts the runtime] → validate shape before writing and restore components in a fixed order while paused.
- [The audio backend cannot restore a tone already playing] → restore APU counters and resynthesize only the remaining portion, or document a silent restart on a backend with a capability grade below reference.
- [Disk restore conflicts with persistent RMS] → use an atomic logical-disk replacement API; modify the durable store only after a complete successful Load.

## Migration Plan

1. Add package-private snapshot accessors and VM-state round-trip tests.
2. Add logical-disk and APU capture and restore.
3. Connect one snapshot to the system menu.
4. Verify Save → mutate → Load on cartridges using globals, bulk memory, disk, and tone.

Rollback removes only the temporary snapshot API; the existing RMS disk remains in its previous format.

## Open Questions

- A device-specific memory admission threshold is needed; it will be determined by measurements on target KEmu profiles before any persistent or multi-slot extension.
