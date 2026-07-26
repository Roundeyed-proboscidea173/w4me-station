# WASM-4 for J2ME toolchain distrobox

The `w4me-station` distrobox is the canonical environment for project
commands. It pins JDK 8, KEmulator, Rust, and supporting tools.

## Setup

Install `just`, Podman, and Distrobox on the Linux host. Then build the image
and create the box once per machine:

```sh
just setup
just doctor
```

Project scripts source `tools/container/env.sh`. When launched from the host, they
automatically re-exec themselves inside the box with a sanitized `PATH`.
Java ME sources target Java 1.3. Both `J2ME_SOURCE` and `J2ME_TARGET` are
pinned to `1.3` by `tools/container/env.sh`.

## KEmulator

Start a clean headless session for a MIDlet JAR:

```sh
tools/kemu/run.sh session start path/to/application.jar
tools/kemu/run.sh session cmd status
tools/kemu/run.sh session cmd screenshot --out /tmp/w4me.png
tools/kemu/run.sh session stop
```

The emulator bundle from `/opt/kemu` is copied to a temporary writable
directory for every session because KEmulator writes RMS and runtime state
next to its bundle. The default display size is `240x320`; override it with
`KEMU_SIZE=160x160` (or another `WxH` value). The default virtual display is
`:98`, configurable through `KEMU_DISPLAY`.

The raw automation entry point is also available:

```sh
tools/kemu/run.sh session start path/to/application.jar
tools/kemu/run.sh session cmd tap 80 80
tools/kemu/run.sh session cmd key FIRE
tools/kemu/run.sh session stop
```

## Pinned tools

| Tool | Version / source |
| --- | --- |
| Base image | Fedora 44 |
| Temurin JDK | `jdk8u492-b09` in `/opt/jdk8` |
| Java ME source/target | `1.3` / `1.3` |
| ProGuard | `7.0.1`, Java ME `StackMap` preverification |
| CLDC/MIDP API lint | MicroEmulator `cldcapi11:2.0.4` and `midpapi20:2.0.4` LGPL build-time stubs, checksum-pinned |
| KEmulator | `mulfyx/KEmulator` commit `73ba4b14b8c2` in `/opt/kemu` |
| Rust | `1.96.0` with `rustfmt`, `clippy`, and `wasm32-unknown-unknown` |
| WABT | Fedora 44 package (`wasm2wat`, `wasm-objdump`, `wasm-validate`) |
| Taplo CLI | `0.7.0` |
| Node.js, npm, Python | Fedora 44 packages |
