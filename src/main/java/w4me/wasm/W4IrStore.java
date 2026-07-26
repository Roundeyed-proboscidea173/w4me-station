package w4me.wasm;

/** Optional persistent backing store for decoded W4IR code. */
public interface W4IrStore {
    boolean isComplete(int functionCount);

    W4IrFunction loadFunction(int functionIndex) throws WasmException;

    void begin(int functionCount) throws WasmException;

    void writeFunction(
            int functionIndex,
            int declaredLocalCount,
            int[] code,
            int[][] branchTables,
            int[] branchDescriptors,
            int[] branchDescriptorPcs,
            int[] branchDescriptorIndices,
            int[][] branchDescriptorTables,
            long fingerprint,
            int intrinsic) throws WasmException;

    void commit() throws WasmException;

    int[] loadPage(W4IrFunction function, int pageIndex);

    int pageFaults();

    int pageHits();

    void discard();

    void close();
}
