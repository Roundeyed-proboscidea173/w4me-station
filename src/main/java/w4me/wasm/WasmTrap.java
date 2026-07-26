package w4me.wasm;

public final class WasmTrap extends RuntimeException {
    public WasmTrap(String message) {
        super(message);
    }
}
