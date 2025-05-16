-- Filesystem operations for vlip
local path_utils = require("vlip.utils.path")
local M = {}

-- Function to check if a file exists
function M.file_exists(path)
    local file = io.open(path_utils.normalize(path), "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Function to create a directory if it doesn't exist
function M.mkdir(path)
    return os.execute("mkdir -p \"" .. path_utils.normalize(path) .. "\"")
end

-- Function to read a file
function M.read_file(path)
    local file = io.open(path_utils.normalize(path), "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

-- Function to write to a file
function M.write_file(path, content)
    local file = io.open(path_utils.normalize(path), "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

-- Function to create a symlink
function M.create_symlink(src, dst)
    return os.execute("ln -sf \"" .. path_utils.normalize(src) .. "\" \"" .. path_utils.normalize(dst) .. "\"")
end

-- Function to remove a file
function M.remove_file(path)
    return os.execute("rm \"" .. path_utils.normalize(path) .. "\"")
end

-- Function to list files matching a pattern
function M.list_files(dir, pattern)
    local files = {}
    local cmd = "ls -1 " .. path_utils.normalize(dir) .. "/" .. (pattern or "*") .. " 2>/dev/null"
    local handle = io.popen(cmd)

    if handle then
        for file in handle:lines() do
            table.insert(files, file:match("([^/]+)$"))
        end
        handle:close()
    end

    return files
end

-- Function to check if a path is a symlink
function M.is_symlink(path)
    local handle = io.popen("ls -l " .. path_utils.normalize(path) .. " 2>/dev/null")
    local output = handle:read("*all")
    handle:close()

    return output:match("->") ~= nil
end

return M
