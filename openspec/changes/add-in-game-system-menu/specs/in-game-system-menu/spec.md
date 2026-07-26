## ADDED Requirements

### Requirement: Open the menu at a frame boundary
The system SHALL accept a system-menu command during play and SHALL enter the menu only after the current WASM-4 frame completes.

#### Scenario: The menu is requested during update
- **WHEN** the user invokes the menu while the worker is executing `update`
- **THEN** the current frame completes, the next `update` does not begin, and the menu opens over the last frame

### Requirement: True runtime pause
The system SHALL stop game updates, presentation timing, and APU advancement while a single-player game is in the system menu.

#### Scenario: The menu remains open
- **WHEN** the system menu remains open for several seconds
- **THEN** game and APU state do not advance and no missed frames execute after Continue

### Requirement: Base menu structure
The system SHALL provide `Continue`, `Settings`, `Restart Cart`, and `Library` actions and SHALL insert `Save State`/`Load State` into the main list when the single-save-state capability is available.

#### Scenario: Save-state capability is connected
- **WHEN** the user opens the menu in a build with `single-save-state`
- **THEN** `Save State` and `Load State` are visible as separate main-menu actions without slot selection

### Requirement: System input isolation
The system SHALL route input to the menu while it is open and SHALL clear game button latches when opening and closing it.

#### Scenario: Continue is confirmed with Fire
- **WHEN** the user presses Fire to select `Continue`
- **THEN** the menu closes and that Fire press is absent from the first resumed game frame

### Requirement: Safe transitions
The system SHALL perform `Restart Cart` and `Library` through worker-owned teardown and SHALL close APU and storage handles exactly once.

#### Scenario: Exit to the library
- **WHEN** the user confirms `Library`
- **THEN** the active runtime stops cleanly and the library opens without a background worker thread

### Requirement: Action feedback
The system SHALL show a brief message after a runtime action and SHALL show an error rather than false success when it fails.

#### Scenario: Restart cannot load the cartridge
- **WHEN** cartridge reinitialization fails
- **THEN** the user sees the reason through the existing error flow and can return to the library
