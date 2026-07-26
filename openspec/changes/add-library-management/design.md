## Context

`LibraryCanvas` shows bundled and installed cartridges but provides only `Install .wasm` and `Exit`. Installations live in `w4lib1`, disk stores are named by fingerprint as `w4d<hash>`, and W4IR stores as `w4i11<hash>`. There are no public cartridge-scoped delete or size APIs yet, so the UI must not delete RMS stores using an unchecked string or broad prefix scan.

## Goals / Non-Goals

**Goals:** delete an installed binary; clear disk and W4IR independently; show usage; confirm exact scope; recover from partial deletion.

**Non-Goals:** deleting bundled resources, clearing all data with one action, multi-select, or managing a session-only save state.

## Decisions

### 1. Open management for stable cartridge identity

The screen receives the title, source kind, and fingerprint calculated by the same algorithm as the storage backends. Bundled and installed entries use one identity; `recordId` is used only to remove the installed payload.

### 2. Every backend provides scoped operations

`CartridgeStore.delete(recordId)` removes the manifest and chunks through a deleting state hidden from `list()`, and recovery completes the operation after interruption. Disk and W4IR provide `inspect(fingerprint)`/`clear(fingerprint)`; the UI neither constructs nor enumerates unrelated store names.

### 3. Destructive actions are independent

The menu contains `Delete installed cartridge`, `Clear game disk`, and `Clear W4IR cache`. Every confirmation names the cartridge and exact data kind. Deleting the binary does not automatically clear disk or cache, protecting data across reinstallation.

### 4. Usage may be Unknown

For an open store, use `getSize()` and `getSizeAvailable()` where the MIDP implementation returns reliable values. The UI shows per-kind bytes and a total available estimate or `Unknown`; unavailable data is distinct from a read error.

## Risks / Trade-offs

- [MIDP deletion is interrupted] → retain a deleting manifest and recover on the next open.
- [Hash collision] → compare length, CRC, and full identity metadata where available before a destructive action; do not delete when ambiguous.
- [The cache is open in the runtime] → management is available only outside an active run of the selected cartridge or requires complete teardown.
- [No free-space API] → show Unknown instead of calculating a false value.

## Migration Plan

Add a read-only inspection API, then scoped clearing, and only then UI confirmations. Existing store formats remain readable; after rollback, recovery must safely remove or hide new deleting records.

## Open Questions

- Whether this uses a dedicated detail screen or a compact context menu will be determined by testing on the minimum display; the action contract does not depend on presentation.
