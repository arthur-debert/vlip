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

return mock_path