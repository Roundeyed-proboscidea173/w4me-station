set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Build the project toolchain image and create the project distrobox.
setup:
    podman build -t wasm-4-for-j2me tools/container/
    distrobox create --name wasm-4-for-j2me --image localhost/wasm-4-for-j2me:latest

# Print and validate every required development tool.
doctor:
    ./tools/toolchain.sh

# Build both CLDC 1.1 / MIDP 2.0 release variants with Java 1.3 bytecode.
build:
    ./tools/build.sh

# Run deterministic parser, interpreter, framebuffer, audio, and storage tests.
test:
    ./tools/test.sh

# Run the complete local correctness gate, including release JAR validation.
verify: test build
    ./tools/verify.sh counterless

# Build and open the station in KEmulator.
run: build
    KEMU_SIZE=240x320 ./tools/kemu/run.sh session start dist/w4me-station.jar

# Benchmark exact corpus routes on the native no-JIT phoneME reference VM.
bench *args:
    ./tools/phoneme/run.sh bench {{ args }}

# Re-run all release checks and write dist/SHA256SUMS.
release:
    ./tools/release.sh
