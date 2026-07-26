## Context

The generic interpreter has a slow outer dispatch loop and a compact executor for eligible straight-line regions. Compact eligibility and activation are currently too narrow for important integer-heavy cartridges: the exported `update` call resets the invocation instruction counter, so workloads below the 65,536-instruction threshold never enter the compact tier even when reusable compact metadata exists. The compact opcode set also omits common integer memory and comparison operations, and every control-flow operation returns execution to the slow loop.

The evidence collected so far separates counter improvements from reference-VM speed. With immediate compact activation, Waternet and Untangle execute 55.3% and 34.0% of their logical instructions in compact blocks and reduce outer-loop dispatches by 49.0% and 27.3%, but phoneME measurements find forced activation on these light frames neutral or harmful. That activation candidate is rejected. The isolated seven-opcode compact patch moves Rubido from 37.5% to 59.2% compact coverage and reduces outer-loop dispatches by 25.1%. Eight balanced phoneME pairs from clean commit `d9c2bd3` measure a +2.924% median paired effect on Rubido with 8/8 wins. Waternet and Untangle execute no compact blocks in either variant and report -0.261% and -0.109% with mixed pair signs, which are classified as control noise rather than regressions.

The canonical performance environment is the locally supplied phoneME CLDC 1.1.1 `cldc_vm_r`: a 32-bit ILP32 C-interpreter VM without JIT. The matching AArch64 portable-C build runs under QEMU only as a cross-ISA correctness gate: route checkpoints and deterministic counters must match i686 exactly, while translated wall time is discarded. KEmulator remains the interactive and MIDP integration environment for canvas, touch, RMS, installation, external loading, and sound-backend verification. Its timing results are secondary JIT-regime evidence and cannot accept or reject interpreter speed changes by themselves. Compiling the phoneME harness against its shared CLDC `classes.zip` is also the required API-conformance lint.

The implementation remains constrained to Java 1.3 source and classfile version 47, CLDC 1.1, MIDP 2.0, preverified StackMaps, bounded memory, and the project method-size gate for `execute`. WebAssembly validation, trap ordering, full runtime state, instruction-budget behavior, and existing framebuffer/audio/input/disk behavior are compatibility requirements rather than optimization trade-offs.

## Goals / Non-Goals

**Goals:**

- Measure the actual dynamic opcode mix, compact-region decisions, and break reasons across the exact cartridge corpus.
- Increase generic compact-tier coverage and reduce interpreter overhead where workload-specific phoneME A/B measurements prove a benefit.
- Preserve exact observable WebAssembly and WASM-4 behavior after every frame.
- Recover bytecode headroom in the main dispatch before adding further main-loop cases.
- Make the stable cutoff explicit and defer control-flow lowering to a separately approved, independently gated change.
- Keep each verified optimization in an isolated implementation and commit phase.

**Non-Goals:**

- User-facing features, UI changes, or cartridge-specific fast paths.
- Runtime-generated JVM bytecode, method-per-opcode execution, or object-threaded dispatch.
- Changing linear memory to `int[]` in this change.
- Moving instruction-budget checks only to backedges or compact-block boundaries.
- Treating desktop wall time, compact coverage, or outer-dispatch reduction alone as proof of target speed.
- Removing the signed `offset < 0` memory guard without an equivalent decode-time unconditional trap.
- Implementing deferred arithmetic, bit-operation, or split-stack redesigns without new phone evidence.
- Replacing KEmulator for interactive use or MIDP integration verification.

## Decisions

### 1. Make evidence generation a permanent first phase

The profiler will record the complete decoded opcode space, including prefixed opcodes, dynamic opcode pairs and triples, per-function entry counts, compact block lengths, and the actual reason each candidate region ends or is rejected. Break reasons will be emitted from the interpreter's real eligibility and region-building decisions rather than from a separately maintained mirror of `isCompactOpcode`.

The exact corpus will include generic Plasma, routed and idle Waternet, routed Rubido, routed Untangle, Duck Maze, and Game of Life Zig Edition. Reference and candidate interpreters will start from the same state and compare complete 64 KiB memory, globals, table, framebuffer, palette, input, tone events, and logical disk after every frame. This prevents framebuffer-only agreement from hiding state divergence.

Alternative considered: use the existing opcode-pair counters and framebuffer oracles alone. This is insufficient because it omits compact break causality, can miss non-visual divergence, and does not isolate benchmark variables.

### 2. Bind every A/B result to one build and one variable

The harness will produce identifiable artifacts for current behavior and the seven-opcode-only candidate from one source build. The previously explored activation-policy-only and combined variants are retained only as rejected historical evidence and are not implementation deliverables. Results will record the build identity, W4IR format, workload route, VM identity, profile configuration, sample count, and measured counters. Comparisons across separately drifting builds will not be accepted.

Logical instructions, outer dispatches, compact block calls, compact instructions, block-length distribution, break reasons, and function entries are diagnostic metrics. A paired A/B verdict is the median of the per-pair percentage effects from matching baseline and candidate samples. Independent per-candidate medians remain descriptive and cannot determine the sign of the result. Paired order must be balanced, small-effect acceptance requires at least eight pairs, and a result below the effective `System.currentTimeMillis` resolution per frame remains exploratory. Generic Plasma must bypass its specialized production fast path wherever it is used. KEmulator timing may be recorded as secondary evidence but is never the canonical speed gate.

Accepted receipts must identify a clean source tree, preverified artifact, VM binary, routes, and timing method. A dirty-tree receipt may verify harness behavior or exactness but cannot accept a production performance candidate.

The AArch64 phoneME binary is verified from the same preverified class and route tree as the native i686 run. QEMU execution must pass every browser checkpoint and reproduce the complete deterministic `PhoneMeRouteBench` signature. Initialization, wall-clock, and per-frame timing fields are excluded from the comparison and from all performance claims.

Alternative considered: infer speed from deterministic dispatch reduction. This is useful for explaining a result but cannot model the different per-operation costs of the target Java VM.

### 3. Land the seven integer compact opcodes as the first isolated executor change

The first compact-coverage batch consists of `i32.load` (`0x28`), `i32.store` (`0x36`), `i32.ne` (`0x47`), `i32.lt_s` (`0x48`), `i32.le_s` (`0x4c`), `i32.le_u` (`0x4d`), and `i32.ge_s` (`0x4e`). Their semantics are copied exactly from the main executor, including memory trap order, stack effects, program-counter movement, and instruction-budget accounting. Its exactness is accepted in the stable artifact. The clean eight-pair phoneME repetition accepts the Rubido improvement at +2.924% with 8/8 wins; the inactive-tier Waternet and Untangle controls remain neutral within mixed-sign sub-percent noise.

The batch changes only compact eligibility and `executeCompactBlock`; it does not depend on dense opcode remapping. The measured target-class bytecode delta is small, but the final classfile must still pass the Java 1.3 verifier, preverification checks, and method-size gates.

Alternative considered: add a broad integer opcode set immediately. The seven-opcode batch has whole-corpus evidence and an existing isolated behavioral experiment; a broader batch would weaken attribution.

### 4. Evaluate cheap runtime changes independently

Stable `memory`, `globals`, and `table` array references may be cached by the interpreter, with hot-loop local aliases preferred where they reduce field access without increasing persistent object state unnecessarily. This relies on the fixed 64 KiB memory contract and must retain the current `memory.grow` result behavior.

The isolated runtime-reference cache candidate passed the complete seven-workload full-state differential, but failed the phoneME performance gate. Four alternating fresh-VM pairs measured Waternet at -10.39%, Rubido at +0.16%, and Untangle at -1.26% relative to the accepted seven-opcode baseline. The deterministic counters were identical. The candidate is therefore rejected and its runtime code is removed. Raw laboratory receipts are intentionally excluded from the public source tree; this measured summary is the retained decision record.

Host imports will be resolved to canonical numeric IDs at module load, then dispatched by integer switch. Function types used by `call_indirect` will receive canonical structural IDs: equivalent duplicate type declarations must compare equal even when their original type-section indices differ. Function entry will zero only declared locals because argument slots are overwritten from the caller.

Numeric host-import dispatch passed the complete differential and target-artifact gates and remains the current production implementation; the string path remains only for same-artifact differential verification. Its original performance verdict was invalid because it subtracted independent medians. Reanalysis of the same eight alternating pairs gives median paired effects of +0.530% on Waternet, -0.220% on Rubido, and +0.196% on Untangle. Therefore the implementation is compatibility-verified but is not accepted or described as a performance win. A clean repeated performance A/B is rejected from this stable change and may be proposed separately. Raw laboratory receipts are intentionally excluded from the public source tree; the correction and verdict remain recorded here.

Canonical structural type IDs are assigned from complete parameter and result
vectors while parsing the type section, and each function retains its resolved
type reference. Duplicate-equivalent and near-miss result signatures pass the
focused `call_indirect` test. An isolated generic workload issuing 4,000
indirect calls per frame measured +3.147% with 8/8 wins on native i686
phoneME. Eight-pair Waternet, Rubido, and Untangle controls measured +0.432%,
+0.302%, and +0.153%, respectively, with exact counters and checkpoints.
The host suite, seven-workload counterless full-state gate, target-47 artifact
gate, and native/AArch64 phoneME route parity pass, so the candidate is
retained.

Each candidate gets its own full-state differential and phoneME A/B. None is accepted merely because its generated bytecode contains fewer `getfield` or `String.equals` operations.

Declared-local-only zeroing was also implemented and rejected. A focused
recursive module verified argument overwrite, zero-initialized declared
locals, and reused frames, while the seven-workload full-state differential
matched exactly. The timing variant used separate compile-time artifacts, so
the candidate had no runtime selection branch. Eight balanced phoneME pairs on
the canonical Duck Maze level-one route measured -0.484%, with one win, six
losses, and one tie. The candidate was removed under the no-corpus-regression
gate. Raw exploratory receipts are intentionally excluded from the public
source tree; the rejection and measured effect remain recorded here.

Alternative considered: combine all low-risk changes in one patch. Separate variants are required because their effects can be workload- and VM-dependent.

### 5. Compile diagnostic counters out of timing artifacts

The regular diagnostic artifact retains `dispatchesExecuted`,
`compactBlockCalls`, and `compactInstructionsExecuted`. A separate timing
artifact replaces only the package-private compile-time build configuration.
`javac` then removes the disabled counter updates entirely, without a runtime
flag branch. The instruction counter remains active because it implements the
execution budget and exact trap point.

The isolated counterless artifact passes full-state differential verification
on all seven workloads. The original isolated target-47 inspection measured
`execute` at 7,516 bytes instead of 7,548. With the resident guard present in
both clean-source comparison artifacts, the candidate measures 7,532 bytes
and still contains zero writes to the three disabled counter fields. Eight
balanced phoneME pairs bound to clean commit `e33a073` report median paired
effects of +0.998% on Waternet, +3.929% on Rubido, and +0.884% on Untangle.
All route checkpoints pass and every effect exceeds timer resolution, so the
counterless artifact passes its isolated reference-VM performance gate.

Alternative considered: guard the counters with a runtime boolean. That adds
one branch to the dispatch path being measured and does not isolate production
cost from diagnostics.

### 6. Specialize resident W4IR dispatch

The executor determines once per function invocation whether `body.code` is
resident. Resident bodies cannot change page, so their outer dispatch skips
the code-offset range arithmetic and page lookup. Paged W4IR retains the
existing range check and page-base update path.

The isolated candidate keeps diagnostic counters enabled in both artifacts
and passes the complete host suite. Eight balanced phoneME pairs bound to
clean commit `1d95b08` report median paired effects of +2.036% on Waternet,
+3.393% on Rubido, and +1.396% on Untangle. The clean commit-bound combined
counterless plus resident candidate reports +3.455%, +7.174%, and +2.108%,
respectively, with 8/8, 8/8, and 7/8 wins and exact checkpoints. Every effect
is timer-resolved, so the combined timing configuration passes the reference-VM
performance gate.

Alternative considered: specialize the complete executor into separate
resident and paged methods. The single compile-time guard removes the measured
resident cost while retaining one implementation of every opcode handler.

### 7. Retain the current compact activation policy

Forced compact activation on light Waternet and Untangle frames increases compact coverage and reduces outer-loop dispatches, but the isolated same-head overlay is slower on all three phoneME routes. The overlay receipt is explicitly exploratory because it is not a clean committed source artifact; it is sufficient for the conservative decision not to promote the candidate, but not for a reusable speed magnitude. Sticky/per-function activation was not implemented or measured and is rejected from this stable change for lack of positive isolated phoneME evidence. The current invocation-local threshold remains the stable policy.

This exploratory result warns that reducing dispatch alone may not pay for compact-region entry and handler costs on small frames. Future activation work requires a separate proposal with clean phoneME data that isolates a profitable policy; it must not be combined with opcode coverage.

Alternative considered: persistent hotness plus a static profitability gate. It remains plausible for a subset of functions but lacks positive reference-VM evidence and is therefore deferred rather than implemented speculatively.

### 8. Densely remap internal opcodes and migrate the cache atomically

Decoding will map standard, prefixed, fused, and internal W4IR operations into a dense internal ID range used by the main switch. Original opcode identity or an equivalent diagnostic mapping will remain available for traps, profiles, and debugging. Target bytecode inspection must confirm that the main dispatch is a `tableswitch`; expected bytecode savings are a hypothesis until the version-47 artifact is measured.

The RMS W4IR format version will be bumped. A cache entry from an older format will be rejected and rebuilt rather than partially decoded. Resident decoded streams and streams reopened from RMS must execute identically. Profiling labels and indices will be migrated with the format.

The accepted implementation maps the 197 standard opcode positions directly,
maps the 12 bulk-prefixed operations after them, and maps the 50 internal W4IR
operations into the remaining dense range. Format 14 stores the dense stream;
format 13 remains only in the same-source sparse benchmark artifact. The
reverse mapping preserves original standard, `0xfc00` bulk, and `0x1000` W4IR
identities for traps, profiles, fusion diagnostics, and tests.

Target-47 inspection measures the sparse baseline as a 240-case
`lookupswitch` with a 7,571-byte `execute` method and the dense production
artifact as a `tableswitch` over IDs 0 through 258 with a 6,691-byte method.
The phase therefore recovers 880 bytes of method headroom. The production JAR
gate now rejects any non-`tableswitch` main dispatch and any bundled phoneME
tool binary in addition to its major-version, StackMap, method-size, and
cartridge-integrity checks.

The complete host suite passes dense-map round trips, resident/current-cache
stream identity, previous-format rejection, 60 cached frames, and all seven
full-state workloads. KEmulator passes atomic format-13 rebuild, format-14
cache hit, paged execution, compact execution, and exact framebuffer checks.
The AArch64 phoneME run reproduces all three native i686 route signatures
exactly.

Eight balanced native phoneME pairs from clean commit `6f5789c` measure
+0.679% on Waternet with 7/8 wins, +0.237% on Rubido with 7/8 wins, and
+0.059% on Untangle with 4/8 wins. Every median delta exceeds timer
resolution, while the mixed-sign Untangle result is classified as neutral.
The phase is accepted for its positive Waternet and Rubido effects, lack of a
corpus regression, exact behavior, and measured bytecode headroom; no material
Untangle speed claim is made.

Alternative considered: add more cases to the existing sparse switch. The current `execute` method has too little project-gate headroom, and retaining a 240-way `lookupswitch` preserves avoidable target-VM dispatch cost.

### 9. Select compare-plus-branch fusion from whole-corpus data

After dense remapping, the fusion pass may add generic compare-plus-`br_if` superinstructions selected from dynamic pair and triple counts across the whole exact corpus. The implementation must carry the same branch target, stack transfer, trap behavior, and instruction-budget accounting as the unfused sequence. Existing specialized fusions may remain, but new selection must not identify a cartridge.

The first bounded batch used a cartridge-independent threshold of at least
600,000 dynamic pairs across at least three workloads. It selected
`i32.eq + br_if` (1,469,373 occurrences across six workloads),
`i32.eqz + br_if` (802,632 across six), `i32.lt_u + br_if` (668,548
across three), and `i32.ge_u + br_if` (651,643 across four).

The isolated format-15 implementation passed its focused taken/untaken,
stack-transfer, and 107-case instruction-budget differential, all seven
full-state workloads, the host suite, target-47 artifact verification,
KEmulator W4IR cache checks, and AArch64 phoneME route parity. Its clean
eight-pair route A/B measured +0.348% on Waternet, -0.110% on Rubido, and
+0.526% on Untangle. The decisive 16-pair Rubido repetition measured -0.214%,
with 5 wins, 10 losses, and 1 tie. Although the candidate removed 75,581 outer
dispatches from the Rubido route without changing compact counters, it failed
the corpus wall-time gate and was removed. Raw laboratory receipts are
intentionally excluded from the public source tree; the rejection and measured
effect remain recorded here.

Alternative considered: add `i32.gt_s + br_if` directly because it is prominent in one workload. Corpus-level selection avoids tuning the generic executor around one cartridge.

### 10. Fuse profile-selected `i32.load + local.tee` as an isolated batch

The whole-corpus profile reports 840,995 dynamic `i32.load + local.tee`
pairs across six routes: 750,980 on Rubido, 51,201 on Game of Life, 15,759
on Duck Maze, 14,744 on routed Waternet, 7,590 on Untangle, and 721 on idle
Waternet. This is evaluated separately from both the rejected compare-branch
batch and the later `local.set + br` batch.

The candidate adds one generic W4IR opcode and increments the dense W4IR cache
format from 14 to 15. Its outer and compact handlers execute the load at the
first logical instruction point, then perform the second budget check before
the local write. A trapping load therefore never charges or executes the
`local.tee`, while a budget trap between the two original instructions observes
the loaded stack value without writing the local.

The focused differential covers three static sites, outer and compact
execution, 27 budget positions in each executor, and an out-of-bounds load.
The seven full-state workloads, host suite, target-47 artifact gate,
KEmulator W4IR cache gate, and native/AArch64 phoneME route parity also pass.

The clean-source acceptance run reports +0.648% on Rubido with 6/8 wins and
+0.419% on one-frame Game of Life with 5/8 wins. The first eight-pair controls
were inconclusive, so both were repeated at 16 pairs: Waternet converged to
0.000% with 8 wins and 8 losses, while Untangle converged to -0.070% with
7 wins and 9 losses and equal independent medians. They are classified as
neutral rather than speed claims or corpus regressions. The 60-frame Duck Maze
idle control does not execute the selected pair and is below timer resolution.
The batch is retained. Raw laboratory receipts are intentionally excluded from
the public source tree; the acceptance result remains recorded here.

Alternative considered: combine `i32.load + local.tee` with `local.set + br`.
Separate W4IR toggles and phoneME runs keep the cost and benefit of each
sequence attributable.

### 11. Fuse profile-selected `local.set + br` after larger superinstructions

The whole-corpus profile reports 1,410,831 dynamic `local.set + br` pairs:
705,365 on Rubido, 694,135 on generic Plasma, 6,301 on Untangle, 4,309 on
routed Waternet, and 721 on idle Waternet. The candidate adds one generic
format-16 W4IR opcode and an independent decode toggle.

The fusion runs only after the existing extended and trace superinstructions
have been selected. An earlier prototype fused the pair before
`W4IR_LOCAL_ADD_SET_BR` and the counted Plasma trace were built; the
`W4IrV11Smoke` regression caught the missing trace opcode. Giving established
larger patterns priority preserves their code shape and lets the new opcode
consume only residual adjacent pairs.

Execution pops and writes the local at the first logical instruction point,
then performs the second budget check before calling the unchanged dynamic
branch transfer. The focused differential covers a depth-zero loop backedge,
a depth-one block exit with a result, a function return, five budget positions,
and execution with compact tiering both enabled and disabled. The seven
full-state workloads, host suite, target-47 artifact gate, KEmulator format-16
cache migration, and native/AArch64 phoneME parity pass.

The clean-source native phoneME run confirms +1.696% on Rubido with 7/8 wins.
Waternet is timer-unresolved at 0.000% with 4/8 wins. The first Untangle run
reports -0.149% with 3/8 wins, but its clean 16-pair repetition converges to
0.000% with 7 wins, 7 losses, and 2 ties. Both routes are neutral controls.

Generic Plasma does not confirm the dirty-tree exploratory improvement. Its
clean eight-pair result is -0.056% with 4/8 wins, and the clean 16-pair
repetition is -0.162% with 8/16 wins. The candidate still removes 115,222
outer dispatches from the ten-frame Plasma route, but the workload-specific
wall-time gate requires a positive target effect. The fusion is therefore
rejected and removed from production code. Raw laboratory receipts are
intentionally excluded from the public source tree; the rejection and measured
effect remain recorded here.

Alternative considered: fold branch descriptors into this opcode. The current
batch deliberately reuses `branch()` so the dispatch effect remains isolated;
static descriptors stay a separate phase.

### 12. Reject control-flow lowering from this stable change

Static branch descriptors, branch-capable compact regions, and dynamic control-stack removal were intentionally not implemented before the stable cutoff at commit `7a97dee`. This is a scope and stability decision, not a phoneME performance rejection: no isolated implementation of those phases was built or measured.

The stable artifact retains the existing validated dynamic control-stack path, the existing compact-region control-flow boundaries, and runtime behavior for `block`, `loop`, `end`, `if`/`else`, `br`, `br_if`, `br_table`, `return`, block parameters and results, supported multi-value forms, and unreachable-polymorphic validation states.

Any future control-flow lowering must be a separate OpenSpec. Static descriptors, branch-capable compact execution, and optional control-stack removal remain three independently reversible phases with their own exactness, target-artifact, and native phoneME gates.

Alternative considered: leave the original unchecked implementation plan in this change. That made the stable cutoff look accidental and made completion status ambiguous, so the work is explicitly deferred instead.

### 13. Preserve exact traps and target constraints

An optimization may predecode a memory offset greater than or equal to 65,536 into an unconditional trap executed at the original instruction point and may precompute a maximum valid base address. It must not simply delete the `offset < 0` case, because an unsigned WebAssembly memarg can occupy a negative Java `int` representation.

Budget checks will not be postponed from every logical instruction to backedges or region boundaries because that changes the instruction at which execution traps. Every target JAR will be checked for classfile major version 47, preverified StackMaps, successful KEmulator loading, and `execute` bytecode size at or below 7,800 bytes.

Alternative considered: trade exact trap timing for fewer checks. Exact execution limits are part of deterministic runtime behavior and are not waived for speed.

### 14. Keep speculative tail work behind a new evidence gate

Constant-time unsigned i64 division/remainder, SWAR `clz`/`ctz`/`popcnt`, and an `int`-word value/local stack remain follow-up candidates. Each requires a fresh workload profile and target-device result before it can enter an implementation batch. An `int[]` linear memory representation is excluded because host and renderer synchronization would enlarge both risk and scope.

## Risks / Trade-offs

- [Profiler perturbation changes the workload] -> Build profiling and timing artifacts separately, keep routes deterministic, and compare counters only within the matching artifact class.
- [A compact coverage increase slows the target VM] -> Require workload-specific phoneME medians and retain the old executor as the fallback until the candidate passes.
- [Dense remapping breaks cached W4IR or diagnostics] -> Version the complete cached representation, reject older entries atomically, and retain an internal-ID-to-original-opcode mapping.
- [Canonical type IDs incorrectly merge signatures] -> Derive them from complete parameter and result vectors and add duplicate-equivalent and near-miss type tests.
- [A future static-descriptor change mishandles uncommon validation states] -> Require a separate proposal, retain a compatibility path during its descriptor stage, and include focused tests for every control construct before removing dynamic state.
- [The main method exceeds target verifier limits] -> Inspect target-47 bytecode after each phase and stop before the 7,800-byte project gate.
- [Several optimizations in one result obscure regressions] -> Maintain isolated variants and accept or revert each phase independently.
- [QEMU translation time is mistaken for ARM performance] -> Use the AArch64 VM only for exact checkpoint and deterministic-counter parity; retain native i686 as the phoneME performance judge.
- [Independent medians reverse a paired A/B sign] -> Compute every verdict from matching per-pair effects, balance run order, retain win/loss counts, and label timer-unresolved or short runs exploratory.

## Migration Plan

1. Land measurement, artifact identity, and full-state differential tooling without changing runtime policy.
2. Implement and verify the seven-opcode compact batch in isolation.
3. Evaluate runtime-reference, import-ID, structural-type-ID, and local-zeroing candidates one at a time; retain only passing candidates.
4. Preserve the current activation threshold; keep the rejected forced/sticky activation result as evidence rather than combining it with another candidate.
5. Densely remap opcodes, bump the W4IR cache format, and verify resident and reopened modules.
6. Evaluate only corpus-supported compare-plus-branch fusions and remove any batch that fails the phoneME corpus gate.
7. Evaluate `i32.load + local.tee` and `local.set + br` as separate profile-selected fusion batches with exact logical-instruction boundaries.
8. Reject static branch descriptors, branch-capable compact regions, and control-stack removal from this stable change; retain the existing control-flow implementation and move any future attempt into a separate OpenSpec.
9. Keep every verified phase independently revertible. A rollback restores the previous executor or policy; incompatible cached W4IR is discarded and rebuilt by the matching binary.

## Open Questions

- Should compare-plus-`br_if` be reconsidered only after static branch descriptors or branch-capable compact execution change its target-VM cost?
- Does phoneME benefit more from persistent field caches or function-local aliases once target-47 bytecode and reference-VM timing are measured?
- Which handler-local changes reduce per-instruction accounting, helper-call, or ILP32 `long`-stack cost without changing exact budget and trap semantics?
- Can dynamic control-stack storage be removed completely within the runtime's supported multi-value limits, or should a rare compatibility path remain?
