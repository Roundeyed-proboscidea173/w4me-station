## 1. Scoped storage APIs

- [ ] 1.1 Define composite cartridge identity and read-only inspection results for library/disk/W4IR
- [ ] 1.2 Implement recoverable `CartridgeStore.delete(recordId)` for manifests and chunks
- [ ] 1.3 Implement cartridge-scoped disk and W4IR clearing without broad store deletion
- [ ] 1.4 Add an exact-or-Unknown RMS usage API

## 2. Management UI

- [ ] 2.1 Add a selected-cartridge screen with source kind and per-kind usage
- [ ] 2.2 Add separate confirmations for binary, disk, and W4IR actions
- [ ] 2.3 Update list/focus after success and retain entry/status after failure

## 3. Verification

- [ ] 3.1 Add tests for deletion interruption/recovery, hash ambiguity, and cross-cartridge isolation
- [ ] 3.2 Add KEmulator flows for bundled restrictions, installed deletion, disk clearing, W4IR rebuild, and cancel
- [ ] 3.3 Run `just test`, `just build`, `tools/kemu/run.sh verify library`, `tools/kemu/run.sh verify rms`, and `tools/kemu/run.sh verify w4ir`
- [ ] 3.4 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized
