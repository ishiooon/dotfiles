#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/lib.sh"

main() {
  parse_arguments "$@"

  local limits
  local five_hour_remaining
  local weekly_remaining
  local five_hour_reset_at
  local weekly_reset_at
  limits="$(read_codex_remaining_percents)"
  IFS="|" read -r five_hour_remaining weekly_remaining five_hour_reset_at weekly_reset_at <<<"$limits"

  # Codex の利用制限は直近セッションログから読み、通常表示には短時間側の残り率を反映する。
  run_command sketchybar --set "$NAME" label="5h $five_hour_remaining"
  run_command sketchybar --set "$NAME.five_hour" label="5h $five_hour_remaining until $five_hour_reset_at"
  run_command sketchybar --set "$NAME.weekly" label="7d $weekly_remaining until $weekly_reset_at"
  update_popup_drawing
}

parse_arguments() {
  while (($#)); do
    parse_common_argument "$1" || fail "未対応の引数です: $1"
    shift
  done
}

read_codex_remaining_percents() {
  ruby -rjson -e '
    def remaining_percent(rate_limits, key)
      used_percent = rate_limits.dig(key, "used_percent")
      return "--" if used_percent.nil?

      remaining = 100 - used_percent.to_f
      remaining = [[remaining, 0].max, 100].min
      "#{remaining.round}%"
    end

    def reset_datetime(rate_limits, key)
      reset_epoch = rate_limits.dig(key, "resets_at")
      return "--" if reset_epoch.nil?

      Time.at(reset_epoch.to_i).strftime("%m/%d %H:%M")
    end

    session_file = ENV["CODEX_USAGE_SESSION_FILE"]
    sessions_dir = ENV.fetch("CODEX_USAGE_SESSIONS_DIR", File.expand_path("~/.codex/sessions"))

    candidates =
      if session_file && !session_file.empty?
        [session_file]
      elsif Dir.exist?(sessions_dir)
        Dir.glob(File.join(sessions_dir, "**", "*.jsonl")).sort_by { |path| -File.mtime(path).to_f }
      else
        []
      end

    candidates.first(20).each do |path|
      next unless File.file?(path)

      File.readlines(path, chomp: true).reverse_each do |line|
        begin
          rate_limits = JSON.parse(line).dig("payload", "rate_limits")
        rescue JSON::ParserError
          next
        end
        next unless rate_limits.is_a?(Hash)

        five_hour = remaining_percent(rate_limits, "primary")
        weekly = remaining_percent(rate_limits, "secondary")
        next if five_hour == "--" && weekly == "--"

        five_hour_reset = reset_datetime(rate_limits, "primary")
        weekly_reset = reset_datetime(rate_limits, "secondary")
        puts "#{five_hour}|#{weekly}|#{five_hour_reset}|#{weekly_reset}"
        exit
      end
    end

    puts "--|--|--|--"
  '
}

update_popup_drawing() {
  case "${SENDER:-}" in
    mouse.entered)
      close_other_popups "$NAME"
      cancel_popup_close "$NAME"
      # マウスポインターが項目に乗ったときだけ、詳細な利用制限を下に表示する。
      clear_popup_hover_state "$NAME"
      run_command sketchybar --set "$NAME" popup.drawing=on
      ;;
    mouse.exited.global)
      # 詳細 popup へ移動する時間を残すため、閉じる処理を短く遅延させる。
      schedule_popup_close "$NAME"
      ;;
  esac
}

main "$@"
