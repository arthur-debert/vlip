-- Tests for the list-enabled command
local utils = require("spec.utils")

describe("vlip list-enabled command", function()
  local core

  setup(function()
    package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
    core = require("vlip.core")
  end)

  after_each(function()
    utils.teardown_fixture()
  end)

  describe("core.list_enabled()", function()
    it("should list all enabled plugins", function()
      -- Setup test fixture with multiple plugins, some enabled
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1",     content = "-- Plugin 1 content" },
          { name = "plugin2",     content = "-- Plugin 2 content" },
          { name = "plugin3.lua", content = "-- Plugin 3 content" }
        },
        plugins = {
          { name = "plugin1",     is_link = true, links_to = "/mock/config/lua/plugins-available/plugin1.lua" },
          { name = "plugin3.lua", is_link = true, links_to = "/mock/config/lua/plugins-available/plugin3.lua" }
        }
      })

      -- Capture print output
      local printer = utils.capture_print()

      -- Call the function with test_mode=true
      core.list_enabled(true)

      -- Restore print
      printer.restore()

      -- Verify output
      assert.is_true(#printer.output >= 3) -- Header + 2 plugins
      assert.equals("Enabled plugins:", printer.output[1])

      -- Check that only enabled plugins are listed
      local plugins_found = {
        plugin1 = false,
        plugin2 = false,
        plugin3 = false
      }

      for i = 2, #printer.output do
        local name = printer.output[i]:match("%s+(.+)$")
        if name then
          plugins_found[name] = true
        end
      end

      assert.is_true(plugins_found.plugin1)
      assert.is_false(plugins_found.plugin2)
      assert.is_true(plugins_found.plugin3)
    end)

    it("should handle no enabled plugins", function()
      -- Setup test fixture with available plugins but none enabled
      utils.setup_fixture({
        plugins_available = {
          { name = "plugin1", content = "-- Plugin 1 content" },
          { name = "plugin2", content = "-- Plugin 2 content" }
        }
      })

      -- Capture print output
      local printer = utils.capture_print()

      -- Call the function with test_mode=true
      core.list_enabled(true)

      -- Restore print
      printer.restore()

      -- Verify output
      assert.equals(1, #printer.output) -- Only the header
      assert.equals("Enabled plugins:", printer.output[1])
    end)
  end)
end)
