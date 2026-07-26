## Why

Manual `file://` entry is inconvenient and requires URI knowledge. On devices with JSR-75, users should be able to select a `.wasm` through an embedded file browser without losing the existing URL/file fallback.

## What Changes

- Add a `Choose .wasm file` action and an embedded file browser when JSR-75 FileConnection/FileSystemRegistry is available.
- Show only directories and eligible `.wasm` files while preserving parent navigation.
- Show the selected name, size, and access or validation errors before installation.
- Retain existing manual URL/file entry as a fallback on devices without JSR-75 or when access is denied.
- Do not scan the file system in the background or request unnecessary permissions before an explicit user action.

## Capabilities

### New Capabilities

- `file-picker-install`: optional JSR-75 picker with a safe fallback to manual location entry.

### Modified Capabilities

- None.

## Impact

This affects the `LibraryCanvas`/`W4MeMidlet` installation flow, `ResourceLoader`, manifest permissions, and optional JSR-75 integration. The base build and startup without JSR-75 must remain functional.
