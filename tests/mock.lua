local M = {}
function M.New()
    local m = { frames = {}, timers = {}, combat = false, raid = false, units = {
        player = { name = "Priest", health = 80, maxHealth = 100, power = 50, maxPower = 100,
            kind = 0, connected = true, dead = false, auras = {} },
    }, auraReads = 0 }
    local methods = {}
    local function protected(self)
        if m.combat and self.protected then error("protected operation during combat") end
    end
    local function object(kind, name, parent, template)
        local f = setmetatable({ kind = kind, name = name, parent = parent, template = template,
            scripts = {}, events = {}, attributes = {}, shown = true, scale = 1 }, { __index = methods })
        if template == "SecureActionButtonTemplate" then
            f.protected = true
            local p = parent
            while p and p ~= UIParent do p.protected = true; p = p.parent end
        end
        m.frames[#m.frames + 1] = f
        if name then _G[name] = f end
        return f
    end
    function methods:SetSize(w, h) protected(self); self.width, self.height = w, h end
    function methods:SetHeight(h) self.height = h end
    function methods:SetScrollChild(child) self.scrollChild = child end
    function methods:SetPoint(...) protected(self); self.point = {...} end
    function methods:ClearAllPoints() protected(self); self.point = nil end
    function methods:SetScale(s) protected(self); self.scale = s end
    function methods:SetFrameLevel(value) protected(self); self.level = value end
    function methods:SetFrameStrata(value) self.strata = value end
    function methods:IsShown() return self.shown end
    function methods:SetVertexColor(...) self.vertexColor = {...} end
    function methods:SetHighlightTexture(value) self.highlight = value end
    function methods:IsMouseOver() return self.hovered == true end
    function methods:GetFrameLevel() return self.level or 1 end
    function methods:SetAlpha(value) self.alpha = value end
    function methods:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetLeft() return self.left or 300 end
    function methods:GetTop() return self.top or 400 end
    function methods:GetBottom() return self.bottom or 402 end
    function methods:SetMovable(v) protected(self); self.movable = v end
    function methods:SetClampedToScreen() protected(self) end
    function methods:SetClipsChildren(value) protected(self); self.clipsChildren = value end
    function methods:StartMoving() protected(self); self.moving = true end
    function methods:StopMovingOrSizing() protected(self); self.moving = false end
    function methods:Show()
        protected(self); local changed = not self.shown; self.shown = true
        if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide()
        protected(self); local changed = self.shown; self.shown = false
        if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:SetShown(v) if v then self:Show() else self:Hide() end end
    function methods:SetAttribute(k, v) protected(self); self.attributes[k] = v end
    function methods:GetAttribute(k) return self.attributes[k] end
    function methods:RegisterForClicks(...) protected(self); self.clicks = {...} end
    function methods:RegisterForDrag(...) self.drags = {...} end
    function methods:EnableMouse(v) self.mouse = v end
    function methods:SetScript(k, v) self.scripts[k] = v end
    function methods:RegisterEvent(e) self.events[e] = true end
    function methods:UnregisterEvent(e) self.events[e] = nil end
    function methods:UnregisterAllEvents() self.events = {} end
    function methods:CreateTexture() return object("Texture", nil, self) end
    function methods:CreateFontString() return object("FontString", nil, self) end
    function methods:SetAllPoints() end
    function methods:SetColorTexture(...) self.color = {...} end
    function methods:SetTexture(value) self.texture = value end
    function methods:SetTexCoord(...) self.texCoord = {...} end
    function methods:SetStatusBarColor(...) self.color = {...} end
    function methods:SetStatusBarTexture(v) self.texture = v; self.fill = object("Texture", nil, self) end
    function methods:GetStatusBarTexture() return self.fill end
    function methods:SetMinMaxValues(lo, hi) assert(hi ~= nil); self.min, self.max = lo, hi end
    function methods:SetValue(v) assert(v ~= nil); self.value = v end
    function methods:SetText(v) self.text = v end
    function methods:SetFormattedText(pattern, ...) self.text = string.format(pattern, ...) end
    function methods:SetTextColor(...) self.color = {...} end
    function methods:GetFont() return "font", 11, "" end
    function methods:SetFont(...) self.font = {...} end
    function methods:SetWordWrap(v) self.wrap = v end
    function methods:SetJustifyH(v) self.justify = v end
    function methods:SetJustifyV(v) self.justifyV = v end
    function methods:SetShadowColor(...) self.shadowColor = {...} end
    function methods:SetShadowOffset(...) self.shadowOffset = {...} end
    function methods:SetChecked(v) self.checked = v end
    function methods:GetChecked() return self.checked end
    function methods:SetEnabled(v) self.enabled = v end
    UIParent = object("Frame"); UIParent.width, UIParent.height = 1920, 1080
    Minimap = object("Frame", nil, UIParent)
    CreateFrame = object
    InCombatLockdown = function() return m.combat end
    GetTime = function() return m.time or 0 end
    UnitIsUnit = function(a, b) return a == b end
    WOW_PROJECT_ID = 1
    GetBuildInfo = function() return "1.60.1", "69913", "", 16001 end
    local secrets = setmetatable({}, {__mode = "k"})
    function m.Secret()
        local x = setmetatable({}, { __add = function() error("secret arithmetic") end,
            __sub = function() error("secret arithmetic") end, __div = function() error("secret arithmetic") end,
            __lt = function() error("secret comparison") end, __concat = function() error("secret concatenation") end })
        secrets[x] = true; return x
    end
    issecretvalue = function(v) return secrets[v] == true end
    canaccessvalue = function(v) return not secrets[v] end
    UnitExists = function(u) return m.units[u] ~= nil end
    UnitLevel = function(u) return m.units[u] and (m.units[u].level or 60) end
    UnitClass = function(u) return "Localized class", m.units[u] and (m.units[u].class or "PRIEST") end
    m.classColors = { PRIEST={1,1,1}, WARRIOR={0.78,0.61,0.43}, MAGE={0.25,0.78,0.92},
        ROGUE={1,0.96,0.41}, DRUID={1,0.49,0.04} }
    C_ClassColor = {GetClassColor = function(token)
        local rgb=m.classColors[token]
        if rgb then return {GetRGB=function() return unpack(rgb) end} end
    end}
    for api, field in pairs({ UnitName = "name", UnitHealth = "health", UnitHealthMax = "maxHealth",
        UnitPower = "power", UnitPowerMax = "maxPower", UnitPowerType = "kind",
        UnitIsConnected = "connected", UnitIsDeadOrGhost = "dead" }) do
        local key = field
        _G[api] = function(u) return m.units[u] and m.units[u][key] end
    end
    UnitHealthPercent = function() return { GetRGBA = function() return 0.28, 0.74, 0.46, 1 end } end
    PowerBarColor = { [1] = {r = 1, g = 0, b = 0}, [3] = {r = 1, g = 1, b = 0} }
    CreateColor = function(...) return {...} end
    Enum = { LuaCurveType = { Step = 1 } }
    Enum.UnitMaximumHealthMode = { Default = 0 }
    Enum.UnitIncomingHealClampMode = { MissingHealth = 0 }
    Enum.UnitHealAbsorbMode = { ReducedByIncomingHeals = 0 }
    CreateUnitHealPredictionCalculator = function()
        return {
            SetMaximumHealthMode = function(self, value) self.healthMode = value end,
            SetIncomingHealClampMode = function(self, value) self.clampMode = value end,
            SetIncomingHealOverflowPercent = function(self, value) self.overflow = value end,
            SetHealAbsorbMode = function(self, value) self.absorbMode = value end,
            ResetPredictedValues = function(self) self.maximum, self.incoming = 0, 0 end,
            GetMaximumHealth = function(self) return self.maximum end,
            GetIncomingHeals = function(self) return self.incoming, 123, 456, false end,
        }
    end
    UnitGetDetailedHealPrediction = function(unit, healer, calculator)
        assert(healer == nil)
        if m.predictionError then error("prediction unavailable") end
        if m.predictionEmpty then return end
        local data = m.units[unit]
        calculator.maximum = data.maxHealth
        if m.secretPrediction then calculator.incoming = m.secretPrediction
        else
            -- Engine simulation only. Addon code must never perform this arithmetic.
            if issecretvalue(data.health) or issecretvalue(data.maxHealth) then error("supply secret fixture") end
            calculator.incoming = math.min(math.max(0, (data.incoming or 0) - (data.healAbsorb or 0)),
                math.max(0, data.maxHealth - data.health))
        end
    end
    C_CurveUtil = { CreateColorCurve = function()
        return { SetType = function() end, AddPoint = function() end }
    end }
    C_Timer = { After = function(_, callback) m.timers[#m.timers + 1] = callback end }
    C_Spell = { GetSpellInfo = function(id)
        if id == 430 then return { name = "Drink", spellID = id } end
    end }
    C_UnitAuras = { GetAuraDataByIndex = function(u, i, filter)
        assert(filter == "HELPFUL"); m.auraReads = m.auraReads + 1
        if m.auraError then error("restricted") end
        return m.units[u] and m.units[u].auras[i]
    end }
    RegisterStateDriver = function(f, state, expression)
        protected(f); assert(state == "visibility"); f.driver = expression
    end
    Settings = {
        RegisterCanvasLayoutCategory = function(panel, title) return {panel = panel, title = title} end,
        RegisterAddOnCategory = function(category) m.category = category end,
    }
    ApogeeHealsDB = nil
    UISpecialFrames = {}
    GetCursorInfo = function() if m.cursor then return unpack(m.cursor) end end
    ClearCursor = function() m.cursor = nil end
    GameTooltip = { Hide=function() end, Show=function() end, SetOwner=function() end,
        SetText=function() end, AddLine=function() end }
    function m.Flush()
        local queue = m.timers; m.timers = {}
        for _, callback in ipairs(queue) do callback() end
    end
    function m.Event(event, ...)
        local count = #m.frames
        for i = 1, count do
            local frame = m.frames[i]
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    function m.Load()
        local addon = {}
        for line in io.lines("ApogeeHeals.toc") do
            if line:match("%.lua$") then assert(loadfile(line))("ApogeeHeals", addon) end
        end
        m.addon = addon
        return addon
    end
    function m.Start()
        local addon = m.Load(); m.Event("ADDON_LOADED", "ApogeeHeals"); m.Flush(); return addon
    end
    return m
end
return M
