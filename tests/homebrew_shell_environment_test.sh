#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 標準配置先だけを一時パスに置き換え、実際のシェルで設定の読み込みを検証する。
python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import subprocess
import sys
import tempfile

repo = Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix="homebrew-shell-test-") as tmp:
    root = Path(tmp)
    for shell, config in [("/bin/zsh", ".zsh/env.zsh"), ("/bin/bash", ".bash/env.bash")]:
        for case in ["apple", "intel", "absent", "linux"]:
            fixture = root / (Path(shell).name + "-" + case)
            fixture.mkdir()
            # 起動時に使う共有設定とシェル固有の環境設定を一時ホームへ配置する。
            # 個人の環境変数ファイルはコピーせず、ローカル設定の優先順位だけを再現する。
            (fixture / ".bin").mkdir()
            config_dir = fixture / Path(config).parent
            config_dir.mkdir()
            local_bin = fixture / "custom/bin"
            local_bin.mkdir(parents=True)
            local_config = config_dir / ("env.local.zsh" if shell.endswith("zsh") else "env.local.bash")
            local_config.write_text(
                f'case ":$PATH:" in *":{local_bin}:"*) ;; *) export PATH="{local_bin}:$PATH" ;; esac\n'
                'export TAVILY_API_KEY=test-local-value\n'
            )
            tool = fixture / ".bin/dotfiles-test-command"
            tool.write_text("#!/bin/sh\nexit 0\n")
            tool.chmod(0o755)
            apple = fixture / "opt/homebrew"
            intel = fixture / "usr/local"
            prefix = intel if case == "intel" else apple
            if case != "absent":
                (prefix / "bin").mkdir(parents=True)
                brew = prefix / "bin/brew"
                brew.write_text(
                    '#!/bin/bash\n[[ "$1" == shellenv ]] || exit 1\n'
                    "cat <<'ENV'\n"
                    f'export PATH="{prefix}/bin:{prefix}/sbin:$PATH"\n'
                    f'export HOMEBREW_PREFIX="{prefix}"\nENV\n'
                )
                brew.chmod(0o755)
                starship = prefix / "bin/starship"
                starship.write_text("#!/bin/bash\nexit 0\n")
                starship.chmod(0o755)
            text = (repo / config).read_text()
            text = text.replace("/opt/homebrew", str(apple)).replace("/usr/local", str(intel))
            settings = fixture / config
            settings.write_text(text)
            shared = repo / ".bin/shell-environment.sh"
            if shared.exists():
                (fixture / ".bin" / shared.name).write_text(
                    shared.read_text().replace("/opt/homebrew", str(apple)).replace("/usr/local", str(intel))
                )
            # 親プロセスの Homebrew 設定を引き継がない。
            environment = {"HOME": str(fixture), "PATH": "/usr/bin::/bin:/usr/bin:", "TEST_SETTINGS": str(settings)}
            # 環境設定を繰り返し読み込んでも検索順とローカル設定を維持する。
            command = (
                'source "$TEST_SETTINGS"; first_path="$PATH"; source "$TEST_SETTINGS"; '
                '[[ "$PATH" == "$first_path" ]] || exit 31; '
                '[[ "$TAVILY_API_KEY" == test-local-value ]] || exit 32; '
                f'[[ "${{PATH%%:*}}" == "{local_bin}" ]] || exit 33; '
                '[[ ":$PATH:" == *"::"* ]] || exit 35; '
                'printf "PATH=%s\\n" "$PATH"; '
                'command -v dotfiles-test-command || exit 34; '
                'command -v brew; command -v starship'
            )
            if case == "linux":
                command = "OSTYPE=linux-gnu; " + command
            result = subprocess.run([shell, "-f", "-c", command], env=environment, text=True, capture_output=True, timeout=120)
            assert str(tool) in result.stdout, (shell, case, result.stdout, result.stderr)
            path_entries = result.stdout.splitlines()[0].removeprefix("PATH=").split(":")
            assert len(path_entries) == len(set(path_entries)), (shell, case, path_entries)
            if case in ("apple", "intel"):
                assert result.returncode == 0, (shell, case, result.stderr)
                assert str(prefix / "bin/brew") in result.stdout, result.stdout
                assert str(prefix / "bin/starship") in result.stdout, result.stdout
            else:
                assert result.returncode == 1, (shell, case, result.stdout)
                assert str(prefix) not in result.stdout, result.stdout
            assert not result.stderr, (shell, case, result.stderr)

            if case in ("apple", "intel"):
                # 本物の起動ファイルを使い、対話シェルの起動と再読込でも同じ結果になることを確かめる。
                # 履歴・補完・外部プロンプトは対象外のため、設定ファイルを一時的な空ファイルに置き換える。
                for other in (repo / Path(config).parent).glob("*." + Path(config).suffix.lstrip(".")):
                    if other.name not in (settings.name, local_config.name):
                        (config_dir / other.name).write_text("# 検証対象外の設定は読み込まない。\n")
                rc = fixture / (".zshrc" if shell.endswith("zsh") else ".bashrc")
                rc.write_text((repo / rc.name).read_text())
                startup_command = (
                    'first_path="$PATH"; source "$TEST_RC"; '
                    '[[ "$PATH" == "$first_path" ]] || exit 36; command -v dotfiles-test-command'
                )
                options = ["-d", "-i"] if shell.endswith("zsh") else ["--noprofile", "--rcfile", str(rc), "+m", "-i"]
                startup = subprocess.run([shell, *options, "-c", startup_command],
                                         env=dict(environment, TEST_RC=str(rc), TERM="dumb"),
                                         text=True, capture_output=True, timeout=120)
                assert startup.returncode == 0, (shell, case, startup.stdout, startup.stderr)
                assert str(tool) in startup.stdout, (shell, case, startup.stdout)
                # 制御端末を持たない自動テストでは Bash がこの通知だけを出すため、起動エラーと区別する。
                startup_errors = startup.stderr.replace("bash: no job control in this shell\n", "")
                assert not startup_errors, (shell, case, startup_errors)

            # 起動スクリプトも、PATH 外の既存 Homebrew を再インストールせず見つける。
            if shell == "/bin/zsh" and case in ("apple", "intel"):
                bootstrap = fixture / "bootstrap.sh"
                bootstrap.write_text((repo / ".bin/bootstrap-macos.sh").read_text()
                                     .replace("/opt/homebrew", str(apple)).replace("/usr/local", str(intel)))
                target = fixture / "not-a-git-repo"
                target.mkdir()
                mock_bin = fixture / "mock-bin"
                mock_bin.mkdir()
                curl_log = fixture / "curl-called"
                curl = mock_bin / "curl"
                curl.write_text(f'#!/bin/bash\ntouch "{curl_log}"\nexit 1\n')
                curl.chmod(0o755)
                environment["PATH"] = f"{mock_bin}:/usr/bin:/bin"
                result = subprocess.run(["/bin/bash", str(bootstrap), "--directory", str(target)],
                                        env=environment, text=True, capture_output=True, timeout=120)
                assert result.returncode != 0, result.stdout
                assert "[スキップ] Homebrew は導入済みです。" in result.stdout, (result.stdout, result.stderr)
                assert "既存のディレクトリが Git リポジトリではありません" in result.stderr, result.stderr
                assert not curl_log.exists(), "既存の Homebrew に対してインストーラーを呼び出しました。"
# 共有設定が Git の除外規則により新しい端末から欠落することを防ぐ。
assert subprocess.run(["git", "check-ignore", ".bin/shell-environment.sh"], cwd=repo,
                      capture_output=True).returncode == 1, "共通環境設定が Git 管理対象から除外されています。"
print("PASS: zsh・Bash の起動と再読込で Homebrew と ~/.bin を認識し、検索順とローカル設定を維持します。")
PY
