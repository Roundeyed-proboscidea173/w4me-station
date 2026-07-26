## Context

The retained interpreter already includes several independently measured
optimizations, but Waternet and Rubido still exceed a 16,667 microsecond frame
budget on the native i686 phoneME C interpreter. Performance work now spans
the full logical frame: W4IR and execution, runtime host calls, allocation,
framebuffer conversion, presentation, input, audio, and persistent cache
behavior.

Previous changes contain detailed evidence for their own candidates, but there
is no single ongoing ledger for future work. That makes it too easy to repeat a
rejected experiment, lose a negative result after removing its prototype, or
mistake a desktop/JIT result for evidence about old Java ME hardware.

The current verified baseline is commit
`f4c824b1433ee831609caabe30bbce5627c50350`, production artifact SHA-256
`b84d58e19c061fefd7d57523eee7b06fa540a917298ccbe0b38a66daac1ae360`,
native i686 VM SHA-256
`bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`,
CLDC classes SHA-256
`117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`,
and preverify SHA-256
`4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.
A one-repetition clean-tree sanity run passed every route checkpoint and
reported 21,104 us/frame for Waternet, 110,472 for Rubido, and 4,830 for
Untangle. These single samples establish rig health only, not a new timing
baseline or acceptance result.

## Goals / Non-Goals

**Goals:**

- Keep one durable record of every new performance hypothesis and verdict.
- Search the complete no-JIT frame budget rather than optimizing only one
  interpreter tier.
- Measure isolated, production-shaped candidates on the runtime that executes
  the affected code.
- Preserve exact WebAssembly, WASM-4, cache, trap, budget, and MIDP behavior.
- Commit each accepted and fully verified optimization as an independently
  revertible stable step.
- Continue the research, prototype, measure, and decision loop until the owner
  changes the goal or asks it to stop.

**Non-Goals:**

- User-facing features or cartridge-specific shortcuts.
- Treating bytecode counts, HotSpot, KEmulator, QEMU, or deterministic counters
  alone as proof of a phone speedup.
- Combining unrelated hypotheses in their first timing comparison.
- Raising the source level above Java 1.3 or depending on APIs beyond CLDC 1.1
  and MIDP 2.0.
- Keeping speculative code in production merely because its semantics are
  correct.

## Decisions

### 1. Use this design as the durable candidate ledger

Every candidate receives a unique `NJIT-NNN` identifier before or during its
first implementation. Its entry records:

- hypothesis and inspiration;
- affected files and exact mechanism;
- expected benefit and compatibility, heap, code-size, and complexity risks;
- baseline commit plus artifact, VM, class-library, and preverify hashes;
- exact build, correctness, inspection, and timing commands;
- workloads and why they exercise the mechanism;
- exactness results, bytecode and memory effects;
- raw balanced pair results and receipt locations;
- one final status: `accepted`, `rejected`, `inconclusive`, `blocked`, or
  `superseded`;
- decision reason and explicit conditions for reconsideration.

Removed prototypes retain their result entry. Raw generated reports stay in
ignored build storage, while the ledger retains enough values and hashes to
understand the verdict after cleanup.

### 2. Index earlier work instead of re-running it

The detailed pre-ledger record remains in
`optimize-generic-interpreter-tiering/design.md` and
`lower-static-wasm-control-flow/design.md`. The following families are already
closed unless materially new evidence or a different mechanism is stated:

- seven integer compact opcodes: accepted;
- counterless timing artifact and resident W4IR dispatch: accepted;
- dense internal opcode mapping: accepted;
- `i32.load + local.tee`: accepted;
- canonical function type IDs: accepted;
- pc-indexed direct ordinary branch path: accepted;
- forced compact activation: rejected;
- persistent runtime array-reference fields: rejected;
- declared-local-only zeroing: rejected;
- compare-plus-`br_if` and `local.set + br` fusion batches: rejected;
- binary-search branch descriptors: rejected and superseded by direct lookup;
- hot generic push/pop inlining and wrapper-only pop simplification: rejected
  by local native phoneME experiments;
- `int[]` linear memory and cartridge-specific fast paths: out of scope.

A candidate may revisit one of these only when its ledger entry identifies the
new evidence, materially different implementation, or improved measurement
method that changes the old hypothesis.

### 3. Match the performance judge to the code being optimized

Native i686 phoneME without JIT is the primary judge for Java interpreter,
runtime, pure conversion, and pure synthesis work that its harness executes.
Balanced paired effects, not independent medians, determine the sign. At least
eight pairs are required for small effects; more are required when signs,
layout, timer resolution, or host contention are unstable.

KEmulator validates interactive Canvas, touch, RMS, installation, filesystem,
and audio behavior. Its JIT wall time is secondary only. A physical phone is
the final judge for `Graphics.drawRGB`, `flushGraphics`, MMAPI latency, real
heap limits, and input responsiveness. AArch64 phoneME under QEMU verifies only
cross-ISA checkpoints and deterministic counters.

### 4. Gate correctness before timing

Each candidate first passes focused semantic tests and all affected exact
oracles. Interpreter changes additionally preserve instruction-budget trap
points, target-47 bytecode shape, dense `tableswitch`, preverified StackMaps,
and the 7,800-byte `execute` ceiling. All candidates record class/JAR and
persistent heap deltas. Timing artifacts compile selection flags out of the hot
path and must be bound to a clean source snapshot and exact binary hashes.

### 5. Keep one variable per first comparison

The first authoritative A/B changes only the candidate mechanism. An accepted
candidate is then measured with the currently retained set before landing;
percentage effects from independent patches are never added. A candidate that
regresses, moves cost elsewhere, falls below reliable resolution, or adds
unjustified memory or complexity is documented, removed, and not committed.

### 6. Candidate ledger

The research queue is ordered by expected target relevance, dynamic coverage,
implementation risk, and the ability to get an authoritative verdict:

| ID | Candidate | Source | State |
| --- | --- | --- | --- |
| `NJIT-001` | Local mandatory instruction counter inside compact execution | phoneME C-interpreter bytecode cost and current `javap` | rejected |
| `NJIT-002` | Skip W4IR operand and auxiliary loads for operand-free numeric opcodes | current dense executor and corpus profile | rejected |
| `NJIT-003` | Implement unsigned i32 comparisons with sign-bit XOR instead of `long` conversion | WebAssembly integer ordering and phoneME ILP32 cost | rejected |
| `NJIT-004` | Reorder `execute` parameters so hot references use `_n` local-load bytecodes | phoneME generic versus short local-load handlers | rejected |
| `NJIT-005` | Fold memory base, offset, overflow, and end checks into one effective-address guard | local algebraic analysis of `checkedAddress` | rejected |
| `NJIT-006` | Lower direct imported calls to a dedicated W4IR host-call opcode | current intrinsic lowering and import metadata | rejected |
| `NJIT-007` | Replace the explicit `push` capacity check with the mandatory JVM array bounds check | target-47 bytecode, phoneME `lastore`, and exact stack-write counts | accepted |
| `NJIT-008` | Expand packed framebuffer bytes and reuse repeated scaled rows | renderer audit | queued, needs renderer microbench and device gate |
| `NJIT-009` | Add an unrotated, unflipped `blitSub` inner loop | host-render audit | accepted |
| `NJIT-010` | Reduce exact PCM envelope and pitch arithmetic per sample | audio synthesis audit | accepted |
| `NJIT-011` | Avoid a third clock read on non-presented logical frames | Canvas timing audit | queued, physical/KEmulator judge only |
| `NJIT-012` | Reorder `executeCompactFused` parameters for short local-load bytecodes | phoneME local-load handlers | rejected |
| `NJIT-013` | Revisit split i32/long value storage with the corrected phoneME cost model | phoneME stack representation research | queued, separate high-risk design |
| `NJIT-014` | Inline packed framebuffer read-modify-write in the transform-free blit loop | `drawPoint` target-47 cost and NJIT-009 coverage | accepted |
| `NJIT-015` | Carry the packed destination byte and bit shift across a plain-blit row | NJIT-014 target-47 bytecode and opaque-pixel profile | accepted |
| `NJIT-016` | Reuse adjacent upscaled ARGB rows through native `System.arraycopy` | framebuffer scaler audit and phoneME native-arraycopy cost | accepted |
| `NJIT-017` | Cache the last packed framebuffer byte while scaling a row | independent renderer target-bytecode review | accepted |
| `NJIT-018` | Hoist `argbLookup` into the ARGB conversion loop's local frame | independent renderer target-bytecode review | accepted |
| `NJIT-019` | Cache the packed framebuffer byte in native/downscale conversion | NJIT-017 result and deferred canonical-loop follow-up | accepted |
| `NJIT-020` | Replace the defined-function argument-copy loop with a scalar/native bulk-copy split | Game of Life call profile and native phoneME arraycopy cost | accepted |
| `NJIT-021` | Fuse signed i32 comparisons with `br_if` and use the pc-indexed direct branch path | Game of Life control-flow profile plus the accepted direct branch descriptors | rejected |
| `NJIT-022` | Fuse `i32.load8_u + local.set` into one exact two-instruction W4IR handler | corrected Game of Life production-stream profile and accepted load/tee precedent | rejected |
| `NJIT-023` | Fuse `i32.add_const + i32.load8_u + local.set` into one exact four-logical-instruction handler | NJIT-022 rejection plus stable compact-stream profile | rejected |
| `NJIT-024` | Inline the compact `i32.load8_u` stack and scalar-address path | Game of Life compact coverage plus phoneME Java-call cost | inconclusive |

The earlier `popFirst`/`popSecond` wrapper-only experiment is not in this
queue: a 16-pair native phoneME repeat measured only +0.060% on Waternet and
mixed neutral or negative controls, so it remains rejected in the historical
index.

### NJIT-001: local compact instruction counter

**Status:** `rejected`.

**Hypothesis and source.** The compact loop currently reads and writes the
`instructionsExecuted` field at every token, including twice for the accepted
two-instruction load/tee fusion. On the portable-C phoneME interpreter every
`aload_0`, `getfield`, arithmetic bytecode, and `putfield` is separately
dispatched. Keeping the mandatory instruction-budget counter in a Java local
for one compact block and publishing it on every normal or exceptional exit
should remove this repeated field traffic without weakening exact budget
accounting. This is distinct from the accepted counterless artifact: that
artifact removes optional diagnostic counters but deliberately leaves this
mandatory counter active.

**Affected files and mechanism.** The production change is limited to
`WasmInterpreter.executeCompactBlock`. It snapshots
`instructionsExecuted`, performs the same per-logical-instruction increments
and limit checks on the local value, and writes the final value back in a
`finally` path so memory, stack, arithmetic, host, and budget traps expose the
same count. Benchmark snapshots use the existing counterless timing config;
no runtime selection branch enters the hot path.

**Expected benefit and risks.** Rubido is the primary real-game workload: the
clean rig sanity receipt records 25,448,416 compact instructions across 129
frames. Generic Plasma is a compute-heavy mechanism control. Waternet and
Untangle currently enter no compact blocks and must remain timing-neutral.
Expected benefit is 1–5% on compact-heavy routes, with zero persistent heap
growth. Main risks are an off-by-one budget trap, failure to publish the count
on a non-budget trap, target-47 `finally`/StackMap behavior, and code growth in
`executeCompactBlock`.

**Baseline identity.**

- source commit:
  `f4c824b1433ee831609caabe30bbce5627c50350`;
- production artifact:
  `b84d58e19c061fefd7d57523eee7b06fa540a917298ccbe0b38a66daac1ae360`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Planned commands and workloads.**

- focused and complete correctness: `just test`, followed by `just verify`;
- clean artifact and checkpoint sanity:
  `tools/phoneme/run.sh bench waternet rubido untangle plasma-cube --mode
  optimized --candidate counterless --reps 1`;
- target inspection: `javap -c -p` on both clean target-47
  `WasmInterpreter.class` files, plus the existing release method-size,
  dense-switch, class-version, and StackMap gates;
- timing: alternate clean baseline and candidate preverified trees with
  `.local/phoneme/cldc_vm_r -EnableTicks =HeapCapacity64M -classpath
  .local/phoneme/classes.zip:<tree> w4me.PhoneMeRouteBench <cart> optimized 60
  1 counterless <sample>` and calculate paired effects with
  `tools/phoneme/paired-stats.awk`;
- at least eight balanced pairs on Rubido and generic Plasma, with Waternet and
  Untangle controls. Increase repetitions if pair signs or timer resolution
  are unstable.

**Acceptance rule.** Require exact checkpoints and counters, at least +0.8%
median paired effect on Rubido, and no resolved regression worse than -0.5% on
Waternet or Untangle. Plasma explains the compact mechanism but cannot accept
the candidate by itself.

**Correctness and artifact results.**

- `just test` and `just verify` passed on the candidate tree. Both release JARs
  were preverified, all 10 bundled cartridges passed release integrity checks,
  and the seven-workload full-state matrix remained exact.
- Native i686 phoneME checkpoint sanity passed for Waternet, Rubido, Untangle,
  and generic Plasma. Every deterministic output field before timing matched
  between the paired clean artifacts.
- The focused load/tee differential test exercised successful compact
  execution, budget boundaries, and an out-of-bounds memory trap. It also
  exposed an existing outer-versus-compact fused-span budget-count difference;
  that unrelated legacy behavior was not changed by this candidate.
- The clean target-47 counterless `executeCompactBlock` grew from 2,815 to
  2,820 code bytes. Accesses to `instructionsExecuted` fell from six
  `getfield` plus three `putfield` instructions to one `getfield` plus two
  `putfield` instructions, with one exception-table entry added by `finally`.
  The complete `WasmInterpreter.class` grew from 79,340 to 79,505 bytes.
  Persistent heap use was unchanged.
- Clean temporary source snapshots were commit
  `ac3b6cd17bc112da17ba129bddcaffef77b3c1ba` for the baseline and
  `7d02c27d30d5b93fd45a2b6b6f04efe68f75f324` for the candidate. Their staged
  counterless preverified tree hashes were respectively
  `5cb285f3f514651dfefc6a27d22f3be70e1e3582501c7add5c9a290c35d6a0e7`
  and
  `58800cc59b1edf417ae89b27fa0f3b919d11d22382c078b45da2988a59f351b2`.
  The source snapshots and raw receipts are retained under
  `/tmp/w4me-njit001.f2r3fe/` for the lifetime of this host session.

**Native i686 phoneME A/B.** Eight balanced Rubido pairs used 129 routed
frames per invocation. Timer resolution was 7.752 us/frame, source snapshots
were clean, all 30 checkpoints passed per invocation, and all invocations
reported exactly 43,301,827 logical instructions:

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 103,511 | 104,093 |
| 1 | candidate first | 104,279 | 103,767 |
| 2 | baseline first | 103,697 | 104,209 |
| 3 | candidate first | 105,108 | 103,573 |
| 4 | baseline first | 104,317 | 103,837 |
| 5 | candidate first | 103,922 | 103,984 |
| 6 | baseline first | 104,689 | 103,581 |
| 7 | candidate first | 104,426 | 104,255 |

The median paired delta was 325.5 us/frame, or **+0.312%**, with five wins and
three losses. This is below the predeclared +0.8% acceptance floor. Additional
control timing cannot make the primary Rubido gate pass, so the planned
Waternet, Untangle, and Plasma timing pairs were not spent after their
checkpoint sanity runs.

**Decision.** Reject and remove the implementation. The bytecode mechanism was
real, exact, and slightly positive, but the authoritative improvement was too
small for the added `finally` control flow, class growth, and maintenance cost.
No production commit is made.

**Reconsideration condition if rejected:** only a materially different
accounting layout, a new compact-heavy real cartridge route, or a more precise
target-device timing method.

The rejected source and focused-test changes were removed exactly. The
restored stable tree then passed `just verify`: diagnostic `execute` remained
7,039 bytes, the counterless `execute` remained 7,007 bytes, both release JARs
were preverified, and the seven-workload full-state matrix passed. The stable
counterless verification artifact is
`3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`;
the station and base JAR hashes are respectively
`da61cf43640dd20a8c65c7cde6746d038c1cb428e0526a590b7ad7ef49d3920e`
and
`5ec791eb2a0a363da36c268f711a362014f5dad244dc56870c3c68b5d7d7a3dc`.
No production commit was made for NJIT-001.

### NJIT-002: resident operand-free numeric payload loads

**Status:** `rejected`.

**Hypothesis and source.** The outer executor eagerly reads all three integers
of every fixed-width W4IR record before dispatch. Standard numeric opcodes
`0x45..0xc4` use neither `operand` nor `auxiliary`, so a resident-code range
guard can replace two bounds-checked `iaload` operations with zero
initialization. Target-47 `javap` shows that each current payload read expands
to six interpreted Java bytecodes before the main `tableswitch`; local phoneME
disassembly confirms that `iaload` performs null, negative-index, and upper
bounds checks in the portable-C interpreter.

This does not repeat the accepted resident W4IR page guard or dense opcode
mapping: those changes remove page-range arithmetic and linear switch lookup,
while both payload array reads remain present on the current stable tree.

**Coverage and selected scope.** The preserved format-15 exact corpus profile
contains 169,131,105 outer dispatches. The numeric band accounts for 23.872%
overall, 18.331% on the Waternet browser route, 18.315% on Rubido, 10.751% on
Untangle, 22.997% on Duck Maze, 23.706% on Game of Life, and 24.527% on
generic Plasma. This profile disabled compact execution and therefore
overstates the optimized outer-path exposure on compact-heavy Rubido and
Plasma; Waternet is the primary real-game workload.

The first candidate intentionally excludes other scattered operand-free
opcodes, dense bulk saturating conversions, and `W4IR_F32_MUL_ADD`. It also
leaves `executeCompactBlock` unchanged. That keeps the classifier to one
contiguous standard-opcode range and isolates one outer-executor mechanism.

**Affected file and mechanism.** In
`WasmInterpreter.execute`, declare `operand` and `auxiliary` without eager
initializers. When `residentCode` is true and `opcode` is in `0x45..0xc4`,
assign zero to both unused locals; otherwise perform the original two array
loads in their original pre-accounting position. The resident guard is
mandatory: a checksum-valid but truncated paged RMS W4IR record currently
fails on the eager `+1` or `+2` access after page reload. Skipping those reads
on paged code could execute an incomplete numeric instruction and change
trap, mutation, profiling, or budget order. The existing page-range guard is
not changed.

**Expected benefit and risks.** The resident numeric path removes two checked
array accesses but every outer dispatch pays the resident/range classifier.
The sign is deliberately unresolved until native phoneME A/B. Persistent heap
delta is zero and no W4IR/cache format change is expected. Risks are a
wrong range boundary, accidental payload suppression on paged code, method
layout changes, a nonnumeric slowdown larger than the numeric saving, and
`tableswitch` alignment or method-size growth.

**Baseline identity.**

- source commit:
  `f4c824b1433ee831609caabe30bbce5627c50350`;
- stable counterless verification artifact:
  `3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Planned verification and measurements.**

- Add a focused differential covering resident and paged W4IR at the
  `0x44/0x45/0xc4` boundaries, numeric stack and arithmetic traps, and
  instruction-budget boundaries. A checksum-valid page truncated by one or
  two integers must retain the stable pre-execution failure and state.
- Run `just test` and `just verify`, inspect both diagnostic and counterless
  target-47 `execute` methods with `javap`, and record method/class/JAR and
  persistent-heap deltas.
- Build clean hash-bound baseline and candidate counterless artifacts. Run
  checkpoint sanity before timing.
- Use at least eight balanced native i686 phoneME pairs on Waternet as the
  primary route, with Untangle as a nonnumeric-sensitive no-regression control.
  If Waternet passes, run Rubido and generic Plasma to detect compact/compute
  interaction. Do not time KEmulator or QEMU as performance evidence.

**Acceptance rule.** Require exact state, trap, budget, paged-cache, and
checkpoint behavior; a median paired Waternet improvement of at least +0.8%;
and no resolved regression worse than -0.5% on Untangle. Rubido and Plasma
cannot accept a Waternet-oriented outer-dispatch candidate by themselves.

**Correctness and artifact results.**

- `just test` and `just verify` passed on the isolated candidate. The complete
  exact corpus, seven-workload full-state differential, valid and malformed
  paged W4IR, trap and instruction-budget suites, both preverified release
  JARs, and all 10 bundled cartridge integrity checks remained green.
- The focused extension fixture executes the inclusive numeric boundary
  `0xc4` (`i64.extend32_s`) and retains the existing `0x44` constant and bulk
  opcode coverage. The resident-only guard leaves paged payload reads in their
  original pre-accounting position.
- Native i686 phoneME checkpoint sanity passed for Waternet, Rubido, Untangle,
  and generic Plasma. Every deterministic field before `init-ms` matched
  between baseline and candidate in every timing pair.
- The diagnostic target-47 `execute` method grew from 7,039 to 7,067 code
  bytes; the counterless method grew from 7,007 to 7,035. Both retained the
  dense `tableswitch`, classfile version 47, preverified StackMaps, and 733
  bytes of diagnostic method headroom below the 7,800-byte gate.
- The clean counterless `WasmInterpreter.class` grew from 52,751 to 52,791
  bytes. The station JAR grew from 228,102 to 228,157 bytes and the base JAR
  from 225,588 to 225,643 bytes. Candidate JAR hashes were respectively
  `3be2fd9ff4e451a897254600f0b1bd8e6706ca86dc9b418189c7950294d93496`
  and
  `534467eb21ed4fdd2f23fe9fe6fcdcf57a96d0c33dcbbe50acd4b5915b71408c`.
  No field, array, retained object, or W4IR record was added, so persistent
  heap delta is zero.
- Clean temporary source snapshots were commit
  `ac3b6cd17bc112da17ba129bddcaffef77b3c1ba` for the baseline and
  `71dcac96e1767c67481dad250ac503b9fbca7fc4` for the candidate. The baseline
  counterless preverified tree hash was
  `5cb285f3f514651dfefc6a27d22f3be70e1e3582501c7add5c9a290c35d6a0e7`.
  Waternet timing used the candidate's Waternet-only tree hash
  `7dc9a18f2ec3c5070697abec04ccb2c638a279a1045e24030281319b2ede732c`;
  the unchanged classes plus all four control resources produced tree hash
  `e3e530f17854f263ea94947943730340428fc3f6ce06d5fb9bdb6f1b5640cdf3`
  for the other timing runs.

**Native i686 phoneME A/B.** All runs used the counterless optimized artifact,
balanced order, exact route checkpoints, and the VM and CLDC hashes recorded
above. Raw outputs and CSV files are under
`/tmp/w4me-njit002.1KywKl/evidence/` for the lifetime of this host session.

| Workload | Routed frames | Median delta us/frame | Median speedup | Wins/losses | Timer resolution |
| --- | ---: | ---: | ---: | ---: | ---: |
| Waternet | 153 | +219.0 | **+1.074%** | 7/1 | 6.536 us/frame |
| Untangle | 460 | +26.0 | **+0.544%** | 7/1 | 2.174 us/frame |
| Rubido | 129 | +1,778.5 | **+1.711%** | 8/0 | 7.752 us/frame |
| generic Plasma | 10 | -43,200.0 | **-3.751%** | 0/8 | 100.000 us/frame |

The raw pairs were:

| Pair | Waternet B/C | Untangle B/C | Rubido B/C | Plasma B/C |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 20,483 / 20,176 | 4,723 / 4,765 | 103,844 / 102,062 | 1,172,700 / 1,186,000 |
| 1 | 20,647 / 20,117 | 4,760 / 4,726 | 104,162 / 102,240 | 1,158,400 / 1,177,400 |
| 2 | 20,673 / 20,202 | 4,758 / 4,721 | 104,271 / 101,891 | 1,144,100 / 1,198,700 |
| 3 | 20,607 / 20,542 | 4,758 / 4,750 | 104,186 / 102,635 | 1,151,700 / 1,196,600 |
| 4 | 20,496 / 20,339 | 4,839 / 4,756 | 104,085 / 102,310 | 1,163,500 / 1,187,100 |
| 5 | 20,313 / 20,496 | 4,758 / 4,743 | 104,379 / 102,697 | 1,144,000 / 1,203,300 |
| 6 | 20,483 / 20,366 | 4,789 / 4,745 | 107,527 / 102,155 | 1,151,400 / 1,192,900 |
| 7 | 20,346 / 20,065 | 4,815 / 4,797 | 104,186 / 102,581 | 1,150,500 / 1,218,200 |

**Decision.** Reject and remove the candidate. It exceeded the primary
Waternet floor and improved both game controls, but generic Plasma regressed
by 3.751% in all eight pairs. That material compute regression is larger than
the accepted game gains and demonstrates that the added classifier and method
layout are not generally profitable. No production commit is made.

The candidate and its focused boundary fixture were removed exactly. The
restored baseline then passed `just verify`: diagnostic `execute` returned to
7,039 bytes, counterless `execute` returned to 7,007 bytes, both release JARs
were preverified at 228,102 and 225,588 bytes, and the seven-workload
counterless full-state matrix remained exact. The stable counterless artifact
is again
`3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`.

**Reconsideration condition if rejected:** only a branch-free operand-shape
encoding, a separately validated page format that makes all records safe for
lazy payload access, a function-level policy that avoids the measured compute
regression, or a target-device measurement method precise enough to resolve a
smaller effect.

### NJIT-003: sign-bit lowering for unsigned i32 comparisons

**Status:** `rejected`.

**Hypothesis and source.** WebAssembly unsigned 32-bit ordering can be mapped
exactly to Java signed `int` ordering by XORing both operands with
`0x80000000`. The current common `compareI32` helper instead converts each
operand to `long`, masks both with `0xffffffffL`, runs `lcmp`, and branches.
Target-47 `javap` shows 10 Java bytecodes in each unsigned comparison core.
The XOR form uses seven and removes two `i2l`, two 64-bit `land`, and one
`lcmp` in exchange for two 32-bit `ixor` instructions.

Three independent read-only reviews agreed on the minimal form and found no
semantic counterexample or prior duplicate. Local phoneME disassembly and an
isolated Java 1.3 prototype support the mechanism but do not establish wall
time. The prototype passed a boundary cross product and one million
deterministic input pairs. The four changes remain inside the existing private
helper; outer and compact executors already share it. Counted trace and the
cartridge fast path do not call this helper and are intentionally unchanged.

This is not a repeat of the rejected unsigned-compare-plus-`br_if` fusion in
commits `874054a` and `20cdc1d`. That experiment changed W4IR dispatch and
control flow and regressed Rubido. NJIT-003 changes only the arithmetic
lowering after the same two stack pops and introduces no opcode or fusion.
Repository history contains no earlier sign-bit implementation in
`compareI32`.

**Coverage and selected scope.** The preserved exact generic-corpus profile
contains 2,697,395 executions of `i32.lt_u` (674,905), `i32.gt_u`
(1,347,966), `i32.le_u` (9,790), and `i32.ge_u` (664,734). Generic Plasma
contributes 2,606,428 across 60 frames, or about
43,440 per frame. The Waternet browser oracle route contributes 27,905, Duck
Maze 15,300, Untangle 19,638, Rubido 700, and one Game of Life frame 25,923.
Plasma is therefore the primary mechanism workload and Waternet is the
representative game control.

**Affected files and mechanism.** In
`WasmInterpreter.compareI32`, keep the existing `right`-then-`left` pop order
and replace only operations 3, 5, 7, and the default operation 9 with signed
comparisons of `left ^ 0x80000000` and `right ^ 0x80000000`. Add a focused
WASM fixture that evaluates the full cross product of
`{0, 1, 0x7fffffff, 0x80000000, 0xfffffffe, 0xffffffff}` for all four
relations, and a
Java smoke test that checks every result against the old unsigned-`long`
oracle in both forced-outer and compact-enabled execution. Include exact
`N-1/N` instruction-budget boundaries.

**Expected benefit and risks.** Every dynamic unsigned i32 comparison removes
three interpreted Java-bytecode dispatches and all 64-bit comparison traffic.
The current target-47 helper is 266 code bytes and is expected to shrink to
about 254; `execute`,
W4IR, cache format, persistent heap, and cartridge state are unchanged. Main
risks are a reversed operand or relation, insufficient boundary coverage,
compact-versus-outer divergence, and whole-class layout effects on phoneME.

**Baseline identity.**

- source commit:
  `f4c824b1433ee831609caabe30bbce5627c50350`;
- stable counterless verification artifact:
  `3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Planned verification and measurements.**

- Run the focused 36-pair by four-relation oracle in forced outer and
  compact-enabled modes, including the exact instruction-budget boundary.
- Run `just test` and `just verify`, inspect target-47 `compareI32` to confirm
  `i2l`, `land`, and `lcmp` disappeared from its unsigned cases, and record
  method/class/JAR and persistent-heap deltas.
- Build clean hash-bound baseline and candidate counterless artifacts and
  require identical checkpoint and deterministic route fields.
- Run at least eight balanced native i686 phoneME pairs on generic Plasma,
  using 10 compute frames per invocation for a tractable but timer-resolved
  primary series. If it passes, run at least eight Waternet pairs and
  no-regression controls on Duck Maze, Untangle, and Rubido. KEmulator and
  QEMU wall time are not evidence for this candidate.

**Acceptance rule.** Require exact semantics and all compatibility gates, a
median paired generic Plasma improvement of at least +0.8%, and no resolved
regression worse than -0.5% on Waternet, Untangle, or Rubido. A game route may
strengthen but cannot replace the compare-heavy primary result.

**Correctness and artifact results.**

- The focused fixture passed all 36 operand pairs and four unsigned relations
  against the original `long`-mask oracle in both forced-outer and
  compact-enabled execution. It also passed the exact `N-1/N` instruction
  budget boundary and proved that compact execution was exercised.
- `just test` and `just verify` passed. Both release JARs were preverified, all
  10 bundled cartridges passed release integrity checks, and the seven-workload
  full-state matrix remained exact.
- Clean native i686 phoneME sanity runs matched every deterministic field
  between baseline and candidate. Waternet passed 17/17 checkpoints over 94
  frames, Untangle passed 47/47 over 401 frames, and Rubido passed 30/30 over
  70 frames. Generic Plasma matched its instruction, trace, branch-fast, and
  W4IR counters over 10 frames.
- Target-47 `compareI32` shrank from 266 to 254 code bytes. The complete
  counterless `WasmInterpreter.class` shrank from 52,751 to 52,739 bytes.
  Diagnostic and counterless `execute` remained 7,039 and 7,007 code bytes.
  Persistent heap and W4IR format were unchanged. Station and base release
  JARs each grew by one byte because ZIP compression changed, to 228,103 and
  225,589 bytes.
- The candidate verification artifact was
  `c55d646ce4ca68991948b6b97124d488ddbf44a8cc2da3a85834314dce46921f`;
  station and base JAR hashes were
  `bca87973dc3278f5323a84e941862759c304ceba3057757403defc64684c01df`
  and
  `74cca579200527cc32c7ce4ff3c2e9d29359b4cff174f50afb20fd9cbd692ff3`.
- Clean timing snapshots were baseline commit
  `f4c824b1433ee831609caabe30bbce5627c50350` and temporary candidate commit
  `3cd3074591306e3087b241eb176513ee415d9873`. Their complete staged
  counterless tree hashes were
  `57fd453b47a4153b0c3d7ac983e85ea51341183a710e1b7d6d793bf25cf08a51`
  and
  `598221b48da3a1ad006125d9cf13e1dfca9015c97d9a670ee52ee9b56b33dd58`.
  Their counterless interpreter-class hashes were
  `ca4644d8ef04fdd8625f28ded3d2e434f3fb0af915ce8886f23db38a397e59c5`
  and
  `e69d32998f9fd853b4096d1f29a51e16f6823a0d98a0b8420dfff66d78e6e103`.

**Native i686 phoneME A/B.** Eight balanced generic Plasma pairs used 10
compute frames per invocation. Timer resolution was 100 us/frame, source
snapshots were clean, and every invocation reported exactly 50,492,866 logical
instructions, 110,662 trace calls, and 331,986 trace iterations:

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 1,168,200 | 1,183,200 |
| 1 | candidate first | 1,155,800 | 1,167,600 |
| 2 | baseline first | 1,169,800 | 1,194,400 |
| 3 | candidate first | 1,160,100 | 1,178,100 |
| 4 | baseline first | 1,150,800 | 1,171,100 |
| 5 | candidate first | 1,151,200 | 1,184,700 |
| 6 | baseline first | 1,155,600 | 1,165,600 |
| 7 | candidate first | 1,170,400 | 1,164,300 |

The median paired delta was -16,500 us/frame, or **-1.418%**, with one win and
seven losses. This decisively failed the predeclared +0.8% primary gate.
Additional game timing could not make the primary gate pass, so the Waternet,
Untangle, and Rubido controls were not spent after their exact sanity runs.
The phoneME harness has no routed Duck Maze checkpoint workload, so its
single-idle-frame path was not treated as a meaningful timing control. Raw
receipts and the pair CSV are retained under
`/tmp/w4me-njit003.g1fuw2/evidence/` for the lifetime of this host session.

**Decision.** Reject and remove the candidate. The arithmetic identity,
semantic coverage, and bytecode reduction are real, but the production-shaped
class is repeatably slower on the authoritative no-JIT runtime. The most
plausible unresolved cause is whole-class or handler-layout sensitivity;
shorter Java bytecode is not sufficient evidence of lower phoneME wall time.
No production commit is made.

**Reconsideration condition if rejected:** only a different branch-free
32-bit comparison lowering, evidence that whole-class layout rather than the
helper caused the verdict, or a more precise target-device measurement method.

The focused candidate fixture and production expressions were removed exactly.
The restored stable tree then passed `just verify`: diagnostic `execute`
returned to 7,039 bytes, counterless `execute` returned to 7,007 bytes, both
release JARs were preverified at 228,102 and 225,588 bytes, and the
seven-workload counterless full-state matrix remained exact. The stable
counterless verification artifact is again
`3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`.
No production commit was made for NJIT-003.

### NJIT-004: short-local parameter layout for the outer executor

**Status:** `rejected`.

**Hypothesis and source.** Java bytecodes have one-byte `aload_0..aload_3` and
`iload_0..iload_3` forms, while a load from a higher local slot uses a
two-byte generic opcode plus an operand. The native i686 phoneME portable-C
interpreter also gives the short forms materially smaller handlers: the
current binary contains 33-byte `aload_1`/`iload_1` handlers and 51-byte
generic `aload`/`iload` handlers. The generic handlers additionally fetch the
local index from the bytecode stream, advance by two bytes, scale the index,
and save/restore a native register.

The current private `execute` signature assigns slots as follows:

| Slot | Parameter | Static target-47 loads |
| ---: | --- | ---: |
| 1 | `functionIndex` | 2 |
| 2 | `body` | 21 |
| 3 | `functionType` | 10 |
| 4 | `locals` | 64 |
| 5 | `functionStackBase` | 12 |
| 6 | `functionControlBase` | 10 |

The same counts occur in diagnostic and counterless target-47 artifacts.
Consequently the current three short parameter slots cover 33 static loads,
while the two hottest generic parameters account for 76.

Three independent reviews selected the same minimal layout: swap only
`functionIndex` and `locals`, yielding
`execute(long[] locals, FunctionBody body, FuncType functionType, int
functionIndex, int functionStackBase, int functionControlBase)`. This leaves
every other parameter in its current relative order, moves 64 `locals` loads
to `aload_1`, and moves only two `functionIndex` loads to generic `iload 4`.
It therefore replaces a net 62 generic parameter loads in the method body with
short forms and should shrink `execute` by about 62 code bytes. Sorting all
parameters by frequency could save only two additional bytes while mixing
three same-typed integer arguments, so it is deliberately excluded.

**History and dynamic selection evidence.** The signature has kept its
current order since the interpreter first appeared in commit `bd3c374`.
Repository and OpenSpec history contain no earlier parameter-layout A/B.
The preserved exact format-15 outer profile is selection evidence rather than
a current timing verdict. Even before counting fused W4IR handlers, standard
`local.get`, `local.set`, and `local.tee` account for 185,867 dispatches
(14.25%) on the Waternet browser route, 2,493,657 (19.81%) on Rubido,
25,066,556 (17.46%) on generic Plasma, 127,123 (11.87%) on Untangle, and
20,561 (4.15%) on Duck Maze. Each such outer handler loads the `locals`
parameter; many existing fused handlers load it multiple times. Waternet and
Untangle execute no compact blocks on the retained route and therefore expose
the outer parameter layout directly. Compact and trace executors are separate
methods and are intentionally unchanged.

**Affected files and mechanism.** Change only the argument order at the sole
private call site and method declaration in `WasmInterpreter`. Every argument
at the call site is already a side-effect-free local variable. Update the two
method-extraction matchers in `tools/verify.sh` to recognize the private
`execute` method independently of its first parameter type; this is a gate
repair, not production behavior. No expression, handler, data representation,
W4IR/cache format, counter, trap point, or persistent allocation changes.

**Expected benefit and risks.** Expected benefit is a small but broad reduction
in interpreted bytecode work on outer-executor workloads, with Waternet as the
primary real-game judge. The candidate should have zero persistent-heap delta,
reduce method/class/JAR size slightly, and increase bytecode headroom. Risks
are whole-class or call-site layout sensitivity on phoneME, a benefit below
timer resolution, a loss from moving the rarely used index parameter, and an
accidental mismatch between declaration and the sole call site. All parameters
are category-1, so compiler temporary slots 7 through 129 do not move. The
method is private, has no overload or reflective caller, and does not recurse
directly.

**Baseline identity.**

- source commit:
  `f4c824b1433ee831609caabe30bbce5627c50350`;
- stable counterless verification artifact:
  `3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Planned verification and measurements.**

- Compile target 47 and inspect the exact signature, parameter slots, short and
  generic load counts, `execute` size, dense `tableswitch`, StackMap, class
  size, JAR size, and heap delta.
- Run `just test` and `just verify`; require the complete seven-workload
  full-state differential, budget/trap fixtures, release integrity,
  Java 1.3, CLDC bootclasspath, preverification, and relevant KEmulator gates.
- Build clean hash-bound counterless baseline and candidate snapshots and
  require byte-identical deterministic phoneME fields before timing.
- Run at least eight balanced native i686 phoneME pairs on the Waternet browser
  route as the primary gate. If it passes, run eight-pair no-regression controls
  on Untangle, Rubido, and generic Plasma. Use current routed frame counts for
  games and 10 compute frames for Plasma.

**Acceptance rule.** Require at least +0.8% median paired improvement on
Waternet, at least six wins in eight pairs, exact behavior, and no resolved
regression worse than -0.5% on Untangle, Rubido, or generic Plasma. Static
handler and bytecode reductions cannot accept the candidate by themselves.

**Correctness and artifact results before timing.**

- `just test` and `just verify` passed. Both release JARs were preverified, all
  10 bundled cartridges passed release integrity checks, and the seven-workload
  full-state matrix remained exact, including memory, globals, framebuffer,
  instruction counters, traps, branches, calls, and cached W4IR.
- Target-47 produced the planned descriptor
  `execute(long[], FunctionBody, FuncType, int, int, int)`. Its parameter-load
  histogram is 64 `aload_1` for `locals`, 21 `aload_2` for `body`, 10
  `aload_3` for `functionType`, two generic `iload 4` for `functionIndex`, 12
  `iload 5` for `functionStackBase`, and 10 `iload 6` for
  `functionControlBase`.
- Diagnostic `execute` shrank from 7,039 to 6,976 code bytes; counterless
  `execute` shrank from 7,007 to 6,944. Both retain a dense `tableswitch`.
  The diagnostic interpreter class shrank from 52,867 to 52,804 bytes and the
  counterless class from 52,751 to 52,688 bytes. Persistent heap use and W4IR
  format are unchanged.
- The candidate counterless verification artifact is
  `4021d7919f58fd418a47207782aeaee2a61b61c4211c99dc443fe6c15c439aa0`.
  Station and base release JARs are 228,093 and 225,579 bytes, with hashes
  `77ce72197eb4703f1c28ae6d2a7cd2e73267b5c2f02e7931699021cf5e422700`
  and
  `b81d7a2231438a5567df93396c01ea03453a4f795be33b554934582e591e91e9`.

**Clean snapshot identity and phoneME sanity.** The clean baseline was commit
`f4c824b1433ee831609caabe30bbce5627c50350`; the temporary candidate was
commit `e9aa5dc042377750e75f225f04933f61d013eda9`. Their complete staged
counterless tree hashes were
`d7ca20dcf808c12a33395ca144db5310e4685cd42688e6a4a726fc57d8982017`
and
`58aacecd2c32f21ecf4ce7fef490ab576bcb4e365c0ced330ae7d7b769d954c9`.
The preverified interpreter-class hashes were
`ca4644d8ef04fdd8625f28ded3d2e434f3fb0af915ce8886f23db38a397e59c5`
and
`9a8c22f0f3e10f810d9aa4269455fef67cb4d5184a7ee4d4606a58f391e3484f`.
A one-repetition native Waternet sanity run passed all 17 checkpoints and
matched every deterministic field.

**Native i686 phoneME A/B.** Eight balanced Waternet pairs used the complete
94-frame browser route per invocation. Timer resolution was 6.536 us/frame,
source snapshots were clean, and every invocation reported exactly 1,650,956
logical instructions and the same branch-fast payload:

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 20,483 | 20,320 |
| 1 | candidate first | 20,326 | 20,594 |
| 2 | baseline first | 20,542 | 20,477 |
| 3 | candidate first | 20,535 | 20,483 |
| 4 | baseline first | 20,594 | 20,457 |
| 5 | candidate first | 20,431 | 20,326 |
| 6 | baseline first | 20,339 | 20,248 |
| 7 | candidate first | 20,562 | 20,359 |

The median paired delta was 98 us/frame, or **+0.481%**, with seven wins and
one loss. The sign is credible, but the magnitude is below the predeclared
+0.8% acceptance floor. Additional controls cannot make the primary gate pass,
so Untangle, Rubido, and Plasma timing pairs were not spent. Raw receipts and
the pair CSV are retained under `/tmp/w4me-njit004.c8UYAO/evidence/` for the
lifetime of this host session.

**Decision.** Reject and remove the candidate. The short-load mechanism,
bytecode and class-size reduction, exact semantics, and small positive wall
effect are all confirmed, but a sub-half-percent gain does not justify
source-order churn and a verification-tool dependency under the goal's
conservative sub-percent policy. No production commit is made.

The production and verification-tool changes were removed exactly. The
restored stable tree then passed `just verify`: diagnostic `execute` returned
to 7,039 bytes, counterless `execute` returned to 7,007 bytes, both release
JARs were preverified at 228,102 and 225,588 bytes, and the seven-workload
counterless full-state matrix remained exact. The stable counterless artifact
is again
`3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`.
No production commit was made for NJIT-004.

**Reconsideration condition if rejected:** only a different slot assignment
supported by dynamic reference counts, evidence that class layout rather than
the local-load mechanism caused the verdict, or a more precise physical-device
measurement method.

### NJIT-005: folded scalar effective-address guard

**Status:** `rejected`.

**Hypothesis and source.** WebAssembly memory operands contain an unsigned
32-bit static offset. A scalar load or store computes the effective address
from that offset and the unsigned 32-bit dynamic base and traps when any byte
of the access is outside linear memory. W4ME stores both bit patterns in signed
Java `int` values, so a negative Java value is necessarily outside the fixed
64-KiB memory but must not be confused with a valid signed address.

The current scalar guard is exact:

```java
int maximumBase = module.memory.length - size;
if (base < 0
        || offset < 0
        || base > maximumBase
        || offset > maximumBase - base) {
    throw new WasmTrap("out-of-bounds memory access");
}
return base + offset;
```

For every current caller, `size` is one of 1, 2, 4, or 8 and therefore
`maximumBase` is in 65,528 through 65,535. After rejecting a set sign bit in
either operand, both operands are nonnegative and
`base > maximumBase - offset` is exactly equivalent to
`base + offset > maximumBase`, without first performing a possibly overflowing
sum. The isolated candidate is consequently:

```java
if ((base | offset) < 0 || base > maximumBase - offset) {
    throw new WasmTrap("out-of-bounds memory access");
}
```

`maximumBase - offset` cannot overflow after the sign guard: its minimum is
greater than `Integer.MIN_VALUE`. The returned addition cannot overflow on the
successful path because the second comparison has already proved that its
result is at most 65,535. This is the same algebra used by bounds-check
elimination in small fixed memories; the WebAssembly 1.1 binary, syntax, load,
and store specifications are the semantic authority. Java's defined wrapping
integer arithmetic is accounted for explicitly rather than used as an
unsigned-address shortcut.

Three independent read-only reviews converged on this two-branch form. A
target-47 scratch compilation measured the current helper at 48 code bytes and
23 successful-path JVM bytecodes with four conditional branches. The
candidate is 40 bytes and 20 JVM bytecodes with two conditional branches.
The retained i686 phoneME binary has 30-byte `ior` and `isub` handlers,
95-byte `iflt`/`ifge` handlers, and 103-byte integer-compare branch handlers.
This proves that three Java bytecode dispatches and two branch handlers are
removed from every successful helper call; it does not prove a wall-time
speedup.

**Scope and alternatives.** Change only `checkedAddress` in the first isolated
candidate. Its 37 `address` call sites and 16 direct call sites cover ordinary,
compact, fused, and trace scalar accesses. Two outer-executor W4IR loops contain
manually inlined copies of the old four-condition guard. They remain unchanged
so the first A/B measures one helper implementation rather than a helper plus
hot-loop specialization. If the helper passes, applying the same algebra to
those two loops is a separate candidate.

Bulk `memory.init`, `memory.copy`, and `memory.fill` stay out of scope. Their
length is dynamic, zero length admits an address at exactly the memory end, and
their source/destination trap order differs from scalar accesses. Also
excluded are an early `base + offset` check, which can accept a double-wrapped
address; `try`/`catch`, which can expose Java exceptions or partially write a
multi-byte store; a `long` unsigned sum, which restores measured ILP32
conversion costs; and predecoded unconditional traps, which would change the
persisted W4IR representation.

**Dynamic selection evidence.** The retained exact seven-workload profile is
format 15 rather than current format 16, so it is selection evidence, not the
timing artifact. The intervening direct-branch format change does not alter
the scalar memory instruction definitions. On the complete browser routes it
records 1,578,959 scalar memory operations on Rubido (10.176% of logical
instructions, 22,557 per frame), 88,076 on Waternet (937 per frame), and
126,451 on Untangle (315 per frame). Generic Plasma executes at least
20,514,986 helper-backed accesses over 60 frames after accounting for fused
instructions and excluding the two manual-guard handlers. The candidate saves
three target-JVM bytecode dispatches per covered access. Rubido is the primary
game gate; Plasma is a high-coverage control rather than a substitute for a
game result.

**Correctness risks and focused gates.**

- Preserve all valid final-byte boundaries for widths 1, 2, 4, and 8 and trap
  one byte beyond them for base-only, offset-only, and split base-plus-offset
  addresses.
- Cover bit patterns `-1`, `Integer.MIN_VALUE`, and `Integer.MAX_VALUE`,
  unsigned offsets `0x80000000` and `0xffffffff`, and additions that would
  overflow a signed Java `int`.
- Require the exact `WasmTrap("out-of-bounds memory access")`, never a Java
  array exception.
- Prove that a failed width-2, width-4, or width-8 store changes no byte.
  Preserve the intentional non-atomic ordering of fused sequences containing
  several distinct Wasm stores.
- Exercise outer and compact scalar paths and sweep budgets across the
  instruction immediately before the memory operation. The dispatcher's
  budget trap must continue to win before address evaluation.
- Keep the complete memory, globals, table, logical instruction count, cache,
  release, CLDC, and MIDP gates exact.

Checksum-valid cached operands may contain any 32-bit value because persisted
W4IR pages are integrity-checked but not re-decoded semantically. The guard
must therefore remain correct for every `int` bit pattern. This algebra-only
change does not alter W4IR format 16, cache fingerprints, instruction
accounting, trap position, stack order, or persistent heap.

**Baseline identity.**

- source commit:
  `f4c824b1433ee831609caabe30bbce5627c50350`;
- stable counterless verification artifact:
  `3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Planned commands and measurements.** Add a focused Wasm fixture and
host/CLDC-compatible smoke covering the matrix above, then run `just test` and
`just verify`. Inspect target-47 `javap`, helper and `execute` code sizes,
dense-switch shape, class/JAR sizes, preverification, and persistent heap.
Create clean, hash-bound counterless baseline and candidate snapshots and
first run one native phoneME Rubido sanity repetition for deterministic-field
identity. The primary verdict uses at least eight balanced native i686 pairs
on the complete 70-frame Rubido route. Only if it passes, run eight-pair
Waternet, Untangle, and generic-Plasma no-regression controls.

**Acceptance rule.** Require at least +0.8% median paired improvement on
Rubido, at least six wins in eight pairs, exact behavior, and no resolved
regression worse than -0.5% on any control. Method-size reduction and
theoretical handler savings cannot accept the candidate. A primary result
below the floor is rejected without spending control timing.

**Correctness and artifact results.** The focused fixture covers every scalar
load and store family, widths 1, 2, 4, and 8, the final valid byte, first
invalid byte, split addresses, signed-negative `u32` representations, signed
addition overflow, failed multi-byte stores, outer and compact execution, and
budget-before-address ordering. It passed with exact trap strings, logical
instruction counts, full memory, globals, and table state.

`just test` and `just verify` passed after the fixture was integrated. All
three browser replay oracles, all seven full-state workloads, Java 1.3,
CLDC-only compilation, classfile major 47, StackMap preverification, both
release JARs, cache checks, audio, storage, and MIDP gates remained green.
The counterless full-state artifact is
`2263114cb6ead98dd978f3852787370518726917ffd5fb5e76bf85d0e1e0272d`.

Target-47 confirmed the scratch prediction exactly: `checkedAddress` shrank
from 48 to 40 code bytes. Diagnostic `WasmInterpreter.class` shrank from
52,867 to 52,859 bytes; counterless from 52,751 to 52,743 bytes. Preverified
counterless class size shrank from 79,340 to 79,332 bytes. Diagnostic and
counterless `execute` remained 7,039 and 7,007 bytes respectively, both with
dense `tableswitch`. Station and base release JARs became 228,101 and 225,587
bytes, one byte smaller each. W4IR format and persistent heap are unchanged.

**Clean snapshot identity and native sanity.** The baseline snapshot is clean
commit `f4c824b1433ee831609caabe30bbce5627c50350`; the temporary candidate
snapshot is clean commit `d35a76baa31e77102c6a29d57246f496cfe3afb5`.
Their staged counterless phoneME artifacts are
`b9b388cf624fb8a7c65e0f22649bcc5d90175ca25c1a3464735e2138bc9a8a54`
and
`9e00523e860635b39ee43d96872c6ce5547a4f0b04b070e6cd14fd93c91be9cd`.
Their preverified interpreter-class hashes are
`ca4644d8ef04fdd8625f28ded3d2e434f3fb0af915ce8886f23db38a397e59c5`
and
`16e1f32ddbcd2b070b93bbdb286ffe50b485c600e659dacc31c26b9e48604509`.
A one-repetition native sanity run passed all 30 Rubido checkpoints and
matched all deterministic fields at 15,515,777 logical instructions.

**Native i686 phoneME A/B.** Eight balanced pairs used the complete 70-frame
Rubido browser route, counterless production-shaped artifacts, and the native
i686 no-JIT VM. Timer resolution was 14.286 us/frame. Every invocation passed
30 checkpoints and reported identical logical instructions and direct-branch
payload:

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 72,628 | 71,757 |
| 1 | candidate first | 71,857 | 71,800 |
| 2 | baseline first | 72,400 | 71,100 |
| 3 | candidate first | 71,800 | 71,671 |
| 4 | baseline first | 71,671 | 71,485 |
| 5 | candidate first | 71,571 | 71,800 |
| 6 | baseline first | 71,371 | 70,871 |
| 7 | candidate first | 72,157 | 71,757 |

The median paired delta is 293 us/frame, or **+0.407%**, with seven wins and
one loss. The positive sign is credible and the result is timer-resolved, but
the effect is only half the predeclared +0.8% acceptance floor. Waternet,
Untangle, and Plasma control timing cannot make the primary gate pass and was
therefore not spent. Raw invocations, pair CSV, receipts, and summary are under
`/tmp/w4me-njit005.325Jgx/evidence/` for the lifetime of this host session.

**Decision.** Reject and remove the candidate. The algebra, target bytecode
reduction, exact behavior, and small native phoneME improvement are all
confirmed, but a 0.407% median does not justify retaining a standalone helper
rewrite under the goal's conservative sub-percent policy. The focused oracle
is candidate-specific and will be removed with the implementation rather than
adding permanent test surface for a rejected optimization. No production
commit is made.

The production, fixture, and test-runner changes were removed exactly. The
restored stable tree then passed `just verify`: diagnostic `execute` returned
to 7,039 bytes, counterless `execute` returned to 7,007 bytes, release JARs
returned to 228,102 and 225,588 bytes, and all seven counterless full-state
workloads remained exact. The stable counterless artifact is again
`3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`.

**Reconsideration condition if rejected:** only an independently measured
caller-inline form that removes the nested Java call frame, a separate
manual-guard specialization with materially higher dynamic coverage, or a
more precise physical-device measurement method.

### NJIT-006: direct imported-call W4IR opcode

**Status:** `rejected`.

**Hypothesis and source.** A validated direct WebAssembly `call` currently
enters the same 919-byte target-47 `callFunction` method used by defined
functions. On the successful numeric-import path it executes the range and
profiling prologue, loads a nullable `FunctionBody`, checks call-depth and
intrinsic conditions for defined functions, resolves the function type,
checks the argument stack, passes two Plasma-only gates, and only then reaches
the host import. Target-47 `javap` counts 85 JVM instructions, 13 branches,
19--20 `getfield` operations, three array loads, and the mandatory
`invokeinterface` on this import path after the outer `call` handler's own
`invokespecial`. The retained i686 phoneME C interpreter sends method calls
through its VM call machinery and does no JIT inlining.

The isolated candidate adds one `W4IR_DIRECT_HOST_CALL` opcode and lowers only
a statically decoded `call` whose function index is below the validated import
count. It must retain the original imported function index as its operand.
That identity is required for profiling, duplicate imports, string-dispatch
fallback, the validated function signature, and fail-closed cached-W4IR
checks. `call_indirect` remains unchanged because its table target and
signature traps are dynamic.

Three independent read-only reviews agreed that this is materially different
from the retained numeric-host-ID implementation. The older change only
replaced the `String.equals` chain inside host dispatch; its corrected paired
effects were +0.530% Waternet, -0.220% Rubido, and +0.196% Untangle and it was
not accepted as a speed claim. `git log -S` found no previous direct imported
call lowering.

**Narrow implementation.** Add original opcode `0x1033`, extend the dense
execution mapping by one slot, and change W4IR format 16/14 to 17/15. Reuse the
post-decode direct-call specialization pass that already recognizes numeric
intrinsics. The new opcode stays outside compact and trace execution, so the
outer dispatcher continues to charge and check its single logical instruction
before any host side effect.

The first safe prototype keeps the function index as the authoritative
metadata and delegates to one import-only helper shared by the specialized
opcode and the malformed/unspecialized direct-call fallback. The helper must:

1. reject an out-of-range or defined-function operand with `WasmTrap` before
   profiling, stack mutation, or host activity;
2. increment the same `functionCallCounts[functionIndex]` slot before argument
   underflow checking;
3. derive parameter and result counts from the validated
   `module.functionTypes[functionIndex]`, never from untrusted packed cache
   metadata;
4. leave arguments on `values` while calling the existing numeric or string
   `WasmHost.invoke` overload;
5. set `valueTop` to the argument base only after a successful host return,
   then use the existing `push(long)` behavior for one result;
6. propagate host traps without wrapping, rollback, hidden instruction charge,
   or fallthrough to the next guest instruction.

This deliberately rejects the faster-looking raw-`hostId` or packed
`hostId/arity/result` handler for the first experiment. RMS pages have
integrity checks but do not semantically revalidate every token, and
`Wasm4Runtime.invoke(int, ...)` indexes arguments immediately. Trusting forged
metadata could therefore expose Java array exceptions, the wrong host import,
or a changed stack effect. If the safe form fails only because its remaining
metadata work dominates, a separately recorded candidate may investigate
one-time cache validation and an inline trusted form.

**Dynamic selection evidence.** The retained exact seven-workload profile is
W4IR format 15, so it is historical selection evidence rather than the timing
artifact. Import counts were independently mapped from the current
cartridges. It records:

- Duck Maze: 16,991 direct host calls over 155 frames, 109.619 per frame and
  100% of dynamic direct calls;
- Waternet browser route: 14,476 over 94 frames, exactly 154 per frame and
  45.67% of direct calls; 14,368 are `blitSub`;
- Waternet idle: 780 over 60 frames, 13 per frame;
- Rubido: 2,134 over 70 frames, 30.486 per frame and 5.62% of direct calls;
- Untangle: 34,265 over 401 frames, 85.449 per frame and 64.76% of direct
  calls;
- Plasma Cube and the retained Game of Life frame: zero host calls.

Waternet is the primary game gate because it has the highest host-call rate
and is close enough to the 60-FPS budget for a small improvement to matter.
Duck Maze and Untangle are high-coverage controls; Rubido is a low-coverage
no-regression control. Static analysis predicts no persistent heap or W4IR
stride growth, one four-byte dense `tableswitch` slot, and roughly 100--160
bytes of handler/helper code. The current counterless `execute` is 7,007
bytes against the 7,800-byte ceiling. These estimates select the experiment;
they do not establish a speedup.

**Correctness and cache gates.**

- Cover all allowed WASM-4 import arities and both void and i32-result imports,
  duplicate import names, a defined direct call, and an imported
  `call_indirect` that remains opcode `0x11`.
- Exercise both numeric-ID and string fallback dispatch and assert exact
  import identity, argument base/count/order, lower-stack preservation, result
  placement, and profile counts.
- Sweep the budget immediately before the call; a denied instruction must
  produce no host call or side effect. A host trap must preserve its class and
  text, must not execute the following guest instruction, and must retain the
  baseline instruction count and stack-mutation order.
- Exercise an import called from the maximum legal defined-function depth; it
  must not consume an additional call frame.
- Compare resident build, new-format paged build/hit, page promotion, and exact
  streams. Reject and rebuild the previous format. Check checksum corruption
  and checksum-valid specialized tokens with negative, defined-function, and
  one-past-import operands; all must fail with `WasmTrap` before host or stack
  side effects.
- Preserve every existing invalid-import, indirect-table/type, lifecycle,
  full-state, framebuffer, audio, disk, trace, Java 1.3, CLDC, target-47,
  StackMap, dense-switch, release-JAR, and MIDP gate.

**Baseline identity.**

- source commit:
  `f4c824b1433ee831609caabe30bbce5627c50350`;
- stable counterless verification artifact:
  `3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Correctness and artifact results before timing.** The isolated
implementation lowers a decoded direct imported `call` to original W4IR
opcode `0x1033`, retains the import function index as its only operand, and
uses a guarded import-only helper. Unspecialized and indirect imported calls
retain the generic `callFunction` entry and share the same helper after the
dynamic target and type checks.

- `just test` and `just verify` passed. The new focused fixture covers 13
  specialized sites; direct imports with arities 1, 2, 3, 4, 6, and 9; void
  and i32 results; duplicate names; numeric-ID and string dispatch; a defined
  direct-call fallback; an imported `call_indirect`; lifecycle imports; exact
  budget boundaries; host traps; paged build/hit behavior; and malformed
  cached operands. It observed seven direct and one indirect host execution
  with exact arguments, stack placement, profile counts, and side effects.
- The seven-workload full-state matrix remained exact at W4IR format 17.
  Release JARs remained target-47, preverified, dense-`tableswitch`, and passed
  cartridge, MIDP, license, and diagnostic-exclusion checks.
- Diagnostic `execute` grew from 7,039 to 7,055 code bytes; counterless
  `execute` grew from 7,007 to 7,023. The new counterless helper is 222 code
  bytes. The unpreverified counterless `WasmInterpreter.class` grew 52,751 to
  53,041 bytes and `WasmModule.class` grew 34,723 to 34,818 bytes.
  Preverification changed those sizes from 79,340 to 79,689 and from 45,352
  to 45,464 bytes respectively. Release JARs grew by 208 bytes each, to
  228,310 and 225,796 bytes.
- No field, array, W4IR token, or metadata stride was added. Persistent runtime
  heap is unchanged; only the cache format version and opcode value change.
  The complete candidate counterless exactness artifact is
  `efd5ff52587a0915fa114a82388faa68a4ef4901467dec83e61029d24004aa52`.
- Clean temporary snapshots are baseline
  `f4c824b1433ee831609caabe30bbce5627c50350` and candidate
  `067017bd8119f8bef057bc37341df46ef683c00e`. Their Waternet-staged
  counterless tree hashes are respectively
  `d7ca20dcf808c12a33395ca144db5310e4685cd42688e6a4a726fc57d8982017`
  and
  `785e81dbe24fcfafd4c6c0bcaead9e2417a22519815b16c84e9727e8b0eec162`.
  The snapshots, bytecode dumps, and raw receipts are retained under
  `/tmp/w4me-njit006.xz5nyr/` for the lifetime of this host session.

**Planned commands and verdict.** Implement the focused fixture and smoke,
then run `just test` and `just verify`. Inspect target-47 `javap`, diagnostic
and counterless `execute` sizes, dense `tableswitch`, class/JAR sizes,
preverification, W4IR cache invalidation, and persistent heap. Create clean,
hash-bound baseline and candidate counterless snapshots. First prove exact
fields with one native phoneME sanity repetition, then run at least eight
balanced pairs on the complete Waternet route. Require at least +0.8% median,
at least six wins in eight pairs, exact checkpoints and counters, and no
resolved regression worse than -0.5% on Duck Maze, Untangle, or Rubido.
Reject without controls if Waternet is decisively below the floor. Record raw
pairs and receipt paths before retaining or removing the implementation.

**Native i686 phoneME A/B.** One clean sanity repetition for each artifact
matched every deterministic Waternet field after normalizing only the expected
W4IR format 16 versus 17. The primary gate then ran eight balanced pairs over
the complete route plus 60 extra frames, 153 frames per invocation. Every
invocation passed 17 checkpoints and reported exactly 3,521,339 logical
instructions, zero optional diagnostic dispatch counters, and identical
branch-fast metadata.

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 20,281 | 20,398 |
| 1 | candidate first | 20,588 | 20,418 |
| 2 | baseline first | 20,464 | 20,444 |
| 3 | candidate first | 20,215 | 20,274 |
| 4 | baseline first | 20,450 | 20,692 |
| 5 | candidate first | 20,313 | 20,529 |
| 6 | baseline first | 20,509 | 20,588 |
| 7 | candidate first | 20,300 | 20,254 |

The median paired delta was -69.0 us/frame, or **-0.339%**, with three wins
and five losses. Timer resolution was 6.536 us/frame, order was balanced, and
both source snapshots were clean. Raw outputs, the pairs CSV, and the paired
summary are retained under `/tmp/w4me-njit006.xz5nyr/evidence/`.

**Decision.** Reject and remove the implementation. The safe import-only
helper eliminated the unrelated defined-function prologue and preserved every
semantic gate, but it added a W4IR opcode, format bump, method, and artifact
growth for a measured Waternet regression. The primary gate is both below the
+0.8% floor and negative, so Duck Maze, Untangle, and Rubido control timing
cannot make the candidate acceptable and was not spent. Do not repeat this
safe metadata-derived helper. A future packed or inline host-call handler is a
materially different candidate only if it first validates cached metadata
once, remains fail-closed for malformed W4IR, and removes the extra Java
method frame that this candidate retained.

### NJIT-007: exception-backed `push` capacity guard

**Status:** `accepted`.

**Hypothesis and source.** Every successful generic `push(long)` first checks
`valueTop >= values.length`, then performs a `lastore` whose JVM semantics and
phoneME C handler independently perform the same array bounds check. A
target-47 Java 1.3 prototype shows 18 JVM instructions in the current
successful path and 12 in a `try`-guarded path. After phoneME field-access
quickening, the defensible target mechanism is about four fewer interpreted
handlers per successful push: two quickened field loads, `arraylength`, and
the compare branch. Java exception tables are metadata and phoneME searches
them only after a failing array access, so the valid path does not execute an
additional catch-dispatch bytecode.

This candidate does not remove runtime stack protection and does not trust the
Wasm validator or persisted W4IR. It replaces one explicit capacity check with
the JVM's mandatory `lastore` bounds check and converts only the resulting
high-side failure back to the existing
`WasmTrap("value stack exhausted")`. Raw removal of `push`, `pop`, or `peek`
guards is rejected: fresh Wasm is validated, but an RMS W4IR cache hit skips
semantic decode and stack validation, and the fixed 4,096-slot value stack is
shared across nested calls while the validator limits each function
independently.

Three independent read-only reviews selected `push` as the first isolated A/B.
`pop` would remove only three successful-path JVM instructions while growing
its method, and `peek` has low dynamic coverage. Combining them would hide
which guard paid. Compact handlers with their own inline guards are unchanged.
The old wrapper-only `popFirst`/`popSecond` experiment remains rejected and is
not repeated.

**Dynamic selection evidence.** A temporary counter-only tree at
`/tmp/w4me-njit007-counts.OPgwzb/` changed only three diagnostic counters,
their getters, helper-entry increments, and receipt output. It was compiled
with Java 1.3 and run under HotSpot only to count deterministic route
coverage; none of its wall times are evidence:

| Workload | Routed frames | `push` calls | Calls/frame | `pop` calls | `peek` calls |
| --- | ---: | ---: | ---: | ---: | ---: |
| Waternet | 153 | 2,132,141 | 13,935 | 1,742,746 | 80,839 |
| Rubido | 129 | 16,421,546 | 127,299 | 14,727,036 | 337,538 |
| Untangle | 460 | 827,269 | 1,798 | 586,450 | 27,225 |

All route checkpoints and deterministic counters passed. The unmodified source
hashes used for selection were
`69657e2d937a85804ee07274e502fd06b1fa9ac38f2054b5da57f0676ffc28c3`
for `WasmInterpreter.java` and
`160d4d5f0c44b81e10ba1f2b62e0deb069184ba797b2685b903bc3055d1ccc1e`
for `PhoneMeRouteBench.java`. Waternet is the primary real-game gate because
it executes about 13,935 covered writes per frame and remains near the
60-FPS boundary. Rubido is a higher-coverage compute/game control; Untangle
is the low-coverage no-regression control.

**Affected file and exact mechanism.** Change only
`WasmInterpreter.push(long)`. The successful path is:

```java
try {
    values[valueTop++] = value;
    return;
} catch (ArrayIndexOutOfBoundsException failure) {
    if (valueTop > values.length || valueTop == Integer.MIN_VALUE) {
        valueTop--;
        throw new WasmTrap("value stack exhausted");
    }
    throw failure;
}
```

The post-increment occurs before `lastore`. For an old top in
`[values.length, Integer.MAX_VALUE - 1]`, the new top is above the array
length; decrement restores the exact old value before throwing the existing
Wasm trap. For `Integer.MAX_VALUE`, post-increment wraps to
`Integer.MIN_VALUE`; the explicit equality recognizes that case and decrement
again restores the old value. For a negative old top, the current method
allows `lastore` to throw Java `ArrayIndexOutOfBoundsException` after
incrementing the field. The candidate rethrows that same failure without
rollback, preserving even this unsupported private-field-corruption behavior.
No other array access or method call is inside the protected bytecode range.

The normal guest invariant remains `0 <= valueTop <= values.length`: reset
starts at zero; call argument bases, control entry, transfers, direct branches,
compact raw decrements, and compact raw increments validate their ranges
before assigning; RMS branch metadata is range-checked when loaded; cached
W4IR tokens cannot write `valueTop` directly; and hosts do not receive the
interpreter. The all-`int` failure handling above avoids relying on that
invariant for observable equivalence.

**Expected benefit and risks.** The Waternet selection count corresponds to
about 55,740 fewer quickened phoneME handler dispatches per frame; Rubido has
roughly nine times that coverage. This is a selection estimate only. The
candidate retains the `invokespecial` helper frame and 64-bit `lastore`, so the
real effect may remain below the +0.8% acceptance floor or change sign through
class layout. No field, array, allocation, W4IR token, cache format, or
persistent heap object is added. Expected artifact growth is only exception
metadata and constant-pool entries. Failure becomes deliberately slower
because phoneME must create or obtain an array exception, search the exception
table, and then create the same Wasm trap.

Correctness risks are a widened catch range, failure to restore the exact top
on full or integer-wrapped overflow, converting a negative-index Java
exception into a Wasm trap, changing trap text or order, classfile-47
preverification failure, whole-class layout regression, and accidentally
changing compact inline guards. The candidate must preserve instruction
budget and diagnostic ordering because `push` itself does not charge an
instruction.

**Baseline identity.**

- source commit:
  `f4c824b1433ee831609caabe30bbce5627c50350`;
- stable counterless verification artifact:
  `3378a78eacab9d4271adad5bedda954570e81f0673ddaafc3e167a7019d1bcfc`;
- station release JAR:
  `da61cf43640dd20a8c65c7cde6746d038c1cb428e0526a590b7ad7ef49d3920e`;
- base release JAR:
  `5ec791eb2a0a363da36c268f711a362014f5dad244dc56870c3c68b5d7d7a3dc`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Pre-implementation proof.** The exact all-`int` scratch candidate is under
`/tmp/w4me-njit007-exact-probe/`. It compiled with
`javac -source 1.3 -target 1.3 -bootclasspath
.local/phoneme/classes.zip`, passed `.local/phoneme/preverify`, produced
classfile major 47 with a CLDC StackMap, and passed natively on the i686
phoneME VM for top values `0`, `length - 1`, `length`, `length + 1`,
`Integer.MAX_VALUE`, `-1`, and `Integer.MIN_VALUE`.
`javap -c -p -verbose` shows a 0--17 protected range ending immediately after
`lastore`, no successful-path `if*`, and a catch of exactly
`ArrayIndexOutOfBoundsException`.

**Planned correctness and artifact gates.**

- Add a focused package-level helper smoke that compares the current oracle
  and candidate for valid writes, full-stack exhaustion, high and negative
  synthetic tops, exact throwable class/message, and post-failure top.
- Exercise sequential writes at the capacity edge, nested caller/callee
  exhaustion, and checksum-valid malformed cached W4IR that pushes past
  capacity. Preserve checksum failure, budget-before-effect, host-failure, and
  compact inline-guard behavior.
- Run `just test` and `just verify`, including all seven full-state workloads,
  resident/paged/promoted cache paths, exact traps and counters, both release
  JARs, MIDP gates, Java 1.3, CLDC bootclasspath, target-47, and preverification.
- Inspect unpreverified and preverified target-47 `push` bytecode, exception
  range, StackMap, method/class/JAR sizes, diagnostic and counterless
  `execute` headroom, W4IR format, and persistent heap delta.

**Planned timing and acceptance.** Build clean, hash-bound counterless baseline
and candidate source snapshots with no runtime selection branch. First run
one native i686 phoneME checkpoint sanity repetition on Waternet, Rubido, and
Untangle and require every deterministic field to match. Then run at least
eight balanced pairs on the complete Waternet route plus 60 frames. Accept
only with at least +0.8% median paired improvement, at least six wins in eight
pairs, timer-resolved effects, and exact checkpoints and counters. If Waternet
passes, run at least eight Rubido and Untangle no-regression pairs and reject
any resolved regression worse than -0.5%. Static bytecode savings, HotSpot
counts, or a Rubido-only improvement cannot accept the candidate.

**Correctness and artifact results.** The retained source passed `just test`
and `just verify`, including the focused seven-state private-helper oracle,
validated nested-call exhaustion, checksum-valid paged and promoted malformed
W4IR overflow, all seven full-state workloads, release-JAR validation, MIDP
integration gates, and counterless exactness. The focused smoke reports:

```text
PASS value-stack-push-guard helper-edges=7 nested-overflow=PASS cached-paged-promoted=PASS
```

The counterless exactness artifact is
`3f05ae2e49c1b378760030179d2a813d95e8b487249e78485d1c592836bdb904`.
Its seven full-state routes are exact, with W4IR format 16 unchanged. Both
diagnostic and timed builds remain below the `execute` gate at 7,039 and 7,007
bytes respectively, unchanged from the baseline. No field, array, or
persistent object was added, so the persistent heap delta is zero.

Target-47 `javap` on the clean timed artifacts confirms the intended shape.
The baseline `push` is 40 code bytes and its successful path contains 18 JVM
instructions, including the explicit capacity branch. The candidate is 63
code bytes including its cold handler, while its 0--17 successful path contains
12 JVM instructions and no `if*`. Its exception table catches only
`ArrayIndexOutOfBoundsException` over bytecodes 0--17, ending immediately after
`lastore`; the preverified class contains the corresponding CLDC StackMap.
The unpreverified `WasmInterpreter.class` grows from 52,751 to 52,840 bytes
(+89), and the preverified class from 79,340 to 79,458 (+118). The station and
base release JARs grow by 69 bytes each, from 228,102/225,588 to
228,171/225,657. Their retained hashes are
`282e5f7154c06e9fda1816ac647141b8c8f3859ffd6661ece520ce5429581a31`
and
`fc732c49593d628eb1fb83cb7805c68f5a473839077e6fdd69387729a622431a`.

**Clean timing artifacts.** The native window used two clean local snapshots
under `/tmp/w4me-njit007.zQhTOP/`. The baseline is commit
`f4c824b1433ee831609caabe30bbce5627c50350`; the isolated candidate snapshot
is `4ea74aff7b1592324fa201c0acf6ac66239c37f7`. The only production difference
between them is `WasmInterpreter.push(long)`. Their counterless preverified
artifact hashes are:

- baseline:
  `f16654bea8d953f3f378f443e93c1625b1abdd927748cf96ae7e42dd037978ce`;
- candidate:
  `c0ce61e7731a458eb72e44c9d260f2391ff29d5eaf9375af33b7cf416cc05754`.

Both receipts report `source-dirty=no`, Java source/target 1.3, the baseline VM,
CLDC, and preverify hashes above, counterless timed configuration, W4IR format
16, and exact checkpoint/counter fields. One preliminary invocation with
`--extra-frames 0` was invalid because one final checkpoint remained
unconsumed; it was discarded before timing. The required `--extra-frames 60`
sanity runs passed on Waternet, Rubido, and Untangle for both artifacts.

**Native i686 phoneME paired measurements.** Every row is a full route plus 60
frames under `=HeapCapacity64M`; order alternates within each eight-pair set.
All deterministic receipt prefixes match exactly. The timer is
`System.currentTimeMillis`; per-frame resolution is reported by the paired
statistics.

Waternet raw pairs:

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 20,248 | 20,084 |
| 1 | candidate first | 20,522 | 20,281 |
| 2 | baseline first | 20,418 | 20,307 |
| 3 | candidate first | 20,490 | 20,300 |
| 4 | baseline first | 20,424 | 20,333 |
| 5 | candidate first | 20,588 | 20,209 |
| 6 | baseline first | 20,522 | 20,222 |
| 7 | candidate first | 20,405 | 20,274 |

Result: median delta 177.0 us/frame, **+0.869%**, 8 wins, 0 losses,
6.536 us/frame timer resolution.

Rubido raw pairs:

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 103,573 | 101,914 |
| 1 | candidate first | 103,511 | 102,519 |
| 2 | baseline first | 103,930 | 102,031 |
| 3 | candidate first | 103,829 | 102,217 |
| 4 | baseline first | 102,899 | 102,069 |
| 5 | candidate first | 103,441 | 102,333 |
| 6 | baseline first | 103,426 | 101,852 |
| 7 | candidate first | 103,457 | 102,310 |

Result: median delta 1,360.5 us/frame, **+1.315%**, 8 wins, 0 losses,
7.752 us/frame timer resolution.

Untangle raw pairs:

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 4,773 | 4,723 |
| 1 | candidate first | 4,750 | 4,700 |
| 2 | baseline first | 4,763 | 4,767 |
| 3 | candidate first | 4,745 | 4,760 |
| 4 | baseline first | 4,752 | 4,734 |
| 5 | candidate first | 4,786 | 4,721 |
| 6 | baseline first | 4,771 | 4,765 |
| 7 | candidate first | 4,797 | 4,765 |

Result: median delta 25.0 us/frame, **+0.523%**, 6 wins, 2 losses,
2.174 us/frame timer resolution.

Raw files and paired summaries are retained under
`/tmp/w4me-njit007.zQhTOP/evidence/`. The exact commands were:

```sh
PHONEME_HOME=.local/phoneme tools/phoneme/run.sh bench \
  waternet rubido untangle --candidate counterless --reps 1 \
  --extra-frames 60
bash /tmp/w4me-njit007.zQhTOP/run-pairs.sh waternet 8 60
bash /tmp/w4me-njit007.zQhTOP/run-pairs.sh rubido 8 60
bash /tmp/w4me-njit007.zQhTOP/run-pairs.sh untangle 8 60
```

**Decision.** Accepted. Waternet exceeds the predeclared +0.8% floor with
8/8 wins; Rubido independently improves by +1.315%; Untangle has no
regression and instead shows a timer-resolved +0.523% median. Exact state,
trap behavior, Java 1.3/CLDC compatibility, bytecode headroom, cache paths,
release artifacts, and persistent memory all pass. Reconsider only if a
physical CLDC/MIDP device exposes materially different exception-table or
array-bounds behavior, or if a future whole-class layout change reverses the
paired native result.

### NJIT-012: short-local parameter layout for `executeCompactFused`

**Status:** `rejected`.

**Hypothesis and source.** The private compact-fusion helper currently has
descriptor `(IIII[J)I`. Its target-47 parameter slots are `opcode=1`,
`instruction=2`, `operand=3`, `auxiliary=4`, and `locals=5`. The phoneME
portable-C interpreter uses 33-byte handlers for the short
`aload_1..aload_3` and `iload_1..iload_3` bytecodes, but 51-byte handlers for
generic `aload` and `iload`; the generic form also fetches an index operand,
advances the bytecode PC by two, scales the index, and saves a native register.
Moving the dynamically hot `locals` reference into slot 2 and the colder
`instruction` value into slot 5 should therefore reduce work inside every
covered fused handler without changing the number of Java calls or JVM
dispatches.

This is materially different from rejected `NJIT-004`. That candidate
reordered parameters of the outer `execute` method and measured +0.481% on
Waternet, where compact execution was not active. This candidate affects only
`executeCompactFused`, has zero Waternet and Untangle coverage, and uses Rubido
as its primary workload. The earlier result supports the handler-cost
mechanism but also warns that this candidate may remain below the +0.8%
acceptance floor.

**Independent selection evidence.** Three read-only reviews confirmed a sole
private caller, category-1 arguments, no recursion or reflective entry, zero
format or heap effect, and the following target-47 load counts:

| Parameter | Current slot | Static loads |
| --- | ---: | ---: |
| `opcode` | 1 | 3 |
| `instruction` | 2 | 13 |
| `operand` | 3 | 49 |
| `auxiliary` | 4 | 33 |
| `locals` | 5 | 54 |

Deterministic route instrumentation measured 1,236,449 compact-fused calls on
Rubido over 70 frames. The selected swap removes 1,843,402 generic parameter
loads there, or 26,334 per frame. Generic Plasma executes 34,893,596 fused
calls over 60 frames and removes 34,421,052 generic loads. Game of Life
removes 786,740 in its measured frame. Waternet, Untangle, and Duck Maze
execute this helper zero times under the retained activation policy.

Two reviews recommend an isolated native A/B because the change is cheap and
the dynamic coverage is exact. One adversarial review recommends skipping it
because both `NJIT-004` and the broader compact-counter `NJIT-001` remained
below the acceptance floor. The conflict is resolved by a primary Rubido
native falsification rather than by treating bytecode counts as performance
proof.

**Affected files and mechanism.** Change only the sole call and declaration
in `WasmInterpreter` to:

```java
executeCompactFused(
        int opcode,
        long[] locals,
        int operand,
        int auxiliary,
        int instruction)
```

The swap keeps the switch selector in slot 1 and the hot operand in slot 3,
moves 54 `locals` loads from generic `aload 5` to `aload_2`, and moves only 13
`instruction` loads from `iload_2` to generic `iload 5`. A target-47 scratch
build reduced generic parameter loads from 87 to 46, helper code length from
1,376 to 1,335 bytes, and `WasmInterpreter.class` from 52,956 to 52,915 bytes.
The `tableswitch`, `max_stack=6`, `locals=49`, caller instruction lengths, and
persistent heap are unchanged. A temporary candidate already passed
preverification and seven-workload full-state differential checks, but those
results are selection evidence rather than the production gate.

**Risks.** Four `int` arguments can be mismatched between the call and
declaration while still compiling. Whole-class layout can outweigh the
mechanical bytecode saving, and the effect may be too small for the
conservative floor. No W4IR, RMS cache, trap, instruction-accounting, call,
stack, or memory semantics should change. The full exact-state and cached-path
matrix must nevertheless prove the argument mapping.

**Baseline identity.**

- source commit:
  `e65c2e61e07db2f230502840ec54ca7590411332`;
- stable counterless verification artifact:
  `3f05ae2e49c1b378760030179d2a813d95e8b487249e78485d1c592836bdb904`;
- station release JAR:
  `282e5f7154c06e9fda1816ac647141b8c8f3859ffd6661ece520ce5429581a31`;
- base release JAR:
  `fc732c49593d628eb1fb83cb7805c68f5a473839077e6fdd69387729a622431a`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Planned commands, workloads, and acceptance.** Compile with Java source and
target 1.3 against the phoneME CLDC bootclasspath, inspect target-47 and
preverified bytecode with `javap`, and run `just test` plus `just verify`.
Require exact seven-workload state, resident/paged/promoted cache behavior,
traps, budgets, release JAR integrity, preverification, and unchanged W4IR
format and persistent heap. Produce clean hash-bound counterless baseline and
candidate snapshots and first require matching native checkpoint and counter
fields.

The authoritative primary gate is eight balanced native i686 phoneME Rubido
pairs over the complete route plus 60 frames. Accept only at a median paired
improvement of at least +0.8%, at least six wins in eight pairs, and exact
deterministic outputs. If it passes, run Waternet and Untangle no-regression
controls and reject a resolved regression worse than -0.5%; generic Plasma is
only a high-coverage mechanism control. If Rubido decisively fails, do not
spend the controls. Raw pair values, artifact hashes, timer resolution, code
size, and final verdict must be recorded before removing or retaining the
candidate.

**Correctness and artifact results.** The isolated candidate passed
`just test` and `just verify`. The full seven-workload state matrix, cached and
resident W4IR paths, exact traps and budgets, both release JARs, Java 1.3,
CLDC API lint, classfile 47, preverification, and the release-integrity gates
all passed. W4IR format 16, diagnostic `execute=7,039`, counterless
`execute=7,007`, and persistent heap use were unchanged. The candidate
counterless verification artifact was
`4b9583484b7232477177fbac97bfd83fde19f4bbe3ea6d8381d6e40f1ec83512`.

The unpreverified counterless interpreter class shrank from 52,956 to 52,915
bytes and the preverified class from 79,458 to 79,417 bytes. Their preverified
class hashes were
`2259d3d6f20205993ecf2e33d2215171c2a38c8a377bdb6c28d41ae719a7c1ad`
and
`5bf23d877f81d639b74ee216a632b38d805cfec4ede1fd37bbc0bd84073dd008`.
The candidate station and base release JARs were 228,177 and 225,663 bytes,
six bytes larger than the retained JARs because of ZIP compression, with
hashes
`a76bd599c36136cd1acca2ed3605d1a859bb00d2be0c9cbad65a594d1df86f6f`
and
`7237bbd4f40e6b040d4a0b1d724b334a6e107a90cbe960af0f49586c537ff3c4`.

**Clean timing artifacts and sanity.** The clean snapshots were baseline
commit `e65c2e61e07db2f230502840ec54ca7590411332` and temporary candidate
commit `1b21063fe4848db299f94c1d260e5c3bdae4f909`. Their complete phoneME
artifact hashes were
`11fc13742f33e6d316df71493f0e2c04b4aa3a76e0cacea86d5705fe429a683c`
and
`db4a2e4d36654cd91bcdd7c4febc2696f79cd17e9c93af1ac63693dff1cbdde1`;
their counterless preverified artifact hashes were
`c0ce61e7731a458eb72e44c9d260f2391ff29d5eaf9375af33b7cf416cc05754`
and
`b26ff54bd981e48acc6d389bc6c3e3584522c84c5af23fe8698f24be0832e4d6`.
Both receipts report clean source, Java source/target 1.3, the baseline VM,
CLDC, and preverify hashes, W4IR format 16, and a 64-MiB heap. One native
sanity repetition on Waternet, Rubido, and Untangle passed every checkpoint
and matched all deterministic fields between artifacts.

**Native i686 phoneME A/B.** Eight balanced Rubido pairs used the complete
route plus 60 frames, 129 total frames per invocation. Every deterministic
receipt prefix was identical:

| Pair | Order | Baseline us/frame | Candidate us/frame |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 101,992 | 102,147 |
| 1 | candidate first | 102,651 | 102,527 |
| 2 | baseline first | 102,829 | 102,558 |
| 3 | candidate first | 102,488 | 102,302 |
| 4 | baseline first | 102,170 | 102,046 |
| 5 | candidate first | 102,751 | 102,511 |
| 6 | baseline first | 102,434 | 102,581 |
| 7 | candidate first | 102,286 | 102,232 |

The median paired delta was 124.0 us/frame, or **+0.121%**, with six wins and
two losses. Timer resolution was 7.752 us/frame, order was balanced, and the
source snapshots were clean. Raw receipts and statistics are under
`/tmp/w4me-njit012.rInVJH/evidence/` for the lifetime of this host session.
The exact primary command was:

```sh
bash /tmp/w4me-njit012.rInVJH/run-pairs.sh rubido 8 60
```

**Decision.** Reject and remove the candidate. The short-local handler
mechanism, expected 41-byte class reduction, exact semantics, and positive
wall-time sign are all confirmed, but +0.121% is 6.6 times below the
predeclared +0.8% floor and does not justify production source-order churn.
The primary gate decisively failed, so zero-coverage Waternet and Untangle
controls and the synthetic Plasma control were not spent. No production
commit is made.

Reconsider only with a physical-device measurement method that resolves and
values sub-percent effects, a combined layout change that removes JVM
dispatches rather than merely shortening handlers, or a future compact-tier
policy that greatly increases real-game coverage. The two production argument
order changes were removed exactly; the durable ledger result remains.

### NJIT-009: transform-free `blitSub` geometry loop

**Status:** `accepted`.

**Hypothesis and source.** WASM-4 uses flag bit 0 for 2-bpp sprites and bits
1, 2, and 3 for horizontal flip, vertical flip, and rotation. Calls satisfying
`(flags & 0x0e) == 0` therefore use the same unrotated, unflipped geometry for
both 1-bpp and 2-bpp sources. The current general inner loop nevertheless
performs four transform-dependent coordinate selections and recomputes
`sampledY * sourceStride` for every pixel. A transform-free loop can compute
source and destination row bases once per row and advance `targetX` and
`bitIndex` linearly.

This is the standard scanline specialization used by software rasterizers,
but the first candidate deliberately retains the existing packed-pixel decode,
draw-color transparency, and `drawPoint` call. It tests only geometry
specialization; framebuffer read-modify-write inlining, packed-byte reuse, and
transform-specific loops remain separate future candidates. Repository and
OpenSpec history contain no prior transform-free `blit` or `blitSub`
implementation or native A/B.

**Dynamic selection evidence.** A temporary instrumentation-only runtime under
`/tmp/w4me-njit009-counts.AXafZl/` counted calls, requested pixels, and clipped
pixels by the low four flag bits while executing the exact seven-workload
corpus. The instrumented full-state matrix remained exact. Its artifact is
`1f4a29f5dfaade366436ee210ab5540e4a512ecd92fb4b044b6d71d0747ce6ad`;
the complete report hash is
`b1b3aa269275254ef8128941694be5853a21fee61ad1c5f41ccb03aa2d19b7f2`
and the extracted summary hash is
`c0f50c80a43b792970c6fedf0067e7979761c259c41bc693f493c671a485fe17`.
No instrumentation is added to production.

| Workload and route | Plain calls | Plain clipped pixels | Per route frame |
| --- | ---: | ---: | ---: |
| Waternet browser, 94 frames | 14,368 | 1,899,520 | 20,207.66 pixels |
| Rubido browser, 70 frames | 1,631 | 715,347 | 10,219.24 pixels |
| Duck Maze, 155 frames | 157 | 40,192 | 259.30 pixels |
| Untangle browser, 401 frames | 368 | 7,248 | 18.08 pixels |

Waternet and Rubido use only transform-free flags in the recorded routes.
Untangle is the fallback control: 25,964 of its 26,332 total calls use
transforms, predominantly rotation, so it exposes the cost and exactness of
the additional guard while barely exercising the new loop. The native
phoneME timer includes `beginFrame`, guest `update`, and all runtime host
drawing calls, so it measures this rasterization. It does not include MIDP
framebuffer conversion, `drawRGB`, or `flushGraphics`.

Static target-47 inspection of the current loop confirms a general pixel body
from bytecode offsets 303 through 489. It evaluates rotate twice, flip-X once,
flip-Y once, multiplies the source row, selects 1-bpp versus 2-bpp, and invokes
`drawPoint` for every nontransparent pixel. The planned specialization removes
about 22 JVM bytecode dispatches from each plain pixel's geometry while
retaining the decode and destination helper. At Waternet coverage that is
roughly 445,000 fewer interpreted Java bytecodes per route frame. This is a
mechanism estimate, not a speedup claim.

**Affected files and isolated mechanism.** In `Wasm4Runtime.blitSub`, preserve
all current size, source-geometry, 64-bit extent, range, and clipping checks in
their current order. After clipping and `DRAW_COLORS` load, branch once on
`(flags & 0x0e) == 0`. The plain loop computes:

- `targetY = destinationY + yIndex` once per row;
- `targetX = destinationX + clipXMinimum` once per row;
- `bitIndex = (sourceY + yIndex) * sourceStride + sourceX +
  clipXMinimum` once per row;
- the unchanged packed source color, draw-color lookup, transparency check,
  and `drawPoint`, followed by linear increments.

The existing general loop remains byte-for-byte semantically responsible for
all flipped or rotated calls. A focused differential smoke will compare the
optimized host call against an independent copy of the original scalar
algorithm across all flags 0 through 15, both bpp modes, transparent and
opaque draw-color mappings, clipping on every edge, nonzero source origins and
strides, unknown high flag bits, extreme destination coordinates, and invalid
source geometry. It must prove exact framebuffer bytes and exact trap class
and text.

**Expected benefit and risks.** Waternet is the primary real-game judge because
it is near the 60-FPS budget and executes the highest plain pixel count.
Rubido is a high-coverage no-regression control. Untangle proves the transformed
fallback and guard cost. Expected benefit is a multi-percent reduction in
runtime rasterization work with no persistent allocation, W4IR/cache change,
or interpreter bytecode-headroom effect. Risks are a clipped source/destination
off-by-one, changing validation or trap order, mishandling 2-bpp bit indices,
changing transparency, a general-loop regression, runtime class/JAR growth,
and a wall-time effect smaller than the static dispatch reduction suggests.

**Baseline identity.**

- source commit:
  `e65c2e61e07db2f230502840ec54ca7590411332`;
- stable counterless verification artifact:
  `3f05ae2e49c1b378760030179d2a813d95e8b487249e78485d1c592836bdb904`;
- station release JAR:
  `282e5f7154c06e9fda1816ac647141b8c8f3859ffd6661ece520ce5429581a31`;
- base release JAR:
  `fc732c49593d628eb1fb83cb7805c68f5a473839077e6fdd69387729a622431a`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Planned gates and acceptance.** Run the focused differential, `just test`,
and `just verify`; require Java source/target 1.3, CLDC API lint, classfile 47,
preverification, exact seven-workload state, every replay framebuffer
checkpoint, unchanged W4IR/cache/trap/budget behavior, release JAR integrity,
zero persistent heap growth, and recorded runtime class/method/JAR deltas.
Build clean hash-bound counterless baseline and candidate snapshots and require
matching deterministic native receipt fields before timing.

Run at least eight balanced native i686 phoneME pairs on the complete Waternet
route plus 60 frames. Accept only at a median paired improvement of at least
+0.8% and at least six wins in eight pairs. If it passes, run eight-pair
Rubido and Untangle controls and reject a resolved regression worse than
-0.5%. KEmulator and physical-device rendering remain later integration gates,
but their JIT wall time cannot accept this pure Java candidate. Record all raw
pairs, hashes, timer resolution, size effects, and the final verdict before
retaining or removing the code.

**Correctness and artifact results.** The implementation adds only the plain
geometry loop and the focused `BlitPlainGeometrySmoke`; the transformed loop
and `drawPoint` remain unchanged. The smoke compared 518 independent cases
covering flags 0 through 15 plus unknown high bits, both bpp modes, clipping on
all sides, source/framebuffer overlap, transparency, `blit` delegation, and
exact trap/rollback behavior. `just test` and `just verify` passed, including
the seven-workload full-state matrix, all framebuffer checkpoints, Java
source/target 1.3, CLDC lint, classfile 47, preverification, release checks,
counterless exactness, cache, instruction budget, and persistent-memory gates.
The candidate counterless exactness artifact is
`7f09e54dab05a01dc4c11b4c0c4f219c982d9e3c355f1240a5d943854e1a1885`.
`WasmInterpreter.execute` remains 7,039 bytes diagnostic and 7,007 bytes
counterless.

The unpreverified `Wasm4Runtime.class` grows from 16,115 to 16,376 bytes
(+261); its preverified form grows from 21,691 to 22,255 bytes (+564).
`blitSub` grows from approximately 502 to 679 target-47 bytecode bytes and from
280 to 384 disassembled instructions. The station/base release JARs grow from
228,171/225,657 to 228,395/225,881 bytes (+224 each); their candidate hashes
are `d9422ce2cceee5d6ea525911829657f4210702aa6f7b6f46ae66a01a181d50aa`
and `c41f62be7c9773e34d174b19580295d392443301a4922aeb33e564b58015f35c`.
No field, allocation, cache, W4IR, or persistent-heap delta is introduced.

Clean snapshots under `/tmp/w4me-njit009.E4DIZE/` used baseline commit
`e65c2e61e07db2f230502840ec54ca7590411332` and an experiment commit containing
only `Wasm4Runtime.java`; the production source SHA-256 was
`76af888f1aa1e95f2f5257732c2b4befe88a9bee2bbcd6cab62f624ec8c0c5a3`.
The counterless phoneME artifacts were
`c0ce61e7731a458eb72e44c9d260f2391ff29d5eaf9375af33b7cf416cc05754`
baseline and
`61b1fd457d4fa331093eb23620529f8b62226ab2c62a3954c3928f1d3aa9fbae`
candidate. The build receipts additionally bind their complete build artifacts
as `11fc13742f33e6d316df71493f0e2c04b4aa3a76e0cacea86d5705fe429a683c`
and `26a2ae617763e6caa3ad807014a4faf3fc459ff5bb593077b73ab70933d68adb`.
Every timed pair matched frames, checkpoints, logical instructions, disabled
diagnostic counters, branch metadata, W4IR format, and all other deterministic
receipt fields.

The exact command used to build each clean artifact was:

```sh
PHONEME_HOME=./.local/phoneme \
  ./tools/phoneme/run.sh bench waternet rubido untangle \
  --candidate counterless --reps 1 --extra-frames 60
```

The paired runner invoked `PhoneMeRouteBench <cart> optimized 60 1 counterless
<sample>` directly on the native i686 VM, alternating baseline-first and
candidate-first. Raw results in microseconds per frame were:

| Pair | Waternet B/C | Rubido B/C | Untangle B/C |
| ---: | ---: | ---: | ---: |
| 0 | 20,294 / 18,954 | 102,131 / 101,496 | 4,734 / 4,700 |
| 1 | 20,202 / 19,300 | 102,534 / 101,689 | 4,710 / 4,741 |
| 2 | 20,032 / 19,352 | 102,798 / 102,263 | 4,747 / 4,743 |
| 3 | 20,209 / 19,287 | 102,302 / 101,829 | 4,745 / 4,726 |
| 4 | 20,267 / 19,176 | 102,286 / 101,620 | 4,821 / 4,773 |
| 5 | 20,411 / 19,209 | 102,232 / 102,240 | 4,802 / 4,878 |
| 6 | 20,254 / 19,372 | 102,364 / 101,806 | 4,706 / 4,754 |
| 7 | 20,294 / 19,333 | 102,248 / 102,054 | 4,752 / 4,773 |
| 8 | — | — | 4,721 / 4,797 |
| 9 | — | — | 4,723 / 4,756 |
| 10 | — | — | 4,756 / 4,771 |
| 11 | — | — | 4,802 / 4,728 |
| 12 | — | — | 4,710 / 4,804 |
| 13 | — | — | 4,754 / 4,782 |
| 14 | — | — | 4,765 / 4,763 |
| 15 | — | — | 4,782 / 4,804 |

Waternet measured +4.649% median (941.5 us/frame, 8/8 wins; timer resolution
6.536 us/frame), comfortably above the predeclared +0.8% and 6/8 gate. Rubido
measured +0.533% (546.5 us/frame, 7/8; resolution 7.752 us/frame). The first
eight Untangle pairs landed at -0.486%, too close to the -0.5% rejection line,
so the control was conservatively extended to 16 pairs. Its final median was
-0.451% (-21.5 us/frame, 6/16; resolution 2.174 us/frame), inside the
predeclared no-regression limit and consistent with the expected one-guard
fallback cost.

KEmulator integration also passed the exact Waternet 94-frame, Rubido
70-frame, and Untangle 401-frame routes. The first Untangle wrapper invocation
returned `java.io.IOException: Bad file descriptor` after its worker log had
already reached the exact final checkpoint; after stopping the stale session,
an immediate clean repeat produced the normal wrapper PASS. This was an
infrastructure failure, not a cartridge or framebuffer mismatch.

**Verdict:** accepted. The isolated scanline geometry specialization produces
a repeatable 4.649% improvement on the high-coverage Waternet route, slightly
improves Rubido, remains within the predefined transformed-fallback control
limit, preserves exact behavior, and has a small fixed code-size cost with no
persistent-memory cost.

### NJIT-014: inline plain-blit framebuffer read-modify-write

**Status:** `accepted`.

**Hypothesis and source.** The accepted NJIT-009 loop still invokes the private
`drawPoint(byte[], int, int, int)` helper for every nontransparent plain-blit
pixel. Target-47 `javap` shows a 57-byte helper plus an `invokespecial` at
`blitSub` offset 436. The helper computes the packed framebuffer byte, shift,
mask, read-modify-write, and returns. phoneME quickens the call site but still
executes its `fast_invokespecial`, frame entry, and return machinery on every
draw. The byte-identical phoneME source/disassembly study attributes roughly
135 i686 instructions to this fixed call/return path, while its native
microbench found about 36 ns saved by inlining one representative small
two-argument helper. That magnitude is shape- and layout-sensitive and is only
motivation for a route A/B, not evidence of a W4ME speedup.

A temporary instrumentation-only profile under
`/tmp/w4me-njit014-profile.mZXvAW/` counted plain pixels, opaque destination
writes, and bpp mode on the exact corpus. It preserved the full seven-workload
state matrix. The artifact is
`7e25249ea4a8d4a0c14d04e1ddfe2aa0e437dfcd673a65550d875a965d153dce`;
the complete report hash is
`d903835056b5b061e8daab389cacc1dd804eac9a96d189fc435b543e8bc0c378`
and the extracted summary hash is
`015ef128df36581e62ea0d84515d9eacc9f285302da1e56034d9dc56f497e4b1`.
No counters or getters are added to production.

| Workload and route | Plain pixels | Opaque draws | Opaque draws/frame |
| --- | ---: | ---: | ---: |
| Waternet browser, 94 frames | 1,899,520 | 1,795,296 | 19,098.89 |
| Rubido browser, 70 frames | 715,347 | 583,629 | 8,337.56 |
| Duck Maze, 155 frames | 40,192 | 40,192 | 259.30 |
| Untangle browser, 401 frames | 7,248 | 4,727 | 11.79 |

Waternet writes 94.51% of its plain pixels and Rubido writes 81.59%, so this
candidate removes about 19,099 and 8,338 Java calls per frame respectively.
Untangle remains the transformed-path control and has negligible dynamic
coverage. A naive multiplication of the helper microbench by Waternet coverage
suggests a sub-millisecond opportunity, but the real inlined body uses
high-numbered locals in the already large `blitSub`; only native paired timing
can determine whether call removal outweighs that local-layout cost.

An independent read-only target-47 prototype under
`/tmp/w4me-njit014-research.WYfkOz/` recommends the same isolated candidate
with only two new locals, `address` and `shift`. Its `blitSub` grows from about
679 to 719 bytes and from 384 to 413 disassembled instructions; the
unpreverified/preverified runtime classes grow from 16,376/22,255 to
16,424/22,303 bytes. `max_stack=7`, `max_locals=37`, and classfile major 47
remain unchanged. The opaque-pixel path falls from 10 caller instructions plus
40 helper instructions to 39 inlined instructions: 11 fewer Java bytecode
dispatches as well as no call-frame entry or return. A four-local translation
was rejected before implementation because it raised `max_locals` to 39 for no
semantic benefit.

**Affected files and isolated mechanism.** Change only the nontransparent
branch of the already accepted `(flags & 14) == 0` loop. Replace
`drawPoint(memory, (drawColor - 1) & 3, targetX, targetY)` with the exact helper
body:

- `address = FRAMEBUFFER + ((WIDTH * targetY + targetX) >> 2)`;
- `shift = (targetX & 3) << 1`;
- the same byte read-modify-write with `((drawColor - 1) & 3)` and
  `~(3 << shift)`.

Do not split the 1-bpp and 2-bpp loops, cache packed source bytes, convert
`targetX` into a row-running framebuffer index, alter clipping, or touch the
transformed fallback in this first comparison. Those are distinct candidates.
Preserving the existing source decode before the destination write also
preserves self-overlap behavior when sprite data aliases the framebuffer.

The existing independent `BlitPlainGeometrySmoke` compares the entire 64-KiB
memory after 518 cases covering both bpp modes, all low flag values, ignored
high bits, every clipping side, transparent and out-of-range color nibbles,
source/framebuffer address overlap, `blit` delegation, extreme coordinates,
and exact traps. Review found that its overlap geometry does not actually
overwrite a source byte before that byte is sampled. Add two true
alias-feedback cases at `pointer=FRAMEBUFFER`, destination `(0,0)`, size `8x1`,
source `(0,0)`, stride 8, and flags 0/1. The scratch prototype passes all 520
cases. This expanded smoke is the focused differential; no production-visible
test hook is needed.

**Expected benefit and risks.** The expected useful range is roughly 1-3% on
Waternet and smaller positive movement on Rubido. Risks are omitting the
`& 3` color normalization, changing packed-bit shift semantics, evaluating a
framebuffer address before transparency, changing source-overlap order,
inflating `blitSub` or the release JAR, and losing the call saving to generic
high-local loads or phoneME layout bimodality. There is no new allocation,
field, persistent heap, W4IR, cache, interpreter bytecode, or transformed-path
branch.

**Baseline identity.**

- source commit:
  `7967206f4776e66957d6859b72f01f85f24c4cb5`;
- counterless exactness artifact:
  `7f09e54dab05a01dc4c11b4c0c4f219c982d9e3c355f1240a5d943854e1a1885`;
- station/base release JAR:
  `d9422ce2cceee5d6ea525911829657f4210702aa6f7b6f46ae66a01a181d50aa`
  /
  `c41f62be7c9773e34d174b19580295d392443301a4922aeb33e564b58015f35c`;
- `Wasm4Runtime.class`: 16,376 bytes unpreverified and 22,255 bytes
  preverified; `blitSub`: approximately 679 target-47 bytes;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Planned gates and acceptance.** Inspect target-47 bytecode to prove that the
plain branch loses its `drawPoint` invoke and record exact method/class/JAR
deltas. Run the focused 520-case differential, `just test`, and `just verify`;
require Java 1.3, CLDC lint, preverification, seven-workload exact state,
framebuffer oracles, trap/budget/cache equivalence, release integrity, and zero
persistent heap growth.

Build clean hash-bound counterless snapshots from commit `7967206` and the
one-file candidate. Run at least eight balanced native i686 phoneME Waternet
pairs over the complete route plus 60 frames. Accept only at median paired
improvement of at least +0.8% with at least six wins in eight. If it passes,
run eight Rubido and Untangle control pairs and reject a resolved regression
worse than -0.5%. Repeat a borderline control rather than deciding at the
threshold. Record all raw pairs and the final verdict before retaining or
removing the implementation.

**Verification, bytecode, and artifact results.** The focused smoke now covers
520 cases, including the two destructive source/framebuffer alias cases, and
passes with complete 64-KiB memory equality and exact traps. `just test` and
`just verify` pass, including all seven full-state workloads, framebuffer,
audio, validation, storage, Java 1.3, CLDC lint, preverification, release, and
counterless gates. The candidate removes the plain-loop `drawPoint` invoke;
the only remaining invoke in `blitSub` is the unchanged transformed fallback.
Target-47 `blitSub` grows from 679 to 719 bytes and 384 to 413 disassembled
instructions while `max_stack=7`, `max_locals=37`, and classfile major 47 stay
unchanged. The counterless unpreverified/preverified `Wasm4Runtime.class`
grows from 16,376/22,255 to 16,424/22,303 bytes. Diagnostic/counterless
`WasmInterpreter.execute` remains 7,039/7,007 bytes. There is no allocation,
field, W4IR, cache-format, or persistent-heap delta.

The final verification artifacts are:

- counterless exactness:
  `c8aaef8a534307dca81d3c2f9e22e534361f73980f9dd2d002fb45bbc5240ac4`;
- station/base release JAR:
  `be9767e87532b131f175344ef4df2f24c1e394d96471c900d8bafddfc9a016ac`
  /
  `9e3abf78534b8117fc16b44a5354dcbf2351ec0a0fdaa1ed1f4650ea709dde3`,
  228,427/225,913 bytes;
- candidate unpreverified/preverified runtime class:
  `4bf80334856d6a74b58e49f02b02b11c4ac87b2cad0924dca49a31f5cffd5fe1`
  /
  `0c6a61aa8dedfacf373c861a036c509b932e86ab6cb504454dfb922cdcdd0226`.

**Clean native artifacts and commands.** The A/B snapshots are under
`/tmp/w4me-njit014.Sop1F0/`. The baseline is clean commit
`7967206f4776e66957d6859b72f01f85f24c4cb5`; the clean temporary candidate
commit `03a3c59b99bf34fdf1c7951b15b23e859d27efe0` contains only the production
`Wasm4Runtime.java` hunk. Their counterless artifacts are
`61b1fd457d4fa331093eb23620529f8b62226ab2c62a3954c3928f1d3aa9fbae`
and
`afb6bb392f22ec824090858cff85863fab09c2e4b0c163e163b8ad274f8eff49`;
the complete build artifacts are
`26a2ae617763e6caa3ad807014a4faf3fc459ff5bb593077b73ab70933d68adb`
and
`ad5df1f974c539dcc4d24d5de62477d18f0735436681859113495ae3c246bc24`.
Both receipts report clean source, Java source/target 1.3, identical VM,
classes, preverify, route, oracle, and cartridge hashes, and a 64-MiB judge
heap. Each artifact was built and sanity-run with:

```sh
PHONEME_HOME=./.local/phoneme \
  ./tools/phoneme/run.sh bench waternet rubido untangle \
  --candidate counterless --reps 1 --extra-frames 60
```

The paired runner invoked
`PhoneMeRouteBench <cart> optimized 60 1 counterless <sample>` directly on the
native i686 no-JIT VM, alternating baseline-first and candidate-first. Every
pair matched frames, checkpoints, logical instructions, disabled diagnostic
counters, branch metadata, W4IR format, and every other deterministic receipt
field. Raw microseconds per frame were:

| Pair | Waternet B/C | Rubido B/C | Untangle B/C |
| ---: | ---: | ---: | ---: |
| 0 | 19,150 / 18,379 | 101,906 / 101,565 | 4,786 / 4,739 |
| 1 | 19,274 / 18,261 | 102,178 / 101,263 | 4,713 / 4,730 |
| 2 | 19,117 / 18,601 | 101,434 / 102,023 | 4,732 / 4,708 |
| 3 | 19,209 / 18,562 | 101,984 / 101,682 | 4,736 / 4,756 |
| 4 | 19,137 / 18,522 | 101,883 / 101,682 | 4,771 / 4,821 |
| 5 | 19,202 / 18,601 | 101,449 / 102,085 | 4,754 / 4,723 |
| 6 | 18,928 / 18,352 | 101,224 / 101,472 | 4,750 / 4,704 |
| 7 | 19,183 / 18,620 | 101,713 / 101,403 | 4,800 / 4,780 |

Waternet measures +3.172% median, 608.0 us/frame, and 8/8 wins, comfortably
above the predeclared +0.8% and 6/8 acceptance gate. Rubido measures +0.247%,
251.5 us/frame, and 5/8 wins. Untangle measures +0.462%, 22.0 us/frame, and
5/8 wins. Both controls are positive and therefore clear the -0.5%
no-regression limit. Timer resolutions were 6.536, 7.752, and 2.174
us/frame respectively.

KEmulator exact integration passed the 94-frame Waternet and 70-frame Rubido
routes normally. Two Untangle wrapper attempts both reached the exact final
401-frame receipt with all 47 checkpoints and framebuffer
`bc0231d9`, then the controller's post-run screenshot command returned
`java.io.IOException: Bad file descriptor`. The worker evidence is exact; the
failure is in the KEmulator controller after cartridge completion and is
recorded rather than hidden.

**Verdict:** accepted. Removing one private Java call per opaque plain-blit
pixel gives a repeatable +3.172% on the high-coverage Waternet route, does not
regress Rubido or the low-coverage Untangle control, preserves exact behavior,
and costs only 48 runtime-class bytes with no persistent memory.

### NJIT-015: running packed destination cursor for plain blits

**Status:** `accepted`.

**Hypothesis and source.** After NJIT-014, every opaque transform-free pixel
still recomputes
`FRAMEBUFFER + ((WIDTH * targetY + targetX) >> 2)` and
`(targetX & 3) << 1`. Target-47 emits an `imul`, two additions, a shift, an
`iand`, and another shift before the packed read-modify-write. The destination
coordinates are contiguous within one clipped row, so the packed byte address
and two-bit shift can instead be initialized once per row and advanced after
each pixel. This is the conventional scanline-cursor shape used by packed
framebuffer rasterizers; here it is a separate experiment from the accepted
geometry and helper-inlining changes.

The NJIT-014 exact profile remains the dynamic basis: Waternet processes
20,207.66 plain clipped pixels and 19,098.89 opaque writes per frame; Rubido
processes about 10,219 plain clipped pixels and 8,337.56 opaque writes per
frame; Untangle has only 18.08 plain pixels and 11.79 opaque writes per frame.
Thus Waternet and Rubido should avoid destination multiply/divide work on
thousands of pixels, while Untangle remains a low-coverage fallback control.
This is mechanism and coverage evidence only; no speedup is claimed before a
native paired A/B.

**Baseline identity.**

- source commit:
  `f30ffe25ac856652eb40153f1a418fbf95a607ee`;
- counterless exactness:
  `c8aaef8a534307dca81d3c2f9e22e534361f73980f9dd2d002fb45bbc5240ac4`;
- station/base release JAR:
  `be9767e87532b131f175344ef4df2f24c1e394d96471c900d8bafddfc9a016ac`
  /
  `9e3abf78534b8117fc16b44a5354dcbf2351ec0a0fdaa1ed1f4650ea709dde3`;
- runtime class: 16,424 bytes unpreverified and 22,303 bytes preverified;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Isolated mechanism.** In the accepted plain-row loop, initialize one
framebuffer byte address and one two-bit shift from the first clipped
destination pixel. Use those locals in the existing opaque write, then advance
the shift by two for every processed source pixel and increment the byte
address only when the shift wraps after four pixels. Remove only the now-dead
per-pixel `targetX` increment and destination address/shift calculation.
Preserve source decoding before any destination memory access, transparency,
row clipping, source validation and traps, 1-bpp/2-bpp behavior, the
transformed fallback, and the exact packed read-modify-write.

The first target-47 comparison must evaluate both a conditional wrap and a
branch-free carry shape before choosing one production prototype. A taken Java
branch reaches phoneME's timer-tick check, while a branch-free carry executes
more bytecodes on every pixel; static counts select the smaller credible
candidate but do not prove speed. Do not combine source-byte caching, 1-bpp
versus 2-bpp loop splitting, multi-pixel stores, or row unpacking in this A/B.

The isolated target-47 comparison selected the conditional rollover form.
Against the 719-byte, 413-instruction baseline `blitSub`, it produces a
732-byte, 419-instruction method; the branch-free carry form produces a
735-byte, 423-instruction method. Both retain `max_stack=7`,
`max_locals=37`, and classfile major 47. The selected form changes the
unpreverified runtime class from 16,424 to 16,449 bytes and the preverified
class from 22,303 to 22,381 bytes. Its opaque write falls from 39 to 23
target bytecodes, while cursor maintenance averages 7.75 bytecodes per
processed pixel plus 16 bytecodes per nonempty row. Applying those exact
counts to the retained coverage predicts about 229,804 fewer Java bytecode
dispatches per Waternet frame and 95,079 per Rubido frame before row setup;
this is still only mechanism evidence.

An independent source, target-bytecode, history, and alias review found no
previous attempt at this candidate and returned `GO` for the isolated native
A/B. It confirmed that the cursor must advance through transparent pixels,
must start from the clipped destination `x`, and must keep source decoding
before the destination read-modify-write. Source-byte caching and whole-byte
assembly remain excluded because framebuffer-backed sprites make sequential
alias feedback observable. The focused differential is expanded with a
destination beginning at packed shift one, mixed transparent/opaque 1-bpp and
2-bpp mappings, byte-boundary crossings, and destructive framebuffer aliasing
from destination `x=1`; the temporary candidate passed 874/874 cases and the
full host test suite before the same patch was applied to the working tree.

**Expected benefit and risks.** A useful result is expected in the 1-2% range
on Waternet, with a smaller Rubido benefit. The main risks are paying cursor
maintenance for transparent pixels, adding a taken branch every fourth pixel,
increasing `max_locals`, advancing the destination cursor in the wrong order,
or changing feedback when the sprite source aliases the framebuffer. The
existing 520-case full-memory differential includes destructive alias
feedback; add focused rows beginning at all four packed shifts and crossing
one or more byte boundaries if current cases do not distinguish cursor
rollover. There must be no field, allocation, persistent heap, W4IR, cache, or
interpreter-bytecode delta.

**Planned gates and acceptance.** Record exact target-47 method, instruction,
local, class, and preverified-class deltas for the chosen minimal form. Pass
the expanded plain-blit differential, `just test`, and `just verify`, including
Java 1.3, CLDC, full-state, framebuffer, traps, release, counterless, size, and
memory gates. Build clean hash-bound counterless snapshots from `f30ffe2` and
the one-file production candidate with:

```sh
PHONEME_HOME=./.local/phoneme \
  ./tools/phoneme/run.sh bench waternet rubido untangle \
  --candidate counterless --reps 1 --extra-frames 60
```

Run eight balanced native i686 Waternet pairs over the full route plus 60
frames. Accept only at median paired improvement of at least +0.8% with at
least six wins in eight. If it passes, run eight Rubido and Untangle controls;
reject a resolved regression worse than -0.5% and extend a borderline control.
Record every pair and remove the implementation if it fails.

**Correctness, compatibility, and artifact result.** The selected one-file
production candidate plus the focused test expansion passed:

- the 874/874 plain-blit full-memory differential, including every flag
  combination, mixed transparent/opaque mappings, clipped packed shifts,
  byte-boundary rollover, and destructive framebuffer overlap;
- all seven full-state workloads, framebuffer and browser-route oracles,
  traps, budget gates, Java 1.3/target 1.3 compilation, CLDC bootclasspath
  lint, target-47 inspection, preverification, release-JAR validation, and
  `just verify`;
- KEmulator Waternet (94 frames/17 checkpoints/14 tones), Rubido
  (70 frames/30 checkpoints), and Untangle (401 frames/47 checkpoints) with
  exact palette, input, framebuffer, and disk state.

The production target-47 class is 16,449 bytes with SHA-256
`3c51bb35ec61f14ea82e5ba3947c94678eaa5e88676854c89f40a5b7fda8845c`;
the release-preverified normalized class is 21,823 bytes with SHA-256
`2f3b61137b46d8b528bcd539f02c6bd629ad65276fb02c65222bc21cab6cfbe0`.
The complete station/base JARs are 228,434/225,920 bytes with SHA-256
`c854fa68c486442e56be58292e5ee49c26fa9c8b701c037ead28dd4ccd4c33a1`
and
`1c01a1437974ba51f74b205c58872ab9e231168d370fe9e923eaf66ca833b160`.
The final counterless exactness artifact is
`0bb15d039554d66b808d50141bc7181c58d468247bb1c323fff7396637300dab`;
`execute` remains 7,039 bytes in the diagnostic build and 7,007 bytes in the
counterless build. The change adds no fields, allocations, W4IR/cache bytes,
or persistent heap.

**Clean native i686 phoneME A/B.** Clean snapshots under
`/tmp/w4me-njit015.nBqekr/` compare source
`f30ffe25ac856652eb40153f1a418fbf95a607ee` with the isolated temporary
candidate `aa3141f`. The counterless artifacts are
`afb6bb392f22ec824090858cff85863fab09c2e4b0c163e163b8ad274f8eff49`
and
`85c103d781f790d225d2284b20142df9ef21bd6aa124016e3c2bd01b82f59c42`.
Their phoneME-preverified runtime classes are 22,303/22,381 bytes with
SHA-256
`0c6a61aa8dedfacf373c861a036c509b932e86ab6cb504454dfb922cdcdd0226`
and
`3a971082ce8d37a0c544020f4f9408afa00896ebc2d8531b3add040f714a9373`.
All deterministic receipt fields match in every pair.

| Sample | Waternet baseline/candidate µs/frame | Rubido baseline/candidate µs/frame | Untangle baseline/candidate µs/frame |
|---:|---:|---:|---:|
| 0 | 18,431 / 17,052 | 101,542 / 100,317 | 4,721 / 4,695 |
| 1 | 18,535 / 17,032 | 101,736 / 100,116 | 4,739 / 4,721 |
| 2 | 18,496 / 17,019 | 101,674 / 101,147 | 4,795 / 4,767 |
| 3 | 18,601 / 17,091 | 101,945 / 100,666 | 4,710 / 4,726 |
| 4 | 18,542 / 16,862 | 101,627 / 100,914 | 4,743 / 4,721 |
| 5 | 18,535 / 16,888 | 101,666 / 101,023 | 4,717 / 4,758 |
| 6 | 18,483 / 16,869 | 101,984 / 101,255 | 4,726 / 4,756 |
| 7 | 18,490 / 17,052 | 101,658 / 100,697 | 4,728 / 4,710 |

Waternet measures a median +1,506.5 µs/frame, **+8.113%**, with 8/8
wins. Rubido measures +845.0 µs/frame, **+0.830%**, with 8/8 wins. Untangle,
whose coverage is negligible, measures +18.0 µs/frame, **+0.380%**, with
5/8 wins and no resolved regression. Timer resolutions are 6.536, 7.752,
and 2.174 µs/frame respectively; order is balanced and both snapshots are
source-clean.

**Verdict.** Accept. The running packed cursor turns the static destination
address/shift saving into a repeatable +8.113% on Waternet and a smaller
+0.830% Rubido gain, while preserving exact behavior and avoiding a control
regression. The branch-free form is rejected as an implementation variant:
it is larger and executes more target bytecodes per pixel, so it was not
promoted to native A/B. Reconsider it only if a different target VM makes
taken conditional branches demonstrably expensive enough to overcome that
larger steady-state stream.

### NJIT-016: native reuse of adjacent upscaled ARGB rows

**Status:** `accepted`.

**Hypothesis and source.** `W4Canvas` builds nearest-neighbor `yMap` entries as
`index * 160 / side`, converted to packed framebuffer row offsets. At common
upscaled sides, adjacent destination rows therefore repeat the same source
row: 80 of 240 rows at side 240 and 16 of 176 at side 176. Nevertheless,
`Wasm4Runtime.copyArgbBand` currently re-runs the complete inner conversion
for every destination pixel. Its target-47 loop performs `yMap`/`xMap` loads,
packed framebuffer addressing, a byte load, `argbLookup`, and an `iastore`
for every repeated pixel. phoneME implements `System.arraycopy` for primitive
arrays in native code, so copying the already expanded preceding destination
row should replace thousands of C-interpreted Java bytecodes per presented
frame.

This candidate is the row-reuse half of the older queued `NJIT-008`; packed
byte expansion and repeated-column reuse remain separate ideas. The native
phoneME route benchmark does not call the MIDP renderer, so its normal
cartridge wall time cannot judge this change. The authoritative component
judge is instead a CLDC-clean `PhoneMeArgbBandBench` running the production
`prepareArgb`/`copyArgbBand` methods on the native i686 no-JIT VM. KEmulator
is retained only for the complete `W4Canvas`/`drawRGB`/`flushGraphics`
integration gate, and physical-device evidence overrides the component result
when available.

**Baseline identity.**

- source commit:
  `58f1469952f3ed1fbd9f096e8fd10ef08b03c16a`;
- counterless exactness:
  `0bb15d039554d66b808d50141bc7181c58d468247bb1c323fff7396637300dab`;
- station/base release JAR:
  `c854fa68c486442e56be58292e5ee49c26fa9c8b701c037ead28dd4ccd4c33a1`
  /
  `1c01a1437974ba51f74b205c58872ab9e231168d370fe9e923eaf66ca833b160`;
- runtime class: 16,449 bytes unpreverified and 22,381 bytes in the
  phoneME-preverified counterless tree; the complete baseline tree digest is
  `dd1cf262cc1963a08372d4ccbbad487695a1fec9b599d25635ce492f62246f27`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Prototype narrowing.** A first temporary prototype added a
`previousSourceRow` local and used `System.arraycopy` for every adjacent equal
row. It changed `copyArgbBand` from 156 bytes/86 target instructions/15
locals to 190 bytes/104 instructions/16 locals. Single exploratory native
runs at full-buffer presentation measured 6,105 -> 4,100 µs/frame at side
240 and 3,340 -> 2,883 at side 176, but 2,580 -> 2,683 at native side 160.
Those unpaired numbers are not a performance verdict; they exposed a material
no-upscale regression risk and superseded that implementation form.

A direct per-row `width > 160` guard avoided the extra local but still altered
the hot loop layout. A helper selected from inside `copyArgbBand` then
measured a borderline -0.575% median on twelve side-160 pairs. The current
production-shaped prototype therefore leaves the complete
`copyArgbBand` target bytecode identical and adds a separate public
`copyUpscaledArgbBand`; `W4Canvas` selects it only when `side > 160`. The new
method copies a row only when its `yMap` entry equals the immediately
preceding entry within the same band; otherwise it executes the canonical
conversion loop. This also handles the low-memory 16-row band renderer
without retaining another row or adding heap. Aliased output/map arrays fall
back to the canonical method because copying the first expanded row could
otherwise overwrite a later map entry. The final
target-47 shape is:

- unchanged `copyArgbBand`: 156 bytes, 86 instructions, `max_stack=6`,
  `max_locals=15`;
- `copyUpscaledArgbBand`: 222 bytes, `max_stack=6`,
  `max_locals=15`;
- runtime class: 16,851 bytes unpreverified and 23,034 bytes preverified;
- counterless phoneME candidate tree:
  `2e62a10d9ca6e7ec06544279cdf319f4d84593e972f06d2e3d29ddf2d4ca9c0c`,
  with runtime class
  `b5931d094fb473de8772e3b1d2e997907b0f2942bda027bf25cd9db0f5597b0b`;
- no new fields, persistent arrays, allocations, W4IR, cache, or interpreter
  bytecode.

**Native i686 phoneME A/B.** The fixed baseline/candidate class trees were
run through `/tmp/w4me-njit016.chLQ6O/run-render-pairs.sh SIDE BAND FRAMES
PAIRS`; every invocation checked the complete output FNV before appending a
pair and used `tools/phoneme/paired-stats.awk`. The reusable single-artifact
path is now:

```sh
tools/phoneme/run.sh bench waternet --reps 1
.local/phoneme/cldc_vm_r -EnableTicks =HeapCapacity64M \
  -classpath .local/phoneme/classes.zip:build/reports/phoneme/preverified \
  w4me.PhoneMeArgbBandBench 240 240 200 0
```

The latter reproduces `output-fnv1a=91a5116c`. Raw baseline/candidate
µs/frame pairs follow; order alternated on every row:

| Shape | Frames | Raw baseline/candidate pairs | Paired result |
|---|---:|---|---|
| 240/full | 200 | 6095/3900, 5945/3965, 5935/3985, 5935/4005, 5870/4010, 6055/4075, 5935/4030, 6080/4045, 5990/3960, 5915/3980, 5960/3995, 5940/4020 | **+32.785%**, +1957.5 µs, 12/12 |
| 240/band-16 | 200 | 6170/4165, 5860/4215, 5880/4120, 6025/4140, 5985/4195, 5855/4160, 6085/4175, 6080/4235, 5985/4215, 5860/4045, 5980/4070, 5990/4125 | **+30.659%**, +1830.0 µs, 12/12 |
| 176/full | 300 | 3193/2946, 3173/2960, 3133/2910, 3310/2916, 3196/2913, 3260/2916, 3146/2926, 3150/2940, 3190/2990, 3186/2903, 3173/2946, 3186/2943 | **+7.391%**, +235.0 µs, 12/12 |
| 176/band-16 | 300 | 3176/2956, 3103/2950, 3193/2960, 3183/2926, 3190/2926, 3193/2953, 3206/2950, 3286/2963, 3223/2953, 3233/2993, 3243/2876, 3173/2940 | **+7.751%**, +248.0 µs, 12/12 |
| 320/full | 100 | 11370/5330, 10810/5330, 10810/5330, 10480/5300, 11030/5300, 10540/5380, 10690/5320, 10470/5270 | **+50.464%**, +5425.0 µs, 8/8 |
| 161/full | 600 | 2663/2680, 2675/2716, 2671/2693, 2660/2681, 2695/2688, 2698/2698, 2690/2668, 2658/2693, 2681/2651, 2700/2693, 2680/2686, 2673/2678 | -0.205%, -5.5 µs, 4/7/1 |
| 160/full | 600 | 2621/2630, 2645/2646, 2696/2650, 2623/2643, 2591/2621, 2685/2633, 2673/2681, 2660/2633, 2600/2663, 2646/2650, 2666/2600, 2775/2640 | -0.094%, -2.5 µs, 5/7 |
| 128/full | 800 | 1716/1708, 1691/1678, 1685/1681, 1701/1701, 1702/1677, 1815/1696, 1711/1686, 1688/1693, 1683/1703, 1652/1772, 1767/1686, 1688/1695 | +0.352%, +6.0 µs, 7/4/1 |

Timer resolutions were 5.000, 3.333, 10.000, 1.667, and 1.250
µs/frame according to sample length. The temporary runner printed
`source-clean=yes`, but both detached snapshots contained their benchmark
source as an untracked file; that metadata bit is therefore not used as
evidence. The compiled trees were immutable throughout all pairs and are
identified by the complete tree digests above. All large positive effects
are many timer ticks, directionally unanimous, and repeat across full and
banded rendering. The 161/160/128 controls are conservatively classified as
no resolved effect and stay above the -0.5% rejection floor.

**Correctness and release gates.** `ArgbBandDifferentialSmoke` compared the
new method to `copyArgbBand` in 3,101 cases across sides 161/176/240/320,
band heights 1/2/15/16/17/full, zero/first/last/partial bands, repeated and
non-monotonic maps, two palettes, untouched output tails, invalid geometry,
and `pixels == xMap` / `pixels == yMap`; all outputs and exception gates
passed. `just verify` passed all replay/full-state/trap tests, target-47
builds, release validation, and counterless exactness. The final counterless
artifact is
`c7f2a189ab91b569ccc3461b772df4746d510541c4a9f050803a2f0673dbaf75`;
`WasmInterpreter.execute` remains 7,039 bytes in production and 7,007 in the
counterless build. Release artifacts are:

- station: 228,701 bytes,
  `863dc617ed578ed70170d0e7dd7ad5c3f225f2b4067c0ead9736092fa8277723`;
- base: 226,187 bytes,
  `579e0db0135cd2ebd667675069023acc5f28464d74f3dddc2f8340fc8859cd4b`.

KEmulator presentation controls also passed exact Waternet 94/94, Rubido
70/70, and Untangle 401/401 routes at the 176x220 phone layout. These are
MIDP correctness gates, not timing evidence. No physical-phone timing was
available.

**Verdict.** Accept. The separate-method boundary preserves native/downscale
target bytecode and has no persistent-heap cost, while native phoneME shows
a repeatable +7.4--7.8% conversion win at 176 and +30.7--32.8% at 240. The
measured percentages cover ARGB conversion only; they must not be reported as
whole-frame or physical-device speedups because `drawRGB`, `flushGraphics`,
the interpreter, and audio remain outside the component timer.

### NJIT-017: cache the packed framebuffer byte across an upscaled row

**Status:** `accepted`.

**Hypothesis and source.** The independent renderer bytecode review following
NJIT-016 found that the horizontal nearest-neighbor map repeats one packed
framebuffer byte across several destination pixels. A WASM-4 byte stores four
2-bpp pixels, so even native 160-wide conversion reads the same byte four
times; an upscaled 240-wide row reads each of its 40 packed bytes about six
times. NJIT-016 removes vertically repeated rows but its remaining 160 source
rows at side 240 still execute 38,400 `baload` operations instead of the
6,400 distinct packed-byte reads required. On phoneME every `baload`, address
calculation, bounds check, and JVM dispatch runs in the C interpreter.

The first isolated form changes only `copyUpscaledArgbBand`: within each
non-copied row it retains the previous packed-byte index and value, reloads
memory only when `(mapping & 0xff)` changes, and still uses the current
mapping's high bits to select the correct 2-bpp lane. `copyArgbBand` and the
native/downscale `W4Canvas` path remain bytecode-identical. Extending the same
mechanism to native/downscale conversion is a separate follow-up only if the
upscale result is accepted and a dedicated A/B justifies altering that loop.

**Baseline identity.**

- source commit:
  `191910ec34db9b5d3b4b645a69b23ef43eb9da5d`;
- counterless exactness:
  `c7f2a189ab91b569ccc3461b772df4746d510541c4a9f050803a2f0673dbaf75`;
- station/base JAR:
  `863dc617ed578ed70170d0e7dd7ad5c3f225f2b4067c0ead9736092fa8277723`
  /
  `579e0db0135cd2ebd667675069023acc5f28464d74f3dddc2f8340fc8859cd4b`;
- runtime class: 16,851 bytes target-47 and 23,034 bytes in the
  phoneME-preverified tree;
- `copyArgbBand` / `copyUpscaledArgbBand`: 156 / 222 bytes;
- native i686 VM, CLDC classes, and preverify:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`,
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`,
  and
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Expected benefit and risks.** The candidate adds two scalar locals and one
integer comparison per computed destination pixel, but removes five of six
packed-byte loads at side 240 and more than four of five at side 176. It adds
no fields, arrays, allocations, W4IR, cache data, or persistent heap. The main
risks are that phoneME's taken/not-taken branch and larger method frame cost
more than the saved `baload` path, that cache state leaks across rows, or that
an arbitrary/non-monotonic `xMap` reuses a stale byte. Resetting the cache at
each computed row and keying it only by the complete low-byte address preserves
arbitrary maps; the existing 3,101-case differential, including alias and
band boundaries, must remain exact.

**Experiment plan.** Build fixed baseline/candidate CLDC trees from
`191910e`, confirm `copyArgbBand` target bytecode is unchanged, and measure the
candidate independently with `PhoneMeArgbBandBench`. Run at least twelve
balanced native i686 pairs at 240/full, 240/band-16, 176/full, and
176/band-16. Require a repeatable useful gain of at least +1% at both widths
with no mode-specific regression; side 161 is the low-coverage guard. Native
160 and downscaled 128 must remain artifact-identical at the original method
boundary. If the timing gate passes, rerun the focused differential, CLDC
preverify, `just verify`, release size/hash checks, and KEmulator presentation
oracles. Record raw pairs and reject the extra branch/locals if phoneME does
not pay them back.

**Artifact and bytecode result.** The isolated baseline/candidate phoneME
trees are
`35128db287d8cdf3fe4c222399a57c38a9586891bc76b0b6f1c1ca1c0fb5fed1`
and
`ffcaff38f604b6916bed9d4b338e7ffff0a8cdef38ffc3172b6756a2c309b4a3`.
The candidate runtime is byte-identical between the measured `/tmp` snapshot
and main:

- target-47 class:
  `d0de4d0c207b3cd3ef98823ebe4d35730f707bdbb979c077ad018217da1185f0`,
  16,892 bytes (+41);
- preverified class:
  `bbff3015a89562e6878258d836537c5b8ca8a93b0e532472605c8318caf92c9c`,
  23,112 bytes (+78);
- `copyArgbBand`: unchanged at 156 bytes;
- `copyUpscaledArgbBand`: 243 bytes (+21), with no new fields, arrays,
  allocations, or persistent heap.

`ArgbBandDifferentialSmoke` passed all 3,101 cases before timing and again
from main. All paired samples verified the full-output FNV. Raw
baseline/candidate µs/frame pairs are:

| Shape | Frames | Raw baseline/candidate pairs | Paired result |
|---|---:|---|---|
| 240/full | 200 | 3955/3370, 3970/3380, 3960/3425, 3995/3375, 3885/3325, 4010/3370, 4030/3465, 4010/3360, 4150/3320, 4025/3365, 4000/3395, 4010/3365 | **+15.322%**, +612.5 µs, 12/12 |
| 240/band-16 | 200 | 4235/3470, 4045/3470, 4165/3455, 4170/3540, 4165/3525, 4120/3500, 4125/3495, 4140/3490, 4110/3505, 4115/3460, 4160/3485, 4120/3480 | **+15.450%**, +640.0 µs, 12/12 |
| 176/full | 300 | 2936/2530, 2943/2543, 2920/2523, 2893/2513, 2913/2533, 2913/2540, 2903/2553, 2986/2523, 2973/2570, 2920/2566, 2920/2526, 2940/2530 | **+13.524%**, +395.5 µs, 12/12 |
| 176/band-16 | 300 | 3046/2790, 2946/2550, 2950/2560, 3043/2550, 2923/2550, 3046/2576, 2960/2543, 2940/2566, 2936/2566, 3016/2536, 2963/2550, 3090/2556 | **+13.690%**, +404.5 µs, 12/12 |
| 161/full | 600 | 2650/2348, 2626/2340, 2670/2365, 2710/2351, 2645/2345, 2655/2368, 2650/2356, 2680/2370, 2701/2358, 2670/2366, 2666/2360, 2660/2335 | **+11.410%**, +304.5 µs, 12/12 |

Timer resolutions were 5.000, 3.333, and 1.667 µs/frame, orders were
balanced, and every effect was unanimous and larger than 300 µs/frame. The
temporary candidate checkout was intentionally uncommitted, so
`paired-stats.awk` conservatively labeled the runs `exploratory`; no source
changed during timing, both fixed artifact hashes are recorded, and the final
main target-47 and preverified classes match the measured candidate
byte-for-byte.

**Final gates and verdict.** `just verify` passed Java 1.3, all cartridge
replays/full-state/traps, the 3,101-case scaler differential, release
validation, and counterless exactness. The final counterless artifact is
`de198887d0b35369dc6e650f355c0fe0f23ed6036af01ba495313c364f6581c9`.
Production `WasmInterpreter.execute` remains 7,039 bytes. Release artifacts
are:

- station: 228,785 bytes,
  `f1ab50c0a3bd27f163c0d60847122bd725cf1b904009382c650c847de75003ed`;
- base: 226,271 bytes,
  `0c3f2240247d612d02d987669a17eb79602ca92bb804230c3b0da69c1acf6790`.

KEmulator exact presentation routes passed Waternet 94/94, Rubido 70/70,
and Untangle 401/401 at 176x220. Accept the helper-only cache: it gives an
additional +11.4--15.5% native-phoneME ARGB conversion improvement on every
upscaled shape tested, while leaving native/downscale bytecode unchanged.
As with NJIT-016, this is a component result, not a whole-frame or
physical-phone FPS claim.

### NJIT-018: hoist the upscaled ARGB lookup table into a local

**Status:** `accepted`.

**Hypothesis and source.** The same independent renderer review found one
remaining `aload_0; getfield argbLookup` in every computed destination pixel
of `copyUpscaledArgbBand`. phoneME does not inline ordinary getters; the
reference-runtime disassembly and native microbench research measured a
quickened instance-field read as materially more expensive than a local
reference load. After NJIT-016 and NJIT-017, side 240 still computes 38,400
pixels and side 176 computes 28,160, so one immutable table-reference load at
method entry can remove that many field-handler dispatches per conversion.

The isolated candidate changes only `copyUpscaledArgbBand`: assign the final
`argbLookup` array to one local after validation/alias fallback and use that
local inside the computed-row loop. It does not alter row reuse, packed-byte
caching, `copyArgbBand`, `W4Canvas`, heap ownership, or output.

**Baseline identity.**

- source commit:
  `272891ba0ad355484417b25044755ce4a3b57f61`;
- counterless exactness:
  `de198887d0b35369dc6e650f355c0fe0f23ed6036af01ba495313c364f6581c9`;
- station/base JAR:
  `f1ab50c0a3bd27f163c0d60847122bd725cf1b904009382c650c847de75003ed`
  /
  `0c3f2240247d612d02d987669a17eb79602ca92bb804230c3b0da69c1acf6790`;
- phoneME production-shaped artifact:
  `ffcaff38f604b6916bed9d4b338e7ffff0a8cdef38ffc3172b6756a2c309b4a3`;
- runtime class: 16,892 bytes target-47 and 23,112 bytes preverified;
- `copyArgbBand` / `copyUpscaledArgbBand`: 156 / 243 bytes;
- native i686 VM, CLDC classes, and preverify remain
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`,
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`,
  and
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

**Expected benefit, risks, and gates.** The patch should add only one
reference local and a few method-entry bytecodes, with no persistent or peak
heap increase. Its risk is entirely phoneME execution shape: the larger frame
or changed method layout may cost more than the removed field reads, and a
sub-percent apparent effect may be layout/timer noise. Prototype in a fixed
snapshot, verify target-47 form and the 3,101-case differential, then run at
least twelve balanced native i686 pairs at 240/full and 176/full. Promote
band-16 controls if either primary is positive. Accept only a repeatable
paired median of at least +0.8% with a clear win majority at both widths and
no result below -0.5%; otherwise reject and record the exact dead end.

**Artifact, A/B, and verdict.** The fixed baseline/candidate phoneME artifacts
are
`ffcaff38f604b6916bed9d4b338e7ffff0a8cdef38ffc3172b6756a2c309b4a3`
and
`27d00eb4fc54e51c92ba1549021e5d5dec3abff68ffd6443ef2a1c918305dc52`.
The target-47 runtime is 16,900 bytes (+8), the preverified runtime is 23,138
bytes (+26), and `copyUpscaledArgbBand` is 247 bytes (+4). Main matches the
measured target-47 class
`67edb79f17208afc59da664ef981502ba6b1395642b3acda5654d223e271f9ba`
and preverified class
`63ce15aae1f76f793b4ffa5bcb409acf323325214645fafc9585519b31a49978`
byte-for-byte. No field, allocation, or heap state was added.

Raw baseline/candidate µs/frame pairs:

| Shape | Frames | Raw baseline/candidate pairs | Paired result |
|---|---:|---|---|
| 240/full | 300 | 3350/3386, 3363/3340, 3430/3286, 3350/3323, 3363/3286, 3390/3363, 3373/3390, 3370/3366, 3393/3336, 3366/3260, 3383/3263, 3393/3253 | **+1.243%**, +42.0 µs, 10/2 |
| 176/full | 400 | 2522/2470, 2512/2467, 2527/2557, 2530/2457, 2542/2532, 2552/2495, 2492/2562, 2537/2512, 2545/2545, 2532/2562, 2525/2457, 2540/2482 | **+1.388%**, +35.0 µs, 8/3/1 |
| 240/band-16 | 300 | 3500/3366, 3470/3353, 3523/3440, 3493/3453, 3480/3480, 3470/3453, 3480/3493, 3470/3470, 3490/3453, 3510/3483, 3473/3406, 3476/3473 | **+0.915%**, +32.0 µs, 9/1/2 |
| 176/band-16 first | 400 | 2550/2572, 2552/2565, 2547/2582, 2560/2450, 2567/2477, 2560/2545, 2520/2565, 2555/2495, 2572/2465, 2557/2482, 2530/2562, 2547/2852 | +0.038%, +1.0 µs, 6/6, unresolved |
| 176/band-16 repeat | 600 | 2531/2516, 2556/2565, 2576/2566, 2571/2500, 2521/2581, 2556/2531, 2568/2560, 2518/2515, 2560/2553, 2551/2531, 2546/2508, 2560/2508, 2560/2545, 2555/2548, 2576/2490, 2546/2573 | +0.487%, +12.5 µs, 13/3 |

The primary full-buffer modes clear the predeclared +0.8% threshold, and
240/band-16 also clears it. The longer 176/band-16 repeat is directionally
positive but deliberately reported as below the standalone acceptance
threshold; its role is no-regression evidence. Timer resolutions were 3.333,
2.500, and 1.667 µs/frame. The temporary candidate remained uncommitted and
therefore received the conservative `exploratory` label, but the artifacts
were fixed throughout timing and main is byte-identical to the measured
candidate.

`just verify` passed the 3,101-case renderer differential, all replay/state
and trap checks, Java 1.3/preverification, release validation, and counterless
exactness. The final counterless artifact is
`91942c2fbc75e201c8153964e7a84aa003bb7951e419ee2d48bd14fca4ec1417`.
Release artifacts are station 228,802 bytes
(`ea870077356454b8e90a7fa547dbb05e2dfc78e7b904a5d069a507d85e9d2339`)
and base 226,288 bytes
(`aa4d9193b8e88ce52104355b4c033235f5f0347ae8398fe1df217478aeabcb22`).
KEmulator Waternet passed 94/94 exact presentation checkpoints at 176x220.

Accept. A four-byte method change removes a field read per computed pixel,
produces repeatable +1.2--1.4% native phoneME conversion gains on both primary
upscaled shapes, remains positive or neutral in low-memory band mode, and has
no heap or correctness cost. This remains component timing, not a whole-frame
FPS claim.

### NJIT-019: cache packed bytes in native/downscale ARGB conversion

**Status:** `accepted`.

**Hypothesis and source.** NJIT-017 proved on native phoneME that retaining the
current packed framebuffer byte inside the upscaled inner loop is worth
+11.4--15.5% conversion time. The same redundancy remains in the intentionally
untouched canonical `copyArgbBand`: side 160 performs 25,600 `baload`
operations although a frame contains only 6,400 packed bytes, while side 128
performs 16,384 loads for about 5,120 distinct bytes selected by its map.
This is the deferred native/downscale half of the same mechanism, not a
combined experiment.

The candidate adds `previousPackedAddress` and `packed` locals to
`copyArgbBand`, resets them for every row, and reloads only when
`mapping & 0xff` changes. `copyUpscaledArgbBand`, NJIT-016 row reuse,
NJIT-017's cache, NJIT-018's lookup local, and `W4Canvas` dispatch remain
byte-identical.

**Baseline identity.**

- source commit:
  `5bb77cd31275df4a5e74d6f4b0a80612f9725cc6`;
- counterless exactness:
  `91942c2fbc75e201c8153964e7a84aa003bb7951e419ee2d48bd14fca4ec1417`;
- station/base JAR:
  `ea870077356454b8e90a7fa547dbb05e2dfc78e7b904a5d069a507d85e9d2339`
  /
  `aa4d9193b8e88ce52104355b4c033235f5f0347ae8398fe1df217478aeabcb22`;
- phoneME artifact:
  `27d00eb4fc54e51c92ba1549021e5d5dec3abff68ffd6443ef2a1c918305dc52`;
- runtime class: 16,900 bytes target-47 and 23,138 bytes preverified;
- `copyArgbBand` / `copyUpscaledArgbBand`: 156 / 247 bytes;
- native i686 phoneME tool hashes remain those recorded by NJIT-018.

**Correctness boundary.** The existing scaler differential intentionally
uses `copyArgbBand` as the canonical oracle, so it cannot independently prove
a rewrite of that same method. Before acceptance, add a direct reference
conversion that reads palette and framebuffer memory without calling either
production converter. Cover native 160, downscaled 128, arbitrary/non-monotonic
maps, band boundaries, palette changes, untouched tails, invalid geometry,
and the public `pixels == xMap` / `pixels == yMap` alias behavior. The cache
key is the complete low-byte address, so a changing 2-bpp lane in the high
mapping bits must still select from the retained byte correctly.

**Performance and decision gates.** Prototype only the canonical loop, inspect
target-47/preverified size, and run at least twelve balanced native i686 pairs
at 160/full, 160/band-16, 128/full, and 128/band-16. Require at least +2% on
both full-buffer primaries, no banded result below -0.5%, exact output on
every sample, and no persistent heap. If it passes, add the independent
reference test to main, run `just verify`, release gates, and KEmulator
native/downscale presentation where available; otherwise remove the cache and
record the rejected implementation.

**Artifact, exactness, and bytecode result.** The fixed baseline and candidate
production-shaped phoneME artifacts are
`27d00eb4fc54e51c92ba1549021e5d5dec3abff68ffd6443ef2a1c918305dc52`
and
`cdc59be1c0e514f9e1a6db915fcf5b66710c2f50e1ad328c3a4cddeadb125974`.
After promotion, main rebuilt the candidate artifact with the same SHA-256.
Its runtime class is byte-identical to the measured `/tmp` snapshot:

- target-47:
  `3523e906614f6728b24e908a500dc36338cd516f6ee3c50ca8f90fc5ea5c9764`,
  16,941 bytes (+41);
- preverified:
  `95fd55080b40b5686ef0c7d87cad32dd2619bbe5cc8691a077a4a49584480adf`,
  23,218 bytes (+80);
- `copyArgbBand`: 177 bytes (+21);
- `copyUpscaledArgbBand`: unchanged at 247 bytes.

The change adds two scalar locals and no field, array, allocation, or
persistent heap. The independent reference reads the 2-bpp framebuffer and
little-endian palette directly rather than using either production converter.
It covers native 160, downscaled 128, full and partial bands, non-monotonic
maps, repeated rows, changing lanes within one packed byte, untouched tails,
aliases, palette changes, and invalid geometry. `ArgbBandDifferentialSmoke`
passes all 3,731 cases.

**Native i686 phoneME A/B.** The native VM, CLDC classes, and preverify hashes
are the NJIT-018 baseline values. Each sample converted a fixed framebuffer
through the public production method, checked the complete output FNV, and
alternated baseline-first and candidate-first order. Raw baseline/candidate
µs/frame pairs are:

| Shape | Frames | Raw baseline/candidate pairs | Paired result |
|---|---:|---|---|
| 160/full | 600 | 2623/2338, 2641/2348, 2645/2326, 2651/2348, 2643/2340, 2736/2345, 2620/2330, 2758/2333, 2665/2343, 2758/2340, 2583/2345, 2606/2340 | **+11.447%**, +303.0 µs, 12/12 |
| 160/band-16 | 600 | 2741/2345, 2648/2335, 2638/2321, 2655/2326, 2605/2340, 2660/2338, 2673/2333, 2655/2358, 2611/2358, 2651/2323, 2705/2335, 2645/2333 | **+12.061%**, +319.5 µs, 12/12 |
| 128/full | 800 | 1683/1543, 1672/1533, 1716/1502, 1713/1542, 1673/1528, 1662/1531, 1681/1538, 1697/1538, 1670/1537, 1686/1533, 1683/1537, 1690/1555 | **+8.587%**, +144.0 µs, 12/12 |
| 128/band-16 | 800 | 1707/1533, 1683/1537, 1721/1551, 1705/1535, 1701/1530, 1721/1547, 1681/1540, 1693/1556, 1772/1541, 1725/1523, 1715/1537, 1818/1545 | **+10.082%**, +172.5 µs, 12/12 |

Timer resolutions are 1.667 µs/frame at side 160 and 1.250 µs/frame at side
128. Every one of the 48 pairs favors the candidate and all deterministic
output fields match. The isolated candidate checkout was intentionally
uncommitted, so the statistics label it `exploratory`; the artifacts remained
fixed throughout timing and the promoted main classes match them
byte-for-byte.

The exact timing commands were:

```sh
/tmp/w4me-njit019.91mC2c/run-render-pairs.sh 160 160 600 12
/tmp/w4me-njit019.91mC2c/run-render-pairs.sh 160 16 600 12
/tmp/w4me-njit019.91mC2c/run-render-pairs.sh 128 128 800 12
/tmp/w4me-njit019.91mC2c/run-render-pairs.sh 128 16 800 12
```

**Final gates and verdict.** `just verify` passes Java 1.3, CLDC lint and
preverification, all replay/full-state/trap checks, the 3,731-case renderer
differential, release validation, and counterless exactness. The counterless
artifact is
`544c0a3bf17074ade5dffe7bd61cf54b34a4b33099e9f01b69e2bb21a4345607`;
diagnostic/counterless `WasmInterpreter.execute` remain 7,039/7,007 bytes.
Release artifacts are:

- station: 228,837 bytes,
  `9b4de64851b0d331ee469e5f0244c62827c96096c7026b3c48d4b3ebed61e221`;
- base: 226,323 bytes,
  `6ac441edbb4ee5ea9c1ca07fe77d6c1d9af978405e3770910fd843a04efa2c6f`.

Two KEmulator diagnostic sessions exercised the production Canvas and the
actual affected method rather than the usual side-176 upscale path:

- screen 160x220 reported
  `framebuffer=0,8,160 controls=176,44 overlap=0`, completed all 60 exact
  Plasma checkpoints, and produced screenshot
  `f95004e8e96d05af1c32ce3f1fc5a122a345d03c12b70009dc6f3dbb7cfb2e61`;
- screen 128x180 reported
  `framebuffer=0,6,128 controls=140,40 overlap=0`, completed the same oracle,
  and produced screenshot
  `40ff63d1edf1c5278a58d0cd8b2193fecfed5e131583d2b6eb11947e80e65f2a`.

Accept. The cache exceeds both predeclared primary gates, wins every pair,
preserves arbitrary-map and alias semantics, costs no heap, and passes real
MIDP native/downscale presentation. This remains a component conversion
result, not a whole-frame FPS claim.

### NJIT-010: constant-envelope and constant-pitch PCM fast path

**Status:** `accepted`.

**Hypothesis and source.** `Wasm4Pcm.synthesize` currently recomputes
`sample * 60 / 8000`, calls the seven-argument `envelopeVolume`, and performs
a signed 64-bit multiply/divide for pitch interpolation on every sample. This
work also runs when a tone has no attack, decay, or release and has no pitch
slide. That is the complete audible route corpus: all 12 non-null Waternet
tones and all seven non-null Rubido tones have a sustain-only envelope and
equal decoded start/end frequencies. One Waternet route synthesizes 41,332
WAV bytes and one Rubido route 7,777 bytes through this shape.

The isolated candidate checks frequency equality first, followed by the three
zero envelope segments, before entering the scalar loop. For that shape it
calls one private helper and returns; the helper retains the decoded start
frequency and sustain volume while preserving the existing waveform, phase,
PCM, pan, and output logic. The original general ADSR/slide calculation stays
unchanged after the guard. This does not change the APU ABI, MMAPI lifecycle,
sample rate, WAV layout, waveform math, allocation count, or buffer size.

**Baseline identity.**

- source commit:
  `df3f518586cd6d012144df80c02b818f37db94b2`;
- counterless exactness:
  `544c0a3bf17074ade5dffe7bd61cf54b34a4b33099e9f01b69e2bb21a4345607`;
- station/base JAR:
  `9b4de64851b0d331ee469e5f0244c62827c96096c7026b3c48d4b3ebed61e221`
  /
  `6ac441edbb4ee5ea9c1ca07fe77d6c1d9af978405e3770910fd843a04efa2c6f`;
- phoneME production-shaped artifact:
  `cdc59be1c0e514f9e1a6db915fcf5b66710c2f50e1ad328c3a4cddeadb125974`;
- target-47/preverified `Wasm4Pcm.class`:
  `f0121589e43d0770532eee16e18c8c2cd1916cb3d88b1dfed4e0f90babb2ddf2`
  (2,631 bytes) /
  `7197e0e2dbe13a1520b36978fc9cbfdc8989c7d6bed012a0a801c07104539666`
  (3,832 bytes);
- `synthesize`: 638 target-47 code bytes;
- native i686 phoneME VM/classes/preverify hashes remain the NJIT-019 values.

**Correctness and performance gates.** Freeze the original implementation as
an independent test reference and compare every returned byte or `null` over
the Cartesian edge corpus, maximum-duration cases, deterministic random
ADSR/slides/note-mode/pan/waveforms, and route fixtures. Require at least
10,000 cases and 50 MiB of compared output, plus stable hashes for Waternet,
Rubido, upward/downward slides, ADSR, note-bend slide, and the maximum
duration. Compile and preverify both artifacts with source/target 1.3 and
record class/method/JAR growth.

Add a CLDC-only `PhoneMePcmBench` that executes exact Waternet and Rubido tone
sequences and separate ADSR/slide slow-path controls, retaining only aggregate
FNV/byte counts so allocation and GC remain production-shaped. Run at least
twelve balanced native i686 pairs per workload under a 64-MiB heap. Accept
only if both route-shaped primaries improve by at least +5% with a clear win
majority, every output is exact, and neither control regresses below -0.5%.
Then run `just verify`, exact KEmulator sound/sound-test/touch gates, release
validation, and record that native phoneME proves synthesis cost only: the
real MMAPI `createPlayer`/`realize`/`prefetch`/`start` boundary still requires
KEmulator or physical-device evidence.

**Correctness and artifact results.** The independent differential freezes
the complete pre-NJIT-010 scalar implementation rather than sharing the new
helper. It compared 11,941 input combinations, including null results,
maximum-duration tones, deterministic random ADSR, slides, note mode, pan,
and every waveform, and found all 52,525,193 returned bytes equal. Seven
immutable fixtures additionally retain exact output lengths and SHA-256:

| Fixture | Bytes | SHA-256 |
| --- | ---: | --- |
| Waternet 262 Hz | 6,711 | `f844e1b3d5ea49578821154e55e241bca7dcef93e0f37cbe527324c4cfec23f1` |
| Rubido 900 Hz | 1,111 | `b35dcb15e954cac510abd22f2c6f82fc0ad1d9177c89071e3ee9ec571a4a0814` |
| upward slide | 8,044 | `22e25f167915097da1053114496e36d236ca1999fa060452b262d1c50f26d579` |
| downward slide | 8,044 | `f4c91b123fbc1ac0408d31197a4452310f14c9fd8d61a8c2e8753c2f4be111c1` |
| ADSR | 1,111 | `ca59388dd6a48d7a5de7e49dfb46a95d0a3435e6d1b20b55d1b07ea28eefacc7` |
| note-bend slide | 2,444 | `14e39141f9d6f65a3f4c94c590152ac42fc8db2d8e3dc691a7084c9b702c4f37` |
| maximum duration | 272,044 | `eebdb0b1dd1ad9f674ce644e023e04f9b92ca3a6ce2062b6526e4bb4380378cc` |

`just test` and `just verify` pass, including Java source/target 1.3, the CLDC
bootclasspath lint, classfile 47, preverification, the full replay/state,
trap, cache, release, and counterless matrices. Native i686 phoneME exact
verification passes Waternet, Rubido, and Untangle. The final counterless
exactness artifact is
`3040229cf4640b41825e8eecc9a79550ed4c69a318fd2bf36704fbec2dc97102`;
diagnostic/counterless `WasmInterpreter.execute` remain 7,039/7,007 bytes.

The retained source file has SHA-256
`110d579a3e3519d4fbd4f0dcaa4c09105ecf5d9d129c40b304b833ee65e1e863`.
The target-47 `Wasm4Pcm.class` is 3,130 bytes
(`cc30bb53e207c834781d2c36c29971b75931b32ab9e81589f9b20636930f22f1`)
and its preverified form is 4,663 bytes
(`d1f0e28699d7b89cbb18c1bb6d5e19a050c3f2e1a1af34f10d2de07bda3fcb6d`).
Against the baseline, `synthesize` grows from 638 to 683 code bytes, the new
helper is 249 bytes, and the class grows by 499 target-47 bytes and 831
preverified bytes. The helper is called once per qualifying tone; the
candidate adds no field, persistent allocation, output allocation, or device
heap state.

The verified uncommitted station/base release JARs are 229,203/226,689 bytes,
366 bytes larger than the baseline, with SHA-256
`fc77ae06cce732242afdba7e29e5158f151b1f7fb93ba3f961eff79964c60a43`
and
`661ce78287f536e5a87844cea7258a8abdd1e8f403ba134f9081b7cd02e83dba`.

**Clean timing artifacts and commands.** The clean snapshots are temporary
commits
`d1eb1973f46ee9dedbcc832492dfb03581b20d5a` for the baseline and
`6f54debb12c8d18c293b07cc21e550c6ac2cc873` for the candidate. Their only
non-build source difference is `Wasm4Pcm.java`; both report an empty
`git status`. Their baseline/candidate preverified PCM-class hashes are
`7197e0e2dbe13a1520b36978fc9cbfdc8989c7d6bed012a0a801c07104539666`
and
`d1f0e28699d7b89cbb18c1bb6d5e19a050c3f2e1a1af34f10d2de07bda3fcb6d`.
The fixed runner and raw evidence are retained under
`/tmp/w4me-njit010-current.dz2WZs/` for the lifetime of this host session.
Each pair alternated order and invoked:

```sh
.local/phoneme/cldc_vm_r -EnableTicks =HeapCapacity64M \
  -classpath .local/phoneme/classes.zip:<preverified-tree> \
  w4me.PhoneMePcmBench <workload> <cycles> <sample>
```

The complete final commands and gates were:

```sh
bash /tmp/w4me-njit010-current.dz2WZs/run-pcm-pairs-v3.sh waternet 50 12
bash /tmp/w4me-njit010-current.dz2WZs/run-pcm-pairs-v3.sh rubido 200 12
bash /tmp/w4me-njit010-current.dz2WZs/run-pcm-pairs-v3.sh slide 50 12
bash /tmp/w4me-njit010-current.dz2WZs/run-pcm-pairs-v3.sh adsr 200 12
just test
just verify
tools/phoneme/run.sh verify
tools/kemu/run.sh verify sound
tools/kemu/run.sh verify sound-test
tools/kemu/run.sh verify touch
```

Every timed invocation matched calls, output byte count, aggregate FNV, and
allocation shape before its wall clock was accepted. Raw baseline/candidate
microseconds per complete tone sequence were:

| Pair | Waternet B/C | Rubido B/C | slide B/C | ADSR B/C |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 23,440 / 17,820 | 4,290 / 3,350 | 18,060 / 17,920 | 4,560 / 4,565 |
| 1 | 23,280 / 17,660 | 4,310 / 3,310 | 18,080 / 18,020 | 4,515 / 4,585 |
| 2 | 23,140 / 17,720 | 4,450 / 3,350 | 18,000 / 17,980 | 4,545 / 4,520 |
| 3 | 23,000 / 17,640 | 4,365 / 3,455 | 18,000 / 18,040 | 4,555 / 4,545 |
| 4 | 23,320 / 17,520 | 4,280 / 3,225 | 18,020 / 18,200 | 4,560 / 4,535 |
| 5 | 23,120 / 17,660 | 4,275 / 3,255 | 18,020 / 18,060 | 4,540 / 4,475 |
| 6 | 23,340 / 17,700 | 4,245 / 3,250 | 18,060 / 18,020 | 4,525 / 4,560 |
| 7 | 23,160 / 17,680 | 4,235 / 3,280 | 17,980 / 18,320 | 4,560 / 4,545 |
| 8 | 23,240 / 17,640 | 4,285 / 3,245 | 17,980 / 17,980 | 4,580 / 4,570 |
| 9 | 23,240 / 17,740 | 4,205 / 3,290 | 18,120 / 17,960 | 4,660 / 4,560 |
| 10 | 23,440 / 17,760 | 4,260 / 3,295 | 18,140 / 18,280 | 4,730 / 4,615 |
| 11 | 23,920 / 17,840 | 4,295 / 3,245 | 17,940 / 18,300 | 4,630 / 4,660 |

Waternet measures **+24.036%**, +5,610 us/sequence, and 12/12 wins at
20 us resolution. Rubido measures **+23.321%**, +997.5 us/sequence, and
12/12 wins at 5 us resolution. The slow-path controls remain within the
predeclared limit: slide is -0.111% with 5/6/1 wins/losses/ties, and ADSR is
+0.274% with 8/4. All four summaries report balanced order,
`source-clean=yes`, and `evidence-quality=measured`.

KEmulator's `sound`, `sound-test`, and `touch` checks pass; `sound-test`
retains framebuffer FNV `a4b700fa`. The selected emulator backend reports
`D-playTone`, so these results prove that the candidate does not break the
MIDP audio/control integration but do not time or audibly validate the
`audio/x-wav` MMAPI player path. No physical-phone audio timing was available.

**Verdict.** Accept. The isolated production shape exceeds both +5% primary
gates unanimously, keeps the general slide and ADSR paths above the -0.5%
floor, preserves every returned byte and all release/device integration
checks, and costs no persistent heap. Report the +23--24% values only as PCM
sequence synthesis improvements during tone emission; they are not whole-game
FPS gains and do not include MMAPI player setup or hardware playback.

### Performance-corpus gate: Game of Life idle generation

**Status:** `verified`.

Game of Life was already present in the host full-state corpus and the
KEmulator generic workload, but not as an exact route in the native phoneME
workflow. Passing its cartridge name to `tools/phoneme/run.sh` staged no input
or oracle files, verified zero checkpoints, and inherited the generic
60-extra-frame default. One frame is already a complete heavy workload, so
that implicit invocation was both weakly checked and needlessly long.

The new immutable `idle-1` route fixes input at gamepad `0`, mouse
`32767,32767`, and buttons `0`, then checks frame zero against:

- framebuffer SHA-256
  `36257a0b35add0f58649174d73f7d568a82f0ca1a251639cb1acc24ae0118fda`;
- framebuffer FNV-1a `a9255758`;
- palette `00fff6d3,00004231,00764462,00edb4a1`;
- zero tone and disk events;
- cartridge SHA-256
  `ca57b23b8bda728a6f92848f8981cfb7837c1c389639cc568c29fddca597d4d3`.

The host replay validates the full framebuffer SHA-256, palette, input memory,
and empty side effects. The existing full-state differential independently
reports exact 64-KiB memory/globals/table state with final memory SHA-256
`45198d7efef567bfe59fee600cc06a41f288bfcf959d46716f66cfee3dc5cc5a`.
The CLDC phoneME route consumes one checkpoint and reproduces
12,802,761 logical instructions, 5,565,951 outer dispatches, 482,291 compact
calls, and 6,407,444 compact instructions with the current integer compact
configuration.

`just bench` and `tools/phoneme/run.sh verify` now include this cartridge.
When `--extra-frames` is absent, existing recorded routes retain their
60-frame tail while Game of Life selects one frame; an explicit value still
overrides all selected routes. This prevents an accidental 60-generation run
without changing any established route baseline. The receipt records the
resolved value per cartridge.

On native i686 phoneME, the one-frame route took 3.40--3.56 seconds in
exploratory dirty-tree checks. A two-pair balanced `current` versus
`seven-opcode` exercise consumed the exact checkpoint on all four VM runs and
produced the normal paired CSV/statistic. Its +0.566% median with one win and
one loss is intentionally not a performance verdict; that run exists only to
prove the A/B path. The workload adds no production class, release-JAR, or
device heap cost. Its role is a high-density integer/control-flow primary or
no-regression control for future candidates.

### NJIT-020 preparation: production-shaped Game of Life deep profile

**Status:** `verified`.

**Trigger and scope.** The owner reports that Game of Life remains extremely
slow on a physical Galaxy S25+ through J2ME Loader, so the next candidate uses
the exact `idle-1-v1` Game of Life frame as its primary workload rather than
selecting only by average corpus coverage. Native i686 phoneME remains the
authoritative no-JIT A/B judge; the physical report proves target relevance
but does not yet identify the responsible VM handler or provide a paired
effect.

The first clean `main@924c1d5f15577531d3999f4974a141109b701ce9`
host-exact profile produced artifact
`5da7dd191969eb64a9b32f47973dba080a853da72cf796c0112b2c1467792e28`
and passed all seven full-state differentials. It also exposed a measurement
configuration defect: `GenericCorpusProfiler` labels its tier side
`CURRENT`, whose explicit test variant has `integer-compact=off` and
`host-import-id=off`, while both defaults are enabled in the production
`WasmInterpreter` and in the phoneME `host-import-id` artifact. The profiler's
raw generic opcode stream is still deterministic, but its 5,848,629 outer
dispatches, 430,771 compact calls, 5,918,928 compact instructions, compact
break metadata, and pre-load-tee pair counts are not the current production
shape. They must not select NJIT-020.

**Instrumentation correction and gates.** Keep profiling execution outside
the compact executor so every dynamic W4IR opcode, pair, triple, and function
entry remains visible, but decode the production load-tee stream and build
compact-region metadata with integer compact opcodes enabled. Run the separate
tier pass with the complete `HOST_IMPORT_ID` production variant. The corpus
full-state differential must compare `REFERENCE` directly with
`HOST_IMPORT_ID`, not the stale intermediate `CURRENT` variant.

The corrected report must:

- retain Java source/target 1.3 and all seven exact full-state workloads;
- identify its artifact, source HEAD, cartridge, route, and complete variant
  configuration;
- reproduce the existing exact Game of Life logical count `12,802,761`;
- reproduce the phoneME production-tier counts `5,565,951` outer dispatches,
  `482,291` compact calls, and `6,407,444` compact instructions;
- replace the stale load/store/signed-comparison compact-break and sequence
  data before a production candidate is chosen.

This correction changes only host test/profiling code and the benchmark
wrapper. It adds no MIDlet class, release-JAR byte, persistent device heap, or
runtime branch. After the corrected report and independent read-only reviews
agree on a high-coverage mechanism, append NJIT-020's isolated implementation,
exactness, bytecode, heap, and at-least-twelve-pair native phoneME acceptance
plan before changing production code.

The corrected Java 1.3 artifact is
`ad211ace5b3697cf0540d82f1d1ebab5d60cb52ab2b1c90a09aeb4f7e3ab3425`;
the complete report SHA-256 is
`7ba74f3fc820a95b62abddde3e5d2c0434397254cf2b219640805d73cf646fad`.
All seven `REFERENCE` versus `HOST_IMPORT_ID` full-state workloads pass. Both
printed configurations now include the production load-tee stream, integer
compact eligibility, and numeric host-import dispatch. Game of Life reproduces
exactly `12,802,761` logical instructions, `5,565,951` outer dispatches,
`482,291` compact calls, and `6,407,444` compact instructions. The raw
profiling pass executes every decoded instruction outside compact execution
and records 9,888,650 production-stream dispatches for coverage only.

The frame has no tone or disk events and executes no host drawing import.
Guest code writes the framebuffer directly, so the phoneME route's
multi-second update is not caused by PCM, MMAPI, blit, rect, ARGB conversion,
or presentation. `W4Canvas` framebuffer conversion, `drawRGB`, touch overlay,
and `flushGraphics` remain outside this headless timing boundary and need a
separate physical-device phase split, but optimizing them cannot remove the
measured 12.8-million-instruction guest update.

### NJIT-020: native bulk copy for defined-function arguments

**Status:** `accepted`.

**Selection evidence and mechanism.** The corrected Game of Life profile has
281,600 defined-function calls in one frame:

| Function | Entries | Parameters | Declared locals | Raw dispatches |
| ---: | ---: | ---: | ---: | ---: |
| 7 | 25,600 | 2 | 1 | 870,400 |
| 8 | 204,800 | 2 | 1 | 5,096,038 |
| 9 | 51,200 | 3 | 0 | 1,536,000 |

The current `callFunction` clears its reused local frame and then copies every
argument from the value stack with an interpreted Java loop. These calls copy
614,400 `long` slots per Game of Life frame. No post-warmup allocation is
involved: functions 7 and 8 reuse one three-slot frame at the same call depth,
function 9 also fits that frame, while the exported update frame has twelve
slots. The candidate leaves full frame clearing unchanged, handles one
argument with one scalar assignment, handles two or more with
`System.arraycopy(values, argumentBase, locals, 0, argumentCount)`, and does
nothing for zero arguments. It then performs the existing `valueTop` update
and function entry unchanged.

This is materially different from the rejected declared-local-only zeroing
candidate. That experiment changed which slots were cleared and regressed the
Duck Maze phoneME route by -0.484%. NJIT-020 preserves the complete clear and
changes only the subsequent copy implementation. CLDC 1.1 provides primitive
`System.arraycopy`, and phoneME implements it below the Java bytecode
interpreter.

An isolated source/target-1.3, preverified native i686 phoneME microbenchmark
used non-overlapping `long[]` arrays and the same dynamic length/source-offset
shape. One five-million-iteration selection run measured:

| Length | Manual loop | `System.arraycopy` | Relative copy time |
| ---: | ---: | ---: | ---: |
| 2 | 64.8 ns/copy | 48.2 ns/copy | -25.6% |
| 3 | 86.8 ns/copy | 49.0 ns/copy | -43.5% |

These component figures justify a production A/B but are not a game-speed
claim. The exact full-call context includes frame clearing, type lookup, Java
method entry/return, W4IR execution, and phoneME layout effects.

**Alternatives rejected for this iteration.** A transformed drawing fast path
has zero coverage in this frame. A new `i32.gt_s + br_if` fusion covers
408,161 pairs but repeats the mechanism of the rejected compare-branch batch,
which removed dispatches yet regressed Rubido by -0.214%, and risks compact-run
erosion. `i32.load8_u + local.set` covers 202,884 pairs and remains a plausible
later W4IR batch, but needs a format bump and two-instruction budget/trap
handling; the analogous accepted `i32.load + local.tee` produced only +0.419%
on Game of Life. Inlining address helpers covers more than 510,000 memory
operations but is a larger multi-site reconsideration of NJIT-005. The
argument-copy candidate is chosen first because it has independent VM-level
support, no W4IR/cache change, no persistent heap, and one semantic boundary.

**Baseline and acceptance plan.** The production baseline is clean
`main@924c1d5f15577531d3999f4974a141109b701ce9`, with native i686 phoneME
`bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`,
CLDC classes
`117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`,
and preverifier
`4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.
Record clean baseline/candidate preverified-tree hashes after the isolated
source snapshots are built.

Correctness must cover zero, one, two, and three-or-more parameters, reused and
recursive frames, 32/64-bit raw argument bits, zeroed declared locals, return
values, traps, instruction budgets, all seven full-state workloads, exact
Game of Life route state, Java 1.3/CLDC lint, classfile 47, preverification,
release JARs, and existing W4IR cache/device gates. Inspect `callFunction`
target-47 and preverified bytecode, class/JAR growth, and confirm zero new
fields, arrays, or persistent heap.

Run at least twelve balanced clean-source native i686 pairs with the exact
one-frame Game of Life route as primary. Require a median speedup of at least
+0.5%, at least eight wins, identical logical/tier/oracle counters, and a
timer-resolved effect. Then run Waternet, Rubido, and Untangle controls and
reject below -0.5%. Only after native acceptance should a physical J2ME Loader
JAR be used to split update versus render time and check that the benefit
survives its different VM; absence of that physical follow-up narrows the
claim to native no-JIT phoneME rather than invalidating exactness.

**Correctness, bytecode, and artifact results.** The retained implementation
changes only the argument copy after the existing complete local-frame clear.
`DefinedCallArgumentCopySmoke` exercises zero, one, two, and five parameters;
raw i32, i64, f32, and f64 bits; sequential and recursive frame reuse; zeroed
declared locals; return values; a second invocation on the same module; and
the exact accepted/denied instruction-budget boundary. It reports:

```text
PASS defined-call-arguments arities=0,1,2,5 raw-types=i32,i64,f32,f64 frame-reuse=sequential,recursive logical=271 budget=exact
```

`just verify` passes the focused test, all replay and seven full-state
workloads, the exact Game of Life checkpoint, traps, budgets, resident and
cached W4IR, Java source/target 1.3, CLDC API lint, classfile 47,
preverification, release integrity, and counterless exactness. The final
counterless artifact is
`16a3364cf2f635eaea07d0993716a2025c7b5fd7900158d6a4869dfb3b84868c`.
Diagnostic/counterless `execute` remain 7,039/7,007 bytes and retain the dense
`tableswitch`.

The isolated clean target-47 `callFunction` grows from 919 to 928 code bytes.
The unpreverified `WasmInterpreter.class` grows from 52,956 to 52,969 bytes,
with hashes
`ac6f075c0ef5b900adaf7167f09fefb04d1567445f6d17c3788c2d9254d0d20a`
and
`4f7ebc4dd671c1c7311282b6da549326fd0658af2ecedf98e3729caf3e498e76`.
Its preverified form grows from 79,574 to 79,587 bytes, with hashes
`1ed81325f2aa6419ed05afcc000349b93d9e30f710c381d501e393be74e1f79b`
and
`89f88b9d3ce8cf70a2782ff7fe0e332177cb20de68940a44d0f615cbefbed6c3`.
The final station/base release JARs are 229,207/226,693 bytes, four bytes
larger than the baseline, with SHA-256
`ab1067d494818feae0f933efe196a52f4b965b0e00862a7a6bc8b2425eba28fb`
and
`4752473a5a81925003ec16459cdedd811f987eed9b03c7876e365b9aa11c34df`.
No field, array, retained object, W4IR token, cache-format byte, or persistent
heap state is added. `System.arraycopy` operates on the existing value and
local arrays and does not allocate.

**Clean native artifacts and commands.** The fixed snapshots under
`/tmp/w4me-njit020.DNUacb/` are clean temporary commits
`956740356ecfc7c0c2af8abfd707f2e4ff8863e8` for the baseline and
`556fd072e71fbb8ae338f54a79704ef60cc33ee1` for the candidate. Their only
production difference is the argument-copy hunk in `WasmInterpreter`.
Complete staged phoneME artifacts are respectively
`0e1d032af5b14eb97d86014e2ef4fb252c7ec06627e66d72ac876c94d576614f`
and
`039bf358fe35847b92eed13afe9e1e6f5b4623b9604a19a349eefafbbef183e4`.
Both receipts bind the native i686 VM, CLDC classes, and preverify hashes
recorded above, `source-dirty=no`, Java 1.3, W4IR format 16, a 64-MiB judge
heap, and the production `host-import-id` configuration.

The clean artifacts were built and sanity-run with:

```sh
PHONEME_HOME=.local/phoneme tools/phoneme/run.sh bench \
  waternet rubido untangle game-of-life-zig-edition \
  --candidate host-import-id --reps 1
bash /tmp/w4me-njit020.DNUacb/run-pairs.sh
bash /tmp/w4me-njit020.DNUacb/run-control-pairs.sh waternet
bash /tmp/w4me-njit020.DNUacb/run-control-pairs.sh rubido
bash /tmp/w4me-njit020.DNUacb/run-control-pairs.sh untangle
```

Every invocation matched checkpoints, logical instructions, outer dispatches,
compact calls/instructions, branch-fast metadata, W4IR format, and all other
deterministic receipt fields. Raw microseconds per frame follow:

| Pair | Order | Game of Life B/C | Waternet B/C | Rubido B/C | Untangle B/C |
| ---: | --- | ---: | ---: | ---: | ---: |
| 0 | baseline first | 3,491,000 / 3,532,000 | 17,313 / 17,163 | 105,310 / 105,457 | 4,778 / 4,802 |
| 1 | candidate first | 3,499,000 / 3,486,000 | 17,339 / 17,156 | 106,116 / 105,116 | 4,739 / 4,743 |
| 2 | baseline first | 3,540,000 / 3,445,000 | 17,156 / 17,222 | 105,844 / 105,480 | 4,789 / 4,765 |
| 3 | candidate first | 3,444,000 / 3,502,000 | 17,366 / 17,156 | 105,542 / 105,651 | 4,804 / 4,817 |
| 4 | baseline first | 3,439,000 / 3,498,000 | 17,294 / 17,307 | 105,705 / 105,348 | 4,841 / 4,773 |
| 5 | candidate first | 3,506,000 / 3,460,000 | 17,228 / 17,235 | 110,069 / 105,232 | 4,736 / 4,813 |
| 6 | baseline first | 3,455,000 / 3,445,000 | 17,156 / 17,078 | 105,736 / 104,790 | 4,806 / 4,758 |
| 7 | candidate first | 3,487,000 / 3,422,000 | 17,431 / 17,300 | 105,186 / 105,496 | 4,802 / 4,802 |
| 8 | baseline first | 3,449,000 / 3,355,000 | — | — | — |
| 9 | candidate first | 3,430,000 / 3,402,000 | — | — | — |
| 10 | baseline first | 3,461,000 / 3,479,000 | — | — | — |
| 11 | candidate first | 3,460,000 / 3,420,000 | — | — | — |

Game of Life measures a median +20,500 us/frame, **+0.594%**, with 8 wins
and 4 losses. The 1,000 us/frame timer resolution is much smaller than the
median effect, order is balanced, and the result clears the predeclared +0.5%
and 8/12 acceptance gates exactly. Controls measure +0.603% Waternet
(+104.5 us/frame, 5/3), +0.341% Rubido (+360.5 us/frame, 5/3), and -0.042%
Untangle (-2.0 us/frame, 3/4/1). The Untangle value is below its 2.174
us/frame resolution and is conservatively classified as exploratory; it is
also far inside the -0.5% no-regression limit. Waternet and Rubido are
timer-resolved. All raw outputs and paired summaries remain under
`/tmp/w4me-njit020.DNUacb/evidence/` for the lifetime of this host session.

**Verdict.** Accept. The isolated native-copy shape meets the predeclared
Game of Life floor and win count, stays exact, adds no persistent memory or
format cost, and has no resolved route regression. The effect is deliberately
reported as only a native i686 no-JIT phoneME whole-update improvement: about
20.5 ms removed from a roughly 3.45-second generation. It does not make Game
of Life interactive and is not yet evidence of an improvement under the
Galaxy S25+ J2ME Loader VM. Reconsider if physical-device phase timing reverses
the result, a future phoneME/class-layout change changes its sign, or a later
call-lowering design removes the argument copy entirely.

### NJIT-021: signed compare plus direct conditional branch

**Status:** `rejected`.

**Hypothesis, source, and dynamic coverage.** The corrected one-frame Game of
Life profile contains the following adjacent pairs after the retained
production fusion pass:

| Pair | Game of Life count | Other routed-corpus count |
| --- | ---: | ---: |
| `i32.lt_s + br_if` | 204,800 | 915 |
| `i32.gt_s + br_if` | 408,161 | 6,430 |
| `i32.le_s + br_if` | 203,362 | 207 |
| **Total** | **816,323** | **7,552** |

The three pairs account for 8.26% of Game of Life's 9,888,650 profiled
production-stream dispatches and can remove at most 14.67% of its 5,565,951
outer dispatches. The exact tiered frame remains 12,802,761 logical
instructions. The expected wall benefit is unresolved until native phoneME
A/B because `i32.gt_s` is currently compact-eligible, while `i32.lt_s` and
`i32.le_s` are enabled only by the integer compact option; replacing the pair
with an outer fused handler changes compact-region boundaries as well as
dispatch count.

This candidate revisits but does not repeat the rejected format-15
compare-branch batch from `optimize-generic-interpreter-tiering`. That batch
covered `i32.eqz`, `i32.eq`, `i32.lt_u`, and `i32.ge_u`, executed taken
branches through the legacy `branch()` helper, saved 75,581 Rubido outer
dispatches, and measured -0.214% on the decisive 16-pair Rubido repeat. Its
ledger explicitly allowed reconsideration after static branch descriptors or
branch-capable compact execution changed the target cost. Since then the
accepted pc-indexed direct ordinary-branch path has replaced binary search and
legacy control-stack lookup for validated arity-zero/one sites, and Game of
Life has added a new exact primary workload with more than ten times the old
saved-dispatch coverage. NJIT-021 uses only the three previously untested
signed relations and the direct descriptor arrays; it does not restore the
old four-opcode batch.

**Selected mechanism and affected files.** Add one tail W4IR opcode representing
`signed-compare + br_if`; encode the relation kind and retained branch depth
in its existing operand fields, keep the second `br_if` token, and keep the
original branch descriptor mapping at `pc + 1`. The outer handler:

1. charges the comparison at the existing dispatcher boundary;
2. pops the two i32 operands and computes `lt_s`, `gt_s`, or `le_s`;
3. charges and checks the original `br_if` instruction before any branch
   transfer;
4. restores the comparison result on the value stack if that intermediate
   budget check traps;
5. on a taken branch, uses `branchFastSiteByPc[pc + 1]` and the accepted
   arity-zero/one direct transfer, with the canonical legacy fallback for a
   function return, larger arity, or rejected descriptor;
6. advances by two original instructions when not taken.

The fused opcode remains compact-eligible with span one. Compact execution
performs only the original comparison and reaches the retained outer `br_if`,
preserving the current compact-region topology; outer execution handles both
instructions and uses the direct descriptor. `WasmModule`, `WasmInterpreter`,
focused differential/profile tests, explicit benchmark variants, opcode
labels, cache-format checks, and the phoneME receipt plumbing are affected. No
cartridge fingerprint, hard-coded function index, or Game-of-Life-specific
runtime path is permitted.

The dense W4IR cache format must rise from 16 to 17 (and the non-dense
development format from 14 to 15) because the function fingerprint is
calculated before fusion and cannot distinguish the new post-fusion stream.
The W4IR array length, branch descriptor arrays, direct-branch arrays, local
frames, and persistent heap shape otherwise remain unchanged.

**Alternatives and research verdicts.** A full decode-time inline of Game of
Life functions 7, 8, and 9 is rejected for this cycle: preserving their
callee-relative branch heights, explicit return, local namespace, profiler
identity, cache-hit path, and budget semantics requires new persisted
metadata and approximately 6-7 KiB of additional W4IR/direct-map storage for
one module. A narrower caller-side defined-leaf path would remove only one
Java frame while retaining nested `execute`; its estimated 0.3-1.0% effect
and risk of increasing `execute` max locals make it a later spike.
`i32.load8_u + local.set` is retained as the next bounded candidate: it covers
202,884 Game of Life pairs and has a successful load/tee precedent, but it is
narrower than the current control-flow reserve and cannot substitute for it
merely because it is easier.

**Baseline identity and planned evidence.**

- source: clean `main@63f82aad4399321be6a143ddb889ac1e94430573`;
- retained NJIT-020 staged artifact:
  `039bf358fe35847b92eed13afe9e1e6f5b4623b9604a19a349eefafbbef183e4`;
- retained counterless exactness artifact:
  `16a3364cf2f635eaea07d0993716a2025c7b5fd7900158d6a4869dfb3b84868c`;
- station/base JAR SHA-256:
  `ab1067d494818feae0f933efe196a52f4b965b0e00862a7a6bc8b2425eba28fb`
  and
  `4752473a5a81925003ec16459cdedd811f987eed9b03c7876e365b9aa11c34df`;
- native i686 phoneME:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

Record new clean baseline and candidate staged-tree hashes after building the
isolated snapshots. Focused correctness must cover every signed relation at
minimum/maximum and neighboring values; taken and untaken branches; arity-zero,
arity-one, loop, block, and function-return targets; stack underflow; every
budget point before the comparison, between comparison and `br_if`, and after
the branch; direct-path hits and canonical fallback. The complete seven
full-state workloads, exact Game of Life checkpoint, profiling stream,
resident/paged/promoted W4IR, format-16 rejection and rebuild, Java 1.3, CLDC
API lint, classfile 47, preverification, release JARs, dense tableswitch,
StackMaps, and the 7,800-byte `execute` limit must pass. Record class/JAR size,
method bytes, max locals, W4IR topology, compact counters, and zero persistent
heap growth.

Run at least twelve balanced native i686 phoneME pairs on the exact one-frame
Game of Life route. Require a timer-resolved median improvement of at least
+0.8%, at least nine wins, identical logical/oracle/tier fields, and no
resolved regression worse than -0.5% on Waternet, Rubido, or Untangle. The
primary A/B changes only this signed direct-branch fusion. Static dispatch
reduction, HotSpot, KEmulator, and QEMU timing cannot accept it.

**Correctness, bytecode, cache, and heap gates before timing.** The isolated
implementation and its focused fixture pass `just verify`. The focused smoke
contains seven static fusion sites and 13 dynamic executions across all three
signed relations. It covers signed minimum/maximum and adjacent values,
taken and untaken branches, arities zero through two, loop, block, and
function-return targets, direct hits and canonical fallback, stack underflow,
every outer and compact instruction-budget boundary, active lower stack, and
the profiling stream. Its exact receipt is:

```text
PASS signed-compare-branch-fusion sites=7 direct=4 fallback=3 dynamic=13 outer-dispatches-saved=13 compact-outer-saved=9 compact-comparisons=4 logical=179 compact-logical=90187 budget=outer+compact stack=exact profiler=exact
```

The complete counterless exactness artifact is
`8243280e981df134426a9d5c6f24a410b82697ef7fda0ae5a221f0d32a1d917e`.
All seven `REFERENCE` versus production-candidate full-state workloads pass
at W4IR format 17, including the exact one-frame Game of Life result at
12,802,761 logical instructions, memory SHA-256
`45198d7efef567bfe59fee600cc06a41f288bfcf959d46716f66cfee3dc5cc5a`,
and framebuffer FNV-1a `a9255758`. Java source/target 1.3, the CLDC-only API
build, classfile 47, StackMap preverification, dense `tableswitch`, both
release JARs, cartridge integrity, traps, budgets, and the complete host test
matrix pass. KEmulator independently passes both the generic 60-frame W4IR
execution route and the old-format rejection/rebuild, build, cache-hit,
descriptor, 12-slot paging, promotion, and compact-execution probe.

The diagnostic and counterless target-47 `execute` methods are respectively
7,340 and 7,308 code bytes, both below the 7,800-byte ceiling and both with
`max_stack=10` and `max_locals=133`. The candidate unpreverified diagnostic
and counterless interpreter classes are 53,584 and 53,498 bytes. The
preverified release interpreter class is 80,716 bytes. Candidate station/base
release JARs are 230,122/227,608 bytes with SHA-256
`df2c59988c4a9bbda6e9db328ecd00acbc3f02602aafc848f38471b4a891a96d`
and
`121153be16e49a3396ce280766748d050b1a2c1027f7e96b20a4644cf2acb536`.
The format bump adds one opcode but no W4IR record, branch-descriptor,
direct-branch, local-frame, or value-stack slot. The candidate selection flag
is threaded only through decode-time method arguments; no persistent module
or interpreter field, array, retained object, or device-heap state is added.
Clean source snapshots, exact staged-tree hashes, and final baseline deltas
remain part of the authoritative timing gate rather than this dirty-tree
correctness receipt.

**Clean artifacts and timing method.** The stable source snapshot is clean
`63f82aad4399321be6a143ddb889ac1e94430573`; the isolated candidate snapshot
is clean temporary commit
`0aeacca9c80efcffab0b3c999ffdee0d66048445`. Their complete phoneME build
artifacts are respectively
`039bf358fe35847b92eed13afe9e1e6f5b4623b9604a19a349eefafbbef183e4`
and
`4f0f7788ec93875b87e0c1919a7337899fee6dfbbba6db1ffb90de1c1b471406`;
their production counterless preverified class trees are
`559cf436bf9eafe3d8ed515504ce557c52da9c1ddcfba0e0b113d832ffbe89f5`
and
`e2b6d624629669d67c2d1f5a2117ab5eb1b11505e1155393ea3647e01f4be89f`.
Both snapshots report `source-dirty=no`, Java source/target 1.3, the same
native VM, CLDC, preverify, cartridge, oracle, and 64-MiB heap identities.
The expected W4IR format difference is 16 versus 17; all logical, checkpoint,
branch-metadata, framebuffer, palette, input, tone, and disk fields match.

Two timing layers distinguish the intended fusion from whole-class layout:

1. A same-class isolate uses the candidate class tree for both sides and
   switches the decode-time fusion flag only. Both sides therefore have format
   17 and byte-identical classes. The Game of Life staged tree is
   `b146dc6fc3786f4e4fc4e5410347a56aef0959256a5b2fb99f3b5dd3f6e92c25`;
   routed controls use
   `362fd1785da10f2cde60a4cd5ff3cc61f00381e27c74b2407dd23f0455a1ac82`.
2. The decisive production comparison executes stable format-16 classes
   against candidate format-17 classes, with no runtime candidate branch. It
   therefore includes the actual method, class, constant-pool, and handler
   layout that would ship.

The same-class raw baseline/candidate microseconds per frame were:

| Pair | Game of Life B/C | Waternet B/C | Rubido B/C | Untangle B/C |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 3,308,000 / 3,081,000 | 17,026 / 17,045 | 102,255 / 102,325 | 4,773 / 4,750 |
| 1 | 3,312,000 / 3,117,000 | 17,124 / 17,052 | 101,759 / 102,124 | 4,765 / 4,786 |
| 2 | 3,296,000 / 3,136,000 | 17,078 / 16,993 | 101,976 / 102,472 | 4,771 / 4,810 |
| 3 | 3,322,000 / 3,117,000 | 17,039 / 17,104 | 101,759 / 102,379 | 4,765 / 4,782 |
| 4 | 3,756,000 / 3,077,000 | 17,326 / 17,026 | 101,899 / 102,472 | 4,765 / 4,734 |
| 5 | 3,284,000 / 3,014,000 | 17,045 / 16,954 | 102,348 / 102,395 | 4,793 / 4,797 |
| 6 | 3,332,000 / 3,073,000 | 16,921 / 16,771 | 102,186 / 101,992 | 4,821 / 4,765 |
| 7 | 3,289,000 / 3,152,000 | 16,921 / 16,954 | 101,891 / 102,124 | 4,800 / 4,717 |
| 8 | 3,284,000 / 3,106,000 | — | — | — |
| 9 | 3,314,000 / 3,138,000 | — | — | — |
| 10 | 3,282,000 / 3,121,000 | — | — | — |
| 11 | 3,276,000 / 3,149,000 | — | — | — |

Same-class paired results are +5.654% Game of Life, 12/12 wins;
+0.459% Waternet, 5/3; -0.294% Rubido, 1/7; and +0.199% Untangle,
4/4. This proves that the fusion mechanism is useful on Game of Life and
that its Rubido instruction-stream effect alone stays inside the -0.5%
control limit. It cannot accept production code because it intentionally
removes the candidate's class-layout cost from both sides.

The production raw baseline/candidate microseconds per frame were:

| Pair | Game of Life B/C | Waternet B/C | Rubido B/C, first | Rubido B/C, repeat | Untangle B/C |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 3,236,000 / 3,092,000 | 16,986 / 16,751 | 100,697 / 101,736 | 100,155 / 101,899 | 4,750 / 4,743 |
| 1 | 3,293,000 / 3,095,000 | 16,862 / 17,071 | 101,480 / 102,542 | 100,860 / 101,736 | 4,800 / 4,780 |
| 2 | 3,229,000 / 3,105,000 | 17,098 / 16,986 | 101,279 / 102,038 | 100,837 / 101,713 | 4,826 / 4,769 |
| 3 | 3,291,000 / 3,126,000 | 16,973 / 17,013 | 100,348 / 101,844 | 100,519 / 101,829 | 4,808 / 4,754 |
| 4 | 3,299,000 / 3,090,000 | 17,000 / 17,117 | 101,325 / 102,240 | 100,806 / 102,263 | 4,767 / 4,754 |
| 5 | 3,248,000 / 3,141,000 | 16,830 / 16,758 | 100,643 / 102,054 | 101,488 / 101,821 | 4,795 / 4,780 |
| 6 | 3,285,000 / 3,134,000 | 16,973 / 16,967 | 100,759 / 102,286 | 100,697 / 102,255 | 4,791 / 4,734 |
| 7 | 3,275,000 / 3,117,000 | 16,928 / 16,973 | 101,085 / 102,465 | 100,457 / 101,922 | 4,793 / 4,706 |
| 8 | 3,245,000 / 3,101,000 | — | — | — | — |
| 9 | 3,321,000 / 3,178,000 | — | — | — | — |
| 10 | 3,318,000 / 3,059,000 | — | — | — | — |
| 11 | 3,308,000 / 3,105,000 | — | — | — | — |

Production Game of Life measures **+4.711%**, +154,500 us/frame, and
12/12 wins at 1,000 us/frame resolution. Waternet measures -0.100%,
-17 us/frame, and 4/4. Untangle measures +0.770%, +37 us/frame, and
8/8. The first Rubido control measures **-1.206%**, -1,221 us/frame,
and 0/8; an independent repeat measures **-1.374%**, -1,383.5 us/frame,
and 0/8. Every summary reports timer-resolved effects, balanced order,
clean source, and exact deterministic outputs. Pair CSV SHA-256 values are:

- Game of Life:
  `6c65b989b3f0bf5cb25010e71ab35d23f2a1220814b622019e25d15bfacdfb96`;
- Waternet:
  `709eaacc15bb85d45823cfe5a25f0861472899a21383ffb4d722455fffd12323`;
- first Rubido:
  `86ba0fd8727eeac9a1dbd96aa605a56be3297147e8024881938d6ac7d3b69ea7`;
- repeated Rubido:
  `6566628c3086a65c6677c2a263d5887fa6da1dbe39833235d0e9dd1184c1901b`;
- Untangle:
  `3a2dc086726254411c52cdf96fca92139bb3641102e5539c02488586d6280590`.

The production diagnostic stream confirms the intended topology: Game of
Life outer dispatches fall from 5,565,951 to 4,749,628, exactly 816,323
fewer, while compact calls and compact instructions remain 482,291 and
6,407,444. The candidate grows diagnostic/counterless `execute` from
7,039/7,007 to 7,340/7,308 bytes. The preverified release interpreter grows
from 79,587 to 80,716 bytes; station/base JARs grow from
229,207/226,693 to 230,122/227,608 bytes, +915 each. W4IR rises from format
16 to 17 but adds no record, direct-map entry, field, allocation, or
persistent device-heap state.

**Decision.** Reject and remove the implementation. It delivers a large,
repeatable Game of Life improvement and preserves exact behavior, but the
actual production artifact regresses Rubido by more than twice the
predeclared -0.5% limit in two independent unanimous series. The same-class
isolate localizes the additional loss to whole-class or handler layout rather
than the signed-pair stream alone, but production layout is part of the
shipping cost and cannot be excluded from the verdict. No production commit
is made.

The opcode, format bump, handlers, decode flag, benchmark variants, focused
fixture, and test-runner wiring were then removed exactly. `src/main`,
`src/test`, and `tools` are byte-identical to stable
`63f82aad4399321be6a143ddb889ac1e94430573`; only this durable ledger and
task history remain changed. The restored tree passed `just verify`, including
all seven exact full-state workloads, replay/framebuffer oracles, traps,
instruction budgets, resident/paged/promoted W4IR, Java 1.3, CLDC API lint,
classfile 47, StackMap preverification, release integrity, and counterless
exactness. W4IR is back at format 16, diagnostic/counterless `execute` are
7,039/7,007 bytes, and the stable counterless artifact is
`16a3364cf2f635eaea07d0993716a2025c7b5fd7900158d6a4869dfb3b84868c`.
Station/base JARs are again 229,207/226,693 bytes with SHA-256
`ab1067d494818feae0f933efe196a52f4b965b0e00862a7a6bc8b2425eba28fb`
and
`4752473a5a81925003ec16459cdedd811f987eed9b03c7876e365b9aa11c34df`.

**Reconsideration condition if rejected:** only branch-capable compact regions,
a relation-specific handler that removes a demonstrated inner-dispatch cost,
an implementation that recovers the measured Rubido class-layout loss, or
physical-device evidence that contradicts the native phoneME result.

### NJIT-022: `i32.load8_u + local.set` fusion

**Status:** `rejected`.

**Hypothesis, source, and dynamic coverage.** The corrected production-stream
profile at SHA-256
`7ba74f3fc820a95b62abddde3e5d2c0434397254cf2b219640805d73cf646fad`
contains 202,884 adjacent `i32.load8_u + local.set` pairs in the exact
one-frame Game of Life route. That is 66.46% of its 305,291 dynamic
`i32.load8_u` operations and 2.05% of its 9,888,650 profiled W4IR dispatches.
The pair can remove at most 202,884 of the production tier's 5,565,951 outer
dispatches, or 3.65%, while preserving the frame's 12,802,761 logical
instructions.

The routed controls contain 10,005 pairs on Waternet, 27 on Rubido, 420 on
Untangle, and 155 on Duck Maze; generic Plasma has no recorded occurrence.
This makes Game of Life the primary performance judge and Waternet the only
material route control for the instruction stream, while Rubido and Untangle
remain mandatory whole-artifact no-regression controls.

The mechanism is inspired by the accepted `i32.load + local.tee` W4IR fusion.
That precedent proved exact two-phase instruction-budget accounting and
measured a small positive Game of Life effect, but it neither covers byte
loads nor removes the loaded value from the stack. NJIT-022 therefore does
not repeat a closed candidate. It isolates a different opcode pair with four
times the Game of Life coverage and a distinct final stack effect.

**Selected implementation and affected files.** Add the tail original W4IR
opcode `W4IR_I32_LOAD8_U_LOCAL_SET = 0x1033`. The fusion pass replaces only an
adjacent `0x2d + 0x21` pair when the second token is not a branch target. The
memory offset remains in `operand`, the local index is copied into
`auxiliary`, and the second token is cleared through the existing
`replacePair` mechanism. Do not absorb a preceding
`W4IR_I32_ADD_CONST`, even though that triple has the same 202,884 Game of
Life executions; it is a separate three-instruction candidate with another
budget boundary.

The outer handler preserves the exact unfused observable order:

1. the dispatcher charges `i32.load8_u`;
2. stack underflow traps without mutation;
3. the address is removed from the value stack before address validation;
4. an invalid address traps with the address already removed and the local
   unchanged;
5. a valid byte is zero-extended and placed back on the value stack;
6. the handler charges `local.set` and checks its instruction budget;
7. an intermediate budget trap leaves the loaded byte on the stack and the
   local unchanged;
8. successful `local.set` writes the local and removes the loaded byte.

The compact handler uses the same two-phase accounting as the accepted
load/tee fusion, reports span two, and remains compact-eligible. A single
range check identifies the two special load/local opcodes that account their
first instruction before the handler and their second instruction inside it;
do not add an `A || B` branch to every compact dispatch. The existing
decode-time load/local-fusion boolean controls both handlers only for focused
differentials. Production keeps the default enabled, and the focused
NJIT-022 fixture contains no `i32.load + local.tee` site, so its enabled versus
disabled comparison remains isolated without adding a module field or runtime
selection branch.

`WasmModule`, `WasmInterpreter`, opcode profile labels, the dense-map
differential, one focused WAT/Java smoke, and test-runner wiring are affected.
The dense W4IR format rises from 16 to 17 and the non-dense development format
from 14 to 15 because the cartridge fingerprint is calculated before fusion
and cannot distinguish the new post-fusion stream. The W4IR stride and token
count, branch metadata, stack/local arrays, and persistent heap shape remain
unchanged.

**Exactness, compatibility, and artifact risks.**

- Cover loaded bytes `0x00`, `0x7f`, `0x80`, and `0xff`, the final valid
  address, nonzero static offsets, signed-negative dynamic addresses, and a
  large unsigned static offset.
- Compare complete memory, globals, table, trap class/text, logical
  instruction count, and final results in forced-outer and compact execution.
- Use a sentinel below the address and inspect the private value stack at the
  intermediate budget boundary to prove that the byte remains on top while
  the local is unchanged.
- Sweep the budget before the load, between load and set, and after set in
  both executor modes. An out-of-bounds load must not write the local.
- Count the exact fused sites and saved outer dispatches, and profile compact
  calls/instructions to detect a four-dispatch-region topology loss.
- Exercise resident, paged, promoted, checksum-invalid, and previous-format
  RMS paths. Format 16 must be rejected and rebuilt rather than interpreted
  as format 17.
- Preserve Java source/target 1.3, CLDC 1.1, classfile major 47,
  preverification, dense `tableswitch`, StackMaps, both release JARs, and the
  7,800-byte diagnostic `execute` ceiling.

Expected target-47 growth is approximately 75--120 bytes in `execute` and
90--130 bytes in `executeCompactBlock`; the current stable methods are
7,039/7,007 bytes for diagnostic/counterless `execute`, leaving sufficient
headroom only if the actual compiled forms remain within the gate. The opcode
adds no field, array, allocation, W4IR record, or persistent device-heap byte.
The principal performance risks are compact-region erosion, whole-class
layout sensitivity like NJIT-021, and helper/frame cost overwhelming the
single removed W4IR dispatch.

**Baseline identity.**

- source: clean `main@63f82aad4399321be6a143ddb889ac1e94430573`;
- retained production phoneME artifact:
  `039bf358fe35847b92eed13afe9e1e6f5b4623b9604a19a349eefafbbef183e4`;
- retained counterless exactness artifact:
  `16a3364cf2f635eaea07d0993716a2025c7b5fd7900158d6a4869dfb3b84868c`;
- station/base JAR SHA-256:
  `ab1067d494818feae0f933efe196a52f4b965b0e00862a7a6bc8b2425eba28fb`
  and
  `4752473a5a81925003ec16459cdedd811f987eed9b03c7876e365b9aa11c34df`;
- stable `WasmInterpreter.java` / `WasmModule.java` SHA-256:
  `b12f7966d446529216374e9fa520a1d5375b4dce6dd9e914b0f0f927e1caaf16`
  and
  `6a155c8cc6ba04a007df6790d9c73c8fb39215502ed77a13b816b572ab85da41`;
- native i686 phoneME:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

Record new clean baseline and candidate staged-tree hashes after producing the
isolated snapshots. Planned correctness commands are `just test`, then
`just verify`, followed by native checkpoint sanity through:

```sh
PHONEME_HOME=.local/phoneme tools/phoneme/run.sh bench \
  waternet rubido untangle game-of-life-zig-edition \
  --candidate host-import-id --reps 1
```

The decisive production comparison alternates clean format-16 baseline and
format-17 candidate preverified trees directly under
`.local/phoneme/cldc_vm_r -EnableTicks =HeapCapacity64M`, with no runtime
candidate branch. Run at least twelve balanced pairs on the exact one-frame
Game of Life route. Require a timer-resolved median improvement of at least
`+0.8%`, at least nine wins, exact oracle/logical/tier fields, and no resolved
regression worse than `-0.5%` on Waternet, Rubido, or Untangle. Record every
raw pair, timer resolution, class/method/JAR delta, W4IR topology, heap delta,
artifact hash, decision, and reconsideration condition before retaining or
removing the code.

**Correctness, profile, and artifact results before timing.** The isolated
candidate passes `just verify`, including the focused differential, all replay
oracles, all seven full-state workloads, traps, instruction budgets, Java
source/target 1.3, the CLDC-only API build, classfile 47, StackMap
preverification, dense `tableswitch`, release integrity, and counterless
exactness. The focused receipt is:

```text
PASS i32-load8-u-local-set-fusion sites=10 update-executions=5 outer-dispatches-saved=5 bytes=00,7f,80,ff,last budget=outer+compact stack=exact traps=negative,oob,large-offset,underflow compact=exact
```

The complete format-17 state matrix retains the exact Game of Life result at
`12,802,761` logical instructions, memory SHA-256
`45198d7efef567bfe59fee600cc06a41f288bfcf959d46716f66cfee3dc5cc5a`,
and framebuffer FNV-1a `a9255758`. KEmulator independently passes the
old-format rejection and rebuild, resident build, cache hit, static
descriptors, 12-slot paging, promotion, and compact execution probe with
framebuffer `2e572184`.

The exact production-profile artifact is
`b7e7478370aeb8a00bf932605818e364c3dca282565366b00895cba6128bf70e`;
its complete report SHA-256 is
`d5bda7a1099dcbb50532a4496f7ae6f12bc6f6b70a5694dbf9ce66ef00d47bfd`.
It corrects the control-route fused counts to 10,075 Waternet, 61 Rubido, 463
Untangle, and 155 Duck Maze while retaining exactly 202,884 Game of Life
executions. The raw profiled Game of Life stream falls from 9,888,650 to
9,685,766 dispatches, exactly one per fused pair. In the production tier,
however, outer dispatches fall only from 5,565,951 to 5,564,838 because most
sites execute inside compact blocks. Compact calls and logical compact
instructions remain exactly 482,291 and 6,407,444, so the candidate does not
erode compact-region topology.

Diagnostic/counterless `execute` grow from 7,039/7,007 to 7,175/7,143 code
bytes and retain respectively 625/657 bytes of headroom below the 7,800-byte
gate. Candidate diagnostic/counterless `executeCompactBlock` are 3,002/2,959
code bytes. The unpreverified diagnostic/counterless interpreter classes are
53,329/53,229 bytes. The candidate counterless exactness artifact is
`1732cc1f5e2e970ffe5ecba5effb67099d97177c86c6bb2ead6f5e12ed3cf440`.
The verified station/base JARs are 229,474/226,960 bytes with SHA-256
`d912cbfcfd9c89fa27d71639b5533c6b52c0e54d000d98c5a95cb9bd6eab1490`
and
`506ca021d17e1ba8664aca168f91a6f4a9dba8634f3bdcefab71806850af88bf`.
No interpreter or module instance field, array, allocation, W4IR record,
direct-map entry, stack/local slot, or persistent device-heap state is added.
`WasmModule` gains only the compile-time static-final opcode constant; the
cache format also changes. Clean baseline/candidate class and staged-tree
deltas remain to be bound by the timing snapshots.

**Clean timing artifacts.** The fixed snapshots under
`/tmp/w4me-njit022.yvNFhI/` are clean commits
`63f82aad4399321be6a143ddb889ac1e94430573` for the baseline and
`7a654f4a6b18c5f044286d9d1be648d9af0282c8` for the candidate. Their only
production differences are the isolated `WasmInterpreter` and `WasmModule`
hunks described above. Complete staged phoneME artifact SHA-256 values are
respectively
`039bf358fe35847b92eed13afe9e1e6f5b4623b9604a19a349eefafbbef183e4`
and
`f2a773e1e8f134f1f8c6ca540519bcf9eecfe813b5ba2d712d63f4cd4f0d97bd`.
Both receipts report clean source, Java source/target 1.3, the native VM,
CLDC, and preverify hashes recorded above, a 64 MiB judge heap, and the
production `host-import-id` configuration.

The clean target-47 `WasmInterpreter.class` grows from 52,969 to 53,359 bytes
(+390), and its preverified form grows from 79,587 to 80,337 bytes (+750).
Their target-47 SHA-256 values are
`4f7ebc4dd671c1c7311282b6da549326fd0658af2ecedf98e3729caf3e498e76`
and
`fed3caa39212506222a6163add19313b659113a279e085b8e9879afffdccd494`;
their preverified hashes are
`89f88b9d3ce8cf70a2782ff7fe0e332177cb20de68940a44d0f615cbefbed6c3`
and
`8241215926a019b980abb4cd407ecc35fd7e0e0935097fa1ca52f7e8cf7446c3`.
The clean target-47 `WasmModule.class` grows from 34,723 to 34,778 bytes
(+55), and its preverified form grows from 45,352 to 45,407 bytes (+55).
Diagnostic `execute` grows by 136 code bytes, from 7,039 to 7,175, while
`executeCompactBlock` grows by 154, from 2,848 to 3,002. No persistent heap
object or per-module array is added.

**Native i686 phoneME A/B.** Twelve balanced pairs used the exact one-frame
Game of Life route. Every invocation passed its checkpoint and reported
12,802,761 logical instructions, 482,291 compact calls, 6,407,444 compact
instructions, and identical branch-fast metadata. The candidate removed
exactly 1,113 outer dispatches in every pair. Raw microseconds per frame were:

| Pair | Order | Baseline | Candidate |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 3,419,000 | 3,468,000 |
| 1 | candidate first | 3,502,000 | 3,466,000 |
| 2 | baseline first | 3,482,000 | 3,460,000 |
| 3 | candidate first | 3,407,000 | 3,389,000 |
| 4 | baseline first | 3,475,000 | 3,525,000 |
| 5 | candidate first | 5,192,000 | 3,465,000 |
| 6 | baseline first | 3,445,000 | 3,456,000 |
| 7 | candidate first | 3,462,000 | 3,509,000 |
| 8 | baseline first | 3,431,000 | 3,468,000 |
| 9 | candidate first | 3,434,000 | 3,455,000 |
| 10 | baseline first | 3,472,000 | 3,387,000 |
| 11 | candidate first | 3,480,000 | 3,456,000 |

The paired median is +3,500 us/frame, or only **+0.105%**, with six wins and
six losses. The 1,000 us/frame timer resolution is below the median effect,
order is balanced, and source is clean. Pair 5 contains an isolated slow
baseline outlier; it favors the candidate and does not change the median
failure. The pair CSV, paired summary, and dispatch receipt SHA-256 values
are respectively
`7ef7f03b750e237b16faae3d0290d313525d7c66ccf122e09f6359cfe9d05696`,
`f3801619bfdeb2d7c0a8fad7a2606e7e089fafc1bb9c7ac531ddf24f6d261e46`,
and
`c8549992bd6aef1d8c45432c0f7b75b03aedba96443ca94cdd96a1943427f98d`.
Raw files remain under
`/tmp/w4me-njit022.yvNFhI/evidence/game-of-life-zig-edition/` for the
lifetime of this host session.

**Decision.** Reject and remove the implementation. The candidate is exact,
preserves compact topology, and removes the predicted outer dispatches, but
it misses both predeclared primary gates: +0.105% versus the required +0.8%,
and 6/12 wins versus the required 9/12. Most of the 202,884 fused pairs run
inside compact blocks, where the new handler replaces rather than eliminates
an inner dispatch, while the whole interpreter class grows by 390 target-47
bytes. Waternet, Rubido, and Untangle timing controls cannot make the failed
primary gate pass and were therefore not spent after their exact clean-artifact
sanity runs.

**Reconsideration condition if rejected:** only a three-instruction form that
also removes the preceding address calculation, a compact handler that
demonstrably reduces inner-dispatch work rather than merely replacing it, a
future class-layout change that eliminates the added handler cost, or a more
precise physical-device measurement showing a materially larger effect.

The opcode, handlers, format bump, focused fixture, profile label, dense-map
expectation, and test-runner wiring were removed exactly. Production, test,
and tool files then matched stable
`main@63f82aad4399321be6a143ddb889ac1e94430573` byte for byte. The restored
tree passed `just verify`: all seven full-state workloads are exact at W4IR
format 16, diagnostic/counterless `execute` are 7,039/7,007 bytes with dense
`tableswitch`, both release JARs are Java 1.3/CLDC-preverified, and the stable
counterless artifact is again
`16a3364cf2f635eaea07d0993716a2025c7b5fd7900158d6a4869dfb3b84868c`.
Station/base JARs returned to 229,207/226,693 bytes with SHA-256
`ab1067d494818feae0f933efe196a52f4b965b0e00862a7a6bc8b2425eba28fb`
and
`4752473a5a81925003ec16459cdedd811f987eed9b03c7876e365b9aa11c34df`.
No production commit is made for NJIT-022.

### NJIT-023: `i32.add_const + i32.load8_u + local.set` fusion

**Status:** `rejected`.

**Why this is not a repeat of NJIT-022.** NJIT-022 fused only
`i32.load8_u + local.set`. Although the exact Game of Life stream executed
that pair 202,884 times, most sites were already inside compact blocks. The
candidate therefore removed only 1,113 outer dispatches, left all 482,291
compact calls and 6,407,444 compact logical instructions unchanged, and
measured only +0.105% with 6/12 wins. Its reconsideration condition explicitly
allows a form that also absorbs the preceding address calculation and removes
inner compact-dispatch work.

The stable format-16 production profile now proves that every one of those
202,884 Game of Life pairs is immediately preceded by
`W4IR_I32_ADD_CONST`. That token already represents the original
`i32.const + i32.add`, so the selected three-token W4IR sequence represents
four logical WebAssembly instructions. One combined handler replaces three
compact switch iterations with one rather than merely replacing the load/set
iteration. The stable profile artifact is
`402d9966b4e3b09b9b97fc14c5d16709e8957314dc93f1d6e4220752f7710b0b`;
the complete report SHA-256 is
`e9be1bf62e7499874da12fc3e119fa0f4c379a7e0654379e79c1137af029c59c`.
It passes all seven full-state workloads at W4IR format 16.

**Coverage and workload selection.** The exact triple executes 202,884 times
in one Game of Life frame and 1,584 times over the 94-frame Waternet route
(16.85 per frame). It does not occur on the routed Rubido, Untangle, Duck
Maze, or generic Plasma workloads. Game of Life is therefore the only primary
mechanism judge. Waternet checks the low-coverage stream, while Rubido and
Untangle remain mandatory whole-class-layout controls because NJIT-021 proved
that a zero-coverage or low-coverage route can regress after a large handler
changes the phoneME dispatch layout.

The stable Game of Life tier executes 12,802,761 logical instructions,
5,565,951 outer dispatches, 482,291 compact calls, and 6,407,444 compact
logical instructions. Static dispatch reduction is selection evidence only:
native i686 phoneME remains the speed judge.

**Selected representation and implementation.** Add the tail original W4IR
opcode `W4IR_I32_ADD_CONST_LOAD8_U_LOCAL_SET = 0x1033` and bump dense/non-dense
formats from 16/14 to 17/15. The post-pair fusion pass recognizes only:

1. `W4IR_I32_ADD_CONST` at index `pc`, whose cleared second original
   instruction remains at `pc + 1`;
2. `i32.load8_u` at `pc + 2`;
3. `local.set` at `pc + 3`;
4. neither active successor is a branch target.

The add constant remains in `operand`; the full unsigned memory offset moves
to `auxiliary`; and the validated local index is stored in the high 16 bits of
the instruction word. This is lossless because the decoder caps total locals
at 4,096. Dense opcode rewriting already preserves the instruction high bits.
The two active successor records are cleared, W4IR stride and instruction
count do not change, and old format 16 records are rejected and rebuilt.

Both executors preserve the existing optimized baseline's exact order:

1. charge and check the first logical instruction;
2. execute the current add-constant stack effect;
3. charge the second logical instruction exactly as the current fused add
   handler does;
4. charge and check `i32.load8_u` before popping its address;
5. pop and validate the effective address, leaving the local unchanged on a
   trap;
6. zero-extend and push the loaded byte;
7. charge and check `local.set`, leaving the byte on the stack on an
   intermediate budget trap;
8. write the local and remove the byte.

The compact handler performs all four accounting phases itself, reports span
four, and remains compact-eligible. It must preserve the current baseline's
add-result stack state at the budget boundary before the load. No runtime
selection branch, module field, array, allocation, direct-map entry, or
persistent heap object is added. The existing decode-time
`loadTeeFusionsEnabled` flag controls the new fusion only for focused
differentials; production keeps it compiled on.

**Correctness and artifact gates.** Add an independent WAT/Java differential
covering add wraparound, byte values `0x00`, `0x7f`, `0x80`, and `0xff`,
nonzero and large unsigned memory offsets, the final valid byte, negative and
overflowed dynamic addresses, local indices above 255, stack underflow,
address traps after the add result is popped, and every budget boundary in
forced-outer and compact execution. Compare complete memory, globals, table,
value-stack contents, locals/results, trap class/text, and logical counters
with fusion disabled.

Run `just test`, `just verify`, the exact production corpus, and the
KEmulator W4IR cache matrix. Require Java source/target 1.3, CLDC-only
compilation, classfile major 47, StackMap preverification, dense
`tableswitch`, both release JARs, previous-format rejection/rebuild,
resident/paged/promoted equivalence, and the 7,800-byte diagnostic `execute`
ceiling. Record diagnostic/counterless method and class growth, JAR deltas,
compact-region topology, staged-tree hashes, and the zero persistent-heap
delta before timing.

**Baseline and native acceptance rule.**

- source:
  `main@63f82aad4399321be6a143ddb889ac1e94430573`;
- production phoneME artifact:
  `039bf358fe35847b92eed13afe9e1e6f5b4623b9604a19a349eefafbbef183e4`;
- counterless exactness artifact:
  `16a3364cf2f635eaea07d0993716a2025c7b5fd7900158d6a4869dfb3b84868c`;
- native i686 VM:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

Build clean production-shaped baseline and candidate artifacts with no runtime
candidate branch. Run at least twelve balanced exact one-frame Game of Life
pairs. Require a timer-resolved median improvement of at least +0.8%, at
least 9/12 wins, identical oracle/logical/tier fields, and a stable predicted
dispatch delta. Only if the primary passes, run at least eight balanced
Waternet, Rubido, and Untangle controls and reject any resolved regression
worse than -0.5%. Record and remove a failed implementation before selecting
another candidate.

**Correctness and artifact results.** The isolated implementation passes the
focused differential, `just verify`, all replay oracles, all seven full-state
workloads, Java source/target 1.3, the CLDC-only API build, classfile 47,
StackMap preverification, dense `tableswitch`, both release JARs, and
counterless exactness. The focused receipt is:

```text
PASS i32-add-const-load8-u-local-set-fusion sites=6 wide-local=259 outer-dispatches-saved=12 compact-blocks=2 logical=90057 budget=outer+compact traps=negative,oob,offset,underflow cache=build+hit profile=exact
```

It covers bytes `00/7f/80/ff`, address 65,535, signed wrapping, a local above
255, all outer and compact budget boundaries, stack underflow, negative/OOB
and unsigned-large offsets, complete private stack/local state, in-memory
W4IR build/hit, page faults, and the persisted opcode. During implementation
two focused failures were corrected before timing: the compact handler first
double-counted one logical instruction, and counting the fused token as one
eligibility dispatch could remove a reference four-dispatch compact region.
The retained test proves exact logical accounting and weights the new token as
three replaced compact dispatches only for the region eligibility threshold.

The complete format-17 state matrix retains the exact Game of Life result at
12,802,761 logical instructions, memory SHA-256
`45198d7efef567bfe59fee600cc06a41f288bfcf959d46716f66cfee3dc5cc5a`,
and framebuffer FNV-1a `a9255758`. The candidate counterless exactness
artifact is
`4517f6aa079da824a88b114928e3db976cae84b99b22b5b391cee3509f9f5c29`.
KEmulator independently passes old-format rejection/rebuild, resident build,
cache hit, static descriptors, 12-slot paging, promotion, and compact
execution with framebuffer `2e572184`.

The diagnostic/counterless `execute` methods grow from 7,039/7,007 to
7,246/7,214 code bytes, retaining 554/586 bytes below the 7,800-byte gate.
Diagnostic/counterless `executeCompactBlock` grow from 2,848/2,815 to
3,130/3,071 bytes. The verified candidate station/base JARs are
229,761/227,247 bytes, both +554 bytes, with SHA-256
`32d1d9b8aaae839ae1f96af7f2a561af88104af01c5302b6188707187b7ca4c2`
and
`cbd9bf07280e18a21a4d268fb41256eb5adef17c1cb9cf4ea844d0d828e47616`.
There is no new interpreter/module instance field, array, allocation, W4IR
record, direct-map entry, or persistent device-heap byte. `WasmModule` gains
only one compile-time static-final opcode constant.

**Clean timing artifacts.** The clean snapshots live under
`/tmp/w4me-njit023.Ua9e64/`. Baseline is
`63f82aad4399321be6a143ddb889ac1e94430573`; candidate is the temporary
clean commit `c05d378ad4fc90dc8f1052cb8b64f8bd4142e6ae`, whose production diff
contains only `WasmInterpreter.java` and `WasmModule.java`. Their
Game-of-Life-staged diagnostic artifacts are respectively
`fc5de15e50289c84b5b36506a7cb19c6a525be95d65389908ebd1b974589e568`
and
`aeeb60683a72a7da623b5f1768465bc18eec26d3b2353d314bbd5c6a807d4010`;
counterless artifacts are
`6c1793b14b883b4a5fc23dc8965588356a85c4ade15fd3f9727d9f3729e54e54`
and
`e757bcda499d66dd2d1e11f0374c5a15988cfe74da57f9b208441c959c61b644`.

The target-47 `WasmInterpreter.class` grows from 52,969 to 53,752 bytes
(+783), and the preverified class from 79,587 to 81,015 (+1,428). The
target/preverified `WasmModule.class` grows from 34,723/45,352 to
34,788/45,417 (+65 each). In the counterless build the interpreter grows
from 52,853/79,471 to 53,598/80,861 target/preverified bytes
(+745/+1,390). Both snapshot repositories report clean source.

**Native i686 phoneME A/B.** Twelve balanced pairs used the exact one-frame
Game of Life route on the native no-JIT VM with a 64 MiB judge heap. Every
invocation passed its checkpoint and reported 12,802,761 logical
instructions, 482,291 compact calls, 6,407,444 compact logical instructions,
and identical branch-fast metadata. The candidate reduced outer dispatches
from 5,565,951 to 5,563,725, exactly 2,226 per frame. Raw microseconds per
frame were:

| Pair | Order | Baseline | Candidate |
| ---: | --- | ---: | ---: |
| 0 | baseline first | 3,438,000 | 3,512,000 |
| 1 | candidate first | 3,447,000 | 3,415,000 |
| 2 | baseline first | 3,426,000 | 3,520,000 |
| 3 | candidate first | 3,459,000 | 3,400,000 |
| 4 | baseline first | 3,452,000 | 3,496,000 |
| 5 | candidate first | 3,429,000 | 3,470,000 |
| 6 | baseline first | 3,420,000 | 3,480,000 |
| 7 | candidate first | 3,454,000 | 3,511,000 |
| 8 | baseline first | 3,462,000 | 3,498,000 |
| 9 | candidate first | 3,399,000 | 3,439,000 |
| 10 | baseline first | 3,400,000 | 3,450,000 |
| 11 | candidate first | 3,465,000 | 3,416,000 |

The paired median is -42,500 us/frame, or **-1.235%**, with three wins and
nine losses. Timer resolution is 1,000 us/frame, order is balanced, source is
clean, and all deterministic fields are exact. The raw pair, paired-summary,
and dispatch-receipt SHA-256 values are respectively
`a06d93a040a8d9de070e8d453de8ed4f7265919d8530a604a8151a9bbedd91cc`,
`ce2cf595df7e7a13cbe16aa99ff1fd1a3b9b604607058703e6082bb54a2d87ff`,
and
`9719b5da49fae469b679fdfb66526d98eeb9802af511db94bd8a378018e1bf4f`.
Two preliminary invocations accidentally overlapped outside the sandbox PID
namespace and were discarded completely; only the single managed PTY series
under `evidence-clean/` is authoritative.

**Decision.** Reject and remove the implementation. It is semantically exact
and reduces both outer and compact inner-dispatch work, but fails both
predeclared gates and instead produces a resolved -1.235% regression. The
783-byte target-class and 282-byte compact-handler growth outweigh the saved
switch iterations on this phoneME layout. Waternet, Rubido, and Untangle
controls cannot rescue a failed primary and were therefore not spent.

Reconsider only if the same semantics can be expressed through a materially
smaller existing handler shape, a future accepted class-layout change removes
the measured regression, or precise physical-device evidence contradicts the
native phoneME result. Do not repeat the present standalone opcode and handler
layout.

The opcode, handlers, eligibility weighting, format bump, profile label,
dense-map expectation, focused fixture, and test-runner wiring were removed
exactly. Production, test, and tool files then matched stable
`main@63f82aad4399321be6a143ddb889ac1e94430573` byte for byte. The restored
tree passed `just verify`: all seven full-state workloads are exact at W4IR
format 16, diagnostic/counterless `execute` are 7,039/7,007 bytes with dense
`tableswitch`, and the stable counterless artifact is again
`16a3364cf2f635eaea07d0993716a2025c7b5fd7900158d6a4869dfb3b84868c`.
Station/base JARs returned to 229,207/226,693 bytes with SHA-256
`ab1067d494818feae0f933efe196a52f4b965b0e00862a7a6bc8b2425eba28fb`
and
`4752473a5a81925003ec16459cdedd811f987eed9b03c7876e365b9aa11c34df`.
No production commit is made for NJIT-023.

### NJIT-024: compact `i32.load8_u` direct stack/address path

**Status:** `inconclusive`.

**Hypothesis and distinction from closed work.** The stable one-frame Game of
Life profile executes 305,291 `i32.load8_u` operations. NJIT-022 proved that
202,884 of them are followed by `local.set`; only 1,113 of those pairs execute
outside compact regions, so at least 201,771 byte loads per frame execute the
existing compact `case 0x2d`. That handler currently evaluates
`pushI32(module.memory[address(operand, 1)] & 0xff)`. On the portable-C
phoneME interpreter this crosses six nested Java method boundaries:
`address`, `popI32`, `pop`, `checkedAddress`, `pushI32`, and `push`. Each
boundary creates and returns from an interpreted Java frame because phoneME
has no JIT or general Java inlining.

NJIT-005 changed only the shared `checkedAddress` algebra and measured a
correct but below-floor +0.407% Rubido result. Its ledger explicitly permits
reconsideration through a caller-inline form that removes the nested Java
frame. The historical push/pop experiment modified hot **generic** handlers
and was rejected. NJIT-024 instead changes one already selected compact
handler with new Game of Life coverage and removes the complete nested
stack/address call chain. It does not repeat NJIT-022 or NJIT-023: no new
W4IR opcode or fusion is introduced and no compact switch iteration is
replaced by a larger standalone handler.

**Selected implementation.** Change only compact `case 0x2d`. Check stack
underflow, decrement `valueTop` before validating the address exactly as
`address()` currently does, perform the existing four-condition scalar bounds
guard inline for width one, read and zero-extend the byte, and write it back
to the now-free stack slot while incrementing `valueTop`. The explicit guard
must retain signed-negative dynamic and static-offset rejection and must trap
before the array read. It must not use exception-backed memory bounds because
that would expose a Java exception and would not preserve multi-byte
follow-up semantics if the mechanism is later generalized.

The outer `i32.load8_u` handler, every other scalar width, the shared
`address`/`checkedAddress` helpers, W4IR decoding, cache format 16, instruction
accounting, compact-region metadata, and runtime selection policy remain
unchanged. The candidate adds no opcode, field, array, allocation, retained
object, local frame, or persistent device-heap byte. The expected target
effect is growth only inside `executeCompactBlock`, in exchange for removing
six interpreted Java calls from every covered compact byte load.

**Correctness and artifact gates.** A focused forced-compact differential must
cover bytes `0x00`, `0x7f`, `0x80`, and `0xff`; zero and nonzero static
offsets; the final valid byte; signed-negative dynamic and static operands;
one-past-end and wrapping addresses; stack underflow; a sentinel below the
address; and the instruction budget immediately before the load. It must
compare result/stack state, full memory, globals, table, trap class/text, and
logical/tier counters with compact execution disabled. Run the complete
`just verify` matrix, exact Game of Life checkpoint, Java source/target 1.3,
CLDC-only lint, classfile 47, StackMap preverification, dense `tableswitch`,
both release JARs, cache/device checks, and counterless exactness.

Inspect target-47 and preverified `executeCompactBlock`, complete interpreter
class/JAR deltas, max locals, and the unchanged 7,039/7,007-byte outer
`execute` methods. Reject before timing if the compiler introduces a
wide-local cascade, changes compact topology or counters, or grows the
interpreter enough to make the six-call saving implausible.

**Baseline and native acceptance plan.**

- source:
  `main@63f82aad4399321be6a143ddb889ac1e94430573`;
- stable `WasmInterpreter.java`:
  `b12f7966d446529216374e9fa520a1d5375b4dce6dd9e914b0f0f927e1caaf16`;
- production phoneME artifact:
  `039bf358fe35847b92eed13afe9e1e6f5b4623b9604a19a349eefafbbef183e4`;
- counterless exactness artifact:
  `16a3364cf2f635eaea07d0993716a2025c7b5fd7900158d6a4869dfb3b84868c`;
- station/base release JARs:
  `ab1067d494818feae0f933efe196a52f4b965b0e00862a7a6bc8b2425eba28fb`
  and
  `4752473a5a81925003ec16459cdedd811f987eed9b03c7876e365b9aa11c34df`;
- native i686 phoneME:
  `bb4866969747430bb619d139c75ab31982e8967aa0e2dcc3e278fcc7920839a2`;
- CLDC classes:
  `117820661071b411b3937e8c708a9581aa48ba06fd06e24eadb5ebbf2036afbe`;
- preverify:
  `4fe0d1b160ac7f18c4f7489917a1d868ff82df50842ca718729b098b25f2f50c`.

Build clean, production-shaped baseline and candidate artifacts with no
runtime candidate branch. Run at least twelve balanced native i686 phoneME
pairs on the exact one-frame Game of Life route. Require a timer-resolved
median improvement of at least +0.8%, at least 9/12 wins, and identical
checkpoint, logical, outer-dispatch, compact-call, compact-instruction, and
branch metadata. If the primary passes, run at least eight balanced Waternet,
Rubido, and Untangle controls and reject a resolved regression worse than
-0.5%. Record every raw pair and remove a failed candidate before selecting
the next experiment.

**Stopped prototype result.** The isolated source form compiled successfully
with Java source/target 1.3 and produced preverified release JARs. The outer
`execute` method remained exactly 7,039 bytes with its dense `tableswitch`.
The target-47 `executeCompactBlock` grew from 2,848 to 2,944 code bytes
(+96), its max locals from 41 to 43, and the unpreverified diagnostic
`WasmInterpreter.class` from 52,969 to 53,059 bytes (+90). Station/base JARs
were 229,289/226,775 bytes, +82 bytes each relative to the stable baseline.
No W4IR, field, array, or persistent-memory shape changed.

The first focused-test invocation did not reach semantic comparison because
the new WAT fixture failed validation: its intentional trapping functions
left an extra sentinel on the validator's nominal fallthrough stack, and the
underflow probe was itself statically ill-typed. This is a fixture-design
failure, not evidence for or against the runtime candidate. The owner then
requested an immediate return to the stable variant before the fixture was
corrected or any native phoneME timing began.

**Decision.** Classify the candidate as inconclusive and remove the prototype,
fixture, and runner wiring. Production, test, and tool sources again match
stable `main@63f82aad4399321be6a143ddb889ac1e94430573` byte for byte. No speed,
correctness, or rejection claim is made and no production commit is created.
Reconsider only by first fixing the statically valid trap fixture, then
repeating the complete exactness/artifact gates and the planned clean twelve
pairs; the +96-byte compact-method cost must be included in that verdict.

An independent renderer review found three additional non-overlapping
candidates and recorded them separately so this loop does not rediscover or
combine them: hoisting `argbLookup` removes one `getfield` per destination
pixel for only eight class bytes; caching the last packed framebuffer byte
can reduce 57,600 byte loads to 9,600 at side 240 for about 41 class bytes;
and the existing `copyArgb` is a possible side-160-only path. The first two
are queued as NJIT-018 and NJIT-017 respectively. Neither is included in
NJIT-016's code or timing.

## Risks / Trade-offs

- [The ledger becomes prose without reproducible evidence] -> Require commands,
  hashes, workloads, raw paired values, and receipt paths in every entry.
- [A benchmark process contaminates another run] -> Check active processes
  before every native timing window and never delegate competing benchmarks.
- [A small apparent win is host noise] -> Use balanced paired effects, repeat
  unstable results, and classify unresolved effects as inconclusive.
- [A microbenchmark optimizes a shape absent from games] -> Record dynamic
  corpus coverage before using a microbenchmark and retain route controls.
- [A faster path consumes scarce phone heap] -> Record persistent and peak heap
  effects and run constrained-heap gates.
- [The stable branch accumulates experimental code] -> Remove rejected
  candidates and commit only accepted, fully verified changes.

## Migration Plan

1. Create the ledger and record the current clean baseline.
2. Select one new candidate not closed by the historical index.
3. Add its complete planned entry, implement it in isolation, and run exactness
   and artifact gates.
4. Run the authoritative paired A/B on a clean source snapshot.
5. Update the verdict, remove rejected code or commit an accepted stable
   optimization, and begin the next candidate.

Rollback of an accepted candidate is the focused revert of its commit. Cache
format changes, when unavoidable, must atomically reject and rebuild older
records.

## Open Questions

- Which renderer conversion shapes dominate on the actual physical phone
  display sizes?
- Which sound-active cartridge provides a deterministic route that separates
  PCM synthesis cost from MMAPI setup latency?
- Can branch-capable compact regions provide a positive no-JIT result now that
  ordinary taken branches have a constant-time direct path?
