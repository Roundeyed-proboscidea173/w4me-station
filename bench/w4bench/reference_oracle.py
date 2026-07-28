#!/usr/bin/env python3
"""Independent W4Bench V1 result oracle.

It intentionally reimplements the seven workload kernels instead of importing
the generator's calculator.  The host benchmark uses this only outside its
timed interval to check the cartridge's fixed little-endian result block.
"""

from __future__ import print_function

import argparse
import json
import os
import struct
import sys
import zlib


ROOT = os.path.dirname(os.path.abspath(__file__))
PROFILE_PATH = os.path.join(ROOT, "profile_v1.json")
MASK32 = 0xffffffff
MASK64 = 0xffffffffffffffff
MAGIC = 0x57423431
CONTRACT_VERSION = 1
VALIDATION_TEST_ID = 0x8000
VALIDATION_F32_UNSIGNED_I64 = 0x8000008000000001
VALIDATION_F64_UNSIGNED_I64 = 0xc000000000000401
VALIDATION_COVER_VALUES = (
    0x0123456789abcdef,
    0x1020304050607080,
    0x1122334455667788,
    0x2233445566778899,
    0x33445566778899aa,
    0x445566778899aabb,
    0x66778899aabbccdd,
)


def canonical_json(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def parse_seed(value):
    return int(value, 16) if isinstance(value, str) else int(value)


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


def as_f32(value):
    return struct.unpack("<f", struct.pack("<f", value))[0]


def f32_bits(value):
    return struct.unpack("<I", struct.pack("<f", value))[0]


def f64_bits(value):
    return struct.unpack("<Q", struct.pack("<d", value))[0]


def unsigned_integer_to_ieee_bits(value, fraction_bits, exponent_bias):
    if value == 0:
        return 0
    exponent = value.bit_length() - 1
    if exponent <= fraction_bits:
        significand = value << (fraction_bits - exponent)
    else:
        shift = exponent - fraction_bits
        significand = value >> shift
        remainder = value & ((1 << shift) - 1)
        half = 1 << (shift - 1)
        if remainder > half or (remainder == half and (significand & 1) != 0):
            significand += 1
            if significand == 1 << (fraction_bits + 1):
                significand >>= 1
                exponent += 1
    fraction = significand & ((1 << fraction_bits) - 1)
    return ((exponent + exponent_bias) << fraction_bits) | fraction


def kernel_i32_control(test):
    x = parse_seed(test["seed"])
    for index in range(test["work_units"]):
        x = rotl32(u32(x + index), 13) ^ 0x9e3779b9
        x = u32(x + 7) if x & 1 else u32(x - 3)
    return x


def kernel_direct_calls_locals(test):
    x = parse_seed(test["seed"])
    for index in range(test["work_units"]):
        x = rotr32(u32((x ^ index) * 0x7feb352d), 16)
    return x


def kernel_call_indirect_table(test):
    x = parse_seed(test["seed"])
    for index in range(test["work_units"]):
        if (index & 1) == 0:
            x = rotl32(u32(x + index * 3), 5) ^ 0x85ebca6b
        else:
            x = u32(rotr32(u32(x ^ (index * 0x27d4eb2d)), 7) + 0x165667b1)
    return x


def kernel_memory_widths(test):
    x = parse_seed(test["seed"])
    words = [0] * 64
    for index in range(test["work_units"]):
        slot = index & 63
        words[slot] = x
        x = u32(words[slot] ^ (x & 0xff) ^ (x & 0xffff) ^ index)
        x = rotl32(x, 3)
    return x


def kernel_i64(test):
    seed = parse_seed(test["seed"])
    x = u64((seed << 32) | (seed ^ 0xa5a5a5a5))
    for index in range(test["work_units"]):
        x = rotl64(u64(x + index), 17) ^ 0x9e3779b97f4a7c15
    return x


def kernel_f32(test):
    seed = parse_seed(test["seed"])
    x = struct.unpack("<f", struct.pack("<I", seed))[0]
    mul = as_f32(1.0001220703125)
    scale = as_f32(0.000001)
    for index in range(test["work_units"]):
        x = as_f32(as_f32(x * mul) + as_f32(as_f32(float(index)) * scale))
    return f32_bits(x)


def kernel_f64(test):
    seed = parse_seed(test["seed"])
    x = struct.unpack("<d", struct.pack("<Q", 0x3ff0000000000000 | seed))[0]
    for index in range(test["work_units"]):
        x = x * 1.0000001 + float(index) * 0.000000001
    return f64_bits(x)


KERNELS = (
    kernel_i32_control, kernel_direct_calls_locals, kernel_call_indirect_table,
    kernel_memory_widths, kernel_i64, kernel_f32, kernel_f64,
)


def contract_crc(profile):
    return zlib.crc32(canonical_json(profile).encode("utf-8")) & MASK32


def payload(test):
    return KERNELS[test["id"] - 1](test)


def result_block(profile, test):
    value = payload(test)
    return struct.pack(
        "<IIIIIIII", MAGIC, CONTRACT_VERSION, contract_crc(profile), test["id"],
        test["work_units"], 0, value & MASK32, (value >> 32) & MASK32,
    )


def result_crc32(profile, test):
    return zlib.crc32(result_block(profile, test)) & MASK32


def validation_payload():
    f32_result = unsigned_integer_to_ieee_bits(
        VALIDATION_F32_UNSIGNED_I64, 23, 127)
    f64_result = unsigned_integer_to_ieee_bits(
        VALIDATION_F64_UNSIGNED_I64, 52, 1023)
    value = (f32_result << 32) ^ f64_result
    for cover_value in VALIDATION_COVER_VALUES:
        value ^= cover_value
    return value


def validation_result_block(profile):
    value = validation_payload()
    return struct.pack(
        "<IIIIIIII", MAGIC, CONTRACT_VERSION, contract_crc(profile),
        VALIDATION_TEST_ID, 0, 0, value & MASK32, (value >> 32) & MASK32,
    )


def validation_result_crc32(profile):
    return zlib.crc32(validation_result_block(profile)) & MASK32


def load_profile(path):
    with open(path, "r") as source:
        profile = json.load(source)
    # The generator canonicalizes hexadecimal seeds to u32 numbers before
    # deriving CONTRACT_CRC32; do the same without importing generator code.
    for test in profile.get("tests", []):
        test["seed"] = parse_seed(test["seed"])
    return profile


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", default=PROFILE_PATH)
    parser.add_argument("--test", type=int)
    parser.add_argument("--all", action="store_true")
    options = parser.parse_args(argv)
    if options.test is None and not options.all:
        parser.error("select --test ID or --all")
    profile = load_profile(options.profile)
    tests = profile["tests"] if options.all else [profile["tests"][options.test - 1]]
    for test in tests:
        value = payload(test)
        print("id=%d name=%s payload=0x%016x crc32=%08x" % (
            test["id"], test["name"], value, result_crc32(profile, test)))
    if options.all:
        print("validation-id=%d payload=0x%016x crc32=%08x" % (
            VALIDATION_TEST_ID, validation_payload(),
            validation_result_crc32(profile)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
