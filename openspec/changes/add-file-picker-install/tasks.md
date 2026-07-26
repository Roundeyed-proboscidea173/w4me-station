## 1. Optional JSR-75 boundary

- [x] 1.1 Verify verifier/preverifier behavior and select isolated-class or dual-variant packaging
- [x] 1.2 Add runtime capability detection and an optional permission without regressing the base build
- [x] 1.3 Implement a bounded FileSystemRegistry/FileConnection adapter with guaranteed close

## 2. File browser and install

- [x] 2.1 Add a paged root/directory browser, parent navigation, and `.wasm` filtering
- [x] 2.2 Add a selection summary, permission/error states, and the manual fallback
- [x] 2.3 Pass the selected stream to the existing staging/validation/commit pipeline

## 3. Verification

- [x] 3.1 Add tests for listing limits, extension filtering, permission denial, oversized or changed streams, and cleanup
- [x] 3.2 Verify the base JAR on a runtime without JSR-75 and the optional variant on a KEmulator profile with the file API
- [x] 3.3 Run `just test`, `just build`, `tools/kemu/run.sh verify install`, and the invalid-cartridge gate
- [x] 3.4 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized
