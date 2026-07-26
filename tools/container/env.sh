#!/usr/bin/env bash
# Canonical project toolchain environment. Project scripts source this file;
# when invoked from the host they re-exec themselves inside the distrobox.

if [ "${CONTAINER_ID:-}" != "w4me-station" ]; then
    if command -v distrobox >/dev/null 2>&1; then
        script="$(readlink -f -- "$0")"
        exec distrobox enter w4me-station -- "${script}" "$@"
    fi
    printf 'error: run inside the w4me-station distrobox (see tools/container/README.md)\n' >&2
    exit 1
fi

# Keep host-installed tools out of project commands.
export PATH="/opt/jdk8/bin:/opt/proguard/bin:/usr/local/bin:/usr/bin:/bin"

export JAVA_HOME="/opt/jdk8"
export JDK8_HOME="/opt/jdk8"
export KEMU_HOME="/opt/kemu"
export PROGUARD_HOME="/opt/proguard"
export CLDC_API_JAR="${CLDC_API_JAR:-/opt/j2me-api/cldcapi11-2.0.4.jar}"
export MIDP_API_STUB_JAR="${MIDP_API_STUB_JAR:-/opt/j2me-api/midpapi20-2.0.4.jar}"
export J2ME_BOOTCLASSPATH="${CLDC_API_JAR}:${MIDP_API_STUB_JAR}"
export MIDP_API_JAR="/opt/kemu/KEmulator.jar"
export J2ME_SOURCE="1.3"
export J2ME_TARGET="1.3"
