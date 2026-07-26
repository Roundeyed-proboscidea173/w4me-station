package w4me.runtime.audio;

public final class AudioBackends {
    private AudioBackends() {}

    public static AudioBackend create() {
        return create(null);
    }

    public static AudioBackend create(String preference) {
        if ("tone".equals(preference)) {
            return createTone();
        }
        if ("midi".equals(preference)) {
            return createCompatible();
        }
        try {
            Object backend = Class.forName("w4me.runtime.audio.MmapiPcmBackend").newInstance();
            return (AudioBackend) backend;
        } catch (Throwable unavailable) {
            return createCompatible();
        }
    }

    static AudioBackend createCompatible() {
        try {
            Object backend =
                    Class.forName("w4me.runtime.audio.MmapiMidiBackend").newInstance();
            return (AudioBackend) backend;
        } catch (Throwable unavailable) {
            return createTone();
        }
    }

    private static AudioBackend createTone() {
        try {
            Object backend =
                    Class.forName("w4me.runtime.audio.MmapiToneBackend").newInstance();
            return (AudioBackend) backend;
        } catch (Throwable unavailable) {
            return new SilentAudioBackend();
        }
    }
}
