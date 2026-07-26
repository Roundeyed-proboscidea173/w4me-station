package w4me;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;

import w4me.runtime.Wasm4Runtime;
import w4me.wasm.WasmInterpreter;
import w4me.wasm.WasmModule;

/**
 * Reference-VM route benchmark. Replays a recorded browser-oracle route and
 * verifies every oracle checkpoint (framebuffer FNV-1a, palette, input state)
 * while timing the interpreter. CLDC 1.1 clean by construction: it runs
 * unchanged on the local phoneME `cldc_vm_r` (the reference measurement,
 * see docs/performance.md) and on any J2SE VM for cross-checks.
 *
 * Arguments: cartridge mode extra-frames repetitions candidate sample-start
 * Modes mirror the KEmulator Untangle benchmark family:
 * optimized | trace-off | fusion-only | baseline.
 * Resources looked up on the classpath: /<cart>.wasm, /<cart>-input.csv,
 * /<cart>-oracle.csv (optional), /w4font.bin.
 */
public final class PhoneMeRouteBench {
    public static void main(String[] args) throws Exception {
        if (args.length != 6) {
            throw new IllegalArgumentException(
                    "usage: cart optimized|trace-off|fusion-only|baseline"
                            + " extraFrames reps"
                            + " current|seven-opcode|host-import-id|counterless"
                            + "|resident-baseline|dense-baseline"
                            + "|load-tee-baseline|load-tee"
                            + "|branch-legacy|branch-inline|branch-direct"
                            + " sampleStart");
        }
        String cart = args[0];
        String mode = args[1];
        int extraFrames = Integer.parseInt(args[2]);
        int repetitions = Integer.parseInt(args[3]);
        String candidate = args[4];
        int sampleStart = Integer.parseInt(args[5]);
        boolean numericHostImportDispatch =
                "host-import-id".equals(candidate)
                        || "counterless".equals(candidate)
                        || "resident-baseline".equals(candidate)
                        || "dense-baseline".equals(candidate)
                        || "load-tee-baseline".equals(candidate)
                        || "load-tee".equals(candidate)
                        || "branch-legacy".equals(candidate)
                        || "branch-inline".equals(candidate)
                        || "branch-direct".equals(candidate);
        boolean integerCompactOpcodes =
                "seven-opcode".equals(candidate) || numericHostImportDispatch;
        boolean loadTeeFusions = !"load-tee-baseline".equals(candidate);
        if (!"current".equals(candidate) && !integerCompactOpcodes) {
            throw new IllegalArgumentException("unknown candidate: " + candidate);
        }
        boolean extended = !"baseline".equals(mode);
        boolean compact = "optimized".equals(mode) || "trace-off".equals(mode);
        boolean trace = "optimized".equals(mode) || "fusion-only".equals(mode);
        if (!"optimized".equals(mode)
                && !"trace-off".equals(mode)
                && !"fusion-only".equals(mode)
                && !"baseline".equals(mode)) {
            throw new IllegalArgumentException("unknown mode: " + mode);
        }

        byte[] font = readResource("/w4font.bin");
        byte[] cartridge = readResource("/" + cart + ".wasm");
        int[][] inputTrace = readCsv("/" + cart + "-input.csv", 5);
        int[][] oracle = readOracle("/" + cart + "-oracle.csv");
        int frames =
                (inputTrace.length == 0 ? 0 : inputTrace[inputTrace.length - 1][0])
                        + extraFrames;

        int repetition;
        for (repetition = 0; repetition < repetitions; repetition++) {
            long initStart = System.currentTimeMillis();
            WasmModule module =
                    WasmModule.read(
                            cartridge,
                            null,
                            extended,
                            loadTeeFusions);
            Wasm4Runtime runtime = new Wasm4Runtime(font);
            runtime.initialize(module);
            WasmInterpreter interpreter = new WasmInterpreter(module, runtime);
            interpreter.setFastPathsEnabled(false);
            interpreter.setCompactExecutorEnabled(compact);
            interpreter.setTraceExecutorEnabled(trace);
            interpreter.setIntegerCompactOpcodesEnabled(integerCompactOpcodes);
            interpreter.setNumericHostImportDispatchEnabled(numericHostImportDispatch);
            interpreter.invokeCartridgeLifecycle();
            long initMs = System.currentTimeMillis() - initStart;

            int inputIndex = 0;
            int oracleIndex = 0;
            int gamepad = 0;
            int mouseX = 0x7fff;
            int mouseY = 0x7fff;
            int mouseButtons = 0;
            long dispatches = 0;
            long fastPaths = 0;
            long compactCalls = 0;
            long compactInstructions = 0;
            long traceCalls = 0;
            long traceIterations = 0;
            long instructions = 0;
            int checkpoints = 0;
            long start = System.currentTimeMillis();
            int frame;
            for (frame = 0; frame < frames; frame++) {
                while (inputIndex < inputTrace.length
                        && inputTrace[inputIndex][0] == frame) {
                    gamepad = inputTrace[inputIndex][1];
                    mouseX = inputTrace[inputIndex][2];
                    mouseY = inputTrace[inputIndex][3];
                    mouseButtons = inputTrace[inputIndex][4];
                    inputIndex++;
                }
                runtime.beginFrame(module, gamepad, mouseX, mouseY, mouseButtons);
                interpreter.invoke("update");
                runtime.endFrame();
                dispatches += interpreter.dispatchesExecuted();
                fastPaths += interpreter.fastPathCalls();
                compactCalls += interpreter.compactBlockCalls();
                compactInstructions += interpreter.compactInstructionsExecuted();
                traceCalls += interpreter.traceLoopCalls();
                traceIterations += interpreter.traceLoopIterations();
                instructions += interpreter.instructionsExecuted();
                if (oracleIndex < oracle.length && oracle[oracleIndex][0] == frame) {
                    checkCheckpoint(
                            cart, module, runtime, oracle[oracleIndex],
                            gamepad, mouseX, mouseY, mouseButtons);
                    oracleIndex++;
                    checkpoints++;
                }
            }
            long elapsed = System.currentTimeMillis() - start;
            if (oracleIndex != oracle.length) {
                throw new RuntimeException(
                        "phoneme-bench:fail cart=" + cart
                                + " unconsumed oracle checkpoints: "
                                + (oracle.length - oracleIndex));
            }
            System.out.println("phoneme-bench:pass cart=" + cart
                    + " mode=" + mode
                    + " candidate=" + candidate
                    + " sample=" + (sampleStart + repetition)
                    + " rep=" + repetition
                    + " w4ir-format=" + WasmModule.W4IR_FORMAT_VERSION
                    + " frames=" + frames
                    + " checkpoints=" + checkpoints
                    + " instructions=" + instructions
                    + " dispatches=" + dispatches
                    + " fast-paths=" + fastPaths
                    + " compact-calls=" + compactCalls
                    + " compact-instructions=" + compactInstructions
                    + " trace-calls=" + traceCalls
                    + " trace-iterations=" + traceIterations
                    + " branch-fast-int-count="
                    + interpreter.directBranchFastPathIntCount()
                    + " branch-fast-array-count="
                    + interpreter.directBranchFastPathArrayCount()
                    + " branch-fast-payload-bytes="
                    + (interpreter.directBranchFastPathIntCount() * 4)
                    + " init-ms=" + initMs
                    + " wall-ms=" + elapsed
                    + " us-per-frame="
                    + (frames == 0 ? 0 : elapsed * 1000 / frames));
        }
    }

    private static void checkCheckpoint(
            String cart,
            WasmModule module,
            Wasm4Runtime runtime,
            int[] receipt,
            int gamepad,
            int mouseX,
            int mouseY,
            int mouseButtons) {
        int frame = receipt[0];
        requireEquals(cart, frame, "gamepad", receipt[1], gamepad);
        requireEquals(cart, frame, "mouse-x", receipt[2], mouseX);
        requireEquals(cart, frame, "mouse-y", receipt[3], mouseY);
        requireEquals(cart, frame, "mouse-buttons", receipt[4], mouseButtons);
        requireEquals(
                cart, frame, "framebuffer-fnv1a",
                receipt[5], FramebufferOracle.fnv1a(module));
        byte[] memory = module.memory();
        int index;
        for (index = 0; index < 4; index++) {
            int address = Wasm4Runtime.PALETTE + index * 4;
            int actual = (memory[address] & 0xff)
                    | ((memory[address + 1] & 0xff) << 8)
                    | ((memory[address + 2] & 0xff) << 16)
                    | (memory[address + 3] << 24);
            requireEquals(cart, frame, "palette" + index, receipt[6 + index], actual);
        }
    }

    private static void requireEquals(
            String cart, int frame, String what, int expected, int actual) {
        if (expected != actual) {
            throw new RuntimeException("phoneme-bench:fail cart=" + cart
                    + " frame=" + frame
                    + " " + what
                    + " expected=0x" + Integer.toHexString(expected)
                    + " actual=0x" + Integer.toHexString(actual));
        }
    }

    /** Reads the leading integer fields of each CSV row, skipping the header. */
    private static int[][] readCsv(String path, int fieldCount) throws Exception {
        String text = readText(path);
        if (text == null) {
            return new int[0][];
        }
        int[][] rows = new int[1024][];
        int count = 0;
        int position = 0;
        boolean header = true;
        while (position < text.length()) {
            int lineEnd = text.indexOf('\n', position);
            if (lineEnd < 0) {
                lineEnd = text.length();
            }
            String line = text.substring(position, lineEnd).trim();
            position = lineEnd + 1;
            if (line.length() == 0) {
                continue;
            }
            if (header) {
                header = false;
                continue;
            }
            rows[count++] = parseFields(line, fieldCount);
        }
        int[][] result = new int[count][];
        System.arraycopy(rows, 0, result, 0, count);
        return result;
    }

    /**
     * Oracle rows become
     * {frame, gamepad, mouseX, mouseY, mouseButtons, fnv1a, palette0..3}.
     * The SHA-256 column is skipped: CLDC has no digest API and the FNV-1a
     * plus palette comparison is already an exact framebuffer check.
     */
    private static int[][] readOracle(String path) throws Exception {
        String text = readText(path);
        if (text == null) {
            return new int[0][];
        }
        int[][] rows = new int[256][];
        int count = 0;
        int position = 0;
        boolean header = true;
        while (position < text.length()) {
            int lineEnd = text.indexOf('\n', position);
            if (lineEnd < 0) {
                lineEnd = text.length();
            }
            String line = text.substring(position, lineEnd).trim();
            position = lineEnd + 1;
            if (line.length() == 0) {
                continue;
            }
            if (header) {
                header = false;
                continue;
            }
            String[] fields = splitFields(line, 12);
            int[] receipt = new int[10];
            int index;
            for (index = 0; index < 5; index++) {
                receipt[index] = Integer.parseInt(fields[index]);
            }
            receipt[5] = (int) Long.parseLong(fields[6], 16);
            for (index = 0; index < 4; index++) {
                receipt[6 + index] = (int) Long.parseLong(fields[7 + index], 16);
            }
            rows[count++] = receipt;
        }
        int[][] result = new int[count][];
        System.arraycopy(rows, 0, result, 0, count);
        return result;
    }

    private static int[] parseFields(String line, int fieldCount) {
        String[] fields = splitFields(line, fieldCount);
        int[] values = new int[fieldCount];
        int index;
        for (index = 0; index < fieldCount; index++) {
            values[index] = Integer.parseInt(fields[index]);
        }
        return values;
    }

    private static String[] splitFields(String line, int minimumFields) {
        String[] fields = new String[16];
        int count = 0;
        int start = 0;
        while (count < fields.length) {
            int comma = line.indexOf(',', start);
            if (comma < 0) {
                fields[count++] = line.substring(start);
                break;
            }
            fields[count++] = line.substring(start, comma);
            start = comma + 1;
        }
        if (count < minimumFields) {
            throw new IllegalArgumentException("short csv row: " + line);
        }
        return fields;
    }

    private static String readText(String path) throws Exception {
        InputStream input = PhoneMeRouteBench.class.getResourceAsStream(path);
        if (input == null) {
            return null;
        }
        try {
            return new String(readAll(input));
        } finally {
            input.close();
        }
    }

    private static byte[] readResource(String path) throws Exception {
        InputStream input = PhoneMeRouteBench.class.getResourceAsStream(path);
        if (input == null) {
            throw new RuntimeException("missing classpath resource: " + path);
        }
        try {
            return readAll(input);
        } finally {
            input.close();
        }
    }

    private static byte[] readAll(InputStream input) throws Exception {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[4096];
        int read;
        while ((read = input.read(buffer)) > 0) {
            output.write(buffer, 0, read);
        }
        return output.toByteArray();
    }
}
