#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${ROOT_DIR}/tools/container/env.sh"

printf 'container-image: %s\n' "${W4ME_TOOLCHAIN_IMAGE:-w4me-station:latest}"
java -version
javac -version
python3 --version
wasm2wat --version
wasm-validate --version
strings --version | sed -n '1p'
unzip -p "${PROGUARD_HOME}/lib/proguard.jar" META-INF/MANIFEST.MF |
    sed -n 's/^Implementation-Version: /ProGuard /p'
just --version
shellcheck --version | sed -n '1,2p'
shfmt --version

test -x "${KEMU_HOME}/kemu.sh"
test -r "${CLDC_API_JAR}"
test -r "${MIDP_API_STUB_JAR}"
test -r "${MIDP_API_JAR}"
"${KEMU_HOME}/kemu.sh" help | sed -n '1p'
printf 'CLDC/MIDP API bootclasspath: %s\n' "${J2ME_BOOTCLASSPATH}"
printf 'KEmulator bundle: %s\n' "${KEMU_HOME}"
