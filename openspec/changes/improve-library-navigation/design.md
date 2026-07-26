## Context

Before this change, the library was a hand-drawn Canvas with `selected` and
`firstVisible` indices, custom painting, key handling, and pointer hit testing.
Installed records have a `recordId`, but favorites and history need an identity
that survives reinstallation and does not conflict with bundled indices.
Metadata must remain small and must not block startup when corrupted.

## Goals / Non-Goals

**Goals:** All/Favorites/Recent views; title search; stable focus; bounded metadata.

**Non-Goals:** cloud sync, ratings, remote tags, folders, or changing the order of primary storage.

## Decisions

### 0. Use an implicit LCDUI List

The primary library screen is an implicit `javax.microedition.lcdui.List`.
LCDUI owns painting, focus, scrolling, keypad mapping, touch selection, and the
select action. Project code owns only the entry snapshot and Install, Sound
settings, and Exit commands. RMS availability is reported through a standard
Ticker.

### 1. Base identity on the cartridge fingerprint

The metadata key contains hash + length + CRC; the bundled resource path is used as additional diagnostic information, not as the sole identity. Reinstalling identical bytes inherits favorite and recent state.

### 2. Build views from a list snapshot

After `reloadInstalled()`, create an array of lightweight entries and apply the view and search filter to it. The LCDUI List displays the filtered array, but opening an item resolves the original entry by identity rather than by a stale index.

### 3. Recent is a bounded MRU

A successful transition to a running cartridge moves its identity to the front. History is limited to 16 entries; unavailable cartridges are not shown, but their metadata may be retained for reinstallation.

### 4. Persist focus by identity

On return, the library attempts to restore the view, search query, selected identity, and first visible row. If the entry disappeared, the nearest visible item is selected; an empty view has a separate state without modulo-by-zero.

### 5. Search is local and incremental

The query is matched against titles case-insensitively. Search opens a `TextBox` and then returns the result to the LCDUI library List.

## Risks / Trade-offs

- [Fingerprint collision] → use a composite identity and do not merge ambiguous entries.
- [Metadata grows] → fixed limits, a compact binary record, and rewrite of one transactional record.
- [An empty filter breaks navigation] → a dedicated empty-state path and Back/Clear Search commands.
- [KEmulator headless automation cannot inject navigation into a high-level LCDUI List] → verify the LCDUI model and commands through `observe`, keep cartridge oracle scenarios independent through test-only direct-launch MIDlets, and retain a real-device navigation smoke test.

## Migration Plan

The metadata store is created lazily. Deleting it restores the All view without affecting binaries or disks. Implement identity and focus first, followed by Favorites/Recent and search.

## Open Questions

- The MRU limit may be reduced after RMS measurements but SHALL remain explicitly bounded.
