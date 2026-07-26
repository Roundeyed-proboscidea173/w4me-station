## Context

`W4Canvas` currently combines MIDP game actions with fixed `5/X` bindings for WASM-4 button 1 and `0/Z` bindings for button 2. Directions are read through `GameCanvas.getKeyStates()`. Devices differ in raw key codes, soft keys, and key names, so mappings cannot be transferred between phones as universal numeric values.

## Goals / Non-Goals

**Goals:** a visible and editable global layout; safe key capture; a guaranteed way back to the menu; immediate application.

**Non-Goals:** touch layout, multiplayer bindings for players 2–4, macros, key combinations, or vendor-specific presets without evidence from a verified device.

## Decisions

### 1. Persist logical action to binding lists

Actions are Up, Down, Left, Right, Button 1, Button 2, and System Menu. A binding stores a raw key code and, for portable directions and Fire, an optional MIDP game action. Input processing checks the raw override first and then the standard game-action fallback.

### 2. Settings are versioned and global

One small RMS record contains a magic value, version, payload length, and checksum. An unknown or corrupted version does not block startup: defaults are applied and a diagnosable fallback is shown.

### 3. Capture has a safe exit

The screen shows `Press a key` and accepts only the next `keyPressed`; `Back` or a timeout cancels capture. System Menu cannot be left without a binding. If the new key is already assigned, the UI offers to move it from the previous action or cancel; it never creates a hidden duplicate.

### 4. Apply changes atomically between frames

After saving, the immutable mapping object is replaced through a single reference assignment. Active pressed bits are cleared so that the old layout cannot leave an action stuck down.

## Risks / Trade-offs

- [A vendor returns the same key code for different soft keys] → show the numeric code and require confirmation before saving an ambiguous mapping.
- [The user remaps a menu navigation key] → protect the System Menu binding and expose reset to defaults through a soft command.
- [RMS is unavailable] → apply changes until the MIDlet closes and clearly report that they were not saved.

## Migration Plan

First introduce defaults equivalent to current behavior, then add the Settings UI and RMS persistence. Deleting the store restores defaults without affecting cartridge or disk data.

## Open Questions

- Model-specific presets may be added only after evidence from real devices and are outside this change.
