## 1. Deterministic multiplayer core

- [ ] 1.1 Add the gamepad 2 input path and a deterministic two-runtime harness
- [ ] 1.2 Define a versioned handshake/frame/pause/checksum protocol with fixed packet limits
- [ ] 1.3 Implement an in-memory lockstep transport, negotiated delay, timeout, and desynchronization detection

## 2. Optional JSR-82 transport and UX

- [ ] 2.1 Verify verifier/preverifier packaging and isolate optional JSR-82 classes
- [ ] 2.2 Implement cancellable RFCOMM host/discovery/join and an exact compatibility handshake
- [ ] 2.3 Add connection status, synchronized menu pause/continue, and a disconnect Retry/Library flow
- [ ] 2.4 Disable Save/Load/Restart semantics that cannot be performed safely during a session

## 3. Verification

- [ ] 3.1 Add protocol tests for mismatch, out-of-window packets, bounded queues, timeout, and checksum desynchronization
- [ ] 3.2 Add a two-instance KEmulator flow or a documented JSR-82 simulator harness for host/join/pause/disconnect
- [ ] 3.3 Run `just test`, `just build`, multiplayer corpus exactness checks, and a single-player performance/memory A/B
- [ ] 3.4 Verify the base JAR without JSR-82 and the absence of netplay allocation/polling in single-player mode
- [ ] 3.5 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized
