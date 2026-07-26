## Context

`W4Canvas` currently runs the runtime inside a worker thread and keeps `Wasm4Runtime`, `WasmModule`, and `WasmInterpreter` as local variables in `run()`. The `Library` soft command immediately calls `W4MeMidlet.showLibrary()`, stops the canvas, and destroys the active session. For the menu, the runtime must remain alive and pause must occur between two `update` calls rather than during interpretation.

The official web runtime uses a single-level menu over the last frame and stops updates while it is open. On MIDP, the menu must work consistently with keys and touch without depending on `Form` or `List`, so switching between `Displayable` instances does not destroy the game context.

## Goals / Non-Goals

**Goals:**

- one entry point for runtime actions;
- frame-boundary pause without losing the active cartridge;
- no menu input leaking into the game;
- safe Continue, Restart Cart, and Library actions;
- extensibility through actions supplied by independent change packages.

**Non-Goals:**

- implementation of save states, settings, disk options, or netplay themselves;
- pausing external phone time or updating the game in the background;
- styling for a specific phone model.

## Decisions

### 1. The menu is a worker-loop state

`RUNNING`, `MENU_REQUESTED`, `MENU_OPEN`, `RESTART_REQUESTED`, and `LEAVE_REQUESTED` belong to `W4Canvas`. The UI thread only sets a request; the worker accepts it after the current frame completes. This prevents snapshots or teardown while WASM is executing.

Stopping the thread and opening a new MIDP `List` is visually simpler, but it loses runtime context and creates a race with the APU and interpreter.

### 2. Draw the overlay over the retained last frame

The worker does not call `update` and performs no catch-up after Continue. It redraws a dim layer and compact menu over the last framebuffer. Navigation wraps; WASM-4 button 1/Fire selects an action, while Back/Menu closes the screen.

### 3. Separate game and system input channels

While the menu is open, physical and touch events update only menu state. All latch and pressed bits are cleared on open and close so the menu or confirmation key does not enter the next game frame.

### 4. Pause includes audio

The APU receives `suspendOutput()` after confirmed menu entry and `resumeOutput()` on Continue. Internal frame counters do not advance while paused. The backend must stop active audible sound or become silent using the best available mechanism.

### 5. Register items as stable actions

The base model contains Continue, Settings, Restart Cart, and Library. Save/Load and future actions appear only when their capability is available, while retaining stable labels and ordering. An unavailable action remains visible only when that helps explain the reason; attempting it produces a status notification.

Restart performs teardown and reinitialization on the worker thread. Library performs teardown and then asks the MIDlet to switch `Displayable` on the UI thread.

## Risks / Trade-offs

- [The backend cannot immediately stop an already submitted tone] → extend the audio contract with a silence operation and test every backend explicitly.
- [The menu does not fit on a small screen] → use scrolling and keep at least one row fully visible.
- [MIDP lifecycle races with a menu request] → lifecycle stop takes priority and closes the APU/runtime idempotently.
- [Restart fails] → show the existing cartridge failure flow and return the user to the library.

## Migration Plan

1. Introduce the state machine and menu input without new child actions.
2. Add the overlay and Continue/Library.
3. Add Restart and notifications.
4. Connect Save/Load and Settings only after their capabilities are implemented.

Rollback removes the menu state machine and restores the existing `Library` command; no user data is migrated.

## Open Questions

- Which vendor key codes should open the menu by default in addition to the soft command will be determined through a real-device matrix when control settings are implemented.
