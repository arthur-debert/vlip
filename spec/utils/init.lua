-- VLIP Test Utilities
-- Main entry point for all test utilities

-- Load the individual utility modules
local fs_mock = require("spec.utils.fs_mock")
local test_utils = require("spec.utils.test_utils")

-- Export all utilities in a single table
local utils = {
  -- Filesystem mocking
  fs_mock = fs_mock,

  -- Test fixture utilities
  setup_fixture = test_utils.setup_fixture,
  teardown_fixture = test_utils.teardown_fixture,
  capture_print = test_utils.capture_print,
  run_workflow = test_utils.run_workflow
}

return utils
