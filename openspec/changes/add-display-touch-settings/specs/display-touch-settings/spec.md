## ADDED Requirements

### Requirement: The cartridge controls overlay hiding
The system MUST hide the touch gamepad when the active cartridge sets `SYSTEM_HIDE_GAMEPAD_OVERLAY`.

#### Scenario: The flag is set during play
- **WHEN** a completed frame changes the system flag from visible to hidden
- **THEN** the next presentation does not draw controls and their area does not generate gamepad buttons

### Requirement: User visibility policy
The system SHALL provide `Auto`, `Visible`, and `Hidden` modes, with the cartridge hide flag taking precedence.

#### Scenario: Hidden mode
- **WHEN** the user selects Hidden and returns to the game
- **THEN** the touch gamepad is not displayed regardless of screen heuristics

### Requirement: Non-overlapping game layout
The system SHALL provide `Game Above Controls`, in which the game and control rectangles do not overlap.

#### Scenario: A portrait screen has enough space
- **WHEN** `Game Above Controls` is selected and the touch gamepad is visible
- **THEN** the square image is positioned entirely above the control area without covering framebuffer pixels

### Requirement: Unified pointer geometry
The system SHALL calculate WASM-4 mouse coordinates relative to the actual rendered game rectangle and SHALL NOT treat the touch-control area as a game click.

#### Scenario: Pressing Button 1 below the game
- **WHEN** the user touches Button 1 in the separate layout
- **THEN** the gamepad receives Button 1 and the mouse button remains unpressed

### Requirement: Deterministic small-screen fallback
The system SHALL keep the game usable and SHALL explicitly apply a safe fallback when the separate layout does not fit.

#### Scenario: Height is insufficient
- **WHEN** `Game Above Controls` would reduce the game rectangle below the supported minimum
- **THEN** the system uses Overlay or hides controls according to a documented rule and shows one brief message

### Requirement: Display/touch settings persistence
The system SHALL store the selected visibility and layout settings in versioned RMS and SHALL apply defaults when the record is corrupted.

#### Scenario: The MIDlet restarts with saved settings
- **WHEN** the user selected the separate layout and starts the MIDlet again
- **THEN** the setting is applied before the first rendered game frame without an intermediate overlap
