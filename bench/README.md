# Benchmark configurations

`configs/` contains package-private build-time replacements used to compile
isolated interpreter variants. They are not production source roots and are
only selected explicitly by `tools/phoneme/run.sh` or `tools/verify.sh`.

The native i686 phoneME C interpreter is the timing judge. Every candidate
must also pass exact corpus state checks. See
[`docs/performance.md`](../docs/performance.md).
