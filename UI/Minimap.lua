local _, A = ...
local M = {}; A.Minimap = M
local function service() return type(ApogeeUI) == "table" and ApogeeUI.apiVersion == 1 and ApogeeUI end
function M.Refresh() local ui=service(); if ui then ui.RefreshComponent("heals") end end
function M.StopDrag() end
function M.ResetPosition() end -- Shared position is reset only from the launcher.
function M.Create()
    local ui=service(); if not ui or not A.started then return end
    ui.RegisterComponent("heals", {apiVersion=1, label="Heals", category=A.Settings.category,
        available=function() return A.started == true end,
        actions={{id="bindings", label="Healing bindings", primary=true,
            checked=function() return A.BindingEditor.frame ~= nil and A.BindingEditor.frame:IsShown() end,
            run=function()
                if A.BindingEditor.frame and A.BindingEditor.frame:IsShown() then A.BindingEditor.Close()
                else A.BindingEditor.Open() end
            end}}})
end
function M.Unregister() local ui=service(); if ui then ui.UnregisterComponent("heals") end end
