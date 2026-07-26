## Why

As the game collection grows, a linear list becomes inconvenient. Users need quick access to recently launched cartridges, favorites, and search without changing the cartridge format.

## What Changes

- Add `All`, `Favorites`, and `Recent` views.
- Add search over locally available titles with a clear no-results state.
- Allow a cartridge to be added to or removed from favorites without launching it.
- Persist favorites and bounded launch history in RMS using stable cartridge identity.
- Preserve the selected item and scroll position when returning from a game or child screen.
- Replace the hand-drawn launcher Canvas with a native LCDUI List.

## Capabilities

### New Capabilities

- `library-navigation`: All/Favorites/Recent filters, search, and list-position persistence.

### Modified Capabilities

- None.

## Impact

This affects the LCDUI library screen, launch events in `W4MeMidlet`, installed and bundled cartridge identity, and RMS metadata. The feature requires no network access and does not change cartridge storage.
