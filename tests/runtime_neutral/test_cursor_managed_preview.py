from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
INSTALLER = REPO_ROOT / "scripts" / "install" / "install_vgo_adapter.py"


class CursorManagedPreviewTests(unittest.TestCase):
    def test_python_installer_materializes_cursor_host_closure_and_sidecar_only_surface(self) -> None:
        with tempfile.TemporaryDirectory() as tempdir:
            target_root = Path(tempdir)
            result = subprocess.run(
                [
                    sys.executable,
                    str(INSTALLER),
                    "--repo-root",
                    str(REPO_ROOT),
                    "--target-root",
                    str(target_root),
                    "--host",
                    "cursor",
                    "--profile",
                    "full",
                ],
                capture_output=True,
                text=True,
                check=True,
            )
            payload = json.loads(result.stdout)
            closure_path = target_root / ".vibeskills" / "host-closure.json"
            host_settings_path = target_root / ".vibeskills" / "host-settings.json"

            self.assertEqual("cursor", payload["host_id"])
            self.assertEqual("preview-guidance", payload["install_mode"])
            self.assertTrue(closure_path.exists())
            self.assertTrue(host_settings_path.exists())
            self.assertTrue((target_root / "skills" / "vibe" / "SKILL.md").exists())
            self.assertFalse((target_root / "settings.json").exists())
            self.assertFalse((target_root / "commands").exists())

            closure = json.loads(closure_path.read_text(encoding="utf-8"))
            host_settings = json.loads(host_settings_path.read_text(encoding="utf-8"))

            self.assertEqual("cursor", closure["host_id"])
            self.assertEqual(str(target_root.resolve()), closure["target_root"])
            self.assertEqual("cursor", host_settings["host_id"])
            self.assertEqual(str((target_root / "skills").resolve()), host_settings["skills_root"])
            self.assertIn("specialist_wrapper_ready", payload)
            self.assertIsInstance(payload["specialist_wrapper_ready"], bool)


if __name__ == "__main__":
    unittest.main()
