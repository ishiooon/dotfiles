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
        -- providers-setting
        copilot = {
            model = "claude-3.7-sonnet",
            -- model = "gpt-4o",
            -- model = "gpt-4o-mini",
            max_tokens = 8192,
        },
        -- other config
        -- The system_prompt type supports both a string and a function that returns a string. Using a function here allows dynamically updating the prompt with mcphub
        system_prompt = function()
            local base_prompt = "以下のルールは必ず守ってください。\n"..
              "===================================================\n"..
               "ソースコード以外は日本語を使用します。\n"..
               "あなたは優秀なコーディングアシスタントです。\n"..
               "関数及びファイルはできるだけ小さく作成し、依存関係に気を使います\n"..
               "sequentialthinking使用を使用して処理を進めます\n"..
               "ファイル修正はfilesystemを使用して行います\n"..
               "ファイルを修正した場合はコミットしませんが、最後にコミット用のメッセージを表示します\n"..
              "====================================================\n"..
                "以下のMCPサーバー機能を理解し、効果的に活用します。\n"..
                "tool使用の前後で使用するtool名と内容を必ず表示します。\n\n"
            
            -- mcphubが存在するか確認してからプロンプトを取得
            local mcp_prompt = ""
            local ok, mcphub = pcall(require, "mcphub")
            if ok and mcphub then
                local hub = mcphub.get_hub_instance()
                if hub then
                    mcp_prompt = hub:get_active_servers_prompt()
                end
            end
            
            return base_prompt .. mcp_prompt
        end,   
      -- The custom_tools type supports both a list and a function that returns a list. Using a function here prevents requiring mcphub before it's loaded
        custom_tools = function()
          return {
              require("mcphub.extensions.avante").mcp_tool(),
          }
        end,
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        --- The below dependencies are optional,
        "nvim-tree/nvim-web-devicons",
        "zbirenbaum/copilot.lua",  -- for providers='copilot'
        {
            -- support for image pasting
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
                -- recommended settings
                default = {
                    embed_image_as_base64 = false,
                    prompt_for_file_name = false,
                    drag_and_drop = {
                        insert_mode = true,
                    },
                    -- required for Windows users
                    use_absolute_path = true,
                },
            },
        },
    },
    extensions = {
        avante = {
            make_slash_commands = true, -- make /slash commands from MCP server prompts
        }
    }
}
