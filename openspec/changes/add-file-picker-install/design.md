## Context

JSR-75 does not define a native file-picker widget; it provides `FileSystemRegistry` and `FileConnection`. This capability is therefore implemented as an embedded MIDP browser, not as a promise of a system dialog. The base build must load on devices without JSR-75, where direct references to optional classes may cause verification failure.

## Goals / Non-Goals

**Goals:** select a local `.wasm`; navigate roots and directories; show explicit permission and error states; reuse transactional installation; retain a manual fallback.

**Non-Goals:** a general-purpose file manager, background indexing, archive support, or writing files.

## Decisions

### 1. Isolate JSR-75 behind an optional boundary

The core UI checks `Class.forName("javax.microedition.io.file.FileConnection")`. The class with direct JSR-75 imports loads only after a successful check. The manifest uses an optional permission. The verified packaging produces `w4me-station.jar` with the optional adapter and `w4me-station-base.jar` without that class; both artifacts are preverified from the same Java 1.3 source tree.

### 2. The browser shows roots, directories, and `.wasm` files

Listing runs only after the user explicitly opens a directory. Entries are sorted directories-first without reading file contents. Parent navigation is always available except in the root list. An inaccessible directory returns the user to the previous screen with an error.

### 3. Installation uses the existing stream pipeline

After selection, the UI shows the name and known size. The FileConnection input stream is passed to the staging loader with a 64 KiB limit, header/length/hash validation, and commit only after a complete read-back. The URI is not retained as an executable source after installation.

### 4. The fallback remains first-class

`Enter URL/file location` remains available with or without JSR-75. Permission denial does not cause repeated prompt loops; the user can go back and use the fallback.

## Risks / Trade-offs

- [The verifier loads optional references] → isolate classes or use a separate build variant.
- [A directory contains thousands of files] → paged listing with a bounded Vector and continuation.
- [The permission prompt repeats] → request permission only after a user action and remember denial for the current flow.
- [TOCTOU between size and read] → treat the stream limit and final validation as authoritative.

## Migration Plan

Add capability detection, then a read-only browser, and only then connect transactional installation. Verify the base build without JSR-75 classes.

## Resolved Questions

- ProGuard/preverification accepts the isolated optional class. A dual artifact is still retained so the base JAR has no constant-pool reference from a packaged implementation class to JSR-75.
