# Upstream reference assets

`src/main/resources/w4font.bin` is the 224-glyph, 8-byte-per-glyph bitmap
font extracted from the official WASM-4 native runtime:

- repository: `https://github.com/aduros/wasm4`
- commit: `b0d7484f3f8bf7d89810bf6113f8ae81e3fc7cc0`
- source: `runtimes/native/src/framebuffer.c`
- source SHA-256: `2f05f98dbafba09bdfbc88b108d232c7eab69f8ed5c0ca48bd4e810fc22d3a6f`

Recreate the binary after obtaining that exact source file:

```sh
tools/reference/extract-wasm4-font.py framebuffer.c src/main/resources/w4font.bin
```
