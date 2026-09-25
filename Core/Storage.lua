local _, A = ...
A.Storage = {}
function A.Storage.DefaultPosition()
    -- Independent Forever placement at 2x scale: align with Tank's 112px bars.
    -- Tank's player + single target + label end at UIParent center y=-81;
    -- this starts at y=-90, leaving a 9px gap without a runtime dependency.
    return { x = 70.5, y = -45 }
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < 100000
end
function A.Storage.Open(saved)
    if type(saved) == "table" and type(saved.version) == "number" and saved.version > 3 then
        return nil, "Saved position is from a newer version; data preserved."
    end
    local position = type(saved) == "table" and saved.position
    if type(position) ~= "table" or not finite(position.x) or not finite(position.y) then
        position = A.Storage.DefaultPosition()
    end
    local editor = type(saved) == "table" and saved.editorPosition
    local editorPosition
    if type(editor) == "table" and finite(editor.x) and finite(editor.y) then
        editorPosition = { x = editor.x, y = editor.y }
    end
    local bindings = {}
    local source = type(saved) == "table" and saved.bindings
    if type(source) == "table" then
        for _, slot in ipairs(A.Bindings.slots) do
            local id = source[slot.id]
            if type(id) == "number" and id > 0 and id < 2147483647 and id % 1 == 0 then
                bindings[slot.id] = id
            end
        end
    end
    local buffs = {}
    local watched = type(saved) == "table" and saved.buffs
    if type(watched) == "table" then
        for index = 1, A.Buffs.limit do
            local entry = watched[index]
            if type(entry) == "table" and type(entry.id) == "number"
                and entry.id > 0 and entry.id < 2147483647 and entry.id % 1 == 0
                and type(entry.enabled) == "boolean" then
                buffs[#buffs + 1] = {id=entry.id, enabled=entry.enabled, party=entry.party == true}
            end
        end
    end
    -- Retain the historical field verbatim for compatibility; minimap placement
    -- never initializes from it or writes session drags back to it.
    local angle
    if type(saved) == "table" then angle = saved.minimapAngle end
    return { version = 3, position = { x = position.x, y = position.y }, bindings = bindings, buffs = buffs,
        minimapAngle = angle, editorPosition = editorPosition }
end
