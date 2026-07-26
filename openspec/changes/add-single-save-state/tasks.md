## 1. Snapshot contract

- [ ] 1.1 Add package-private capture/restore APIs for memory, globals, table, and passive-data state
- [ ] 1.2 Add snapshot/atomic-replacement APIs for logical disk and APU channel state
- [ ] 1.3 Implement a compact `RuntimeSnapshot` with cartridge identity, shape validation, and lazy allocation

## 2. Menu integration

- [ ] 2.1 Implement worker-boundary Save with atomic replacement and `State saved`/failure notification
- [ ] 2.2 Implement worker-boundary Load, missing-state notification, input clearing, and immediate rendering
- [ ] 2.3 Clear the snapshot on Restart/Library/failure/destroy without changing persistent disk outside a successful Load

## 3. Verification

- [ ] 3.1 Add round-trip tests for memory, globals, table, passive segments, disk, APU, and mismatched identity
- [ ] 3.2 Add low-heap/OOM tests proving that no partial snapshot becomes available
- [ ] 3.3 Add a KEmulator Save → mutate → Load flow across multiple cartridges without slots or persistence
- [ ] 3.4 Run `just test`, `just build`, oracle gates, and constrained-heap regression
- [ ] 3.5 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized
