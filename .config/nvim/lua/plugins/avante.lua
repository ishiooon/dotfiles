local system_prompt = require("config.system-prompt")
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
        -- auto_approve_tool_permissions = {"replace_in_file", "write_to_file"},
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
        providers = {
            copilot = {
                model = "claude-sonnet-4",
                -- model = "claude-3.7-sonnet",
                -- model = "gpt-4.1",
                -- model= "gemini-2.5-pro",
                extra_request_body = {
                    max_tokens = 1000000,
                },
            },
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

            return system_prompt.base_system_prompt_text .. get_mcp_servers_prompt_info()
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
    },
    extensions = {
        avante = {
            make_slash_commands = true,
        }
    }
}
