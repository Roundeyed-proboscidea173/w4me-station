## Context

Bluetooth netplay is an optional capability for devices with JSR-82. The base runtime currently exposes only gamepad 1 even though the WASM-4 memory map supports four gamepad bytes. Bluetooth latency and constrained heaps make continuous rollback snapshots expensive; deterministic lockstep with a small input delay is more reliable for the first version.

## Goals / Non-Goals

**Goals:** host/join UX; handshake; two players; synchronized frames and input; synchronized pause; explicit disconnect behavior; zero overhead without JSR-82/netplay.

**Non-Goals:** internet relay, more than two phones, a matchmaking service, voice/chat, rollback prediction, or transferring different cartridges over Bluetooth.

## Decisions

### 1. Isolate JSR-82 as an optional transport

Capability detection and class isolation follow the file-picker approach. Host publishes a UUID service over RFCOMM; Join starts discovery only after a user action and permission grant. The action is hidden when the API is unavailable.

### 2. The handshake verifies exact compatibility

Before launch, peers exchange the protocol version, runtime compatibility ID, cartridge length/CRC/hash, and player roles. Any mismatch terminates the session before the first multiplayer frame and reports a clear reason.

### 3. Deterministic lockstep with input delay

Host numbers the frames. Each peer sends local input for `N + D`; update `N` executes only after both inputs have arrived. D is selected from a small fixed range during the handshake. Frame packets carry a sequence number and checksum; a timeout moves the session to a disconnected overlay instead of allowing one side to continue.

This increases latency but avoids 64 KiB snapshots for every rollback frame and is easier to verify under CLDC heap constraints.

### 4. Menu and pause are protocol events

Opening the system menu sends a pause request. Both peers stop at an acknowledged shared frame boundary. Continue resumes the shared frame number. Restart and Library end the session after notifying the peer. User Save/Load actions are unavailable during the session.

### 5. Detect desynchronization

At a bounded interval, peers compare checksums of selected deterministic VM state. A mismatch stops the game and reports a desynchronization; there is no automatic hidden continuation.

## Risks / Trade-offs

- [Bluetooth latency causes stalls] → negotiated delay, bounded queues, and connection-quality UI.
- [One peer moves to the background] → timeout and a disconnected overlay on both sides.
- [A cartridge or runtime path is nondeterministic] → periodic checksums and corpus tests; terminate the session on desynchronization.
- [Optional classes break the base verifier] → use an isolated package or a separate JSR-82 build variant.

## Migration Plan

First add the gamepad 2 path and a deterministic two-instance harness, then an in-memory transport and JSR-82 handshake/discovery, and only then the UI. A feature flag must completely remove polling and allocation from the single-player frame loop.

## Open Questions

- Default input delay and timeout will be determined using KEmu and real devices; the protocol stores them explicitly instead of relying on peer wall clocks.
