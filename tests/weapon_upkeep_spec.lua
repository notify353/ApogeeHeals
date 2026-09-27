local Mock = dofile("tests/mock.lua")
local oldXML, oldSlots = C_XMLUtil, AuraContainerItemEnchantmentSlot
local function setup(class, mode)
    local m = Mock.New()
    m.units.player.class = class
    local a = {View={}, Runtime={}, UnitAPI={State=function() return m.state or "alive" end}}
    a.Style = {sideIconSize=19.5, sideIconGap=2, Text=function(parent) return parent:CreateFontString() end}
    assert(loadfile("Core/Access.lua"))("ApogeeHeals", a)
    local containers, buttons = {}, {}
    C_XMLUtil = {GetTemplateInfo=function()
        if mode == "missing" then return nil end
        if mode == "restricted" then return m.InaccessibleTable() end
        return {type="AuraContainer"}
    end}
    AuraContainerItemEnchantmentSlot = mode == "slots" and m.InaccessibleTable() or {MainHand=0, OffHand=1}
    local create = CreateFrame
    CreateFrame = function(kind, name, parent, template)
        local f = create(kind, name, parent, template)
        if template == "SecureHandlerStateTemplate" then f.protected = true end
        if template == "CustomAuraContainerTemplate" then
            assert(not m.combat)
            containers[#containers + 1] = f
            function f:SetUnit(unit) assert(unit == "player"); self.unit = unit end
            function f:SetItemEnchantmentLayout(options) self.layout = options end
            function f:AddItemEnchantment(slot, options)
                self.slot, self.options = slot, options
                local button = create("AuraButton", nil, self, "CustomAuraButtonTemplate")
                function button:SetCancelAuraButtons(value) assert(value == nil); self.cancelDisabled = true end
                function button:SetTooltipAnchorPoint(value) self.anchor = value end
                function button:SetIcon(value) self.icon = value end
                if mode ~= "no-duration" then
                    function button:SetDurationText(value, options) self.durationText = value; assert(next(options) == nil) end
                end
                options.initializeFrame(button)
                assert(next(button.scripts) == nil and next(button.attributes) == nil)
                assert(not options.templateNames and options.hidePermanent == false)
                buttons[#buttons + 1] = button
            end
        end
        return f
    end
    assert(loadfile("WeaponUpkeep/Runtime.lua"))("ApogeeHeals", a)
    local row = create("Frame", nil, UIParent); row.unit = "player"; row.health = create("Frame", nil, row)
    return m, a, row, containers, buttons
end
for _, class in ipairs({"ROGUE", "SHAMAN", "WARLOCK"}) do
    local m, a, row, containers, buttons = setup(class)
    a.WeaponUpkeep.Refresh(row, 3)
    assert(#containers == 2 and #buttons == 2 and row.weaponUpkeep.alpha == 1)
    assert(row.weaponUpkeep.point[4] == -2 - 3 * 21.5)
    for i, container in ipairs(containers) do
        assert(container.slot == i - 1 and container.unit == "player" and container.enabled)
        assert(container.point[4] == -(i - 1) * 21.5 and container.width == 19.5)
        assert(container.layout.elementHeight == 19.5 and container.layout.elementSpacing == 2)
        assert(buttons[i].cancelDisabled and buttons[i].anchor == "ANCHOR_LEFT")
        assert(buttons[i].icon and buttons[i].durationText)
    end
    local point = row.weaponUpkeep.point
    m.combat = true
    a.WeaponUpkeep.Refresh(row, 8); a.WeaponUpkeep.Create(row); a.WeaponUpkeep.Stop()
    assert(row.weaponUpkeep.point == point and row.weaponUpkeep.alpha == 0)
    assert(not containers[1].enabled and not containers[2].enabled and #containers == 2)
    m.combat = false
    a.WeaponUpkeep.Refresh(row, 1)
    assert(row.weaponUpkeep.point[4] == -23.5 and containers[1].enabled)
    for _, unit in ipairs({"party1", "party4", "target", "targettarget"}) do
        a.WeaponUpkeep.Refresh({unit=unit}, 0); a.WeaponUpkeep.Create({unit=unit})
    end
    assert(#containers == 2)
    a.View.unlocked = true; a.WeaponUpkeep.Refresh(row, 0); assert(not containers[1].enabled)
    a.View.unlocked = false; a.Runtime.suspended = true
    a.WeaponUpkeep.Refresh(row, 0); assert(not containers[1].enabled)
    a.Runtime.suspended = false; m.state = "dead"
    a.WeaponUpkeep.Refresh(row, 0); assert(not containers[1].enabled)
    m.state = "alive"; a.WeaponUpkeep.Refresh(row, m.Secret()); assert(not containers[1].enabled)
    a.WeaponUpkeep.Refresh(row, 0); assert(containers[1].enabled)
    assert(m.auraReads == 0)
end
for _, mode in ipairs({"missing", "restricted", "slots"}) do
    local _, a, row, containers = setup("ROGUE", mode)
    a.WeaponUpkeep.Refresh(row, 0); assert(#containers == 0 and not row.weaponUpkeep)
end
local m, a, row, containers, buttons = setup("PRIEST")
a.WeaponUpkeep.Refresh(row, 0); assert(#containers == 0)
m.units.player.class = m.Secret(); a.WeaponUpkeep.Refresh(row, 0); assert(#containers == 0)
m, a, row, containers, buttons = setup("ROGUE", "no-duration")
m.combat = true; a.WeaponUpkeep.Create(row); assert(#containers == 0)
m.combat = false; a.WeaponUpkeep.Refresh(row, 0)
assert(#containers == 2 and buttons[1].icon and not buttons[1].durationText)
C_XMLUtil, AuraContainerItemEnchantmentSlot = oldXML, oldSlots
print("PASS player-only native weapon enchants, fixed hands, class isolation, no aura reads/actions, combat/preview/world cleanup and optional capability guards")

local root = os.getenv("APOGEE_FOREVER_EXPORT")
if not root or root == "" then print("SKIP native weapon enchant contracts (set APOGEE_FOREVER_EXPORT)"); return end
local function read(path)
    local f = assert(io.open(root .. "/Blizzard_AuraContainer/" .. path, "rb"))
    local text = f:read("*a"):gsub("\r\n", "\n"); f:close(); return text
end
local function definition(source, name)
    local first = assert(source:find("function " .. name, 1, true))
    local last = assert(source:find("\nend", first, true))
    return source:sub(first, last + 3)
end
local env = setmetatable({CustomAuraContainerSharedMixin={}, assertf=assert,
    ValidateItemEnchantmentSlot=function(slot) assert(slot == 0 or slot == 1) end,
    GetInboundAddItemEnchantmentOptions=function(options) return options end,
    AuraContainerDirtyMask={AuraFrameLayoutGroups=1}}, {__index=_G})
local fn = assert(loadstring(definition(read("Blizzard_CustomAuraContainer.lua"),
    "CustomAuraContainerSharedMixin:AddItemEnchantment")))
setfenv(fn, env); fn()
local native = {}
function native:HasItemEnchantment() return false end
function native:CreateAuraSlotFrame(options) assert(not options.templateNames); return {} end
function native:RegisterItemEnchantment(slot, description) self.slot=slot; assert(description.hidePermanent == false) end
function native:RequestFrameAssignmentRefresh() self.refreshed=true end
function native:MarkDirty(flag) assert(flag == 1) end
env.CustomAuraContainerSharedMixin.AddItemEnchantment(native, 0, containers[1].options)
assert(native.slot == 0 and native.refreshed)
assert(read("Blizzard_AuraButton.lua"):find('tooltip:SetInventoryItem(unitToken, auraData.inventorySlot)', 1, true))
assert(read("Blizzard_CustomAuraButton.lua"):find('function CustomAuraButtonSharedMixin:SetDurationText', 1, true))
assert(read("Blizzard_AuraContainerEnchantments.lua"):find('local ItemEnchantmentUnitToken = "player"', 1, true))
assert(read("Blizzard_AuraContainer.lua"):find('frameEvents["WEAPON_ENCHANT_CHANGED"] = true', 1, true))
print("PASS matching-export enchant setup, player ownership, native inventory tooltip/duration and enchant events; live engine acceptance remains separate")
