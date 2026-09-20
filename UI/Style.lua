-- Tank's accepted dimensions and palette, copied locally with MIT attribution.
local _, A = ...
local S = { width = 112, healthHeight = 14, powerHeight = 5, barGap = 0.5,
    rowGap = 2, scale = 2,
    background = { 0.06, 0.075, 0.1, 0.94 }, muted = { 0.65, 0.70, 0.78, 1 } }
A.Style = S
S.clusterHeight = S.healthHeight + S.barGap + S.powerHeight
S.rowHeight = S.clusterHeight + S.rowGap
S.stackHeight = S.rowHeight * 4 + S.clusterHeight
function S.Background(parent)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(); texture:SetColorTexture(unpack(S.background))
end
function S.Text(parent, size)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local font, _, flags = text:GetFont()
    text:SetFont(font, size or 9, flags)
    text:SetWordWrap(false)
    return text
end
function S.CleanText(parent, size)
    -- Native locale-aware sans-serif family (Arial Narrow for Roman alphabets).
    local text = parent:CreateFontString(nil, "OVERLAY", "Number12Font")
    local font = text:GetFont()
    text:SetFont(font, size or 7, "")
    text:SetTextColor(1, 1, 1, 1)
    text:SetWordWrap(false)
    return text
end
function S.PowerColor(kind)
    if kind == 0 then return 0.32, 0.52, 0.88, 1 end
    if kind == 1 then return 0.78, 0.22, 0.20, 1 end
    if kind == 3 then return 0.84, 0.73, 0.26, 1 end
    local color = PowerBarColor and PowerBarColor[kind]
    if color then return color.r, color.g, color.b, 1 end
    return 0.7, 0.7, 0.7, 1
end
function S.RowEdges(row, first)
    -- Only the internal health/power rule remains. Inter-player space is empty.
    local layer = CreateFrame("Frame", nil, row)
    layer:SetAllPoints(row)
    layer:SetFrameLevel(row.nameLayer:GetFrameLevel() + 1)
    layer:EnableMouse(false)
    local texture = layer:CreateTexture(nil, "OVERLAY")
    texture:SetSize(S.width, S.barGap)
    texture:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -S.healthHeight)
    texture:SetColorTexture(0.08, 0.10, 0.13, 1)
end
function S.HealthColor(percent)
    if percent > 0.60 then return 0.28, 0.74, 0.46, 1 end
    if percent > 0.35 then return 0.90, 0.74, 0.22, 1 end
    if percent > 0.15 then return 0.92, 0.48, 0.24, 1 end
    return 0.86, 0.30, 0.30, 1
end
