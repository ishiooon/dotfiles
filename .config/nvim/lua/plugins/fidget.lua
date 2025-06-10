----------------------------------------------
-- シンプルな通知プラグイン
-- 現在LSPの進捗と1時間ごとの通知を表示している
----------------------------------------------
return{
    {
        "j-hui/fidget.nvim",
        opts = {
            progress = {
                display = {
                  progress_icon = { pattern = 'meter', period = 1 },
                },
            },
        },
        config = function()
            require("fidget").setup({
                progress = {
                    display = {
                        progress_icon = { pattern = 'meter', period = 1 },
                    },
                },
            })
            
            -- 時刻とスピナーを表示する関数
            local function show_time_notification()
                local current_time = os.date("%Y-%m-%d %H:%M:%S")
                local fidget = require("fidget")
                
                -- 時刻とスピナーを表示
                fidget.notify("現在時刻: " .. current_time, vim.log.levels.INFO, {
                    annote = "時計",
                    key = "hourly_time_display"
                })
                
                -- 10秒後に通知をクリア（副作用あり）
                vim.defer_fn(function()
                    fidget.notify(nil, nil, { key = "hourly_time_display" })
                end, 10000) -- 10秒 = 10000ミリ秒
            end
            
            -- 次の正時（00分00秒）までの秒数を計算する純粋関数
            local function calculate_seconds_to_next_hour()
                local now = os.date("*t")
                local minutes_remaining = 60 - now.min
                local seconds_remaining = 60 - now.sec
                
                -- 既に00分00秒の場合は0秒後に実行
                if now.min == 0 and now.sec == 0 then
                    return 0
                end
                
                return (minutes_remaining - 1) * 60 + seconds_remaining
            end
            
            -- 正時に実行し、その後1時間ごとに繰り返すタイマー設定
            local function setup_hourly_timer()
                local seconds_to_next_hour = calculate_seconds_to_next_hour()
                
                -- 次の正時まで待機するタイマー
                local initial_timer = vim.loop.new_timer()
                if initial_timer then
                    initial_timer:start(seconds_to_next_hour * 1000, 0, vim.schedule_wrap(function()
                        -- 正時に実行
                        show_time_notification()
                        
                        -- 1時間ごとの繰り返しタイマーを設定
                        local recurring_timer = vim.loop.new_timer()
                        if recurring_timer then
                            recurring_timer:start(3600000, 3600000, vim.schedule_wrap(show_time_notification))
                        end
                        
                        -- 初期タイマーを閉じる
                        initial_timer:close()
                    end))
                end
            end
            
            -- タイマー設定を開始
            setup_hourly_timer()
        end,
    }
}
