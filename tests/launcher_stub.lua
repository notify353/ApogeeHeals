-- Component-unit-test dependency double. Real launcher is tested separately and in generated packages.
ApogeeUI={apiVersion=1,components={}}
function ApogeeUI.EnsureSettingsParent()
    if type(Settings.RegisterCanvasLayoutSubcategory) ~= "function" then
        return {schema=1,children={}}
    end
    local registry = _G.ApogeeSettingsRegistry
    if registry ~= nil and (type(registry) ~= "table" or registry.schema ~= 1
        or type(registry.category) ~= "table" or type(registry.category.GetID) ~= "function"
        or type(registry.children) ~= "table") then return nil end
    if not registry then
        local parentName = ("Apogee"):sub(-3) == "Dev" and "Apogee DEV" or "Apogee"
        local overview = CreateFrame("Frame")
        local background = overview:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(overview)
        background:SetColorTexture(0.035, 0.035, 0.045, 0.96)
        local title = overview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16); title:SetText(parentName)
        local description = overview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        description:SetPoint("TOPLEFT", 16, -52)
        description:SetPoint("TOPRIGHT", -16, -52)
        description:SetJustifyH("LEFT"); description:SetTextColor(0.8, 0.8, 0.8)
        description:SetText("Select an enabled addon's settings from the list on the left.")
        local parent = Settings.RegisterCanvasLayoutCategory(overview, parentName)
        Settings.RegisterAddOnCategory(parent)
        registry = {schema = 1, category = parent, children = {}}
        _G.ApogeeSettingsRegistry = registry
    end
    return registry
end
function ApogeeUI.RegisterSettings(_,panel,label)
    if type(Settings.RegisterCanvasLayoutSubcategory) ~= "function" then return Settings.RegisterCanvasLayoutCategory(panel,"Apogee "..label) end
    local r=ApogeeUI.EnsureSettingsParent(); if not r then return end
    if r.children[label] then return r.children[label] end
    local c=Settings.RegisterCanvasLayoutSubcategory(r.category,panel,label); r.children[label]=c; return c
end
function ApogeeUI.RegisterComponent(id,p) ApogeeUI.components[id]=p; return true end
function ApogeeUI.RefreshComponent() end
function ApogeeUI.UnregisterComponent(id) ApogeeUI.components[id]=nil end
