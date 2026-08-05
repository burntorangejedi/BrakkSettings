-- luacheck: globals EnhanceQoL
local addonName, addon = ...
local L = addon.L

local AceGUI = addon.AceGUI
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local db
local stream

local function getOptionsHint()
    if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
        local text = addon.DataPanel.GetOptionsHintText()
        if text ~= nil then return text end
        return nil
    end
    return L["Right-Click for options"]
end

local function ensureDB()
    addon.db.datapanel = addon.db.datapanel or {}
    addon.db.datapanel.gold = addon.db.datapanel.gold or {}
    db = addon.db.datapanel.gold
    db.fontSize = db.fontSize or 14
    db.fontFace = db.fontFace or (addon.variables and addon.variables.defaultFont)
end

local function buildFontList()
    local list, order = {}, {}
    local defaultFont = addon.variables and addon.variables.defaultFont

    if defaultFont then
        list[defaultFont] = L["actionBarFontDefault"] or "Blizzard Font"
        order[#order + 1] = defaultFont
    end

    if LSM and LSM.HashTable then
        local entries = {}
        for name, path in pairs(LSM:HashTable("font") or {}) do
            if type(path) == "string" and path ~= "" then
                entries[#entries + 1] = { key = path, text = tostring(name) }
            end
        end
        table.sort(entries, function(a, b) return a.text < b.text end)
        for _, entry in ipairs(entries) do
            list[entry.key] = entry.text
            order[#order + 1] = entry.key
        end
    end

    return list, order
end

-- Returns the player's average item level (equipped and overall)
local function GetPlayerItemLevel()
    -- GetAverageItemLevel() returns: overall, equipped, PvP
    local overall, equipped, pvp = GetAverageItemLevel()

    -- You can choose which value you want to use.
    -- Most addons use "equipped" for display.
    return string.format("%.2f / %.2f", equipped, overall)
end

local header = "|TInterface\\Addons\\EnhanceQoL\\Icons\\Talents: %d:%d:0:0|t"
local function checkItemLevel(stream)
    ensureDB()
    local ilvl = GetPlayerItemLevel() or 0
    local size = db and db.fontSize or 12
    local fontFace = db and db.fontFace or (addon.variables and addon.variables.defaultFont)
    stream.snapshot.fontSize = size
    stream.snapshot.font = fontFace
    stream.snapshot.text = header:format(size, size) .. " " .. ilvl
    stream.snapshot.tooltip = getOptionsHint()
end

local function RestorePosition(frame)
    if db.point and db.x and db.y then
        frame:ClearAllPoints()
        frame:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    end
end

local aceWindow
local function createAceWindow()
    if aceWindow then
        aceWindow:Show()
        return
    end
    ensureDB()
    local frame = AceGUI:Create("Window")
    aceWindow = frame.frame
    frame:SetTitle(GAMEMENU_OPTIONS)
    frame:SetWidth(300)
    frame:SetHeight(200)
    frame:SetLayout("List")

    -- Lock resizing (window shouldn't be resizable)
    if frame.frame.SetResizeBounds then
        local w, h = frame.frame:GetWidth(), frame.frame:GetHeight()
        frame.frame:SetResizeBounds(w, h, w, h)
    end
    if frame.frame.SetResizable then frame.frame:SetResizable(false) end
    if frame.sizer then frame.sizer:Hide() end
    if frame.sizer_e then frame.sizer_e:Hide() end
    if frame.sizer_s then frame.sizer_s:Hide() end
    if frame.sizer_se then frame.sizer_se:Hide() end

    -- Close with Escape
    frame.frame:EnableKeyboard(true)
    frame.frame:SetPropagateKeyboardInput(true)
    frame.frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then self:Hide() end
    end)

    frame.frame:SetScript("OnShow", function(self) RestorePosition(self) end)
    frame.frame:SetScript("OnHide", function(self)
        local point, _, _, xOfs, yOfs = self:GetPoint()
        db.point = point
        db.x = xOfs
        db.y = yOfs
    end)

    local fontSize = AceGUI:Create("Slider")
    fontSize:SetLabel(FONT_SIZE)
    fontSize:SetSliderValues(8, 32, 1)
    fontSize:SetValue(db.fontSize)
    fontSize:SetCallback("OnValueChanged", function(_, _, val)
        db.fontSize = val
        addon.DataHub:RequestUpdate(stream)
    end)
    frame:AddChild(fontSize)

    local fontList, fontOrder = buildFontList()
    local fontDropdown = AceGUI:Create("Dropdown")
    fontDropdown:SetLabel(L["Font"] or FONT)
    fontDropdown:SetList(fontList, fontOrder)
    local currentFont = db.fontFace
    if not fontList[currentFont] then currentFont = addon.variables and addon.variables.defaultFont end
    fontDropdown:SetValue(currentFont)
    frame:AddChild(fontDropdown)

    local apply = AceGUI:Create("Button")
    apply:SetText(APPLY or "Apply")
    apply:SetCallback("OnClick", function()
        local chosen = fontDropdown:GetValue()
        if not fontList[chosen] then
            chosen = addon.variables and addon.variables.defaultFont
        end
        db.fontFace = chosen or db.fontFace
        db.fontSize = fontSize:GetValue() or db.fontSize
        addon.DataHub:RequestUpdate(stream)
    end)
    frame:AddChild(apply)

    frame.frame:Show()
end

local provider = {
    id = "ilvl",          -- required: unique identifier for the stream
    version = 1,          -- required: increment when the provider changes
    title = "Item Level", -- required: human readable title
    update = checkItemLevel,
    events = {
        PLAYER_EQUIPMENT_CHANGED = function(stream) addon.DataHub:RequestUpdate(stream) end,
        PLAYER_LOGIN = function(stream) addon.DataHub:RequestUpdate(stream) end,
    },
    OnClick = function(_, btn)
        if btn == "RightButton" then createAceWindow() end
    end,
}

print("Loaded Stream: Item Level")

-- Register the stream with the DataHub
stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
