#!/usr/bin/env lua

-- Script to update imports in spec files from legacy paths to new module paths

local function update_imports(file)
    local f = io.open(file, "r")
    if not f then
        print("Error: Could not open file " .. file)
        return
    end

    local content = f:read("*all")
    f:close()

    -- Replace legacy imports with new module paths
    local replaced = content:gsub('require%("vlip%.cli"%)', 'require("vlip.adapters.cli")')
        :gsub('require%("vlip%.config"%)', 'require("vlip.core.config")')

    if content ~= replaced then
        local f_out = io.open(file, "w")
        if not f_out then
            print("Error: Could not write to file " .. file)
            return
        end

        f_out:write(replaced)
        f_out:close()
        print("Updated imports in: " .. file)
    end
end

-- Find all spec files
local handle = io.popen("find spec -name '*.lua'")
local result = handle:read("*a")
handle:close()

for file in result:gmatch("[^\r\n]+") do
    update_imports(file)
end

print("Import update complete!")
