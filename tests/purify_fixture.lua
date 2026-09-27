-- Engine simulation for addon configuration tests; real native functions are
-- exercised separately by native_purify_spec.lua. This is not taint acceptance.
local Mock = dofile("tests/mock.lua")
local F = {}
function F.New(options)
    options = options or {}
    local previousXMLUtil = C_XMLUtil
    local m = Mock.New()
    m.units.player.class = options.class or "PALADIN"
    m.known = options.known ~= false
    m.cleanse = options.cleanse == true
    Enum.SpellBookSpellBank = {Player=0}
    C_Spell.GetSpellInfo = function(id)
        if id == 1152 then return {spellID=id,name="Purify",iconID=135949} end
        if id == 4987 then return {spellID=id,name="Cleanse",iconID=135953} end
        if id == 19740 and options.might then return {spellID=id,name="Might",iconID=135906} end
    end
    C_Spell.IsSpellHelpful = function() return options.helpful ~= false end
    C_Spell.IsSpellHarmful = function() return false end
    C_Spell.IsSpellPassive = function() return false end
    local function known(id) return (id==1152 and m.known) or (id==4987 and m.cleanse) or (id==19740 and options.might==true) end
    C_SpellBook = {IsSpellInSpellBook=known, IsSpellKnown=known}
    C_XMLUtil = {GetTemplateInfo=function() return {type="AuraContainer"} end}
    if options.noTemplates then C_XMLUtil = nil end
    if options.secretTemplates then C_XMLUtil.GetTemplateInfo=function() return m.InaccessibleTable() end end
    local createFrame = CreateFrame
    m.cleanseContainers, m.xmlWarnings = {}, 0
    CreateFrame = function(kind, name, parent, template)
        local frame = createFrame(kind, name, parent, template)
        if template == "CustomAuraContainerTemplate" then
            m.cleanseContainers[#m.cleanseContainers + 1] = frame
            frame.slots = {}
            function frame:AddAuraSlot(key, filter, config)
                assert(not config.templateNames and filter == "HARMFUL")
                local indicator = createFrame("AuraButton", nil, self, "CustomAuraButtonTemplate")
                indicator.SetCancelAuraButtons = function(_, value) assert(value == nil) end
                config.initializeFrame(indicator)
                assert(not next(indicator.scripts) and not next(indicator.attributes))
                self.slots[key] = {frame=indicator, filters=config.candidateFilters}
            end
            function frame:SetAuraSlotCandidateFilters(key, filters)
                assert(not m.combat); self.slots[key].filters = filters
            end
            function frame:AddAuraGroup(_, filter, options)
                assert(filter == "HARMFUL"); self.group = options
            end
            function frame:SetUnit(unit) self.unit = unit end
            function frame:SetEnabled(enabled) self.enabled = enabled end
        end
        return frame
    end
    GameTooltip.SetSpellByID = function() return true end
    local a=m.Load();m.Event("ADDON_LOADED","ApogeeHeals");m.Flush()
    C_XMLUtil = previousXMLUtil
    return m,a
end
return F
