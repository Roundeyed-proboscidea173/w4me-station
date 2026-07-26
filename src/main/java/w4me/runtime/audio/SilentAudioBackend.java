package w4me.runtime.audio;

public final class SilentAudioBackend implements AudioBackend, AudioControl {
    public void submitTone(int frequency, int durationMillis, int volume, int flags) {}

    public void tick() {}

    public void close() {}

    public void silence() {}

    public int volumeCapability() {
        return SILENT;
    }

    public String grade() {
        return "E-silent";
    }
}
