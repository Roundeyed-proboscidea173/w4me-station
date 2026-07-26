package w4me.midp;

import javax.microedition.rms.RecordEnumeration;
import javax.microedition.rms.RecordStore;

/** Versioned, fail-open RMS preferences for audio mode and user volume. */
final class AudioPreferences {
    private static final String STORE_NAME = "w4audio1";
    private static final int MAGIC_W = 0x57;
    private static final int MAGIC_4 = 0x34;
    private static final int VERSION = 2;
    private static final int FLAG_COMPATIBILITY = 1;
    private static final int FLAG_MUTED = 2;

    private AudioPreferences() {}

    static Settings load() {
        RecordStore store = null;
        RecordEnumeration records = null;
        try {
            store = RecordStore.openRecordStore(STORE_NAME, false);
            records = store.enumerateRecords(null, null, false);
            if (!records.hasNextElement()) {
                return Settings.defaults();
            }
            return decode(store.getRecord(records.nextRecordId()));
        } catch (Throwable unavailable) {
            return Settings.defaults();
        } finally {
            destroy(records);
            close(store);
        }
    }

    static boolean save(Settings settings) {
        RecordStore store = null;
        RecordEnumeration records = null;
        try {
            store = RecordStore.openRecordStore(STORE_NAME, true);
            byte[] value = encode(settings);
            records = store.enumerateRecords(null, null, false);
            if (records.hasNextElement()) {
                store.setRecord(records.nextRecordId(), value, 0, value.length);
            } else {
                store.addRecord(value, 0, value.length);
            }
            return true;
        } catch (Throwable unavailable) {
            return false;
        } finally {
            destroy(records);
            close(store);
        }
    }

    static byte[] encode(Settings settings) {
        int flags = 0;
        if (settings.compatibilityMode) {
            flags |= FLAG_COMPATIBILITY;
        }
        if (settings.muted) {
            flags |= FLAG_MUTED;
        }
        return new byte[] {
            (byte) MAGIC_W,
            (byte) MAGIC_4,
            (byte) VERSION,
            (byte) flags,
            (byte) clampGain(settings.gain)
        };
    }

    static Settings decode(byte[] value) {
        if (value == null) {
            return Settings.defaults();
        }
        if (value.length == 1) {
            return new Settings(value[0] == 1, false, 100);
        }
        if (value.length != 5
                || (value[0] & 0xff) != MAGIC_W
                || (value[1] & 0xff) != MAGIC_4
                || (value[2] & 0xff) != VERSION) {
            return Settings.defaults();
        }
        int flags = value[3] & 0xff;
        int gain = value[4] & 0xff;
        if (gain > 100) {
            return Settings.defaults();
        }
        return new Settings(
                (flags & FLAG_COMPATIBILITY) != 0,
                (flags & FLAG_MUTED) != 0,
                gain);
    }

    private static int clampGain(int gain) {
        if (gain < 0) {
            return 0;
        }
        return gain > 100 ? 100 : gain;
    }

    private static void close(RecordStore store) {
        if (store == null) {
            return;
        }
        try {
            store.closeRecordStore();
        } catch (Throwable ignored) {
            // Best effort for an optional preference.
        }
    }

    private static void destroy(RecordEnumeration records) {
        if (records == null) {
            return;
        }
        try {
            records.destroy();
        } catch (Throwable ignored) {
            // Best effort after reading or writing an optional preference.
        }
    }

    static final class Settings {
        final boolean compatibilityMode;
        final boolean muted;
        final int gain;

        Settings(boolean compatibilityMode, boolean muted, int gain) {
            this.compatibilityMode = compatibilityMode;
            this.muted = muted;
            this.gain = clampGain(gain);
        }

        static Settings defaults() {
            return new Settings(false, false, 100);
        }
    }
}
