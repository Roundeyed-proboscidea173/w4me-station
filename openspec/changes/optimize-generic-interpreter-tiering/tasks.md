## 1. Measurement foundation

- [x] 1.1 Extend profiling to the complete decoded opcode space, dynamic pairs and triples, function entries, compact block lengths, and actual compact break or rejection reasons
- [x] 1.2 Define deterministic generic Plasma, Waternet route and idle, Rubido route, Untangle route, Duck Maze, and Game of Life Zig Edition workloads
- [x] 1.3 Add per-frame full-state differential comparison for 64 KiB memory, globals, table, framebuffer, palette, input, tone events, and logical disk
- [x] 1.4 Bind profiler and benchmark reports to build identity, W4IR format, route, profile, metrics, and artifact configuration
- [x] 1.5 Produce same-build current and seven-opcode-only artifacts without sharing confounding runtime or activation changes
- [x] 1.6 Add and verify the phoneME reference-VM route harness and retain a generic Plasma control that bypasses the specialized production fast path
- [x] 1.7 Add an AArch64 phoneME ISA gate that compares all three production routes and deterministic counters with the native i686 run while excluding QEMU wall time
- [x] 1.8 Replace independent-median A/B verdicts with median paired effects, balanced eight-pair defaults, timer-resolution classification, a wrong-sign regression fixture, and a real phoneME validation run

## 2. Integer compact coverage

- [x] 2.1 Add compact eligibility for `i32.load`, `i32.store`, `i32.ne`, `i32.lt_s`, `i32.le_s`, `i32.le_u`, and `i32.ge_s`
- [x] 2.2 Implement the seven compact handlers with reference-equivalent stack effects, memory trap order, PC movement, and instruction-budget accounting
- [x] 2.3 Run the complete differential and target-artifact gates on the isolated seven-opcode artifact
- [x] 2.4 Repeat the isolated seven-opcode workload and controls under the paired-effect phoneME gate before retaining its historical speed claim

## 3. Independent runtime candidates

- [x] 3.1 Implement and isolate stable memory, globals, and table reference caching, preferring hot-loop aliases where target bytecode supports them; reject and remove it after neutral-to-negative phoneME results
- [x] 3.2 Resolve validated host imports to canonical numeric IDs and replace per-call string dispatch with an integer switch
- [x] 3.3 Canonicalize complete structural function signatures for `call_indirect`, including duplicate-equivalent and near-miss tests
- [x] 3.4 Zero only declared non-argument locals on function entry and verify argument and recursive-call behavior; reject and remove it after the canonical Duck Maze phoneME route regresses
- [x] 3.5 Close each runtime candidate independently: reject and remove persistent field caching and declared-local-only zeroing, retain structural type IDs after positive phoneME evidence, and retain numeric host-import IDs only as compatibility-verified behavior with its speed claim rejected from this change
- [x] 3.6 Add a separately compiled counterless artifact that removes dispatch and compact diagnostics without a runtime branch while preserving instruction-budget accounting
- [x] 3.7 Verify zero hot counter writes in target-47 bytecode, all seven full-state workloads, the complete host suite, and three-route phoneME checkpoint exactness
- [x] 3.8 Repeat the positive eight-pair counterless phoneME result from a clean source tree before making it the production artifact
- [x] 3.9 Add and isolate a resident-W4IR outer-dispatch fast path while retaining the paged range-check path, full diagnostics in both isolated artifacts, and exact route behavior
- [x] 3.10 Repeat the positive combined counterless plus resident-W4IR eight-pair result from a clean source tree before selecting the production timing configuration

## 4. Compact activation decision

- [x] 4.1 Bind the forced compact-activation experiment to an isolated same-head overlay receipt and Waternet, Rubido, and Untangle controls; label it exploratory because the overlay is not a clean committed source artifact
- [x] 4.2 Reject forced compact activation from this stable change after the exploratory phoneME overlay measures -5.899% on Waternet, -0.394% on Rubido, and -4.585% on Untangle despite improved counters; reject unmeasured sticky activation from this change for lack of positive isolated evidence
- [x] 4.3 Retain the current invocation-local threshold and verify that no persistent-hotness or forced-activation code enters the stable artifact

## 5. Dense opcode dispatch and cache migration

- [x] 5.1 Define a dense internal ID map for standard, prefixed, fused, and internal W4IR operations plus a diagnostic mapping to original identity
- [x] 5.2 Decode execution streams and profiling indices through the dense ID map
- [x] 5.3 Bump the RMS W4IR format and atomically reject and rebuild older cached streams
- [x] 5.4 Add equivalence tests for newly decoded, resident, current-format reopened, and old-format rejected streams
- [x] 5.5 Confirm with target-47 bytecode inspection that the main dispatch is a `tableswitch` and record the recovered `execute` bytecode headroom
- [x] 5.6 Run the complete exactness, artifact, and phoneME gates before using the recovered headroom

## 6. Profile-selected compare and branch fusion

- [x] 6.1 Rank generic compare-plus-`br_if` candidates from whole-corpus pair, triple, and compact-break evidence
- [x] 6.2 Document a cartridge-independent selection threshold and select the first bounded fusion batch
- [x] 6.3 Implement selected fusions with reference-equivalent target, stack transfer, trap behavior, and logical instruction accounting; remove the batch after the canonical Rubido route regresses
- [x] 6.4 Run isolated differential, target-artifact, and workload-specific phoneME gates for the fusion batch and retain its rejected evidence

## 6a. Profile-selected adjacent instruction fusion

- [x] 6.5 Rank `i32.load + local.tee` from whole-corpus dynamic evidence and keep it independent from the rejected compare-branch batch
- [x] 6.6 Implement the format-15 load/tee opcode with exact outer and compact stack, trap, PC, and per-logical-instruction budget behavior
- [x] 6.7 Add focused success, out-of-bounds trap, compact, outer, and between-instruction budget differentials
- [x] 6.8 Run the seven-workload full-state suite, host suite, target-47 artifact gate, KEmulator W4IR cache gate, and native/AArch64 phoneME correctness gate
- [x] 6.9 Retain the load/tee batch after clean-source balanced phoneME A/B confirms +0.648% on Rubido, +0.419% on Game of Life, and neutral 16-pair Waternet and Untangle controls
- [x] 6.10 Rank `local.set + br` from whole-corpus dynamic evidence after the load/tee verdict is durable
- [x] 6.11 Implement an independently toggled format-16 opcode after existing larger fusion and trace selection
- [x] 6.12 Add focused depth-zero, depth-one, function-return, stack-transfer, and between-instruction budget differentials
- [x] 6.13 Run the seven-workload full-state suite, host suite, target-47 artifact gate, KEmulator W4IR cache gate, and native/AArch64 phoneME correctness gate
- [x] 6.14 Reject and remove the local-set/branch batch after clean-source phoneME A/B confirms +1.696% on Rubido but no generic Plasma improvement, while Waternet and 16-pair Untangle controls remain neutral

## 7. Control-flow lowering decision

- [x] 7.1 Reject static branch descriptor implementation from this stable change before modifying the decoder or executor
- [x] 7.2 Record that this is a scope and stability rejection, not a phoneME performance verdict, because no isolated descriptor candidate was implemented or measured
- [x] 7.3 Retain the existing validated dynamic branch and stack-transfer path in the stable artifact
- [x] 7.4 Reject branch-capable compact-region implementation from this stable change before changing next-PC, stack-transfer, or budget semantics
- [x] 7.5 Retain the existing compact-region exits at control-flow boundaries
- [x] 7.6 Keep `block`, `loop`, and `end` runtime behavior unchanged because descriptor equivalence was not attempted in this change
- [x] 7.7 Retain the dynamic control stack and defer descriptors, branch-capable compact execution, and stack removal to a separately approved OpenSpec with independent gates

## 8. Acceptance and deferred work

- [x] 8.1 Run the applicable host, WebAssembly, exact-corpus, full-state, phoneME route, target-artifact, and affected KEmulator gates for every retained implementation phase and before removing rejected candidates
- [x] 8.2 Accept performance claims only from clean same-build balanced phoneME pairs with at least eight pairs for small effects above timer resolution; label the forced-compact overlay and invalid historical host-import result exploratory instead of promoting either to a reusable speed claim
- [x] 8.3 Verify the stable candidate against the CLDC 1.1 bootclasspath, classfile-version-47 and preverified-StackMap gates, KEmulator integration gates affected by the changes, release exclusion of phoneME binaries, and the current `execute` sanity limit
- [x] 8.4 Reject i64 div/rem replacement, SWAR bit operations, `int`-word stack or locals, and `int[]` linear memory from this implementation batch until a separately approved evidence-backed change
- [x] 8.5 Review the final stable diff for unrelated or cartridge-specific behavior and commit the verified batch only after explicit authorization, producing commit `7a97dee`
