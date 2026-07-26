#!/usr/bin/env python3
"""Extract the 224-glyph bitmap font from the official framebuffer.c."""

import pathlib
import re
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: extract-wasm4-font.py INPUT_FRAMEBUFFER_C OUTPUT_BIN", file=sys.stderr)
        return 2

    source_path = pathlib.Path(sys.argv[1])
    output_path = pathlib.Path(sys.argv[2])
    source = source_path.read_text(encoding="utf-8")
    match = re.search(
        r"static const uint8_t font\[1792\]\s*=\s*\{(.*?)\};",
        source,
        flags=re.DOTALL,
    )
    if match is None:
        raise SystemExit("official font array not found")

    values = bytes(int(value, 16) for value in re.findall(r"0x([0-9a-fA-F]{2})", match.group(1)))
    if len(values) != 1792:
        raise SystemExit(f"expected 1792 font bytes, found {len(values)}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(values)
    print(f"wrote {len(values)} bytes to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
