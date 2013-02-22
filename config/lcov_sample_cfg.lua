local M = {}

--------------------------------------------------------------------
-- This allows you to run coverage over a subset of files.
-- This is an array of strings which are complete filenames.
-- Use the shortcut "exe" to specify the "--exe" filename.  If
-- the shortcut "exe" does not exist the "--exe" file is not
-- covered (i.e. only other files covered).
--------------------------------------------------------------------
M.fileFilter = { "exe", "pluginUtils.lua" }

--------------------------------------------------------------------
-- true indicates M.fileFilter contains FULL paths and that the filter process
-- should also use full paths.  This is useful if duplicate file names exist.
-- false (just file name) is the default.
--------------------------------------------------------------------
--M.filterFullPaths = true



--------------------------------------------------------------------
-- These are optional override to the existing command line options.
-- If they are commented out the command line options will be used.
--------------------------------------------------------------------
--M.bAppend   = false         -- "--append" option
--M.bCon      = false         -- "--con" option
--M.bDbg      = false         -- "--dbg" option
--M.sDir      = "/tmp"        -- "--dir" option
--M.bDoAll    = false         -- "--doall" option
--M.bGen      = false         -- "--gen" option
M.bListDeps = true         -- "--listdeps" option

--------------------------------------------------------------------
-- These are optional values DO NOT override existing command line options.
--------------------------------------------------------------------
--M.sExe    = "../src/file.lua" -- "--exe" path/filename
--M.tArgs   = {"-m", "../other.lua", "-t","../test.lua"} -- "--exe" args

M.sExe    = "../src/audioMgr.lua"            -- "--exe" path/filename
M.tArgs   = {"-m",
             "../cfg/test/AudioMgr_SrcMatrix_Test.lua",
             "-t",
             "../test/audioMgrTest.lua"}            -- "--exe" args

return M

