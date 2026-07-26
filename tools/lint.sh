#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${ROOT_DIR}/tools/container/env.sh"

mapfile -d '' scripts < <(
    find "${ROOT_DIR}/tools" -type f -name '*.sh' -print0 |
        sort -z
)

shellcheck "${scripts[@]}"
shfmt -d -i 4 "${scripts[@]}"

printf 'PASS shell scripts: ShellCheck and shfmt\n'
