-- Tests for fs_mock.lua
-- Run with: busted spec/utils/fs_mock_spec.lua

local utils = require("spec.utils")

describe("Filesystem Mock", function()
  before_each(function()
    utils.fs_mock.setup()
    utils.fs_mock.reset()
  end)

  after_each(function()
    utils.fs_mock.teardown()
  end)

  describe("File operations", function()
    it("should handle file existence checking", function()
      -- Setup
      utils.fs_mock.set_file("/test/file.txt", "Hello, world!")

      -- Test file_exists function
      local function file_exists(path)
        local file = io.open(path, "r")
        if file then
          file:close()
          return true
        end
        return false
      end

      -- Assert
      assert.is_true(file_exists("/test/file.txt"))
      assert.is_false(file_exists("/test/nonexistent.txt"))
    end)

    it("should handle file reading", function()
      -- Setup
      utils.fs_mock.set_file("/test/file.txt", "Hello, world!")

      -- Test read_file function
      local function read_file(path)
        local file = io.open(path, "r")
        if not file then return nil end
        local content = file:read("*all")
        file:close()
        return content
      end

      -- Assert
      assert.equals("Hello, world!", read_file("/test/file.txt"))
      assert.is_nil(read_file("/test/nonexistent.txt"))
    end)

    it("should handle file writing", function()
      -- Test write_file function
      local function write_file(path, content)
        local file = io.open(path, "w")
        if not file then return false end
        file:write(content)
        file:close()
        return true
      end

      -- Act
      local result = write_file("/test/new_file.txt", "New content")

      -- Assert
      assert.is_true(result)
      assert.equals("New content", utils.fs_mock.get_file("/test/new_file.txt"))
    end)
  end)

  describe("Directory operations", function()
    it("should handle directory creation", function()
      -- Test mkdir function
      local function mkdir(path)
        os.execute("mkdir -p " .. path)
      end

      -- Act
      mkdir("/test/new_dir")

      -- Assert
      assert.is_true(utils.fs_mock.directory_exists("/test/new_dir"))
    end)

    it("should handle directory listing", function()
      -- Setup
      utils.fs_mock.set_file("/test/dir/file1.lua", "-- File 1")
      utils.fs_mock.set_file("/test/dir/file2.lua", "-- File 2")
      utils.fs_mock.set_directory("/test/dir")

      -- Test get_files function
      local function get_files(dir)
        local files = {}
        local handle = io.popen("ls -1 " .. dir .. "/*.lua 2>/dev/null")
        if handle then
          for file in handle:lines() do
            table.insert(files, file)
          end
          handle:close()
        end
        return files
      end

      -- Act
      local result = get_files("/test/dir")

      -- Assert
      assert.equals(2, #result)
      -- The order of files might not be guaranteed, so we check both possibilities
      assert.is_true(result[1] == "/test/dir/file1.lua" or result[1] == "/test/dir/file2.lua")
      assert.is_true(result[2] == "/test/dir/file1.lua" or result[2] == "/test/dir/file2.lua")
      assert.is_not_equal(result[1], result[2]) -- Make sure they're different
    end)
  end)

  describe("Symlink operations", function()
    it("should handle symlink creation", function()
      -- Setup
      utils.fs_mock.set_file("/test/original.lua", "-- Original file")

      -- Test create_symlink function
      local function create_symlink(src, dst)
        os.execute("ln -sf " .. src .. " " .. dst)
      end

      -- Act
      create_symlink("/test/original.lua", "/test/link.lua")

      -- Assert
      assert.equals("/test/original.lua", utils.fs_mock.get_symlink("/test/link.lua"))
    end)

    it("should handle symlink checking", function()
      -- Setup
      utils.fs_mock.set_file("/test/original.lua", "-- Original file")
      utils.fs_mock.set_symlink("/test/original.lua", "/test/link.lua")

      -- Test is_symlink function
      local function is_symlink(path)
        local handle = io.popen("ls -l " .. path .. " 2>/dev/null")
        local output = handle:read("*all")
        handle:close()
        return output:match("->") ~= nil
      end

      -- Assert
      assert.is_true(is_symlink("/test/link.lua"))
      assert.is_false(is_symlink("/test/original.lua"))
    end)

    it("should handle file reading through symlinks", function()
      -- Setup
      utils.fs_mock.set_file("/test/original.lua", "-- Original content")
      utils.fs_mock.set_symlink("/test/original.lua", "/test/link.lua")

      -- Test read_file function
      local function read_file(path)
        local file = io.open(path, "r")
        if not file then return nil end
        local content = file:read("*all")
        file:close()
        return content
      end

      -- Assert
      assert.equals("-- Original content", read_file("/test/link.lua"))
    end)

    it("should handle broken symlinks", function()
      -- Setup - create a symlink to a non-existent file
      utils.fs_mock.set_symlink("/test/nonexistent.lua", "/test/broken_link.lua")

      -- Test read_file function
      local function read_file(path)
        local file = io.open(path, "r")
        if not file then return nil end
        local content = file:read("*all")
        file:close()
        return content
      end

      -- Assert
      assert.is_nil(read_file("/test/broken_link.lua"))
    end)
  end)

  describe("File removal", function()
    it("should handle file removal", function()
      -- Setup
      utils.fs_mock.set_file("/test/to_remove.lua", "-- Will be removed")

      -- Test remove_file function
      local function remove_file(path)
        os.execute("rm " .. path)
      end

      -- Act
      remove_file("/test/to_remove.lua")

      -- Assert
      assert.is_false(utils.fs_mock.file_exists("/test/to_remove.lua"))
    end)

    it("should handle symlink removal", function()
      -- Setup
      utils.fs_mock.set_file("/test/original.lua", "-- Original file")
      utils.fs_mock.set_symlink("/test/original.lua", "/test/link.lua")

      -- Test remove_file function
      local function remove_file(path)
        os.execute("rm " .. path)
      end

      -- Act
      remove_file("/test/link.lua")

      -- Assert
      assert.is_false(utils.fs_mock.file_exists("/test/link.lua"))
      assert.is_true(utils.fs_mock.file_exists("/test/original.lua"))
    end)
  end)

  describe("VLIP-specific operations", function()
    it("should handle plugin listing with ls -1", function()
      -- Setup
      utils.fs_mock.set_file("/config/lua/plugins-available/plugin1.lua", "-- Plugin 1")
      utils.fs_mock.set_file("/config/lua/plugins-available/plugin2.lua", "-- Plugin 2")
      utils.fs_mock.set_directory("/config/lua/plugins-available")

      -- Test get_available_plugins function (similar to VLIP's implementation)
      local function get_available_plugins()
        local plugins = {}
        local handle = io.popen("ls -1 /config/lua/plugins-available/*.lua 2>/dev/null")
        if handle then
          for file in handle:lines() do
            local name = file:match("([^/]+)$")
            table.insert(plugins, name)
          end
          handle:close()
        end
        return plugins
      end

      -- Act
      local result = get_available_plugins()

      -- Assert
      assert.equals(2, #result)
      -- Check that both plugins are in the result
      local has_plugin1 = false
      local has_plugin2 = false
      for _, name in ipairs(result) do
        if name == "plugin1.lua" then has_plugin1 = true end
        if name == "plugin2.lua" then has_plugin2 = true end
      end
      assert.is_true(has_plugin1)
      assert.is_true(has_plugin2)
    end)

    it("should handle plugin enabling with symlinks", function()
      -- Setup
      utils.fs_mock.set_file("/config/lua/plugins-available/test.lua", "-- Test plugin")
      utils.fs_mock.set_directory("/config/lua/plugins")
      utils.fs_mock.set_directory("/config/lua/plugins-available")

      -- Test enable function (similar to VLIP's implementation)
      local function enable_plugin(name)
        local plugin_file = name
        if not name:match("%.lua$") then
          plugin_file = name .. ".lua"
        end

        local src = "/config/lua/plugins-available/" .. plugin_file
        local dst = "/config/lua/plugins/" .. plugin_file

        local function file_exists(path)
          local file = io.open(path, "r")
          if file then
            file:close()
            return true
          end
          return false
        end

        if file_exists(src) then
          if not file_exists(dst) then
            os.execute("ln -sf " .. src .. " " .. dst)
            return true
          end
        end
        return false
      end

      -- Act
      local result = enable_plugin("test")

      -- Assert
      assert.is_true(result)
      assert.equals("/config/lua/plugins-available/test.lua",
        utils.fs_mock.get_symlink("/config/lua/plugins/test.lua"))
    end)
  end)
end)
