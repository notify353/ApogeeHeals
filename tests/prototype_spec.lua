local Mock = dofile("tests/mock.lua")
local count = 0
local function test(name, fn)
    fn(); count = count + 1; print("PASS " .. name)
end
local function equal(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
test("composition, fixed geometry and native targeting", function()
    local m = Mock.New(); local a = m.Start()
    equal(#a.View.rows, 5); equal(a.View.root.scale, 2)
    for i, row in ipairs(a.View.rows) do
        equal(row.attributes.unit, i == 1 and "player" or "party" .. (i - 1))
        equal(row.attributes.type1, "target"); equal(row.attributes.type2, "")
        equal(row.clicks[1], "LeftButtonUp"); equal(row.health.width, 112)
        equal(row.health.height, 14); equal(row.power.height, 5)
        equal(row.power.point[5], -14.5); equal(row.name.wrap, false)
        equal(row.driver, "[group:raid] hide; [@" .. row.unit .. ",exists] show; hide")
        assert(row.template == "SecureActionButtonTemplate")
    end
    equal(a.View.rows[1].health.value, 80); equal(a.View.rows[1].name.text, "Priest")
    equal(a.View.rows[2].health.value, 0); equal(a.View.handle.shown, false)
    equal(m.category.title, "Apogee Heals")
end)
test("roster changes never rewrite protected unit buttons in combat", function()
    local m = Mock.New(); local a = m.Start(); m.combat = true
    m.units.party1 = {name="Warrior", health=70,maxHealth=100,power=30,maxPower=100,kind=1,connected=true,dead=false,auras={}}
    m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
    equal(a.View.rows[2].health.value, 70); equal(a.View.rows[2].power.color[1], 0.78)
    m.units.party1.kind = 3; m.Event("UNIT_DISPLAYPOWER", "party1"); m.Flush()
    equal(a.View.rows[2].power.color[2], 0.73)
    m.units.party1 = nil; m.Event("GROUP_ROSTER_UPDATE"); m.Flush()
    equal(a.View.rows[2].health.value, 0); equal(a.View.rows[2].name.text, "")
end)
test("dead, offline, missing and unknown states clear stale bars", function()
    local m = Mock.New(); local a = m.Start(); local row = a.View.rows[1]
    m.units.player.dead = true; a.View.Refresh(); equal(row.status.text, "DEAD"); equal(row.health.value, 0)
    m.units.player.connected = false; a.View.Refresh(); equal(row.status.text, "OFFLINE")
    m.units.player.connected = m.Secret(); a.View.Refresh(); equal(row.health.value, 0)
    m.units.player = nil; a.View.Refresh(); equal(row.name.text, ""); equal(row.status.text, "")
end)
test("restricted health and power reach native sinks; restricted names stay blank", function()
    local m = Mock.New(); local a = m.Start()
    local secret = m.Secret()
    for _, field in ipairs({"health", "maxHealth", "power", "maxPower", "name"}) do m.units.player[field] = secret end
    a.View.Refresh(); local row = a.View.rows[1]
    equal(row.health.value, secret); equal(row.health.max, secret); equal(row.name.text, "")
    equal(row.power.value, secret)
    m.units.player.kind = secret; a.View.Refresh(); equal(row.power.value, 0)
    UnitHealth = function() error("unavailable") end
    a.View.Refresh(); equal(row.health.value, 0)
end)
test("player labels show first names only and refresh when a name changes", function()
    local m = Mock.New(); local a = m.Start(); local row = a.View.rows[1]
    for _, example in ipairs({{"Anduin Wrynn", "Anduin"}, {"Anduin-Wrynn", "Anduin"},
        {"Priest", "Priest"}, {"Élodie Dubois", "Élodie"}, {"", ""}}) do
        m.units.player.name = example[1]; a.View.Refresh(); equal(row.name.text, example[2])
    end
    local previous = Constants
    Constants = {CharacterNameSeparatorConsts={CHARACTERNAME_SURNAME_SEPARATOR="·"}}
    m.units.player.name = "Anduin·Wrynn"; a.View.Refresh(); equal(row.name.text, "Anduin")
    Constants = previous
end)
test("confirmed drinks, localized identities and unavailable auras", function()
    local m = Mock.New(); local a = m.Start(); local row = a.View.rows[1]
    m.units.player.auras = {{spellId=430,name="Drink"}}; a.View.Refresh(); equal(row.drinkIcon.shown, true)
    m.units.player.auras = {}; a.View.Refresh(); equal(row.status.text, "")
    C_Spell.GetSpellInfo = function(id) if id == 430 then return {spellID=id,name="Boisson"} end end
    a.Drinking.Resolve(); m.units.player.auras={{spellId=999,name="Boisson"}}
    a.View.Refresh(); equal(row.drinkIcon.shown, true)
    m.units.player.auras[2]={spellId=m.Secret(),name="Unreadable"}
    a.View.Refresh(); equal(row.status.text, "")
    m.auraError=true; a.View.Refresh(); equal(row.status.text, "")
    m.auraError=false; C_Spell.GetSpellInfo=function() return nil end
    a.Drinking.Resolve(); m.units.player.auras={{spellId=430,name="Drink"}}
    a.View.Refresh(); equal(row.status.text, "")
end)
test("combat immediately clears drinking and cancels unlocked dragging safely", function()
    local m = Mock.New(); local a = m.Start()
    m.units.player.auras={{spellId=430,name="Drink"}}; a.View.Refresh()
    a.View.SetUnlocked(true); a.View.handle.scripts.OnDragStart()
    a.View.handle.scripts.OnUpdate(); assert(a.View.dragging)
    m.combat=true; m.Event("PLAYER_REGEN_DISABLED")
    equal(a.View.rows[1].status.text, ""); equal(a.View.unlocked, false)
    equal(a.View.dragging, false); equal(a.View.handle.scripts.OnUpdate, nil)
    equal(a.Settings.unlock.enabled, false); m.Flush()
    local reads = m.auraReads; a.View.Refresh(); equal(m.auraReads, reads)
    m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush()
    equal(a.View.rows[1].drinkIcon.shown, true); equal(a.View.unlocked, false)
end)
test("events coalesce, filter unrelated units and remain idle afterward", function()
    local m = Mock.New(); local a = m.Start()
    m.Event("UNIT_HEALTH", "target"); equal(#m.timers, 0)
    m.Event("UNIT_HEALTH", "player"); m.Event("UNIT_AURA", "player"); m.Event("GROUP_ROSTER_UPDATE")
    equal(#m.timers, 1); m.Flush(); equal(#m.timers, 0)
    equal(a.Runtime.driver.scripts.OnUpdate, nil)
end)
test("finishing a drag saves position and synchronizes the lock control", function()
    local m = Mock.New(); local a = m.Start()
    a.View.SetUnlocked(true); a.Settings.Refresh(); equal(a.Settings.unlock.checked, true)
    a.View.handle.scripts.OnDragStart(); a.View.handle.scripts.OnUpdate()
    a.View.handle.scripts.OnDragStop()
    equal(a.View.unlocked, false); equal(a.Settings.unlock.checked, false)
    equal(a.View.handle.scripts.OnUpdate, nil); equal(a.db.position.x, -180)
    local saved = a.db
    local m2 = Mock.New(); local a2 = m2.Load(); ApogeeHealsDB = saved
    m2.Event("ADDON_LOADED", "ApogeeHeals"); m2.Flush()
    equal(a2.db.position.x, saved.position.x); equal(a2.View.unlocked, false)
end)
test("position validation, persistence and future-schema preservation", function()
    local m = Mock.New(); local a = m.Load()
    ApogeeHealsDB = {version=1,position={x=-123,y=45}}
    m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush()
    equal(a.db.position.x, -123); equal(a.db.position.y, 45)
    local invalid = a.Storage.Open({version=1,position={x=0/0,y=math.huge}})
    equal(invalid.position.x, 70.5); equal(invalid.position.y, -45)
    a.db.position={x=90000,y=-90000}; a.View.ApplyPosition()
    assert(a.db.position.x <= 353); assert(a.db.position.y >= -164.5)
    a.View.ResetPosition(); equal(a.db.position.x, 70.5); equal(a.db.position.y, -45)
    m.combat=true; a.View.ResetPosition(); a.View.SetUnlocked(true); equal(a.View.unlocked, false)
    local m2 = Mock.New(); local a2 = m2.Load()
    local future = {version=9,position={x=1,y=2}}; ApogeeHealsDB=future
    m2.Event("ADDON_LOADED", "ApogeeHeals")
    equal(ApogeeHealsDB, future); equal(a2.started, nil)
end)
test("combat login defers all secure construction until combat ends", function()
    local m = Mock.New(); m.combat=true; local a=m.Load()
    m.Event("ADDON_LOADED", "ApogeeHeals"); equal(a.started, nil)
    m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); m.Flush(); equal(a.started, true)
end)
test("unsupported clients create no gameplay frames or saved data", function()
    local m = Mock.New(); local a=m.Load(); WOW_PROJECT_ID=2
    m.Event("ADDON_LOADED", "ApogeeHeals"); equal(a.started, nil); equal(ApogeeHealsDB, nil)
end)
print(count .. " prototype scenarios passed")
