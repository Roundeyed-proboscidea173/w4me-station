package w4me.wasm;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.InputStream;

import w4me.runtime.Wasm4Runtime;

public final class PlasmaTriDifferentialSmoke {
    public static void main(String[] arguments) throws Exception {
        if (arguments.length != 2) {
            throw new IllegalArgumentException("usage: font.bin plasma.wasm");
        }
        byte[] font = readFile(arguments[0]);
        WasmModule module = WasmModule.read(readFile(arguments[1]));
        Wasm4Runtime runtime = new Wasm4Runtime(font);
        runtime.initialize(module);
        WasmInterpreter interpreter = new WasmInterpreter(module, runtime);
        interpreter.setInstructionLimit(200000000L);
        interpreter.setPlasmaTriDifferentialEnabled(true);
        interpreter.invokeCartridgeLifecycle();

        int frame;
        for (frame = 0; frame < 60; frame++) {
            runtime.beginFrame(module, 0, 0, 0, 0);
            interpreter.invoke("update");
            runtime.endFrame();
        }
        if (interpreter.plasmaTriDifferentialCalls() != 720) {
            throw new AssertionError(
                    "expected 720 differential calls, got "
                            + interpreter.plasmaTriDifferentialCalls());
        }

        WasmModule productionModule = WasmModule.read(readFile(arguments[1]));
        Wasm4Runtime productionRuntime = new Wasm4Runtime(font);
        productionRuntime.initialize(productionModule);
        WasmInterpreter productionInterpreter =
                new WasmInterpreter(productionModule, productionRuntime);
        productionInterpreter.setInstructionLimit(200000000L);
        productionInterpreter.invokeCartridgeLifecycle();
        productionRuntime.beginFrame(productionModule, 0, 0, 0, 0);
        productionInterpreter.invoke("update");
        productionRuntime.endFrame();
        if (productionInterpreter.fastPathCalls() != 12) {
            throw new AssertionError(
                    "expected 12 production fast-path calls, got "
                            + productionInterpreter.fastPathCalls());
        }
        System.out.println(
                "PASS Plasma fast-path production-calls=12 differential-calls=720 frames=60");
    }

    private static byte[] readFile(String path) throws Exception {
        InputStream input = new FileInputStream(path);
        try {
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            int count;
            while ((count = input.read(buffer)) >= 0) {
                output.write(buffer, 0, count);
            }
            return output.toByteArray();
        } finally {
            input.close();
        }
    }
}
