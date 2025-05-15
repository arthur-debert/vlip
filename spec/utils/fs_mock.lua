-- fs_mock.lua - Filesystem mocking utilities for testing
-- luacheck: globals io os
local fs_mock = {}

-- Create a mock filesystem state
local mock_state = {
  files = {},         -- Table to store mock file contents
  directories = {},   -- Table to track directories
  symlinks = {},      -- Table to track symlinks
  debug_mode = false, -- Debug mode flag
  operation_log = {}  -- Log of operations for debugging
}

-- Reset the mock filesystem
function fs_mock.reset()
  mock_state.files = {}
  mock_state.directories = {}
  mock_state.symlinks = {}
  mock_state.operation_log = {}
  -- Don't reset debug_mode
end

-- Debug logging
local function debug_log(message)
  if mock_state.debug_mode then
    print("[MOCK DEBUG] " .. message)
  end
  table.insert(mock_state.operation_log, message)
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
    debug_log("io.open called with path: " .. path .. ", mode: " .. mode)

    if mode == "r" then
      if not mock_state.files[path] and not mock_state.symlinks[path] then
        debug_log("File not found: " .. path)
        return nil
      end

      local target_path = path
      if mock_state.symlinks[path] then
        target_path = mock_state.symlinks[path]
        debug_log("Following symlink: " .. path .. " -> " .. target_path)
        -- If the target doesn't exist, return nil (broken symlink)
        if not mock_state.files[target_path] then
          debug_log("Broken symlink detected: target doesn't exist")
          return nil
        end
      end

      debug_log("Reading file: " .. target_path)
      return {
        read = function(_, format)
          debug_log("Reading with format: " .. format)
          if format == "*all" then
            return mock_state.files[target_path]
          else
            -- Simple line reading implementation
            return mock_state.files[target_path]:match("([^\n]*)\n?")
          end
        end,
        close = function()
          debug_log("Closing file: " .. target_path)
          return true
        end
      }
    elseif mode == "w" then
      -- Ensure parent directory exists
      local dir = path:match("(.+)/[^/]+$")
      if dir and not mock_state.directories[dir] then
        debug_log("Auto-creating parent directory: " .. dir)
        mock_state.directories[dir] = true
      end

      debug_log("Opening file for writing: " .. path)
      return {
        write = function(_, content)
          debug_log("Writing content to file: " .. path)
          mock_state.files[path] = content
          return true
        end,
        close = function()
          debug_log("Closing file after write: " .. path)
          return true
        end
      }
    end
  end

  -- Replace io.popen
  io.popen = function(command)
    debug_log("io.popen called with command: " .. command)

    -- Handle directory listing with ls -1
    local dir_pattern = command:match("^ls%s+%-1%s+\"?([^\"]+)\"?%s+2>/dev/null$")
    if dir_pattern then
      local dir = dir_pattern:gsub("%*%.lua", "")
      debug_log("Directory listing for: " .. dir)
      local results = {}

      -- Ensure consistent behavior by normalizing the directory path
      -- Add trailing slash if needed
      if not dir:match("/$") then
        dir = dir .. "/"
      end

      -- Handle pattern matching more accurately
      local pattern = "^" .. dir:gsub("%-", "%%-") .. "([^/]+)%.lua$"

      for path, _ in pairs(mock_state.files) do
        if path:match(pattern) then
          debug_log("Found file: " .. path)
          table.insert(results, path)
        end
      end

      for dst, _ in pairs(mock_state.symlinks) do
        if dst:match(pattern) then
          debug_log("Found symlink: " .. dst)
          table.insert(results, dst)
        end
      end

      debug_log("Directory listing found " .. #results .. " items")
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
    local symlink_check = command:match("^ls%s+%-l%s+\"?([^\"]+)\"?%s+2>/dev/null$")
    if symlink_check then
      debug_log("Symlink check for: " .. symlink_check)

      if mock_state.symlinks[symlink_check] then
        local target = mock_state.symlinks[symlink_check]
        debug_log("Is a symlink pointing to: " .. target)
        return {
          read = function()
            return "lrwxrwxrwx ... -> " .. target
          end,
          close = function() return true end
        }
      elseif mock_state.files[symlink_check] then
        debug_log("Is a regular file")
        return {
          read = function()
            return "-rw-r--r-- ... " .. symlink_check
          end,
          close = function() return true end
        }
      else
        debug_log("File/symlink not found")
        return {
          read = function() return "" end,
          close = function() return true end
        }
      end
    end

    -- Handle file existence checking with ls
    local file_check = command:match("^ls%s+\"?([^\"]+)\"?%s+2>/dev/null$")
    if file_check then
      debug_log("File existence check for: " .. file_check)

      if mock_state.files[file_check] or mock_state.symlinks[file_check] then
        debug_log("File exists: " .. file_check)
        return {
          read = function() return file_check end,
          close = function() return true end
        }
      else
        debug_log("File doesn't exist: " .. file_check)
      end
    end

    -- Default empty response
    debug_log("Command not recognized, returning empty response")
    return {
      lines = function() return function() return nil end end,
      read = function() return "" end,
      close = function() return true end
    }
  end

  -- Replace os.execute
  os.execute = function(command)
    debug_log("os.execute called with command: " .. command)

    -- Handle directory creation
    local mkdir = command:match("^mkdir%s+%-p%s+\"?([^\"]+)\"?$")
    if mkdir then
      debug_log("Creating directory: " .. mkdir)
      mock_state.directories[mkdir] = true
      return 0
    end

    -- Handle symlink creation
    local src, dst = command:match("^ln%s+%-sf%s+\"?([^\"]+)\"?%s+\"?([^\"]+)\"?$")
    if src and dst then
      debug_log("Creating symlink: " .. dst .. " -> " .. src)
      mock_state.symlinks[dst] = src
      return 0
    end

    -- Handle file removal
    local remove = command:match("^rm%s+\"?([^\"]+)\"?$")
    if remove then
      debug_log("Removing file/symlink: " .. remove)

      local was_removed = false
      if mock_state.files[remove] then
        mock_state.files[remove] = nil
        was_removed = true
        debug_log("Removed file: " .. remove)
      end

      if mock_state.symlinks[remove] then
        mock_state.symlinks[remove] = nil
        was_removed = true
        debug_log("Removed symlink: " .. remove)
      end

      if was_removed then
        return 0
      else
        debug_log("File/symlink not found for removal: " .. remove)
        -- Still return success to mimic real rm behavior
        return 0
      end
    end

    debug_log("Command not recognized, returning error code")
    return 1
  end
end

-- Teardown the mocks
function fs_mock.teardown()
  -- Restore original functions
  io.open = fs_mock._original.io_open
  io.popen = fs_mock._original.io_popen
  os.execute = fs_mock._original.os_execute

  debug_log("Teardown complete - mocks restored")
end

-- Enable debug mode
function fs_mock.enable_debug()
  mock_state.debug_mode = true
  print("[MOCK] Debug mode enabled")
end

-- Disable debug mode
function fs_mock.disable_debug()
  mock_state.debug_mode = false
end

-- Get operation log
function fs_mock.get_log()
  return mock_state.operation_log
end

-- Dump the current state
function fs_mock.dump_state()
  print("--- Mock Filesystem State ---")
  print("Files:")
  for path, content in pairs(mock_state.files) do
    print("  " .. path .. " (" .. #content .. " bytes)")
  end
  print("Directories:")
  for dir, _ in pairs(mock_state.directories) do
    print("  " .. dir)
  end
  print("Symlinks:")
  for link, target in pairs(mock_state.symlinks) do
    print("  " .. link .. " -> " .. target)
  end
  print("---------------------------")
end

-- Helper functions to manipulate the mock state
function fs_mock.set_file(path, content)
  debug_log("Setting file: " .. path)
  mock_state.files[path] = content
end

function fs_mock.set_directory(path)
  debug_log("Setting directory: " .. path)
  mock_state.directories[path] = true
end

function fs_mock.set_symlink(src, dst)
  debug_log("Setting symlink: " .. dst .. " -> " .. src)
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

-- Expose internal state for testing
function fs_mock._get_mock_state()
  return mock_state
end

return fs_mock
