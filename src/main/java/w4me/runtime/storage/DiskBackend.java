package w4me.runtime.storage;

public interface DiskBackend {
    int read(byte[] target, int offset, int size);

    int write(byte[] source, int offset, int size);

    void close();

    String grade();
}
