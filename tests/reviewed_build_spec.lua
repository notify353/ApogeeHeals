local M=dofile("tests/mock.lua"); M.New()
local file=assert(io.open("docs/wow-api-export.json","rb"))
local record=file:read("*a"); file:close()
local version,build=record:match('"clientVersion"%s*:%s*"(%d+%.%d+%.%d+)%.(%d+)"')
assert(version and build,"Reviewed client metadata is required")
GetBuildInfo=function() return version,build,"",16001 end
WOW_PROJECT_CAMELOT=18; WOW_PROJECT_ID=18
local messages={}; local originalPrint=print
print=function(message) messages[#messages+1]=message end
local A={}; assert(loadfile("Core/Client.lua"))("ApogeeHeals",A)
assert(A.CheckClient() and #messages==0,"Reviewed build must not produce an unreviewed-build warning")
build=tostring(tonumber(build)+1)
assert(A.CheckClient() and #messages==1,"An unreviewed build must still warn and use capability checks")
canaccessvalue=nil
assert(not A.CheckClient(),"Build review does not waive required APIs")
print=originalPrint
print("PASS reviewed build metadata: quiet startup, future warning and required APIs")
