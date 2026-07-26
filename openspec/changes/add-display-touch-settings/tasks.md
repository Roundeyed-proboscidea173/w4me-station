## 1. Layout model

- [ ] 1.1 Move render/pointer/touch geometry into one immutable `ViewportLayout`
- [ ] 1.2 Add `SYSTEM_HIDE_GAMEPAD_OVERLAY` handling and effective-visibility precedence
- [ ] 1.3 Implement Overlay/Game Above Controls and a deterministic small-screen fallback

## 2. Settings and input

- [ ] 2.1 Add Auto/Visible/Hidden and layout controls to Settings
- [ ] 2.2 Persist settings and apply them before the first game presentation
- [ ] 2.3 Clear gestures and latches when the effective layout changes and handle pointers outside the game correctly

## 3. Verification

- [ ] 3.1 Add geometry tests for portrait, landscape, and small screens and for system-flag transitions
- [ ] 3.2 Extend KEmulator screenshot/touch gates for overlay, separate layout, and a hidden gamepad
- [ ] 3.3 Run `just test`, `just build`, `tools/kemu/run.sh verify touch`, and framebuffer oracle gates
- [ ] 3.4 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized
