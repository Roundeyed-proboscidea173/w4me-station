#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

cmd_bench() {
    # Reference-VM interpreter benchmark: compiles the current working tree
    # against local CLDC 1.1.1 system classes (rejecting any non-CLDC API
    # at compile time), preverifies it, and replays the recorded browser-oracle
    # routes on the local phoneME cldc_vm_r — a 32-bit, JIT-less C-interpreter
    # CLDC VM. Every oracle checkpoint (framebuffer FNV-1a, palette, input state)
    # is verified during the timed run.
    #
    # This script intentionally does NOT source tools/container/env.sh: the local VM is
    # a host i686 binary and needs no distrobox. Requirements: javac 8+ on PATH
    # and the 32-bit loader (/lib/ld-linux.so.2, glibc.i686, libstdc++.i686).
    #
    # usage: tools/phoneme/run.sh bench [cart ...] [--mode optimized|trace-off|fusion-only|baseline|all]
    #                         [--candidate current|seven-opcode|host-import-id|counterless|
    #                                      resident-baseline|dense-baseline|all|
    #                                      host-import-id-all|counterless-all|
    #                                      resident-fast-all|combined-all|dense-all|
    #                                      load-tee-all|branch-inline-all|
    #                                      branch-direct-all|branch-direct-vs-inline-all]
    #                         [--reps N] [--extra-frames N] [--heap-capacity 64M]
    #
    # Without --extra-frames, recorded game routes use a 60-frame tail while
    # Game of Life uses its canonical single-frame route. The explicit option
    # still overrides every selected cartridge.

    PHONEME_HOME="${PHONEME_HOME:-${ROOT_DIR}/.local/phoneme}"
    CLDC_VM="${PHONEME_HOME}/cldc_vm_r"
    PREVERIFY="${PHONEME_HOME}/preverify"
    CLDC_CLASSES="${PHONEME_HOME}/classes.zip"
    OUT_DIR="${ROOT_DIR}/build/reports/phoneme"
    RECEIPT="${OUT_DIR}/receipt.txt"
    PAIRED_STATS="${ROOT_DIR}/tools/phoneme/paired-stats.awk"
    INTERPRETER_CONFIG_SOURCE="${INTERPRETER_CONFIG_SOURCE:-${ROOT_DIR}/src/main/java/w4me/wasm/InterpreterBuildConfig.java}"

    [ -f "${INTERPRETER_CONFIG_SOURCE}" ] || {
        printf 'error: missing interpreter config: %s\n' \
            "${INTERPRETER_CONFIG_SOURCE}" >&2
        exit 1
    }

    hash_or_missing() {
        if [ -f "$1" ]; then
            sha256sum -- "$1" | cut -d ' ' -f 1
        else
            printf 'missing\n'
        fi
    }

    CARTS=()
    MODE="optimized"
    CANDIDATE="host-import-id"
    REPS=""
    EXTRA_FRAMES=""
    HEAP_CAPACITY="64M"
    while [ $# -gt 0 ]; do
        case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --reps)
            REPS="$2"
            shift 2
            ;;
        --candidate)
            CANDIDATE="$2"
            shift 2
            ;;
        --extra-frames)
            EXTRA_FRAMES="$2"
            shift 2
            ;;
        --heap-capacity)
            HEAP_CAPACITY="$2"
            shift 2
            ;;
        *)
            CARTS+=("$1")
            shift
            ;;
        esac
    done
    if [ "${#CARTS[@]}" -eq 0 ]; then
        CARTS=(waternet rubido untangle game-of-life-zig-edition)
    fi
    route_extra_frames() {
        if [ -n "${EXTRA_FRAMES}" ]; then
            printf '%s\n' "${EXTRA_FRAMES}"
        elif [ "$1" = "game-of-life-zig-edition" ]; then
            printf '1\n'
        else
            printf '60\n'
        fi
    }
    if [ "${MODE}" = "all" ]; then
        MODES=(optimized trace-off fusion-only baseline)
    else
        MODES=("${MODE}")
    fi
    PAIR_BASELINE=""
    PAIR_CANDIDATE=""
    case "${CANDIDATE}" in
    all)
        CANDIDATES=(current seven-opcode)
        PAIR_BASELINE="current"
        PAIR_CANDIDATE="seven-opcode"
        ;;
    host-import-id-all)
        CANDIDATES=(seven-opcode host-import-id)
        PAIR_BASELINE="seven-opcode"
        PAIR_CANDIDATE="host-import-id"
        ;;
    counterless-all)
        CANDIDATES=(host-import-id counterless)
        PAIR_BASELINE="host-import-id"
        PAIR_CANDIDATE="counterless"
        ;;
    resident-fast-all)
        CANDIDATES=(resident-baseline host-import-id)
        PAIR_BASELINE="resident-baseline"
        PAIR_CANDIDATE="host-import-id"
        ;;
    combined-all)
        CANDIDATES=(resident-baseline counterless)
        PAIR_BASELINE="resident-baseline"
        PAIR_CANDIDATE="counterless"
        ;;
    dense-all)
        CANDIDATES=(dense-baseline host-import-id)
        PAIR_BASELINE="dense-baseline"
        PAIR_CANDIDATE="host-import-id"
        ;;
    load-tee-all)
        CANDIDATES=(load-tee-baseline load-tee)
        PAIR_BASELINE="load-tee-baseline"
        PAIR_CANDIDATE="load-tee"
        ;;
    branch-inline-all)
        CANDIDATES=(branch-legacy branch-inline)
        PAIR_BASELINE="branch-legacy"
        PAIR_CANDIDATE="branch-inline"
        ;;
    branch-direct-all)
        CANDIDATES=(branch-legacy counterless)
        PAIR_BASELINE="branch-legacy"
        PAIR_CANDIDATE="counterless"
        ;;
    branch-direct-vs-inline-all)
        CANDIDATES=(branch-inline branch-direct)
        PAIR_BASELINE="branch-inline"
        PAIR_CANDIDATE="branch-direct"
        ;;
    current | seven-opcode | host-import-id | counterless | resident-baseline | dense-baseline | load-tee-baseline | load-tee | branch-legacy | branch-inline | branch-direct)
        CANDIDATES=("${CANDIDATE}")
        ;;
    *)
        printf 'error: unknown candidate: %s\n' "${CANDIDATE}" >&2
        exit 1
        ;;
    esac
    if [ -z "${REPS}" ]; then
        if [ -n "${PAIR_BASELINE}" ]; then
            REPS=8
        else
            REPS=3
        fi
    fi
    case "${REPS}" in
    '' | *[!0-9]*)
        printf 'error: reps must be a positive integer: %s\n' "${REPS}" >&2
        exit 1
        ;;
    esac
    if [ "${REPS}" -le 0 ]; then
        printf 'error: reps must be positive: %s\n' "${REPS}" >&2
        exit 1
    fi
    case "${EXTRA_FRAMES}" in
    *[!0-9]*)
        printf 'error: extra frames must be a positive integer: %s\n' \
            "${EXTRA_FRAMES}" >&2
        exit 1
        ;;
    esac
    if [ -n "${EXTRA_FRAMES}" ] && [ "${EXTRA_FRAMES}" -le 0 ]; then
        printf 'error: extra frames must be positive: %s\n' \
            "${EXTRA_FRAMES}" >&2
        exit 1
    fi
    case "${HEAP_CAPACITY}" in
    '' | [!0-9]* | *[!0-9KMGkmg]* | *[KMGkmg][0-9KMGkmg]*)
        printf 'error: heap capacity must be an integer with optional K, M, or G suffix: %s\n' \
            "${HEAP_CAPACITY}" >&2
        exit 1
        ;;
    esac
    if [ -n "${PAIR_BASELINE}" ] && [ $((REPS % 2)) -ne 0 ]; then
        printf 'error: paired comparisons require an even rep count: %s\n' \
            "${REPS}" >&2
        exit 1
    fi
    [ -f "${PAIRED_STATS}" ] || {
        printf 'error: missing %s\n' "${PAIRED_STATS}" >&2
        exit 1
    }

    command -v javac >/dev/null || {
        printf 'error: javac not found on PATH\n' >&2
        exit 1
    }
    [ -f "${CLDC_CLASSES}" ] || {
        printf 'error: missing phoneME classes: %s\n' "${CLDC_CLASSES}" >&2
        printf 'hint: set PHONEME_HOME; see docs/performance.md\n' >&2
        exit 1
    }
    [ -x "${PREVERIFY}" ] || {
        printf 'error: missing phoneME preverifier: %s\n' "${PREVERIFY}" >&2
        printf 'hint: set PHONEME_HOME; see docs/performance.md\n' >&2
        exit 1
    }
    [ -x "${CLDC_VM}" ] || {
        printf 'error: missing %s\n' "${CLDC_VM}" >&2
        printf 'hint: set PHONEME_HOME; see docs/performance.md\n' >&2
        exit 1
    }
    VM_PROBE="$("${CLDC_VM}" 2>&1 || true)"
    if ! printf '%s' "${VM_PROBE}" | grep -q 'class not specified'; then
        printf 'error: %s does not run; install 32-bit glibc/libstdc++ (glibc.i686)\n' \
            "${CLDC_VM}" >&2
        exit 1
    fi

    rm -rf -- "${OUT_DIR}"
    mkdir -p -- "${OUT_DIR}/classes" "${OUT_DIR}/preverified"

    # Compile main sources plus the bench against the CLDC bootclasspath. This is
    # also the CLDC API lint: any java.* use outside CLDC 1.1.1 fails right here.
    # MIDP-dependent classes (MMAPI backends, RMS storage) are excluded: they need
    # javax.microedition.* and cannot exist on the headless CLDC VM.
    find "${ROOT_DIR}/src/main/java/w4me/wasm" \
        "${ROOT_DIR}/src/main/java/w4me/runtime" \
        -name '*.java' \
        ! -path "${ROOT_DIR}/src/main/java/w4me/wasm/InterpreterBuildConfig.java" \
        -print | sort |
        xargs grep -L -E 'javax\.microedition|RmsW4IrStore|RmsDiskBackend' \
            >"${OUT_DIR}/sources.list"
    {
        printf '%s\n' "${INTERPRETER_CONFIG_SOURCE}"
        printf '%s\n' "${ROOT_DIR}/src/test/java/w4me/FramebufferOracle.java"
        printf '%s\n' "${ROOT_DIR}/src/test/java/w4me/PhoneMeArgbBandBench.java"
        printf '%s\n' "${ROOT_DIR}/src/test/java/w4me/PhoneMePcmBench.java"
        printf '%s\n' "${ROOT_DIR}/src/test/java/w4me/PhoneMeRouteBench.java"
    } >>"${OUT_DIR}/sources.list"
    javac \
        -nowarn \
        -encoding UTF-8 \
        -source 1.3 \
        -target 1.3 \
        -Xlint:-options \
        -bootclasspath "${CLDC_CLASSES}" \
        -d "${OUT_DIR}/classes" \
        @"${OUT_DIR}/sources.list"

    "${PREVERIFY}" -classpath "${CLDC_CLASSES}" -d "${OUT_DIR}/preverified" \
        "${OUT_DIR}/classes"

    stage_resources() {
        local destination="$1"
        local cart
        cp -- "${ROOT_DIR}/src/main/resources/w4font.bin" "${destination}/"
        for cart in "${CARTS[@]}"; do
            cp -- "${ROOT_DIR}/cartridges/${cart}.wasm" "${destination}/"
            if [ -f "${ROOT_DIR}/testdata/oracles/${cart}/input.csv" ]; then
                cp -- "${ROOT_DIR}/testdata/oracles/${cart}/input.csv" \
                    "${destination}/${cart}-input.csv"
            fi
            if [ -f "${ROOT_DIR}/testdata/oracles/${cart}/oracle.csv" ]; then
                cp -- "${ROOT_DIR}/testdata/oracles/${cart}/oracle.csv" \
                    "${destination}/${cart}-oracle.csv"
            fi
        done
    }

    build_alternate_artifact() {
        local name="$1"
        local config_source="$2"
        local classes="${OUT_DIR}/${name}-classes"
        local preverified="${OUT_DIR}/${name}-preverified"
        local sources="${OUT_DIR}/${name}-sources.list"
        mkdir -p -- "${classes}" "${preverified}"
        grep -v -F \
            "${INTERPRETER_CONFIG_SOURCE}" \
            "${OUT_DIR}/sources.list" >"${sources}"
        printf '%s\n' "${config_source}" >>"${sources}"
        javac \
            -nowarn \
            -encoding UTF-8 \
            -source 1.3 \
            -target 1.3 \
            -Xlint:-options \
            -bootclasspath "${CLDC_CLASSES}" \
            -d "${classes}" \
            @"${sources}"
        "${PREVERIFY}" -classpath "${CLDC_CLASSES}" \
            -d "${preverified}" \
            "${classes}"
        stage_resources "${preverified}"
    }

    build_dense_baseline_artifact() {
        local classes="${OUT_DIR}/dense-baseline-classes"
        local preverified="${OUT_DIR}/dense-baseline-preverified"
        local sources="${OUT_DIR}/dense-baseline-sources.list"
        mkdir -p -- "${classes}" "${preverified}"
        grep -v -F \
            "${ROOT_DIR}/src/main/java/w4me/wasm/OpcodeBuildConfig.java" \
            "${OUT_DIR}/sources.list" >"${sources}"
        printf '%s\n' \
            "${ROOT_DIR}/bench/configs/dense-baseline/java/w4me/wasm/OpcodeBuildConfig.java" \
            >>"${sources}"
        javac \
            -nowarn \
            -encoding UTF-8 \
            -source 1.3 \
            -target 1.3 \
            -Xlint:-options \
            -bootclasspath "${CLDC_CLASSES}" \
            -d "${classes}" \
            @"${sources}"
        "${PREVERIFY}" -classpath "${CLDC_CLASSES}" \
            -d "${preverified}" \
            "${classes}"
        stage_resources "${preverified}"
    }

    stage_resources "${OUT_DIR}/preverified"

    BUILD_COUNTERLESS="no"
    BUILD_RESIDENT_BASELINE="no"
    BUILD_DENSE_BASELINE="no"
    BUILD_BRANCH_LEGACY="no"
    BUILD_BRANCH_INLINE="no"
    BUILD_BRANCH_DIRECT="no"
    for candidate in "${CANDIDATES[@]}"; do
        case "${candidate}" in
        counterless)
            BUILD_COUNTERLESS="yes"
            ;;
        resident-baseline)
            BUILD_RESIDENT_BASELINE="yes"
            ;;
        dense-baseline)
            BUILD_DENSE_BASELINE="yes"
            ;;
        branch-legacy)
            BUILD_BRANCH_LEGACY="yes"
            ;;
        branch-inline)
            BUILD_BRANCH_INLINE="yes"
            ;;
        branch-direct)
            BUILD_BRANCH_DIRECT="yes"
            ;;
        esac
    done
    if [ "${BUILD_COUNTERLESS}" = "yes" ]; then
        build_alternate_artifact \
            "counterless" \
            "${ROOT_DIR}/bench/configs/timed/java/w4me/wasm/InterpreterBuildConfig.java"
    fi
    if [ "${BUILD_RESIDENT_BASELINE}" = "yes" ]; then
        build_alternate_artifact \
            "resident-baseline" \
            "${ROOT_DIR}/bench/configs/resident-baseline/java/w4me/wasm/InterpreterBuildConfig.java"
    fi
    if [ "${BUILD_DENSE_BASELINE}" = "yes" ]; then
        build_dense_baseline_artifact
    fi
    if [ "${BUILD_BRANCH_LEGACY}" = "yes" ]; then
        build_alternate_artifact \
            "branch-legacy" \
            "${ROOT_DIR}/bench/configs/branch-legacy-timed/java/w4me/wasm/InterpreterBuildConfig.java"
    fi
    if [ "${BUILD_BRANCH_INLINE}" = "yes" ]; then
        build_alternate_artifact \
            "branch-inline" \
            "${ROOT_DIR}/bench/configs/branch-inline-timed/java/w4me/wasm/InterpreterBuildConfig.java"
    fi
    if [ "${BUILD_BRANCH_DIRECT}" = "yes" ]; then
        build_alternate_artifact \
            "branch-direct" \
            "${ROOT_DIR}/bench/configs/branch-direct-timed/java/w4me/wasm/InterpreterBuildConfig.java"
    fi
    # Bind every result to the exact preverified class/resource tree. The hash is
    # independent of file timestamps and includes the selected cartridges and
    # route oracles as well as all benchmarked classes.
    artifact_sha256() {
        (
            cd -- "$1"
            find . -type f -print0 | sort -z | xargs -0 sha256sum |
                sha256sum | cut -d ' ' -f 1
        )
    }

    candidate_preverified() {
        case "$1" in
        counterless)
            printf '%s\n' "${OUT_DIR}/counterless-preverified"
            ;;
        resident-baseline)
            printf '%s\n' "${OUT_DIR}/resident-baseline-preverified"
            ;;
        dense-baseline)
            printf '%s\n' "${OUT_DIR}/dense-baseline-preverified"
            ;;
        branch-legacy)
            printf '%s\n' "${OUT_DIR}/branch-legacy-preverified"
            ;;
        branch-inline)
            printf '%s\n' "${OUT_DIR}/branch-inline-preverified"
            ;;
        branch-direct)
            printf '%s\n' "${OUT_DIR}/branch-direct-preverified"
            ;;
        *)
            printf '%s\n' "${OUT_DIR}/preverified"
            ;;
        esac
    }

    BASE_ARTIFACT_SHA256="$(artifact_sha256 "${OUT_DIR}/preverified")"
    COUNTERLESS_ARTIFACT_SHA256=""
    if [ "${BUILD_COUNTERLESS}" = "yes" ]; then
        COUNTERLESS_ARTIFACT_SHA256="$(
            artifact_sha256 "${OUT_DIR}/counterless-preverified"
        )"
    fi
    RESIDENT_BASELINE_ARTIFACT_SHA256=""
    if [ "${BUILD_RESIDENT_BASELINE}" = "yes" ]; then
        RESIDENT_BASELINE_ARTIFACT_SHA256="$(
            artifact_sha256 "${OUT_DIR}/resident-baseline-preverified"
        )"
    fi
    DENSE_BASELINE_ARTIFACT_SHA256=""
    if [ "${BUILD_DENSE_BASELINE}" = "yes" ]; then
        DENSE_BASELINE_ARTIFACT_SHA256="$(
            artifact_sha256 "${OUT_DIR}/dense-baseline-preverified"
        )"
    fi
    BRANCH_LEGACY_ARTIFACT_SHA256=""
    if [ "${BUILD_BRANCH_LEGACY}" = "yes" ]; then
        BRANCH_LEGACY_ARTIFACT_SHA256="$(
            artifact_sha256 "${OUT_DIR}/branch-legacy-preverified"
        )"
    fi
    BRANCH_INLINE_ARTIFACT_SHA256=""
    if [ "${BUILD_BRANCH_INLINE}" = "yes" ]; then
        BRANCH_INLINE_ARTIFACT_SHA256="$(
            artifact_sha256 "${OUT_DIR}/branch-inline-preverified"
        )"
    fi
    BRANCH_DIRECT_ARTIFACT_SHA256=""
    if [ "${BUILD_BRANCH_DIRECT}" = "yes" ]; then
        BRANCH_DIRECT_ARTIFACT_SHA256="$(
            artifact_sha256 "${OUT_DIR}/branch-direct-preverified"
        )"
    fi
    candidate_artifact_sha256() {
        case "$1" in
        counterless)
            printf '%s\n' "${COUNTERLESS_ARTIFACT_SHA256}"
            ;;
        resident-baseline)
            printf '%s\n' "${RESIDENT_BASELINE_ARTIFACT_SHA256}"
            ;;
        dense-baseline)
            printf '%s\n' "${DENSE_BASELINE_ARTIFACT_SHA256}"
            ;;
        branch-legacy)
            printf '%s\n' "${BRANCH_LEGACY_ARTIFACT_SHA256}"
            ;;
        branch-inline)
            printf '%s\n' "${BRANCH_INLINE_ARTIFACT_SHA256}"
            ;;
        branch-direct)
            printf '%s\n' "${BRANCH_DIRECT_ARTIFACT_SHA256}"
            ;;
        *)
            printf '%s\n' "${BASE_ARTIFACT_SHA256}"
            ;;
        esac
    }

    candidate_diagnostic_counters() {
        if [ "$1" = "counterless" ] ||
            [ "$1" = "branch-legacy" ] ||
            [ "$1" = "branch-inline" ] ||
            [ "$1" = "branch-direct" ]; then
            printf 'off\n'
        else
            printf 'on\n'
        fi
    }

    candidate_inline_branch_fast_path() {
        if [ "$1" = "branch-inline" ]; then
            printf 'on\n'
        else
            printf 'off\n'
        fi
    }

    candidate_direct_branch_fast_path() {
        if [ "$1" = "branch-legacy" ] || [ "$1" = "branch-inline" ]; then
            printf 'off\n'
        else
            printf 'on\n'
        fi
    }

    candidate_resident_fast_path() {
        if [ "$1" = "resident-baseline" ]; then
            printf 'off\n'
        else
            printf 'on\n'
        fi
    }

    candidate_dense_opcode_dispatch() {
        if [ "$1" = "dense-baseline" ]; then
            printf 'off\n'
        else
            printf 'on\n'
        fi
    }

    candidate_load_tee_fusions() {
        if [ "$1" = "load-tee-baseline" ]; then
            printf 'off\n'
        else
            printf 'on\n'
        fi
    }

    SOURCE_HEAD="$(git -C "${ROOT_DIR}" rev-parse HEAD 2>/dev/null || printf 'unversioned')"
    if [ -z "$(git -C "${ROOT_DIR}" status --porcelain --untracked-files=normal)" ]; then
        SOURCE_DIRTY="no"
    else
        SOURCE_DIRTY="yes"
    fi

    {
        printf 'phoneme-bench receipt\n'
        printf 'vm-arch=i686 vm-sha256=%s\n' \
            "$(sha256sum "${CLDC_VM}" | cut -d ' ' -f 1)"
        printf 'classes-sha256=%s\n' "$(sha256sum "${CLDC_CLASSES}" | cut -d ' ' -f 1)"
        printf 'preverify-sha256=%s\n' "$(sha256sum "${PREVERIFY}" | cut -d ' ' -f 1)"
        printf 'artifact-sha256=%s\n' "${BASE_ARTIFACT_SHA256}"
        printf 'source-head=%s source-dirty=%s\n' "${SOURCE_HEAD}" "${SOURCE_DIRTY}"
        printf 'cldc-api-lint=pass source=1.3 target=1.3 fast-paths=off\n'
        printf 'timer=System.currentTimeMillis paired-statistic=median-paired-effect paired-acceptance-reps=8\n'
        printf 'reps=%s extra-frames=%s heap-capacity=%s modes=%s candidates=%s\n' \
            "${REPS}" "${EXTRA_FRAMES:-per-route}" "${HEAP_CAPACITY}" \
            "${MODES[*]}" "${CANDIDATES[*]}"
        for candidate in "${CANDIDATES[@]}"; do
            printf 'artifact candidate=%s diagnostic-counters=%s resident-fast-path=%s dense-opcode-dispatch=%s load-tee-fusions=%s inline-branch-fast-path=%s direct-branch-fast-path=%s sha256=%s\n' \
                "${candidate}" \
                "$(candidate_diagnostic_counters "${candidate}")" \
                "$(candidate_resident_fast_path "${candidate}")" \
                "$(candidate_dense_opcode_dispatch "${candidate}")" \
                "$(candidate_load_tee_fusions "${candidate}")" \
                "$(candidate_inline_branch_fast_path "${candidate}")" \
                "$(candidate_direct_branch_fast_path "${candidate}")" \
                "$(candidate_artifact_sha256 "${candidate}")"
        done
        for cart in "${CARTS[@]}"; do
            printf 'route cart=%s extra-frames=%s cartridge-sha256=%s input-sha256=%s oracle-sha256=%s\n' \
                "${cart}" \
                "$(route_extra_frames "${cart}")" \
                "$(hash_or_missing "${ROOT_DIR}/cartridges/${cart}.wasm")" \
                "$(hash_or_missing "${ROOT_DIR}/testdata/oracles/${cart}/input.csv")" \
                "$(hash_or_missing "${ROOT_DIR}/testdata/oracles/${cart}/oracle.csv")"
        done
    } >"${RECEIPT}"

    status=0
    for cart in "${CARTS[@]}"; do
        CART_EXTRA_FRAMES="$(route_extra_frames "${cart}")"
        for mode in "${MODES[@]}"; do
            for candidate in "${CANDIDATES[@]}"; do
                : >"${OUT_DIR}/${cart}-${mode}-${candidate}-samples.txt"
            done
            sample=0
            while [ "${sample}" -lt "${REPS}" ]; do
                if [ -n "${PAIR_BASELINE}" ] && [ $((sample % 2)) -eq 1 ]; then
                    SAMPLE_ORDER=("${PAIR_CANDIDATE}" "${PAIR_BASELINE}")
                else
                    SAMPLE_ORDER=("${CANDIDATES[@]}")
                fi
                printf 'paired-order cart=%s mode=%s sample=%s order=%s\n' \
                    "${cart}" "${mode}" "${sample}" "${SAMPLE_ORDER[*]}" |
                    tee -a "${RECEIPT}"
                for candidate in "${SAMPLE_ORDER[@]}"; do
                    RESULT="${OUT_DIR}/${cart}-${mode}-${candidate}-${sample}.txt"
                    RUN_PREVERIFIED="$(candidate_preverified "${candidate}")"
                    printf '=== %s %s %s sample=%s\n' \
                        "${cart}" "${mode}" "${candidate}" "${sample}"
                    if "${CLDC_VM}" -EnableTicks "=HeapCapacity${HEAP_CAPACITY}" \
                        -classpath "${CLDC_CLASSES}:${RUN_PREVERIFIED}" \
                        w4me.PhoneMeRouteBench "${cart}" "${mode}" \
                        "${CART_EXTRA_FRAMES}" 1 "${candidate}" "${sample}" \
                        >"${RESULT}" 2>&1; then
                        PASS_COUNT="$(grep -c 'phoneme-bench:pass' "${RESULT}" || true)"
                        if [ "${PASS_COUNT}" -ne 1 ]; then
                            printf 'FAIL %s %s %s sample=%s passes=%s\n' \
                                "${cart}" "${mode}" "${candidate}" "${sample}" \
                                "${PASS_COUNT}" | tee -a "${RECEIPT}"
                            cat "${RESULT}"
                            status=1
                            continue
                        fi
                        PASS_LINE="$(grep 'phoneme-bench:pass' "${RESULT}")"
                        printf '%s\n' "${PASS_LINE}" |
                            tee -a "${RECEIPT}" \
                                "${OUT_DIR}/${cart}-${mode}-${candidate}-samples.txt"
                    else
                        printf 'FAIL %s %s %s sample=%s (vm exit)\n' \
                            "${cart}" "${mode}" "${candidate}" "${sample}" |
                            tee -a "${RECEIPT}"
                        cat "${RESULT}"
                        status=1
                    fi
                done
                sample=$((sample + 1))
            done

            for candidate in "${CANDIDATES[@]}"; do
                SAMPLES="${OUT_DIR}/${cart}-${mode}-${candidate}-samples.txt"
                PASS_COUNT="$(wc -l <"${SAMPLES}")"
                if [ "${PASS_COUNT}" -ne "${REPS}" ]; then
                    printf 'FAIL %s %s %s expected-samples=%s actual-samples=%s\n' \
                        "${cart}" "${mode}" "${candidate}" "${REPS}" "${PASS_COUNT}" |
                        tee -a "${RECEIPT}"
                    status=1
                    continue
                fi
                MEDIAN_US_PER_FRAME="$(
                    sed -n 's/.* us-per-frame=\([0-9][0-9]*\).*/\1/p' "${SAMPLES}" |
                        sort -n |
                        awk '{ value[NR] = $1 } END { \
                            if (NR % 2 == 1) print value[(NR + 1) / 2]; \
                            else printf "%.1f\n", (value[NR / 2] + value[NR / 2 + 1]) / 2.0; \
                        }'
                )"
                CANDIDATE_ARTIFACT_SHA256="$(
                    candidate_artifact_sha256 "${candidate}"
                )"
                printf 'phoneme-bench:median cart=%s mode=%s candidate=%s reps=%s us-per-frame=%s artifact-sha256=%s\n' \
                    "${cart}" "${mode}" "${candidate}" "${REPS}" "${MEDIAN_US_PER_FRAME}" \
                    "${CANDIDATE_ARTIFACT_SHA256}" | tee -a "${RECEIPT}"
            done
            if [ -n "${PAIR_BASELINE}" ]; then
                PAIR_FILE="${OUT_DIR}/${cart}-${mode}-${PAIR_BASELINE}-vs-${PAIR_CANDIDATE}-pairs.csv"
                printf 'sample,baseline_us_per_frame,candidate_us_per_frame,frames,order\n' \
                    >"${PAIR_FILE}"
                sample=0
                while [ "${sample}" -lt "${REPS}" ]; do
                    BASELINE_RESULT="${OUT_DIR}/${cart}-${mode}-${PAIR_BASELINE}-${sample}.txt"
                    CANDIDATE_RESULT="${OUT_DIR}/${cart}-${mode}-${PAIR_CANDIDATE}-${sample}.txt"
                    BASELINE_PASS="$(
                        sed -n 's/.*phoneme-bench:pass /phoneme-bench:pass /p' \
                            "${BASELINE_RESULT}"
                    )"
                    CANDIDATE_PASS="$(
                        sed -n 's/.*phoneme-bench:pass /phoneme-bench:pass /p' \
                            "${CANDIDATE_RESULT}"
                    )"
                    BASELINE_US="$(
                        printf '%s\n' "${BASELINE_PASS}" |
                            sed -n 's/.* us-per-frame=\([0-9][0-9]*\).*/\1/p'
                    )"
                    CANDIDATE_US="$(
                        printf '%s\n' "${CANDIDATE_PASS}" |
                            sed -n 's/.* us-per-frame=\([0-9][0-9]*\).*/\1/p'
                    )"
                    BASELINE_FRAMES="$(
                        printf '%s\n' "${BASELINE_PASS}" |
                            sed -n 's/.* frames=\([0-9][0-9]*\).*/\1/p'
                    )"
                    CANDIDATE_FRAMES="$(
                        printf '%s\n' "${CANDIDATE_PASS}" |
                            sed -n 's/.* frames=\([0-9][0-9]*\).*/\1/p'
                    )"
                    if [ -z "${BASELINE_US}" ] || [ -z "${CANDIDATE_US}" ] ||
                        [ -z "${BASELINE_FRAMES}" ] ||
                        [ "${BASELINE_FRAMES}" != "${CANDIDATE_FRAMES}" ]; then
                        printf 'FAIL %s %s incomplete-pair sample=%s\n' \
                            "${cart}" "${mode}" "${sample}" | tee -a "${RECEIPT}"
                        status=1
                        sample=$((sample + 1))
                        continue
                    fi
                    if [ $((sample % 2)) -eq 0 ]; then
                        ORDER="baseline-first"
                    else
                        ORDER="candidate-first"
                    fi
                    printf '%s,%s,%s,%s,%s\n' \
                        "${sample}" "${BASELINE_US}" "${CANDIDATE_US}" \
                        "${BASELINE_FRAMES}" "${ORDER}" >>"${PAIR_FILE}"
                    sample=$((sample + 1))
                done
                PAIR_COUNT="$(awk 'NR > 1 { count++ } END { print count + 0 }' "${PAIR_FILE}")"
                if [ "${PAIR_COUNT}" -ne "${REPS}" ]; then
                    printf 'FAIL %s %s expected-pairs=%s actual-pairs=%s\n' \
                        "${cart}" "${mode}" "${REPS}" "${PAIR_COUNT}" |
                        tee -a "${RECEIPT}"
                    status=1
                else
                    PAIR_RESULT="$(
                        awk -v source_dirty="${SOURCE_DIRTY}" \
                            -f "${PAIRED_STATS}" "${PAIR_FILE}"
                    )"
                    BASELINE_ARTIFACT_SHA256="$(
                        candidate_artifact_sha256 "${PAIR_BASELINE}"
                    )"
                    PAIR_CANDIDATE_ARTIFACT_SHA256="$(
                        candidate_artifact_sha256 "${PAIR_CANDIDATE}"
                    )"
                    printf 'phoneme-bench:paired cart=%s mode=%s baseline=%s candidate=%s %s baseline-artifact-sha256=%s candidate-artifact-sha256=%s pairs-file=%s\n' \
                        "${cart}" "${mode}" "${PAIR_BASELINE}" "${PAIR_CANDIDATE}" \
                        "${PAIR_RESULT}" "${BASELINE_ARTIFACT_SHA256}" \
                        "${PAIR_CANDIDATE_ARTIFACT_SHA256}" \
                        "$(basename -- "${PAIR_FILE}")" | tee -a "${RECEIPT}"
                fi
            fi
        done
    done

    printf 'receipt: %s\n' "${RECEIPT}"
    exit "${status}"
}

cmd_verify_arm64() {
    # Cross-ISA correctness gate for the phoneME portable-C interpreter.
    # Native i686 remains the performance judge. The AArch64 VM runs under QEMU
    # TCG only to prove that route checkpoints and deterministic VM counters match.

    PHONEME_HOME="${PHONEME_HOME:-${ROOT_DIR}/.local/phoneme}"
    OUT_DIR="${ROOT_DIR}/build/reports/phoneme"
    I686_VM="${PHONEME_HOME}/cldc_vm_r"
    ARM64_VM="${PHONEME_HOME}/cldc_vm_r-arm64"
    CLDC_CLASSES="${PHONEME_HOME}/classes.zip"
    ARM64_IMAGE="${PHONEME_ARM64_IMAGE:-docker.io/library/debian:stable-slim}"
    CANDIDATE="host-import-id"
    MODE="optimized"
    EXTRA_FRAMES=60
    CARTS=(waternet rubido untangle)

    command -v podman >/dev/null || {
        printf 'error: podman not found on PATH\n' >&2
        exit 1
    }
    [ -x "${ARM64_VM}" ] || {
        printf 'error: missing executable %s\n' "${ARM64_VM}" >&2
        printf 'hint: set PHONEME_HOME; see docs/performance.md\n' >&2
        exit 1
    }
    [ -x "${I686_VM}" ] || {
        printf 'error: missing executable %s\n' "${I686_VM}" >&2
        exit 1
    }
    [ -f "${CLDC_CLASSES}" ] || {
        printf 'error: missing phoneME classes: %s\n' "${CLDC_CLASSES}" >&2
        exit 1
    }

    # Build one CLDC-clean, preverified tree and collect the native reference run.
    "${ROOT_DIR}/tools/phoneme/run.sh" bench \
        "${CARTS[@]}" --mode "${MODE}" --candidate "${CANDIDATE}" --reps 1 \
        --extra-frames "${EXTRA_FRAMES}"

    RECEIPT="${OUT_DIR}/arm64-isa-receipt.txt"
    ARTIFACT_SHA256="$(sed -n 's/^artifact-sha256=//p' "${OUT_DIR}/receipt.txt")"
    SOURCE_IDENTITY="$(sed -n 's/^source-head=//p' "${OUT_DIR}/receipt.txt")"

    deterministic_signature() {
        local result="$1"
        local count
        count="$(grep -c '^phoneme-bench:pass ' "${result}" || true)"
        if [ "${count}" -ne 1 ]; then
            printf 'error: expected one pass line in %s, found %s\n' \
                "${result}" "${count}" >&2
            return 1
        fi
        sed -n 's/ init-ms=.*$//p' "${result}"
    }

    {
        printf 'phoneme-arm64-isa receipt\n'
        printf 'artifact-sha256=%s\n' "${ARTIFACT_SHA256}"
        printf 'source-head=%s\n' "${SOURCE_IDENTITY}"
        printf 'classes-sha256=%s\n' \
            "$(sha256sum -- "${CLDC_CLASSES}" | cut -d ' ' -f 1)"
        printf 'reference-vm-arch=i686 reference-vm-sha256=%s\n' \
            "$(sha256sum -- "${I686_VM}" | cut -d ' ' -f 1)"
        printf 'candidate-vm-arch=arm64 candidate-vm-sha256=%s\n' \
            "$(sha256sum -- "${ARM64_VM}" | cut -d ' ' -f 1)"
        printf 'candidate-execution=qemu-tcg timing-authoritative=no image=%s\n' \
            "${ARM64_IMAGE}"
        printf 'mode=%s candidate=%s extra-frames=%s\n' \
            "${MODE}" "${CANDIDATE}" "${EXTRA_FRAMES}"
    } >"${RECEIPT}"

    for cart in "${CARTS[@]}"; do
        I686_RESULT="${OUT_DIR}/${cart}-${MODE}-${CANDIDATE}-0.txt"
        ARM64_RESULT="${OUT_DIR}/${cart}-${MODE}-${CANDIDATE}-arm64-0.txt"
        I686_SIGNATURE="$(deterministic_signature "${I686_RESULT}")"

        if ! podman run --rm --arch arm64 \
            -v "${PHONEME_HOME}:/vp:ro,z" \
            -v "${OUT_DIR}/preverified:/pv:ro,z" \
            "${ARM64_IMAGE}" \
            /vp/cldc_vm_r-arm64 -EnableTicks =HeapCapacity64M \
            -classpath /vp/classes.zip:/pv \
            w4me.PhoneMeRouteBench "${cart}" "${MODE}" \
            "${EXTRA_FRAMES}" 1 "${CANDIDATE}" 0 \
            >"${ARM64_RESULT}" 2>&1; then
            printf 'FAIL phoneME arm64 cart=%s (VM exit)\n' "${cart}" >&2
            cat -- "${ARM64_RESULT}" >&2
            exit 1
        fi
        ARM64_SIGNATURE="$(deterministic_signature "${ARM64_RESULT}")"

        if [ "${I686_SIGNATURE}" != "${ARM64_SIGNATURE}" ]; then
            printf 'FAIL phoneME cross-ISA cart=%s deterministic state differs\n' \
                "${cart}" >&2
            printf 'i686: %s\n' "${I686_SIGNATURE}" >&2
            printf 'arm64: %s\n' "${ARM64_SIGNATURE}" >&2
            exit 1
        fi
        printf 'route cart=%s signature=%s\n' "${cart}" "${ARM64_SIGNATURE}" |
            tee -a "${RECEIPT}"
        printf 'PASS phoneME cross-ISA cart=%s checkpoints-and-counters=exact\n' \
            "${cart}"
    done

    printf 'PASS phoneME cross-ISA routes=%s timing-authoritative=no\n' \
        "${#CARTS[@]}"
    printf 'receipt: %s\n' "${RECEIPT}"
}

case "${1:-}" in
bench)
    shift
    cmd_bench "$@"
    ;;
verify)
    shift
    cmd_bench waternet rubido untangle game-of-life-zig-edition --reps 1 "$@"
    ;;
verify-arm64)
    shift
    cmd_verify_arm64 "$@"
    ;;
*)
    printf '%s\n' 'usage: tools/phoneme/run.sh <bench|verify|verify-arm64> [args...]' >&2
    exit 1
    ;;
esac
