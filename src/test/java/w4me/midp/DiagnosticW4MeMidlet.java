package w4me.midp;

/** Test-only MIDlet base that attaches diagnostics to the production session. */
public abstract class DiagnosticW4MeMidlet extends W4MeMidlet {
    protected W4SessionMonitor createSessionMonitor(
            String resource, String title) {
        return new DiagnosticW4SessionMonitor(
                title,
                replayRoute(resource, title),
                frameDiagnostics(),
                benchmarkWarmupFrames());
    }

    protected boolean replayRoute(String resource, String title) {
        return false;
    }

    protected boolean frameDiagnostics() {
        return "true".equals(getAppProperty("W4ME-Diagnostics"));
    }

    private int benchmarkWarmupFrames() {
        String value = getAppProperty("W4ME-Benchmark-Warmup-Frames");
        if (value == null) {
            return -1;
        }
        try {
            int frames = Integer.parseInt(value);
            if (frames >= 0 && frames <= 600) {
                return frames;
            }
        } catch (NumberFormatException invalid) {
            // The diagnostic harness reports no benchmark for an invalid setting.
        }
        return -1;
    }
}
