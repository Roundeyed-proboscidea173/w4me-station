package w4me.midp;

/** Product library with test-only frame diagnostics and the Duck Maze replay. */
public final class DiagnosticLibraryMidlet extends DiagnosticW4MeMidlet {
    protected boolean frameDiagnostics() {
        return true;
    }

    protected boolean replayRoute(String resource, String title) {
        return "Duck Maze".equals(title);
    }
}
