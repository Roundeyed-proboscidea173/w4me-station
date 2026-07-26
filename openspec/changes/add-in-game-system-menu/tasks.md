## 1. Runtime state machine

- [ ] 1.1 Move the active runtime/module/interpreter lifecycle into a worker-owned session object
- [ ] 1.2 Add frame-boundary RUNNING/MENU/RESTART/LEAVE states with lifecycle-stop priority
- [ ] 1.3 Add an APU suspend/resume/silence contract and input-latch clearing

## 2. Menu UI

- [ ] 2.1 Implement a scrollable overlay over the last frame with keyboard and touch navigation
- [ ] 2.2 Connect Continue, the Settings placeholder, Restart Cart, and Library
- [ ] 2.3 Add capability-controlled Save State/Load State items and brief notifications

## 3. Verification

- [ ] 3.1 Add host tests for state-machine transitions, input isolation, and the absence of catch-up frames
- [ ] 3.2 Add a KEmulator open/continue/restart/library flow that verifies worker/APU cleanup
- [ ] 3.3 Run `just test`, `just build`, cartridge oracle gates, and a frame-loop performance A/B
- [ ] 3.4 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized
