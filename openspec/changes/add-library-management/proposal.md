## Why

The library can install and launch cartridges but cannot free RMS space or remove data for a specific game. Safe maintenance actions are needed with an exact explanation of what will be deleted.

## What Changes

- Add a management menu for the selected cartridge and a summary of its RMS data.
- Allow deletion of an installed cartridge binary; bundled cartridges cannot be deleted.
- Add independent clearing of WASM-4 disk data and W4IR cache for the selected cartridge.
- Show available and used RMS as accurately as the MIDP implementation allows.
- Before every destructive action, show a confirmation naming the cartridge and data type.
- After an error, do not hide the cartridge or claim successful cleanup.

## Capabilities

### New Capabilities

- `library-management`: cartridge-binary, disk-data, and W4IR-cache management and RMS usage display.

### Modified Capabilities

- None.

## Impact

This affects `LibraryCanvas`, `CartridgeStore`, `DiskBackends`, `RmsDiskBackend`, `RmsW4IrStore`, and the MIDP confirmation/alert flow. Deletions must be cartridge-scoped and must not affect unrelated RMS stores.
