#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${ROOT_DIR}/tools/container/env.sh"

cmd_untangle() {

    BUILD_DIR="${ROOT_DIR}/build/reports/bench/untangle"
    CLASSES_DIR="${BUILD_DIR}/classes"

    rm -rf -- "${BUILD_DIR}"
    mkdir -p -- "${CLASSES_DIR}"
    find "${ROOT_DIR}/src/main/java/w4me/wasm" \
        "${ROOT_DIR}/src/main/java/w4me/runtime" \
        -name '*.java' -print | sort >"${BUILD_DIR}/sources.list"
    javac \
        -source "${J2ME_SOURCE}" \
        -target "${J2ME_TARGET}" \
        -Xlint:-options \
        -bootclasspath "${J2ME_BOOTCLASSPATH}" \
        -classpath "${MIDP_API_JAR}" \
        -d "${CLASSES_DIR}" \
        @"${BUILD_DIR}/sources.list"
    javac \
        -source "${J2ME_SOURCE}" \
        -target "${J2ME_TARGET}" \
        -Xlint:-options \
        -classpath "${CLASSES_DIR}" \
        -d "${CLASSES_DIR}" \
        "${ROOT_DIR}/src/test/java/w4me/FramebufferOracle.java" \
        "${ROOT_DIR}/src/test/java/w4me/UntangleBenchmarkRoute.java" \
        "${ROOT_DIR}/src/test/java/w4me/UntangleRuntimeBenchmark.java"

    java -classpath "${CLASSES_DIR}" w4me.UntangleRuntimeBenchmark \
        "${ROOT_DIR}/src/main/resources/w4font.bin" \
        "${ROOT_DIR}/cartridges/untangle.wasm"
}

cmd_corpus() {

    RESULT_DIR="${ROOT_DIR}/build/reports/bench/corpus"
    CLASSES_DIR="${RESULT_DIR}/classes"
    ARTIFACT="${RESULT_DIR}/generic-corpus-profiler.jar"
    REPORT="${RESULT_DIR}/report.txt"
    REPORT_TMP="${RESULT_DIR}/report.txt.tmp"

    rm -rf -- "${RESULT_DIR}"
    mkdir -p -- "${CLASSES_DIR}"

    for cartridge in \
        mandelbrot \
        duck-maze \
        plasma-cube \
        waternet \
        rubido \
        untangle \
        game-of-life-zig-edition; do
        wasm-validate "${ROOT_DIR}/cartridges/${cartridge}.wasm"
    done

    find \
        "${ROOT_DIR}/src/main/java/w4me/wasm" \
        "${ROOT_DIR}/src/main/java/w4me/runtime" \
        -name '*.java' -print | sort >"${RESULT_DIR}/sources.list"

    javac \
        -source "${J2ME_SOURCE}" \
        -target "${J2ME_TARGET}" \
        -Xlint:-options \
        -bootclasspath "${J2ME_BOOTCLASSPATH}" \
        -classpath "${MIDP_API_JAR}" \
        -d "${CLASSES_DIR}" \
        @"${RESULT_DIR}/sources.list"

    javac \
        -source "${J2ME_SOURCE}" \
        -target "${J2ME_TARGET}" \
        -Xlint:-options \
        -classpath "${CLASSES_DIR}:${MIDP_API_JAR}" \
        -d "${CLASSES_DIR}" \
        "${ROOT_DIR}/src/test/java/w4me/FramebufferOracle.java" \
        "${ROOT_DIR}/src/test/java/w4me/wasm/OpcodeNames.java" \
        "${ROOT_DIR}/src/test/java/w4me/wasm/CorpusWorkload.java" \
        "${ROOT_DIR}/src/test/java/w4me/wasm/InterpreterVariant.java" \
        "${ROOT_DIR}/src/test/java/w4me/wasm/FullStateDifferential.java" \
        "${ROOT_DIR}/src/test/java/w4me/wasm/GenericCorpusProfiler.java"

    # Keep the profiler build identity stable for identical sources and toolchains.
    find "${CLASSES_DIR}" -exec touch -h -t 198001010000.00 -- {} +
    jar cfM "${ARTIFACT}" -C "${CLASSES_DIR}" .
    artifact_sha256="$(sha256sum -- "${ARTIFACT}" | cut -d ' ' -f 1)"
    font_sha256="$(sha256sum -- "${ROOT_DIR}/src/main/resources/w4font.bin" | cut -d ' ' -f 1)"

    java_arguments=(
        "${artifact_sha256}"
        "${ROOT_DIR}/src/main/resources/w4font.bin"
        "${ROOT_DIR}/cartridges/plasma-cube.wasm"
        "${ROOT_DIR}/cartridges/duck-maze.wasm"
        "${ROOT_DIR}/cartridges/waternet.wasm"
        "${ROOT_DIR}/testdata/oracles/waternet/input.csv"
        "${ROOT_DIR}/cartridges/rubido.wasm"
        "${ROOT_DIR}/testdata/oracles/rubido/input.csv"
        "${ROOT_DIR}/cartridges/untangle.wasm"
        "${ROOT_DIR}/testdata/oracles/untangle/input.csv"
        "${ROOT_DIR}/cartridges/game-of-life-zig-edition.wasm"
    )

    {
        printf 'GENERIC_CORPUS_ARTIFACT sha256=%s source=%s target=%s profile=host-exact font-sha256=%s\n' \
            "${artifact_sha256}" "${J2ME_SOURCE}" "${J2ME_TARGET}" "${font_sha256}"
        java -classpath "${ARTIFACT}" w4me.wasm.FullStateDifferential \
            "${java_arguments[@]}" reference-host-import-id
        java -classpath "${ARTIFACT}" w4me.wasm.GenericCorpusProfiler "${java_arguments[@]}"
    } | tee "${REPORT_TMP}"

    mv -- "${REPORT_TMP}" "${REPORT}"
    printf 'PASS generic corpus artifact=%s report=%s\n' "${artifact_sha256}" "${REPORT}"
}

cmd_fusions() {

    BUILD_DIR="${ROOT_DIR}/build/reports/bench/fusions"
    CLASSES_DIR="${BUILD_DIR}/classes"

    rm -rf -- "${BUILD_DIR}"
    mkdir -p -- "${CLASSES_DIR}"
    find "${ROOT_DIR}/src/main/java/w4me/wasm" \
        "${ROOT_DIR}/src/main/java/w4me/runtime" \
        -name '*.java' -print | sort >"${BUILD_DIR}/sources.list"
    javac \
        -source "${J2ME_SOURCE}" \
        -target "${J2ME_TARGET}" \
        -Xlint:-options \
        -bootclasspath "${J2ME_BOOTCLASSPATH}" \
        -classpath "${MIDP_API_JAR}" \
        -d "${CLASSES_DIR}" \
        @"${BUILD_DIR}/sources.list"
    javac \
        -source "${J2ME_SOURCE}" \
        -target "${J2ME_TARGET}" \
        -Xlint:-options \
        -classpath "${CLASSES_DIR}" \
        -d "${CLASSES_DIR}" \
        "${ROOT_DIR}/src/test/java/w4me/FramebufferOracle.java" \
        "${ROOT_DIR}/src/test/java/w4me/UntangleBenchmarkRoute.java" \
        "${ROOT_DIR}/src/test/java/w4me/wasm/W4IrFusionProfile.java"

    java -classpath "${CLASSES_DIR}" w4me.wasm.W4IrFusionProfile \
        "${ROOT_DIR}/src/main/resources/w4font.bin" \
        "${ROOT_DIR}/cartridges/plasma-cube.wasm" \
        "${ROOT_DIR}/cartridges/untangle.wasm" |
        tee "${BUILD_DIR}/profile.txt"
}

case "${1:-}" in
untangle)
    shift
    cmd_untangle "$@"
    ;;
corpus)
    shift
    cmd_corpus "$@"
    ;;
fusions)
    shift
    cmd_fusions "$@"
    ;;
*)
    printf '%s\n' 'usage: tools/bench/run.sh <untangle|corpus|fusions> [args...]' >&2
    exit 1
    ;;
esac
