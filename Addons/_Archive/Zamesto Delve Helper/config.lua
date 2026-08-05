local myname, ns = ...
local L = LibStub("AceLocale-3.0"):GetLocale(myname, false)

ns.defaults = {
    profile = {
        show_on_world = true,
        show_on_minimap = true,
        show_Zamro = true,
        repeatable = true,
        icon_scale = 1.0,
        icon_alpha = 1.0,
    },
    char = {
        hidden = {
            ['*'] = {},
        },
    },
}

local gwaProfileExportText = ""
local gwaProfileImportText = ""
local gwaProfileStatusText = ""

local function EnsureGWASavedVars()
    GWA_SavedVars = GWA_SavedVars or { framesVisible = true, positions = {} }
    GWA_SavedVars.positions = GWA_SavedVars.positions or {}
    return GWA_SavedVars
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

local function BuildGWAProfileString()
    local vars = EnsureGWASavedVars()
    local positions = vars.positions or {}
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

    local scale = tonumber(vars.uiScale) or 1
    local parts = {
        "GWA2",
        "fv:" .. tostring(vars.framesVisible and 1 or 0),
        "scale:" .. string.format("%.2f", scale),
        "fsize:" .. tostring(vars.fontSize or ""),
        "fpath:" .. EscapeProfileValue(vars.fontPath or ""),
        "tracks:" .. getXY("tracks"),
        "raid:" .. getXY("raid"),
        "mythicPlus:" .. getXY("mythicPlus"),
        "delve:" .. getXY("delve"),
    }
    return table.concat(parts, ";")
end

local function ParseXY(value)
    local xStr, yStr = tostring(value or ""):match("^([^,/]+)[,/]([^,/]+)$")
    local x = tonumber(xStr)
    local y = tonumber(yStr)
    if not x or not y then
        return nil
    end
    return x, y
end

local function ImportGWAProfileString(data)
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
            return false, "Malformed profile string (missing " .. key .. ")."
        end
    end
    if fieldCount < 8 then
        return false, "Malformed profile string."
    end

    local vars = EnsureGWASavedVars()
    local keys = {"tracks", "raid", "mythicPlus", "delve"}
    for _, key in ipairs(keys) do
        if fields[key] then
            local x, y = ParseXY(fields[key])
            if x and y then
                vars.positions[key] = {
                    point = "TOPLEFT",
                    relativePoint = "TOPLEFT",
                    x = x,
                    y = y,
                }
            end
        end
    end

    if fields.fv == "1" then
        vars.framesVisible = true
    elseif fields.fv == "0" then
        vars.framesVisible = false
    end

    if fields.scale ~= nil then
        local scale = tonumber(fields.scale)
        if scale and scale >= 0.7 and scale <= 2.0 then
            vars.uiScale = scale
        elseif fields.scale == "" then
            vars.uiScale = nil
        end
    end

    if fields.fsize ~= nil then
        local fsize = tonumber(fields.fsize)
        if fsize and fsize >= 6 and fsize <= 24 then
            vars.fontSize = math.floor(fsize + 0.5)
        elseif fields.fsize == "" then
            vars.fontSize = nil
        end
    end

    if fields.fpath ~= nil then
        local path = UnescapeProfileValue(fields.fpath)
        if path == "" then
            vars.fontPath = nil
        elseif path:find("=", 1, true) or path:find(",", 1, true) then
            return false, "Malformed font path in profile."
        else
            vars.fontPath = path
        end
    end

    return true
end

ns.options = {
    type = "group",
    name = myname:gsub("HandyNotes_", ""):gsub("([A-Z])", " %1"):gsub("^%s+", ""),
    get = function(info) return ns.db[info[#info]] end,
    set = function(info, v)
        ns.db[info[#info]] = v
        ns.HL:SendMessage("HandyNotes_NotifyUpdate", myname:gsub("HandyNotes_", ""))
    end,
    args = {
        icon = {
            type = "group",
            name = L["Icon settings"],
            inline = true,
            args = {
                desc = {
                    name = L["These settings control the look of the icon."],
                    type = "description",
                    order = 0,
                },
                icon_scale = {
                    type = "range",
                    name = L["Icon Scale"],
                    desc = L["The scale of the icons"],
                    min = 0.25, max = 2, step = 0.01,
                    order = 10,
                },
                icon_alpha = {
                    type = "range",
                    name = L["Icon Alpha"],
                    desc = L["The alpha transparency of the icons"],
                    min = 0, max = 1, step = 0.01,
                    order = 20,
                },
                show_on_world = {
                    type = "toggle",
                    name = L["World Map"],
                    desc = L["Show icons on world map"],
                    order = 30,
                },
                show_on_minimap = {
                    type = "toggle",
                    name = L["Minimap"],
                    desc = L["Show icons on the minimap"],
                    order = 40,
                },
            },
        },
        display = {
            type = "group",
            name = L["What to display"],
            inline = true,
            args = {
                show_Zamro = {
                    type = "toggle",
                    name = L["Show Zamros"],
                    desc = L["Show Zamros gold"],
                    order = 20,
                },
                unhide = {
                    type = "execute",
                    name = L["Reset hidden nodes"],
                    desc = L["Show all nodes that you manually hid by right-clicking on them and choosing \"hide\"."],
                    func = function()
                        for map,coords in pairs(ns.hidden) do
                            wipe(coords)
                        end
                        ns.HL:Refresh()
                    end,
                    order = 30,
                },
            },
        },
        gwa_profile = {
            type = "group",
            name = "Great Vault Overlay Profile",
            inline = true,
            order = 100,
            args = {
                info = {
                    type = "description",
                    order = 1,
                    name = "Import/export GWA frame positions, scale, and font settings.",
                },
                export_now = {
                    type = "execute",
                    order = 5,
                    name = "Generate Export String",
                    func = function()
                        gwaProfileExportText = BuildGWAProfileString()
                        gwaProfileStatusText = "Export string generated. Copy from the box below."
                    end,
                },
                export_text = {
                    type = "input",
                    order = 10,
                    name = "Export String",
                    width = "full",
                    multiline = 4,
                    get = function()
                        return gwaProfileExportText
                    end,
                    set = function(_, value)
                        gwaProfileExportText = value
                    end,
                },
                import_text = {
                    type = "input",
                    order = 20,
                    name = "Import String",
                    width = "full",
                    multiline = 4,
                    get = function()
                        return gwaProfileImportText
                    end,
                    set = function(_, value)
                        gwaProfileImportText = value
                    end,
                },
                import_apply = {
                    type = "execute",
                    order = 30,
                    name = "Apply Import String",
                    func = function()
                        local ok, err = ImportGWAProfileString(gwaProfileImportText)
                        if ok then
                            if type(_G.GWA_ApplyImportedProfile) == "function" then
                                _G.GWA_ApplyImportedProfile()
                            end
                            gwaProfileStatusText = "Import successful. Open or reopen Great Vault to verify."
                            print("GWA: Profile imported from Options panel.")
                        else
                            gwaProfileStatusText = "Import failed: " .. tostring(err)
                        end
                    end,
                },
                status = {
                    type = "description",
                    order = 40,
                    name = function()
                        return gwaProfileStatusText ~= "" and gwaProfileStatusText or " "
                    end,
                },
            },
        },
    },
}

-- moved this up
local GetCriteriaInfo = function(id, criteria)
    local results = {GetAchievementCriteriaInfoByID(id, criteria)}
    if not results[1] then
        if criteria <= GetAchievementNumCriteria(id) then
            results = {GetAchievementCriteriaInfo(id, criteria)}
        else
            ns.Error(
                'unknown achievement criteria (' .. id .. ', ' .. criteria ..
                    ')')
            return UNKNOWN
        end
    end
    return unpack(results)
end

local player_faction = UnitFactionGroup("player")
local player_name = UnitName("player")
ns.should_show_point = function(coord, point, currentZone, isMinimap)
    if isMinimap and not ns.db.show_on_minimap and not point.minimap then
        return false
    elseif not isMinimap and not ns.db.show_on_world then
        return false
    end
    if ns.hidden[currentZone] and ns.hidden[currentZone][coord] then
        return false
    end
    if ns.outdoors_only and IsIndoors() then
        return false
    end
    if point.faction and point.faction ~= player_faction then
        return false
    end
    if point.Zamro and not ns.db.show_Zamro then
        return false
    end
    if point.hide_before and not ns.db.upcoming then
        return false
    end
    if point.quest and C_QuestLog.IsQuestFlaggedCompleted(point.quest) then
        return false
    end

    -- Added this
    if point.achievement and select(13, GetCriteriaInfo(point.achievement.id, point.achievement.criteria)) then
        return false
    end
    return true
end

