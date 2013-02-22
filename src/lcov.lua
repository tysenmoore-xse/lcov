--[[
---------------------------------------------------------------------------
            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                        Version 2, December 2004

     Copyright (C) 2013 Tysen Moore

     Everyone is permitted to copy and distribute verbatim or modified
     copies of this license document, and changing it is allowed as long
     as the name is changed.

                DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
       TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

      0. You just DO WHAT THE FUCK YOU WANT TO.
---------------------------------------------------------------------------
]]

local helpText = [[
---------------------------------------------------------------------------
Overiew:
=================

This is a simple code coverage script.  This can be especially useful in Lua
since many errors are not found until the code executes.  This implementation
was written to gather stats in an embedded system so I purposely wrote the
code with the smallest number of dependencies and as a single file for
simple portability.

You can run this script by adding the necessary function calls to start and
stop, OR you can execute this script and pass in the script to code coverage
as an argument.

This script will take the actual execution and determine the overall coverage.
This script will better determine the actual coverage based on what Lua told us.
For example, Lua will indicate a "repeat" statement is called by indicating the
"until" line that the loop was executed, not the starting "repeat".  Multiline
comments and stings are similar. Require statements don't show any execution,
etc.  This script cleans all this up (and more) to show better and more accurate
coverage stats.

By default the coverage file stats are stored in /tmp/origFilename.lcno
and the coverage results are generated/saved to /tmp/origFilename where
lines are commented out with:
`---- |`  == for lines that are commented or are all whitespace
`--XX |`  == for lines that Lua identified as executed.
`--xx |`  == for lines that were determined executed by lcov (multiline, etc)
Each results file will contain stats at the end of the file with: total comment/
whitespace lines, total lines, total possible to execute, lines executed,
percentage of lines executed, etc.

Requirements:
=============
- lfs -- required for final results file generation, but not the stats gathering
- bit -- optional, gives better memory usage, BUT is not required
- DO NOT change this scripts file name, this is checked to ensure we do not
  profile this script.

License:
========
WTFPL

Module Example:
===============
~~~
 local lcov = require "lcov"
 ...
 lcov.setResultsDir( "/fs/mmc0/" ) -- default is "/tmp/"
 lcov.start()                      -- start coverage
 ...                               -- execute something
 lcov.stop()                       -- stop coverage
 lcov.generateResults()            -- generate results files
                                   -- can optionally pass in true to have the
                                      results go to the console.
~~~

lcov.lua arguments:
===================

### --append
append new results to exiting .lcno file.  By default this is off and
existing files are truncated. If an error occurs a new file is created.
(-exe, n/a for -gen) (--cfg file option (boolean) bAppend)

### --con
dump generated results (-gen output) to console
(--cfg file option (boolean) bCon)

### --cfg [file]
Loads a Lua module/config file to define fileFilters or override most command
line settings.  Command line options after this declaration will override the
cfg file settings.  Command line options prior to this declaration will be
overriden by the cfg file options. This also has the addeed benefit of being
able to execute code early if needed (clear files, etc)

#### Cfg file only options:

##### fileFilter
array of strings which are each file to track for coverage.  Use the shortcut
"exe" to specify the "--exe" filename. If the shortcut "exe" does not exist the
"--exe" file is not covered (i.e. only other files covered). This overriden with
then --doall option.

##### filterFullPaths
(boolean) true means fileFilter contains full paths for each file false means
only the filename is used for the fileFilter.
(default is false)

### --dbg
debug output when using -gen
(--cfg file option (boolean) bDbg)

### --dir [path]
path to store the coverage results (-exe, n/a for -gen)
(--cfg file option (string) sDir)

### --doall
if set, performs coverage on ALL executed files.  [covers "require" files, off
by default]. This overrides --cfg.fileFilter option.
(--cfg file option (boolean) bDoAll)

### --exe [file] [args]
if "-dir" is not used the -f is not needed. Also, all params after the "file"
are treated as arguments to the file to execute.  Therefore, this must be the
last arguments on the command line.
(--cfg file option (string) bExe -- path/filename,
(table) tArgs -- list of arguments)

### --gen
generate the results file to the path and use the lcno coverage file(s) in
path (-dir).  If -gen and -exe are specified AND NOT -doall then only a single
files .lcno is processed NOT all in the target directory.
(--cfg file option (boolean) bGen)

### --listdeps
Will list all dependencies (files seen) but only when used with --exe.  This
option can be useful in setting up the fileFilter.
(--cfg file option (boolean) bListDeps)


Executable Example:
===================

`lua lcov.lua somethingToExec.lua arg1 arg2`

(This passes arg1, arg2 to somethingToExec.lua as arguments.
 NOTE: only generates the coverage stats in .lcno)

or

`lua lcov.lua -dir /fs/usb0 -exe somethingToExec.lua arg1 arg2`

(Same as previous except store stats to /fs/usb0.
 NOTE: only generates the coverage stats in .lcno)

or

`lua lcov.lua -dir /fs/usb0 -gen -exe somethingToExec.lua arg1 arg2`

(Same as previous except after running it will generate the results files)

or

`lua lcov.lua -gen -dbg -exe .\lcov_test.lua`

(Test example)

or

`lua lcov.lua -gen`

(Will take existing stats from /tmp/*.lcno and generate result files)


Optional Source Code Instrumentation:
=====================================
There is a special markup language you can add to the code to improve
then results of lcov.  This section describes the special code/format.

On a line of code you can add `--> lcov: [CMD][PARAMS]` for special processing.
NOTE: You can has any amount of whitespace after "-->" and after "lcov:".
      There should be no whitespace between [CMD] and [PARAMS].  Any whitespace
      after [PARAMS] will terminate the [PARAMS].

CMD = "ref"
-----------
This is used to refer (or set a reference) to another line that you know lcov
will catch as executed. This is useful when you know lcov will not catch this
line, BUT it will catch the execution of a different line.
The [PARAMS] portion is an offset +/-/= the current line number.  The "=" can
be useful for global variable/references definitions that are not caught.

Example:
~~~
 local var     --> lcov: ref+1
 var = {}
~~~

In this example, "var={}" is marked executed from Lua, but "local var" is not.
The reference comment will show "local var" as executed.  For example,
~~~
 --xx|     local var     --> lcov: ref+1
 --XX|     var = {}
~~~

You can also have:  `local var --> lcov: ref+1 -- can have comment here`
               or:  `local var -- can have comment here  --> lcov: ref+1`

CMD = "ref" (block)
-------------------
You can use the "ref" syntax an build on that the ability to assign a reference
line to complete block.  Use the original syntax for the start of the block then
add ",start" (no spaces).  To end the block use "ref=end".  These assignments
can be in a tailing comment or as a standalone comment.
~~~
--> lcov: ref=1,start
local VAR1
local VAR2, VAR3, VAR4
local VAR5
--> lcov: ref=end
~~~
~~~
----| --> lcov: ref=1,start
--XX| local VAR1
--xx| local VAR2, VAR3, VAR4
--xx| local VAR5
----| --> lcov: ref=end
~~~

CMD = "ignore"
--------------
This is used to ignore a block of lines.  If the line within this block
has not executed it will be marked as "--xx".  The params are "=start"/"=end".
For example,
~~~
--> lcov: ignore=start
local VAR1
local VAR2,       VAR3,            VAR4
local VAR5
--> lcov: ignore=end
~~~
NOTE: This can be on the start of a line.
~~~
----| --> lcov: ignore=start
--XX| local VAR1
--xx| local VAR2,       VAR3,            VAR4
--xx| local VAR5
----| --> lcov: ignore=end
~~~

Known Limitations:
==================
1. Currently only tested in Lua 5.1.4
2. The following syntax is not handled properly:

~~~
     | local execLines2
 --XX| =
 --XX| {
 --XX|     "something"
 --XX| }
~~~

### Written by: tmoore
------------------------------------------------------------------------------]]

-- ------------------
--  Requires
-- ------------------

local isOk, lfs = pcall(require, "lfs")
if isOk == false then
    lfs = nil -- otherwise this is a string error
end

local isOk, bit = pcall(require, "bit")
if isOk == false then
    bit = nil -- otherwise this is a string error
end

-- ------------------
--  Constants
-- ------------------

local APP_VER           = "2.6"

local LCOV_EXT          = "lcno"
local LCOV_MARKER       = "--XX"    -- truly executed
local LCOV_MARKER2      = "--xx"    -- determined executed (multiline, etc)

local EXEC_TRUE         = 1 -- truly executed
local EXEC_CALC         = 2 -- calculated executed (multiline, etc)
local COMMENT_LINE      = 3 -- comment line or blank line

-- Used in tracking the end processing logic
local BLOCK_IF          = 1
local BLOCK_FOR         = 2
local BLOCK_WHILE       = 3
local BLOCK_REPEAT      = 4
local BLOCK_FUNCTION    = 5
local BLOCK_ELSE        = 6    -- only standalone else

-- ------------------
--  Globals
-- ------------------

local M                 = {}  -- methods for the module API

local g_bAppendStats    = false  -- --append option
local g_localStoreDir   = "/tmp/"--"c:\\temp\\"  -- -dir to override
local g_fileToExec      = nil    -- --exe to set
local g_bRunGen         = false  -- based on --gen
local g_dumpToConsole   = false  -- --con option
local g_bCoverAllFiles  = false  -- --doall option sets this to true
local g_bListAllDeps    = false  -- --listdeps option

local g_fileFilter      = nil    -- list of files to use
local g_fullPathFilter  = false  -- files in g_fileFilter must be full path

local g_fileList        = {}     -- "set" of files executed

local g_debug           = false

-- if running standalone executable this will be the filename
-- of the executed lua script (lcov.lua).  This is used to
-- make sure we skip coveraging this file.
local g_execFilename      = ""

local g_filesSeenList     = {}  -- list of ALL files seen


-- ---------------------------------------------
--  Forward Declarations
-- ---------------------------------------------
local parseCfgFile


-- -------------------------------------------------------------
--  dbg
--
--  Debug print routine.  This will display when using "--dbg"
--
--  @tparam   (string)  ...  ....what to display
-- -------------------------------------------------------------
local function dbg(...)
    if g_debug == true then
       print( unpack(arg) )
    end

end -- dbg

-- -------------------------------------------------------------
--  adjustArgs
--
--  Called to modify the arg order so they are correct for the
--  caller when running as a standalone executable.
--
--  @tparam   (string)  fileToExec ....file being executed
--  @tparam   (string)  tArgs      ....copy of command line args
-- -------------------------------------------------------------
local function adjustArgs( fileToExec, tArgs )

    g_fileToExec = fileToExec -- full path

    local filename = g_fileToExec
    if g_fullPathFilter == false then
        filename = string.match(g_fileToExec, ".*[/\\@](.*)$")
    end

    if g_fileFilter == nil then
        g_fileFilter = {}
        -- We only do the "--exe" file
        g_fileFilter[filename] = true

    elseif g_fileFilter.exe then
        g_fileFilter.exe           = nil
        g_fileFilter[filename] = true
    end

    if tArgs then
        -- Adjust the args to remove the lcov specific args.
        -- This way when the program to profile is executed
        -- the args will look the way it expects, just in
        -- case it inspects the args.

        -- copy the early args
        for i=0,-6,-1 do
            if arg[i] == nil then
                break
            end
            tArgs[i] = arg[i]
        end

        arg = tArgs -- throws bogus lint warning
    end

end -- adjustArgs

-- -------------------------------------------------------------
--  covHandler
--
--  Handler for the Lua Debug call
--
--  @tparam   (string)  callType ...."call"|"return"
--  @tparam   (string)  linenum  ....line number that executed
-- -------------------------------------------------------------
local function covHandler( callType, linenum )

    -- - - - - - - - - - - - - - - - - - - - - - - - - - - -
    local function store( source, linenum, linedefined, skipWrite )

        if bit == nil then
            -- The internal tracking is a less efficient memory model but
            -- holds fewer dependencies.  With the bit module we can
            -- improve this.
            if g_fileList[source].lines[linenum] == nil then
                -- new execution
                g_fileList[source].lines[linenum] = 1
                if skipWrite == nil then
                    -- filelineNum:functionLineNum(0==main)
                    g_fileList[source].fp:write(linenum, ":", linedefined, "\n")
                    g_fileList[source].fp:flush()
                end

            end -- else, already there, NOP
        else
            -- Memory space is improved, but is performance?
            -- Need more testing to know this.
            local bytePos = math.floor(linenum/32)+1 -- cannot index [0]
            local bitPos  = math.mod(linenum, 32)
            local bitMask = bit.lshift(1,bitPos)
            if bit.band(g_fileList[source].lines[bytePos], bitMask) == 0 then
                -- new execution
                g_fileList[source].lines[bytePos] = bit.bor(g_fileList[source].lines[bytePos], bitMask)
                if skipWrite == nil then
                    -- filelineNum:functionLineNum(0==main)
                    g_fileList[source].fp:write(linenum, ":", linedefined, "\n")
                    g_fileList[source].fp:flush()
                end
            end
        end
    end -- store
    -- - - - - - - - - - - - - - - - - - - - - - - - - - - -

    local dbgInfo = debug.getinfo(2, "Sn")
    if dbgInfo == nil then
        return
    end

    -- store the coverage
    if g_fileList[dbgInfo.source] == nil then
        -- nothing yet, so create it

        -- This is the FULL path of the filename
        local fullFilename = string.match(dbgInfo.source, "^@(.*)")
        -- This is JUST the filename
        local origFilename = string.match(fullFilename, ".*[/\\@](.*)$")

        if origFilename == g_execFilename then
            -- don't bother with coverage for this (lcov.lua) file
            return
        end

        -- Track which files we've seen
        g_filesSeenList[fullFilename] = true

        if g_fileFilter and g_bCoverAllFiles == false then

            -- Check our filter and see if it should be covered
            if (g_fullPathFilter == true  and g_fileFilter[fullFilename] == nil) or
               (g_fullPathFilter == false and g_fileFilter[origFilename] == nil) then
                -- File should not be covered
                return
            end
        end

        local destFilename = g_localStoreDir..origFilename.."."..LCOV_EXT

        local oldStatsFp    = nil
        local openMode      = "w"
        local origLineCount = 0
        if g_bAppendStats then
            oldStatsFp = io.open(destFilename, "r")
            if oldStatsFp then
                -- previous file exists
                openMode = "a"

                origFilename  = oldStatsFp:read("*l") -- line1    = orig filename
                origLineCount = oldStatsFp:read("*l") -- line2    = num lines in file

                if origFilename ~= dbgInfo.source then
                    print(string.format("\nWARNING: %s contains a different originating file name: %s ~= %s, creating new file",
                                        destFilename, origFilename, dbgInfo.source))
                    openMode = "w"
                end
            end
        end

        local newFp = io.open(destFilename, openMode)
        if newFp == nil then
            if oldStatsFp then
                oldStatsFp:close()
            end
            return
        end

        --print("DEST>", destFilename)
        --print("FILE>", fullFilename)
        local fp = io.open(fullFilename, "r")
        if fp then

            -- Determine the current source files line count
            local lineCount = 0
            for line in fp:lines() do
                lineCount = lineCount + 1
            end
            fp:close()
            --print("LINES>", lineCount)

            if openMode == "a" and tonumber(origLineCount) ~= lineCount then
                print(string.format("\nWARNING: Line counts differ in: old:%s(%d) ~= current:%s(%d), creating new file",
                                    origFilename,origLineCount, dbgInfo.source,lineCount))
                openMode = "w"
                newFp:close()
                if oldStatsFp then
                    oldStatsFp:close()
                    oldStatsFp = nil
                end

                -- reopen with write permissions
                newFp = io.open(destFilename, openMode)
                if newFp == nil then
                    if oldStatsFp then
                        oldStatsFp:close()
                    end
                    return
                end
            end

            if openMode ~= "a" then
                -- start the file
                newFp:write(dbgInfo.source.."\n")
                newFp:write(lineCount, "\n")
            end

            g_fileList[dbgInfo.source]       = {}
            g_fileList[dbgInfo.source].fp    = newFp
            g_fileList[dbgInfo.source].file  = destFilename
            g_fileList[dbgInfo.source].count = lineCount
            g_fileList[dbgInfo.source].lines = {}

            if bit then
                -- More efficient when the bit module exists
                local maxBytes = math.ceil(lineCount/32)+1 --cannot index [0]
                for i=1,maxBytes do
                    g_fileList[dbgInfo.source].lines[i] = 0
                end
            end

            if oldStatsFp and openMode == "a" then
                -- Load the old results
                local sTmp = ""
                local lineNum, functLineNum
                local linesLoaded = 0
                while true do
                    sTmp = oldStatsFp:read("*l")
                    if not sTmp then
                        break
                    end

                    linesLoaded = linesLoaded + 1

                    -- lineNum:functLineNum
                    lineNum, functLineNum = string.match(sTmp, "(%d*):(%d*)")
                    if lineNum and functLineNum then
                        store( dbgInfo.source, tonumber(linenum), tonumber(functLineNum), "skipWrite" )
                    end
                end
                print(string.format("Loaded: %s executed lines\n\n", linesLoaded))
            end

        else
            -- unable to open the file, skip it
            print("\nERROR: Unable to open:", fullFilename)
            newFp:close()
            if oldStatsFp then
                oldStatsFp:close()
            end
            return
        end

        if oldStatsFp then
            oldStatsFp:close()
        end

    end -- initial creation

    --print("covHandler", dbgInfo.source, linenum, callType,
    --      dbgInfo.linedefined,dbgInfo.what, dbgInfo.name, dbgInfo.namewhat)

    store( dbgInfo.source, linenum, dbgInfo.linedefined )

end -- covHandler

-- -------------------------------------------------------------
--  covGenerateFileResults
--
--  Do the work to generate the results for a single file.
--
--  @tparam   (string)  covFilename ....file to convert
--  @tparam   (string)  destDir     ....destination directory for
--                                      the results file
--
--  @treturn  (table) { total          = maxLines,
--                      commented      = commentCount,
--                      actualCode     = totalExec,
--                      totalExec      = execCount,
--                      percentCovered = (execCount/totalExec)*100 }
-- -------------------------------------------------------------
local function covGenerateFileResults( covFilename, destDir )

    -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    -- - - - - - - - - - - - - - - - - - - - - - -
    -- lineHas
    --
    -- Checks to see if the line has a specific
    -- command.  The routine takes the place of
    -- a few pattern matches to do the same thing
    -- so this should be faster and easier to
    -- understand.  One patter match was not enough
    -- to cover all cases.
    --
    -- str..............string to process
    -- key..............keyword to look for (if, for, etc)
    -- allowPreChar.....if non-nil will allow this
    --                  char before the key.
    -- allowPostChar....if non-nil will allow this
    --                  char after the key.
    -- - - - - - - - - - - - - - - - - - - - - - -
    local function lineHas( str, key, allowPreChar, allowPostChar )

    	if str == key then
    		return( true )
    	end

    	local startPos, endPos = string.find(str, key)

    	if startPos == nil then
    		return( false )
    	end

    	local preChar  = ""
    	local postChar = ""
    	if startPos ~= 1 then
    		preChar = string.sub(str, startPos-1, startPos-1)
    	end
    	if endPos ~= 1 then
    		postChar = string.sub(str, endPos+1, endPos+1)
    	end

    	if (preChar == ""  or preChar  == " " or preChar  == "\t" or
           (allowPreChar and preChar == allowPreChar))
           and
    	   (postChar == ""  or postChar == " " or postChar == "\t" or
    	   (allowPostChar and postChar == allowPostChar) or
            postChar == "\n") then
    	   return( true )
    	end

    	return( false )

    end -- lineHas

    -- - - - - - - - - - - - - - - - - - - - - - -
    -- removeStrings
    --
    -- Remove quoted strings from an existing
    -- string.  Then leaves an empty quoted
    -- string in its place.  Inner quotes and
    -- apostrophe strings will be removed.  The
    -- goal is to strip the strings of content
    -- that may mess up other logic.
    --
    -- For example,
    -- "local s = "if/then/else"" ==> "local s = """
    --
    -- NOTE: Order of precedence: '', [[]], ""
    --
    -- str....string to process
    -- opChr...when initially called it should be nil
    -- - - - - - - - - - - - - - - - - - - - - - -
    local function removeStrings( str, opChr )

        -- TODO: Could use some work, but should work for most cases

        local count    = 0
        local pos
        local retStr   = ""
        local startPos = 1
        local endPos   = 1

        if opChr == nil then
            opChr = "\'"
        end

        -- Remove escaped quotes
        string.gsub(str, string.format('(\\%s)', opChr), function (s) return "" end)

        while true do
            local _, pos = string.find(str, opChr, startPos)
            if pos == nil then
                --print("DONE",str, opChr, startPos)
                break
            end
            --print("pos", pos)

            count = count + 1
            if count % 2 == 0 then
                startPos = pos + 1
                retStr   = retStr..opChr
                --print("startPos", startPos, retStr)
            else
                retStr   = retStr..string.sub(str, startPos, pos)
                --print("STR", startPos, pos, retStr)

                startPos = pos + 1
                endPos   = startPos
            end
        end -- forever while

        if count % 2 == 0 then
            --print("END", string.sub(str, startPos))
            retStr = retStr..string.sub(str, startPos)
        end

        if opChr == "\'" then
            -- only do this once
            local multiStartPos, _ = string.find(retStr, "%[%[")
            local multiEndPos, _   = string.find(retStr, "%]%]")
            if multiStartPos and multiEndPos then
                -- create passing string to match the original,
                -- the goal is to remove all contents that may
                -- mess up other logic.
                local pad = string.sub(retStr, multiStartPos, multiEndPos)
                pad    = string.gsub(pad, "[^\n]", " ")
                retStr = string.sub(retStr, 1, multiStartPos+1)..pad..string.sub(retStr, multiEndPos)
            end
        end

        if opChr == "\'" then
            -- Now work on quotes
            retStr = removeStrings(retStr, "\"")
        end

        return( retStr )

    end -- removeStrings

    -- - - - - - - - - - - - - - - - - - - - - - -
    -- split
    --
    -- Called to split a string based on some
    -- regular expression string
    --
    -- Return: Array of values split accordingly
    -- - - - - - - - - - - - - - - - - - - - - - -
    local function split(keyStr, delimiter)
        local result = { }
        local from   = 1
        local delim_from, delim_to = string.find( keyStr, delimiter, from  )
        while delim_from do
            table.insert( result, string.sub( keyStr, from , delim_from-1 ) )
            from  = delim_to + 1
            delim_from, delim_to = string.find( keyStr, delimiter, from  )
        end
        table.insert( result, string.sub( keyStr, from  ) )
        return result
    end -- split

    -- - - - - - - - - - - - - - - - - - - - - - -
    -- trimComments
    --
    -- Removes comments from a line.
    --
    -- str       ....string to process
    -- commentPos....optional position if already known
    -- - - - - - - - - - - - - - - - - - - - - - -
    local function trimComments( str, commentPos )

        if commentPos == nil then
            commentPos, _ = string.find(str, "%-%-")
        end
        if commentPos == nil then
            return str
        end

        return  string.sub(str, 1, commentPos-1) -- remove line comment

    end -- trimComments

    -- - - - - - - - - - - - - - - - - - - - - - -
    -- write
    --
    -- Write to file AND console
    --
    -- desfFp     ....destination file pointer
    -- str        ....string to write out
    -- - - - - - - - - - - - - - - - - - - - - - -
    local function write( destFp, str )
        destFp:write(str.."\n")
        print(str)
    end -- write
    -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    local line             = ""
    local destFilename     = ""
    local origFilename     = ""
        local maxLines         = 0
    local linesStr         = ""
    local execLines        = {}    -- keyvalue pairs of "lineNum" = EXEC_xxx
    local refLines         = {}    -- reference list: "linenum" = offset (+1,-1,=1)
    local blockRefLines    = {}    -- block reference lines: "start linenum" = {offset (+1,-1,=1), end linenum}
    local blockRefPend     = {}    -- block reference pending list
    local ignoreBlock      = {}    -- block ignore list: "start linenum" = end linenum
    local ignoreBlockPend  = {}    -- block ignore pending list
    local execCount        = 0
    local execLoaded       = 0
    local commentCount     = 0
    local isNopLine        = false  -- comment or empty line
    local commentPos       = 0
    local tailCommentStr   = ""     -- possible trailing comment
    local trimmedLine      = ""

    local multiEndPos      = 0
    local multiStartPos    = 0
    local multiLines       = {}
    local multiLineExec    = false
    local multiLineComment = false
    local mulitLineWhile   = 0     -- non-zero is line for the while

    local pendingRightBrace= 0     -- if non-zero we are in an object definition
    local startingLeftBrace= 0     -- line number with the left brace which we are looking to close

    local tFunctLineNum    = {}
    local functLineNum     = 0
    local lineNum          = 0

    local endTracking      = {}

    local srcLine, destLine

    if destDir == nil then
        destDir = g_localStoreDir
    end

    local covFp = io.open( covFilename, "r" )
    if covFp == nil then
        print("ERROR: Unable to open:", covFilename)
        return
    end

    origFilename = covFp:read("*l") -- line1    = orig filename
    maxLines     = covFp:read("*l") -- line2    = num lines in file

    if maxLines == nil or origFilename == nil then
        print("ERROR: Too few lines in:", covFilename)
        covFp:close()
        return
    end

    maxLines     = tonumber(maxLines)
    origFilename = string.match(origFilename, "^@(.*)")

    -- line3..n = lineNum:functLineNum
    -- Build a list of lines executed
    local sTmp = ""
    while true do
        sTmp = covFp:read("*l")
        if not sTmp then
            break
        end

        -- lineNum:functLineNum
        lineNum, functLineNum = string.match(sTmp, "(%d*):(%d*)")
        -- Check for nil in execLines[lineNum] in case of duplicates
        -- within the file--there should not be, but have seen it in
        -- the past or if a user copied results manually.  This will
        -- screw up the execLoaded.  The numbers work out correctly
        -- in the end, but the lcov stat shows a negative value, but
        -- the other stats will be correct.
        if lineNum and lineNum ~= "" and execLines[lineNum] == nil then
            execLines[lineNum]  = EXEC_TRUE
            execLoaded          = execLoaded + 1
        end

        -- Track actual function execution because the
        -- "function name()" line will show executed
        -- from "lineNum:0".  We will later remove these
        -- incorrect executions.
        if functLineNum and functLineNum ~= "" and functLineNum ~= "0" then
            if tFunctLineNum[tostring(functLineNum)] then
                tFunctLineNum[tostring(functLineNum)] = tFunctLineNum[tostring(functLineNum)] + 1
            else
                tFunctLineNum[tostring(functLineNum)] = 1
            end
        end
    end
    covFp:close()

    print("origFilename", origFilename)
    dbg(  "Loaded Execution List Size:", execLoaded)

    local destFilename = ""

    -- Check for only a filename, no path, or do we need to strip the path
    if string.match(origFilename, ".*([/\\]).*") then
        destFilename = destDir..string.match(origFilename, ".*[/\\@](.*)$")
    else
        -- Only a filename, no path
        destFilename = destDir..origFilename
    end

    print("destFilename", destFilename)

    --******************************************************
    -- NOTE: Three phases needed due to the way some lines
    --       are marked by Lua as executed.  For example,
    --       a function is marked on the end so without
    --       two phases the start of the function could
    --       no be marked.  Also, if the code has special
    --       lcov markup commands we need to process some of
    --       them AFTER all other code is done.
    --******************************************************

    -------------------------------------------
    -- PASS 1: Now store/determine the results
    -------------------------------------------
    local srcFp = io.open( origFilename, "r" )
    if srcFp == nil then
        print("ERROR: Unable to open phase 1:", origFilename)
        return
    end

    local bIsLineSet  = false
    local curLineNum  = 0
    local curLineStr  = ""
    local lineCont    = false  -- true we have multi-line execution
    local lineContEnd = ""
    local cleanStr    = ""

    for srcLine in srcFp:lines() do ------------------------------

        --print(curLineNum, srcLine)

        bIsLineSet  = false
        curLineNum  = curLineNum + 1
        isNopLine   = false
        trimmedLine = nil

        --------------------------------------------------------
        -- now cleanup a version with no strings but could have comments
        --------------------------------------------------------
        cleanStr = removeStrings( srcLine )
        --------------------------------------------------------

        --print("  ", cleanStr)

        -- Attempt to determine if we have a multiline comment situation
        multiStartPos, _ = string.find(cleanStr, "%[%[")
        multiEndPos, _   = string.find(cleanStr, "%]%]")
        if multiStartPos or multiEndPos or #multiLines ~= 0 then
            table.insert(multiLines, srcLine)
            if multiEndPos then
                srcLine  = table.concat(multiLines, "\n")
                -- remove text in [[]] to avoid logic problems
                cleanStr = removeStrings( srcLine )
                multiLines = split(cleanStr, "\n")
            else
                if multiStartPos then
                    cleanStr = string.sub(srcLine, 1, multiStartPos+2)
                else
                    cleanStr = ""
                end
            end
            if execLines[tostring(curLineNum)] then
                -- Multiline statement with [[ ]] must have executed
                multiLineExec = true
            end
        end

        tailCommentStr = nil

        -- Look for empty lines and adjust stats
        commentPos, _ = string.find(cleanStr, "%-%-")
        if #multiLines ~= 0 then

            if multiStartPos and commentPos and commentPos+2 == multiStartPos then
                -- MUST be "--[[" type comment
                multiLineComment = true
                multiLineExec    = false
            end

        elseif #cleanStr == 0 or commentPos == 1 then
            -- Empty line or comment on this line at position 1
            isNopLine = true

            -- ckeck for lcov command
            local lcovCmdStr = string.match(cleanStr, ".*%-%->%s-lcov:%s*(.*)")
            if lcovCmdStr then
                -- process this lcov command
                tailCommentStr = cleanStr
            end

        elseif commentPos then
            tailCommentStr  = string.sub(cleanStr, commentPos)
            trimmedLine     = trimComments(cleanStr, commentPos) -- remove comment
            local tmpLine   = string.match(trimmedLine, "[ \t\n\r]*(.*)") -- trim leading whitespace
            if #tmpLine == 0 then
                -- only a comment on the line
                isNopLine = true
            end
        end

        --------------------------------------------------------
        -- now cleanup a version with no comments and no strings
        --------------------------------------------------------
        cleanStr = trimComments(cleanStr)
        --------------------------------------------------------

        if #ignoreBlockPend ~= 0 then
            -- We must be in an ignored block
            bIsLineSet = true
        end


        if bIsLineSet == false and
           string.find(cleanStr, "else") then

            trimmedLine = cleanStr:match( "^%s*(.-)%s*$" )
            if trimmedLine == "else" then
                -- a standalone else will not show execution
                -- So this needs special tracking
                bIsLineSet = true
                table.insert(endTracking, {curLineNum, BLOCK_ELSE} )
            end
        end

        -- Check for the start of a loop (for, if, ...)
        if bIsLineSet       == false and
           multiLineComment == false and
           multiLineExec    == false and
           isNopLine        == false and
           #multiLines      == 0     then

           local bIsFunction = lineHas(cleanStr, "function", nil, "(")

           -- here we remove all string data and remove comments
           -- this way none of the string are confused in strings
           if bIsFunction and lineHas(cleanStr, "end", nil, ")") then
               -- e.g. print(string.gsub(str, string.format("([^\\]%s)", '"'), function (n) itCnt = itCnt+1 end) )
               -- NOP, function is inline, so it should
               -- already have the correct exec status
               bIsLineSet  = true
               dbg("INLINE FUNCT:", curLineNum, cleanStr, execLines[tostring(curLineNum)])

           else

               local blockType = nil
               if bIsFunction then
                   blockType = BLOCK_FUNCTION
               elseif lineHas(cleanStr, "if",       nil, "(") then
                   blockType = BLOCK_IF
               elseif lineHas(cleanStr, "for") then
                   blockType = BLOCK_FOR
               elseif lineHas(cleanStr, "while",    nil, "(") then
                   blockType = BLOCK_WHILE
               elseif lineHas(cleanStr, "repeat") then
                   blockType = BLOCK_REPEAT
               end

               if blockType then
                   -- Track the start of a loop requiring an end

                   if bIsFunction then
                       if tFunctLineNum[tostring(curLineNum)] then
                           execLines[tostring(curLineNum)] = EXEC_TRUE
                       else
                           execLines[tostring(curLineNum)] = nil
                       end

                       local _, functEndPos   = string.find(cleanStr, "function")
                       local sPostFunct       = string.sub(cleanStr, functEndPos)
                       local _, leftParenCnt  = string.gsub(sPostFunct, "%(", "(")
                       local _, rightParenCnt = string.gsub(sPostFunct, "%)", ")")

                       -- should be the start of a function declaration,
                       -- check to see if this line contains the start/end
                       -- paren, if not it must span multiple lines.  In this
                       -- case the first line shows execution, but the following
                       -- lines do not.
                       if leftParenCnt > rightParenCnt then
                           dbg("MULTILINE DEF FUNCT:", curLineNum, cleanStr, execLines[tostring(curLineNum)], leftParenCnt,  rightParenCnt)
                           lineCont    = true
                           lineContEnd = ")"
                       end

                   --else, not a valid loop type
                   end

                   dbg("LOOP START:", curLineNum, blockType, cleanStr, execLines[tostring(curLineNum)])
                   table.insert(endTracking, {curLineNum, blockType} )
               end

           end

           if lineHas(cleanStr, "until", nil, "(") == true then
               -- This is a hack to get the until to be tracked.  This
               -- process banks on the fact that a repeat/end would not
               -- compile so this must match a repeat.
               cleanStr = string.gsub(cleanStr, "until", " end ")
           end

           if bIsLineSet == false and lineHas(cleanStr, "end", nil, ")") == true then
                -- Track the end of a loop and update the execLine status
                local blockObj  = table.remove(endTracking)
                local startLine = blockObj[1]
                local blockType = blockObj[2]

                dbg("LOOP END:", startLine, blockType, execLines[tostring(startLine)], curLineNum, execLines[tostring(curLineNum)], cleanStr)

                -- repeat,   Lua marks the end   (until statement)
                -- while,    Lua marks the start (while statement)
                -- for,      Lua marks the start (for statement)
                -- if,       Lua marks the end   (end statement)
                -- function, Lua marks the start AND end BUT
                --           we check the only the first line because
                --           we manually manage that ourselves based
                --           on tFunctLineNum.
                if blockType == BLOCK_ELSE then
                    -- look for something that has executed within
                    -- the else/end block
                    for i=startLine,curLineNum  do
                        if execLines[tostring(i)] and
                           execLines[tostring(i)] ~= COMMENT_LINE then
                            execLines[tostring(startLine)]  = EXEC_CALC
                            break
                        end
                    end

                    if #endTracking ~= 0 then
                        -- MUST be an if statement that needs processing
                        blockObj  = table.remove(endTracking)
                        startLine = blockObj[1]
                        blockType = blockObj[2]
                    end
                end

                if blockType == BLOCK_FUNCTION then
                    if execLines[tostring(startLine)] then
                        if execLines[tostring(curLineNum)] == nil then
                            execLines[tostring(curLineNum)] = EXEC_CALC -- end
                        end
                    else
                        -- start was not executed, so neither should the end
                        execLines[tostring(curLineNum)] = nil -- end
                    end

                else
                    if execLines[tostring(startLine)] then
                        if execLines[tostring(curLineNum)] == nil then
                            execLines[tostring(curLineNum)] = EXEC_CALC -- end
                        end
                    else
                        if blockType ~= BLOCK_FUNCTION and execLines[tostring(curLineNum)] then
                            if execLines[tostring(startLine)] == nil then
                                execLines[tostring(startLine)]  = EXEC_CALC -- start
                            end
                        else
                            -- start was not executed, so neither should the end
                            execLines[tostring(curLineNum)] = nil -- end
                        end
                    end
                end

            end
        end -- if/while/repeat/function end check

        -- Look for object definitions that span multiple lines
        if bIsLineSet == false and lineCont == false and isNopLine == false then

            local _,leftBraceCnt  = string.gsub(cleanStr, "{", "{")
            local _,rightBraceCnt = string.gsub(cleanStr, "}", "}")

            if pendingRightBrace == 0 and leftBraceCnt ~= 0 then
                -- track the left brace we need to close
                startingLeftBrace = curLineNum
            end

            -- This is how many braces we need to close this
            local rightBracesNeeded = pendingRightBrace+(leftBraceCnt-rightBraceCnt)

            if pendingRightBrace == 1 and rightBracesNeeded == 0 then
                -- We completed the definition with a right brace
                dbg("MULTILINE BRACE DONE:", pendingRightBrace, cleanStr)
                if execLines[tostring(curLineNum)] == nil then
                    -- nor previously marked, so use the same
                    -- tracking as the opening left brace
                    -- Addresses:
                    -- --XX| local g_appSvcObj      = {
                    -- --XX|                             varA = 0,
                    -- --XX|                             VarB = "This is a {test}",
                    --     |                          }
                    execLines[tostring(curLineNum)] = execLines[tostring(startingLeftBrace)]

                elseif execLines[tostring(curLineNum)]        == EXEC_TRUE and
                    execLines[tostring(startingLeftBrace)] == nil then
                    -- The right brace was marked executed while the
                    -- left brace was not, make the left the same
                    -- Addresses:
                    -- --XX|         local anotherVar =
                    --     |         {
                    -- --XX|             1,2,3
                    -- --XX|         }
                    execLines[tostring(startingLeftBrace)] = execLines[tostring(curLineNum)]
                end

                if  execLines[tostring(startingLeftBrace)] ~= nil then
                    -- Mark all line between as the same
                    -- Addresses:
                    -- --XX| local execLines        =
                    -- --XX| {
                    --     |     "something"
                    -- --XX| }
                    --print("FILL IN: ",startingLeftBrace,"to",curLineNum)
                    for i=startingLeftBrace,curLineNum  do
                        execLines[tostring(i)] = execLines[tostring(startingLeftBrace)]
                    end
                end

                startingLeftBrace = 0
            end

            pendingRightBrace = rightBracesNeeded

            if pendingRightBrace ~= 0 then
                dbg("MULTILINE BRACE:", curLineNum, pendingRightBrace, leftBraceCnt, rightBraceCnt, cleanStr)
            end

        end -- multi line brace handling

        if bIsLineSet == false and lineCont == true and isNopLine == false then

            if execLines[tostring(curLineNum)] == nil then
                execLines[tostring(curLineNum)] = EXEC_CALC
            end

            dbg("MULTILINE DONE:", lineContEnd, curLineNum, cleanStr)
            -- look for the end of the loop
            if lineHas(cleanStr, lineContEnd) then
                -- end found
                lineCont = false
                if mulitLineWhile ~= 0 then
                    -- this must be the do of the while on multiple
                    -- lines. Lua will indicate the lines in between
                    -- as executed, but not the while or do
                    -- e.g. while\n itCnt ~= 0 \n do \n ... \n end
                    -- In this example the itCnt shows executed and the
                    -- "..." but not the while, do, or, end
                    dbg("MULTILINE WHILE DO:", mulitLineWhile, curLineNum, cleanStr)
                    execLines[tostring(mulitLineWhile)]  = EXEC_CALC
                    mulitLineWhile = 0
                end
                lineContEnd = ""
            end
        end

        if #multiLines == 0 then
            -- To keep the write logic clean add this to the
            -- table and let it process everything in the same loop
            -- as would be processed for a multiline string.
            table.insert(multiLines, srcLine)
            multiEndPos = -1
        end

        -- Handle: #!/usr/bin/env lua
        -- NOTE: only checks if on FIRST line
        if curLineNum == 1 and  string.find(cleanStr, "^#!.*") == 1 then
            execLines[tostring(curLineNum)]  = EXEC_CALC
        end

        if multiEndPos then

            if multiEndPos ~= -1 then

                if multiLineComment == true then
                    -- must be true multiline (i.e. "--[[")
                    isNopLine = true
                    for i=curLineNum - #multiLines+1, curLineNum do
                        dbg("MULITCOMMENT:", i, #multiLines)
                        execLines[tostring(i)] = COMMENT_LINE
                    end
                elseif multiLineExec == true then
                    -- Multiline statement with [[ ]] must have executed
                    for i=curLineNum - #multiLines+1, curLineNum do
                        dbg("MULTIEXEC:", i, #multiLines, isNopLine)
                        execLines[tostring(i)] = EXEC_CALC
                    end
                    -- last line is marked executed by Lua
                    execLines[tostring(curLineNum)] = EXEC_TRUE
                end
            end

            -- This is the adjusted line number to match "multiLines"
            local loopLineNum = curLineNum - #multiLines+1
            for i,line in ipairs(multiLines) do -----------

                if isNopLine == false then
                    -- Mark the require as executed since this occurred
                    -- during compilation.  This covers a normal "require"
                    -- and a require on a "pcall".
                    if string.match(line, "[%s=]-require[%s%(\"]") or
                       string.match(line, ".*pcall[%s\t]*%([%s\t]*require[%s\t]*,") and
                       execLines[tostring(loopLineNum)] == nil then
                        -- TODO: Check for lines executed after this
                        --       which indicates this was truely executed.
                        execLines[tostring(loopLineNum)] = EXEC_CALC
                    end
                end

                if isNopLine == true then
                    dbg("COMMENT2:", loopLineNum, line)
                    execLines[tostring(loopLineNum)] = COMMENT_LINE

                elseif execLines[tostring(loopLineNum)] or
                       multiLineExec == true then

                    --multiline loop statements (if/then, while/do, for/do)
                    cleanStr = removeStrings(line)
                    cleanStr = trimComments(cleanStr)
                    if lineHas(cleanStr, "if", nil, "(") == true then
                        -- if statement on multiple lines show execution on the first line
                        if lineHas(cleanStr, "then") == false then
                            -- then must be on different line
                            lineCont    = true
                            lineContEnd = "then"
                        end
                    elseif lineHas(cleanStr, "for", nil, "(") == true then
                        -- "for" statement on multiple lines show execution on
                        -- the first line up to the do
                        if lineHas(cleanStr, "do") == false then
                            -- then must be on different line
                            lineCont    = true
                            lineContEnd = "do"
                        end

                    end

                else
                    -- Line did not execute

                    cleanStr = removeStrings(line)
                    cleanStr = trimComments(cleanStr)
                    if lineHas(cleanStr, "while", nil, "(") == true then
                        -- "while" statement on multiple lines show execution
                        -- on the middle line, not the first like the others
                        -- thus we check on the "did not execute" logic
                        if lineHas(cleanStr, "do") == false then
                            -- then must be on different line
                            lineCont       = true
                            lineContEnd    = "do"
                            mulitLineWhile = loopLineNum
                            dbg("MULTILINE WHILE:", mulitLineWhile, cleanStr)
                        end
                    end
                end

                loopLineNum = loopLineNum + 1

            end -- multiLines loop ---------------------

            if #multiLines > 1 then
                --curLineNum = curLineNum + 1
            end

            multiLines       = {}
            multiEndPos      = 0
            multiStartPos    = 0
            multiLineExec    = false
            multiLineComment = false

        end -- multiline processing

        -- lcov Special Syntax
        ------------------------------------------------
        if tailCommentStr then
            -- Check for a special lcov command, for example:
            -- "--> lcov: ref-1"  or ref=1, ref+1
            local lcovCmdStr = string.match(tailCommentStr, ".*%-%->%s-lcov:%s*(.*)")
            if lcovCmdStr then

                local lcovCmd, lcovCmdParam = string.match(lcovCmdStr, "(%a+)(%S*)")

                dbg("LCOV CMD:", lcovCmd, lcovCmdParam, curLineNum)

                -- ref syntax
                ----------------------------------------
                if lcovCmd == "ref" then

                    local blockOp   = nil
                    local operation = string.sub(lcovCmdParam, 1,1)
                    local offsetVal = ""

                    if string.match(lcovCmdParam, "=(%a*)%s*.*") == "end" then
                        blockOp = "end"

                    elseif operation == "=" or operation == "-" or operation == "+" then
                        offsetVal = string.match(lcovCmdParam, "(%d+)", 2)
                        blockOp   = string.match(lcovCmdParam, ",(%a+)%s*.*", 2+#offsetVal)
                    end

                    if blockOp == nil then
                        -- This references this line to another.  This is useful
                        -- when you know lcov will not catch this line, BUT it
                        -- will catch the execution of a different line.  The
                        -- param portion is an offset +/- the current line number.
                        refLines[tostring(curLineNum)] = operation..offsetVal
                    else

                        if blockOp == "start" then
                            table.insert( blockRefPend, { tostring(curLineNum), operation..offsetVal } )
                        elseif blockOp == "end" then
                            local startObj = table.remove( blockRefPend )
                            if startObj then
                                blockRefLines[startObj[1]] = { startObj[2], curLineNum }
                            end
                        end
                    end

                -- ignore syntax
                ----------------------------------------
                elseif lcovCmd == "ignore" then
                    if lcovCmdParam == "=start" then
                        table.insert( ignoreBlockPend, tostring(curLineNum) )
                    elseif lcovCmdParam == "=end" then
                        local sLineNum = table.remove( ignoreBlockPend )
                        if sLineNum then
                            ignoreBlock[sLineNum] = curLineNum
                        end
                    end
                end
            end
        end

    end ------------------------------------------------------
    srcFp:close()

    -------------------------------------------
    -- PASS 2: Process special lcov syntax
    -------------------------------------------
    local function getRefLineNum( refOffsetStr, origLineNumStr )
        local operation, offsetVal = string.match(refOffsetStr, "(%D)(%d)")
        local iRefLineNum = 1
        if operation == "=" then
            -- absolute reference
            return tonumber(offsetVal)
        end
        return tonumber(origLineNumStr)+tonumber(operation..offsetVal)
    end -- getRefLineNum

    local endLineNum  = 0
    local iRefLineNum = 1

    -- Process individual references
    for origLineNumStr, refLineNum in pairs(refLines) do
        local iRefLineNum = getRefLineNum(refLineNum, origLineNumStr)
        if execLines[tostring(iRefLineNum)] and
           execLines[tostring(iRefLineNum)] ~= COMMENT_LINE then
            execLines[origLineNumStr] = EXEC_CALC
        end
    end

    -- Process reference blocks
    for startLineNumStr, refBlockObj in pairs(blockRefLines) do

        iRefLineNum = getRefLineNum(refBlockObj[1], startLineNumStr)
        endLineNum  = refBlockObj[2]

        for i=tonumber(startLineNumStr),endLineNum do
            if execLines[tostring(iRefLineNum)] and
               execLines[tostring(iRefLineNum)] ~= COMMENT_LINE and
               execLines[tostring(i)] == nil then

                execLines[tostring(i)] = EXEC_CALC
            end
        end
    end

    -- Process the ignore blocks
    for startLineNumStr, endLineNum in pairs(ignoreBlock) do
        for i=tonumber(startLineNumStr),endLineNum do
            if execLines[tostring(i)] == nil then
                execLines[tostring(i)] = EXEC_CALC
            end
        end
    end

    -------------------------------------------
    -- PASS 3: Now save the results
    -------------------------------------------
    local srcFp = io.open( origFilename, "r" )
    if srcFp == nil then
        print("ERROR: Unable to open pass 2 src:", origFilename)
        return
    end
    local destFp = io.open( destFilename, "w" )
    if destFp == nil then
        print("ERROR: Unable to open destination:", destFilename)
        srcFp:close()
        return
    end

    curLineNum   = 0
    curLineStr   = ""
    execCount    = 0   -- total lines marked as executed (by Lua or lcov)
    commentCount = 0   -- total comment/whitespace lines
    for srcLine in srcFp:lines() do --------------------------

        curLineNum  = curLineNum + 1
        curLineStr  = tostring(curLineNum)

        if execLines[curLineStr] then

            if execLines[curLineStr] == EXEC_TRUE then
                destLine  = LCOV_MARKER
                execCount = execCount + 1
            elseif execLines[curLineStr] == EXEC_CALC then
                destLine  = LCOV_MARKER2
                execCount = execCount + 1
            else
                destLine     = string.rep("-", #LCOV_MARKER)
                commentCount = commentCount + 1
            end
        else
            -- Line did not execute
            destLine = string.rep(" ", #LCOV_MARKER)
        end

        destLine = destLine.."| "..srcLine
        destFp:write(destLine.."\n")

        if g_dumpToConsole == true then
            print(string.format("%4d:%s", curLineNum, destLine))
        end

    end ------------------------------------------------------

    ------------------------------------------------------
    -- Stats Key:
    --
    -- execCount    = total lines marked as executed (by Lua or lcov)
    -- commentCount = total comment/whitespace lines
    -- execLoaded   = executed lines loaded from stats file
    ------------------------------------------------------

    -- Display stats to the file and stdout
    local totalExec = maxLines-commentCount
    write(destFp, string.rep("-", 80))
    write(destFp, string.format("-- Total Lines                 : %d", maxLines))
    write(destFp, string.format("-- Comments/Whitespace Lines   : %d", commentCount))
    write(destFp, string.format("-- Total Possible Exec Lines   : %d", totalExec))
    write(destFp, string.format("-- Coverage (lines)            : %d  (Lua: %d + lcov: %d)", execCount, execLoaded, execCount-execLoaded))
    write(destFp, string.format("-- Coverage (percentage)       : %f%%", (execCount/totalExec)*100))
    write(destFp, "--")
    write(destFp, string.format("-- Code Percentage in File     : %f%%", (totalExec/maxLines)*100))
    write(destFp, string.format("-- Non-Code Percentage in File : %f%%", (commentCount/maxLines)*100))
    write(destFp, "--")
    write(destFp, string.format("-- Results Generated from lcov.lua v%s on %s", APP_VER, os.date()))
    write(destFp, string.rep("-", 80))

    srcFp:close()
    destFp:close()

    return { total          = maxLines,
             commented      = commentCount,
             actualCode     = totalExec,
             totalExec      = execCount,
             percentCovered = (execCount/totalExec)*100 }

end -- covGenerateFileResults

----------------------------------------------------------------
--- generateResults
---
--- Generate the results files from the ".lcno" coverage stats files.
---
--- @tparam   (boolean)  conOutput ....true/false(or nil)
----------------------------------------------------------------
function M.generateResults( conOutput )

    local bExecute  = true
    local iFileCount= 0
    local sDir      = ""
    local sFile     = ""
    local sPathFile = ""
    local sCurrDir  = g_localStoreDir
    local sPos, ePos

    local summary    = {}
    local summaryCnt = 0

    if conOutput and type(conOutput) == "boolean" then
        g_dumpToConsole = true
    end

    if lfs == nil then
        print("\nERROR: lfs is required to generate the results file(s).\n")
        return
    end

    for filename in lfs.dir(g_localStoreDir) do

        sPos, ePos, sDir = string.find(filename, "(.*):")
        if sDir ~= nil then
            sCurrDir = sDir
        end

        if string.find(filename,"%."..LCOV_EXT) then
            -- QNX will have a * for all files
            -- Windows/Linux will not have the *
            sPos, ePos, sFile = string.find(filename, "(.*)%*")
            if sFile == nil then
                sPos, ePos, sFile = string.find(filename, "(.*)")
            end

            bExecute = true
            if g_fileFilter and  g_bCoverAllFiles == false then

                local fullFilename = ""
                local onlyFilename = ""
                local covFp        = io.open( g_localStoreDir..filename, "r" )
                if covFp then
                    fullFilename = covFp:read("*l") -- line1 = orig filename
                    fullFilename = string.match(fullFilename, "^@(.*)")
                    onlyFilename = string.match(fullFilename, ".*[/\\@](.*)$")
                    covFp:close()

                    -- Check our filter and see if it should be covered
                    -- Check our filter and see if it should be covered
                    if (g_fullPathFilter == true  and g_fileFilter[fullFilename] == nil) or
                       (g_fullPathFilter == false and g_fileFilter[onlyFilename] == nil) then
                        -- File should not be covered
                        bExecute = false
                    end
                else
                    -- error so skip
                    bExecute = false
                end
            end

            if bExecute == true then
                iFileCount = iFileCount+1
                print("\n"..string.rep("-", 80))

                if sCurrDir and sFile then
                    local tResults  = nil
                    local sFilename = sFile
                    if g_localStoreDir == sFile then
                        -- MUST have a file passed in
                        print(string.format("PROCESSING: %s\n", sFile))
                        tResults = covGenerateFileResults(sFile)
                    else
                        sPathFile = string.format("%s/%s", sCurrDir, sFile)
                        sFilename = sPathFile
                        print(string.format("PROCESSING: %s\n", sPathFile))
                        tResults = covGenerateFileResults(sPathFile, sCurrDir)
                    end
                    summary[sFilename] = tResults
                    summaryCnt         = summaryCnt + 1
                else
                    -- something wrong, don't crash
                    print("SKIPPING:",filename,"FILE:",sFile)
                end

            -- else, don't execute
            end

        end

    end -- file loop

    if summaryCnt > 1 then
        print(string.rep("=", 80))
        print(string.format("%-30s    %8s   %8s  %8s    %8s    %8s",
              "SUMMARY","TotalLines","Commented","Code","Executed","Coverage" ))
        for filename, tResults in pairs(summary) do
            print(string.format("%-30s    %7d       %7d    %7d    %7d    %f",
                              filename,
                              tResults.total,
                              tResults.commented,
                              tResults.actualCode,
                              tResults.totalExec,
                              tResults.percentCovered ))
        end
        print(string.rep("=", 80))
    end

    print()

end -- generateResults

-- -------------------------------------------------------------
--  parseArgs
--
--  Process all args
-- -------------------------------------------------------------
local function parseArgs()

    -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    -- deepcopy
    --
    -- MIT Code taken from:
    -- http://snippets.luacode.org/snippets/Deep_copy_of_a_Lua_Table_2
    -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    local function deepcopy(t)
        if type(t) ~= 'table' then return t end
        local mt = getmetatable(t)
        local res = {}
        for k,v in pairs(t) do
            if type(v) == 'table' then
                v = M.deepcopy(v)
            end
            res[k] = v
        end
        setmetatable(res,mt)
        return res
    end -- deepcopy
    -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    local newArgs      = {}
    local sCfgFilename = nil

    print(string.format("\nlcov %s Options:", APP_VER))
    if #arg == 0 then
        print(helpText)
        os.exit(1)
    end

    local tArgs = deepcopy(arg)

    local idx, v = next(tArgs)
    while idx and idx > 0 do
        if v == "--append" then
            g_bAppendStats = true

        elseif v == "--listdeps" then
            g_bListAllDeps = true

        elseif v == "--doall" then
            g_bCoverAllFiles = true

        elseif v == "--gen" then
            g_bRunGen = true

        elseif v == "--cfg" then
            idx, sCfgFilename = next(tArgs, idx)
            local loadFunct, sErr = loadfile(sCfgFilename)
            if loadFunct == nil then
                print("\n"..string.rep("*", 50))
                print(sErr) -- error message
                print(string.rep("*", 50).."\n")
                print("ERRROR: Failed to load the config file:", sCfgFilename)
                os.exit(1)
            else
                parseCfgFile( loadFunct() )
            end

        elseif v == "--con" then
            g_dumpToConsole = true

        elseif v == "--dbg" then
            g_debug = true

        elseif v == "--dir" then
            idx,v = next(tArgs, idx)
            if v == nil or idx < 0 then
                print(string.rep("*", 80))
                print("ERROR: --dir requires a path")
                print(string.rep("*", 80))
                print()
                print(helpText)
                os.exit(1)
            end
            g_localStoreDir = v

        elseif v == "--exe" then
            idx,v = next(tArgs, idx)
            if v == nil then
                print(string.rep("*", 80))
                print("ERROR: --exe requires a file to execute followed by optional arguments")
                print(string.rep("*", 80))
                print()
                print(helpText)
                os.exit(1)
            end
            local fileToExec = v

            -- all following args need to be put to args
            idx, v = next(tArgs, idx)
            while idx and idx > 0 do
                table.insert(newArgs, v)
                idx, v = next(tArgs, idx)
            end

            adjustArgs( fileToExec, newArgs )
        end
        idx, v = next(tArgs, idx)
    end

    -- Display the command line options
    -------------------------------------------------------------
    if sCfgFilename then
        print(string.format("Config File Used           %s", sCfgFilename))
    end
    print(string.format("Append to Stats           %s", tostring(g_bAppendStats)))
    print(string.format("Cover All Files           %s", tostring(g_bCoverAllFiles)))
    print(string.format("Generate Results          %s", tostring(g_bRunGen)))
    print(string.format("Dump Results to Console   %s", tostring(g_dumpToConsole)))
    print(string.format("Debug Logging             %s", tostring(g_debug)))
    print(string.format("Results Dir               %s", g_localStoreDir))
    if g_fileToExec == nil or g_fileToExec == "" then
        print("File to Exec              MISSING\n")
        if g_bRunGen ~= true then
            --print(helpText)
            os.exit(1)
        end
    else
        print(string.format("File to Exec              %s", g_fileToExec))
    end
    for i,v in ipairs(arg) do
        print(string.format("   arg[%d]:               %s", i,v))
    end
    if g_fileFilter then
        print(string.format("Filter Using Full Path    %s", tostring(g_fullPathFilter)))
        print("File to Cover:")
        for filename,_ in pairs(g_fileFilter) do
            print("", filename)
        end
    end
    print("\n")

end -- parseArgs

-- -------------------------------------------------------------
--  parseCfgFile
--
--  Process the (--cfg) config file
--
--  @tparam   (table)  cfgFile ....loaded module
-- -------------------------------------------------------------
function parseCfgFile( cfgFile )

    if cfgFile == nil then
        return
    end

    -- Cfg only options
    ---------------------------------------
    g_fileFilter = cfgFile.fileFilter
    if g_fileFilter then
        local tSet = {}
        for _,path in ipairs(g_fileFilter) do
            tSet[path] = true
        end
        g_fileFilter = tSet
    end
    g_fullPathFilter = cfgFile.filterFullPaths or g_fullPathFilter


    -- command line overrides/options
    ---------------------------------------
    if cfgFile.bAppend ~= nil then
        g_bAppendStats = cfgFile.bAppend
    end
    if cfgFile.bCon ~= nil then
        g_dumpToConsole = cfgFile.bCon
    end
    if cfgFile.bDbg ~= nil then
        g_dumpToConsole = cfgFile.bDbg
    end
    if cfgFile.sDir ~= nil then
        g_localStoreDir = cfgFile.sDir
    end
    if cfgFile.bDoAll ~= nil then
        g_bCoverAllFiles = cfgFile.bDoAll
    end
    if cfgFile.bGen ~= nil then
        g_bRunGen = cfgFile.bGen
    end
    if cfgFile.bListDeps ~= nil then
        g_bListAllDeps = cfgFile.bListDeps
    end
    if cfgFile.sExe ~= nil then
        adjustArgs( cfgFile.sExe, cfgFile.tArgs or {} )
    end

end -- parseCfgFile

---------------------------------------------------------------
-- setResultsDir
--
-- Change where we store the generated results.
--
-- @tparam   (string)  path ....path to store files
---------------------------------------------------------------
function M.setResultsDir( path )

    g_localStoreDir = path

end -- setResultsDir

----------------------------------------------------------------
--- stop
---
--- Stop the coverage tracking
----------------------------------------------------------------
function M.stop()

    debug.sethook()

    for k,v in pairs(g_fileList) do
        if v.fp then
            v.fp:close()
        end
    end

end -- stop

----------------------------------------------------------------
--- start
---
--- Start the coverage tracking
---
--- @tparam   (string)  fileToExec ....optional file to run the
---                                    coverage on.
----------------------------------------------------------------
function M.start( fileToExec )

    if fileToExec then

        if g_fileToExec == nil then
            -- Must be executing from a module
            adjustArgs( fileToExec )
        end

        -- Verify the file compiles in the first place.
        -- We don't want to be bothered with bad syntax
        local fp = assert (io.popen ("luac -o lualint.tmp "..fileToExec.." 2>&1"))
        if fp then
            local bErrors = false
            for line in fp:lines() do
                print("ERROR: "..line)
                bErrors = true
            end
            fp:close()
            if bErrors then
                print()
                os.exit(1)
            end
        end

        local loadFunct = assert( loadfile(fileToExec) )
        debug.sethook(covHandler, "l" )

        -- Workaround: coroutines require us to sethook again.
        local oldCreate = coroutine.create
        coroutine.create = function( coFunct )
            local callback, opt = debug.gethook()
            return oldCreate( function()
                                 debug.sethook(callback, opt )
                                 coFunct()
                              end )
        end

        loadFunct() -- run the main program

        -- ORIGINAL:
        --dofile( fileToExec )

        M.stop()

    else
        debug.sethook(covHandler, "l" )
    end

end -- start


----------------------------------------------------------------
-- Main
----------------------------------------------------------------

g_execFilename = string.match(arg[0], ".*[/\\@](.*)$")
if g_execFilename == nil then
    g_execFilename = arg[0]
end

if not package.loaded[...] then

    -- MUST be running as an executable

    parseArgs()

    if g_fileToExec then
        M.start( g_fileToExec ) -- will call M.stop
    end

    if g_bRunGen == true then
        M.generateResults()
    end

    if g_bListAllDeps and g_filesSeenList then

        print("Execution Dependencies Seen During Execution:")
        for filename,_ in pairs(g_filesSeenList) do
            print("",filename)
        end
        print()
    end

else
    -- MUST be treating this as a module

    return M

end


