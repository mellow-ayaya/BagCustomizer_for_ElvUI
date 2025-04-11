-- ElvUI Bag Customizer - Settings module
--
-- This file contains all settings definitions and management functions.
local E, L, V, P, G = unpack(ElvUI)
local addon = E:GetModule("BagCustomizer")
-- Debug function optimization
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][Settings]:|r "
-- Module-specific debug function
local function debug(message)
	-- First check if E.db.bagCustomizer exists
	if not E.db or not E.db.bagCustomizer then return end

	-- Then proceed with existing checks
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.settings or
			not E.db.bagCustomizer.settings.debug then
		return
	end

	-- Output the message with module name
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(message))
end

-- Default settings
addon.defaults = {
	-- Global addon settings
	enabled = true,

	-- Debug settings
	debug = false,
	core = { debug = false },
	searchBar = { debug = false },
	mainTextures = { debug = false },
	miscTextures = { debug = false },
	miscBorders = { debug = false },
	bindText = { debug = false },
	currencies = { debug = false },
	themeManager = { debug = false },
	resourceManager = { debug = false },
	updateSystem = { debug = false },
	settings = { debug = false },
	importExportDialog = { debug = false },

	-- BindText module
	bindTextSettings = {
		enable = true,
		useCustomColor = false,
		color = { r = 1, g = 1, b = 1 },
		brightness = 250,
		applyToBindOnEquip = true,
		applyToWarbound = true,
		applyToPoorQuality = false,
	},

	-- CurrencyAndTextures
	closeButtonTexture = {
		enable = true,
		texture = "close_blizzard_modern.tga",
		scale = 1.5,
		buttonScale = 1.5,
		alpha = 1,
		buttonXOffset = 7,
		buttonYOffset = 6,
		textureXOffset = 0,
		textureYOffset = 0,
		anchorToFrameHeight = true,
	},

	textureHeightOffset = -4,
	fixGoldTextStrata = true,
	enableButtonYChanges = true,
	currencyTopPadding = 34,
	currencyModuleEnabled = true,
	goldAnchorPosition = "BOTTOM_RIGHT_BELOW", -- Options: "DEFAULT", "BOTTOM_RIGHT_BELOW", "BOTTOM_RIGHT_ABOVE"
	reverseCurrencyGrowth = true,
	currencyPaddingSize = 30,
	currencyHorizontalPadding = 8,
	goldTextXOffset = 0,
	goldTextYOffset = 0,

	goldTextTexture = {
		enable = true,
		preserveAspectRatio = false, -- legacy
		useCustomColor = false,
		matchHolderFrameWidth = true,
		anchorToHolderFrame = true,
		autoWidth = true,
		autoHeight = true,
		texture = "gold_blizzard_modern.tga",
		alpha = 1,
		xOffset = 0,
		yOffset = 0,
		holderFrameXOffset = 0,
		holderFrameYOffset = 0,
		widthModifier = 0,
		heightAdjustment = 0,
		width = 100,
		height = 20,
		scale = 1,
		-- 3-slice settings
		use3Slice = true,
		useTiling = true,
		leftBreakPct = 5,
		rightBreakPct = 95,
		tileSpacing = 0,
		tileOffset = 0,
		edgeSize = 10,
	},

	currencyTexture = {
		enable = true,
		autoFitHeight = true,
		matchHolderFrameWidth = true,
		preserveAspectRatio = true, -- legacy
		texture = "currency_blizzard_modern.tga",
		alpha = 1,
		textureAnchor = "CENTER",
		textureXOffset = -12,
		textureYOffset = 0,
		rowHeightOffset = 0,
		widthAdjustment = 0,
		scale = 1,
		width = 100,
		height = 30,
		widthModifier = 100,
		xOffset = 0,
		yOffset = 0,
		-- 3-slice settings
		use3Slice = true,
		useTiling = true,
		useVerticalTiling = true,
		leftBreakPct = 5,
		rightBreakPct = 95,
		tileSpacing = 0,
		tileOffset = 0,
		edgeSize = 10,
	},

	-- FrameHeight module
	frameHeight = {
		debug = false,
		enable = true,
		bagSpacing = 35,
	},

	-- InventoryBackgroundAdjust module
	inventoryBackgroundAdjust = {
		debug = false,
		enableColor = true,
		color = { r = 0.1, g = 0.1, b = 0.1 },
		opacity = 0.78,
	},

	-- InventorySlots module
	inventorySlots = {
		debug = false,
		enable = true,
		preset = "blizzard_modern",
		style = "Rounded",
		BorderStyle = nil,
		EmptyBorderStyle = nil,
		EmptyStyle = nil,
		NormalStyle = nil,
		HighlightStyle = nil,
		textureAlpha = 1.0,
		emptySlotColor = { r = 1.0, g = 1.0, b = 1.0 },
		emptySlotOpacity = 1,
		globalBrightness = 100,
		globalColorIntensity = 100,
		showIndividualBrightness = false,
		showIndividualColorIntensity = false,
		emptySlotBrightness = {
			unassigned = 100,
			assigned = 100,
		},
		emptySlotColorIntensity = {
			unassigned = 100,
			assigned = 100,
		},
		qualityBrightness = {
			[0] = 100, -- Poor
			[1] = 100, -- Common
			[2] = 100, -- Uncommon
			[3] = 100, -- Rare
			[4] = 100, -- Epic
			[5] = 100, -- Legendary
			[6] = 100, -- Artifact
			[7] = 100, -- Heirloom
		},
		qualityColorIntensity = {
			[0] = 100,
			[1] = 100,
			[2] = 100,
			[3] = 100,
			[4] = 100,
			[5] = 100,
			[6] = 100,
			[7] = 100,
		},
		globalScaleFactor = 1.0,
		scaleFactor = 104,
		userModifiedScale = false,
		separateEmptyBorder = true,
		disableElvUIHighlight = true,
		showPoorQualityBorders = true,
		poorQualityColor = { r = 0.55, g = 0.55, b = 0.55 },
		showCommonQualityBorders = true,
		commonQualityColor = { r = 0.85, g = 0.85, b = 0.85 },
		emptySlotTextureAlpha = 1.0,
		colorEmptySlotsByAssignment = true,
		emptySlotAlphaAssigned = 0.6,
		useMainBorderForAssignedEmpty = true,
	},
	custom1PresetSettings = {
		disableElvUIHighlight = false,
		separateEmptyBorder = false,
		applyMainBorderToEmptyAssigned = false,
		scaleFactor = 100,
		globalScaleFactor = 1.0,
	},
	custom2PresetSettings = {
		disableElvUIHighlight = false,
		separateEmptyBorder = false,
		applyMainBorderToEmptyAssigned = false,
		scaleFactor = 100,
		globalScaleFactor = 1.0,
	},
	custom3PresetSettings = {
		disableElvUIHighlight = false,
		separateEmptyBorder = false,
		applyMainBorderToEmptyAssigned = false,
		scaleFactor = 100,
		globalScaleFactor = 1.0,
	},
	-- MainTextures module
	topTexture = {
		enable = true,
		texture = "top_blizzard_modern.tga",
		alpha = 1,
		scale = 1,
		height = 30,
		xOffset = 0,
		yOffset = 37,
		useSlice = true,
		leftBreakPct = 10,
		rightBreakPct = 95,
		useTiling = true,
		tileSpacing = 0,
		tileOffset = 0,
		manualDimensions = false,
		textureWidth = 435,
		textureHeight = 42,
		widthAdjust = 4,
		edgeSize = 24,
	},

	uiBackground = {
		enable = false,
		texture = "",
		alpha = 1,
		scale = 1,
		point = "CENTER",
		xOffset = 0,
		yOffset = 0,
	},

	artBackground = {
		enable = false,
		texture = "",
		alpha = 1,
		scale = 1,
		point = "CENTER",
		xOffset = 0,
		yOffset = 0,
		horizontalSize = 100,
		verticalSize = 100,
		desaturate = false,
		useTint = false,
		tintColor = { r = 1, g = 1, b = 1 },
		useEdgeFade = false,
		maskShape = "alpha_fade_soft_circular.tga",
		cropHorizontally = false,
		cropHorizontalAmount = 0,
		cropVertically = false,
		cropVerticalAmount = 0,
		maintainArtAspectRatio = true,
		maintainMaskAspectRatio = true,
	},

	-- MiscBorders module
	borders = {
		enable = true,
		style = "wowui",
		color = { r = 1, g = 1, b = 1 },
		elements = {
			mainFrame = true,
			searchBar = true,
			vendorGrays = true,
			toggleBars = true,
			cleanup = true,
			stack = true,
			minimap = false,
			frameHeight = true,
		},
		mainFrame = {
			size = 16,
			inset = 6,
			style = "wowui",
			color = { r = 1, g = 1, b = 1 },
			alpha = 1,
		},
		searchBar = {
			size = 14,
			inset = 5,
			style = "wowui",
			color = { r = 1, g = 1, b = 1 },
			alpha = 1,
		},
		buttons = {
			size = 14,
			inset = 4,
			style = "wowui",
			color = { r = 1, g = 1, b = 1 },
			alpha = 1,
		},
		minimap = {
			size = 24,
			inset = 9,
			style = "wowui",
			color = { r = 1, g = 1, b = 1 },
			alpha = 1,
		},
	},
	hideDefaultBorders = true,

	-- SearchBar module
	searchBarBackdrop = {
		enable = true,
		color = { r = 0.1, g = 0.1, b = 0.1 },
		alpha = 0.7,
		hideBorder = true,
		yOffset = 21,
		stackButtonYOffset = 20.5,
	},
}
-- Border style options
addon.borderStyles = {
	["tooltip"] = "Blizzard Tooltip",
	["glow"] = "Glow",
	["shadow"] = "Shadow",
	["flat"] = "Flat",
	["thin"] = "Thin Line",
	["achievement"] = "Achievement",
	["gold"] = "Gold Trim",
	["metal"] = "Metal Frame",
	["dialog"] = "Dialog Box",
	["parchment"] = "Parchment",
	["wowui"] = "Blizzard Modern Inventory",
}
-- Border Textures mapping
addon.borderTextures = {
	["tooltip"] = "Interface\\Tooltips\\UI-Tooltip-Border",
	["glow"] = "Interface\\BUTTONS\\ButtonHilight-Square",
	["shadow"] = "Interface\\Common\\DropShadow",
	["flat"] = "Interface\\DialogFrame\\UI-DialogBox-Border",
	["thin"] = "Interface\\Tooltips\\UI-Tooltip-Background",
	["achievement"] = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	["gold"] = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
	["metal"] = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
	["dialog"] = "Interface\\DialogFrame\\UI-DialogBox-Border-Dark",
	["parchment"] = "Interface\\GLUES\\COMMON\\TextPanel-Border",
	["wowui"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Borders\\blizzard_modern_inventory_border",
}
-- InventorySlots preset configurations
addon.slotBorderPresetMap = {
	["blizzard_modern"] = {
		Border = "blizzard_modern",
		EmptyBorder = "blizzard_modern_empty",
		Normal = "blizzard_modern",
		Empty = "blizzard_modern",
		Highlight = "blizzard_modern",
		ScaleFactor = 104,
		disableElvUIHighlight = true,
		separateEmptyBorder = true,
		applyMainBorderToEmptyAssigned = false,
	},
	["elvui_border_and_texture"] = {
		Border = "elvui",
		EmptyBorder = "elvui_empty",
		Normal = "elvui",
		Empty = "elvui",
		Highlight = "elvui",
		ScaleFactor = 104,
		disableElvUIHighlight = true,
		separateEmptyBorder = true,
		applyMainBorderToEmptyAssigned = true,
	},
	["elvui_rounded_border_and_blizzard_texture"] = {
		Border = "elvui_rounded",
		EmptyBorder = "elvui_rounded_empty",
		Normal = "blizzard_modern",
		Empty = "blizzard_modern",
		Highlight = "blizzard_modern",
		ScaleFactor = 104,
		disableElvUIHighlight = true,
		separateEmptyBorder = true,
		applyMainBorderToEmptyAssigned = true,
	},
	["elvui_rounded_border_and_texture"] = {
		Border = "elvui_rounded",
		EmptyBorder = "elvui_rounded_empty",
		Normal = "elvui_rounded",
		Empty = "elvui_rounded",
		Highlight = "elvui_rounded",
		ScaleFactor = 104,
		disableElvUIHighlight = true,
		separateEmptyBorder = true,
		applyMainBorderToEmptyAssigned = true,
	},
	["custom_1"] = {
		Border = "custom",
		EmptyBorder = "custom",
		Normal = "custom",
		Empty = "custom",
		Highlight = "custom",
		ScaleFactor = 100,
	},
	["custom_2"] = {
		Border = "custom",
		EmptyBorder = "custom",
		Normal = "custom",
		Empty = "custom",
		Highlight = "custom",
		ScaleFactor = 100,
	},
	["custom_3"] = {
		Border = "custom",
		EmptyBorder = "custom",
		Normal = "custom",
		Empty = "custom",
		Highlight = "custom",
		ScaleFactor = 100,
	},
}
-- Full preset texture definitions (resolved paths)
addon.slotBorderPresets = {
	["blizzard_modern"] = {
		Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_border_modern.tga",
		EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_border_modern_empty.tga",
		Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_modern.tga",
		Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_modern.tga",
		Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_highlight_modern.tga",
	},
	["blizzard_classic"] = {
		Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_border_classic.tga",
		EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_border_classic.tga",
		Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_classic.tga",
		Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_classic.tga",
		Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_highlight_classic.tga",
		ScaleFactor = 100,
	},
	["elvui_border_and_texture"] = {
		Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border.tga",
		EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border_empty.tga",
		Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_texture.tga",
		Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_texture.tga",
		Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_highlight.tga",
	},
	["elvui_rounded_border_and_blizzard_texture"] = {
		Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border_rounded.tga",
		EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border_rounded.tga",
		Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_modern.tga",
		Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_modern.tga",
		Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_highlight_modern.tga",
	},
	["elvui_rounded_border_and_texture"] = {
		Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border_rounded.tga",
		EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border_rounded_empty.tga",
		Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_texture_rounded.tga",
		Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_texture_rounded.tga",
		Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_highlight_rounded.tga",
	},
	["custom_1"] = {
		Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_border.tga",
		EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_border.tga",
		Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_texture.tga",
		Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_texture.tga",
		Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_highlight.tga",
	},
	["custom_2"] = {
		Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_border.tga",
		EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_border.tga",
		Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_texture.tga",
		Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_texture.tga",
		Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_highlight.tga",
	},
	["custom_3"] = {
		Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_border.tga",
		EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_border.tga",
		Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_texture.tga",
		Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_texture.tga",
		Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_highlight.tga",
	},
}
-- Available texture options for dropdowns
addon.textureOptions = {
	-- Textures that are commented out are WIP

	-- Close button Textures
	closeButton = {
		["close_blizzard_modern.tga"] = "Blizzard Close Modern",
		--	["close_blizzard_modern_borderless.tga"] = "Blizzard Close Modern Borderless",
		--	["close_blizzard_classic.tga"] = "Blizzard Close Classic",
		--	["close_cataclysm.tga"] = "Cataclysm Close",
		--	["close_northrend.tga"] = "Northrend Close",
		[""] = "None",
		["close_custom1.tga"] = "Custom Close 1",
		["close_custom2.tga"] = "Custom Close 2",
		["close_custom3.tga"] = "Custom Close 3",
	},

	-- Top Textures
	topTexture = {
		["top_blizzard_classic.tga"] = "Blizzard top Classic",
		["top_blizzard_modern.tga"] = "Blizzard top Modern",
		["top_cataclysm.tga"] = "Cataclysm top",
		["top_northrend.tga"] = "Northrend top",
		[""] = "None",
		["top_custom1.tga"] = "Custom top 1",
		["top_custom2.tga"] = "Custom top 2",
		["top_custom3.tga"] = "Custom top 3",
	},

	-- UI background Textures
	uiBackground = {
		--	["ui_blizzard_classic.tga"] = "Blizzard UI Classic",
		--	["ui_cataclysm.tga"] = "Cataclysm UI",
		--	["ui_northrend.tga"] = "Northrend UI",
		--	[""] = "None", -- Doesn't make sense for this dropdown
		["ui_custom1.tga"] = "Custom UI 1",
		["ui_custom2.tga"] = "Custom UI 2",
		["ui_custom3.tga"] = "Custom UI 3",
	},

	-- Art background Textures
	artBackground = {
		["art_cataclysm.tga"] = "Cataclysm Art",
		["art_cataclysm_wide.tga"] = "Cataclysm Art Wide",
		["art_cataclysm_2.tga"] = "Cataclysm Art 2",
		["art_northrend.tga"] = "Northrend Art",
		--	[""] = "None", -- Doesn't make sense for this dropdown
		["art_custom1.tga"] = "Custom Art 1",
		["art_custom2.tga"] = "Custom Art 2",
		["art_custom3.tga"] = "Custom Art 3",
	},

	-- Custom fade shapes
	fadeMasks = {
		["alpha_fade_soft_circular.tga"] = "Soft Circular",
		["alpha_fade_soft_circular_small.tga"] = "Soft Circular Small",
		["alpha_fade_soft_circular_large.tga"] = "Soft Circular Large",
		["alpha_fade_soft_elliptical.tga"] = "Soft Elliptical",
		["alpha_fade_soft_elliptical_small.tga"] = "Soft Elliptical Small",
		["alpha_fade_soft_elliptical_large.tga"] = "Soft Elliptical Large",
		["alpha_fade_soft_square.tga"] = "Soft Square",
		["alpha_fade_soft_square_small.tga"] = "Soft Square Small",
		["alpha_fade_soft_square_large.tga"] = "Soft Square Large",
		["alpha_fade_hard_square.tga"] = "Hard Square",
		["alpha_fade_hard_square_small.tga"] = "Hard Square Small",
		["alpha_fade_hard_square_large.tga"] = "Hard Square Large",
		["alpha_fade_hard_circular.tga"] = "Hard Circular",
		["alpha_fade_hard_circular_small.tga"] = "Hard Circular Small",
		["alpha_fade_hard_circular_large.tga"] = "Hard Circular Large",
		["alpha_fade_hard_elliptical.tga"] = "Hard Elliptical",
		["alpha_fade_hard_elliptical_small.tga"] = "Hard Elliptical Small",
		["alpha_fade_hard_elliptical_large.tga"] = "Hard Elliptical Large",
		["alpha_fade_custom1.tga"] = "Custom Fade 1",
		["alpha_fade_custom2.tga"] = "Custom Fade 2",
		["alpha_fade_custom3.tga"] = "Custom Fade 3",
	},

	-- Currency Textures
	currency = {
		["currency_blizzard_modern.tga"] = "Blizzard Currency Modern",
		["currency_blizzard_classic.tga"] = "Blizzard Currency Classic",
		--	["currency_cataclysm.tga"] = "Cataclysm Currency",
		--	["currency_northrend.tga"] = "Northrend Currency",
		["currency_custom1.tga"] = "Custom Currency 1",
		["currency_custom2.tga"] = "Custom Currency 2",
		["currency_custom3.tga"] = "Custom Currency 3",
		[""] = "None",
	},

	-- Gold text Textures (sharing same set as currency)
	goldtext = {
		["gold_blizzard_modern.tga"] = "Blizzard Currency Modern",
		["gold_blizzard_classic.tga"] = "Blizzard Currency Classic",
		--	["gold_cataclysm.tga"] = "Cataclysm Gold",
		--	["gold_northrend.tga"] = "Northrend Gold",
		["gold_custom1.tga"] = "Custom Gold 1",
		["gold_custom2.tga"] = "Custom Gold 2",
		["gold_custom3.tga"] = "Custom Gold 3",
		[""] = "None",
	},
}
-- Helper function to ensure settings exist
function addon:EnsureSettings(defaults, current)
	if type(defaults) ~= "table" then return end

	if type(current) ~= "table" then current = {} end

	for k, v in pairs(defaults) do
		if type(v) == "table" then
			if current[k] == nil then
				current[k] = {}
			elseif type(current[k]) ~= "table" then
				current[k] = {}
			end

			-- Recursively ensure settings for nested tables
			self:EnsureSettings(v, current[k])
		elseif current[k] == nil then
			-- For primitive types, simply copy if missing
			current[k] = v
		end
	end

	debug("Settings ensured and initialized")
	return current
end
