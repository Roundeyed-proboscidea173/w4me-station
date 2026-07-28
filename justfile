set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Build the project toolchain image. Commands start disposable containers from it.
setup:
    ./tools/container/setup.sh

# Print and validate every required development tool.
doctor:
    ./tools/toolchain.sh

# Check every project shell script without rewriting it.
lint:
    ./tools/lint.sh

# Build both CLDC 1.1 / MIDP 2.0 release variants with Java 1.3 bytecode.
build:
    ./tools/build.sh

# Run deterministic parser, interpreter, framebuffer, audio, and storage tests.
test:
    ./tools/test.sh

# Run the complete local correctness gate, including release JAR validation.
verify: lint test build
    ./tools/verify.sh counterless

# Build and open the station in KEmulator.
run: build
    KEMU_SIZE=240x320 ./tools/kemu/run.sh session start dist/w4me-station.jar

# Benchmark exact corpus routes on the native no-JIT phoneME reference VM.
bench *args:
    ./tools/phoneme/run.sh bench {{ args }}

# Benchmark production PCM synthesis on the native no-JIT phoneME reference VM.
bench-pcm *args:
    ./tools/phoneme/run.sh bench-pcm {{ args }}

# Benchmark framebuffer-to-ARGB conversion on native no-JIT phoneME.
bench-argb *args:
    ./tools/phoneme/run.sh bench-argb {{ args }}

# Re-run all release checks and write dist/SHA256SUMS.
release:
    ./tools/release.sh
