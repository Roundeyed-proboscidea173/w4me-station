## Why

W4ME still exceeds the 60 FPS frame budget on representative cartridges when
run by an old CLDC 1.1 C interpreter without a JIT. Continued optimization
needs a durable, evidence-based loop so that promising ideas are tested against
the real target cost model and rejected paths are not rediscovered.

## What Changes

- Establish a permanent candidate ledger for interpreter, runtime, rendering,
  input, audio, allocation, and cache-path experiments.
- Require isolated, production-shaped prototypes and exact-behavior gates
  before timing claims.
- Use balanced native i686 phoneME A/B measurements as the primary judge for
  Java execution changes, with device-specific secondary gates where phoneME
  does not execute the relevant MIDP boundary.
- Accept, document, and commit only useful stable optimizations; record and
  remove rejected or inconclusive experiments.
- Keep CLDC 1.1, MIDP 2.0, Java 1.3 source compatibility, bounded heap use, and
  release behavior unchanged.

## Capabilities

### New Capabilities

- `no-jit-performance-validation`: Durable candidate tracking, target-specific
  measurement, correctness gates, and accept/reject rules for no-JIT Java ME
  performance work.

### Modified Capabilities

None.

## Impact

The change may touch the WebAssembly decoder and interpreter, W4IR, runtime
host calls, framebuffer conversion and presentation, audio synthesis, test and
benchmark harnesses, and performance documentation. It does not add
user-facing features or change the WASM-4 cartridge contract.
