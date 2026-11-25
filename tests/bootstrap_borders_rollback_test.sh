#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 一時 HOME と模擬 Homebrew を使い、各失敗段階で削除対象を確認する。
python3 - "$ROOT_DIR" <<'PY'
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

repo = Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix="borders-rollback-test-") as tmp:
    for case in ["early", "packages", "existing-late", "new-late", "new-partial", "new-success"]:
        root = Path(tmp) / case
        home = root / "home"
        target = root / "dotfiles"
        bindir = root / "bin"
        home.mkdir(parents=True)
        target.mkdir()
        bindir.mkdir()
        (home / ".zshrc").write_text("original shell settings\n")
        state = root / "borders-installed"
        if case in ("early", "packages", "existing-late"):
            state.touch()
        log = root / "brew.log"
        log.touch()
        brew = bindir / "brew"
        brew.write_text('''#!/bin/bash
printf '%s\n' "$*" >> "$TEST_BREW_LOG"
case "$*" in
  'list --formula borders') [[ -f "$TEST_BORDERS_STATE" ]];;
  'list --formula neovim') [[ "$TEST_CASE" != packages ]];;
  'install neovim') exit 1;;
  'install borders') echo 'Error: untrusted tap felixkratz/formulae' >&2; exit 1;;
  'install felixkratz/formulae/borders') touch "$TEST_BORDERS_STATE";;
  'uninstall --formula borders') rm "$TEST_BORDERS_STATE";;
  'services start borders') [[ "$TEST_CASE" != new-partial ]];;
  *) exit 0;;
esac
''')
        brew.chmod(0o755)
        nvim = bindir / "nvim"
        nvim.write_text('#!/bin/bash\n[[ "$TEST_CASE" == new-success ]]\n')
        nvim.chmod(0o755)
        if case != "early":
            (target / ".git").mkdir()
            (target / ".bin").mkdir()
            for name in ["install.sh", "install-janky-borders.sh"]:
                shutil.copy2(repo / ".bin" / name, target / ".bin" / name)
            # Karabiner のセットアップは実行せず、後続の Neovim まで進める。
            karabiner = target / ".bin/install-karabiner.sh"
            karabiner.write_text("#!/bin/bash\nexit 0\n")
            karabiner.chmod(0o755)
            (target / ".config/borders").mkdir(parents=True)
            (target / ".config/borders/bordersrc").write_text("# fixture\n")
            (target / ".zshrc").write_text("new shell settings\n")
            for shell, suffix in [(".bash", "bash"), (".zsh", "zsh")]:
                (target / shell).mkdir()
                (target / shell / f"env.local.{suffix}.example").write_text("export TEST_VALUE=example\n")
            (home / "vscode-php-debug/.git").mkdir(parents=True)
            (home / "vscode-php-debug/out").mkdir()
            (home / "vscode-php-debug/out/phpDebug.js").touch()
        environment = dict(os.environ, HOME=str(home), PATH=f"{bindir}:/usr/bin:/bin:/usr/sbin:/sbin",
                           TEST_BREW_LOG=str(log), TEST_BORDERS_STATE=str(state), TEST_CASE=case, LC_ALL="en_US.UTF-8")
        result = subprocess.run(["/bin/bash", str(repo / ".bin/bootstrap-macos.sh"), "--directory", str(target)],
                                env=environment, text=True, capture_output=True)
        assert (result.returncode == 0) == (case == "new-success"), (case, result.stdout, result.stderr)
        calls = log.read_text().splitlines()
        removed = "uninstall --formula borders" in calls
        should_remove = case in ("new-late", "new-partial")
        assert removed == should_remove, (case, calls, result.stderr)
        assert ("services stop borders" in calls) == should_remove, (case, calls)
        assert state.exists() != should_remove, (case, calls)
        if case != "new-success":
            assert (home / ".zshrc").read_text() == "original shell settings\n", case
        else:
            for shell, suffix in [(".bash", "bash"), (".zsh", "zsh")]:
                assert (home / shell / f"env.local.{suffix}").read_text() == "export TEST_VALUE=example\n"
print("PASS: 既存の JankyBorders を保持し、今回の新規導入だけを失敗時に取り消します。")
PY
