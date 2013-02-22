local helpText = [[
---------------------------------------------------------------------------

This is a simple code coverage test script.

------------------------------------------------------------------------------]]

local os = require "os"
local isOk, bit = pcall(require, "bit")

--local s = "@c:\\temp\\lcov.lua"
--local s = "@/tmp/lcov.lua"
--local s = "@lcov.lua"
--local s = "lcov.lua"

local function test()
    -- Init
	local linenum  = 0
    local count    = 1260
    local lines    = {}
    local maxBytes = math.ceil(count/32)
    for i=1,maxBytes do
      lines[i] = 0
    end

	for
	    i=1,maxBytes
	    do
      lines[i] = 0
    end


    for linenum=0,45 do
        local bytePos = math.floor(linenum/32)
        local bitPos  = math.mod(linenum, 32)
        --print(string.format("%d.%d", bytePos, bitPos))
    end

	local scont = [[this is
	multiple lines
	of executions]]

	print("pre-exec", scont)
	if linenum and
	--  false then
	    count then

		local var = true
		if var == true then -- test nesting
		    print("nested if then")
		else
			print("not called")
		end
	end

	local elseCheck = false
	if elseCheck == true then
		print("not called")
	else
		print("Check else")
	end

end -- test

function notCalled( fmt, ... )
    local someVar
    local anotherVar = 0
    local msg = string.format(fmt, unpack(arg))
    print(msg)
end

local s = "if something \'then"
print("res:", string.match(s, "%s*if%s+"))
print("res:", string.match(s, "[%s\"\')]+then[%s\n\r%z]"))
print("res:", string.match(s, "[%s\"\')]+then$"))

local s2 = '--[[something]]'

print("res:", string.find(s2, "%[%["))
--print("res:", string.match(s2, "%]%]"))

--[[ something
else
]]

--local s3 = "something -- comment"
local s3 = "-- something -- comment"
--local s3 = "something comment"

local itCnt = 3
repeat
	itCnt = itCnt - 1
until itCnt == 0

local itCnt = 3
while itCnt ~= 0 do
	itCnt = itCnt - 1
end

local itCnt = 3
while
	itCnt ~= 0
	do
	itCnt = itCnt - 1
end

local itCnt = 3
for i=1,itCnt do
	print(i)
end

if itCnt ~= nil then
	print("working")
end


--print("res:", string.find(s3, "%-%-"))

--> lcov: ignore=start
local Var_1
local Var_2,       Var_3,           Var_4
local Var_5
--> lcov: ignore=start
local Var_6,       Var_7,           Var_8
local Var_9,       Var_10,  		Var_11
--> lcov: ignore=end
local Var_12,      Var_13,          Var_14
local Var_15,      Var_16,          Var_17
local Var_18,      Var_19,          Var_20
local Var_21,      Var_22,          Var_23
--> lcov: ignore=end

--> lcov: ref=1,start
local Var_A,        Var_B,          Var_C
local Var_D,        Var_E
local Var_F,        Var_G
--> lcov: ref=end

local function registerStreams( sessionObj, eventName,
                                destName,   streamName,
                                altEventName )
    local var                            --> lcov: ref+1
    var = {}
    print("registerStreams", var)
end -- registerStreams

local g_testObj      = {
							iId  = 0,
							sId  = "This is a {test}",
							tObj = {}
						 }

local execLines      =
{
	"something"
}
local execLines2                    -- this is a comment --> lcov: ref+1
=
{
	"something"
}

registerStreams( destName, {"AM", "FM", "Pandora"}, "Media", "permanent", true )
registerStreams( destName, {"nav"}, "InfoMix", "transient", false )

local s = [[g_appSvcObj      = {
                            mixedSessionId  = 0,
                            sessionId       = 0,
                            sessions        = {}
                         }]]

local s4 = "this is a test"
print(string.match(s4, "[ \t\n\r]*(.*)"))

local t = {}
table.insert(t, 1)
table.insert(t, 2)
table.insert(t, 3)
print(t[#t])

local str = 'local s = "some"'
print(string.gsub(str, string.format("([^\\]%s)", '"'), function (n) itCnt = itCnt+1 end) )

print(string.gsub(str, string.format("([^\\]%s)", '"'),
	function (n)
		itCnt = itCnt+1
	end) )


test()


