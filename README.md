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
`
local lcov = require "lcov"
...
lcov.setResultsDir( "/fs/mmc0/" ) -- default is "/tmp/"
lcov.start()                      -- start coverage
...                               -- execute something
lcov.stop()                       -- stop coverage
lcov.generateResults()            -- generate results files
                                  -- can optionally pass in true to have the
                                     results go to the console.
`

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
`
local var     --> lcov: ref+1
var = {}
`
In this example, "var={}" is marked executed from Lua, but "local var" is not.
The reference comment will show "local var" as executed.  For example,
`
--xx|     local var     --> lcov: ref+1
--XX|     var = {}
`
You can also have:  local var --> lcov: ref+1 -- can have comment here
               or:  local var -- can have comment here  --> lcov: ref+1

CMD = "ref" (block)
-------------------
You can use the "ref" syntax an build on that the ability to assign a reference
line to complete block.  Use the original syntax for the start of the block then
add ",start" (no spaces).  To end the block use "ref=end".  These assignments
can be in a tailing comment or as a standalone comment.
`
--> lcov: ref=1,start
local VAR1
local VAR2,       VAR3,            VAR4
local VAR5
--> lcov: ref=end
`
`
----| --> lcov: ref=1,start
--XX| local VAR1
--xx| local VAR2,       VAR3,            VAR4
--xx| local VAR5
----| --> lcov: ref=end
`

CMD = "ignore"
--------------
This is used to ignore a block of lines.  If the line within this block
has not executed it will be marked as "--xx".  The params are "=start"/"=end".
For example,
`
--> lcov: ignore=start
local VAR1
local VAR2,       VAR3,            VAR4
local VAR5
--> lcov: ignore=end
`
NOTE: This can be on the start of a line.
`
----| --> lcov: ignore=start
--XX| local VAR1
--xx| local VAR2,       VAR3,            VAR4
--xx| local VAR5
----| --> lcov: ignore=end
`

Known Limitations:
==================
1) Currently only tested in Lua 5.1.4
2) The following syntax is not handled properly:
`
    | local execLines2
--XX| =
--XX| {
--XX|     "something"
--XX| }
`

### Written: 2011 by tmoore
------------------------------------------------------------------------------
================================================================================

SAMPLE RESULTS:
=================

> ------------------------------------------------------------------------------
> PROCESSING: /tmp//fileUtils.lua.lcno
> 
> origFilename    /usr/share/lua/5.1/fileUtils.lua
> destFilename    /tmp/fileUtils.lua
>
> ------------------------------------------------------------------------------
> Total Lines                 : 1096
> Comments/Whitespace Lines   : 675
> Total Possible Exec Lines   : 421
> Coverage (lines)            : 323  (Lua: 248 + lcov: 75)
> Coverage (percentage)       : 76.722090%
> 
> Code Percentage in File     : 38.412409%
> Non-Code Percentage in File : 61.587591%
> 
> Results Generated from lcov.lua v2.6 on Fri Feb 22 13:24:50 2013
>
> ------------------------------------------------------------------------------
> 
> ------------------------------------------------------------------------------
> PROCESSING: /tmp//pluginUtils.lua.lcno
> 
> origFilename	/usr/share/lua/5.1/pluginUtils.lua
> destFilename	/tmp/pluginUtils.lua
>
> ------------------------------------------------------------------------------
> Total Lines                 : 1748
> Comments/Whitespace Lines   : 1041
> Total Possible Exec Lines   : 707
> Coverage (lines)            : 379  (Lua: 276 + lcov: 103)
> Coverage (percentage)       : 53.606789%
> 
> Code Percentage in File     : 40.446224%
> Non-Code Percentage in File : 59.553776%
> 
> Results Generated from lcov.lua v2.6 on Fri Feb 22 13:24:51 2013
>
> ------------------------------------------------------------------------------
> 
> ------------------------------------------------------------------------------
> PROCESSING: /tmp//otherUtils.lua.lcno
> 
> origFilename	/usr/share/lua/5.1/otherUtils.lua
> destFilename	/tmp/otherUtils.lua
>
> ------------------------------------------------------------------------------
> Total Lines                 : 2205
> Comments/Whitespace Lines   : 1219
> Total Possible Exec Lines   : 986
> Coverage (lines)            : 499  (Lua: 383 + lcov: 116)
> Coverage (percentage)       : 50.608519%
> 
> Code Percentage in File     : 44.716553%
> Non-Code Percentage in File : 55.283447%
> 
> Results Generated from lcov.lua v2.6 on Fri Feb 22 13:24:51 2013
>
> ------------------------------------------------------------------------------
> 
> ------------------------------------------------------------------------------
> PROCESSING: /tmp//fileMgr.lua.lcno
> 
> origFilename	../src/fileMgr.lua
> destFilename	/tmp/fileMgr.lua
>
> ------------------------------------------------------------------------------
> Total Lines                 : 6421
> Comments/Whitespace Lines   : 3117
> Total Possible Exec Lines   : 3304
> Coverage (lines)            : 3082  (Lua: 1659 + lcov: 1423)
> Coverage (percentage)       : 93.280872%
> 
> Code Percentage in File     : 51.456159%
> Non-Code Percentage in File : 48.543841%
> 
> Results Generated from lcov.lua v2.6 on Fri Feb 22 13:24:52 2013
>
> ------------------------------------------------------------------------------
> = ============================================================================
 SUMMARY                     TotalLines  Commented Code  Executed    Coverage
 /tmp//fileUtils.lua.lcno       1096          675   421      323    76.722090
 /tmp//fileMgr.lua.lcno         6421         3117  3304     3082    93.280872
 /tmp//pluginUtils.lua.lcno     1748         1041   707      379    53.606789
 /tmp//otherUtils.lua.lcno      2205         1219   986      499    50.608519
 = =============================================================================




