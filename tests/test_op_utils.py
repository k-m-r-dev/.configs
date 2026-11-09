#!/usr/bin/env python3
"""Behavior tests for the generic 1Password Zsh helper."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "home" / "op_utils.zsh"


@unittest.skipUnless(shutil.which("zsh"), "zsh is required")
class OpUtilsTests(unittest.TestCase):
    def run_helper(self, item, *options, op_exit=0, op_output=None):
        with tempfile.TemporaryDirectory() as temp_dir:
            fake_bin = Path(temp_dir)
            fake_op = fake_bin / "op"
            fake_op.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "print(os.environ.get('FAKE_OP_OUTPUT', json.dumps(sys.argv[1:])))\n"
                "sys.exit(int(os.environ.get('FAKE_OP_EXIT', '0')))\n"
            )
            fake_op.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{fake_bin}:{env['PATH']}"
            env["FAKE_OP_EXIT"] = str(op_exit)
            if op_output is not None:
                env["FAKE_OP_OUTPUT"] = op_output
            return subprocess.run(
                [
                    "zsh",
                    "-c",
                    'source "$1"; shift; op_get_item "$@"',
                    "_",
                    str(HELPER),
                    item,
                    *options,
                ],
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

    def test_forwards_name_vault_account_and_format(self):
        result = self.run_helper(
            "NPM ReadOnly Token",
            "--vault",
            "Engineering Contractors",
            "--account",
            "fieldnation-team.1password.com",
            "--format",
            "json",
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout),
            [
                "item",
                "get",
                "NPM ReadOnly Token",
                "--format",
                "json",
                "--vault",
                "Engineering Contractors",
                "--account",
                "fieldnation-team.1password.com",
            ],
        )

    def test_defaults_format_to_json_for_item_id(self):
        result = self.run_helper("l357xlwz2nsyqs3y324qkt3kby")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout),
            ["item", "get", "l357xlwz2nsyqs3y324qkt3kby", "--format", "json"],
        )

    def test_propagates_op_failure(self):
        result = self.run_helper("NPM ReadOnly Token", op_exit=42)

        self.assertEqual(result.returncode, 42)

    @unittest.skipUnless(shutil.which("jq"), "jq is required")
    def test_extracts_field_by_id_or_label(self):
        item = {
            "fields": [
                {"id": "password", "label": "password", "value": "test-secret"}
            ]
        }
        result = self.run_helper(
            "DD API Key",
            "--vault",
            "Engineering Vault",
            "--field",
            "password",
            op_output=json.dumps(item),
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "test-secret\n")

    @unittest.skipUnless(shutil.which("jq"), "jq is required")
    def test_rejects_ambiguous_field_match(self):
        item = {
            "fields": [
                {"id": "password1", "label": "password", "value": "one"},
                {"id": "password2", "label": "password", "value": "two"},
            ]
        }
        result = self.run_helper(
            "DD API Key",
            "--field",
            "password",
            op_output=json.dumps(item),
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected exactly one matching field", result.stderr)


if __name__ == "__main__":
    unittest.main()
