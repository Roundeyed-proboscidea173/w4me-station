## Context

`W4Canvas` currently selects a `min(width,height)` square, centers it across the full Canvas, and then draws touch controls over the bottom 40–64 pixels. Pointer mapping uses the same full square. The runtime already stores `SYSTEM_FLAGS`, but the overlay does not honor `SYSTEM_HIDE_GAMEPAD_OVERLAY` (bit `0x02`).

## Goals / Non-Goals

**Goals:** honor the cartridge flag; provide a user-controlled visibility policy; support a layout that does not cover the game; use one geometry model for rendering, pointer mapping, and touch hit testing.

**Non-Goals:** framebuffer filtering, non-uniform aspect-ratio stretching, touch-control themes, or arbitrary placement of individual buttons.

## Decisions

### 1. Use one immutable `ViewportLayout`

When the Canvas size, settings, or system flag changes, calculate `gameLeft`, `gameTop`, `gameSide`, `controlsTop/Height`, and effective visibility. Rendering, pointer mapping, and touch hit testing use only this object, eliminating divergent formulas.

### 2. Visibility precedence

`Hidden` always hides controls. Cartridge `SYSTEM_HIDE_GAMEPAD_OVERLAY` also hides them in every user mode. `Visible` forces controls to appear on a pointer-capable device when the cartridge flag is clear; `Auto` additionally allows device heuristics to hide them when touch is unavailable or space is insufficient.

### 3. Two layouts

`Overlay` preserves the largest square and draws controls over its bottom area. `Game Above Controls` reserves control height first and then fits the square into the remaining area above the controls. A pointer outside the game returns sentinel coordinates and does not become a game mouse click.

If the separate area would reduce the game side below the verified minimum, the effective layout temporarily becomes Overlay and shows one brief message.

### 4. Scaling remains nearest-neighbor

Existing x/y maps are built for `gameSide`. Black bars are cleared using the full geometry, and overlays and menus are always drawn after the game image.

## Risks / Trade-offs

- [The flag changes every frame] → recalculate the layout only when effective visibility changes and do not allocate arrays every frame.
- [A pointer gesture starts before the layout changes] → pin the layout at gesture start and clear touch buttons when it changes.
- [Small portrait screen] → use a deterministic fallback that keeps the game usable.

## Migration Plan

First move the current geometry into `ViewportLayout` without visual changes, then add the system flag, separate layout, and settings persistence. The default `Auto + Overlay` preserves the current appearance except for the mandatory hide flag.

## Open Questions

- The minimum `gameSide` will be selected after screenshot verification at target resolutions; the specification requires only a deterministic fallback.
