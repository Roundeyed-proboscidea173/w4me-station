## Why

The current interpreter resolves WebAssembly branch depths through six runtime
control-stack arrays and returns from compact execution at every control-flow
boundary. Research across WAMR, wasmi, wasm3, Endive, wasm2j, and interpreter
work targeting Sun CVM shows that branch targets and stack-transfer metadata can
instead be derived once during validation, but the change must be staged and
measured on native phoneME rather than introduced as one control-stack rewrite.

## What Changes

- Add primitive static branch descriptors containing direct target, transfer,
  and control-depth metadata derived during module decoding.
- Introduce the descriptor path beside the current dynamic control stack and
  verify both paths agree before descriptors become authoritative.
- Lower `br`, `br_if`, and `br_table` independently, retaining exact logical
  instruction accounting, trap points, stack transfers, and function returns.
- Allow selected compact regions to execute conditional and unconditional
  branches only after the generic descriptor path is exact and profitable.
- Make dynamic control-stack removal a final, independently reversible phase
  rather than a prerequisite.
- Evaluate an optional 32-bit cell or register-slot W4IR follow-up without
  combining it with the branch-descriptor acceptance decision.
- Bump the cached W4IR format whenever descriptor serialization changes and
  reject older cache records atomically.
- Accept performance claims only from clean, balanced native i686 phoneME A/B
  runs with exact route and full-state gates.

## Capabilities

### New Capabilities

- `static-wasm-control-flow`: Staged decoding, verification, execution, and
  acceptance of static WebAssembly branch descriptors and branch-capable
  interpreter regions on Java 1.3/CLDC 1.1.

### Modified Capabilities

None.

## Impact

The change affects `WasmModule` validation and W4IR generation,
`WasmInterpreter` control transfer and compact execution, cached W4IR
serialization, interpreter differential tests, profiling, and phoneME
benchmarks. It does not change the WASM-4 host API, MIDP UI, cartridge format,
or public user features. The production fallback remains the current validated
dynamic control stack until each replacement phase passes its independent
correctness and performance gates.
