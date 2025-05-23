local base_system_prompt_text = "以下のルールは必ず守ってください。\n" ..
                                "===================================================\n" ..
                                "不要になった古いプロンプトは都度縮小してよいです。\n" ..
                                "ソースコード以外は必ず日本語を使用。\n" ..
                                "このファイルが読めている場合は処理の開始前に[read_system_prompt]と表示。\n" ..
                                "mcptoolのfilesystemとsequentialthinkingを必ず使用するため、処理の開始前に使用可能か確認する。\n" ..
                                "関数型プログラミングを基本とし、できる限り純粋関数を作成します。また、既存のソースも可能な限り関数型に書き直します。\n" ..
                                "副作用がある場合は、必ずコメントを追加する\n" ..
                                "基本1ファイルは150行以内、関数は50行以内に収める。\n" ..
                                "とにかく読みやすさを優先し、保守性を担保する。\n" ..
                                "関数及びファイルはできるだけ小さく作成し、関心は分離する。\n" ..
                                "似たの機能がないか常に確認し、共用、再利用できるよう修正し使用する。\n" ..
                                "関連ファイルも確認し、より関心の近いファイルに移動する。\n" ..
                                "関数は呼び出し順に並べて配置。\n" ..
                                "ファイルを修正した場合はコミットせず、最後にコミット用のメッセージを表示。\n" ..
                                "全ての処理が終了した場合は[finished]と表示。\n" ..
                                "====================================================\n"

return {
    "yetone/avante.nvim",
    enabled = true,
    event = "VeryLazy",
    lazy = false,
    version = false,
    opts = {
        provider = "copilot",
        auto_suggestions_provider = "copilot",
        cursor_applying_provider = 'copilot',
        mode = 'agentic',
        behaviour = {
            auto_suggestions = false,
            auto_set_highlight_group = true,
            auto_set_keymaps = true,
            auto_apply_diff_after_generation = true,
            support_paste_from_clipboard = true,
            enable_cursor_planning_mode = true, 
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
            -- model = "gpt-4.1",
            -- model= "gemini-2.5-pro",
            max_tokens = 1000000,
        },
        -- MCPサーバーのプロンプト情報を取得するヘルパー関数
        -- @return string MCPサーバー情報を含むプロンプト文字列、または空文字列
        system_prompt = function()
            local function get_mcp_servers_prompt_info()
                local mcp_servers_info = ""
                -- mcphubモジュールを安全にロード試行 (副作用: モジュールのロード)
                local mcphub_module_loaded, mcphub_module = pcall(require, "mcphub")

                if mcphub_module_loaded and mcphub_module then
                    -- mcphubインスタンスを安全に取得試行
                    local hub_instance_retrieved, hub_instance = pcall(function() return mcphub_module.get_hub_instance() end)
                    if hub_instance_retrieved and hub_instance then
                        -- アクティブなサーバーのプロンプト情報を取得
                        mcp_servers_info = hub_instance:get_active_servers_prompt()
                    end
                end
                return mcp_servers_info
            end

            return base_system_prompt_text .. get_mcp_servers_prompt_info()
        end,
        custom_tools = function()
            -- mcphub.extensions.avante モジュールからmcp_toolを取得 (副作用: モジュールのロード)
            return {
                require("mcphub.extensions.avante").mcp_tool(),
            }
        end,
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


