#!/usr/bin/env python3
"""Host-side contract tests for W4Bench V1."""

from __future__ import print_function

import copy
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest


ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
import generate_profile
import reference_oracle


class W4BenchContractTest(unittest.TestCase):
    def setUp(self):
        self.profile = generate_profile.load_profile(
            os.path.join(ROOT, "profile_v1.json"))
        self.contract_crc = generate_profile.contract_crc(self.profile)
        self.profile_crc = generate_profile.frozen_profile_crc(
            self.profile, self.contract_crc)

    def test_ieee_crc32_known_vector(self):
        self.assertEqual(generate_profile.crc32(b"123456789"), 0xcbf43926)

    def test_catalog_is_exact_complete_source_set(self):
        catalog = generate_profile.validate_catalog_data(
            json.loads(generate_profile.render_catalog()))
        self.assertEqual(len(catalog["entries"]), 190)
        self.assertEqual(sum(1 for entry in catalog["entries"]
                             if entry["mode"] == "trap"), 1)
        self.assertFalse(any(entry["mode"] == "pending" for entry in catalog["entries"]))
        timed = set(int(entry["opcode"], 16) for entry in catalog["entries"]
                    if entry["mode"] == "timed")
        self.assertEqual(timed, generate_profile.TIMED_SOURCE_OPCODES)
        for entry in catalog["entries"]:
            self.assertEqual(entry["name"],
                             generate_profile.opcode_token(int(entry["opcode"], 16)))

    def test_build_outputs_are_deterministic(self):
        with tempfile.TemporaryDirectory() as first:
            with tempfile.TemporaryDirectory() as second:
                generate_profile.generate(
                    os.path.join(ROOT, "profile_v1.json"), first)
                generate_profile.generate(
                    os.path.join(ROOT, "profile_v1.json"), second)
                for relative in (
                        "opcode_catalog_v1.json",
                        "w4bench_v1.wat",
                        os.path.join("java", "w4me", "W4BenchProfile.java")):
                    with open(os.path.join(first, relative), "rb") as source:
                        first_bytes = source.read()
                    with open(os.path.join(second, relative), "rb") as source:
                        second_bytes = source.read()
                    self.assertEqual(first_bytes, second_bytes, relative)

    def test_authoritative_gate_rejects_precalibration(self):
        profile = copy.deepcopy(self.profile)
        profile["state"] = "PRECALIBRATION"
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as output:
            json.dump(profile, output)
            path = output.name
        try:
            with tempfile.TemporaryDirectory() as output_dir:
                completed = subprocess.run(
                    [sys.executable, os.path.join(ROOT, "generate_profile.py"),
                     "--profile", path, "--output-dir", output_dir,
                     "--require-frozen"],
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            self.assertEqual(completed.returncode, 1)
            self.assertIn("requires a FROZEN profile", completed.stderr)
        finally:
            os.unlink(path)

    def test_frozen_calibration_matches_tracked_contract(self):
        with open(os.path.join(ROOT, "calibration_v1.json"), "r") as source:
            calibration = json.load(source)
        self.assertEqual(calibration["profile_state"], "FROZEN")
        self.assertEqual(calibration["profile_crc32"], "%08x" % self.profile_crc)
        self.assertEqual(calibration["contract_crc32"], "%08x" % self.contract_crc)
        with open(os.path.join(ROOT, "profile_v1.json"), "rb") as source:
            profile_sha256 = hashlib.sha256(source.read()).hexdigest()
        self.assertEqual(calibration["profile_sha256"], profile_sha256)
        generated_java = generate_profile.render_java(
            self.profile, self.contract_crc, self.profile_crc).encode("utf-8")
        self.assertEqual(
            calibration["generated_profile_sha256"],
            hashlib.sha256(generated_java).hexdigest())
        self.assertEqual(set(calibration["median_wall_ms"]),
                         set(test["name"] for test in self.profile["tests"]))
        self.assertTrue(all(value >= self.profile["min_timed_ms"]
                            for value in calibration["median_wall_ms"].values()))

    def test_oracle_matches_generated_payload_and_crc(self):
        self.assertEqual(reference_oracle.contract_crc(self.profile),
                         self.contract_crc)
        raw_profile = reference_oracle.load_profile(
            os.path.join(ROOT, "profile_v1.json"))
        self.assertEqual(reference_oracle.contract_crc(raw_profile),
                         self.contract_crc)
        for test in self.profile["tests"]:
            expected_payload = generate_profile.payload_for_test(test)
            expected_crc = generate_profile.crc32(
                generate_profile.result_block(self.contract_crc, test))
            self.assertEqual(reference_oracle.payload(test), expected_payload)
            self.assertEqual(
                reference_oracle.result_crc32(self.profile, test), expected_crc)
        self.assertEqual(
            reference_oracle.validation_payload(),
            generate_profile.validation_payload())
        self.assertEqual(
            reference_oracle.validation_result_crc32(self.profile),
            generate_profile.validation_result_crc(self.contract_crc))
        self.assertEqual(
            reference_oracle.unsigned_integer_to_ieee_bits(
                reference_oracle.VALIDATION_F32_UNSIGNED_I64, 23, 127),
            0x5f000001)
        self.assertEqual(
            reference_oracle.unsigned_integer_to_ieee_bits(
                reference_oracle.VALIDATION_F64_UNSIGNED_I64, 52, 1023),
            0x43e8000000000001)

    def test_tampered_profile_is_rejected(self):
        broken = copy.deepcopy(self.profile)
        broken["tests"][0]["work_units"] = 7
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as output:
            json.dump(broken, output)
            path = output.name
        try:
            with self.assertRaises(ValueError):
                generate_profile.load_profile(path)
        finally:
            os.unlink(path)

    def test_required_runtime_exports_are_generated(self):
        wat = generate_profile.render_wat(self.profile, self.contract_crc)
        for name in ("cover_control", "cover_memory", "cover_i32", "cover_i64",
                     "cover_f32", "cover_f64", "cover_convert", "cover_bulk",
                     "validate_all", "trap_unreachable", "report"):
            self.assertIn('(export "%s")' % name, wat)
        for test in self.profile["tests"]:
            self.assertIn('(export "%s")' % test["prepare_export"], wat)
            self.assertIn('(export "%s")' % test["run_export"], wat)

    def test_every_catalogued_opcode_has_a_wat_probe_token(self):
        catalog = generate_profile.validate_catalog_data(
            json.loads(generate_profile.render_catalog()))
        wat = generate_profile.render_wat(self.profile, self.contract_crc)
        for entry in catalog["entries"]:
            self.assertIn(entry["wat_token"], wat, entry["opcode"])


if __name__ == "__main__":
    unittest.main()
