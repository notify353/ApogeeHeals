-- Engine simulation for addon configuration tests; real native functions are
-- exercised separately by native_purify_spec.lua. This is not taint acceptance.
local Mock = dofile("tests/mock.lua")
local F = {}
function F.New(options)
    options = options or {}
    local m = Mock.New()
    m.units.player.class = options.class or "PALADIN"
    m.known = options.known ~= false
    Enum.SpellBookSpellBank = {Player=0}
    C_Spell.GetSpellInfo = function(id)
        if id == 1152 then return {spellID=id,name="Purify",iconID=135949} end
        if id == 19740 and options.might then return {spellID=id,name="Might",iconID=135906} end
    end
    C_Spell.IsSpellHelpful = function() return options.helpful ~= false end
    C_Spell.IsSpellHarmful = function() return false end
    C_Spell.IsSpellPassive = function() return false end
    local function known(id) return (id==1152 and m.known) or (id==19740 and options.might==true) end
    C_SpellBook = {IsSpellInSpellBook=known, IsSpellKnown=known}
    C_XMLUtil = {GetTemplateInfo=function() return {type="Frame"} end}
    if options.noTemplates then C_XMLUtil = nil end
    if options.secretTemplates then C_XMLUtil.GetTemplateInfo=function() return m.InaccessibleTable() end end
    local createFrame = CreateFrame
    m.cleanseContainers, m.xmlWarnings = {}, 0
    CreateFrame = function(kind, name, parent, template)
        local frame = createFrame(kind, name, parent, template)
        if template == "CustomAuraContainerTemplate" then
            m.cleanseContainers[#m.cleanseContainers + 1] = frame
            -- Real XML reports a warning without throwing a Lua error. A pcall
            -- around construction cannot establish that secure composition works.
            frame.AddAuraSlot = function() m.xmlWarnings = m.xmlWarnings + 1 end
            frame.SetUnit = function() end
            frame.SetEnabled = function() end
        end
        return frame
    end
    local a=m.Load();m.Event("ADDON_LOADED","ApogeeHeals");m.Flush()
    return m,a
end
return F
