## Why

WASM-4 supports multiplayer input, and J2ME phones commonly provide Bluetooth. Optional JSR-82 netplay will enable local cooperative play without making Bluetooth a requirement for the base runtime.

## What Changes

- Add host/join flows, device discovery, peer confirmation, and a connection-status screen.
- Exchange frame input with an agreed delay and detect desynchronization.
- Give pause, disconnect, and reconnection explicit UX without hiding peer loss.
- Disable user `Save State` and `Load State` actions during an active netplay session.
- Hide netplay on devices without JSR-82 and leave the single-player runtime unchanged.

## Capabilities

### New Capabilities

- `bluetooth-netplay`: optional JSR-82 discovery, pairing, session UI, and multiplayer input synchronization.

### Modified Capabilities

- None.

## Impact

This affects the system menu, multiplayer gamepad state, the frame scheduler, and the optional JSR-82 transport. The change must remain separate from the single-player runtime and must not degrade its speed or memory use when netplay is disabled.
