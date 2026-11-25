#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境の指定を必須にし、実際の初期構成と取り違えないようにする。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 一時設定で Neovim を起動し、導入完了まで待つことと失敗が呼び出し元に伝わることを確認する。
python3 - "$ROOT_DIR" <<'PY'
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile

repo = Path(sys.argv[1])
nvim = shutil.which("nvim")
assert nvim, "テストには Neovim が必要です。"
source = (repo / ".bin/bootstrap-macos.sh").read_text()
entrypoint = '\nmain "$@"'
assert source.count(entrypoint) == 1, "初期構成スクリプトの実行開始位置を確認できません。"

with tempfile.TemporaryDirectory(prefix="bootstrap-neovim-test-") as temporary:
    root = Path(temporary)
    bindir = root / "bin"
    bindir.mkdir()
    init = root / "init.lua"
    init.write_text('''
-- 操作順序を一時ファイルに残し、実際のプラグインや解析器には接続しない。
local function record(event)
    vim.fn.writefile({ event }, vim.env.BOOTSTRAP_NEOVIM_TRACE, "a")
end
vim.api.nvim_create_user_command("Lazy", function() record("sync") end, { bang = true, nargs = "+" })
vim.api.nvim_create_autocmd("VimLeavePre", { callback = function() record("quit") end })
-- プラグイン側に記録されたビルドエラーを再現し、後続の解析器導入へ進まないことを確認する。
package.preload["lazy.manage.checker"] = function()
    return { has_errors = function() return vim.env.BOOTSTRAP_NEOVIM_CASE == "build-failure" end }
end
package.preload["config.treesitter"] = function()
    return {
        wait_for_parsers = function(timeout)
            record("wait-start")
            if vim.env.BOOTSTRAP_NEOVIM_CASE == "failure" then
                error("解析器の導入に失敗しました。")
            end
            if vim.env.BOOTSTRAP_NEOVIM_CASE == "timeout" then
                error("解析器の導入待機がタイムアウトしました。")
            end
            local finished = false
            vim.defer_fn(function() finished = true end, 20)
            assert(vim.wait(timeout, function() return finished end), "導入完了を待機できません。")
            record("wait-finished")
        end,
    }
end
''')
    wrapper = bindir / "nvim"
    wrapper.write_text("#!/bin/bash\nexec " + shlex.join([nvim, "-u", str(init), "-i", "NONE", "--noplugin"]) + ' "$@"\n')
    wrapper.chmod(0o755)
    isolated = root / "bootstrap-function.sh"
    # 全体の実行だけを除外し、変更対象の関数を元のスクリプトと同じ定義で呼び出す。
    isolated.write_text(source.replace(entrypoint, "\ninstall_neovim_plugins", 1))

    for case in ["success", "failure", "timeout", "build-failure"]:
        trace = root / f"{case}.trace"
        environment = dict(os.environ, PATH=f"{bindir}:{os.environ['PATH']}",
                           XDG_DATA_HOME=str(root / "data"), XDG_STATE_HOME=str(root / "state"),
                           XDG_CACHE_HOME=str(root / "cache"), NVIM_LOG_FILE=str(root / "nvim.log"),
                           BOOTSTRAP_NEOVIM_TRACE=str(trace), BOOTSTRAP_NEOVIM_CASE=case, LC_ALL="en_US.UTF-8")
        # 日本語の引数を含む実行ログも、欠損のない UTF-8 として読み取れることを確認する。
        result = subprocess.run(["/bin/bash", str(isolated)], env=environment,
                                text=True, capture_output=True, timeout=120)
        expected = ["sync"]
        if case != "build-failure":
            expected.append("wait-start")
        if case == "success":
            expected.append("wait-finished")
        expected.append("quit")
        assert trace.read_text().splitlines() == expected, (case, result.stdout, result.stderr)
        assert (result.returncode == 0) == (case == "success"), (case, result.returncode, result.stderr)
        if case != "success":
            expected_error = "プラグインの同期" if case == "build-failure" else "解析器の導入"
            assert expected_error in result.stderr, (case, result.stderr)

print("PASS: Neovim は解析器の導入完了を待ち、同期失敗・導入失敗・待機時間超過を初期構成へ伝えます。")
PY
