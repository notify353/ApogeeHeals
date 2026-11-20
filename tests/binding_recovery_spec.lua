local Mock = dofile("tests/mock.lua")
local root = os.getenv("APOGEE_HEALS_RUNTIME_ROOT")
local name = os.getenv("APOGEE_HEALS_RUNTIME_NAME") or "ApogeeHeals"
local function setup(defaults)
    local m = Mock.New()
    m.units.player.class = "PRIEST"
    local state = { known = true, metadata = true, rank = true, classification = true }
    Enum.SpellBookSpellBank = { Player = 0 }
    C_SpellBook = {
        IsSpellInSpellBook = function(id) return id == 2050 and state.known end,
        IsSpellKnown = function(id) return id == 2050 and state.known end,
    }
    C_Spell.GetSpellInfo = function(id)
        if not state.metadata then return nil end
        return {name="Lesser Heal", iconID=1, spellID=id}
    end
    C_Spell.GetSpellSubtext = function() if state.rank then return "Rank 1" end end
    C_Spell.IsSpellHelpful = function() if state.classification then return true end end
    C_Spell.IsSpellHarmful = function() return false end
    C_Spell.IsSpellPassive = function() return false end
    local a = {}
    local prefix = root and root .. "/" or ""
    a.__ApogeeFamilyAdmission = function(n) return n == name end
    for line in io.lines(prefix .. name .. ".toc") do
        if line:match("%.lua$") and not line:match("^__Distribution/") then
            assert(loadfile(prefix .. line))(name, a)
        end
    end
    _G[name .. "DB"] = {bindings={}, defaultSpells={enabled=defaults == true,time=1,serial=0}}
    if not defaults then
        for _, slot in ipairs(a.Bindings.slots) do _G[name .. "DB"].bindings[slot.id] = 2050 end
    end
    m.addon = a; m.Event("ADDON_LOADED", name); m.Flush()
    local rows = {unpack(a.View.rows)}
    rows[#rows+1] = a.View.target; rows[#rows+1] = a.View.targetTarget
    return m, a, state, rows
end
local function expect(rows, active)
    for _, row in ipairs(rows) do
        assert(row.attributes.type1 == (active and "macro" or ""), "all-recipient healing state")
        assert(row.attributes.unit == row.unit)
        if active then
            assert(row.attributes.macrotext1 == "/cast [@" .. row.unit .. ",exists,help] Lesser Heal(Rank 1)\n/stopspelltarget")
        else assert(row.attributes.macrotext1 == nil) end
    end
end
for _, field in ipairs({"metadata", "rank", "classification"}) do
    local m, a, state, rows = setup()
    expect(rows, true)
    state[field] = false; m.Event("SPELLS_CHANGED")
    expect(rows, false)
    state[field] = true
    -- No further spell/combat event and no reload: the runtime must recover itself.
    for i=1,4 do m.Flush() end
    expect(rows, true)
    for _,row in ipairs(rows) do
        for _,slot in ipairs(a.Bindings.slots) do assert(row.attributes[slot.id:gsub("(%d)$", "type%1")] == "macro") end
    end
end
print("PASS transient spell/name/rank/classification failures recover every healing slot without another event")

do
    local m, a, state, rows = setup()
    local writes = 0
    for _,row in ipairs(rows) do
        local original = row.SetAttribute
        row.SetAttribute = function(self, key, value) writes=writes+1; original(self,key,value) end
    end
    for i=1,10 do a.Bindings.Apply() end
    assert(writes == 0, "unchanged actions must not rewrite protected attributes")
    state.rank = false; m.Event("SPELL_TEXT_UPDATE"); expect(rows,false)
    state.rank = true
    m.combat = true; writes=0
    m.Flush()
    assert(writes == 0 and a.Bindings.pending)
    expect(rows,false)
    m.combat=false; m.Event("PLAYER_REGEN_ENABLED"); expect(rows,true)
    state.metadata=false; m.Event("SPELLS_CHANGED")
    m.Event("PLAYER_LEAVING_WORLD")
    state.metadata=true; writes=0; m.Flush()
    assert(writes==0 and a.Bindings.pending and a.Runtime.suspended)
    m.Event("PLAYER_ENTERING_WORLD"); expect(rows,true)
end
print("PASS unchanged bindings avoid writes; recovery pauses during combat/loading and resumes safely")

do
    local m,a,state,rows=setup(true)
    state.metadata=false; m.Event("SPELLS_CHANGED")
    expect(rows,false) -- Unknown automatic heal must not silently become targeting.
    assert(a.Bindings.retryNeeded and a.db.bindings['1']==nil)
    local delays={}
    local after=C_Timer.After
    C_Timer.After=function(delay,callback) delays[#delays+1]=delay; after(delay,callback) end
    for i=1,20 do m.Flush() end
    assert(a.Bindings.retryNeeded and #delays>=20)
    for _,delay in ipairs(delays) do assert(delay>=0.25 and delay<=5) end
    state.metadata=true; m.Flush(); expect(rows,true)
    assert(not a.Bindings.retryNeeded and not a.Bindings.retryToken)
end
print("PASS missing default metadata stays inactive and recovers after prolonged unavailability with bounded backoff")

do
    local m,a,state,rows=setup()
    state.rank=false; m.Event("SPELL_TEXT_UPDATE")
    local token=a.Bindings.retryToken
    assert(token)
    for i=1,15 do a.Bindings.Apply() end
    assert(a.Bindings.retryToken==token,"only one recovery timer may be queued")
    state.rank=true
    m.Event("SPELL_DATA_LOAD_RESULT",2050,m.Secret()); expect(rows,false)
    m.Event("SPELL_DATA_LOAD_RESULT",2050,false); expect(rows,false)
    m.Event("SPELL_DATA_LOAD_RESULT",2050,true); expect(rows,true)
    assert(not a.Bindings.retryToken and not a.Bindings.retryNeeded)
    -- Old timer must not restore an assignment removed after the successful event.
    assert(a.Bindings.Put("1",nil)); m.Flush()
    for _,row in ipairs(rows) do assert(row.attributes.type1=="target" and row.attributes.spell1==nil) end
end
print("PASS data-ready event, restricted/failed result guards, coalescing and stale callback cancellation")

do
    local m,a,state,rows=setup()
    state.metadata=false; m.Event("SPELLS_CHANGED")
    state.known=false; m.Flush()
    expect(rows,false)
    assert(not a.Bindings.retryNeeded,"definitely unlearned spells must not poll")
    state.known=true; state.metadata=true
    m.Event("SPELLS_CHANGED"); expect(rows,true)
    C_Spell.IsSpellHarmful=function() return true end
    a.Bindings.Apply(); expect(rows,false); assert(not a.Bindings.retryNeeded)
    C_Spell.IsSpellHarmful=function() return m.Secret() end
    a.Bindings.Apply(); expect(rows,false); assert(a.Bindings.retryNeeded)
    C_Spell.IsSpellHarmful=function() error("temporary API failure") end
    m.Flush(); expect(rows,false); assert(a.Bindings.retryNeeded)
    C_Spell.IsSpellHarmful=function() return false end
    m.Flush(); expect(rows,true)
    C_Spell.GetSpellSubtext=function() return "Rank 1\n/cast Other" end
    a.Bindings.Apply(); expect(rows,false); assert(not a.Bindings.retryNeeded)
end
print("PASS unlearned/hostile/injected programs remain rejected; throwing/restricted metadata can recover")

do
    local m,a,state,rows=setup()
    state.metadata=false; m.Event("SPELLS_CHANGED")
    a.startupState="failed"; state.metadata=true
    m.Flush(); expect(rows,false)
    assert(not a.Bindings.retryNeeded and not a.Bindings.retryToken)
    a.Bindings.Apply(); expect(rows,false)
end
print("PASS retries never revive a failed startup")

do
    local m,a,state,rows=setup()
    C_SpellBook.IsSpellKnown=function() return m.Secret() end
    m.Event("SPELLS_CHANGED"); expect(rows,false)
    assert(a.Bindings.retryNeeded)
    C_SpellBook.IsSpellKnown=function() return true end
    m.Flush(); expect(rows,true)
    C_Spell.GetSpellSubtext=nil
    a.Bindings.Apply(); expect(rows,false)
    assert(not a.Bindings.retryNeeded, "absent capabilities must not cause endless polling")
    C_Spell.GetSpellInfo=nil
    a.Bindings.Apply(); assert(not a.Bindings.retryNeeded)
end
print("PASS unreadable spell-book recovery and missing-capability polling guard")

do
    local m,a,state,rows=setup()
    Enum.ItemClass={Consumable=0}; Enum.ItemConsumableSubclass={Bandage=7}
    local ready=true
    C_Item={GetItemInfoInstant=function(id)
        if ready then return id,nil,nil,nil,1,0,7 end
    end}
    assert(a.Bindings.Put("1",{kind="item",id=1251}))
    ready=false; a.Bindings.Apply()
    for _,row in ipairs(rows) do assert(row.attributes.type1=="") end
    ready=true; m.Flush()
    for _,row in ipairs(rows) do assert(row.attributes.type1=="item" and row.attributes.item1=="item:1251") end
    assert(a.db.bindings['1'].id==1251 and not a.Bindings.retryNeeded)
end
print("PASS healing-item metadata recovers without changing the saved assignment")

do
    local m,a,state,rows=setup()
    local original=a.BindingEditor.Refresh
    a.BindingEditor.Refresh=function() error("cosmetic refresh failure") end
    state.rank=false
    assert(not pcall(a.Bindings.Apply))
    assert(a.Bindings.retryToken,"cosmetic error must not prevent recovery scheduling")
    a.BindingEditor.Refresh=original; state.rank=true
    m.Flush(); expect(rows,true)
    for _,row in ipairs(rows) do row.GetAttribute=function() return m.Secret() end end
    assert(a.Bindings.Put('1',nil))
    for _,row in ipairs(rows) do
        assert(row.attributes.type1=='target' and row.attributes.macrotext1==nil and row.attributes.spell1==nil)
    end
end
print("PASS cosmetic failure preserves recovery; unavailable attribute reads never skip stale-action clearing")
