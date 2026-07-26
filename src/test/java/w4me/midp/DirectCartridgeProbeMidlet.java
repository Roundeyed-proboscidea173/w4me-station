package w4me.midp;

/**
 * Test-only direct cartridge launcher.
 *
 * <p>KEmulator injects raw Canvas keys and cannot navigate high-level LCDUI
 * Lists. These nested MIDlets keep cartridge scenarios independent from the
 * product launcher's presentation while still exercising the production
 * cartridge runtime.
 */
public abstract class DirectCartridgeProbeMidlet extends DiagnosticW4MeMidlet {
    private boolean started;

    protected void startApp() {
        if (!started) {
            started = true;
            openCartridge(cartridgeResource(), cartridgeTitle());
            return;
        }
        super.startApp();
    }

    protected boolean frameDiagnostics() {
        return true;
    }

    protected boolean replayRoute(String resource, String title) {
        return replayEnabled();
    }

    public String getAppProperty(String name) {
        if ("W4ME-Audio-Backend".equals(name) && compatibilityAudioEnabled()) {
            return "midi";
        }
        return super.getAppProperty(name);
    }

    protected boolean replayEnabled() {
        return false;
    }

    protected boolean compatibilityAudioEnabled() {
        return false;
    }

    protected abstract String cartridgeResource();

    protected abstract String cartridgeTitle();

    public static final class Duck extends DirectCartridgeProbeMidlet {
        protected String cartridgeResource() {
            return "/cartridges/duck-maze.wasm";
        }

        protected String cartridgeTitle() {
            return "Duck Maze";
        }

        protected boolean replayEnabled() {
            return true;
        }
    }

    public static final class Plasma extends DirectCartridgeProbeMidlet {
        protected String cartridgeResource() {
            return "/cartridges/plasma-cube.wasm";
        }

        protected String cartridgeTitle() {
            return "Plasma Cube";
        }
    }

    public static final class SoundDemo extends DirectCartridgeProbeMidlet {
        protected String cartridgeResource() {
            return "/cartridges/sound-demo.wasm";
        }

        protected String cartridgeTitle() {
            return "Sound Demo";
        }

        protected boolean compatibilityAudioEnabled() {
            return true;
        }
    }

    public static final class SoundTest extends DirectCartridgeProbeMidlet {
        protected String cartridgeResource() {
            return "/cartridges/sound-test.wasm";
        }

        protected String cartridgeTitle() {
            return "Sound Test";
        }
    }

    public static final class Tankle extends DirectCartridgeProbeMidlet {
        protected String cartridgeResource() {
            return "/cartridges/tankle.wasm";
        }

        protected String cartridgeTitle() {
            return "Tankle";
        }
    }
}
