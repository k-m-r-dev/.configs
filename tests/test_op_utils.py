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
    def run_helper(self, item, *options, op_exit=0):
        with tempfile.TemporaryDirectory() as temp_dir:
            fake_bin = Path(temp_dir)
            fake_op = fake_bin / "op"
            fake_op.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "print(json.dumps(sys.argv[1:]))\n"
                "sys.exit(int(os.environ.get('FAKE_OP_EXIT', '0')))\n"
            )
            fake_op.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{fake_bin}:{env['PATH']}"
            env["FAKE_OP_EXIT"] = str(op_exit)
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


if __name__ == "__main__":
    unittest.main()
