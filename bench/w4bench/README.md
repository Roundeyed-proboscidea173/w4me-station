# W4Bench

W4Bench is W4ME's deterministic interpreter benchmark:

```sh
just bench-w4bench
```

The command validates the cartridge on the host, then measures seven fixed
workloads on the native i686 phoneME VM without a JIT. The canonical receipt is
written to `build/reports/w4bench/v1/receipt.txt`. A local phoneME rig under
`.local/phoneme/` is required for authoritative timing; `just verify` runs the
host correctness gate without it.

The timed workloads isolate integer control flow, calls, indirect calls,
memory, `i64`, `f32`, and `f64`. Preparation, result validation, CRC32, and
logging stay outside the timer. A separate untimed sweep executes all 190
source-WASM opcodes supported by W4ME. This proves dispatch reachability, not
every possible operand or edge case.

## Files

- `profile_v1.json` is the frozen workload contract.
- `calibration_v1.json` records the reference VM, artifact, and timings.
- `generate_profile.py` produces Java metadata, the opcode catalog, and WAT.
- `w4bench-v1.wasm` is the pinned binary fixture.
- `reference_oracle.py` independently calculates expected results.
- `test_w4bench.py` checks the contract and generator.

Generated sources and reports belong under `build/`; they are not tracked.
The fixture is deliberately kept beside the benchmark rather than among the
third-party game cartridges. `tools/bench/run.sh w4bench` regenerates a
candidate with the pinned project toolchain and requires it to match the
fixture byte-for-byte before any measurement.
