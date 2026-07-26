## Context

Workshop is a future network screen layered over the local library. It must not change the trust boundary: remote metadata is untrusted, and a `.wasm` becomes an installed entry only after existing transactional validation. Some J2ME devices lack HTTPS/TLS or require user permission.

## Goals / Non-Goals

**Goals:** bounded manifest; browse/search/details; progress/error states; installation-pipeline reuse; an offline-safe local library.

**Non-Goals:** accounts, payments, reviews, automatic updates, or executing a cartridge directly from the network without installation.

## Decisions

### 1. Versioned, bounded manifest

The endpoint returns a compact JSON subset or a purpose-defined binary manifest with version, generatedAt, and entries. The parser enforces limits on response bytes, entry count, and string lengths, ignores unknown fields, and rejects an unknown major version.

Every entry contains a stable ID, title, author, description, cartridge HTTPS URL, byte size, and content hash. The UI does not interpret HTML.

### 2. Keep the metadata cache separate from the library

The last valid manifest is stored in a separate RMS store with a checksum and age. Offline mode may show a stale label. Removing or changing a remote entry does not delete an installed cartridge.

### 3. Downloads reuse staged installation

The download stream has declared and hard 64 KiB limits, progress based on actual bytes, and hash verification before WASM validation. `CartridgeStore` performs the commit; cancellation or failure removes staging.

### 4. Capability degradation is explicit

If HTTPS is unavailable, Workshop shows the reason and Back/Retry. The local library does not wait for the network at startup. Network permission is requested only on entry or Retry.

## Risks / Trade-offs

- [TLS is incompatible on an older device] → Workshop remains unavailable without downgrading to HTTP.
- [The manifest exhausts the heap] → streaming/bounded parser and a paginated endpoint.
- [Remote metadata is tampered with] → HTTPS, content hash, and local WASM validation; metadata remains untrusted text.
- [The network drops] → transactional staging and retry from the beginning; resume is a separate future change.

## Migration Plan

First define the schema, fixtures, and offline UI, then add a read-only catalog, followed by download integration. A build/property flag can disable the feature without changing local data stores.

## Open Questions

- The specific official endpoint and licensing for metadata and covers will be selected separately before implementation; this specification does not name an unverified service.
