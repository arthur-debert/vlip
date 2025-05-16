-- Mock path module for testing
local mock_path = {}

function mock_path.normalize(path_str)
  return path_str
end

function mock_path.exists(path_str)
  -- Always return true for testing, but use path_str to avoid luacheck warning
  return path_str ~= nil
end

function mock_path.abs(path_str)
  return path_str
end

-- Add mock join function to match the utils/path interface
function mock_path.join(...)
  local segments = { ... }
  local result = segments[1] or ""

  for i = 2, #segments do
    if segments[i] then
      if result:sub(-1) ~= "/" and segments[i]:sub(1, 1) ~= "/" then
        result = result .. "/" .. segments[i]
      else
        result = result .. segments[i]
      end
    end
  end

  return result
end

return mock_path
