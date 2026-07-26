## 1. Durable experiment foundation

- [x] 1.1 Define the required candidate-ledger fields, statuses, and
  reconsideration rules
- [x] 1.2 Record the clean `f4c824b` baseline and exact artifact, VM, CLDC, and
  preverify hashes
- [x] 1.3 Index accepted, rejected, superseded, and explicitly deferred
  pre-ledger candidate families
- [x] 1.4 Define the native phoneME, KEmulator, QEMU, and physical-device judge
  boundaries

## 2. Candidate research and selection

- [x] 2.1 Collect independent interpreter, no-JIT VM, and non-interpreter frame
  budget research without overlapping edits or benchmark processes
- [x] 2.2 Rank new candidates against dynamic coverage, target-VM mechanism,
  implementation risk, heap cost, and prior experiment history
- [x] 2.3 Add the selected candidate's complete planned `NJIT-*` ledger entry
  before implementation

## 3. Isolated candidate gate

- [x] 3.1 Implement one production-shaped candidate without unrelated changes
- [x] 3.2 Add focused semantic, trap, budget, cache, and differential tests
  required by the affected path
- [x] 3.3 Verify Java 1.3, CLDC 1.1, classfile version 47, preverification,
  release JAR integrity, bytecode headroom, and heap or artifact-size effects
- [x] 3.4 Run the affected exact corpus, full-state, phoneME correctness, and
  MIDP integration gates before timing

## 4. Authoritative measurement and verdict

- [x] 4.1 Produce clean, hash-bound baseline and candidate artifacts with the
  experimental selection compiled out of the hot path
- [x] 4.2 Run balanced paired native i686 phoneME A/B with enough repetitions
  for a primary-workload decision; run no-regression timing controls before
  acceptance, but do not spend them after a decisive primary rejection
- [x] 4.3 Record every raw pair, timer resolution, win/loss count, counters,
  receipt path, bytecode delta, and memory delta in the candidate ledger
- [x] 4.4 Mark the candidate accepted, rejected, inconclusive, blocked, or
  superseded with an explicit reason and reconsideration condition

## 5. Stable closeout and next cycle

- [x] 5.1 Remove rejected or inconclusive implementation code while preserving
  its ledger entry, or measure an accepted candidate with the retained set
- [x] 5.2 Run the complete verification matrix on the exact stable tree
- [x] 5.3 Review scope and commit an accepted optimization to `main` with a
  focused English message; make no production commit for a rejected candidate
- [x] 5.4 Update the baseline identities and append the next candidate section,
  then repeat sections 2 through 5 until the owner changes or stops the goal

## 6. NJIT-002 resident operand-free numeric payload loads

- [x] 6.1 Implement the isolated resident-only numeric payload-load candidate
  without changing W4IR or cache formats
- [x] 6.2 Cover the resident numeric boundaries and retain the existing valid
  paged, malformed-cache, trap, and budget differential gates; the
  resident-only guard leaves paged payload reads unchanged
- [x] 6.3 Pass the Java 1.3, CLDC, target-47, preverification, exact-state,
  release, bytecode-headroom, and memory gates
- [x] 6.4 Produce clean hash-bound artifacts and run the native i686 phoneME
  Waternet paired acceptance gate
- [x] 6.5 Record all pairs and the final verdict, remove a rejected candidate or
  fully verify and commit an accepted candidate, then select `NJIT-003`

## 7. NJIT-003 sign-bit unsigned i32 comparisons

- [x] 7.1 Record the independent semantic, target-bytecode, phoneME mechanism,
  coverage, history, and adversarial reviews in the ledger
- [x] 7.2 Implement only the four unsigned `compareI32` expressions and add the
  focused 36-pair oracle for forced-outer and compact execution
- [x] 7.3 Pass focused budget, Java 1.3, CLDC, target-47, preverification,
  exact-state, release, bytecode-headroom, and memory gates
- [x] 7.4 Produce clean hash-bound artifacts and run the balanced native i686
  phoneME primary and required no-regression paired gates
- [x] 7.5 Record the verdict, remove a rejected candidate or fully verify and
  commit an accepted candidate, then select the next ledger entry

## 8. NJIT-004 short-local parameter layout

- [x] 8.1 Record the target-47 local-slot map, phoneME bytecode-cost mechanism,
  dynamic hot-reference coverage, history, and adversarial review
- [x] 8.2 Implement one isolated parameter-layout candidate without changing
  behavior, formats, persistent heap, or the instruction budget
- [x] 8.3 Pass Java 1.3, CLDC, target-47, preverification, exact-state, release,
  bytecode-headroom, and memory gates
- [x] 8.4 Produce clean hash-bound artifacts and run balanced native i686
  phoneME primary and no-regression paired gates
- [x] 8.5 Record the verdict, remove a rejected candidate or fully verify and
  commit an accepted candidate, then select the next ledger entry

## 9. NJIT-005 effective-address guard

- [x] 9.1 Record the exact WebAssembly address algebra, current target-47 and
  phoneME cost, dynamic memory-op coverage, history, and adversarial review
- [x] 9.2 Implement one isolated effective-address candidate with focused
  overflow, offset, width, trap-order, and partial-store coverage
- [x] 9.3 Pass Java 1.3, CLDC, target-47, preverification, exact-state, release,
  bytecode-headroom, and memory gates
- [x] 9.4 Produce clean hash-bound artifacts and run balanced native i686
  phoneME primary and no-regression paired gates
- [x] 9.5 Record the verdict, remove a rejected candidate or fully verify and
  commit an accepted candidate, then select the next ledger entry

## 10. NJIT-006 direct imported-call opcode

- [x] 10.1 Record import-call semantics, current target-47 and phoneME cost,
  dynamic host-call coverage, history, and adversarial review
- [x] 10.2 Implement one isolated direct imported-call lowering with focused
  argument, result, trap, budget, host-ID, cache, and fallback coverage
- [x] 10.3 Pass Java 1.3, CLDC, target-47, preverification, exact-state, release,
  bytecode-headroom, and memory gates
- [x] 10.4 Produce clean hash-bound artifacts and run balanced native i686
  phoneME primary and no-regression paired gates
- [x] 10.5 Record the verdict, remove a rejected candidate or fully verify and
  commit an accepted candidate, then select the next ledger entry

## 11. NJIT-007 exception-backed push capacity guard

- [x] 11.1 Record validator, RMS-cache, target-47, phoneME-handler,
  dynamic-coverage, exact edge-semantics, and adversarial reviews
- [x] 11.2 Implement only the exception-backed `push(long)` capacity guard and
  add focused valid, overflow, malformed-cache, trap-order, and rollback gates
- [x] 11.3 Pass Java 1.3, CLDC, target-47, preverification, exact-state,
  release, bytecode-headroom, cache, and memory gates
- [x] 11.4 Produce clean hash-bound artifacts and run the balanced native
  i686 phoneME Waternet primary and required no-regression paired gates
- [x] 11.5 Record the verdict, remove a rejected candidate or fully verify and
  commit an accepted candidate, then select the next ledger entry

## 12. NJIT-012 compact-fused short-local parameter layout

- [x] 12.1 Record the exact slot/load map, dynamic fused-handler coverage,
  phoneME handler mechanism, history, and independent adversarial reviews
- [x] 12.2 Implement only the `instruction`/`locals` parameter swap at the sole
  private call and declaration
- [x] 12.3 Pass Java 1.3, CLDC, target-47, preverification, exact-state,
  release, bytecode-headroom, cache, and persistent-memory gates
- [x] 12.4 Produce clean hash-bound artifacts and run the balanced native i686
  phoneME Rubido primary gate, followed by controls only if it passes
- [x] 12.5 Record every pair and the verdict, remove a rejected candidate or
  fully verify and commit an accepted candidate, then select the next ledger
  entry

## 13. NJIT-009 transform-free blit geometry loop

- [x] 13.1 Record exact flag/call/pixel coverage, target-47 mechanism, timing
  boundary, history, and independent reviews
- [x] 13.2 Implement only the transform-free row/coordinate specialization,
  retaining packed decode and `drawPoint`
- [x] 13.3 Add the focused all-flags geometry differential and pass Java 1.3,
  CLDC, target-47, preverification, exact-state, release, size, and memory gates
- [x] 13.4 Produce clean hash-bound artifacts and run the balanced native i686
  phoneME Waternet primary and required Rubido/Untangle controls
- [x] 13.5 Record all pairs and the verdict, remove a rejected candidate or
  fully verify and commit an accepted candidate, then select the next ledger
  entry

## 14. NJIT-014 inline plain-blit framebuffer write

- [x] 14.1 Record opaque draw coverage, phoneME call mechanism, exact isolated
  patch boundary, baseline hashes, risks, and native acceptance thresholds
- [x] 14.2 Inline only the existing `drawPoint` body in the accepted plain loop
- [x] 14.3 Pass the focused 520-case differential, Java 1.3, CLDC, target-47,
  preverification, exact-state, release, size, and memory gates
- [x] 14.4 Build clean hash-bound artifacts and run balanced native i686
  phoneME Waternet primary and Rubido/Untangle controls
- [x] 14.5 Record every pair and the verdict, remove a rejected candidate or
  fully verify and commit an accepted candidate, then select the next entry

## 15. NJIT-015 running packed plain-blit cursor

- [x] 15.1 Record dynamic coverage, exact mechanism, baseline hashes, history,
  alias/rollover risks, independent review, and native acceptance thresholds
- [x] 15.2 Compare conditional and branch-free target-47 cursor forms and
  implement only the smaller credible production candidate
- [x] 15.3 Expand focused rollover/alias coverage and pass Java 1.3, CLDC,
  target-47, preverification, exact-state, release, size, and memory gates
- [x] 15.4 Build clean hash-bound artifacts and run balanced native i686
  phoneME Waternet primary and required Rubido/Untangle controls
- [x] 15.5 Record every pair and the verdict, remove a rejected candidate or
  fully verify and commit an accepted candidate, then select the next entry

## 16. NJIT-016 adjacent upscaled ARGB row reuse

- [x] 16.1 Record the renderer coverage, phoneME arraycopy mechanism, baseline
  hashes, timing boundary, risks, history, and acceptance thresholds
- [x] 16.2 Preserve the original native/downscale loop and implement only the
  helper-isolated adjacent-row reuse for upscaled bands
- [x] 16.3 Add a CLDC renderer benchmark and focused exact differential for
  full/banded, repeated, arbitrary-map, invalid, and alias cases
- [x] 16.4 Run balanced native i686 phoneME component pairs at 240, 176, 160,
  and downscaled sides, then the required KEmulator presentation controls
- [x] 16.5 Record all raw pairs and the final verdict, remove a rejected
  candidate or fully verify and commit an accepted candidate, then continue

## 17. NJIT-017 packed framebuffer byte cache

- [x] 17.1 Record the packed-byte reuse mechanism, baseline hashes, isolated
  method boundary, risks, and native phoneME acceptance thresholds
- [x] 17.2 Prototype the per-row low-byte-address cache only in the upscaled
  conversion method and inspect target-47/preverified size
- [x] 17.3 Run the existing exact renderer differential and balanced native
  i686 phoneME pairs at 240, 176, and the 161 boundary
- [x] 17.4 Record raw pairs and the verdict, remove a rejected candidate or
  fully verify and commit an accepted candidate, then continue

## 18. NJIT-018 upscaled ARGB lookup local

- [x] 18.1 Record the field-load mechanism, post-NJIT-017 baseline hashes,
  isolated method boundary, risk, and native acceptance threshold
- [x] 18.2 Prototype the single lookup-table local and inspect target-47 and
  preverified method/class size
- [x] 18.3 Run exact differential and balanced native i686 phoneME 240/176
  primary pairs, adding banded controls when warranted
- [x] 18.4 Record raw pairs and verdict, remove a rejected candidate or fully
  verify and commit an accepted candidate, then continue

## 19. NJIT-019 native/downscale packed-byte cache

- [x] 19.1 Record the post-NJIT-018 baseline, redundant-load coverage,
  canonical-oracle gap, isolated boundary, risks, and acceptance thresholds
- [x] 19.2 Prototype the per-row packed-byte cache only in `copyArgbBand` and
  inspect target-47/preverified size
- [x] 19.3 Add an independent palette/framebuffer reference differential and
  pass native/downscale, arbitrary-map, band, invalid, and alias cases
- [x] 19.4 Run balanced native i686 pairs at 160 and 128 in full/band modes
- [x] 19.5 Record raw pairs and verdict, remove a rejected candidate or fully
  verify and commit an accepted candidate, then continue

## 20. NJIT-010 PCM common-tone fast path

- [x] 20.1 Record the post-NJIT-019 baseline, real tone coverage, isolated
  mechanism, exactness boundary, memory risks, and acceptance thresholds
- [x] 20.2 Prototype only the sustain-only/no-slide fast path and inspect
  target-47/preverified bytecode and class size
- [x] 20.3 Add the independent byte-exact differential and CLDC phoneME PCM
  benchmark with route-shaped and ADSR/slide workloads
- [x] 20.4 Run balanced native i686 pairs, exact output checks, full release
  verification, and the relevant KEmulator sound gates
- [x] 20.5 Record all raw pairs and verdict, remove a rejected candidate or
  fully verify and commit an accepted candidate, then continue

## 21. Game of Life phoneME performance route

- [x] 21.1 Confirm existing host/KEmulator coverage and measure the native
  phoneME cost and deterministic counters of one idle generation
- [x] 21.2 Add immutable one-frame input, framebuffer, palette, tone, and disk
  oracle fixtures and run them through the exact host replay
- [x] 21.3 Include Game of Life in the default and verify phoneME corpora with
  a one-frame per-route default and an explicit global override
- [x] 21.4 Exercise the balanced paired A/B path on both artifacts and record
  the exact checkpoint, counter, duration, and evidence-quality boundary
- [x] 21.5 Run the complete release verification, document the public command,
  validate OpenSpec, and review the final uncommitted diff

## 22. NJIT-020 Game of Life-primary deep profile

- [x] 22.1 Record the physical-device trigger, clean HEAD/profile artifact,
  production-variant mismatch, invalid evidence boundary, and correction gates
- [x] 22.2 Align the generic profile stream, compact metadata, tier pass, and
  full-state differential with the retained production configuration
- [x] 22.3 Re-run the seven-workload exact corpus and prove that the corrected
  Game of Life tier counters match the production phoneME route
- [x] 22.4 Rank the corrected Game of Life hot mechanisms, record one isolated
  NJIT-020 candidate with exact/bytecode/heap/A-B gates, and reject the rest

## 23. NJIT-020 defined-function argument bulk copy

- [x] 23.1 Implement only the zero/scalar/native argument-copy split after the
  unchanged full local-frame clear and inspect target-47/preverified bytecode
- [x] 23.2 Pass focused frame semantics, Java 1.3/CLDC, complete exact-state,
  trap/budget, release-JAR, cache, and relevant device gates
- [x] 23.3 Produce clean hash-bound artifacts and run at least twelve balanced
  native i686 phoneME Game of Life pairs plus the three route controls
- [x] 23.4 Record every raw pair and artifact/heap/bytecode delta, then remove a
  rejected candidate or fully verify and commit an accepted candidate

## 24. NJIT-021 signed compare plus direct conditional branch

- [x] 24.1 Record the new signed-pair coverage, accepted direct-descriptor
  mechanism, distinction from the rejected unsigned/equality batch, research
  alternatives, baseline identities, risks, and acceptance thresholds
- [x] 24.2 Implement only the three signed comparison relations plus retained
  `br_if` as one direct-descriptor W4IR mechanism, with a format bump and no
  cartridge-specific recognition
- [x] 24.3 Add focused signed-boundary, taken/untaken, branch-arity, fallback,
  trap, budget, cache-format, and profiler differentials; pass Java 1.3, CLDC,
  target-47, preverification, full-state, release, bytecode, and heap gates
- [x] 24.4 Produce clean hash-bound artifacts and run at least twelve balanced
  native i686 phoneME Game of Life pairs plus Waternet, Rubido, and Untangle
  controls when the primary gate passes
- [x] 24.5 Record all raw pairs and artifact/topology deltas, then remove a
  rejected candidate or fully verify and commit an accepted candidate before
  selecting the next ledger entry

## 25. NJIT-022 i32.load8_u plus local.set

- [x] 25.1 Record exact routed coverage, the accepted load/tee precedent,
  isolated mechanism, baseline hashes, trap/budget order, cache-format bump,
  bytecode/heap risks, commands, and native acceptance thresholds
- [x] 25.2 Implement only `i32.load8_u + local.set` as one two-instruction
  W4IR handler in the outer and compact executors, without absorbing a
  preceding address calculation or adding persistent runtime state
- [x] 25.3 Add focused byte/boundary/stack/trap/budget/cache/profile
  differentials and pass Java 1.3, CLDC, target-47, preverification,
  full-state, release, bytecode-headroom, compact-topology, and heap gates
- [x] 25.4 Produce clean hash-bound artifacts and run at least twelve balanced
  native i686 phoneME Game of Life pairs plus Waternet, Rubido, and Untangle
  controls when the primary gate passes
- [x] 25.5 Record every raw pair and artifact/topology delta, then remove a
  rejected candidate or fully verify and commit an accepted candidate before
  selecting the next ledger entry

## 26. NJIT-023 add-constant plus load8_u plus local.set

- [x] 26.1 Record the material distinction from NJIT-022, exact stable triple
  coverage, selected representation, baseline identities, semantic order,
  compatibility risks, commands, and native acceptance thresholds
- [x] 26.2 Implement only the four-logical-instruction
  `i32.add_const + i32.load8_u + local.set` W4IR handler in the outer and
  compact executors, with no runtime branch or persistent state
- [x] 26.3 Add focused stack/address/byte/local/budget/cache/profile
  differentials and pass Java 1.3, CLDC, target-47, preverification,
  full-state, release, bytecode-headroom, compact-topology, and heap gates
- [x] 26.4 Produce clean hash-bound artifacts and run at least twelve balanced
  native i686 phoneME Game of Life pairs plus Waternet, Rubido, and Untangle
  controls only if the primary gate passes
- [x] 26.5 Record every raw pair and artifact/topology delta, then remove a
  rejected candidate or fully verify and commit an accepted candidate before
  selecting the next ledger entry

## 27. NJIT-024 compact i32.load8_u direct stack/address path

- [x] 27.1 Record the exact compact coverage lower bound, distinction from
  rejected helper/fusion work, isolated mechanism, baseline identities,
  semantic risks, commands, and native acceptance thresholds
- [x] 27.2 Prototype only the existing compact `i32.load8_u` stack and
  width-one address path, inspect its bytecode, then remove it when the owner
  requests a return to stable before verification
- [x] 27.3 Record the focused-fixture validation failure and explicitly make
  no correctness claim because the full gate was stopped before it began
- [x] 27.4 Skip clean native phoneME timing and route controls after the owner
  stops the experiment; do not infer performance from bytecode
- [x] 27.5 Record the candidate as inconclusive, remove all implementation and
  test changes, and restore the stable source tree
