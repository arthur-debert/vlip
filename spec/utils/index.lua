-- Index file for the utils module
-- This makes all utilities available through a single require("spec.utils")

local fs_mock = require("spec.utils.fs_mock")
local test_utils = require("spec.utils.test_utils")

local utils = {}

-- Re-export fs_mock
utils.fs_mock = fs_mock

-- Re-export test_utils functions
utils.setup_fixture = test_utils.setup_fixture
utils.teardown_fixture = test_utils.teardown_fixture
utils.capture_print = test_utils.capture_print
utils.run_workflow = test_utils.run_workflow

return utils
