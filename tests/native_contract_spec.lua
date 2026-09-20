local root = os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root == "" then print("SKIP native export contracts (set APOGEE_FOREVER_EXPORT)"); return end
local function read(path)
    local file = assert(io.open(root .. "/" .. path, "rb"))
    local text = file:read("*a"):gsub("\r\n", "\n"); file:close(); return text
end
local function definition(text, name)
    local start = assert(text:find("function " .. name, 1, true))
    local finish = assert(text:find("\nend", start, true))
    return text:sub(start, finish + 3)
end
local source = read("Blizzard_FrameXML/SecureTemplates.lua")
local m = dofile("tests/mock.lua").New(); local a = m.Start()
local env = setmetatable({}, {__index = _G})
local invoked, targeted = 0, nil
env.SecureButton_GetAttribute = function(frame, key) return frame.attributes[key] end
env.GetCVarBool = function() return true end -- Key-down global must not disable our release click.
env.OnActionButtonClick = function(frame, button)
    invoked = invoked + 1; assert(button == "LeftButton")
    assert(frame.attributes.type1 == "target")
end
env.OnActionButtonPressAndHoldRelease = function() error("unexpected press-and-hold") end
local code = definition(source, "SecureActionButton_ShouldUseOnKeyDown") .. "\n"
    .. definition(source, "SecureActionButton_OnClick")
local chunk = assert(loadstring(code)); setfenv(chunk, env); chunk()
for _, row in ipairs(a.View.rows) do
    assert(env.SecureActionButton_OnClick(row, "LeftButton", false) == true)
end
assert(invoked == 5)
local action = assert(source:match("SECURE_ACTIONS%.target%s*=%s*(function.-\n    end);"))
env.SpellIsTargeting = function() return false end
env.CursorHasItem = function() return false end
env.TargetUnit = function(unit) targeted = unit end
chunk = assert(loadstring("return " .. action)); setfenv(chunk, env)
local target = chunk()
for _, row in ipairs(a.View.rows) do target(row, row.unit, "LeftButton"); assert(targeted == row.unit) end

local stateSource = read("Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua")
local stateEnv = setmetatable({}, {__index = _G})
local raid, present = false, {player=true}
stateEnv.SecureCmdOptionParse = function(expression)
    local unit = assert(expression:match("^%[group:raid%] hide; %[@(%w+),exists%] show; hide$"))
    return not raid and present[unit] and "show" or "hide"
end
chunk = assert(loadstring(definition(stateSource, "resolveDriver") .. "\nreturn resolveDriver"))
setfenv(chunk, stateEnv); local resolve = chunk()
-- The engine supplies secure execution and condition parsing, modeled here.
local frame = {Show=function(self) self.shown=true end, Hide=function(self) self.shown=false end,
    SetAttribute=function() end}
for i, row in ipairs(a.View.rows) do
    resolve(frame, "state-visibility", row.driver); assert(frame.shown == (i == 1))
end
present.party1=true; resolve(frame, "state-visibility", a.View.rows[2].driver); assert(frame.shown)
present.party1=nil; resolve(frame, "state-visibility", a.View.rows[2].driver); assert(not frame.shown)
raid=true
for _, row in ipairs(a.View.rows) do resolve(frame, "state-visibility", row.driver); assert(not frame.shown) end
print("PASS matching-export click dispatch, target action and visibility resolver contracts")
