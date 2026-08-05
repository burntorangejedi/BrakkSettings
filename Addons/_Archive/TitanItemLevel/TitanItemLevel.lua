---@diagnostic disable: duplicate-set-field
--[[
-- **************************************************************************
-- * TitanItemLevel.lua
-- *
-- * Displays your current Item Level on Titan Panel
-- **************************************************************************
--]]

-- ******************************** Constants *******************************
TITAN_ITEMLEVEL_ID = "ItemLevel"
local TITAN_BUTTON = "TitanPanel" .. TITAN_ITEMLEVEL_ID .. "Button"
local _G = getfenv(0)

-- ******************************** Variables *******************************
local ItemLevelTimer = {}
local ItemLevelTimerRunning = false
local updateTable = { TITAN_ITEMLEVEL_ID, TITAN_PANEL_UPDATE_ALL }

-- ******************************** Functions *******************************

local function GetPlayerItemLevel()
	local itemLevel = select(2, GetAverageItemLevel())
	return itemLevel or 0
end

local function GetButtonText()
	local itemLevel = GetPlayerItemLevel()
	local showLabel = TitanGetVar(TITAN_ITEMLEVEL_ID, "ShowLabel")
	
	local displayText = ""
	local formattedItemLevel = string.format("%.2f", itemLevel)
	
	if showLabel then
		displayText = displayText .. TitanUtils_GetHighlightText("iL: " .. formattedItemLevel)
	else
		displayText = displayText .. TitanUtils_GetHighlightText(formattedItemLevel)
	end
	
	return "", displayText
end

local function GetTooltipText()
	local itemLevel = GetPlayerItemLevel()
	return "Item Level: " .. string.format("%.2f", itemLevel)
end

local function CreateMenu()
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_ITEMLEVEL_ID].menuText)
	
	local info = {}
	info.text = "Show Label"
	info.func = function()
		TitanToggleVar(TITAN_ITEMLEVEL_ID, "ShowLabel")
		TitanPanelButton_UpdateButton(TITAN_ITEMLEVEL_ID)
	end
	info.checked = function()
		return TitanGetVar(TITAN_ITEMLEVEL_ID, "ShowLabel")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel())
	
	TitanPanelRightClickMenu_AddControlVars(TITAN_ITEMLEVEL_ID)
end

---local Build the plugin .registry and register events
---@param self Button plugin frame
local function OnLoad(self)
	local notes = ""
		.. "Displays your current Item Levnope el on Titan Panel.\n"
		.. "- Toggle icon and label display via right-click menu\n"
	self.registry = {
		id = TITAN_ITEMLEVEL_ID,
		category = "Information",
		version = TITAN_VERSION,
		menuText = "Item Level",
		menuTextFunction = CreateMenu,
		buttonTextFunction = GetButtonText,
		tooltipTitle = "Item Level",
		tooltipTextFunction = GetTooltipText,
		icon = "Interface\\Addons\\TitanItemLevel\\shield-16.blp",
		iconWidth = 16,
		notes = notes,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = false,
		},
		savedVariables = {
			ShowIcon = 1,
			ShowLabel = 1,
		}
	}
end

---local Start the timer for updating the item level
---@param self Button plugin frame
local function OnShow(self)
	if ItemLevelTimerRunning then
		-- Do not create a new one
	else
		local AceTimer = LibStub("AceTimer-3.0")
		ItemLevelTimer = AceTimer:ScheduleRepeatingTimer(TitanPanelPluginHandle_OnUpdate, 1, updateTable)
		ItemLevelTimerRunning = true
	end
end

---local Stop the timer for updating the item level
---@param self Button plugin frame
local function OnHide(self)
	local AceTimer = LibStub("AceTimer-3.0")
	AceTimer:CancelTimer(ItemLevelTimer)
	ItemLevelTimerRunning = false
end

---local Handle events the item level plugin is interested in.
---@param self Button plugin frame
---@param event string Event
---@param ... any Event parameters
local function OnEvent(self, event, ...)
	TitanPanelButton_UpdateButton(TITAN_ITEMLEVEL_ID)
end

---local Handle mouse events the item level plugin is interested in.
---@param self Button plugin frame
---@param button string Button pushed with any modifiers
local function OnClick(self, button)
	TitanPanelButton_OnClick(self, button)
end

-- ====== Create needed frames
local function Create_Frames()
	if _G[TITAN_BUTTON] then
		return -- if already created
	end

	-- general container frame
	local f = CreateFrame("Frame", nil, UIParent)

	-- Titan plugin button
	local window = CreateFrame("Button", TITAN_BUTTON, f, "TitanPanelComboTemplate")
	window:SetFrameStrata("FULLSCREEN")
	OnLoad(window)

	window:SetScript("OnShow", function(self)
		OnShow(self)
		TitanPanelButton_OnShow(self)
	end)
	window:SetScript("OnHide", function(self)
		OnHide(self)
	end)
	window:SetScript("OnEvent", function(self, event, ...)
		OnEvent(self, event, ...)
	end)
	window:SetScript("OnClick", function(self, button)
		OnClick(self, button)
		TitanPanelButton_OnClick(self, button)
	end)
	
	window:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	window:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
end

Create_Frames()
