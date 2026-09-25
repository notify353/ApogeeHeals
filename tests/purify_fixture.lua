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
    m.cleanseContainers = {}
    CreateFrame = function(kind, name, parent, template)
        local frame=createFrame(kind,name,parent,template)
        if template=="CustomAuraContainerTemplate" then
            m.cleanseContainers[#m.cleanseContainers+1]=frame
            frame.AddAuraSlot=function(self,key,filter,description)
                assert(not m.combat and key=="poison" and filter=="HARMFUL")
                assert(description.templateNames[1]=="SecureActionButtonTemplate")
                self.description=description
                local button=createFrame("AuraButton",nil,self,"SecureActionButtonTemplate")
                self.nativeButton=button -- Only the mock native container retains this handle.
                button.IsProtected=function() return not options.unprotected end
                button.SetCancelAuraButtons=function(_,value) assert(value==nil) end
                button.SetTooltipAnchorPoint=function(_,value) assert(value=="ANCHOR_RIGHT") end
                description.initializeFrame(button)
                button.shown=false
                -- Simulate access restrictions after initialization. Addon code
                -- must never inspect/mutate the native button after handoff.
                for _, method in ipairs({"SetAttribute","GetAttribute","SetPoint","SetSize","IsShown",
                    "Show","Hide","SetShown","SetScript","RegisterForClicks","IsProtected"}) do
                    button[method]=function() error("tainted access to native-owned aura button") end
                end
            end
            frame.SetUnit=function(self,unit)
                assert(not m.combat and not self.nativeUnit);self.nativeUnit=unit
            end
            frame.SetEnabled=function(self,enabled) assert(not m.combat);self.nativeEnabled=enabled end
        end
        return frame
    end
    local a=m.Load();m.Event("ADDON_LOADED","ApogeeHeals");m.Flush()
    function m.NativePoison(unit,dispelType)
        for _, container in ipairs(m.cleanseContainers) do
            if container.nativeUnit==unit then
                -- Trusted-engine simulation, never a public addon aura getter.
                container.nativeButton.shown=container.description.candidateFilters.includeDispelTypes[dispelType] == true
            end
        end
    end
    return m,a
end
return F
