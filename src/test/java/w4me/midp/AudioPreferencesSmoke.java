package w4me.midp;

public final class AudioPreferencesSmoke {
    public static void main(String[] arguments) {
        AudioPreferences.Settings defaults = AudioPreferences.decode(null);
        assertSettings("null defaults", defaults, false, false, 100);
        assertSettings(
                "legacy automatic",
                AudioPreferences.decode(new byte[] {0}),
                false,
                false,
                100);
        assertSettings(
                "legacy compatible",
                AudioPreferences.decode(new byte[] {1}),
                true,
                false,
                100);

        AudioPreferences.Settings expected =
                new AudioPreferences.Settings(true, true, 40);
        byte[] encoded = AudioPreferences.encode(expected);
        assertSettings(
                "versioned round trip",
                AudioPreferences.decode(encoded),
                true,
                true,
                40);

        assertSettings(
                "corrupt record defaults",
                AudioPreferences.decode(new byte[] {0x57, 0x34, 2, 3, (byte) 101}),
                false,
                false,
                100);
        assertSettings(
                "unknown version defaults",
                AudioPreferences.decode(new byte[] {0x57, 0x34, 3, 0, 50}),
                false,
                false,
                100);

        System.out.println("PASS audio-preferences legacy-migration versioned corrupt-default");
    }

    private static void assertSettings(
            String label,
            AudioPreferences.Settings settings,
            boolean compatibility,
            boolean muted,
            int gain) {
        if (settings.compatibilityMode != compatibility
                || settings.muted != muted
                || settings.gain != gain) {
            throw new AssertionError(
                    label
                            + ": got compatibility="
                            + settings.compatibilityMode
                            + " muted="
                            + settings.muted
                            + " gain="
                            + settings.gain);
        }
    }
}
