local addonName, addon = ...

-- Localization
local L = {}
if GetLocale() == "ruRU" then
    L["Explorer"] = "Исследователь"
    L["Adventurer"] = "Приключенец"
    L["Veteran"] = "Ветеран"
    L["Champion"] = "Защитник"
    L["Hero"] = "Герой"
    L["Myth"] = "Легенда"
    L["Run"] = "Run"
    L["Vault"] = "Хранилище"
else
    L["Explorer"] = "Explorer"
    L["Adventurer"] = "Adventurer"
    L["Veteran"] = "Veteran"
    L["Champion"] = "Champion"
    L["Hero"] = "Hero"
    L["Myth"] = "Myth"
    L["Run"] = "Run"
    L["Vault"] = "Vault"
end

local lootData = {
    raid = {
        bosses = {-1, 1, 2, 3, 4, 5, 6},
        headers = {"LFR", "Normal", "Heroic", "Mythic"},
        LFR = {
            index = 0,
            bosses = {
            [1] = 233,
            [2] = 237,
            [3] = 240,
            [4] = 243,
            [5] = 246,
            [6] = 250,
            },
            rare = 243,
        },
        Normal = {
            index = 10,
            bosses = {
            [1] = 246,
            [2] = 250,
            [3] = 253,
            [4] = 256,
            [5] = 259,
            [6] = 263,
            },
            ["Very Rare"] = 256,
        },
        Heroic = {
            index = 20,
            bosses = {
            [1] = 259,
            [2] = 263,
            [3] = 266,
            [4] = 269,
            [5] = 272,
            [6] = 276,
            },        
            rare = 269,
        },
        Mythic = {
            index = 30,
            bosses = {
            [1] = 272,
            [2] = 276,
            [3] = 279,
            [4] = 282,
            [5] = 285,
            [6] = 289,
            },        
            rare = 282,
        },
    },
    mythicPlus = {
        types = {"Run", "Vault"},
        headers = {-1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
    [2] = {run = 250, vault = 259},
    [3] = {run = 250, vault = 259},
    [4] = {run = 253, vault = 263},
    [5] = {run = 256, vault = 263},
    [6] = {run = 256, vault = 266},
    [7] = {run = 259, vault = 269},
    [8] = {run = 263, vault = 269},
    [9] = {run = 263, vault = 269},
    [10] = {run = 266, vault = 272},
    },
    delve = {
        types = {"Run", "Vault"},
        headers = {-1, 1, 2, 3, 4, 5, 6, 7, 8},
        [1] = {run = 220, vault = 233},
        [2] = {run = 224, vault = 237},
        [3] = {run = 227, vault = 240},
        [4] = {run = 230, vault = 243},
        [5] = {run = 233, vault = 246},
        [6] = {run = 237, vault = 253},
        [7] = {run = 250, vault = 256},
        [8] = {run = 250, vault = 259},
    },
}

local tracks = {
    [208] = "Explorer", [211] = "Explorer", [214] = "Explorer", [217] = "Explorer",
    [220] = "Adventurer", [224] = "Adventurer", [227] = "Adventurer", [230] = "Adventurer",
    [233] = "Veteran", [237] = "Veteran", [240] = "Veteran", [243] = "Veteran",
    [246] = "Champion", [250] = "Champion", [253] = "Champion", [256] = "Champion",
    [259] = "Hero", [263] = "Hero", [266] = "Hero", [269] = "Hero",
    [272] = "Myth", [276] = "Myth", [279] = "Myth", [282] = "Myth", [285] = "Myth", [289] = "Myth",
}

local trackColors = {
    Explorer = {0.69, 0.69, 0.69, 1}, -- #B0B0B0 (Light Gray, Common)
    Adventurer = {0, 1, 0.59, 1}, -- #00FF96 (Pale Green, Uncommon)
    Veteran = {0, 0.64, 1, 1}, -- #00A2FF (Bright Blue, Rare)
    Champion = {0.64, 0.21, 0.93, 1}, -- #A335EE (Deep Purple, Epic)
    Hero = {1, 0.82, 0, 1}, -- #FFD100 (Gold, Legendary)
    Myth = {1, 0.27, 0, 1}, -- #FF4500 (Fiery Orange, Mythic)
}

local textFrames = {}
local textFrameSizes = setmetatable({}, { __mode = "k" })
local GetConfiguredFontPath
local GetConfiguredFontSize
local ApplyConfiguredFont
local RefreshAllTextFonts
local GetConfiguredUIScale
local ApplyConfiguredUIScale
local RefreshAllUIScales
local BindDragProxy

BindDragProxy = function(dragFrame, movableFrame)
    if not dragFrame or not movableFrame then
        return
    end

    dragFrame:EnableMouse(true)
    dragFrame:RegisterForDrag("LeftButton")
    dragFrame:SetScript("OnDragStart", function()
        if movableFrame:IsMovable() then
            movableFrame:StartMoving()
        end
    end)
    dragFrame:SetScript("OnDragStop", function()
        local onDragStop = movableFrame:GetScript("OnDragStop")
        if onDragStop then
            onDragStop(movableFrame)
        else
            movableFrame:StopMovingOrSizing()
        end
    end)
end

-- Frame creation
local function CreateTextureFrame(parent, width, height, color, text, fontSize, justify, anchorFrame, anchorPoint, selfPoint, xOffset, yOffset)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)
    frame:SetPoint(selfPoint, anchorFrame, anchorPoint, xOffset, yOffset)
    BindDragProxy(frame, parent)
    
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture:SetAllPoints()
    
    color = type(color) == "table" and color or {1, 1, 1, 1}
    texture:SetVertexColor(unpack(color))
    texture:SetBlendMode("BLEND")
    
    local textFrame = frame:CreateFontString(nil, "OVERLAY")
    textFrameSizes[textFrame] = fontSize
    ApplyConfiguredFont(textFrame, fontSize)
    textFrame:SetJustifyH(justify)
    textFrame:SetPoint("CENTER")
    textFrame:SetText(text or "")
    textFrame:SetTextColor(1, 1, 1, 1)
    table.insert(textFrames, textFrame)
    
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 1)
    frame.border = border
    
    frame:Show()
    return frame
end

-- Main frame
local mainFrame = CreateFrame("Frame", "GreatVaultInfoFrame", UIParent)
mainFrame:Hide()
mainFrame:SetFrameStrata("HIGH")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGIN")

local tracksFrame
local raidFrame
local mpFrame
local delveFrame

local function AttachMainFrameToVault()
    if not WeeklyRewardsFrame then
        return false
    end

    if mainFrame:GetParent() ~= WeeklyRewardsFrame then
        mainFrame:SetParent(WeeklyRewardsFrame)
    end

    mainFrame:ClearAllPoints()
    mainFrame:SetAllPoints(WeeklyRewardsFrame)
    ApplyConfiguredUIScale(mainFrame)
    return true
end

GetConfiguredFontPath = function()
    if GWA_SavedVars and type(GWA_SavedVars.fontPath) == "string" and GWA_SavedVars.fontPath ~= "" then
        return GWA_SavedVars.fontPath
    end
    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

ApplyConfiguredFont = function(fontString, fontSize)
    local fontPath = GetConfiguredFontPath()
    local effectiveSize = GetConfiguredFontSize(fontSize)
    local ok = pcall(fontString.SetFont, fontString, fontPath, effectiveSize, "OUTLINE")
    if not ok and fontPath ~= (STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF") then
        pcall(fontString.SetFont, fontString, STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", effectiveSize, "OUTLINE")
    end
end

GetConfiguredFontSize = function(defaultSize)
    local size = GWA_SavedVars and tonumber(GWA_SavedVars.fontSize)
    if size and size >= 6 and size <= 24 then
        return size
    end
    return defaultSize
end

RefreshAllTextFonts = function()
    for _, fontString in ipairs(textFrames) do
        if fontString and fontString.SetFont then
            ApplyConfiguredFont(fontString, textFrameSizes[fontString] or 8)
        end
    end
end

GetConfiguredUIScale = function()
    local scale = GWA_SavedVars and tonumber(GWA_SavedVars.uiScale)
    if scale and scale >= 0.7 and scale <= 2.0 then
        return scale
    end
    return 1
end

ApplyConfiguredUIScale = function(frame)
    if frame and frame.SetScale then
        frame:SetScale(GetConfiguredUIScale())
    end
end

RefreshAllUIScales = function()
    ApplyConfiguredUIScale(mainFrame)
end

local function ApplyFramePosition(frame, key, defaultX, defaultY)
    local saved = GWA_SavedVars and GWA_SavedVars.positions and GWA_SavedVars.positions[key]
    frame:ClearAllPoints()
    if saved and type(saved.x) == "number" and type(saved.y) == "number" then
        frame:SetPoint(saved.point or "TOPLEFT", mainFrame, saved.relativePoint or "TOPLEFT", saved.x, saved.y)
    else
        frame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", defaultX, defaultY)
    end
end

local function MakeFrameMovable(frame, key)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local frameLeft = self:GetLeft()
        local frameTop = self:GetTop()
        local parentLeft = mainFrame and mainFrame:GetLeft()
        local parentTop = mainFrame and mainFrame:GetTop()
        if frameLeft and frameTop and parentLeft and parentTop then
            local x = frameLeft - parentLeft
            local y = frameTop - parentTop

            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", x, y)

            GWA_SavedVars.positions[key] = {
                point = "TOPLEFT",
                relativePoint = "TOPLEFT",
                x = x,
                y = y,
            }
        end
    end)
end

-- Tracks display
local function CreateTracks()
    if tracksFrame then
        tracksFrame:Show()
        return
    end

    tracksFrame = CreateFrame("Frame", nil, mainFrame)
    tracksFrame:SetSize(300, 28)
    ApplyFramePosition(tracksFrame, "tracks", 41.999938964844, -22.999877929688)
    MakeFrameMovable(tracksFrame, "tracks")
    tracksFrame:Show()
    
    local trackOrder = {"Explorer", "Adventurer", "Veteran", "Champion", "Hero", "Myth"}
    local ilvlRanges = {
        Explorer = "208 - 217",
        Adventurer = "220 - 230",
        Veteran = "233 - 243",
        Champion = "246 - 256",
        Hero = "259 - 269",
        Myth = "272 - 289",
    }
    
    for i, track in ipairs(trackOrder) do
        local xOffset = (i - 1) * 50
        local frame = CreateTextureFrame(
            tracksFrame, 50, 14, trackColors[track] or {1, 1, 1, 1}, L[track], 8, "CENTER",
            tracksFrame, "TOPLEFT", "TOPLEFT", xOffset, 0
        )
        
        local ilvlFrame = CreateTextureFrame(
            tracksFrame, 50, 14, {0, 0, 0, 1}, ilvlRanges[track], 8, "CENTER",
            tracksFrame, "TOPLEFT", "TOPLEFT", xOffset, -14
        )
        if ilvlFrame.border then
            ilvlFrame.border:Hide()
        end
    end
end

-- Raid data display
local function CreateRaidData()
    if raidFrame then
        raidFrame:Show()
        return
    end

    raidFrame = CreateFrame("Frame", nil, mainFrame)
    raidFrame:SetSize(150, 112)
    ApplyFramePosition(raidFrame, "raid", 150 * 0.8, -80 * 0.8)
    MakeFrameMovable(raidFrame, "raid")
    raidFrame:Show()
    for i, header in ipairs(lootData.raid.headers) do
        local xOffset = i * 30
        CreateTextureFrame(
            raidFrame, 30, 16, {0, 0, 0, 1}, header, 8, "CENTER",
            raidFrame, "TOPLEFT", "TOPLEFT", xOffset, 0
        )
    end
    for i = 2, #lootData.raid.bosses do
        local key = lootData.raid.bosses[i]
        local yOffset = -16 * (i - 1)
        CreateTextureFrame(
            raidFrame, 30, 16, {0, 0, 0, 1}, tostring(key), 8, "CENTER",
            raidFrame, "TOPLEFT", "TOPLEFT", 0, yOffset
        )
        for j, header in ipairs(lootData.raid.headers) do
            local ilvl = lootData.raid[header].bosses[key]
            local track = tracks[ilvl]
            local color = trackColors[track] or {1, 1, 1, 1}
            local xOffset = j * 30
            
            CreateTextureFrame(
                raidFrame, 30, 16, color, tostring(ilvl), 8, "CENTER",
                raidFrame, "TOPLEFT", "TOPLEFT", xOffset, yOffset
            )
        end
    end
end

-- Mythic+ data display
local function CreateMythicPlusData()
    if mpFrame then
        mpFrame:Show()
        return
    end

    mpFrame = CreateFrame("Frame", nil, mainFrame)
    mpFrame:SetSize(250, 48)
    ApplyFramePosition(mpFrame, "mythicPlus", 40 * 0.8, -330 * 0.8)
    MakeFrameMovable(mpFrame, "mythicPlus")
    mpFrame:Show()
    
    for i, key in ipairs(lootData.mythicPlus.headers) do
        local xOffset = (i - 1) * 25
        local text = key == -1 and "" or "+" .. key
        CreateTextureFrame(
            mpFrame, 25, 16, {0, 0, 0, 1}, text, 8, "CENTER",
            mpFrame, "TOPLEFT", "TOPLEFT", xOffset, 0
        )
    end
    
    for i, label in ipairs(lootData.mythicPlus.types) do
        local yOffset = -16 * i
        CreateTextureFrame(
            mpFrame, 25, 16, {0, 0, 0, 1}, L[label], 8, "CENTER",
            mpFrame, "TOPLEFT", "TOPLEFT", 0, yOffset
        )
        
        for j, key in ipairs({2, 3, 4, 5, 6, 7, 8, 9, 10}) do
            local data = lootData.mythicPlus[key]
            local ilvl = data[label:lower()]
            local track = tracks[ilvl]
            local color = trackColors[track] or {1, 1, 1, 1}
            local xOffset = j * 25
            CreateTextureFrame(
                mpFrame, 25, 16, color, tostring(ilvl), 8, "CENTER",
                mpFrame, "TOPLEFT", "TOPLEFT", xOffset, yOffset
            )
        end
    end
end

-- Delve data display
local function CreateDelveData()
    if delveFrame then
        delveFrame:Show()
        return
    end

    delveFrame = CreateFrame("Frame", nil, mainFrame)
    delveFrame:SetSize(225, 48)
    ApplyFramePosition(delveFrame, "delve", 40, -381.49951171875)
    MakeFrameMovable(delveFrame, "delve")
    delveFrame:Show()
    
    for i, key in ipairs(lootData.delve.headers) do
        local xOffset = (i - 1) * 25
        local text = key == -1 and "" or tostring(key)
        CreateTextureFrame(
            delveFrame, 25, 16, {0, 0, 0, 1}, text, 8, "CENTER",
            delveFrame, "TOPLEFT", "TOPLEFT", xOffset, 0
        )
    end
    
    for i, label in ipairs(lootData.delve.types) do
        local yOffset = -16 * i
        CreateTextureFrame(
            delveFrame, 25, 16, {0, 0, 0, 1}, L[label], 8, "CENTER",
            delveFrame, "TOPLEFT", "TOPLEFT", 0, yOffset
        )
        
        for j, key in ipairs({1, 2, 3, 4, 5, 6, 7, 8}) do
            local data = lootData.delve[key]
            local ilvl = data[label:lower()]
            local color
            -- Override color for vault = 694 at delve tier 7 to use Champion color
            if key == 7 and label:lower() == "vault" and ilvl == 694 then
                color = {0.64, 0.21, 0.93, 1} -- Champion color
            else
                local track = tracks[ilvl]
                color = trackColors[track] or {1, 1, 1, 1}
            end
            local xOffset = j * 25
            CreateTextureFrame(
                delveFrame, 25, 16, color, tostring(ilvl), 8, "CENTER",
                delveFrame, "TOPLEFT", "TOPLEFT", xOffset, yOffset
            )
        end
    end
end

-- Initialize displays
local function InitializeDisplays()
    if not WeeklyRewardsFrame or not (WeeklyRewardsFrame:IsShown() or WeeklyRewardsFrame:IsVisible()) then
        mainFrame:Hide()
        return
    end

    if not AttachMainFrameToVault() then
        mainFrame:Hide()
        return
    end
    
    CreateTracks()
    CreateRaidData()
    CreateMythicPlusData()
    CreateDelveData()
    
    if GWA_SavedVars and GWA_SavedVars.framesVisible then
        mainFrame:Show()
    else
        mainFrame:Hide()
    end
end

-- SavedVariables to store frame visibility state
local function SetupSavedVariables()
    GWA_SavedVars = GWA_SavedVars or {
        framesVisible = true
    }
    GWA_SavedVars.positions = GWA_SavedVars.positions or {}
    if GWA_SavedVars.fontPath == "" then
        GWA_SavedVars.fontPath = nil
    end
    if GWA_SavedVars.fontSize ~= nil then
        local fontSize = tonumber(GWA_SavedVars.fontSize)
        if not fontSize or fontSize < 6 or fontSize > 24 then
            GWA_SavedVars.fontSize = nil
        else
            GWA_SavedVars.fontSize = math.floor(fontSize + 0.5)
        end
    end
    if GWA_SavedVars.uiScale ~= nil then
        local uiScale = tonumber(GWA_SavedVars.uiScale)
        if not uiScale or uiScale < 0.7 or uiScale > 2.0 then
            GWA_SavedVars.uiScale = nil
        end
    end
end

-- Function to toggle frame visibility
local function ToggleFrames()
    GWA_SavedVars.framesVisible = not GWA_SavedVars.framesVisible
    if GWA_SavedVars.framesVisible then
        mainFrame:Show()
    else
        mainFrame:Hide()
    end
end

local function PrintSavedPosition(key)
    local pos = GWA_SavedVars and GWA_SavedVars.positions and GWA_SavedVars.positions[key]
    if not pos then
        print("GWA: " .. key .. " -> no saved position")
        return
    end

    local point = pos.point or "TOPLEFT"
    local relativePoint = pos.relativePoint or "TOPLEFT"
    local x = type(pos.x) == "number" and string.format("%.2f", pos.x) or tostring(pos.x)
    local y = type(pos.y) == "number" and string.format("%.2f", pos.y) or tostring(pos.y)

    print("GWA: " .. key .. " -> " .. point .. " to GreatVaultInfoFrame." .. relativePoint .. " x=" .. x .. " y=" .. y)
end

local function PrintAllSavedPositions()
    print("GWA: Saved frame positions (relative to GreatVaultInfoFrame):")
    PrintSavedPosition("tracks")
    PrintSavedPosition("raid")
    PrintSavedPosition("mythicPlus")
    PrintSavedPosition("delve")
end

local function ResetPositionsToSafeDefaults()
    GWA_SavedVars.framesVisible = true
    GWA_SavedVars.uiScale = nil
    GWA_SavedVars.fontPath = nil
    GWA_SavedVars.fontSize = nil

    GWA_SavedVars.positions = {
        tracks = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 30, y = -28 },
        raid = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 30, y = -74 },
        mythicPlus = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 30, y = -190 },
        delve = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 30, y = -245 },
    }

    if tracksFrame then
        ApplyFramePosition(tracksFrame, "tracks", 30, -28)
    end
    if raidFrame then
        ApplyFramePosition(raidFrame, "raid", 30, -74)
    end
    if mpFrame then
        ApplyFramePosition(mpFrame, "mythicPlus", 30, -190)
    end
    if delveFrame then
        ApplyFramePosition(delveFrame, "delve", 30, -245)
    end

    if WeeklyRewardsFrame and (WeeklyRewardsFrame:IsShown() or WeeklyRewardsFrame:IsVisible()) then
        InitializeDisplays()
    end

    if type(_G.GWA_ApplyImportedProfile) == "function" then
        _G.GWA_ApplyImportedProfile()
    end
end

local function EscapeProfileValue(value)
    value = tostring(value or "")
    value = value:gsub("%%", "%%25")
    value = value:gsub(";", "%%3B")
    value = value:gsub(":", "%%3A")
    value = value:gsub("/", "%%2F")
    value = value:gsub("|", "%%7C")
    value = value:gsub(",", "%%2C")
    return value
end

local function UnescapeProfileValue(value)
    value = tostring(value or "")
    value = value:gsub("%%2C", ",")
    value = value:gsub("%%7C", "|")
    value = value:gsub("%%2F", "/")
    value = value:gsub("%%3A", ":")
    value = value:gsub("%%3B", ";")
    value = value:gsub("%%25", "%%")
    return value
end

local function BuildExportString()
    local positions = GWA_SavedVars.positions or {}
    local exportScale = GetConfiguredUIScale()
    local defaults = {
        tracks = { x = 30, y = -28 },
        raid = { x = 30, y = -74 },
        mythicPlus = { x = 30, y = -190 },
        delve = { x = 30, y = -245 },
    }
    local function getXY(key)
        local p = positions[key]
        local x = (p and type(p.x) == "number") and p.x or defaults[key].x
        local y = (p and type(p.y) == "number") and p.y or defaults[key].y
        return string.format("%.2f/%.2f", x, y)
    end

    local parts = {
        "GWA2",
        "fv:" .. tostring(GWA_SavedVars.framesVisible and 1 or 0),
        "scale:" .. string.format("%.2f", exportScale),
        "fsize:" .. tostring(GWA_SavedVars.fontSize or ""),
        "fpath:" .. EscapeProfileValue(GWA_SavedVars.fontPath or ""),
        "tracks:" .. getXY("tracks"),
        "raid:" .. getXY("raid"),
        "mythicPlus:" .. getXY("mythicPlus"),
        "delve:" .. getXY("delve"),
    }
    return table.concat(parts, ";")
end

local function ApplyPositionsNow()
    if tracksFrame then
        ApplyFramePosition(tracksFrame, "tracks", 41.999938964844, -22.999877929688)
    end
    if raidFrame then
        ApplyFramePosition(raidFrame, "raid", 150 * 0.8, -80 * 0.8)
    end
    if mpFrame then
        ApplyFramePosition(mpFrame, "mythicPlus", 40 * 0.8, -330 * 0.8)
    end
    if delveFrame then
        ApplyFramePosition(delveFrame, "delve", 40, -381.49951171875)
    end
end

local function ApplySavedVarsToLiveFrames()
    if (not tracksFrame or not raidFrame or not mpFrame or not delveFrame)
        and WeeklyRewardsFrame
        and (WeeklyRewardsFrame:IsShown() or WeeklyRewardsFrame:IsVisible()) then
        InitializeDisplays()
    end

    RefreshAllTextFonts()
    RefreshAllUIScales()
    ApplyPositionsNow()

    if GWA_SavedVars and GWA_SavedVars.framesVisible then
        mainFrame:Show()
    else
        mainFrame:Hide()
    end
end

_G.GWA_ApplyImportedProfile = ApplySavedVarsToLiveFrames

local function ParseXY(value)
    local xStr, yStr = tostring(value or ""):match("^([^,/]+)[,/]([^,/]+)$")
    local x = tonumber(xStr)
    local y = tonumber(yStr)
    if not x or not y then
        return nil
    end
    return x, y
end

local function ImportFromString(data)
    if type(data) ~= "string" or data == "" then
        return false, "Empty profile string."
    end

    local trimmed = data:match("^%s*(.-)%s*$")
    trimmed = trimmed:gsub("[\r\n]", "")
    trimmed = trimmed:gsub("^<", ""):gsub(">$", "")

    local isV1 = trimmed:find("^GWA1|", 1, false) ~= nil
    local isV2 = trimmed:find("^GWA2;", 1, false) ~= nil
    if not isV1 and not isV2 then
        return false, "Invalid profile header."
    end

    local fields = {}
    local fieldCount = 0
    local tokenPattern = isV2 and "[^;]+" or "[^|]+"
    for token in trimmed:gmatch(tokenPattern) do
        if token ~= "GWA1" and token ~= "GWA2" then
            local k, v
            if isV2 then
                k, v = token:match("^([^:]+):(.*)$")
            else
                k, v = token:match("^([^=]+)=(.*)$")
            end
            if k then
                fields[k] = v
                fieldCount = fieldCount + 1
            end
        end
    end

    local requiredKeys = {"tracks", "raid", "mythicPlus", "delve", "scale", "fv"}
    for _, key in ipairs(requiredKeys) do
        if fields[key] == nil then
            return false, "Malformed profile string (missing " .. key .. "). Use /gwa import and paste into popup."
        end
    end
    if fieldCount < 8 then
        return false, "Malformed profile string. Use /gwa import and paste into popup."
    end

    GWA_SavedVars.positions = GWA_SavedVars.positions or {}

    local keys = {"tracks", "raid", "mythicPlus", "delve"}
    for _, key in ipairs(keys) do
        if fields[key] then
            local x, y = ParseXY(fields[key])
            if x and y then
                GWA_SavedVars.positions[key] = {
                    point = "TOPLEFT",
                    relativePoint = "TOPLEFT",
                    x = x,
                    y = y,
                }
            end
        end
    end

    if fields.fv == "1" then
        GWA_SavedVars.framesVisible = true
    elseif fields.fv == "0" then
        GWA_SavedVars.framesVisible = false
    end

    if fields.scale ~= nil then
        local scale = tonumber(fields.scale)
        if scale and scale >= 0.7 and scale <= 2.0 then
            GWA_SavedVars.uiScale = scale
        elseif fields.scale == "" then
            GWA_SavedVars.uiScale = nil
        end
    end

    if fields.fsize ~= nil then
        local fsize = tonumber(fields.fsize)
        if fsize and fsize >= 6 and fsize <= 24 then
            GWA_SavedVars.fontSize = math.floor(fsize + 0.5)
        elseif fields.fsize == "" then
            GWA_SavedVars.fontSize = nil
        end
    end

    if fields.fpath ~= nil then
        local path = UnescapeProfileValue(fields.fpath)
        if path == "" then
            GWA_SavedVars.fontPath = nil
        elseif path:find("=", 1, true) or path:find(",", 1, true) then
            return false, "Malformed font path in profile."
        else
            GWA_SavedVars.fontPath = path
        end
    end

    ApplySavedVarsToLiveFrames()

    return true
end

local profileDialog

local function EnsureProfileDialog()
    if profileDialog then
        return profileDialog
    end

    local frame = CreateFrame("Frame", "GWA_ProfileDialog", UIParent, "BackdropTemplate")
    frame:SetSize(560, 210)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 24,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -16)

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.hint:SetPoint("TOP", frame.title, "BOTTOM", 0, -10)
    frame.hint:SetTextColor(1, 0.82, 0, 1)

    frame.editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.editBox:SetAutoFocus(false)
    frame.editBox:SetPoint("TOPLEFT", 20, -70)
    frame.editBox:SetPoint("TOPRIGHT", -20, -70)
    frame.editBox:SetHeight(28)
    frame.editBox:SetMaxLetters(0)
    frame.editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        frame:Hide()
    end)
    frame.editBox:SetScript("OnEnterPressed", function(self)
        if frame.mode == "import" then
            frame.acceptButton:Click()
        else
            self:HighlightText()
        end
    end)

    frame.acceptButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.acceptButton:SetSize(110, 24)
    frame.acceptButton:SetPoint("BOTTOMRIGHT", -20, 16)

    frame.cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.cancelButton:SetSize(110, 24)
    frame.cancelButton:SetPoint("RIGHT", frame.acceptButton, "LEFT", -8, 0)
    frame.cancelButton:SetText(CANCEL or "Cancel")
    frame.cancelButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.acceptButton:SetScript("OnClick", function()
        if frame.mode == "import" then
            local raw = frame.editBox:GetText() or ""
            local ok, err = ImportFromString(raw)
            if not ok then
                print("GWA: Import failed: " .. tostring(err))
                frame.editBox:SetFocus()
                frame.editBox:HighlightText()
                return
            end
            print("GWA: Profile imported.")
            frame:Hide()
            return
        end
        frame:Hide()
    end)

    profileDialog = frame
    return frame
end

local function ShowExportPopup()
    local frame = EnsureProfileDialog()
    local exportString = BuildExportString()

    frame.mode = "export"
    frame.title:SetText("GWA Export")
    frame.hint:SetText("Ctrl+C to copy")
    frame.acceptButton:SetText(OKAY or "OK")
    frame.cancelButton:Hide()
    frame.editBox:SetText(exportString)
    frame:Show()
    frame.editBox:SetFocus()
    frame.editBox:HighlightText()
end

local function ShowImportPopup()
    local frame = EnsureProfileDialog()

    frame.mode = "import"
    frame.title:SetText("GWA Import")
    frame.hint:SetText("Paste profile string and click Import")
    frame.acceptButton:SetText(ACCEPT or "Import")
    frame.cancelButton:Show()
    frame.editBox:SetText("")
    frame:Show()
    frame.editBox:SetFocus()
    frame.editBox:HighlightText()
end

-- Slash command handler
SLASH_GWA1 = "/gwa"
SlashCmdList["GWA"] = function(msg)
    local input = (msg or ""):match("^%s*(.-)%s*$")
    local command, value = input:match("^(%S+)%s*(.-)$")

    if command then
        command = command:lower()
    end

    if command == "font" then
        if value == nil or value == "" then
            print("GWA: /gwa font default | /gwa font Fonts\\ARIALN.TTF")
            return
        end

        if value:lower() == "default" then
            GWA_SavedVars.fontPath = nil
            RefreshAllTextFonts()
            print("GWA: Font reset to WoW global font.")
            return
        end

        GWA_SavedVars.fontPath = value
        RefreshAllTextFonts()
        print("GWA: Font set to " .. value)
        return
    end

    if command == "export" then
        ShowExportPopup()
        print("GWA: Export popup opened.")
        return
    end

    if command == "import" then
        if value == nil or value == "" then
            ShowImportPopup()
            print("GWA: Import popup opened.")
            return
        end

        local ok, err = ImportFromString(value)
        if not ok then
            print("GWA: Import failed: " .. tostring(err))
            print("GWA: Tip - raw chat commands can corrupt '|'. Use /gwa import and paste in popup.")
            return
        end

        print("GWA: Profile imported.")
        return
    end

    if command == "fontsize" then
        if value == nil or value == "" then
            print("GWA: /gwa fontsize default | /gwa fontsize 10")
            return
        end

        if value:lower() == "default" then
            GWA_SavedVars.fontSize = nil
            RefreshAllTextFonts()
            print("GWA: Font size reset to default.")
            return
        end

        local size = tonumber(value)
        if not size then
            print("GWA: Invalid font size. Use 6-24.")
            return
        end

        size = math.floor(size + 0.5)
        if size < 6 or size > 24 then
            print("GWA: Font size out of range. Use 6-24.")
            return
        end

        GWA_SavedVars.fontSize = size
        RefreshAllTextFonts()
        print("GWA: Font size set to " .. size)
        return
    end

    if command == "scale" then
        if value == nil or value == "" then
            print("GWA: /gwa scale default | /gwa scale 1.15")
            return
        end

        if value:lower() == "default" then
            GWA_SavedVars.uiScale = nil
            RefreshAllUIScales()
            print("GWA: Overlay scale reset to default.")
            return
        end

        local scale = tonumber(value)
        if not scale then
            print("GWA: Invalid scale. Use 0.7-2.0.")
            return
        end

        if scale < 0.7 or scale > 2.0 then
            print("GWA: Scale out of range. Use 0.7-2.0.")
            return
        end

        GWA_SavedVars.uiScale = scale
        RefreshAllUIScales()
        print("GWA: Overlay scale set to " .. string.format("%.2f", scale))
        return
    end

    if command == "resetpos" or command == "rescue" then
        ResetPositionsToSafeDefaults()
        print("GWA: Rescue applied (positions/visibility/font/scale reset).")
        return
    end

    if command == "pos" or command == "positions" then
        PrintAllSavedPositions()
        return
    end

    ToggleFrames()
end

-- Event handling
mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            SetupSavedVariables()
            if not GWA_SavedVars.framesVisible then
                mainFrame:Hide()
            end
        elseif arg1 == "Blizzard_WeeklyRewards" then
            if WeeklyRewardsFrame then
                AttachMainFrameToVault()
                hooksecurefunc(WeeklyRewardsFrame, "Show", function()
                    InitializeDisplays()
                end)
                hooksecurefunc(WeeklyRewardsFrame, "Hide", function()
                    mainFrame:Hide()
                end)
                if WeeklyRewardsFrame:IsShown() or WeeklyRewardsFrame:IsVisible() then
                    InitializeDisplays()
                end
            end
        end
    elseif event == "PLAYER_LOGIN" then
        SetupSavedVariables()
        if C_AddOns.IsAddOnLoaded("Blizzard_WeeklyRewards") and WeeklyRewardsFrame and (WeeklyRewardsFrame:IsShown() or WeeklyRewardsFrame:IsVisible()) then
            InitializeDisplays()
        end
    end
end)