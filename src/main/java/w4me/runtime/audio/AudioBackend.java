package w4me.runtime.audio;

public interface AudioBackend {
    /** Receives the four packed WASM-4 tone arguments without lossy conversion. */
    void submitTone(int frequency, int duration, int volume, int flags);

    void tick();

    void close();

    String grade();
}
