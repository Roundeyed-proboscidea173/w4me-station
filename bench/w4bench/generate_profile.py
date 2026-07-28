#!/usr/bin/env python3
"""Generate the deterministic W4Bench V1 contract into a build directory.

This is deliberately dependency-free. The frozen profile is the only editable
benchmark input; Java metadata, the opcode catalog, and WAT are build outputs.
"""

from __future__ import print_function

import argparse
import json
import os
import struct
import sys
import zlib


ROOT = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PROFILE = os.path.join(ROOT, "profile_v1.json")
DEFAULT_OUTPUT = os.path.normpath(os.path.join(
    ROOT, "..", "..", "build", "reports", "bench", "w4bench", "generated"))

MAGIC = 0x57423431
CONTRACT_VERSION = 1
RESULT_OFFSET = 8192
RESULT_LENGTH = 32
STATUS_PASS = 0
STATUS_PREPARED = 1
STATUS_ERROR = 2
MASK32 = 0xffffffff
MASK64 = 0xffffffffffffffff
VALIDATION_TEST_ID = 0x8000
VALIDATION_F32_UNSIGNED_I64 = 0x8000008000000001
VALIDATION_F32_EXPECTED_BITS = 0x5f000001
VALIDATION_F64_UNSIGNED_I64 = 0xc000000000000401
VALIDATION_F64_EXPECTED_BITS = 0x43e8000000000001
VALIDATION_COVER_VALUES = (
    0x0123456789abcdef,
    0x1020304050607080,
    0x1122334455667788,
    0x2233445566778899,
    0x33445566778899aa,
    0x445566778899aabb,
    0x66778899aabbccdd,
)

# This is intentionally an explicit source-WASM space, rather than W4IR
# internals.  178 core/sign-extension opcodes plus 12 FC-prefixed extensions
# are accepted by the current interpreter.  `unreachable` is the one expected
# trap; every other entry is exercised by validate_all's eight sub-exports.
SUPPORTED_SOURCE_OPCODES = (
    [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x0b]
    + list(range(0x0c, 0x12))
    + list(range(0x1a, 0x1d))
    + list(range(0x20, 0x25))
    + list(range(0x28, 0xc5))
    + list(range(0xfc00, 0xfc0c))
)

# Source opcodes reached between entering a run_* export and returning from it,
# including its transitive kernel/helper calls.  This is metadata about the
# timed workload shape, not the all-opcode validation sweep below.
TIMED_SOURCE_OPCODES = frozenset((
    0x02, 0x03, 0x04, 0x05, 0x0b, 0x0c, 0x0d, 0x10, 0x11,
    0x20, 0x21, 0x24,
    0x28, 0x2d, 0x2f, 0x36, 0x3a, 0x3b,
    0x41, 0x42, 0x43, 0x44, 0x4f,
    0x6a, 0x6b, 0x6c, 0x71, 0x73, 0x77, 0x78,
    0x7c, 0x85, 0x89,
    0x92, 0x94, 0xa0, 0xa2,
    0xad, 0xb3, 0xb8, 0xbc, 0xbd, 0xbe, 0xbf,
))


def canonical_json(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def parse_u32(value, field):
    if isinstance(value, int):
        number = value
    elif isinstance(value, str) and value.startswith("0x"):
        number = int(value, 16)
    else:
        raise ValueError("%s must be an integer or 0x-prefixed integer" % field)
    if number < 0 or number > MASK32:
        raise ValueError("%s outside u32 range" % field)
    return number


def load_profile(path):
    with open(path, "r") as source:
        profile = json.load(source)
    required = {
        "format", "state", "contract_version", "warmup_runs", "measured_runs",
        "min_timed_ms", "instruction_limit",
        "result_offset", "result_length", "tests", "opcode_validation"
    }
    missing = required.difference(profile)
    if missing:
        raise ValueError("profile missing fields: %s" % ", ".join(sorted(missing)))
    if profile["format"] != "w4bench-profile-v1":
        raise ValueError("unsupported profile format")
    if profile["state"] not in ("PRECALIBRATION", "FROZEN"):
        raise ValueError("state must be PRECALIBRATION or FROZEN")
    if profile["contract_version"] != CONTRACT_VERSION:
        raise ValueError("unexpected contract version")
    if profile["warmup_runs"] != 1 or profile["measured_runs"] != 9:
        raise ValueError("W4Bench V1 requires exactly one warmup and nine measured runs")
    if not isinstance(profile["min_timed_ms"], int) or profile["min_timed_ms"] < 1:
        raise ValueError("min_timed_ms must be a positive integer")
    if (not isinstance(profile["instruction_limit"], int)
            or profile["instruction_limit"] < 1
            or profile["instruction_limit"] > 0x7fffffffffffffff):
        raise ValueError("instruction_limit must fit a positive signed i64")
    if profile["result_offset"] != RESULT_OFFSET or profile["result_length"] != RESULT_LENGTH:
        raise ValueError("W4Bench V1 result block layout is fixed")
    tests = profile["tests"]
    if not isinstance(tests, list) or len(tests) != 7:
        raise ValueError("profile must contain exactly seven ordered timed tests")
    expected_names = (
        "i32-control", "direct-calls-locals", "call-indirect-table",
        "memory-widths", "i64", "f32", "f64"
    )
    for index, test in enumerate(tests):
        if set(test) != {"id", "name", "seed", "work_units", "prepare_export", "run_export"}:
            raise ValueError("test %d has an invalid field set" % (index + 1))
        if test["id"] != index + 1 or test["name"] != expected_names[index]:
            raise ValueError("tests must retain the V1 fixed ordered identifiers")
        test["seed"] = parse_u32(test["seed"], "tests[%d].seed" % index)
        if (test["prepare_export"] != "prepare_" + test["name"].replace("-", "_")
                or test["run_export"] != "run_" + test["name"].replace("-", "_")):
            raise ValueError("tests[%d] must use canonical no-argument exports" % index)
        if not isinstance(test["work_units"], int) or not 1024 <= test["work_units"] <= 1000000:
            raise ValueError("tests[%d].work_units outside safe V1 range" % index)
    validation = profile["opcode_validation"]
    if validation.get("mode") != "CATALOG_SWEEP":
        raise ValueError("opcode validation must use CATALOG_SWEEP")
    if validation.get("required_coverage") != "ALL_SUPPORTED_SOURCE_OPCODES":
        raise ValueError("opcode validation must require all supported source opcodes")
    if validation.get("catalog") != "opcode_catalog_v1.json":
        raise ValueError("unexpected opcode catalog name")
    if validation.get("expected_trap_exports") != ["trap_unreachable"]:
        raise ValueError("V1 must expose trap_unreachable")
    if len(SUPPORTED_SOURCE_OPCODES) != 190:
        raise ValueError("internal source opcode catalog is incomplete")
    return profile


def validate_catalog_data(catalog):
    if catalog.get("format") != "w4bench-opcode-catalog-v1":
        raise ValueError("invalid opcode catalog format")
    entries = catalog.get("entries")
    if not isinstance(entries, list) or not entries:
        raise ValueError("opcode catalog has no entries")
    seen = set()
    valid_modes = set(("timed", "validate", "trap", "pending"))
    for entry in entries:
        opcode = entry.get("opcode")
        if not isinstance(opcode, str) or not opcode.startswith("0x"):
            raise ValueError("catalog opcode must be an 0x string")
        if opcode in seen:
            raise ValueError("duplicate catalog opcode %s" % opcode)
        seen.add(opcode)
        if entry.get("mode") not in valid_modes:
            raise ValueError("invalid catalog mode for %s" % opcode)
        if not entry.get("name"):
            raise ValueError("catalog name missing for %s" % opcode)
        if not entry.get("wat_token"):
            raise ValueError("catalog WAT token missing for %s" % opcode)
        value = int(opcode, 16)
        if entry.get("name") != opcode_token(value):
            raise ValueError("catalog name does not match opcode %s" % opcode)
        expected_mode = catalog_mode(value)
        if entry.get("mode") != expected_mode:
            raise ValueError(
                "catalog mode for %s must be %s" % (opcode, expected_mode))
    required = set("0x%04x" % value if value >= 0xfc00 else "0x%02x" % value
                   for value in SUPPORTED_SOURCE_OPCODES)
    if seen != required:
        missing = required.difference(seen)
        extra = seen.difference(required)
        raise ValueError("catalog does not exactly match supported source opcodes: "
                         "missing=%s extra=%s" % (sorted(missing), sorted(extra)))
    if catalog.get("coverage_status") != "COMPLETE":
        raise ValueError("catalog must declare COMPLETE source opcode coverage")
    if any(entry.get("mode") == "pending" for entry in entries):
        raise ValueError("COMPLETE catalog cannot contain pending entries")
    return catalog


def validate_catalog(path):
    with open(path, "r") as source:
        return validate_catalog_data(json.load(source))


def catalog_opcode(value):
    if value >= 0xfc00:
        return "0x%04x" % value
    return "0x%02x" % value


def catalog_mode(value):
    if value == 0x00:
        return "trap"
    if value in TIMED_SOURCE_OPCODES:
        return "timed"
    return "validate"


def opcode_token(value):
    direct = {
        0x00: "unreachable", 0x01: "nop", 0x02: "block", 0x03: "loop",
        0x04: "if", 0x05: "else", 0x0b: "end", 0x0c: "br", 0x0d: "br_if",
        0x0e: "br_table", 0x0f: "return", 0x10: "call", 0x11: "call_indirect",
        0x1a: "drop", 0x1b: "select", 0x1c: "select (result i32)",
        0x20: "local.get", 0x21: "local.set", 0x22: "local.tee",
        0x23: "global.get", 0x24: "global.set",
        0x3f: "memory.size", 0x40: "memory.grow",
        0x41: "i32.const", 0x42: "i64.const", 0x43: "f32.const", 0x44: "f64.const",
        0xc0: "i32.extend8_s", 0xc1: "i32.extend16_s", 0xc2: "i64.extend8_s",
        0xc3: "i64.extend16_s", 0xc4: "i64.extend32_s",
        0xfc00: "i32.trunc_sat_f32_s", 0xfc01: "i32.trunc_sat_f32_u",
        0xfc02: "i32.trunc_sat_f64_s", 0xfc03: "i32.trunc_sat_f64_u",
        0xfc04: "i64.trunc_sat_f32_s", 0xfc05: "i64.trunc_sat_f32_u",
        0xfc06: "i64.trunc_sat_f64_s", 0xfc07: "i64.trunc_sat_f64_u",
        0xfc08: "memory.init", 0xfc09: "data.drop", 0xfc0a: "memory.copy",
        0xfc0b: "memory.fill",
    }
    if value in direct:
        return direct[value]
    memory = {
        0x28: "i32.load", 0x29: "i64.load", 0x2a: "f32.load", 0x2b: "f64.load",
        0x2c: "i32.load8_s", 0x2d: "i32.load8_u", 0x2e: "i32.load16_s",
        0x2f: "i32.load16_u", 0x30: "i64.load8_s", 0x31: "i64.load8_u",
        0x32: "i64.load16_s", 0x33: "i64.load16_u", 0x34: "i64.load32_s",
        0x35: "i64.load32_u", 0x36: "i32.store", 0x37: "i64.store",
        0x38: "f32.store", 0x39: "f64.store", 0x3a: "i32.store8",
        0x3b: "i32.store16", 0x3c: "i64.store8", 0x3d: "i64.store16",
        0x3e: "i64.store32",
    }
    if value in memory:
        return memory[value]
    names = {
        0x45: "i32.eqz", 0x46: "i32.eq", 0x47: "i32.ne", 0x48: "i32.lt_s",
        0x49: "i32.lt_u", 0x4a: "i32.gt_s", 0x4b: "i32.gt_u", 0x4c: "i32.le_s",
        0x4d: "i32.le_u", 0x4e: "i32.ge_s", 0x4f: "i32.ge_u",
        0x50: "i64.eqz", 0x51: "i64.eq", 0x52: "i64.ne", 0x53: "i64.lt_s",
        0x54: "i64.lt_u", 0x55: "i64.gt_s", 0x56: "i64.gt_u", 0x57: "i64.le_s",
        0x58: "i64.le_u", 0x59: "i64.ge_s", 0x5a: "i64.ge_u",
        0x5b: "f32.eq", 0x5c: "f32.ne", 0x5d: "f32.lt", 0x5e: "f32.gt",
        0x5f: "f32.le", 0x60: "f32.ge", 0x61: "f64.eq", 0x62: "f64.ne",
        0x63: "f64.lt", 0x64: "f64.gt", 0x65: "f64.le", 0x66: "f64.ge",
        0x67: "i32.clz", 0x68: "i32.ctz", 0x69: "i32.popcnt",
        0x6a: "i32.add", 0x6b: "i32.sub", 0x6c: "i32.mul", 0x6d: "i32.div_s",
        0x6e: "i32.div_u", 0x6f: "i32.rem_s", 0x70: "i32.rem_u", 0x71: "i32.and",
        0x72: "i32.or", 0x73: "i32.xor", 0x74: "i32.shl", 0x75: "i32.shr_s",
        0x76: "i32.shr_u", 0x77: "i32.rotl", 0x78: "i32.rotr",
        0x79: "i64.clz", 0x7a: "i64.ctz", 0x7b: "i64.popcnt",
        0x7c: "i64.add", 0x7d: "i64.sub", 0x7e: "i64.mul", 0x7f: "i64.div_s",
        0x80: "i64.div_u", 0x81: "i64.rem_s", 0x82: "i64.rem_u", 0x83: "i64.and",
        0x84: "i64.or", 0x85: "i64.xor", 0x86: "i64.shl", 0x87: "i64.shr_s",
        0x88: "i64.shr_u", 0x89: "i64.rotl", 0x8a: "i64.rotr",
        0x8b: "f32.abs", 0x8c: "f32.neg", 0x8d: "f32.ceil", 0x8e: "f32.floor",
        0x8f: "f32.trunc", 0x90: "f32.nearest", 0x91: "f32.sqrt", 0x92: "f32.add",
        0x93: "f32.sub", 0x94: "f32.mul", 0x95: "f32.div", 0x96: "f32.min",
        0x97: "f32.max", 0x98: "f32.copysign", 0x99: "f64.abs", 0x9a: "f64.neg",
        0x9b: "f64.ceil", 0x9c: "f64.floor", 0x9d: "f64.trunc", 0x9e: "f64.nearest",
        0x9f: "f64.sqrt", 0xa0: "f64.add", 0xa1: "f64.sub", 0xa2: "f64.mul",
        0xa3: "f64.div", 0xa4: "f64.min", 0xa5: "f64.max", 0xa6: "f64.copysign",
        0xa7: "i32.wrap_i64", 0xa8: "i32.trunc_f32_s", 0xa9: "i32.trunc_f32_u",
        0xaa: "i32.trunc_f64_s", 0xab: "i32.trunc_f64_u", 0xac: "i64.extend_i32_s",
        0xad: "i64.extend_i32_u", 0xae: "i64.trunc_f32_s", 0xaf: "i64.trunc_f32_u",
        0xb0: "i64.trunc_f64_s", 0xb1: "i64.trunc_f64_u", 0xb2: "f32.convert_i32_s",
        0xb3: "f32.convert_i32_u", 0xb4: "f32.convert_i64_s", 0xb5: "f32.convert_i64_u",
        0xb6: "f32.demote_f64", 0xb7: "f64.convert_i32_s", 0xb8: "f64.convert_i32_u",
        0xb9: "f64.convert_i64_s", 0xba: "f64.convert_i64_u", 0xbb: "f64.promote_f32",
        0xbc: "i32.reinterpret_f32", 0xbd: "i64.reinterpret_f64", 0xbe: "f32.reinterpret_i32",
        0xbf: "f64.reinterpret_i64",
    }
    return names[value]


def render_catalog():
    entries = []
    for value in SUPPORTED_SOURCE_OPCODES:
        token = opcode_token(value)
        entry = {
            "opcode": catalog_opcode(value),
            "name": token,
            "mode": catalog_mode(value),
            "wat_token": token,
        }
        if value == 0x00:
            entry["export"] = "trap_unreachable"
        entries.append(entry)
    return json.dumps({
        "format": "w4bench-opcode-catalog-v1",
        "scope": "W4ME source-WASM opcodes",
        "coverage_status": "COMPLETE",
        "contract": ("All 190 supported source-WASM opcodes are individually "
                     "listed. validate_all executes the 189 non-trapping opcodes; "
                     "trap_unreachable is an expected trap."),
        "entries": entries,
    }, indent=2, sort_keys=True) + "\n"


def u32(value):
    return value & MASK32


def u64(value):
    return value & MASK64


def rotl32(value, count):
    count &= 31
    return u32((value << count) | (value >> ((32 - count) & 31)))


def rotr32(value, count):
    count &= 31
    return u32((value >> count) | (value << ((32 - count) & 31)))


def rotl64(value, count):
    count &= 63
    return u64((value << count) | (value >> ((64 - count) & 63)))


def f32(value):
    return struct.unpack("<f", struct.pack("<f", value))[0]


def f32_bits(value):
    return struct.unpack("<I", struct.pack("<f", value))[0]


def f64_bits(value):
    return struct.unpack("<Q", struct.pack("<d", value))[0]


def validation_payload():
    value = (
        (VALIDATION_F32_EXPECTED_BITS << 32)
        ^ VALIDATION_F64_EXPECTED_BITS
    )
    for cover_value in VALIDATION_COVER_VALUES:
        value ^= cover_value
    return value


def payload_i32_control(test):
    x = test["seed"]
    for index in range(test["work_units"]):
        x = rotl32(u32(x + index), 13) ^ 0x9e3779b9
        x = u32(x + 7) if (x & 1) else u32(x - 3)
    return x


def direct_step(x, index):
    return rotr32(u32((x ^ index) * 0x7feb352d), 16)


def payload_direct(test):
    x = test["seed"]
    for index in range(test["work_units"]):
        x = direct_step(x, index)
    return x


def indirect_a(x, index):
    return rotl32(u32(x + index * 3), 5) ^ 0x85ebca6b


def indirect_b(x, index):
    return rotr32(u32(x ^ (index * 0x27d4eb2d)), 7) + 0x165667b1 & MASK32


def payload_indirect(test):
    x = test["seed"]
    for index in range(test["work_units"]):
        x = indirect_a(x, index) if (index & 1) == 0 else indirect_b(x, index)
    return x


def payload_memory(test):
    x = test["seed"]
    words = [0] * 64
    for index in range(test["work_units"]):
        slot = index & 63
        words[slot] = x
        low8 = x & 0xff
        low16 = x & 0xffff
        x = u32(words[slot] ^ low8 ^ low16 ^ index)
        x = rotl32(x, 3)
    return x


def payload_i64(test):
    x = u64((test["seed"] << 32) | (test["seed"] ^ 0xa5a5a5a5))
    for index in range(test["work_units"]):
        x = rotl64(u64(x + index), 17) ^ 0x9e3779b97f4a7c15
    return x


def payload_f32(test):
    x = struct.unpack("<f", struct.pack("<I", test["seed"]))[0]
    for index in range(test["work_units"]):
        x = f32(f32(x * f32(1.0001220703125)) + f32(f32(float(index)) * f32(0.000001)))
    return f32_bits(x)


def payload_f64(test):
    bits = (0x3ff0000000000000 | test["seed"])
    x = struct.unpack("<d", struct.pack("<Q", bits))[0]
    for index in range(test["work_units"]):
        x = x * 1.0000001 + float(index) * 0.000000001
    return f64_bits(x)


PAYLOADS = (
    payload_i32_control, payload_direct, payload_indirect, payload_memory,
    payload_i64, payload_f32, payload_f64
)


def payload_for_test(test):
    return PAYLOADS[test["id"] - 1](test)


def result_block(contract_crc, test, status=STATUS_PASS, payload=None):
    if payload is None:
        payload = payload_for_test(test)
    return struct.pack(
        "<IIIIIIII",
        MAGIC, CONTRACT_VERSION, contract_crc, test["id"], test["work_units"],
        status, payload & MASK32, (payload >> 32) & MASK32,
    )


def validation_result_crc(contract_identity):
    validation_test = {"id": VALIDATION_TEST_ID, "work_units": 0}
    return crc32(
        result_block(
            contract_identity,
            validation_test,
            payload=validation_payload()))


def crc32(data):
    return zlib.crc32(data) & MASK32


def contract_crc(profile):
    return crc32(canonical_json(profile).encode("utf-8"))


def frozen_profile_crc(profile, contract_identity):
    expected = []
    for test in profile["tests"]:
        expected.append(crc32(result_block(contract_identity, test)))
    return crc32(canonical_json({"profile": profile, "expected_crc32": expected}).encode("utf-8"))


def java_int_array(values):
    return ", ".join("0x%08x" % (value & MASK32) for value in values)


def java_string_array(values):
    return ", ".join('"%s"' % value for value in values)


def render_java(profile, contract_identity, profile_identity):
    tests = profile["tests"]
    expected = [crc32(result_block(contract_identity, test)) for test in tests]
    return """// Generated by bench/w4bench/generate_profile.py; do not edit.
package w4me;

/** Build-time contract consumed by W4BenchRunner. */
public final class W4BenchProfile {
    public static final String PROFILE_ID = "w4bench-v1";
    public static final String PROFILE_STATE = "%s";
    public static final int PROFILE_CRC32 = 0x%08x;
    public static final int CONTRACT_CRC32 = 0x%08x;
    public static final int WARMUPS = %d;
    public static final int REPETITIONS = %d;
    public static final int MIN_TIMED_MS = %d;
    public static final int RESULT_OFFSET = %d;
    public static final long INSTRUCTION_LIMIT = %dL;
    public static final int VALIDATION_TEST_ID = 0x%08x;
    public static final long VALIDATION_PAYLOAD = 0x%016xL;
    public static final int VALIDATION_EXPECTED_CRC32 = 0x%08x;
    public static final int[] TEST_IDS = { %s };
    public static final String[] TEST_NAMES = { %s };
    public static final String[] PREPARE_EXPORTS = { %s };
    public static final String[] RUN_EXPORTS = { %s };
    public static final int[] WORKLOAD_UNITS = { %s };
    public static final int[] RESULT_LENGTHS = { %s };
    public static final int[] EXPECTED_CRC32 = { %s };

    private W4BenchProfile() {
    }
}
""" % (
        profile["state"], profile_identity, contract_identity,
        profile["warmup_runs"], profile["measured_runs"],
        profile["min_timed_ms"], profile["result_offset"], profile["instruction_limit"],
        VALIDATION_TEST_ID, validation_payload(), validation_result_crc(contract_identity),
        java_int_array([test["id"] for test in tests]),
        java_string_array([test["name"] for test in tests]),
        java_string_array([test["prepare_export"] for test in tests]),
        java_string_array([test["run_export"] for test in tests]),
        java_int_array([test["work_units"] for test in tests]),
        java_int_array([profile["result_length"] for test in tests]),
        java_int_array(expected),
    )


def wat_dispatch(tests, function_prefix, result_type):
    lines = []
    for test in tests:
        lines.extend((
            "    global.get $active",
            "    i32.const %d" % test["id"],
            "    i32.eq",
            "    if (result %s)" % result_type,
            "      call $%s_%d" % (function_prefix, test["id"]),
            "    else",
        ))
    lines.append("      %s.const 0" % ("i64" if result_type == "i64" else "i32"))
    for unused in tests:
        lines.append("    end")
    return "\n".join(lines)


def wat_explicit_exports(tests):
    lines = []
    for test in tests:
        prepare = test["prepare_export"]
        run = test["run_export"]
        lines.extend((
            "  (func (export \"%s\")" % prepare,
            "    i32.const %d" % test["id"],
            "    global.set $active",
            "    i32.const %d" % test["id"],
            "    global.set $result_test",
            "    i32.const %d" % test["work_units"],
            "    global.set $result_units",
            "    i32.const 1",
            "    global.set $result_status",
        ))
        if test["id"] == 4:
            lines.append("    call $prepare_memory")
        lines.append("  )")
        lines.extend((
            "  (func (export \"%s\")" % run,
            "    call $kernel_%d" % test["id"],
            "    global.set $last_payload",
            "    i32.const 0",
            "    global.set $result_status",
            "  )",
        ))
    return "\n".join(lines)


def coverage_unary(value_type, opcode, value):
    return "    %s.const %s\n    nop\n    %s\n    drop" % (value_type, value, opcode)


def coverage_binary(value_type, opcode, left, right):
    return ("    %s.const %s\n    nop\n    %s.const %s\n    nop\n"
            "    %s\n    drop") % (value_type, left, value_type, right, opcode)


def render_coverage_wat():
    """Return untimed, fusion-separated probes for every successful opcode."""
    i32_compare = ["i32.eq", "i32.ne", "i32.lt_s", "i32.lt_u", "i32.gt_s",
                   "i32.gt_u", "i32.le_s", "i32.le_u", "i32.ge_s", "i32.ge_u"]
    i32_unary = ["i32.clz", "i32.ctz", "i32.popcnt"]
    i32_binary = ["i32.add", "i32.sub", "i32.mul", "i32.div_s", "i32.div_u",
                  "i32.rem_s", "i32.rem_u", "i32.and", "i32.or", "i32.xor",
                  "i32.shl", "i32.shr_s", "i32.shr_u", "i32.rotl", "i32.rotr"]
    i64_compare = ["i64.eq", "i64.ne", "i64.lt_s", "i64.lt_u", "i64.gt_s",
                   "i64.gt_u", "i64.le_s", "i64.le_u", "i64.ge_s", "i64.ge_u"]
    i64_unary = ["i64.clz", "i64.ctz", "i64.popcnt"]
    i64_binary = ["i64.add", "i64.sub", "i64.mul", "i64.div_s", "i64.div_u",
                  "i64.rem_s", "i64.rem_u", "i64.and", "i64.or", "i64.xor",
                  "i64.shl", "i64.shr_s", "i64.shr_u", "i64.rotl", "i64.rotr"]
    f32_compare = ["f32.eq", "f32.ne", "f32.lt", "f32.gt", "f32.le", "f32.ge"]
    f64_compare = ["f64.eq", "f64.ne", "f64.lt", "f64.gt", "f64.le", "f64.ge"]
    f32_unary = ["f32.abs", "f32.neg", "f32.ceil", "f32.floor", "f32.trunc",
                 "f32.nearest", "f32.sqrt"]
    f64_unary = ["f64.abs", "f64.neg", "f64.ceil", "f64.floor", "f64.trunc",
                 "f64.nearest", "f64.sqrt"]
    f32_binary = ["f32.add", "f32.sub", "f32.mul", "f32.div", "f32.min", "f32.max", "f32.copysign"]
    f64_binary = ["f64.add", "f64.sub", "f64.mul", "f64.div", "f64.min", "f64.max", "f64.copysign"]
    i32_lines = ["  (func $cover_i32 (result i64)",
                 coverage_unary("i32", "i32.eqz", "7")]
    i32_lines.extend(coverage_binary("i32", opcode, "17", "3") for opcode in i32_compare)
    i32_lines.extend(coverage_unary("i32", opcode, "17") for opcode in i32_unary)
    i32_lines.extend(coverage_binary("i32", opcode, "17", "3") for opcode in i32_binary)
    i32_lines.extend(("    i64.const 0x1122334455667788", "  )"))
    i64_lines = ["  (func $cover_i64 (result i64)",
                 coverage_unary("i64", "i64.eqz", "7")]
    i64_lines.extend(coverage_binary("i64", opcode, "17", "3") for opcode in i64_compare)
    i64_lines.extend(coverage_unary("i64", opcode, "17") for opcode in i64_unary)
    i64_lines.extend(coverage_binary("i64", opcode, "17", "3") for opcode in i64_binary)
    i64_lines.extend(("    i64.const 0x2233445566778899", "  )"))
    f32_lines = ["  (func $cover_f32 (result i64)"]
    f32_lines.extend(coverage_binary("f32", opcode, "1.25", "2.5") for opcode in f32_compare)
    f32_lines.extend(coverage_unary("f32", opcode, "1.25") for opcode in f32_unary)
    f32_lines.extend(coverage_binary("f32", opcode, "1.25", "2.5") for opcode in f32_binary)
    f32_lines.extend(("    i64.const 0x33445566778899aa", "  )"))
    f64_lines = ["  (func $cover_f64 (result i64)"]
    f64_lines.extend(coverage_binary("f64", opcode, "1.25", "2.5") for opcode in f64_compare)
    f64_lines.extend(coverage_unary("f64", opcode, "1.25") for opcode in f64_unary)
    f64_lines.extend(coverage_binary("f64", opcode, "1.25", "2.5") for opcode in f64_binary)
    f64_lines.extend(("    i64.const 0x445566778899aabb", "  )"))
    return """
  (func $return_one (result i32)
    i32.const 1
    nop
    return
    i32.const 0)
  (func $cover_control (result i64) (local $x i32)
    nop
    i32.const 7
    nop
    local.set $x
    nop
    local.get $x
    nop
    local.tee $x
    drop
    global.get $sweep_global
    nop
    global.set $sweep_global
    block $done
      loop $again
        local.get $x
        nop
        i32.eqz
        br_if $done
        local.get $x
        nop
        i32.const 1
        nop
        i32.sub
        local.set $x
        br $again
      end
    end
    i32.const 1
    if (result i32)
      i32.const 3
    else
      i32.const 4
    end
    drop
    block $control_zero
      i32.const 0
      br_table $control_zero $control_zero
    end
    call $return_one
    drop
    i32.const 4
    i32.const 9
    i32.const 1
    select
    drop
    i32.const 4
    i32.const 9
    i32.const 0
    select (result i32)
    drop
    i32.const 17
    i32.const 3
    i32.const 2
    call_indirect (type $step)
    drop
    i64.const 0x0123456789abcdef)

  (func $cover_memory (result i64) (local $x i64)
    i32.const 12288
    i32.const 0x11223344
    i32.store
    i32.const 12288
    nop
    i32.load
    drop
    i32.const 12296
    i64.const 0x1122334455667788
    i64.store
    i32.const 12296
    nop
    i64.load
    drop
    i32.const 12304
    f32.const 1.25
    f32.store
    i32.const 12304
    nop
    f32.load
    drop
    i32.const 12312
    f64.const 1.25
    f64.store
    i32.const 12312
    nop
    f64.load
    drop
    i32.const 12320
    i32.const 0xff80
    i32.store8
    i32.const 12320
    nop
    i32.load8_s
    drop
    i32.const 12320
    nop
    i32.load8_u
    drop
    i32.const 12322
    i32.const 0xff80
    i32.store16
    i32.const 12322
    nop
    i32.load16_s
    drop
    i32.const 12322
    nop
    i32.load16_u
    drop
    i32.const 12328
    i64.const 0xffffffffffffff80
    i64.store8
    i32.const 12328
    nop
    i64.load8_s
    drop
    i32.const 12328
    nop
    i64.load8_u
    drop
    i32.const 12330
    i64.const 0xffffffffffff8000
    i64.store16
    i32.const 12330
    nop
    i64.load16_s
    drop
    i32.const 12330
    nop
    i64.load16_u
    drop
    i32.const 12336
    i64.const 0xffffffff80000000
    i64.store32
    i32.const 12336
    nop
    i64.load32_s
    drop
    i32.const 12336
    nop
    i64.load32_u
    drop
    memory.size
    drop
    i32.const 0
    memory.grow
    drop
    i64.const 0x1020304050607080)

%s

%s

%s

%s

  (func $cover_convert (result i64)
    i64.const 7
    nop
    i32.wrap_i64
    drop
    f32.const 7
    nop
    i32.trunc_f32_s
    drop
    f32.const 7
    nop
    i32.trunc_f32_u
    drop
    f64.const 7
    nop
    i32.trunc_f64_s
    drop
    f64.const 7
    nop
    i32.trunc_f64_u
    drop
    i32.const -7
    nop
    i64.extend_i32_s
    drop
    i32.const 7
    nop
    i64.extend_i32_u
    drop
    f32.const 7
    nop
    i64.trunc_f32_s
    drop
    f32.const 7
    nop
    i64.trunc_f32_u
    drop
    f64.const 7
    nop
    i64.trunc_f64_s
    drop
    f64.const 7
    nop
    i64.trunc_f64_u
    drop
    i32.const -7
    nop
    f32.convert_i32_s
    drop
    i32.const 7
    nop
    f32.convert_i32_u
    drop
    i64.const -7
    nop
    f32.convert_i64_s
    drop
    i64.const 7
    nop
    f32.convert_i64_u
    drop
    f64.const 7
    nop
    f32.demote_f64
    drop
    i32.const -7
    nop
    f64.convert_i32_s
    drop
    i32.const 7
    nop
    f64.convert_i32_u
    drop
    i64.const -7
    nop
    f64.convert_i64_s
    drop
    i64.const 7
    nop
    f64.convert_i64_u
    drop
    f32.const 7
    nop
    f64.promote_f32
    drop
    f32.const 1.25
    nop
    i32.reinterpret_f32
    drop
    f64.const 1.25
    nop
    i64.reinterpret_f64
    drop
    i32.const 0x3f800000
    nop
    f32.reinterpret_i32
    drop
    i64.const 0x3ff0000000000000
    nop
    f64.reinterpret_i64
    drop
    i32.const 0x80
    nop
    i32.extend8_s
    drop
    i32.const 0x8000
    nop
    i32.extend16_s
    drop
    i64.const 0x80
    nop
    i64.extend8_s
    drop
    i64.const 0x8000
    nop
    i64.extend16_s
    drop
    i64.const 0x80000000
    nop
    i64.extend32_s
    drop
    f32.const nan
    nop
    i32.trunc_sat_f32_s
    drop
    f32.const nan
    nop
    i32.trunc_sat_f32_u
    drop
    f64.const nan
    nop
    i32.trunc_sat_f64_s
    drop
    f64.const nan
    nop
    i32.trunc_sat_f64_u
    drop
    f32.const nan
    nop
    i64.trunc_sat_f32_s
    drop
    f32.const nan
    nop
    i64.trunc_sat_f32_u
    drop
    f64.const nan
    nop
    i64.trunc_sat_f64_s
    drop
    f64.const nan
    nop
    i64.trunc_sat_f64_u
    drop
    ;; Semantic sentinels for correctly rounded unsigned-i64 conversion.
    i64.const 0x8000008000000001
    nop
    f32.convert_i64_u
    nop
    i32.reinterpret_f32
    nop
    i64.extend_i32_u
    i64.const 32
    i64.shl
    i64.const 0xc000000000000401
    nop
    f64.convert_i64_u
    nop
    i64.reinterpret_f64
    i64.xor)

  (func $cover_bulk (result i64)
    i32.const 12400
    i32.const 0
    i32.const 7
    memory.init $sweep_data
    i32.const 12408
    i32.const 12400
    i32.const 7
    memory.copy
    i32.const 12416
    i32.const 0x5a
    i32.const 7
    memory.fill
    data.drop $sweep_data
    i64.const 0x66778899aabbccdd)

  (func (export "cover_control") call $cover_control drop)
  (func (export "cover_memory") call $cover_memory drop)
  (func (export "cover_i32") call $cover_i32 drop)
  (func (export "cover_i64") call $cover_i64 drop)
  (func (export "cover_f32") call $cover_f32 drop)
  (func (export "cover_f64") call $cover_f64 drop)
  (func (export "cover_convert") call $cover_convert drop)
  (func (export "cover_bulk") call $cover_bulk drop)
""" % ("\n".join(i32_lines), "\n".join(i64_lines), "\n".join(f32_lines), "\n".join(f64_lines))


def render_wat(profile, contract_identity):
    tests = profile["tests"]
    seed = {test["id"]: test["seed"] for test in tests}
    units = {test["id"]: test["work_units"] for test in tests}
    prepare_cases = []
    for test in tests:
        prepare_cases.extend((
            "    global.get $active",
            "    i32.const %d" % test["id"],
            "    i32.eq",
            "    if",
            "      i32.const %d" % test["id"],
            "      global.set $result_test",
            "      i32.const %d" % units[test["id"]],
            "      global.set $result_units",
            "      i32.const 1",
            "      global.set $result_status",
            "    end",
        ))
    return """;; Generated by bench/w4bench/generate_profile.py; do not edit.
;; W4Bench V1 is a test-only deterministic cartridge. Timed run() has no clock,
;; logging or CRC: call prepare(), time run(), then call report() and validate
;; the 32-byte little-endian block at offset 8192 in the host harness.
(module
  (memory (export "memory") 1)
  (table 3 funcref)
  (elem (i32.const 0) $indirect_a $indirect_b $coverage_indirect)
  (data $sweep_data "W4Bench")
  (type $step (func (param i32 i32) (result i32)))

  (global $active (mut i32) (i32.const -1))
  (global $next (mut i32) (i32.const 0))
  (global $result_test (mut i32) (i32.const 0))
  (global $result_units (mut i32) (i32.const 0))
  (global $result_status (mut i32) (i32.const 2))
  (global $last_payload (mut i64) (i64.const 0))
  (global $sweep_global (mut i32) (i32.const 0))
  (global $bulk_done (mut i32) (i32.const 0))

  (func $start
    i32.const 0
    global.set $next
    i32.const -1
    global.set $active)
  (start $start)

  (func (export "update"))
  (func (export "reset")
    call $start)

  (func $direct_step (param $x i32) (param $i i32) (result i32)
    local.get $x
    local.get $i
    i32.xor
    i32.const 0x7feb352d
    i32.mul
    i32.const 16
    i32.rotr)
  (func $indirect_a (type $step) (param $x i32) (param $i i32) (result i32)
    local.get $x
    local.get $i
    i32.const 3
    i32.mul
    i32.add
    i32.const 5
    i32.rotl
    i32.const 0x85ebca6b
    i32.xor)
  (func $indirect_b (type $step) (param $x i32) (param $i i32) (result i32)
    local.get $x
    local.get $i
    i32.const 0x27d4eb2d
    i32.mul
    i32.xor
    i32.const 7
    i32.rotr
    i32.const 0x165667b1
    i32.add)
  (func $coverage_indirect (type $step) (param $x i32) (param $i i32) (result i32)
    local.get $x
    nop
    local.get $i
    nop
    i32.add)

  (func $kernel_1 (result i64) (local $i i32) (local $x i32)
    i32.const 0x%08x
    local.set $x
    block $done
      loop $again
        local.get $i
        i32.const %d
        i32.ge_u
        br_if $done
        local.get $x
        local.get $i
        i32.add
        i32.const 13
        i32.rotl
        i32.const 0x9e3779b9
        i32.xor
        local.set $x
        local.get $x
        i32.const 1
        i32.and
        if
          local.get $x
          i32.const 7
          i32.add
          local.set $x
        else
          local.get $x
          i32.const 3
          i32.sub
          local.set $x
        end
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $again
      end
    end
    local.get $x
    i64.extend_i32_u)

  (func $kernel_2 (result i64) (local $i i32) (local $x i32)
    i32.const 0x%08x
    local.set $x
    block $done
      loop $again
        local.get $i
        i32.const %d
        i32.ge_u
        br_if $done
        local.get $x
        local.get $i
        call $direct_step
        local.set $x
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $again
      end
    end
    local.get $x
    i64.extend_i32_u)

  (func $kernel_3 (result i64) (local $i i32) (local $x i32)
    i32.const 0x%08x
    local.set $x
    block $done
      loop $again
        local.get $i
        i32.const %d
        i32.ge_u
        br_if $done
        local.get $x
        local.get $i
        local.get $i
        i32.const 1
        i32.and
        call_indirect (type $step)
        local.set $x
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $again
      end
    end
    local.get $x
    i64.extend_i32_u)

  (func $prepare_memory
    i32.const 12288
    i32.const 0
    i32.store
    i32.const 12292
    i32.const 0
    i32.store)
  (func $kernel_4 (result i64) (local $i i32) (local $x i32) (local $addr i32)
    i32.const 0x%08x
    local.set $x
    block $done
      loop $again
        local.get $i
        i32.const %d
        i32.ge_u
        br_if $done
        i32.const 12288
        local.get $i
        i32.const 63
        i32.and
        i32.const 8
        i32.mul
        i32.add
        local.set $addr
        local.get $addr
        local.get $x
        i32.store
        local.get $addr
        i32.const 4
        i32.add
        local.get $x
        i32.store8
        local.get $addr
        i32.const 5
        i32.add
        local.get $x
        i32.store16
        local.get $addr
        i32.load
        local.get $addr
        i32.const 4
        i32.add
        i32.load8_u
        i32.xor
        local.get $addr
        i32.const 5
        i32.add
        i32.load16_u
        i32.xor
        local.get $i
        i32.xor
        i32.const 3
        i32.rotl
        local.set $x
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $again
      end
    end
    local.get $x
    i64.extend_i32_u)

  (func $kernel_5 (result i64) (local $i i32) (local $x i64)
    i64.const 0x%08x%08x
    local.set $x
    block $done
      loop $again
        local.get $i
        i32.const %d
        i32.ge_u
        br_if $done
        local.get $x
        local.get $i
        i64.extend_i32_u
        i64.add
        i64.const 17
        i64.rotl
        i64.const 0x9e3779b97f4a7c15
        i64.xor
        local.set $x
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $again
      end
    end
    local.get $x)

  (func $kernel_6 (result i64) (local $i i32) (local $x f32)
    i32.const 0x%08x
    f32.reinterpret_i32
    local.set $x
    block $done
      loop $again
        local.get $i
        i32.const %d
        i32.ge_u
        br_if $done
        local.get $x
        f32.const 1.0001220703125
        f32.mul
        local.get $i
        f32.convert_i32_u
        f32.const 0.000001
        f32.mul
        f32.add
        local.set $x
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $again
      end
    end
    local.get $x
    i32.reinterpret_f32
    i64.extend_i32_u)

  (func $kernel_7 (result i64) (local $i i32) (local $x f64)
    i64.const 0x3ff00000%08x
    f64.reinterpret_i64
    local.set $x
    block $done
      loop $again
        local.get $i
        i32.const %d
        i32.ge_u
        br_if $done
        local.get $x
        f64.const 1.0000001
        f64.mul
        local.get $i
        f64.convert_i32_u
        f64.const 0.000000001
        f64.mul
        f64.add
        local.set $x
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $again
      end
    end
    local.get $x
    i64.reinterpret_f64)

%s

%s

  ;; setup is explicitly outside timed run().
  (func (export "prepare")
    global.get $next
    global.set $active
    global.get $next
    i32.const 1
    i32.add
    i32.const 7
    i32.rem_u
    global.set $next
%s
    global.get $active
    i32.const 4
    i32.eq
    if
      call $prepare_memory
    end)

  ;; This is the only interval the host times. It has no clock, output write,
  ;; CRC, logging, allocation, or preparation work.
  (func (export "run")
    global.get $active
    i32.const 0
    i32.lt_s
    if
      i32.const 2
      global.set $result_status
    else
%s
      global.set $last_payload
      i32.const 0
      global.set $result_status
    end)

  (func $write_u32 (param $offset i32) (param $value i32)
    local.get $offset
    local.get $value
    i32.store)
  (func $report (export "report")
    i32.const 8192
    i32.const 0x57423431
    call $write_u32
    i32.const 8196
    i32.const 1
    call $write_u32
    i32.const 8200
    i32.const 0x%08x
    call $write_u32
    i32.const 8204
    global.get $result_test
    call $write_u32
    i32.const 8208
    global.get $result_units
    call $write_u32
    i32.const 8212
    global.get $result_status
    call $write_u32
    i32.const 8216
    global.get $last_payload
    i32.wrap_i64
    call $write_u32
    i32.const 8220
    global.get $last_payload
    i64.const 32
    i64.shr_u
    i32.wrap_i64
    call $write_u32)

  ;; Untimed diagnostic sweep. The catalog records opcode ownership separately
  ;; from the timed score so rare instructions never skew performance numbers.
  (func $opcode_sweep (result i64) (local $x i64)
    call $cover_control
    call $cover_memory
    i64.xor
    call $cover_i32
    i64.xor
    call $cover_i64
    i64.xor
    call $cover_f32
    i64.xor
    call $cover_f64
    i64.xor
    call $cover_convert
    i64.xor
    global.get $bulk_done
    if (result i64)
      i64.const 0
    else
      call $cover_bulk
      i32.const 1
      global.set $bulk_done
    end
    i64.xor)
  (func (export "validate_all")
    i32.const 32768
    global.set $result_test
    i32.const 0
    global.set $result_units
    call $opcode_sweep
    global.set $last_payload
    i32.const 0
    global.set $result_status
    call $report)
  (func (export "trap_unreachable")
    unreachable)
)
""" % (
        seed[1], units[1], seed[2], units[2], seed[3], units[3], seed[4], units[4],
        seed[5], seed[5] ^ 0xa5a5a5a5, units[5], seed[6], units[6], seed[7], units[7],
        wat_explicit_exports(tests), render_coverage_wat(), "\n".join(prepare_cases),
        wat_dispatch(tests, "kernel", "i64"), contract_identity
    )


def write_output(path, content):
    directory = os.path.dirname(path)
    if not os.path.isdir(directory):
        os.makedirs(directory)
    with open(path, "w") as output:
        output.write(content)


def generate(profile_path=DEFAULT_PROFILE, output_dir=DEFAULT_OUTPUT):
    profile = load_profile(profile_path)
    contract_identity = contract_crc(profile)
    profile_identity = frozen_profile_crc(profile, contract_identity)
    catalog_path = os.path.join(output_dir, "opcode_catalog_v1.json")
    write_output(catalog_path, render_catalog())
    validate_catalog(catalog_path)
    write_output(
        os.path.join(output_dir, "java", "w4me", "W4BenchProfile.java"),
        render_java(profile, contract_identity, profile_identity))
    write_output(
        os.path.join(output_dir, "w4bench_v1.wat"),
        render_wat(profile, contract_identity))
    return profile, contract_identity, profile_identity


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", default=DEFAULT_PROFILE)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT)
    parser.add_argument("--require-frozen", action="store_true")
    options = parser.parse_args(argv)
    try:
        if options.require_frozen:
            candidate_profile = load_profile(options.profile)
            if candidate_profile["state"] != "FROZEN":
                raise ValueError("authoritative benchmark requires a FROZEN profile")
        profile, contract_identity, profile_identity = generate(
            options.profile, options.output_dir)
    except (IOError, ValueError, TypeError) as error:
        print("error: %s" % error, file=sys.stderr)
        return 1
    print("W4Bench V1 %s contract_crc32=%08x profile_crc32=%08x tests=%d" % (
        profile["state"], contract_identity, profile_identity, len(profile["tests"])))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
