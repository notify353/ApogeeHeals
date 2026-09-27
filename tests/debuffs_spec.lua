local Mock = dofile("tests/mock.lua")
local previousXMLUtil = C_XMLUtil
local function setup(mode)
    local m = Mock.New()
    local containers, buttons = {}, {}
    C_XMLUtil = {GetTemplateInfo=function()
        if mode == "missing" then return nil end
        if mode == "restricted" then return m.InaccessibleTable() end
        return {type="AuraContainer"}
    end}
    local create = CreateFrame
    CreateFrame = function(kind, name, parent, template)
        local frame = create(kind, name, parent, template)
        if template == "CustomAuraContainerTemplate" then
            assert(not m.combat and kind == "AuraContainer")
            containers[#containers + 1] = frame
            function frame:SetUnit(unit) assert(not self.unit); self.unit = unit end
            function frame:SetEnabled(enabled) self.enabled = enabled end
            function frame:AddAuraGroup(key, filter, options)
                self.key, self.filter, self.options = key, filter, options
                assert(not options.templateNames and not options.candidateFilters)
                -- Native initialization allocates a batch of ten irrespective of aura count.
                for index = 1, 10 do
                    local button = create("AuraButton", nil, self, "CustomAuraButtonTemplate")
                    function button:SetCancelAuraButtons(value) assert(value == nil); self.cancelDisabled = true end
                    function button:SetTooltipAnchorPoint(value) self.tooltipAnchor = value end
                    function button:SetIcon(icon) self.icon = icon end
                    options.initializeFrame(button)
                    assert(not next(button.scripts) and not next(button.attributes))
                    buttons[#buttons + 1] = button
                end
            end
        end
        return frame
    end
    return m, containers, buttons
end
local m, containers, buttons = setup()
local a = m.Start()
assert(#containers == 5 and #buttons == 50)
for index, container in ipairs(containers) do
    local row = a.View.rows[index]
    assert(container.parent == row and container.unit == row.unit and container.enabled)
    assert(container.filter == "HARMFUL" and container.options.maxFrameCount == 8)
    assert(container.point[2] == row.health and container.point[3] == "TOPRIGHT")
    assert(container.point[4] == 16 and container.options.layout.elementSpacing == 2)
end
for _, button in ipairs(buttons) do
    assert(button.cancelDisabled and button.icon and button.width == 12)
    assert(button.tooltipAnchor == "ANCHOR_RIGHT" and button.icon.parent == button)
end
local reads = m.auraReads
m.combat = true
for _, event in ipairs({"PLAYER_REGEN_DISABLED", "GROUP_ROSTER_UPDATE", "UNIT_AURA"}) do
    m.Event(event, "party1"); m.Flush()
end
assert(m.auraReads == reads and #containers == 5 and #buttons == 50)
m.Event("PLAYER_LEAVING_WORLD"); m.Flush()
m.combat = false
m.Event("PLAYER_ENTERING_WORLD"); m.Flush()
a.View.SetUnlocked(true); a.View.SetUnlocked(false)
assert(#containers == 5 and #buttons == 50)
for _, mode in ipairs({"missing", "restricted"}) do
    local other, absent = setup(mode)
    assert(other.Start().started and #absent == 0)
end
local deferred, deferredContainers = setup()
deferred.combat = true
local pending = deferred.Load(); deferred.Event("ADDON_LOADED", "ApogeeHeals")
assert(not pending.started and #deferredContainers == 0)
deferred.combat = false; deferred.Event("PLAYER_REGEN_ENABLED"); deferred.Flush()
assert(#deferredContainers == 5)
C_XMLUtil = previousXMLUtil
print("PASS native debuff configuration, fixed party units, no action/script overrides, combat initialization deferral and optional API guards")

local root = os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root == "" then print("SKIP native debuff source contracts (set APOGEE_FOREVER_EXPORT)"); return end
local function read(path)
    local file = assert(io.open(root .. "/Blizzard_AuraContainer/" .. path, "rb"))
    local data = file:read("*a"):gsub("\r\n", "\n"); file:close(); return data
end
local function definition(source, name)
    local start = assert(source:find("function " .. name, 1, true))
    local finish = assert(source:find("\nend", start, true))
    return source:sub(start, finish + 3)
end
-- Execute the exported group setup with mock engine dependencies. This checks
-- the inbound contract and trusted provider routing, not native taint enforcement.
local env = setmetatable({CustomAuraContainerSharedMixin={}}, {__index=_G})
env.IsNonEmptyString = function(value) return type(value) == "string" and value ~= "" end
env.AuraUtil = {IsValidFilterString=function(value) return value == "HARMFUL" end}
env.assertf = assert
env.GetInboundAddAuraGroupOptions = function(options) return options end
env.CustomAuraContainerConstants = {FrameCreationBatchSize=10, AccessRestrictionFlags=123}
env.Enum = {ForbiddenAspect={UntrustedLayoutScriptExecution=1}}
local allocated, registered, refreshed = false, false, false
env.AuraContainerUtil = {
    CreateCustomFrameProvider=function(_, description)
        assert(description.batchSize == 10 and description.accessRestrictions == 123)
        assert(not description.templateNames)
        return {CreateFrameBatch=function() allocated = true end}
    end,
    GetAuraSortComparator=function() return function() end end,
}
local native = assert(loadstring(definition(read("Blizzard_CustomAuraContainer.lua"),
    "CustomAuraContainerSharedMixin:AddAuraGroup")))
setfenv(native, env); native()
local container = {layoutOptionsByAuraGroup={}}
function container:HasAuraGroup() return false end
function container:RegisterAuraGroup(key, description)
    assert(allocated and key == "debuffs" and description.filterString == "HARMFUL")
    assert(description.maxFrameCount == 8); registered = true; return {}
end
function container:AddForbiddenAspects(value) assert(value == 1) end
function container:UpdateEventRegistrations() assert(registered) end
function container:UpdateAllAuras() refreshed = true end
env.CustomAuraContainerSharedMixin.AddAuraGroup(container, "debuffs", "HARMFUL", containers[1].options)
assert(refreshed)
assert(read("Blizzard_CustomAuraContainer.xml"):find('allowUntaintedCreation="true"', 1, true))
assert(read("Blizzard_AuraContainerFrameProviders.lua"):find('"CustomAuraButtonTemplate"', 1, true))
print("PASS matching-export harmful group setup, native frame provider and restricted layout contract; live acceptance remains separate")
