## Why

After the local library is stable, users will need a convenient way to find and install compatible cartridges without manually copying URLs. Workshop must remain an optional network layer over the verified installation pipeline.

## What Changes

- Add a separate Workshop screen with catalog browsing, search, game details, and explicit installation.
- Download a small versioned manifest over HTTPS and do not execute content before full download and current WASM validation.
- Show progress, size, source, network errors, and already-installed state.
- Cache metadata only; do not delete local games when a catalog entry disappears.
- When network access or HTTPS is unavailable, show a clear unavailable state and keep the local library fully functional.

## Capabilities

### New Capabilities

- `workshop-catalog`: remote catalog, search, game details, and installation through the existing transactional pipeline.

### Modified Capabilities

- None.

## Impact

This affects new MIDP UI, the network loader, manifest parser, `CartridgeStore`, and MIDlet permissions. The change depends on a stable local installation flow but does not replace it.
