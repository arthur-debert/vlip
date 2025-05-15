-- Test file to verify enhanced fs_mock functionality
-- Run with: busted spec/test_enhanced_fs_mock_spec.lua

local utils = require("spec.utils")
local fs_mock = require("spec.utils.fs_mock")

describe("Enhanced fs_mock tests", function()
    after_each(function()
        -- Teardown filesystem mocking
        utils.teardown_fixture()
    end)

    it("should track operations in the log", function()
        -- Setup
        fs_mock.setup()
        fs_mock.reset()

        -- Enable debug mode to see the output
        fs_mock.enable_debug()

        -- Perform some operations
        fs_mock.set_file("/test/file.txt", "Hello, world!")
        fs_mock.set_directory("/test/dir")
        fs_mock.set_symlink("/test/file.txt", "/test/link.txt")

        -- Check operation log
        local log = fs_mock.get_operations()
        assert.is_true(#log > 0, "Operation log should not be empty")

        -- Get filtered operations by type
        local set_file_ops = fs_mock.get_operations("set_file")
        local set_dir_ops = fs_mock.get_operations("set_directory")
        local set_symlink_ops = fs_mock.get_operations("set_symlink")

        -- Verify specific operations were logged
        assert.is_true(#set_file_ops > 0, "set_file operations should be tracked")
        assert.is_true(#set_dir_ops > 0, "set_directory operations should be tracked")
        assert.is_true(#set_symlink_ops > 0, "set_symlink operations should be tracked")

        -- Verify operation details
        for _, op in ipairs(set_file_ops) do
            assert.equals("set_file", op.type)
            assert.is_not_nil(op.details.path)
            assert.is_not_nil(op.details.size)
        end

        for _, op in ipairs(set_dir_ops) do
            assert.equals("set_directory", op.type)
            assert.is_not_nil(op.details.path)
        end

        for _, op in ipairs(set_symlink_ops) do
            assert.equals("set_symlink", op.type)
            assert.is_not_nil(op.details.path)
            assert.is_not_nil(op.details.target)
        end

        -- Test the dump_operations function (visually check output)
        fs_mock.dump_operations(10)

        -- Cleanup
        fs_mock.disable_debug()
        fs_mock.teardown()
    end)

    it("should correctly handle broken symlinks", function()
        -- Setup
        fs_mock.setup()
        fs_mock.reset()

        -- Create a symlink to a non-existent file
        fs_mock.set_symlink("/non/existent/target.txt", "/test/broken_link.txt")

        -- Try to open the symlink (should fail since target doesn't exist)
        local file = io.open("/test/broken_link.txt", "r")
        assert.is_nil(file, "Opening broken symlink should return nil")

        -- Verify symlink state
        assert.equals("/non/existent/target.txt", fs_mock.get_symlink("/test/broken_link.txt"))

        -- Verify target doesn't exist
        assert.is_false(fs_mock.file_exists("/non/existent/target.txt"))

        -- Cleanup
        fs_mock.teardown()
    end)

    it("should handle symlink detection with ls -l correctly", function()
        -- Setup
        fs_mock.setup()
        fs_mock.reset()

        -- Create a regular file and a symlink
        fs_mock.set_file("/test/real_file.txt", "Regular file content")
        fs_mock.set_symlink("/test/real_file.txt", "/test/link_file.txt")

        -- Use io.popen to check if file is a symlink
        local handle = io.popen("ls -l /test/real_file.txt 2>/dev/null")
        local output = handle:read("*all")
        handle:close()

        -- Regular file should not have "->"
        assert.is_nil(output:match("->"), "Regular file shouldn't be shown as symlink")

        -- Now check the symlink
        handle = io.popen("ls -l /test/link_file.txt 2>/dev/null")
        output = handle:read("*all")
        handle:close()

        -- Symlink should have "->"
        assert.is_not_nil(output:match("->"), "Symlink should be shown with ->")
        assert.is_not_nil(output:match("/test/real_file.txt"), "Symlink should point to correct target")

        -- Cleanup
        fs_mock.teardown()
    end)

    it("should handle directory listing with trailing slashes consistently", function()
        -- Setup
        fs_mock.setup()
        fs_mock.reset()

        -- Create some files
        fs_mock.set_file("/dir/file1.lua", "File 1")
        fs_mock.set_file("/dir/file2.lua", "File 2")
        fs_mock.set_symlink("/dir/file3.lua", "/dir/link.lua")

        -- List with trailing slash
        local handle1 = io.popen("ls -1 /dir/*.lua 2>/dev/null")
        local files1 = {}
        for file in handle1:lines() do
            table.insert(files1, file)
        end
        handle1:close()

        -- List without trailing slash
        local handle2 = io.popen("ls -1 /dir*.lua 2>/dev/null")
        local files2 = {}
        for file in handle2:lines() do
            table.insert(files2, file)
        end
        handle2:close()

        -- We should get consistent behavior
        assert.equals(3, #files1, "Should find 3 files with trailing slash")
        assert.equals(3, #files2, "Should find 3 files without trailing slash")

        -- Cleanup
        fs_mock.teardown()
    end)

    it("should expose internal state for testing", function()
        -- Setup
        fs_mock.setup()
        fs_mock.reset()

        -- Create test data
        fs_mock.set_file("/test/file1.txt", "File 1 content")
        fs_mock.set_directory("/test/dir1")
        fs_mock.set_symlink("/target.txt", "/test/link1.txt")

        -- Get internal state
        local state = fs_mock._get_mock_state()

        -- Verify state contains expected data
        assert.equals("File 1 content", state.files["/test/file1.txt"])
        assert.is_true(state.directories["/test/dir1"])
        assert.equals("/target.txt", state.symlinks["/test/link1.txt"])

        -- Cleanup
        fs_mock.teardown()
    end)

    it("should dump state for debugging", function()
        -- Setup
        fs_mock.setup()
        fs_mock.reset()

        -- Create test data
        fs_mock.set_file("/test/file1.txt", "File 1 content")
        fs_mock.set_directory("/test/dir1")
        fs_mock.set_symlink("/target.txt", "/test/link1.txt")

        -- This is a visual test, just make sure it doesn't error
        fs_mock.dump_state()

        -- Cleanup
        fs_mock.teardown()
    end)
end)
