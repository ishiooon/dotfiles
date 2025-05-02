return {
    "yetone/avante.nvim",
    enabled = true,
    event = "VeryLazy",
    lazy = false,
    version = false,
    opts = {
        provider = "copilot",
        auto_suggestions_provider = "copilot",
        behaviour = {
            auto_suggestions = false,
            auto_set_highlight_group = true,
            auto_set_keymaps = true,
            auto_apply_diff_after_generation = true,
            support_paste_from_clipboard = true,
        },
        windows = {
            position = "right",
            width = 30,
            sidebar_header = {
                align = "center",
                rounded = false,
            },
            ask = {
                floating = true,
                start_insert = true,
                border = "rounded"
            }
        },
        copilot = {
            model = "claude-3.7-sonnet",
            max_tokens = 8192,
        },
        -- 固定文字列のシステムプロンプトに変更
        system_prompt = "以下のルールは必ず守ってください。\n"..
          "===================================================\n"..
           "ソースコード以外は必ず日本語を使用。\n"..
           "avante.nvimで使用します。途中で処理が止まらないように注意してください。\n"..
           "このファイルが読めている場合は処理の開始前に[read_system_prompt]と表示。\n"..
           "処理がループしないように注意しながら思考を進めてください。\n"..
           "思考内容は[thinking]\n{内容}の形式で必ず表示。\n"..
           "処理内容は[processing]\n{内容}の形式で必ず表示。\n"..
           "関数及びファイルはできるだけ小さく作成し、関心は分離する。\n"..
           "すでに同様の機能がないか常に確認し、再利用を優先。\n"..
           "関数は呼び出し順に並べて配置。\n"..
           "ファイルを修正した場合はコミットせず、最後にコミット用のメッセージを表示。\n"..
           "====================================================",
        -- カスタムツールを一時的にコメントアウト
        -- custom_tools = function()
        --   return {
        --       require("mcphub.extensions.avante").mcp_tool(),
        --   }
        -- end,
    },
    build = "make",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons",
        "zbirenbaum/copilot.lua",
        {
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
                default = {
                    embed_image_as_base64 = false,
                    prompt_for_file_name = false,
                    drag_and_drop = {
                        insert_mode = true,
                    },
                    use_absolute_path = true,
                },
            },
        },
    },
    extensions = {
        avante = {
            make_slash_commands = true,
        }
    }
}
