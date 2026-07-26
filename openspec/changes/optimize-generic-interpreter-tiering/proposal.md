## Why

The generic W4IR interpreter leaves substantial integer-heavy and control-flow-heavy workloads outside its compact tier, while the current activation threshold resets for every exported `update` invocation. Existing measurements show a real coverage opportunity, but the implementation variables and benchmark environments must be isolated before counter reductions can be treated as phone-speed improvements.

## What Changes

- Establish permanent whole-corpus profiling, full-state differential verification, and artifact-bound paired A/B benchmarking that derives the verdict from matching sample effects rather than independent medians.
- Extend the compact executor with the first measured seven-opcode integer batch while preserving exact WebAssembly traps, stack effects, and instruction-budget timing.
- Evaluate stable runtime-reference caching, numeric host-import IDs, canonical structural type IDs, and declared-local-only zeroing as independent optimizations.
- Provide a separately compiled counterless timing/production candidate so diagnostic dispatch and compact counters add no branch or write to the measured hot path.
- Specialize resident W4IR execution so it does not repeat code-page range arithmetic that is required only by paged bodies, while retaining the paged compatibility path.
- Retain the current compact activation policy because an exploratory isolated phoneME overlay was slower on all three routes and no clean positive evidence justifies forced or sticky activation.
- Densely remap decoded internal opcodes, migrate the W4IR cache format, and verify that the main interpreter dispatch compiles to `tableswitch` without losing diagnostic opcode identity.
- Evaluate profile-selected compare-plus-branch fusion and retain it only if phoneME shows no corpus regression. Explicitly reject static branch descriptors, branch-capable compact regions, and control-stack removal from this stable change; those invasive phases require a separately approved OpenSpec and independent phoneME gates.
- Evaluate profile-selected adjacent memory/local and local/control fusion batches one at a time, beginning with `i32.load + local.tee` and then `local.set + br`, while preserving each original logical instruction boundary for budgets and traps.
- Require workload-specific phoneME reference-VM results and the exact corpus/oracle suite for every accepted optimization phase; retain KEmulator for MIDP integration and secondary JIT-regime measurements.
- Cross-check production routes and deterministic counters on the AArch64 build of the same phoneME interpreter under QEMU, without treating translated wall time as ARM performance evidence.
- Defer lower-confidence changes such as an `int` value stack, constant-time i64 helpers, and SWAR bit operations until target-device evidence justifies them.

## Capabilities

### New Capabilities

- `generic-interpreter-optimization`: evidence-driven optimization of W4IR profiling, compact execution, dispatch, runtime lookup, and control-flow handling while preserving exact behavior on Java 1.3/CLDC 1.1.

### Modified Capabilities

- None.

## Impact

This change affects `WasmInterpreter`, W4IR decoding and fusion in `WasmModule`, host-import dispatch in `Wasm4Runtime`, structural type handling, RMS W4IR cache compatibility, corpus replay tooling, the local phoneME reference harness, KEmulator verification harnesses, and target-artifact verification. It introduces no user-facing behavior or cartridge-specific path. Vendored phoneME binaries are local measurement tools and are excluded from release JARs and archives.
