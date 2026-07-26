## 1. Mapping model

- [ ] 1.1 Define logical actions, default raw/game-action bindings, and an immutable runtime mapping
- [ ] 1.2 Implement a versioned and checksummed settings record with safe defaults
- [ ] 1.3 Move `W4Canvas` input to the mapping with atomic swap and latch clearing

## 2. Settings UI

- [ ] 2.1 Add an action list with key names and a numeric fallback
- [ ] 2.2 Implement cancellable key capture and explicit conflict resolution
- [ ] 2.3 Protect the last System Menu binding and add Reset to defaults

## 3. Verification

- [ ] 3.1 Add tests for settings encode/decode, corruption, conflicts, and default equivalence
- [ ] 3.2 Add a KEmulator flow for remapping Button 1, Button 2, and the menu key and restarting the MIDlet
- [ ] 3.3 Run `just test`, `just build`, `tools/kemu/run.sh verify touch`, and the input oracle gates
- [ ] 3.4 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized
