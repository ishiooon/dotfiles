#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/lib.sh"

main() {
  parse_arguments "$@"

  # Codex の利用制限は直近セッションログから読み、通常表示へ短時間側の残り率だけを反映する。
  run_command sketchybar --set "${NAME:-codex.usage}" label="5h $(read_codex_remaining_percent)"
}

parse_arguments() {
  while (($#)); do
    parse_common_argument "$1" || fail "未対応の引数です: $1"
    shift
  done
}

read_codex_remaining_percent() {
  ruby -rjson -e '
    def remaining_percent(rate_limits)
      used_percent = rate_limits.dig("primary", "used_percent")
      return "--" if used_percent.nil?

      remaining = 100 - used_percent.to_f
      remaining = [[remaining, 0].max, 100].min
      "#{remaining.round}%"
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

        remaining = remaining_percent(rate_limits)
        next if remaining == "--"

        puts remaining
        exit
      end
    end

    puts "--"
  '
}

main "$@"
