-- このファイルはWezTermのペイン変数へ値を渡すOSCシーケンスを生成します。
local M = {}

local BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function M.send(name, value)
  -- 端末へ制御シーケンスを書き込み、WezTermのペイン変数を更新します。
  if not (vim.fn and type(vim.fn.chansend) == "function" and vim.v and vim.v.stderr) then
    return false
  end
  local ok = pcall(vim.fn.chansend, vim.v.stderr, M.sequence(name, value, M.is_tmux()))
  return ok
end

function M.sequence(name, value, in_tmux)
  local body = string.format("\27]1337;SetUserVar=%s=%s\7", name, M.base64_encode(value or ""))
  if in_tmux then
    return string.format("\27Ptmux;\27%s\27\\", body)
  end
  return body
end

function M.base64_encode(value)
  local text = tostring(value or "")
  local encoded = {}
  for index = 1, #text, 3 do
    local first, second, third = text:byte(index, index + 2)
    local padding = second and (third and 0 or 1) or 2
    local combined = first * 65536 + (second or 0) * 256 + (third or 0)
    encoded[#encoded + 1] = M.base64_char(math.floor(combined / 262144) % 64)
    encoded[#encoded + 1] = M.base64_char(math.floor(combined / 4096) % 64)
    encoded[#encoded + 1] = padding == 2 and "=" or M.base64_char(math.floor(combined / 64) % 64)
    encoded[#encoded + 1] = padding >= 1 and "=" or M.base64_char(combined % 64)
  end
  return table.concat(encoded)
end

function M.base64_char(index)
  return BASE64_CHARS:sub(index + 1, index + 1)
end

function M.is_tmux()
  return vim.env and type(vim.env.TMUX) == "string" and vim.env.TMUX ~= ""
end

return M
