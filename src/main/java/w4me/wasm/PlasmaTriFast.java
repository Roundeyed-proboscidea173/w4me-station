package w4me.wasm;

/** Fingerprint-guarded native equivalent of Plasma Cube's triangle shader. */
strictfp final class PlasmaTriFast {
    static final long FINGERPRINT = 0x796cf5a13e0b9933L;
    private static final long CARTRIDGE_FINGERPRINT = 0xc5c3ce511f45510eL;
    private static final int CARTRIDGE_LENGTH = 5573;
    private static final int WORK_LIMIT = 262144;

    private static final float TWO_PI = Float.intBitsToFloat(0x40c90fdb);
    private static final float PHASE_SCALE = Float.intBitsToFloat(0x3f333333);
    private static final float ROW_SCALE = Float.intBitsToFloat(0x3f11e10e);
    private static final float ATTRIBUTE_SCALE = Float.intBitsToFloat(0x3f413faa);
    private static final float TIME_SCALE = Float.intBitsToFloat(0x3fa66666);
    private static final float SHADE_SCALE = Float.intBitsToFloat(0x3e4ccccd);
    private static final float NAN = Float.intBitsToFloat(0x7fc00001);

    private PlasmaTriFast() {}

    static boolean matches(WasmModule module, WasmModule.FunctionBody body) {
        return module.cartridgeLength == CARTRIDGE_LENGTH
                && module.cartridgeFingerprint == CARTRIDGE_FINGERPRINT
                && body.fingerprint == FINGERPRINT;
    }

    static void run(WasmModule module, int trianglePointer, int basisPointer) {
        byte[] memory = module.memory;
        int c = (int) module.globals[0] - 48;
        checkRange(memory, trianglePointer, 24);
        checkRange(memory, basisPointer, 44);
        checkRange(memory, c, 44);
        module.globals[0] = c;
        try {
            float e = loadF32(memory, trianglePointer + 8);
            float f = loadF32(memory, trianglePointer);
            float g = loadF32(memory, trianglePointer + 20);
            float h = loadF32(memory, trianglePointer + 4);
            float i = loadF32(memory, trianglePointer + 12);
            float j = loadF32(memory, trianglePointer + 16);
            float left = (e - f) * (g - h);
            float right = (i - h) * (j - f);
            if (left - right > 0.0f) {
                return;
            }

            int d = 1;
            int k = 0;
            int l = 2;
            memory[c + 30] = memory[6818];
            storeU16(memory, c + 28, loadU16(memory, 6816));

            float m;
            float n;
            float o;
            if (h > i) {
                k = 1;
                storeU16(memory, c + 28, 1);
                d = 0;
                m = h;
                n = e;
                o = i;
            } else {
                m = i;
                n = f;
                o = h;
                f = e;
                h = i;
            }

            int a;
            float p;
            if (m > g) {
                memory[c + 30] = (byte) d;
                a = 2;
                memory[c + 29] = 2;
                m = g;
                l = d;
                e = j;
                p = g;
            } else {
                a = d;
                e = f;
                p = h;
                f = j;
                h = g;
            }

            if (o > m) {
                memory[c + 29] = (byte) k;
                memory[c + 28] = (byte) a;
                j = o;
                g = e;
                i = p;
            } else {
                j = m;
                m = o;
                a = k;
                g = n;
                i = o;
                n = e;
                o = p;
            }

            int q = roundToI32(m);
            int r = roundToI32(h);
            int s = roundToI32(n);
            int t = roundToI32(j);
            m = f - g;
            o = o - i;
            n = n - g;
            h = h - i;
            int u = roundToI32(f);
            f = m * o;
            h = h * n;
            float v = (float) q;
            m = (float) r;
            d = l << 4;
            a = a << 4;
            int w = roundToI32(g);
            float x = h - f;
            float y = m - v;
            int z = d + 6720;
            int aa = a + 6720;
            float ba = (float) u;
            float ca = (float) w;
            int da = basisPointer + 36;
            int ea = 0;
            int fa = q;
            int work = 0;

            while (ea != 2) {
                a = memory[6819 + ea] & 0xff;
                d = a != 0 ? t : r;
                int ga = d > fa ? d : fa;
                float ha = (float) (a != 0 ? q : t);
                float ia = (float) d - ha;
                int ja = c + 28 + (a != 0 ? 1 : 2);
                int ka = (c + 28) | (a ^ 1);
                float la = (float) (a != 0 ? s : u);
                float ma = (float) (a != 0 ? w : s);

                while (fa != ga) {
                    if (++work > WORK_LIMIT) {
                        throw new WasmTrap("Plasma fast-path work limit exhausted");
                    }
                    g = (float) fa;
                    h = (g - v) / y;
                    i = h * loadF32(memory, z + 4);
                    m = 1.0f - h;
                    n = m * loadF32(memory, aa + 4);
                    f = (g - ha) / ia;
                    k = (memory[ja] & 0xff) << 4;
                    int na = k + 6720;
                    e = f * loadF32(memory, na + 4);
                    o = 1.0f - f;
                    int oa = (memory[ka] & 0xff) << 4;
                    int pa = oa + 6720;
                    j = o * loadF32(memory, pa + 4);
                    p = h * ba + m * ca;
                    float qa = f * la + o * ma;
                    boolean reversed = x < 0.0f;
                    float ra = reversed ? p : qa;
                    d = roundToI32(ra);
                    i = n + i;
                    n = j + e;
                    qa = reversed ? qa : p;
                    l = roundToI32(qa);
                    float sa = reversed ? i : n;
                    float ta = reversed ? n : i;
                    int ua = l > d ? l : d;
                    ra = ra - qa;
                    i = m * loadF32(memory, aa + 8) + h * loadF32(memory, z + 8);
                    n = o * loadF32(memory, oa + 6728)
                            + f * loadF32(memory, k + 6728);
                    float va = reversed ? i : n;
                    h = m * loadF32(memory, aa) + h * loadF32(memory, z);
                    f = o * loadF32(memory, pa) + f * loadF32(memory, na);
                    float wa = reversed ? h : f;
                    float xa = reversed ? n : i;
                    float ya = reversed ? f : h;
                    oa = fa * 40;
                    float za = g * ROW_SCALE;

                    while (l != ua) {
                        if (++work > WORK_LIMIT) {
                            throw new WasmTrap("Plasma fast-path work limit exhausted");
                        }
                        n = (float) l;
                        h = (n - qa) / ra;
                        f = 1.0f - h;
                        e = va * h + xa * f;
                        j = wa * h + ya * f;
                        p = sa * h + ta * f;
                        storeF32(memory, c + 40, e);
                        storeF32(memory, c + 32, j);
                        storeF32(memory, c + 36, p);

                        o = loadF32(memory, basisPointer + 40);
                        g = loadF32(memory, da);
                        i = loadF32(memory, basisPointer + 32);
                        h = 0.0f;
                        a = 0;
                        k = c + 32;
                        d = basisPointer;
                        f = 0.0f;
                        while (a != 3) {
                            storeF32(memory, c, i);
                            storeF32(memory, c + 4, g);
                            storeF32(memory, c + 8, o);
                            m = -loadF32(memory, k)
                                    / loadF32(memory, c | ((a & 3) << 2));
                            f = f + loadF32(memory, d + 4) * m;
                            h = h + loadF32(memory, d) * m;
                            k += 4;
                            d += 8;
                            a++;
                        }

                        float time = loadF32(memory, 6824);
                        m = j / -i;
                        m = m - p / g;
                        m = m - e / o;
                        f = f / m;
                        o = sin(time + time + f * TWO_PI * PHASE_SCALE);
                        h = o * SHADE_SCALE + h / m;
                        m = sin(time * TIME_SCALE + h * TWO_PI * PHASE_SCALE);
                        float displacedH = h;
                        h = time * 0.5f;
                        o = sin((displacedH * 2.5f + h) * TWO_PI);
                        f = sin((h + (f + m * SHADE_SCALE) * 2.5f) * TWO_PI);
                        h = fractionalPart(za + n * ATTRIBUTE_SCALE);

                        if ((fa & 0xffffffffL) <= 159L && (l & 0xffffffffL) <= 159L) {
                            a = (l << 1) & 6;
                            f = (o + f) * 0.25f + 0.5f;
                            f = f < 1.0f ? f : 1.0f;
                            f = maximumF32(f, 0.0f);
                            h = f * 3.0f + h;
                            k = truncateUnsignedOrZero(h);
                            d = (l >>> 2)
                                    + oa
                                    + ((l & 3) != 0 ? l >>> 31 : 0)
                                    + 160;
                            int packed = memory[d] & 0xff;
                            memory[d] = (byte) ((packed & ~(3 << a)) | (k << a));
                        }
                        l++;
                    }
                    fa++;
                }
                ea++;
                fa = ga;
            }
        } finally {
            module.globals[0] = c + 48;
        }
    }

    private static float sin(float value) {
        return Float.intBitsToFloat(
                WasmInterpreter.sinF32BitsForFastPath(Float.floatToIntBits(value)));
    }

    private static int roundToI32(float value) {
        float rounded = value + 0.5f;
        if (!(Math.abs(rounded) < 2147483648.0f)) {
            return Integer.MIN_VALUE;
        }
        return (int) rounded;
    }

    private static float fractionalPart(float value) {
        int bits = Float.floatToIntBits(value);
        int magnitude = bits & 0x7fffffff;
        if (magnitude == 0x7f800000) {
            return NAN;
        }
        int sign = bits & 0x80000000;
        int exponent = (bits >>> 23) & 0xff;
        int unbiased = exponent - 127;
        if (exponent >= 150) {
            float selected = unbiased == 128
                    ? value
                    : Float.intBitsToFloat(sign);
            return (bits & 0x007fffff) != 0 ? selected : NAN;
        }
        if (exponent < 127) {
            return value;
        }
        int shift = unbiased & 31;
        if (((bits << shift) & 0x007fffff) == 0) {
            return Float.intBitsToFloat(sign);
        }
        int wholeBits = (-8388608 >> shift) & bits;
        return value - Float.intBitsToFloat(wholeBits);
    }

    private static float maximumF32(float left, float right) {
        if (left != left || right != right) {
            return Float.intBitsToFloat(0x7fc00000);
        }
        if (left == 0.0f && right == 0.0f) {
            return Float.intBitsToFloat(
                    Float.floatToIntBits(left) & Float.floatToIntBits(right));
        }
        return left > right ? left : right;
    }

    private static int truncateUnsignedOrZero(float value) {
        if (!(value >= 0.0f && value < 4294967296.0f)) {
            return 0;
        }
        if (value < 2147483648.0f) {
            return (int) value;
        }
        return ((int) (value - 2147483648.0f)) ^ Integer.MIN_VALUE;
    }

    private static int loadU16(byte[] memory, int address) {
        return (memory[address] & 0xff) | ((memory[address + 1] & 0xff) << 8);
    }

    private static void checkRange(byte[] memory, int address, int length) {
        if (address < 0 || length < 0 || address > memory.length - length) {
            throw new WasmTrap("Plasma fast-path memory access is out of bounds");
        }
    }

    private static void storeU16(byte[] memory, int address, int value) {
        memory[address] = (byte) value;
        memory[address + 1] = (byte) (value >>> 8);
    }

    private static float loadF32(byte[] memory, int address) {
        int bits = (memory[address] & 0xff)
                | ((memory[address + 1] & 0xff) << 8)
                | ((memory[address + 2] & 0xff) << 16)
                | (memory[address + 3] << 24);
        return Float.intBitsToFloat(bits);
    }

    private static void storeF32(byte[] memory, int address, float value) {
        int bits = Float.floatToIntBits(value);
        memory[address] = (byte) bits;
        memory[address + 1] = (byte) (bits >>> 8);
        memory[address + 2] = (byte) (bits >>> 16);
        memory[address + 3] = (byte) (bits >>> 24);
    }
}
