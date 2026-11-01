#!/usr/bin/env python3
"""Run inside the Plasma image; fixtures never use a user's persistent home."""

import importlib.machinery
import importlib.util
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import unittest
from unittest import mock

SCRIPT = Path("/opt/gow/appimage-menu")
if not SCRIPT.exists():
    SCRIPT = Path(__file__).resolve().parents[1] / "build-fedora/overlay/opt/gow/appimage-menu"
loader = importlib.machinery.SourceFileLoader("appimage_menu", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
integration = importlib.util.module_from_spec(spec)
loader.exec_module(integration)


class MenuTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.source = self.home / "Applications"
        self.source.mkdir()
        self.menu = integration.Menu(self.home, self.home / "data")

    def app(self, name, content=b"not an AppImage", mode=0o755):
        path = self.source / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        path.chmod(mode)
        return path

    def entries(self):
        return list(self.menu.applications.glob("gow-appimage-*.desktop"))

    def test_add_update_rename_remove_and_preserve_other_launchers(self):
        app = self.app("Game.AppImage")
        with mock.patch.object(integration, "metadata", return_value=({"Name": "First", "Categories": "Game;"}, None)):
            self.assertTrue(self.menu.sync())
            original = self.entries()[0]
            timestamp = original.stat().st_mtime_ns
            self.assertFalse(self.menu.sync())
            self.assertEqual(original.stat().st_mtime_ns, timestamp)
        unrelated = self.menu.applications / "personal.desktop"
        unrelated.write_text("[Desktop Entry]\nName=Personal\n")
        lookalike = self.menu.applications / "gow-appimage-personal.desktop"
        lookalike.write_bytes(unrelated.read_bytes())
        app.write_bytes(b"updated content")
        with mock.patch.object(integration, "metadata", return_value=({"Name": "Updated"}, None)):
            self.assertTrue(self.menu.sync())
            self.assertIn("Name=Updated\n", original.read_text())
            moved = app.rename(app.with_name("Renamed.AppImage"))
            self.assertTrue(self.menu.sync())
            self.assertFalse(original.exists())
            moved.unlink()
            self.assertTrue(self.menu.sync())
        self.assertEqual(self.entries(), [lookalike])
        self.assertTrue(unrelated.exists())

    def test_permissions_hidden_files_recursion_and_distinct_names(self):
        self.app("One/Game.AppImage")
        self.app("Two/Game.aPpImAgE")
        disabled = self.app("Disabled.AppImage", mode=0o644)
        self.app(".Hidden.AppImage")
        self.app(".hidden/Game.AppImage")
        (self.source / "loop").symlink_to(self.source, target_is_directory=True)
        self.menu.sync()
        self.assertEqual(len(self.entries()), 2)
        disabled.chmod(0o755)
        self.menu.sync()
        self.assertEqual(len(self.entries()), 3)
        disabled.chmod(0o644)
        self.menu.sync()
        self.assertEqual(len(self.entries()), 2)

    def test_read_only_source_and_no_execution_during_discovery(self):
        marker = self.home / "executed"
        app = self.app("Never run.AppImage", f"#!/bin/sh\ntouch '{marker}'\n".encode(), 0o555)
        original = app.stat()
        self.source.chmod(0o555)
        try:
            self.menu.sync()
            self.assertEqual(len(self.entries()), 1)
            self.assertFalse(marker.exists())
            self.assertEqual((app.stat().st_mode, app.stat().st_mtime_ns),
                             (original.st_mode, original.st_mtime_ns))
        finally:
            self.source.chmod(0o755)

    def test_launch_special_characters_without_shell_interpretation(self):
        marker = self.home / "injected"
        # Includes Desktop Entry field codes, shell syntax, Unicode and newline.
        name = 'Späces %F " \\ $HOME `touch injected`\n.AppImage'
        app = self.app(name, b'#!/bin/sh\nprintf "%s" "$0" > "$APPIMAGE_TEST_RESULT"\n')
        self.menu.sync()
        entry = self.entries()[0]
        subprocess.run(["desktop-file-validate", str(entry)], check=True)
        command = next(line[5:] for line in entry.read_text().splitlines() if line.startswith("Exec="))
        result = self.home / "launched"
        subprocess.run(["python3", str(SCRIPT), *command.split()[1:]], check=True,
                       cwd=self.home, env={**os.environ, "APPIMAGE_TEST_RESULT": str(result)})
        self.assertEqual(result.read_text(), str(app))
        self.assertFalse(marker.exists())

    def test_missing_folder_cleans_only_managed_entries(self):
        self.app("Gone.AppImage")
        self.menu.sync()
        shutil.rmtree(self.source)
        self.menu.sync()
        self.assertEqual(self.entries(), [])

    @unittest.skipIf(os.getuid() == 0, "permission check requires the desktop user")
    def test_unreadable_folder_does_not_delete_entries(self):
        self.app("Keep.AppImage")
        self.menu.sync()
        self.source.chmod(0)
        try:
            with self.assertRaises(PermissionError):
                self.menu.sync()
            self.assertEqual(len(self.entries()), 1)
        finally:
            self.source.chmod(0o755)

    @unittest.skipUnless(Path("/opt/gow/dwarfs-universal").exists(), "requires built image")
    def test_embedded_metadata_symlinks_icons_and_cleanup(self):
        appdir = self.home / "AppDir"
        (appdir / "usr/share/applications").mkdir(parents=True)
        (appdir / "usr/share/icons").mkdir()
        (appdir / "usr/share/applications/game.desktop").write_text(
            "[Desktop Entry]\nType=Application\nName=Test Game\nName[de]=Testspiel\n"
            "Categories=Game;Emulator\nIcon=game\nTerminal=true\n"
            "Exec=touch SHOULD_NOT_RUN\nActions=HostAction;\n"
            "[Desktop Action HostAction]\nName=Bad\nExec=touch SHOULD_NOT_RUN\n")
        (appdir / "game.desktop").symlink_to("usr/share/applications/game.desktop")
        (appdir / "usr/share/icons/game.svg").write_text('<svg xmlns="http://www.w3.org/2000/svg"/>')
        (appdir / "game.svg").symlink_to("usr/share/icons/game.svg")
        filesystem = self.home / "test.dwarfs"
        subprocess.run(["/opt/gow/dwarfs-universal", "--tool=mkdwarfs", "-i", str(appdir),
                        "-o", str(filesystem), "-l", "0", "--log-level", "error"],
                       check=True, stdout=subprocess.DEVNULL)
        header = bytearray(128)
        header[:11] = b"\x7fELF\x02\x01\x01\x00AI\x02"
        struct.pack_into("<Q", header, 40, 64)
        struct.pack_into("<HH", header, 58, 64, 1)
        app = self.app("Fixture.AppImage", header + filesystem.read_bytes())
        self.menu.sync()
        entry = self.entries()[0]
        text = entry.read_text()
        for expected in ("Name=Test Game\n", "Name[de]=Testspiel\n", "Categories=Game;Emulator;\n", "Terminal=true\n"):
            self.assertIn(expected, text)
        self.assertNotIn("SHOULD_NOT_RUN", text)
        self.assertNotIn("Actions=", text)
        self.assertEqual(len(list(self.menu.icons.glob("*.svg"))), 1)
        subprocess.run(["desktop-file-validate", str(entry)], check=True)
        # A replacement with no readable metadata drops the old icon/category.
        app.write_bytes(b"unsupported replacement")
        self.menu.sync()
        self.assertIn("Categories=Utility;\n", entry.read_text())
        self.assertEqual(list(self.menu.icons.iterdir()), [])
        app.unlink()
        self.menu.sync()
        self.assertEqual(self.entries(), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
