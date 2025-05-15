-- fs_mock.lua - Filesystem mocking utilities for testing
-- luacheck: globals io os
local fs_mock = {}

-- Create a mock filesystem state
local mock_state = {
  files = {},          -- Table to store mock file contents
  directories = {},    -- Table to track directories
  symlinks = {},       -- Table to track symlinks
}

-- Reset the mock filesystem
function fs_mock.reset()
  mock_state.files = {}
  mock_state.directories = {}
  mock_state.symlinks = {}
end

-- Setup the mocks
function fs_mock.setup()
  -- Save original functions
  fs_mock._original = {
    io_open = io.open,
    io_popen = io.popen,
    os_execute = os.execute
  }
  
  -- Replace io.open
  io.open = function(path, mode)
    if mode == "r" then
      if not mock_state.files[path] and not mock_state.symlinks[path] then
        return nil
      end
      
      local target_path = path
      if mock_state.symlinks[path] then
        target_path = mock_state.symlinks[path]
        -- If the target doesn't exist, return nil (broken symlink)
        if not mock_state.files[target_path] then
          return nil
        end
      end
      
      return {
        read = function(_, format)
          if format == "*all" then
            return mock_state.files[target_path]
          else
            -- Simple line reading implementation
            return mock_state.files[target_path]:match("([^\n]*)\n?")
          end
        end,
        close = function() return true end
      }
    elseif mode == "w" then
      -- Ensure parent directory exists
      local dir = path:match("(.+)/[^/]+$")
      if dir and not mock_state.directories[dir] then
        mock_state.directories[dir] = true
      end
      
      return {
        write = function(_, content)
          mock_state.files[path] = content
          return true
        end,
        close = function() return true end
      }
    end
  end
  
  -- Replace io.popen
  io.popen = function(command)
    -- Handle directory listing with ls -1
    local dir_pattern = command:match("^ls%s+%-1%s+(.+)%s+2>/dev/null$")
    if dir_pattern then
      local dir = dir_pattern:gsub("%*%.lua", "")
      local results = {}
      
      for path, _ in pairs(mock_state.files) do
        if path:match("^" .. dir:gsub("%-", "%%-") .. "([^/]+)%.lua$") then
          table.insert(results, path)
        end
      end
      
      for dst, _ in pairs(mock_state.symlinks) do
        if dst:match("^" .. dir:gsub("%-", "%%-") .. "([^/]+)%.lua$") then
          table.insert(results, dst)
        end
      end
      
      return {
        lines = function()
          local i = 0
          return function()
            i = i + 1
            return results[i]
          end
        end,
        read = function()
          if #results > 0 then
            return table.concat(results, "\n")
          else
            return ""
          end
        end,
        close = function() return true end
      }
    end
    
    -- Handle symlink checking with ls -l
    local symlink_check = command:match("^ls%s+%-l%s+(.+)%s+2>/dev/null$")
    if symlink_check then
      if mock_state.symlinks[symlink_check] then
        return {
          read = function()
            return "lrwxrwxrwx ... -> " .. mock_state.symlinks[symlink_check]
          end,
          close = function() return true end
        }
      elseif mock_state.files[symlink_check] then
        return {
          read = function()
            return "-rw-r--r-- ... " .. symlink_check
          end,
          close = function() return true end
        }
      end
    end
    
    -- Handle file existence checking with ls
    local file_check = command:match("^ls%s+(.+)%s+2>/dev/null$")
    if file_check then
      if mock_state.files[file_check] or mock_state.symlinks[file_check] then
        return {
          read = function() return file_check end,
          close = function() return true end
        }
      end
    end
    
    -- Default empty response
    return {
      lines = function() return function() return nil end end,
      read = function() return "" end,
      close = function() return true end
    }
  end
  
  -- Replace os.execute
  os.execute = function(command)
    -- Handle directory creation
    local mkdir = command:match("^mkdir%s+%-p%s+(.+)$")
    if mkdir then
      mock_state.directories[mkdir] = true
      return 0
    end
    
    -- Handle symlink creation
    local src, dst = command:match("^ln%s+%-sf%s+(.+)%s+(.+)$")
    if src and dst then
      mock_state.symlinks[dst] = src
      return 0
    end
    
    -- Handle file removal
    local remove = command:match("^rm%s+(.+)$")
    if remove then
      mock_state.files[remove] = nil
      mock_state.symlinks[remove] = nil
      return 0
    end
    
    return 1
  end
end

-- Teardown the mocks
function fs_mock.teardown()
  -- Restore original functions
  io.open = fs_mock._original.io_open
  io.popen = fs_mock._original.io_popen
  os.execute = fs_mock._original.os_execute
end

-- Helper functions to manipulate the mock state
function fs_mock.set_file(path, content)
  mock_state.files[path] = content
end

function fs_mock.set_directory(path)
  mock_state.directories[path] = true
end

function fs_mock.set_symlink(src, dst)
  mock_state.symlinks[dst] = src
end

function fs_mock.get_file(path)
  return mock_state.files[path]
end

function fs_mock.get_symlink(path)
  return mock_state.symlinks[path]
end

function fs_mock.file_exists(path)
  return mock_state.files[path] ~= nil or mock_state.symlinks[path] ~= nil
end

function fs_mock.directory_exists(path)
  return mock_state.directories[path] == true
end

return fs_mock