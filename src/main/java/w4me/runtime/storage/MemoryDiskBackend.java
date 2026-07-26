package w4me.runtime.storage;

public final class MemoryDiskBackend implements DiskBackend {
    private final byte[] data = new byte[1024];
    private int length;

    public int read(byte[] target, int offset, int size) {
        int count = minimum(size, length);
        System.arraycopy(data, 0, target, offset, count);
        return count;
    }

    public int write(byte[] source, int offset, int size) {
        int count = minimum(size, data.length);
        System.arraycopy(source, offset, data, 0, count);
        length = count;
        return count;
    }

    public void close() {}

    public String grade() {
        return "memory";
    }

    private int minimum(int left, int right) {
        return left < right ? left : right;
    }
}
