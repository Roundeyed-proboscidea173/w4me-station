package w4me.midp;

public final class TrapCartProbeMidlet extends DiagnosticW4MeMidlet {
    private static final String URL = "http://127.0.0.1:18387/trap.wasm";

    public String getAppProperty(String name) {
        if ("W4ME-Cartridge-URL".equals(name)) {
            return URL;
        }
        if ("W4ME-Diagnostics".equals(name)) {
            return "true";
        }
        return super.getAppProperty(name);
    }
}
