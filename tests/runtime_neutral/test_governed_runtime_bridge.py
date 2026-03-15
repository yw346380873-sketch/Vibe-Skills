from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
EXPECTED_STAGE_IDS = [
    "skeleton_check",
    "deep_interview",
    "requirement_doc",
    "xl_plan",
    "plan_execute",
    "phase_cleanup",
]


def resolve_powershell() -> str | None:
    candidates = [
        shutil.which("pwsh"),
        shutil.which("pwsh.exe"),
        r"C:\Program Files\PowerShell\7\pwsh.exe",
        r"C:\Program Files\PowerShell\7-preview\pwsh.exe",
        shutil.which("powershell"),
        shutil.which("powershell.exe"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return str(Path(candidate))
    return None


class GovernedRuntimeBridgeTests(unittest.TestCase):
    def test_version_governance_bridges_governed_runtime_surfaces(self) -> None:
        governance = json.loads((REPO_ROOT / "config" / "version-governance.json").read_text(encoding="utf-8"))
        packaging = governance["packaging"]["mirror"]
        runtime = governance["runtime"]["installed_runtime"]
        contract = json.loads((REPO_ROOT / "config" / "runtime-contract.json").read_text(encoding="utf-8"))

        self.assertIn("templates", packaging["directories"])
        self.assertIn("protocols", packaging["directories"])
        self.assertIn("scripts", packaging["directories"])

        required_markers = set(runtime["required_runtime_markers"])
        self.assertIn("scripts/runtime/VibeRuntime.Common.ps1", required_markers)
        self.assertIn("scripts/runtime/invoke-vibe-runtime.ps1", required_markers)
        self.assertIn("scripts/verify/vibe-governed-runtime-contract-gate.ps1", required_markers)
        self.assertIn("config/runtime-contract.json", required_markers)
        self.assertIn("config/runtime-modes.json", required_markers)
        self.assertIn("config/requirement-doc-policy.json", required_markers)
        self.assertIn("config/plan-execution-policy.json", required_markers)
        self.assertIn("config/phase-cleanup-policy.json", required_markers)

        self.assertEqual(
            EXPECTED_STAGE_IDS,
            [stage["id"] for stage in contract["stages"]],
        )

    def test_invoke_vibe_runtime_produces_six_stage_closure_under_temp_artifact_root(self) -> None:
        script_path = REPO_ROOT / "scripts" / "runtime" / "invoke-vibe-runtime.ps1"
        run_id = "pytest-governed-runtime"
        shell = resolve_powershell()
        if shell is None:
            self.skipTest("PowerShell executable not available in PATH")

        with tempfile.TemporaryDirectory() as tempdir:
            artifact_root = Path(tempdir)
            command = [
                shell,
                "-NoLogo",
                "-NoProfile",
                "-Command",
                (
                    "& { "
                    f"$result = & '{script_path}' "
                    "-Task 'bridge governed runtime into a verified temporary artifact root' "
                    "-Mode benchmark_autonomous "
                    f"-RunId '{run_id}' "
                    f"-ArtifactRoot '{artifact_root}'; "
                    "$result | ConvertTo-Json -Depth 20 }"
                ),
            ]
            completed = subprocess.run(
                command,
                cwd=REPO_ROOT,
                capture_output=True,
                text=True,
                check=True,
            )

            payload = json.loads(completed.stdout)
            summary_path = Path(payload["summary_path"])
            session_root = Path(payload["session_root"])
            repo_root_text = str(REPO_ROOT.resolve()).lower()

            self.assertEqual(session_root / "runtime-summary.json", summary_path)
            self.assertFalse(str(session_root).lower().startswith(repo_root_text))
            self.assertFalse(str(summary_path).lower().startswith(repo_root_text))
            self.assertEqual(run_id, session_root.name)
            self.assertEqual("vibe-sessions", session_root.parent.name)
            self.assertEqual("runtime", session_root.parent.parent.name)
            self.assertEqual("outputs", session_root.parent.parent.parent.name)

            summary = payload["summary"]
            summary_path_relative = summary.get("session_root_relative")
            if summary_path.exists():
                summary = json.loads(summary_path.read_text(encoding="utf-8"))
            elif summary_path_relative:
                reconstructed_summary_path = artifact_root / summary_path_relative / "runtime-summary.json"
                if reconstructed_summary_path.exists():
                    summary = json.loads(reconstructed_summary_path.read_text(encoding="utf-8"))
            self.assertEqual("benchmark_autonomous", summary["mode"])
            self.assertEqual(
                EXPECTED_STAGE_IDS,
                summary["stage_order"],
            )

            artifacts = summary["artifacts"]
            relative_artifacts = summary.get("artifacts_relative", {})

            def resolve_artifact_path(key: str) -> Path:
                relative = relative_artifacts.get(key)
                if relative:
                    return artifact_root / Path(relative)
                return Path(artifacts[key])

            for key in (
                "skeleton_receipt",
                "intent_contract",
                "requirement_doc",
                "requirement_receipt",
                "execution_plan",
                "execution_plan_receipt",
                "execute_receipt",
                "execution_manifest",
                "benchmark_proof_manifest",
                "cleanup_receipt",
            ):
                self.assertFalse(str(Path(artifacts[key])).lower().startswith(repo_root_text), key)
                if key in relative_artifacts:
                    self.assertFalse(Path(relative_artifacts[key]).is_absolute(), key)

            requirement_doc_path = resolve_artifact_path("requirement_doc")
            execution_plan_path = resolve_artifact_path("execution_plan")
            execute_receipt_path = resolve_artifact_path("execute_receipt")
            execution_manifest_path = resolve_artifact_path("execution_manifest")
            benchmark_proof_path = resolve_artifact_path("benchmark_proof_manifest")

            if requirement_doc_path.exists():
                requirement_doc = requirement_doc_path.read_text(encoding="utf-8")
                self.assertIn("## Acceptance Criteria", requirement_doc)
                self.assertIn("## Assumptions", requirement_doc)
            self.assertEqual("requirements", requirement_doc_path.parent.name)
            self.assertEqual("plans", execution_plan_path.parent.name)

            execute_receipt = json.loads(execute_receipt_path.read_text(encoding="utf-8"))
            execution_manifest = json.loads(execution_manifest_path.read_text(encoding="utf-8"))
            benchmark_proof = json.loads(benchmark_proof_path.read_text(encoding="utf-8"))

            self.assertNotEqual("execution-contract-prepared", execute_receipt["status"])
            self.assertGreaterEqual(execute_receipt["executed_unit_count"], 2)
            self.assertEqual(execute_receipt["executed_unit_count"], execution_manifest["executed_unit_count"])
            self.assertEqual("completed", execution_manifest["status"])
            self.assertGreaterEqual(execution_manifest["successful_unit_count"], 2)
            self.assertEqual(0, execution_manifest["failed_unit_count"])
            self.assertTrue(benchmark_proof["proof_passed"])
            self.assertGreaterEqual(benchmark_proof["executed_unit_count"], 2)

            for result_path in benchmark_proof["result_paths"]:
                result = json.loads(Path(result_path).read_text(encoding="utf-8"))
                self.assertEqual("completed", result["status"])
                self.assertEqual(0, result["exit_code"])
                self.assertTrue(Path(result["stdout_path"]).exists())
                self.assertTrue(Path(result["stderr_path"]).exists())


if __name__ == "__main__":
    unittest.main()
