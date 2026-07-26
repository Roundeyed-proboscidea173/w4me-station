## Why

The current touch gamepad is always drawn over the lower part of the square frame and does not honor `SYSTEM_HIDE_GAMEPAD_OVERLAY`. The game needs a predictable image that can remain unobstructed and user control over on-screen buttons.

## What Changes

- Honor the cartridge's `SYSTEM_HIDE_GAMEPAD_OVERLAY` flag.
- Add `Auto`, `Visible`, and `Hidden` touch-gamepad modes.
- Add `Overlay` and `Game Above Controls` layouts, with the latter reserving a separate area that does not cover the 160x160 image.
- Calculate pointer coordinates strictly relative to the actual game rectangle.
- Persist display/touch settings globally and adapt safely to small screens and orientation changes.

## Capabilities

### New Capabilities

- `display-touch-settings`: touch-gamepad visibility, a non-overlapping layout, and correct scaling and pointer mapping.

### Modified Capabilities

- None.

## Impact

This affects `W4Canvas` rendering, hit testing, and pointer mapping, `SYSTEM_FLAGS` reads, the settings screen, and settings RMS. The pixel framebuffer and its palette remain unchanged.
