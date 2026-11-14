#!/usr/bin/env python3
"""Maintainer checks for the cross-platform, instruction-only v04 package."""

from __future__ import annotations

import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS = ("codex-collab-switch",)


class PackageContractTests(unittest.TestCase):
    def test_skill_local_references_resolve(self) -> None:
        for document in (ROOT / "skills").rglob("*.md"):
            for target in re.findall(r"\]\(([^)]+)\)", document.read_text(encoding="utf-8")):
                self.assertTrue((document.parent / target).is_file(), (document, target))

    def test_only_one_instruction_only_skill_is_shipped(self) -> None:
        self.assertFalse((ROOT / "codex-agents").exists())
        self.assertEqual(
            sorted(path.name for path in (ROOT / "skills").iterdir() if path.is_dir()),
            sorted(SKILLS),
        )
        for name in SKILLS:
            skill = ROOT / "skills" / name
            self.assertTrue((skill / "SKILL.md").is_file())
            self.assertTrue((skill / "references/exit.md").is_file())
            self.assertFalse((skill / "scripts").exists())

    def test_runtime_has_no_external_language_dependency(self) -> None:
        runtime_text = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (ROOT / "skills").rglob("*")
            if path.is_file()
        )
        for forbidden in ("python3 ", "persist_mode.py", "os.fchmod", "node "):
            self.assertNotIn(forbidden, runtime_text)

    def test_openai_yaml_disables_implicit_invocation(self) -> None:
        for name in SKILLS:
            text = (ROOT / "skills" / name / "agents/openai.yaml").read_text(
                encoding="utf-8"
            )
            self.assertIn("allow_implicit_invocation: false", text)
            self.assertIn(f"${name}", text)

    def test_installers_target_official_and_optional_legacy_locations(self) -> None:
        shell = (ROOT / "install.sh").read_text(encoding="utf-8")
        powershell = (ROOT / "install.ps1").read_text(encoding="utf-8")
        self.assertIn('$HOME/.agents/skills', shell)
        self.assertIn("--legacy", shell)
        self.assertIn('Join-Path $AgentsRoot "skills"', powershell)
        self.assertIn("[switch]$Legacy", powershell)
        for text in (shell, powershell):
            self.assertNotIn("luna_executor.toml", text)
        self.assertNotIn('$HOME/.codex/config.toml', shell)
        self.assertNotIn('Join-Path $CodexRoot "config.toml"', powershell)
        self.assertNotIn("rm -", shell)
        self.assertNotIn("Remove-Item", powershell)

    @unittest.skipIf(os.name == "nt", "POSIX installer; use native PowerShell suite on Windows")
    def test_legacy_install_and_root_guard(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / "home"
            codex_home = Path(temporary) / "codex-home"
            home.mkdir()
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            environment["CODEX_HOME"] = str(codex_home)

            installed = subprocess.run(
                [str(ROOT / "install.sh"), "--legacy"],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(installed.returncode, 0, installed.stderr)
            for name in SKILLS:
                self.assertTrue((codex_home / "skills" / name / "SKILL.md").is_file())
            self.assertFalse((home / ".agents/skills").exists())

            environment["CODEX_HOME"] = "/"
            refused = subprocess.run(
                [str(ROOT / "install.sh"), "--legacy"],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(refused.returncode, 0)
            self.assertIn("filesystem-root", refused.stderr)

    @unittest.skipIf(os.name == "nt", "POSIX installer; use native PowerShell suite on Windows")
    def test_force_install_preserves_modified_target(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / "home"
            home.mkdir()
            environment = os.environ.copy()
            environment["HOME"] = str(home)

            subprocess.run(
                [str(ROOT / "install.sh")],
                cwd=ROOT,
                env=environment,
                check=True,
                capture_output=True,
                text=True,
            )
            target = home / ".agents/skills/codex-collab-switch"
            user_note = target / "user-note.txt"
            user_note.write_text("preserve this\n", encoding="utf-8")

            replaced = subprocess.run(
                [str(ROOT / "install.sh"), "--force"],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(replaced.returncode, 0, replaced.stderr)
            self.assertFalse((target / "user-note.txt").exists())
            backups = list(
                (home / ".agents/skill-backups").glob("codex-collab-switch.before-v04-*")
            )
            self.assertEqual(len(backups), 1)
            self.assertEqual(
                (backups[0] / "user-note.txt").read_text(encoding="utf-8"),
                "preserve this\n",
            )

    @unittest.skipIf(os.name == "nt", "POSIX installer; use native PowerShell suite on Windows")
    def test_shell_install_and_recoverable_uninstall(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / "home"
            home.mkdir()
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            environment.pop("CODEX_HOME", None)

            installed = subprocess.run(
                [str(ROOT / "install.sh")],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(installed.returncode, 0, installed.stderr)
            official = home / ".agents/skills"
            for name in SKILLS:
                self.assertTrue((official / name / "SKILL.md").is_file())
            self.assertFalse((home / ".codex/config.toml").exists())
            self.assertFalse((home / ".codex/agents/luna_executor.toml").exists())

            removed = subprocess.run(
                [str(ROOT / "uninstall.sh")],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(removed.returncode, 0, removed.stderr)
            for name in SKILLS:
                self.assertFalse((official / name).exists())
                backups = list(
                    (home / ".agents/skill-backups").glob(
                        f"{name}.uninstalled-v04-*"
                    )
                )
                self.assertEqual(len(backups), 1)

    @unittest.skipIf(os.name == "nt", "POSIX installer; use native PowerShell suite on Windows")
    def test_modified_skill_is_not_uninstalled(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / "home"
            home.mkdir()
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            subprocess.run(
                [str(ROOT / "install.sh")],
                cwd=ROOT,
                env=environment,
                check=True,
                capture_output=True,
                text=True,
            )
            changed = home / ".agents/skills/codex-collab-switch/user-note.txt"
            changed.write_text("keep me\n", encoding="utf-8")
            subprocess.run(
                [str(ROOT / "uninstall.sh")],
                cwd=ROOT,
                env=environment,
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertTrue(changed.is_file())


if __name__ == "__main__":
    unittest.main(verbosity=2)
