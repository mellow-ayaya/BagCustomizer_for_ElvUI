-- ElvUI Bag Customizer - Theme Management
--
-- This module handles theme management, import/export functionality and serialization.
local E, L, V, P, G = unpack(ElvUI)
local addon = E:GetModule("BagCustomizer")
-- Simple debug function
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][themeManager]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.themeManager or
			not E.db.bagCustomizer.themeManager.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- Create theme manager namespace
addon.elements.themeManager = {}
local ThemeManager = addon.elements.themeManager
-- Constants and cached values
local MAX_CACHE_SIZE = 50
local THEME_VERSION = "2.2" -- Increment when format changes
local BUILT_IN_THEME_PREFIX = "*"
-- Memory optimization: local cache for serialization/deserialization
local texturePathCache = {}
local deserializationCache = {}
-- ========================================
-- CORE THEME MANAGEMENT SYSTEM
-- ========================================
-- Initialize the themes system
function ThemeManager:Initialize()
	debug("Initializing")
	-- Create a single source of truth for themes
	if not BagCustomizer_for_ElvUIDB then
		BagCustomizer_for_ElvUIDB = {}
	end

	if not BagCustomizer_for_ElvUIDB.themes then
		BagCustomizer_for_ElvUIDB.themes = {}
	end

	-- Define required fields for themes (for validation)
	self.requiredThemeFields = {
		"inventoryBackgroundAdjust",
		"borders",
		"enabled" }
	-- Define the built-in themes (could be moved to Settings.lua)
	self.builtInThemes = {
		["Blizzard Modern"] =
		"BCTHEME:^1^T^Sname^Sblizz~`(2)^Ssettings^T^Scustom1PresetSettings^T^SglobalScaleFactor^N1^SapplyMainBorderToEmptyAssigned^b^SscaleFactor^N100^SdisableElvUIHighlight^b^SseparateEmptyBorder^b^t^SgoldTextTexture^T^StileSpacing^N0^Senable^B^Suse3Slice^B^SyOffset^N0^SanchorToHolderFrame^B^SleftBreakPct^N5^SautoHeight^B^SmatchHolderFrameWidth^B^SpreserveAspectRatio^b^Sscale^N1^SedgeSize^N10^SuseTiling^B^SholderFrameYOffset^N0^SrightBreakPct^N95^SwidthModifier^N0^Salpha^N1^StileOffset^N0^SxOffset^N0^Swidth^N100^SautoWidth^B^SholderFrameXOffset^N0^Sheight^N20^SheightAdjustment^N0^Stexture^Sgold_blizzard_modern.tga^SuseCustomColor^b^t^StextureHeightOffset^N-4^ScurrencyHorizontalPadding^N8^Scustom3PresetSettings^T^SglobalScaleFactor^N1^SapplyMainBorderToEmptyAssigned^b^SscaleFactor^N100^SdisableElvUIHighlight^b^SseparateEmptyBorder^b^t^S_metadata^T^Screated^N1744335554^SexportTime^N1744335559^Sversion^S2.2^SuserName^SFrenir^t^ScustomTexture^T^Stexture^Sbackground.tga^SrepeatVertically^b^Spoint^SCENTER^Senable^b^SxOffset^N0^Sscale^N1^Salpha^N0.5^SyOffset^N0^t^SthemeManager^T^Sdebug^b^t^SgoldTextYOffset^N0^Senabled^B^Sdebug^b^SbindTextSettings^T^SapplyToWarbound^B^SapplyToBindOnEquip^B^SapplyToPoorQuality^b^Senable^B^Sbrightness^N250^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^SuseCustomColor^b^t^Score^T^Sdebug^b^t^SenableButtonYChanges^B^ScurrencyModuleEnabled^B^SartBackground^T^SverticalSize^N100^Spoint^SCENTER^SxOffset^N0^SyOffset^N0^ShorizontalSize^N100^ScropHorizontalAmount^N0^Stexture^Sart_northrend.tga^SmaintainArtAspectRatio^B^SmaintainMaskAspectRatio^B^ScropHorizontally^b^Salpha^N1^Sdesaturate^b^Sscale^N1^SmaskShape^Salpha_fade_soft_circular.tga^Senable^b^ScropVertically^b^SuseEdgeFade^b^SuseTint^b^ScropVerticalAmount^N0^StintColor^T^Sb^N1^Sg^N1^Sr^N1^t^t^ScurrencyTexture^T^StileSpacing^N0^Sscale^N1^SrowHeightOffset^N0^StextureXOffset^N-12^SleftBreakPct^N5^Stexture^Scurrency_blizzard_modern.tga^SyOffset^N0^SmatchHolderFrameWidth^B^StextureYOffset^N0^Suse3Slice^B^SedgeSize^N10^SuseTiling^B^SrightBreakPct^N95^StileOffset^N0^SuseVerticalTiling^B^Salpha^N1^Swidth^N100^SxOffset^N0^SwidthModifier^N100^SwidthAdjustment^N0^Senable^B^Sheight^N30^StextureAnchor^SCENTER^SpreserveAspectRatio^B^SautoFitHeight^B^t^SsearchBar^T^Sdebug^b^t^SmainTextures^T^Sdebug^b^t^SinventoryBackgroundAdjust^T^Scolor^T^Sb^N0.1^Sg^N0.1^Sr^N0.1^t^SenableColor^B^Sdebug^b^Sopacity^N0.78^t^SreverseCurrencyGrowth^B^SsearchBarBackdrop^T^ShideBorder^B^SstackButtonYOffset^N20.5^Senable^B^Scolor^T^Sb^N0.1^Sg^N0.1^Sr^N0.1^t^Salpha^N0.7^SyOffset^N21^t^Ssettings^T^Sdebug^b^t^SbindText^T^Sdebug^b^t^ScurrencyTopPadding^N34^Sborders^T^Sminimap^T^Sstyle^Swowui^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Salpha^N1^Sinset^N9^Ssize^N24^t^Selements^T^Sminimap^b^Scleanup^B^SframeHeight^B^SsearchBar^B^SvendorGrays^B^Sstack^B^StoggleBars^B^SmainFrame^B^t^SsearchBar^T^Sstyle^Swowui^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Salpha^N1^Sinset^N5^Ssize^N14^t^Sbuttons^T^Sstyle^Swowui^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Salpha^N1^Sinset^N4^Ssize^N14^t^Senable^B^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Sstyle^Swowui^SmainFrame^T^Sstyle^Swowui^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Salpha^N1^Sinset^N6^Ssize^N16^t^t^SresourceManager^T^Sdebug^b^t^SgoldAnchorPosition^SBOTTOM_RIGHT_BELOW^ShideDefaultBorders^B^SframeHeight^T^Senable^B^Sdebug^b^SbagSpacing^N35^t^SmiscTextures^T^Sdebug^b^t^Scurrencies^T^Sdebug^b^t^Scustom2PresetSettings^T^SglobalScaleFactor^N1^SapplyMainBorderToEmptyAssigned^b^SscaleFactor^N100^SdisableElvUIHighlight^b^SseparateEmptyBorder^b^t^StopTexture^T^StileSpacing^N0^Sscale^N1^SyOffset^N37^SleftBreakPct^N10^SmanualDimensions^b^Stexture^Stop_blizzard_modern.tga^SedgeSize^N24^StextureHeight^N42^Salpha^N1^StileOffset^N0^SxOffset^N0^SrightBreakPct^N95^StextureWidth^N435^SwidthAdjust^N4^Sheight^N30^Senable^B^SuseTiling^B^SuseSlice^B^t^SgoldTextXOffset^N0^ScurrencyPaddingSize^N30^SuiBackground^T^SyOffset^N0^Spoint^SCENTER^SxOffset^N0^Senable^b^Sscale^N1^Salpha^N1^Stexture^S^t^SupdateSystem^T^Sdebug^b^t^SmiscBorders^T^Sdebug^b^t^SinventorySlots^T^Senable^B^SglobalBrightness^N100^StextureAlpha^N1^SemptySlotColorIntensity^T^Sunassigned^N100^Sassigned^N100^t^SseparateEmptyBorder^B^SuserModifiedScale^b^SemptySlotAlphaAssigned^N0.6^SemptySlotTextureAlpha^N1^SscaleFactor^N104^SemptySlotColor^T^Sb^N1^Sg^N1^Sr^N1^t^SemptySlotBrightness^T^Sunassigned^N100^Sassigned^N100^t^SpoorQualityColor^T^Sb^N0.55^Sg^N0.55^Sr^N0.55^t^ScolorEmptySlotsByAssignment^B^SglobalScaleFactor^N1^Sdebug^b^Spreset^Sblizzard_modern^SshowCommonQualityBorders^B^SglobalColorIntensity^N100^SqualityColorIntensity^T^N1^N100^N2^N100^N3^N100^N4^N100^N5^N100^N6^N100^N7^N100^N0^N100^t^SqualityBrightness^T^N1^N100^N2^N100^N3^N100^N4^N100^N5^N100^N6^N100^N7^N100^N0^N100^t^SshowIndividualBrightness^b^SuseMainBorderForAssignedEmpty^B^Sstyle^SRounded^SshowIndividualColorIntensity^b^SshowPoorQualityBorders^B^ScommonQualityColor^T^Sb^N0.85^Sg^N0.85^Sr^N0.85^t^SdisableElvUIHighlight^B^SemptySlotOpacity^N1^t^SimportExportDialog^T^Sdebug^b^t^ScloseButtonTexture^T^Senable^B^Salpha^N1^StextureXOffset^N0^SbuttonScale^N1.5^StextureYOffset^N0^SanchorToFrameHeight^B^SbuttonXOffset^N7^SbuttonYOffset^N6^Sscale^N1.5^Stexture^Sclose_blizzard_modern.tga^t^SfixGoldTextStrata^B^t^Sversion^S2.2^t^^",
		["ElvUI Default"] =
		"BCTHEME:^1^T^Sname^Sekv^Ssettings^T^Scustom1PresetSettings^T^SglobalScaleFactor^N1^SapplyMainBorderToEmptyAssigned^b^SscaleFactor^N100^SdisableElvUIHighlight^b^SseparateEmptyBorder^b^t^SgoldTextTexture^T^StileSpacing^N0^Senable^B^Suse3Slice^B^SyOffset^N0^SanchorToHolderFrame^B^SleftBreakPct^N5^SautoHeight^B^SmatchHolderFrameWidth^B^SpreserveAspectRatio^b^Sscale^N1^SedgeSize^N10^SuseTiling^B^SholderFrameYOffset^N0^SrightBreakPct^N95^SwidthModifier^N0^Salpha^N1^StileOffset^N0^SxOffset^N0^Swidth^N100^SautoWidth^B^SholderFrameXOffset^N0^Sheight^N20^SheightAdjustment^N0^Stexture^Sgold_blizzard_modern.tga^SuseCustomColor^b^t^StextureHeightOffset^N-4^ScurrencyHorizontalPadding^N8^Scustom3PresetSettings^T^SglobalScaleFactor^N1^SapplyMainBorderToEmptyAssigned^b^SscaleFactor^N100^SdisableElvUIHighlight^b^SseparateEmptyBorder^b^t^S_metadata^T^Screated^N1744335709^SexportTime^N1744335725^Sversion^S2.2^SuserName^SFrenir^t^ScustomTexture^T^Stexture^Sbackground.tga^SrepeatVertically^b^Spoint^SCENTER^Senable^b^SxOffset^N0^Sscale^N1^Salpha^N0.5^SyOffset^N0^t^SthemeManager^T^Sdebug^b^t^SgoldTextYOffset^N0^Senabled^B^Sdebug^b^SbindTextSettings^T^SapplyToWarbound^B^SapplyToBindOnEquip^B^SapplyToPoorQuality^b^Senable^b^Sbrightness^N200^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^SuseCustomColor^b^t^Score^T^Sdebug^b^t^SenableButtonYChanges^B^ScurrencyModuleEnabled^b^SartBackground^T^SverticalSize^N100^Spoint^SCENTER^SxOffset^N0^SyOffset^N0^ShorizontalSize^N100^ScropHorizontalAmount^N0^Stexture^Sart_cataclysm.tga^SmaintainArtAspectRatio^B^SmaintainMaskAspectRatio^B^ScropHorizontally^b^Salpha^N1^Sdesaturate^B^Sscale^N1^SmaskShape^Salpha_fade_soft_circular.tga^Senable^b^ScropVertically^b^SuseEdgeFade^B^SuseTint^b^ScropVerticalAmount^N0^StintColor^T^Sb^N1^Sg^N1^Sr^N1^t^t^ScurrencyTexture^T^StileSpacing^N0^Sscale^N1^SrowHeightOffset^N0^StextureXOffset^N-12^SleftBreakPct^N5^Stexture^Scurrency_blizzard_modern.tga^SyOffset^N0^SmatchHolderFrameWidth^B^StextureYOffset^N0^Suse3Slice^B^SedgeSize^N10^SuseTiling^B^SrightBreakPct^N95^StileOffset^N0^SuseVerticalTiling^B^Salpha^N1^Swidth^N100^SxOffset^N0^SwidthModifier^N100^SwidthAdjustment^N0^Senable^B^Sheight^N30^StextureAnchor^SCENTER^SpreserveAspectRatio^B^SautoFitHeight^B^t^SsearchBar^T^Sdebug^b^t^SmainTextures^T^Sdebug^b^t^SinventoryBackgroundAdjust^T^Scolor^T^Sb^N0.1^Sg^N0.1^Sr^N0.1^t^SenableColor^b^Sdebug^b^Sopacity^N0.78^t^SreverseCurrencyGrowth^B^SsearchBarBackdrop^T^ShideBorder^B^SstackButtonYOffset^N20.5^Senable^b^Scolor^T^Sb^N0.1^Sg^N0.1^Sr^N0.1^t^Salpha^N0.7^SyOffset^N21^t^Ssettings^T^Sdebug^b^t^SbindText^T^Sdebug^b^t^ScurrencyTopPadding^N34^Sborders^T^Sminimap^T^Sstyle^Swowui^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Salpha^N1^Sinset^N9^Ssize^N24^t^Selements^T^Sminimap^b^Scleanup^B^SframeHeight^B^SsearchBar^B^SvendorGrays^B^Sstack^B^StoggleBars^B^SmainFrame^B^t^SsearchBar^T^Sstyle^Swowui^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Salpha^N1^Sinset^N5^Ssize^N14^t^Sbuttons^T^Sstyle^Swowui^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Salpha^N1^Sinset^N4^Ssize^N14^t^Senable^b^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Sstyle^Swowui^SmainFrame^T^Sstyle^Swowui^Scolor^T^Sb^N1^Sg^N1^Sr^N1^t^Salpha^N1^Sinset^N6^Ssize^N16^t^t^SresourceManager^T^Sdebug^b^t^SgoldAnchorPosition^SBOTTOM_RIGHT_BELOW^ShideDefaultBorders^B^SframeHeight^T^Senable^b^Sdebug^b^SbagSpacing^N35^t^SmiscTextures^T^Sdebug^b^t^Scurrencies^T^Sdebug^b^t^Scustom2PresetSettings^T^SglobalScaleFactor^N1^SapplyMainBorderToEmptyAssigned^b^SscaleFactor^N100^SdisableElvUIHighlight^b^SseparateEmptyBorder^b^t^StopTexture^T^StileSpacing^N0^Sscale^N1^SyOffset^N37^SleftBreakPct^N10^SmanualDimensions^b^Stexture^Stop_blizzard_modern.tga^SedgeSize^N24^StextureHeight^N42^Salpha^N1^StileOffset^N0^SxOffset^N0^SrightBreakPct^N95^StextureWidth^N435^SwidthAdjust^N4^Sheight^N30^Senable^b^SuseTiling^B^SuseSlice^B^t^SgoldTextXOffset^N0^ScurrencyPaddingSize^N30^SuiBackground^T^SyOffset^N0^Spoint^SCENTER^SxOffset^N0^Senable^b^Sscale^N1^Salpha^N1^Stexture^Sui_custom1.tga^t^SupdateSystem^T^Sdebug^b^t^SmiscBorders^T^Sdebug^b^t^SinventorySlots^T^Senable^B^SglobalBrightness^N100^StextureAlpha^N1^SemptySlotColorIntensity^T^Sunassigned^N100^Sassigned^N100^t^SseparateEmptyBorder^B^SuserModifiedScale^b^SemptySlotAlphaAssigned^N1^SemptySlotTextureAlpha^N1^SscaleFactor^N104^SemptySlotColor^T^Sb^N1^Sg^N1^Sr^N1^t^SemptySlotBrightness^T^Sunassigned^N100^Sassigned^N100^t^SpoorQualityColor^T^Sb^N0.55^Sg^N0.55^Sr^N0.55^t^ScolorEmptySlotsByAssignment^b^SglobalScaleFactor^N1.04^Sdebug^b^Spreset^Selvui_border_and_texture^SshowCommonQualityBorders^b^SglobalColorIntensity^N100^SqualityColorIntensity^T^N1^N100^N2^N100^N3^N100^N4^N100^N5^N100^N6^N100^N7^N100^N0^N100^t^SqualityBrightness^T^N1^N100^N2^N100^N3^N100^N4^N100^N5^N100^N6^N100^N7^N100^N0^N100^t^SshowIndividualBrightness^b^SuseMainBorderForAssignedEmpty^B^Sstyle^SRounded^SshowIndividualColorIntensity^b^SshowPoorQualityBorders^b^ScommonQualityColor^T^Sb^N0.85^Sg^N0.85^Sr^N0.85^t^SdisableElvUIHighlight^B^SemptySlotOpacity^N1^t^SimportExportDialog^T^Sdebug^b^t^ScloseButtonTexture^T^Senable^b^Salpha^N1^StextureXOffset^N0^SbuttonScale^N1.5^StextureYOffset^N0^SanchorToFrameHeight^B^SbuttonXOffset^N7^SbuttonYOffset^N6^Sscale^N1.5^Stexture^Sclose_blizzard_modern.tga^t^SfixGoldTextStrata^B^t^Sversion^S2.2^t^^",
		["Northrend"] = "BCTHEME:YourFantasyThemeImportString",
		["Sleek"] = "BCTHEME:YourSleekThemeImportString",
	}
	-- Synchronize theme data from ElvUI DB to our DB
	self:SyncThemeData()
	-- Clear caches to start fresh
	self:ClearCaches()
	debug("Initialization complete")
end

-- OPTIMIZED: Simplified module notification system for better performance
function ThemeManager:NotifyModulesOfThemeChange()
	debug("Notifying modules of theme change")
	-- Direct update to ElvUI bag frames (These might still interfere - consider removing/delaying if needed)
	local B = E:GetModule("Bags")
	if B then
		if B.ResetSlotInfo then B:ResetSlotInfo() end

		if B.LayoutBagButtons then B:LayoutBagButtons() end

		if B.UpdateAllBagSlots then B:UpdateAllBagSlots() end
	end

	-- Update the visuals directly
	if addon.UpdateVisuals then
		debug("NotifyModules: Calling addon:UpdateVisuals()")
		-- TODO: Assess if addon:UpdateVisuals() causes immediate layout changes.
		-- If it does, this might need to be delayed or removed.
		addon:UpdateVisuals()
	else
		-- REMOVED: Fallback no longer schedules its own update timer.
		-- The main LoadTheme function handles scheduling the update.
		-- if addon.Update then
		--    addon:Update("ThemeChanged", true)
		-- end
		debug("NotifyModules: No addon:UpdateVisuals found, fallback does nothing now.")
	end

	-- You might want to trigger a simple event instead, which modules can listen to
	-- without forcing an immediate update loop.
	addon:TriggerEvent("THEME_APPLIED")
end

-- Clear all caches to free memory
function ThemeManager:ClearCaches()
	texturePathCache = {}
	deserializationCache = {}
	collectgarbage("step", 100)
	debug("Caches cleared")
end

-- OPTIMIZED: Simplified cache management
function ThemeManager:CleanupMemory()
	self:ClearCaches()
end

-- Synchronize theme data between ElvUI DB and addon DB
function ThemeManager:SyncThemeData()
	-- Create necessary tables if missing
	E.db.bagCustomizerThemes = E.db.bagCustomizerThemes or {}
	BagCustomizer_for_ElvUIDB = BagCustomizer_for_ElvUIDB or {}
	BagCustomizer_for_ElvUIDB.themes = BagCustomizer_for_ElvUIDB.themes or {}
	-- Sync from ElvUI DB to addon DB
	for themeName, themeData in pairs(E.db.bagCustomizerThemes) do
		BagCustomizer_for_ElvUIDB.themes[themeName] = CopyTable(themeData)
	end

	-- Sync from addon DB to ElvUI DB (for newly added themes)
	for themeName, themeData in pairs(BagCustomizer_for_ElvUIDB.themes) do
		if not E.db.bagCustomizerThemes[themeName] then
			E.db.bagCustomizerThemes[themeName] = CopyTable(themeData)
		end
	end

	debug("Theme data synchronized")
end

-- Validate a theme for required fields
function ThemeManager:ValidateTheme(theme)
	if type(theme) ~= "table" then
		debug("Theme validation failed - not a table")
		return false
	end

	for _, field in ipairs(self.requiredThemeFields) do
		if theme[field] == nil then
			debug("Theme missing required field: " .. field)
			return false
		end
	end

	debug("Theme validation passed")
	return true
end

-- ADDED: Helper to ensure required settings exist
function ThemeManager:EnsureRequiredSettings()
	-- Ensure borders elements exist
	if E.db.bagCustomizer.borders and not E.db.bagCustomizer.borders.elements then
		E.db.bagCustomizer.borders.elements = {
			mainFrame = true,
			searchBar = true,
			vendorGrays = true,
			toggleBars = true,
			cleanup = true,
			stack = true,
			minimap = false,
		}
	end

	-- Ensure customTexture exists
	if not E.db.bagCustomizer.customTexture then
		E.db.bagCustomizer.customTexture = {
			enable = false,
			texture = "background.tga",
			alpha = 0.5,
			scale = 1.0,
			point = "CENTER",
			xOffset = 0,
			yOffset = 0,
			repeatVertically = false,
		}
	end
end

-- ADDED: Direct update function without cache invalidation
function ThemeManager:DirectUpdateBagFrames()
	local B = E:GetModule("Bags")
	if B then
		if B.ResetSlotInfo then B:ResetSlotInfo() end

		if B.LayoutBagButtons then B:LayoutBagButtons() end

		if B.UpdateAllBagSlots then B:UpdateAllBagSlots() end
	end
end

-- ========================================
-- THEME OPERATIONS
-- ========================================
-- Save current settings as a theme with validation and naming protection
-- @param themeName: The name to save the theme as
-- @param allowOverwrite: (optional) Set to true to allow overwriting existing themes
function ThemeManager:SaveTheme(themeName, allowOverwrite)
	debug("Saving theme '" .. themeName .. "'")
	-- Initialize themes DB properly
	if not BagCustomizer_for_ElvUIDB then
		BagCustomizer_for_ElvUIDB = {}
	end

	if not BagCustomizer_for_ElvUIDB.themes then
		BagCustomizer_for_ElvUIDB.themes = {}
	end

	-- Prevent overwriting built-in themes
	if self:IsBuiltInTheme(themeName) then
		debug("Cannot save over built-in theme '" .. themeName .. "'")
		print("|cff1784d1Bag Customizer for ElvUI:|r Cannot save over built-in themes.")
		return false
	end

	local finalThemeName = themeName
	-- Check if theme already exists and handle accordingly
	if not allowOverwrite and self:ThemeNameExists(themeName) then
		-- Generate a unique name to avoid overwriting
		finalThemeName = self:GetUniqueThemeName(themeName)
		-- Notify user about the rename
		if finalThemeName ~= themeName then
			debug("Theme renamed from '" ..
				themeName .. "' to '" .. finalThemeName .. "' to avoid overwriting")
			print("|cff1784d1Bag Customizer for ElvUI:|r Theme saved as '" ..
				finalThemeName .. "' to avoid overwriting existing theme.")
		end
	end

	-- Save current settings to our primary DB
	local currentSettings = CopyTable(E.db.bagCustomizer)
	-- Add metadata
	currentSettings._metadata = {
		version = THEME_VERSION,
		created = time(),
		userName = UnitName("player"),
	}
	-- Store in both locations
	BagCustomizer_for_ElvUIDB.themes[finalThemeName] = currentSettings
	E.db.bagCustomizerThemes = E.db.bagCustomizerThemes or {}
	E.db.bagCustomizerThemes[finalThemeName] = currentSettings
	-- Output success message (only if name hasn't changed, otherwise we already printed a message)
	if finalThemeName == themeName then
		print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" .. finalThemeName .. "' saved.")
	end

	return true, finalThemeName
end

-- OPTIMIZED: Streamlined theme loading process with import string support
function ThemeManager:LoadTheme(themeName)
	debug("Loading theme '" .. themeName .. "'")
	self:Initialize() -- Ensure theme DBs are initialized
	-- Check if it's a built-in theme (remove asterisk if present)
	local isBuiltIn = self:IsBuiltInTheme(themeName)
	local actualThemeName = isBuiltIn and themeName:sub(2) or themeName
	local themeSettings
	-- Try to load from built-in themes first
	if isBuiltIn and self.builtInThemes[actualThemeName] then
		-- Check if the built-in theme is an import string
		if type(self.builtInThemes[actualThemeName]) == "string" and
				self.builtInThemes[actualThemeName]:find("^BCTHEME:") then
			debug("Found import string for built-in theme '" .. actualThemeName .. "'")
			local importString = self.builtInThemes[actualThemeName]
			local tempName = "TEMP_" .. actualThemeName -- Use a temporary name for import
			local success, importedName = self:ImportTheme(importString, tempName)
			if not success then
				debug("Failed to import built-in theme '" .. actualThemeName .. "'")
				print("|cff1784d1Bag Customizer for ElvUI:|r Failed to load theme '" .. actualThemeName .. "'.")
				return false
			end

			-- Get the imported theme settings using the potentially renamed temporary name
			local finalTempName = importedName or tempName -- Use the name returned by ImportTheme
			if BagCustomizer_for_ElvUIDB.themes[finalTempName] then
				themeSettings = CopyTable(BagCustomizer_for_ElvUIDB.themes[finalTempName])
				-- Clean up temporary theme
				BagCustomizer_for_ElvUIDB.themes[finalTempName] = nil
				if E.db.bagCustomizerThemes then
					E.db.bagCustomizerThemes[finalTempName] = nil
				end

				debug("Loaded built-in theme '" .. actualThemeName .. "' via import")
			else
				debug("Failed to find imported theme '" .. finalTempName .. "' after import attempt")
				print("|cff1784d1Bag Customizer for ElvUI:|r Failed to load theme '" .. actualThemeName .. "'.")
				return false
			end
		else
			-- Traditional table-based built-in theme
			themeSettings = CopyTable(self.builtInThemes[actualThemeName])
			debug("Loaded built-in theme '" .. actualThemeName .. "' from table")
		end

		-- Otherwise load from user themes
	elseif BagCustomizer_for_ElvUIDB.themes[actualThemeName] then
		themeSettings = CopyTable(BagCustomizer_for_ElvUIDB.themes[actualThemeName])
		debug("Loaded user theme '" .. actualThemeName .. "'")
	else
		debug("Theme '" .. actualThemeName .. "' not found")
		print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" .. actualThemeName .. "' not found.")
		return false
	end

	if not themeSettings then
		-- Loading failed (already printed message)
		return false
	end

	-- <<< ADD EXPLICIT CLEANUP OF TARGET MODULES *BEFORE* APPLYING >>>
	debug("LoadTheme: Running pre-emptive cleanup for relevant modules.")
	local CT_Module = addon:GetCachedModule("currencyAndTextures")
	if CT_Module and CT_Module.Cleanup then
		debug("LoadTheme: Cleaning up currencyAndTextures...")
		-- Use pcall for safety in case Cleanup errors
		local success, err = pcall(function() CT_Module:Cleanup() end)
		if not success then debug("LoadTheme: Error during currencyAndTextures Cleanup: " .. tostring(err)) end
	end

	-- Add cleanup calls for other modules affected by themes if necessary
	-- e.g., local SearchBar_Module = addon:GetCachedModule("searchBar")
	--      if SearchBar_Module and SearchBar_Module.ResetAll then ... end
	-- <<< END ADDED CLEANUP CODE >>>
	-- Remove metadata before applying
	if themeSettings._metadata then
		themeSettings._metadata = nil
	end

	-- Ensure the settings are complete before applying by merging onto defaults
	local newSettings = {} -- Start fresh
	if addon and addon.defaults then
		addon:EnsureSettings(addon.defaults, newSettings)
		self:MergeSettings(newSettings, themeSettings)
		themeSettings = newSettings -- Use the fully merged table
	else
		debug("WARNING: addon.defaults not found, theme settings might be incomplete.")
	end

	-- Apply the potentially merged settings to the database
	E.db.bagCustomizer = themeSettings
	-- Ensure required settings (like borders.elements) exist after applying
	self:EnsureRequiredSettings()
	debug("LoadTheme: Settings applied to DB.")
	-- NOTE: Immediate calls remain commented out.
	-- -- Direct update to ElvUI bag frames
	-- self:DirectUpdateBagFrames()
	-- -- Notify modules about the theme change
	-- self:NotifyModulesOfThemeChange()
	-- Schedule the main UI update via a timer to allow frames to settle
	if addon._themeUpdateTimer then
		debug("LoadTheme: Cancelling previous theme update timer.")
		addon._themeUpdateTimer:Cancel()
		addon._themeUpdateTimer = nil
	end

	local themeNameToUse = actualThemeName                    -- Capture for timer callback
	addon._themeUpdateTimer = C_Timer.NewTimer(0.1, function() -- 0.1 sec delay
		debug("Theme Update Timer Fired: Calling addon:Update for " .. themeNameToUse)
		if addon and addon.Update then
			local invSlotsModule = addon:GetCachedModule("inventorySlots")
			if invSlotsModule and invSlotsModule.ResetForForcedUpdate then
				debug("Theme Update Timer Fired (LoadTheme): Calling InventorySlots:ResetForForcedUpdate()")
				invSlotsModule:ResetForForcedUpdate()
			else
				debug("Theme Update Timer Fired (LoadTheme): WARNING - Could not get InventorySlots module to reset state.")
			end

			-- This Update call will trigger ExecuteUpdate which calls the Apply... functions
			addon:Update("LoadTheme: " .. themeNameToUse, true)
			-- First, try calling it directly on the main addon (if it exists there as a stub)
			if addon.ApplyMinimapBorder then
				addon:ApplyMinimapBorder()
			else
				-- Otherwise, get the UpdateSystem module using GetCachedModule
				local updateSystemModule = addon:GetCachedModule("updateSystem") -- Get the module
				if updateSystemModule and updateSystemModule.ApplyMinimapBorder then
					updateSystemModule:ApplyMinimapBorder()                    -- Call the function ON the module object
				else
					debug("ERROR: Could not find ApplyMinimapBorder function on addon or UpdateSystem module!")
				end
			end

			-- Call UpdateSettings to ensure hooks/state are correct for the *new* theme
			if CT_Module and CT_Module.UpdateSettings then
				debug("Theme Update Timer Fired: Calling currencyAndTextures:UpdateSettings()")
				local success, err = pcall(function() CT_Module:UpdateSettings() end)
				if not success then debug("Theme Update Timer Fired: Error during CT:UpdateSettings: " .. tostring(err)) end
			end

			-- Add calls to UpdateSettings or similar refresh functions for other affected modules if needed
			-- <<< END ADDED REFRESH CODE >>>
		else
			debug("Theme Update Timer Fired - addon or addon:Update not found!")
		end

		addon._themeUpdateTimer = nil -- Clear the handle after execution
	end)
	if addon._themeUpdateTimer then
		debug("LoadTheme: Update timer scheduled successfully.")
	else
		debug("LoadTheme: ERROR - Update timer failed to schedule!")
	end

	-- Hide any confirmation popups
	StaticPopup_Hide("BagCustomizer_for_ElvUI_LOAD_THEME_CONFIRM")
	StaticPopup_Hide("BCZE_LOAD_THEME_CONFIRM")
	debug("LoadTheme: Skipped potentially interfering immediate calls.")
	print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" .. actualThemeName .. "' loaded.")
	return true
end

-- Delete a theme with validation
-- @param themeName: The name of the theme to delete
function ThemeManager:DeleteTheme(themeName)
	debug("Deleting theme '" .. themeName .. "'")
	self:Initialize()
	-- Check if it's a built-in theme
	if self:IsBuiltInTheme(themeName) then
		debug("Cannot delete built-in theme '" .. themeName .. "'")
		print("|cff1784d1Bag Customizer for ElvUI:|r Built-in themes cannot be deleted.")
		return false
	end

	local actualThemeName = themeName
	if not BagCustomizer_for_ElvUIDB.themes[actualThemeName] then
		debug("Theme '" .. actualThemeName .. "' not found")
		print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" .. actualThemeName .. "' not found.")
		return false
	end

	-- Delete from both locations
	BagCustomizer_for_ElvUIDB.themes[actualThemeName] = nil
	if E.db.bagCustomizerThemes then
		E.db.bagCustomizerThemes[actualThemeName] = nil
	end

	print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" .. actualThemeName .. "' deleted.")
	return true
end

-- Rename a theme with validation
-- @param oldName: The current name of the theme
-- @param newName: The new name for the theme
function ThemeManager:RenameTheme(oldName, newName)
	debug("Renaming theme from '" .. oldName .. "' to '" .. newName .. "'")
	self:Initialize()
	-- Validate theme exists
	if not BagCustomizer_for_ElvUIDB.themes[oldName] then
		debug("Theme '" .. oldName .. "' not found")
		print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" .. oldName .. "' not found.")
		return false
	end

	-- Prevent renaming built-in themes
	if self:IsBuiltInTheme(oldName) then
		debug("Cannot rename built-in theme '" .. oldName .. "'")
		print("|cff1784d1Bag Customizer for ElvUI:|r Built-in themes cannot be renamed.")
		return false
	end

	-- Check if new name would conflict with built-in theme
	if self:IsBuiltInThemeName(newName) then
		debug("New name conflicts with built-in theme '" .. newName .. "'")
		print("|cff1784d1Bag Customizer for ElvUI:|r Cannot rename to a built-in theme name.")
		return false
	end

	-- Check if new name conflicts with existing theme
	if BagCustomizer_for_ElvUIDB.themes[newName] then
		debug("New name conflicts with existing theme '" .. newName .. "'")
		print("|cff1784d1Bag Customizer for ElvUI:|r A theme with the name '" .. newName .. "' already exists.")
		return false
	end

	-- Copy the theme with new name in both locations
	BagCustomizer_for_ElvUIDB.themes[newName] = CopyTable(BagCustomizer_for_ElvUIDB.themes[oldName])
	E.db.bagCustomizerThemes = E.db.bagCustomizerThemes or {}
	E.db.bagCustomizerThemes[newName] = CopyTable(BagCustomizer_for_ElvUIDB.themes[oldName])
	-- Remove the old theme from both locations
	BagCustomizer_for_ElvUIDB.themes[oldName] = nil
	E.db.bagCustomizerThemes[oldName] = nil
	print("|cff1784d1Bag Customizer for ElvUI:|r Theme renamed from '" .. oldName .. "' to '" .. newName .. "'.")
	return true
end

-- Get a list of available themes with caching for performance
-- @return: Table with theme names as keys and display names as values
function ThemeManager:GetThemesList()
	debug("Getting themes list")
	-- Initialize if needed
	self:Initialize()
	local themesList = {}
	-- Add built-in themes first (marked with asterisk)
	for themeName, _ in pairs(self.builtInThemes) do
		themesList[BUILT_IN_THEME_PREFIX .. themeName] = themeName .. " (Built-in)"
	end

	-- Add user themes
	if BagCustomizer_for_ElvUIDB and BagCustomizer_for_ElvUIDB.themes then
		for themeName, _ in pairs(BagCustomizer_for_ElvUIDB.themes) do
			-- Just use the theme name directly without version
			themesList[themeName] = themeName
		end
	end

	return themesList
end

-- Helper: Check if a theme is a built-in theme
function ThemeManager:IsBuiltInTheme(themeName)
	return themeName and themeName:sub(1, 1) == BUILT_IN_THEME_PREFIX
end

-- Helper: Check if a name matches a built-in theme
function ThemeManager:IsBuiltInThemeName(themeName)
	for builtInName, _ in pairs(self.builtInThemes) do
		if themeName == builtInName then
			return true
		end
	end

	return false
end

-- Helper: Deeply merge settings tables
function ThemeManager:MergeSettings(target, source)
	for k, v in pairs(source) do
		if type(v) == "table" and type(target[k]) == "table" then
			-- For tables, merge instead of replace
			self:MergeSettings(target[k], v)
		else
			-- Otherwise copy the value
			target[k] = v
		end
	end
end

-- ========================================
-- THEME IMPORT/EXPORT SYSTEM
-- ========================================
-- Export a specific theme to a string
-- @param themeName: Name of the theme to export (nil for current settings)
-- @return: Export string or nil if theme not found
function ThemeManager:ExportTheme(themeName)
	debug("Exporting theme '" .. tostring(themeName) .. "'")
	local themeData
	if not themeName then
		-- Export for current settings has been removed
		debug("Exporting current settings is not supported")
		print("|cff1784d1Bag Customizer for ElvUI:|r Exporting current settings is not supported.")
		return nil
	else
		-- Check if it's a built-in theme
		local isBuiltIn = self:IsBuiltInTheme(themeName)
		local actualThemeName = isBuiltIn and themeName:sub(2) or themeName
		if isBuiltIn and self.builtInThemes[actualThemeName] then
			debug("Cannot export built-in theme '" .. actualThemeName .. "'")
			print("|cff1784d1Bag Customizer for ElvUI:|r Built-in themes cannot be exported.")
			return nil
		elseif BagCustomizer_for_ElvUIDB.themes[actualThemeName] then
			local themeSettings = CopyTable(BagCustomizer_for_ElvUIDB.themes[actualThemeName])
			-- Ensure metadata is updated
			themeSettings._metadata = themeSettings._metadata or {}
			themeSettings._metadata.version = THEME_VERSION
			themeSettings._metadata.exportTime = time()
			themeData = {
				settings = themeSettings,
				version = THEME_VERSION,
				name = actualThemeName,
			}
		else
			debug("Theme '" .. actualThemeName .. "' not found")
			print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" .. actualThemeName .. "' not found.")
			return nil
		end
	end

	-- Serialize theme data safely using pcall
	local success, serializedData = pcall(function()
		return self:SerializeData(themeData)
	end)
	if not success or not serializedData then
		debug("Failed to serialize theme data")
		print("|cff1784d1Bag Customizer for ElvUI:|r Failed to serialize theme data.")
		return nil
	end

	-- Add header for identification
	local exportString = "BCTHEME:" .. serializedData
	return exportString
end

-- OPTIMIZED: Improved theme import with direct updates
function ThemeManager:ImportTheme(importString, newName)
	debug("Importing theme" .. (newName and " as '" .. newName .. "'" or ""))
	if not importString or importString == "" then
		debug("No import string provided")
		print("|cff1784d1Bag Customizer for ElvUI:|r No import string provided.")
		return false, nil
	end

	-- Check if this is a theme export
	if not importString:find("^BCTHEME:") then
		debug("Invalid theme import string format")
		print("|cff1784d1Bag Customizer for ElvUI:|r Invalid theme import string format.")
		return false, nil
	end

	-- Remove header
	local serializedData = importString:sub(9)
	-- Deserialize theme data with improved error handling
	local success, themeData = pcall(function()
		return self:DeserializeData(serializedData)
	end)
	if not success or not themeData then
		debug("Failed to deserialize theme data")
		print(
			"|cff1784d1Bag Customizer for ElvUI:|r Failed to deserialize theme data. The import string may be corrupted.")
		return false, nil
	end

	if not themeData.settings or not themeData.name then
		debug("Invalid theme data (missing required fields)")
		print("|cff1784d1Bag Customizer for ElvUI:|r Invalid theme data in import string (missing required fields).")
		return false, nil
	end

	-- Store original settings for comparison
	local originalSettings = CopyTable(themeData.settings)
	-- Sanitize the settings against current defaults
	if addon and addon.defaults then
		themeData.settings = self:SanitizeSettings(themeData.settings, addon.defaults)
		-- Detect and report dropped settings
		local droppedSettings = self:DetectDroppedSettings(originalSettings, themeData.settings)
		if droppedSettings.count > 0 then
			debug(droppedSettings.count .. " settings dropped during import")
			print("|cff1784d1Bag Customizer for ElvUI:|r " .. droppedSettings.count ..
				" settings were ignored because they're not supported in the current version.")
			if #droppedSettings.examples > 0 then
				print("|cff1784d1Bag Customizer for ElvUI:|r Examples: " ..
					table.concat(droppedSettings.examples, ", "))
			end
		end
	end

	-- Use provided name if specified and not empty, otherwise use the one from the theme
	local themeName
	if newName and newName ~= "" then
		themeName = newName
	else
		themeName = themeData.name
	end

	-- Check for name conflict
	self:Initialize() -- Ensure DB is initialized
	BagCustomizer_for_ElvUIDB = BagCustomizer_for_ElvUIDB or {}
	BagCustomizer_for_ElvUIDB.themes = BagCustomizer_for_ElvUIDB.themes or {}
	-- Handle name conflicts - don't reject but rename automatically
	local finalThemeName = self:GetUniqueThemeName(themeName)
	-- If name was changed, notify user
	if finalThemeName ~= themeName then
		debug("Theme renamed from '" .. themeName .. "' to '" .. finalThemeName .. "'")
		print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" ..
			themeName .. "' was renamed to '" .. finalThemeName .. "' to avoid conflict.")
	end

	-- Update metadata
	themeData.settings._metadata = themeData.settings._metadata or {}
	themeData.settings._metadata.importTime = time()
	themeData.settings._metadata.importedBy = UnitName("player")
	-- Save theme
	BagCustomizer_for_ElvUIDB.themes[finalThemeName] = CopyTable(themeData.settings)
	-- Also save to ElvUI DB
	E.db.bagCustomizerThemes = E.db.bagCustomizerThemes or {}
	E.db.bagCustomizerThemes[finalThemeName] = CopyTable(themeData.settings)
	debug("Theme '" .. finalThemeName .. "' imported successfully")
	print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" .. finalThemeName .. "' imported successfully.")
	-- Ensure all default settings are present after import
	if addon and addon.EnsureSettings and addon.defaults then
		addon:EnsureSettings(addon.defaults, E.db.bagCustomizer)
		-- Direct update to ElvUI bag frames
		self:DirectUpdateBagFrames()
		addon:Update("PostImportThemeCheck", true)
	end

	-- Notify modules about the imported theme - only if we're applying it
	if addon.LoadThemeOnImport then
		self:NotifyModulesOfThemeChange()
	end

	return true, finalThemeName
end

-- Export all settings and themes to a string
function ThemeManager:ExportSettings()
	debug("Exporting all settings and themes")
	-- Create a table with all settings and themes
	local settings = CopyTable(E.db.bagCustomizer)
	local themes = {}
	-- Add metadata
	settings._metadata = {
		version = THEME_VERSION,
		exportTime = time(),
		exportedBy = UnitName("player"),
	}
	-- Include all saved themes
	if BagCustomizer_for_ElvUIDB and BagCustomizer_for_ElvUIDB.themes then
		themes = CopyTable(BagCustomizer_for_ElvUIDB.themes)
	end

	local exportTable = {
		settings = settings,
		themes = themes,
		version = THEME_VERSION,
	}
	-- Serialize using our improved method with error handling
	local success, exportString = pcall(function()
		return self:SerializeData(exportTable)
	end)
	if success and exportString then
		-- Add header to identify the export type
		exportString = "BCEXP:" .. exportString
		addon.exportString = exportString
		debug("Settings export generated successfully")
		print("|cff1784d1Bag Customizer for ElvUI:|r Export string generated. Copy it from the export box.")
		return exportString
	else
		debug("Failed to generate export string")
		print("|cff1784d1Bag Customizer for ElvUI:|r Failed to generate export string.")
		return nil
	end
end

-- OPTIMIZED: Improved settings import with direct updates
function ThemeManager:ImportSettings(importString)
	debug("Importing settings")
	if not importString or importString == "" then
		debug("No import string provided")
		print("|cff1784d1Bag Customizer for ElvUI:|r No import string provided.")
		return false
	end

	-- Check if it's a theme-only import
	if importString:find("^BCTHEME:") then
		debug("Redirecting to theme import")
		return self:ImportTheme(importString)
	end

	local importTable
	-- Try to deserialize with error handling
	local success, result = pcall(function()
		-- Check for our export format
		if importString:find("^BCEXP:") then
			local serializedData = importString:sub(7)
			return self:DeserializeData(serializedData)
		else
			-- Try direct deserialization as fallback
			return self:DeserializeData(importString)
		end
	end)
	if not success or not result then
		debug("Failed to deserialize import string: " .. tostring(result))
		print(
			"|cff1784d1Bag Customizer for ElvUI:|r Invalid import string. Please ensure you pasted the entire export string.")
		return false
	end

	importTable = result
	-- Validate import data
	if not importTable.settings then
		debug("Invalid import data (missing settings)")
		print("|cff1784d1Bag Customizer for ElvUI:|r Invalid import string (missing required data).")
		return false
	end

	-- Store original settings for comparison
	local originalSettings = CopyTable(importTable.settings)
	-- Sanitize the settings against current defaults
	if addon and addon.defaults then
		importTable.settings = self:SanitizeSettings(importTable.settings, addon.defaults)
		-- Process themes if present
		if importTable.themes then
			local originalThemes = CopyTable(importTable.themes)
			for themeName, themeSettings in pairs(originalThemes) do
				importTable.themes[themeName] = self:SanitizeSettings(themeSettings, addon.defaults)
			end
		end

		-- Detect and report dropped settings
		local droppedSettings = self:DetectDroppedSettings(originalSettings, importTable.settings)
		if droppedSettings.count > 0 then
			debug(droppedSettings.count .. " settings dropped during import")
			print("|cff1784d1Bag Customizer for ElvUI:|r " .. droppedSettings.count ..
				" settings were ignored because they're not supported in the current version.")
			if #droppedSettings.examples > 0 then
				print("|cff1784d1Bag Customizer for ElvUI:|r Examples: " ..
					table.concat(droppedSettings.examples, ", "))
			end
		end
	end

	-- Apply settings
	E.db.bagCustomizer = CopyTable(importTable.settings)
	-- Apply themes if present with validation
	if importTable.themes then
		-- Ensure DB exists
		self:Initialize() -- Make sure DB is initialized
		-- Process themes with unique naming
		for themeName, themeData in pairs(importTable.themes) do
			self:ImportSingleTheme(themeName, themeData)
		end
	end

	-- Direct update to ElvUI bag frames
	self:DirectUpdateBagFrames()
	-- Update the UI
	print("|cFF00FF00Bag Customizer:|r ImportSettings: Scheduling update via timer.") -- Debug
	if addon._themeUpdateTimer then
		addon._themeUpdateTimer:Cancel(); addon._themeUpdateTimer = nil;
	end

	addon._themeUpdateTimer = C_Timer.NewTimer(0.1,
		function()                                                                                            -- 0.1 sec delay
			print("|cFF00FF00Bag Customizer:|r Theme Update Timer (from ImportSettings) Fired - Calling Update()") -- Debug
			addon:Update("ImportSettings", true)
			addon._themeUpdateTimer = nil
		end)
	debug("Settings imported successfully")
	print("|cff1784d1Bag Customizer for ElvUI:|r Settings imported successfully!")
	-- Ensure all default settings are present after import
	if addon and addon.EnsureSettings and addon.defaults then
		addon:EnsureSettings(addon.defaults, E.db.bagCustomizer)
	end

	-- Notify modules about the imported settings
	self:NotifyModulesOfThemeChange()
	-- Clean up memory
	collectgarbage("step", 200)
	return true
end

-- Helper to import a single theme during settings import
function ThemeManager:ImportSingleTheme(themeName, themeData)
	debug("Processing import of theme '" .. themeName .. "'")
	-- Get a unique name for the theme to avoid conflicts
	local finalThemeName = self:GetUniqueThemeName(themeName)
	-- If name was changed, notify user
	if finalThemeName ~= themeName then
		debug("Theme renamed from '" .. themeName .. "' to '" .. finalThemeName .. "'")
		print("|cff1784d1Bag Customizer for ElvUI:|r Theme '" ..
			themeName .. "' was renamed to '" .. finalThemeName .. "' to avoid conflict.")
	end

	-- Update metadata
	themeData._metadata = themeData._metadata or {}
	themeData._metadata.importTime = time()
	themeData._metadata.importedBy = UnitName("player")
	-- Save theme to both locations
	BagCustomizer_for_ElvUIDB.themes[finalThemeName] = themeData
	E.db.bagCustomizerThemes = E.db.bagCustomizerThemes or {}
	E.db.bagCustomizerThemes[finalThemeName] = CopyTable(themeData)
	debug("Theme '" .. finalThemeName .. "' imported")
end

-- Helper to get a unique theme name
function ThemeManager:GetUniqueThemeName(themeName)
	local finalThemeName = themeName
	local counter = 2
	-- Check if theme exists in user themes or built-in themes
	while self:ThemeNameExists(finalThemeName) do
		finalThemeName = themeName .. " (" .. counter .. ")"
		counter = counter + 1
	end

	return finalThemeName
end

-- Helper to check if a theme name exists
function ThemeManager:ThemeNameExists(themeName)
	-- Check user themes
	if BagCustomizer_for_ElvUIDB.themes[themeName] then
		return true
	end

	-- Check built-in themes
	for builtInName, _ in pairs(self.builtInThemes) do
		if themeName == builtInName then
			return true
		end
	end

	return false
end

-- ========================================
-- SETTINGS MANAGEMENT FUNCTIONS
-- ========================================
-- Filter imported settings based on current defaults structure
function ThemeManager:SanitizeSettings(importedSettings, defaultSettings)
	debug("Sanitizing imported settings")
	if type(importedSettings) ~= "table" or type(defaultSettings) ~= "table" then
		return CopyTable(defaultSettings)
	end

	-- Start with a fresh copy of the default settings
	local sanitized = CopyTable(defaultSettings)
	-- Function to recursively validate and copy only valid settings
	local function validateAndCopy(imported, defaults, target)
		for k, v in pairs(defaults) do
			-- Only process keys that exist in both imported and defaults
			if imported[k] ~= nil then
				if type(v) == "table" and type(imported[k]) == "table" then
					-- If both are tables, recursively validate nested settings
					validateAndCopy(imported[k], v, target[k])
				elseif type(v) == type(imported[k]) then
					-- If types match, copy the value
					target[k] = imported[k]
				end

				-- If types don't match, keep the default
			end

			-- If key doesn't exist in imported data, keep the default
		end
	end

	-- Start the validation process
	validateAndCopy(importedSettings, defaultSettings, sanitized)
	-- Preserve metadata if present
	if importedSettings._metadata then
		sanitized._metadata = CopyTable(importedSettings._metadata)
	end

	return sanitized
end

-- Detect settings that would be dropped during import
function ThemeManager:DetectDroppedSettings(imported, sanitized, path, results)
	path = path or ""
	results = results or { count = 0, examples = {} }
	if type(imported) ~= "table" or type(sanitized) ~= "table" then
		return results
	end

	-- Find settings in imported data that aren't in sanitized result
	for k, v in pairs(imported) do
		-- Skip metadata with conditional instead of goto
		if k ~= "_metadata" then
			local currentPath = path == "" and k or path .. "." .. k
			if sanitized[k] == nil then
				-- This key doesn't exist in current defaults
				results.count = results.count + 1
				if #results.examples < 5 then
					table.insert(results.examples, currentPath)
				end
			elseif type(v) == "table" and type(sanitized[k]) == "table" then
				-- Check nested tables recursively
				self:DetectDroppedSettings(v, sanitized[k], currentPath, results)
			end
		end
	end

	return results
end

-- OPTIMIZED: Reset all settings with direct updates
function ThemeManager:ResetAllSettings()
	debug("Resetting all settings to defaults")
	-- Reset to default settings
	if addon and addon.defaults then
		-- Copy the defaults from Core
		E.db.bagCustomizer = CopyTable(addon.defaults)
		-- Ensure all critical structures exist using EnsureSettings
		addon:EnsureSettings(addon.defaults, E.db.bagCustomizer)
	else
		-- Fallback if defaults aren't available (existing logic)
		E.db.bagCustomizer = {
			enabled = true,
			debug = false,
			hideDefaultBorders = false,
			background = {
				enableColor = true,
				color = { r = 0.1, g = 0.1, b = 0.1 },
				opacity = 0.5,
			},
		}
		if not E.db.bagCustomizer.searchBarBackdrop then
			E.db.bagCustomizer.searchBarBackdrop = {
				enable = false,
				color = { r = 0.1, g = 0.1, b = 0.1 },
				alpha = 0.7,
				hideBorder = false,
				yOffset = 0,
			}
		end

		if not E.db.bagCustomizer.borders then
			E.db.bagCustomizer.borders = {
				enable = true,
				elements = {
					mainFrame = true,
					searchBar = true,
					vendorGrays = true,
					toggleBars = true,
					cleanup = true,
					stack = true,
					minimap = false,
				},
			}
		end

		-- Ensure inventorySlots exists for fallback case too
		if not E.db.bagCustomizer.inventorySlots then
			E.db.bagCustomizer.inventorySlots = CopyTable(addon.defaults and addon.defaults.inventorySlots or {})
			-- Manually add essential defaults if addon.defaults wasn't available
			if not addon.defaults then
				E.db.bagCustomizer.inventorySlots.enable = true
				E.db.bagCustomizer.inventorySlots.preset = "blizzard_modern" -- or your actual default
				-- Add other minimal required defaults for inventorySlots here...
			end
		end
	end

	-- Clear all user-created themes safely
	if BagCustomizer_for_ElvUIDB then BagCustomizer_for_ElvUIDB.themes = {} end

	if E.db.bagCustomizerThemes then E.db.bagCustomizerThemes = {} end

	-- Clear ThemeManager caches
	self:ClearCaches()
	-- <<< Call RevertAllSlots directly HERE >>>
	local invSlotsModule = addon:GetCachedModule("inventorySlots")
	if invSlotsModule and invSlotsModule.RevertAllSlots then
		debug("ResetAllSettings: Calling InventorySlots:RevertAllSlots() to remove custom skins.")
		invSlotsModule:RevertAllSlots() -- This cleans up visuals and internal InventorySlots state/caches
	else
		debug("ResetAllSettings: WARNING - Could not get InventorySlots module to revert slots.")
	end

	-- <<< END CHANGE >>>
	-- Direct update to ElvUI bag frames (Keep this - ElvUI might need its own state reset)
	self:DirectUpdateBagFrames()
	-- Schedule the addon:Update to re-apply the *default* skin settings
	debug("ResetAllSettings: Scheduling addon:Update via timer.")
	if addon._themeUpdateTimer then
		addon._themeUpdateTimer:Cancel(); addon._themeUpdateTimer = nil;
	end

	addon._themeUpdateTimer = C_Timer.NewTimer(0.1, function()
		debug("Theme Update Timer (from ResetAllSettings) Fired - Calling addon:Update()")
		if addon and addon.Update then
			-- The addon:Update call will now trigger InventorySlots update,
			-- which will re-skin the reverted slots using the default DB settings.
			addon:Update("ResetAllSettings", true)
		else
			debug("Theme Update Timer (from ResetAllSettings) - addon or addon:Update not found!")
		end

		addon._themeUpdateTimer = nil
	end)
	-- Notify modules about the reset (Keep this)
	self:NotifyModulesOfThemeChange()
	-- Notify user (existing logic)
	debug("Reset complete")
	print("|cff1784d1Bag Customizer for ElvUI:|r All settings and user-created themes have been reset to default.")
	-- Force UI refresh (existing logic)
	if E.Libs and E.Libs.AceConfigDialog then
		E.Libs.AceConfigDialog:SelectGroup("ElvUI", "bagCustomizer", "themesTab")
	end

	-- Clean up memory (existing logic)
	collectgarbage("step", 200)
end

-- ========================================
-- SERIALIZATION AND DESERIALIZATION
-- ========================================
-- Improved serialization function with fallbacks
function ThemeManager:SerializeData(data)
	-- Try to use ElvUI's serialization (most reliable)
	if E and E.Libs and E.Libs.Serialize then
		return E.Libs.Serialize:Serialize(data)
	end

	-- Try AceSerializer as a fallback
	if LibStub and LibStub("AceSerializer-3.0", true) then
		local AceSerializer = LibStub("AceSerializer-3.0")
		return AceSerializer:Serialize(data)
	end

	-- If all else fails, try a basic approach
	debug("WARNING: Using basic serialization. This is less reliable.")
	return self:BasicSerialize(data)
end

-- Improved deserialization with caching and error handling
function ThemeManager:DeserializeData(str)
	if not str or str == "" then
		return nil
	end

	-- Check cache first for large strings
	if #str > 100 and deserializationCache[str] then
		debug("Using cached deserialization result")
		return CopyTable(deserializationCache[str])
	end

	local result
	-- Try ElvUI's serialization first (most reliable)
	if E and E.Libs and E.Libs.Serialize then
		local success
		success, result = pcall(function()
			return E.Libs.Serialize:Deserialize(str)
		end)
		if success and result then
			-- Cache result for large strings
			if #str > 100 then
				deserializationCache[str] = CopyTable(result)
				-- Limit cache size
				local count = 0
				for _ in pairs(deserializationCache) do
					count = count + 1
				end

				if count > 10 then
					-- Reset cache if it gets too large
					deserializationCache = {}
					deserializationCache[str] = CopyTable(result)
				end
			end

			return result
		end
	end

	-- Try AceSerializer as a fallback
	if LibStub and LibStub("AceSerializer-3.0", true) then
		local AceSerializer = LibStub("AceSerializer-3.0")
		local success, data = AceSerializer:Deserialize(str)
		if success and data then
			return data
		end
	end

	-- Last resort: try using loadstring with safety precautions
	local success, result = pcall(function()
		local func, err = loadstring("return " .. str)
		if func then
			return func()
		end

		return nil
	end)
	if success and result and type(result) == "table" then
		return result
	end

	return nil
end

-- Basic serialization for fallback (only used if everything else fails)
function ThemeManager:BasicSerialize(data)
	if type(data) ~= "table" then
		return tostring(data)
	end

	local str = "{"
	local first = true
	for k, v in pairs(data) do
		if not first then str = str .. "," else first = false end

		-- Serialize key
		if type(k) == "string" then
			str = str .. string.format("%q", k) .. "="
		else
			str = str .. "[" .. tostring(k) .. "]="
		end

		-- Serialize value
		if type(v) == "table" then
			str = str .. self:BasicSerialize(v)
		elseif type(v) == "string" then
			str = str .. string.format("%q", v)
		elseif type(v) == "number" or type(v) == "boolean" then
			str = str .. tostring(v)
		else
			str = str .. "nil"
		end
	end

	return str .. "}"
end

-- ========================================
-- MAKE FUNCTIONS AVAILABLE TO ADDON INTERFACE
-- ========================================
-- Make theme functions available through addon interface
addon.SaveTheme = function(self, themeName)
	return ThemeManager:SaveTheme(themeName)
end
addon.LoadTheme = function(self, themeName)
	return ThemeManager:LoadTheme(themeName)
end
addon.DeleteTheme = function(self, themeName)
	return ThemeManager:DeleteTheme(themeName)
end
addon.RenameTheme = function(self, oldName, newName)
	return ThemeManager:RenameTheme(oldName, newName)
end
addon.GetThemesList = function(self)
	return ThemeManager:GetThemesList()
end
addon.ExportTheme = function(self, themeName)
	return ThemeManager:ExportTheme(themeName)
end
addon.ImportTheme = function(self, importString, newName)
	return ThemeManager:ImportTheme(importString, newName)
end
addon.ExportSettings = function(self)
	return ThemeManager:ExportSettings()
end
addon.ImportSettings = function(self, importString)
	if not importString and self.importString then
		importString = self.importString
	end

	return ThemeManager:ImportSettings(importString)
end
addon.ResetAllSettings = function(self)
	return ThemeManager:ResetAllSettings()
end
-- OPTIMIZED: Replace RegisterElementUpdate with direct event registration
addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
	ThemeManager:Initialize()
end)
addon:RegisterEvent("PLAYER_LOGOUT", function()
	ThemeManager:ClearCaches()
end)
-- Initialize on load for immediate access
ThemeManager:Initialize()
-- Debug message when module loads
debug("ThemeManager module loaded")
-- Return module
return ThemeManager
