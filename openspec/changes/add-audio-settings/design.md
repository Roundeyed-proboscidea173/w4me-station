## Context

`Wasm4Apu` passes packed WASM-4 tone parameters directly to the backend. There is no user-controlled master gain, and a tone already submitted to the backend may continue playing after the menu is opened or sound is muted. Backend capabilities vary, so the UI must not promise precise volume control when the implementation only supports silence/on.

## Goals / Non-Goals

**Goals:** global mute; volume levels when supported; persistence; no changes to pitch, duration, or envelope timing.

**Non-Goals:** per-cartridge mixing, an equalizer, waveform changes, or fixing backend fidelity as part of this UI change.

## Decisions

### 1. Apply master gain at the APU boundary

The APU stores a value from 0 through 100. Before `submitTone`, it scales the sustain and peak bytes of the packed volume with rounding; frequency, duration, channel, and mode flags remain bit-for-bit unchanged. Zero suppresses audible output, but APU state and ticks continue to advance according to the reference behavior unless the game is paused by the system menu.

### 2. The backend declares its capability

`AudioBackend` reports `VOLUME_CONTINUOUS`, `MUTE_ONLY`, or `SILENT`. The UI shows volume levels only for continuous control, a toggle for mute-only backends, and an unavailable state for silent backends. `silence()` must attempt to stop current output.

### 3. The setting is global and versioned

Gain is stored in the shared settings store. The default is 100; a corrupted record must not silently disable sound.

### 4. Menu pause and user mute are distinct

Pause temporarily suspends output and restores the previous gain afterward. Mute remains active after Continue and after restarting the MIDlet.

### 5. Audio mode is part of the settings form

The existing Automatic/Compatible preference is presented as an exclusive choice in Audio Settings and is persisted together with mute and gain. A change made while a cartridge is running applies when the cartridge is next opened because the active runtime owns its backend for the lifetime of that cartridge.

### 6. The gauge uses the persisted percentage directly

The interactive Gauge uses the full 0 through 100 range. Its saved value is set again after the item is appended to the Form so implementations that normalize an unattached Gauge cannot reset the visible initial level.

## Risks / Trade-offs

- [The backend cannot alter an active tone] → `silence()` closes or resets the active primitive, and the next tone uses the new gain.
- [Packed volume quantization] → use integer scaling with deterministic rounding and boundary tests for 0, 1, and 100.
- [RMS write failure] → keep the setting active for the session and tell the user that it could not be saved.
- [Mode changed while a cartridge is running] → label the deferred application explicitly instead of restarting the cartridge and losing state.

## Migration Plan

Add master gain with a default of 100, then backend capability reporting and silence support, followed by the Settings UI. Existing tone tests at gain 100 must remain bit-for-bit equivalent.

## Open Questions

- The set of UI levels will be refined using real phones; the contract remains 0 through 100.
