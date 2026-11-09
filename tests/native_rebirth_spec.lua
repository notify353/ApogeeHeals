local root = os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root == "" then print("SKIP native Rebirth contracts (set APOGEE_FOREVER_EXPORT)"); return end
local function read(path)
    local file = assert(io.open(root .. "/" .. path, "rb"))
    local text = file:read("*a"):gsub("\r\n", "\n"); file:close(); return text
end
local function definition(text, name)
    local first = assert(text:find("function " .. name, 1, true))
    return text:sub(first, assert(text:find("\nend", first, true)) + 3)
end
local function execute(code, env)
    local chunk = assert(loadstring(code)); setfenv(chunk, env); return chunk()
end
local m, a = dofile("tests/purify_fixture.lua").New({class="DRUID", known=false})
C_Spell.GetSpellInfo = function(id)
    if id == 20484 then return {name="Rebirth", iconID=136080, spellID=id} end
end
C_Spell.GetSpellSubtext = function() return "Rank 1" end
C_SpellBook.IsSpellKnown = function(id) return id == 20484 end
C_SpellBook.IsSpellInSpellBook = C_SpellBook.IsSpellKnown
C_Spell.IsSpellHelpful = function() return false end
m.Event("SPELLS_CHANGED"); m.Flush()
local source = read("Blizzard_FrameXML/SecureTemplates.lua")
local env = setmetatable({}, {__index=_G})
env.SecureButton_GetAttribute = function(frame, key) return frame.attributes[key] end
env.SecureButton_GetModifiedAttribute = function(frame, key) return frame.attributes[key .. "1"] end
env.OnActionButtonPressAndHoldRelease = function() error("unexpected held action") end
local count, lastUnit = 0
env.C_Macro = {RunMacroText=function(text)
    lastUnit = assert(text:match("^/cast %[@(%w+),exists,help,dead%] Rebirth%(Rank 1%)\n/stopspelltarget$"))
    count = count + 1
end}
local macro = execute("return " .. assert(source:match("SECURE_ACTIONS%.macro%s*=%s*(function.-\n    end);")), env)
env.OnActionButtonClick = function(frame, key) macro(frame, frame.attributes.unit, key) end
execute(definition(source, "SecureActionButton_ShouldUseOnKeyDown") .. "\n"
    .. definition(source, "SecureActionButton_OnClick"), env)
m.combat = true; m.Event("PLAYER_REGEN_DISABLED"); m.Flush()
for _, row in ipairs(a.View.supportRows) do
    local button = row.rebirthButton
    if button then
        for _, keyDown in ipairs({false, true}) do
            env.GetCVarBool = function() return keyDown end
            local before = count
            env.SecureActionButton_OnClick(button, "LeftButton", true); assert(count == before)
            env.SecureActionButton_OnClick(button, "LeftButton", false)
            assert(count == before + 1 and lastUnit == row.unit)
        end
    end
end
local states = read("Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua")
local stateEnv = setmetatable({}, {__index=_G})
local combat, playerDead, present, friendly, dead = false, false, true, true, false
-- Macro parsing and secure provenance belong to the engine. These inputs model
-- their public outcomes; the actual matching-export resolver runs below.
stateEnv.SecureCmdOptionParse = function(expression)
    local prefix, unit = expression:match("^%[@player,dead%] hide; %[(.-)@(%w+),exists,help,dead%] show; hide$")
    assert(unit and (prefix == "" or prefix == "combat,"))
    return not playerDead and (prefix == "" or combat) and present and friendly and dead and "show" or "hide"
end
local resolve = execute(definition(states, "resolveDriver") .. "\nreturn resolveDriver", stateEnv)
local frame = {Show=function(self) self.shown=true end, Hide=function(self) self.shown=false end,
    SetAttribute=function() end}
local action = a.View.rows[2].rebirthButton
local function shown(expected) resolve(frame, "state-visibility", action.driver); assert(frame.shown == expected) end
shown(false)
combat = true; shown(false)
dead = true; shown(true) -- Death after entering combat, no addon refresh/rebind.
present = false; shown(false)
present = true; friendly = false; shown(false)
friendly = true; playerDead = true; shown(false)
playerDead = false; shown(true) -- Released dead recipients retain the same native dead gate.
combat = false; shown(true)
m.combat = false; a.View.SetUnlocked(true)
shown(false)
combat = true; shown(true) -- Prepared preview gate restores itself on combat entry.
print("PASS matching-export Rebirth release dispatch and death/combat visibility contracts")
