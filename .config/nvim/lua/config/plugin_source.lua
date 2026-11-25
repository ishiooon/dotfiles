local M = {}

-- ファイルシステムを照会し、記載順で見つかった開発版を優先してプラグインの参照先を決める。
function M.resolve(repository, candidates, options)
    local spec = vim.tbl_extend("force", options or {}, {
        repository,
        name = repository:match("[^/]+$"),
    })
    local fs = vim.uv or vim.loop
    if not (fs and fs.fs_stat) then return spec end
    for _, candidate in ipairs(candidates) do
        local directory = vim.fn.expand(candidate)
        local stat = fs.fs_stat(directory)
        if stat and stat.type == "directory" then
            spec[1] = nil
            spec.dir = directory
            break
        end
    end
    return spec
end

return M
