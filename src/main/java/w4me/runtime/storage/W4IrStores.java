package w4me.runtime.storage;

import w4me.wasm.W4IrStore;

public final class W4IrStores {
    private static final int DEFAULT_CACHE_SLOTS = 12;

    private W4IrStores() {}

    public static W4IrStore create(byte[] cartridge) {
        return create(cartridge, DEFAULT_CACHE_SLOTS);
    }

    public static W4IrStore create(byte[] cartridge, int cacheSlots) {
        RmsW4IrStore store = null;
        try {
            store = RmsW4IrStore.open(cartridge, cacheSlots);
            return store;
        } catch (Throwable unavailable) {
            if (store != null) {
                store.close();
            }
            return null;
        }
    }
}
