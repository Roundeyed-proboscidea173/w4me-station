## Why

The runtime currently provides no way to control volume or quickly mute sound. On phones this is a basic system setting that must behave predictably for every cartridge.

## What Changes

- Add global `Sound: On/Off` and volume controls to system settings.
- Apply mute immediately and prevent new audible tones while sound is off.
- Scale volume without changing the WASM-4 envelope, frequency, or tone duration.
- Persist the setting in RMS and restore it the next time the MIDlet starts.
- Put the Automatic/Compatible audio mode selector in the same settings form.
- Show that level adjustment is unavailable when the active backend supports only on/off.

## Capabilities

### New Capabilities

- `audio-settings`: global mute, volume level, persistence, and backend fallback behavior.

### Modified Capabilities

- None.

## Impact

This affects `Wasm4Apu`, audio backends, the settings menu, and settings RMS. The logic must preserve reference-accurate WASM-4 tone parameters and must not add dependencies newer than Java 1.3.
