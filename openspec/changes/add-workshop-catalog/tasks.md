## 1. Catalog contract

- [ ] 1.1 Select a verified HTTPS endpoint and define a versioned bounded schema and fixtures
- [ ] 1.2 Implement a streaming/bounded parser with unknown-major, size, count, and string limits
- [ ] 1.3 Implement a checksummed metadata cache with stale age and no link to local deletion

## 2. Workshop UI and download

- [ ] 2.1 Add browse/search/detail/offline/error screens without a network request at Library startup
- [ ] 2.2 Add permission-aware HTTPS refresh, progress, cancel, and retry without HTTP downgrade
- [ ] 2.3 Integrate hash, size, and WASM validation with transactional installation commit

## 3. Verification

- [ ] 3.1 Add fixture tests for malformed, oversized, and unknown manifests and cached offline behavior
- [ ] 3.2 Add controlled-server tests for TLS failure, hash mismatch, cancel, duplicate, and network interruption
- [ ] 3.3 Add a KEmulator UI flow with a local deterministic catalog server and run `just test`/`just build`
- [ ] 3.4 Verify the absence of startup and per-frame regression while Workshop remains unopened
- [ ] 3.5 Review the final diff and commit only the verified feature as a separate commit when the implementation batch has been authorized
