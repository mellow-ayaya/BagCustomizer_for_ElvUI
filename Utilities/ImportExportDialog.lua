-- ElvUI Bag Customizer - Import/Export Dialog System
--
-- This file handles UI dialog interactions for theme and settings import/export.
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags")
local addon = E:GetModule("BagCustomizer")
-- Simple debug function
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][importExportDialog]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.importExportDialog or
		not E.db.bagCustomizer.importExportDialog.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- Constants for dialog settings
local DIALOG_PREFIX = "BCZE_" -- Prefixed namespace to avoid conflicts
local MAX_IMPORT_CHUNK_SIZE = 5000
local DIALOG_STRATA = "FULLSCREEN_DIALOG"
local DIALOG_LEVEL = 100
local EDITBOX_WIDTH = 350
-- Cache frequently used functions locally for better performance
local StaticPopup_Show = StaticPopup_Show
local StaticPopup_Hide = StaticPopup_Hide
local C_Timer_After = C_Timer.After
-- Flag to track active import processing
local isProcessingImport = false
-- =======================================
-- DIALOG DEFINITIONS
-- =======================================
-- Create the export popup dialog
StaticPopupDialogs[DIALOG_PREFIX .. "EXPORT"] = {
	text = "%s",
	button1 = "Close",
	hasEditBox = true,
	editBoxWidth = EDITBOX_WIDTH,
	maxLetters = 0,
	OnShow = function(self, data)
		self.editBox:SetText(data.exportString)
		self.editBox:HighlightText()
		self.editBox:SetFocus()
		self:SetFrameStrata(DIALOG_STRATA)
		self:SetFrameLevel(DIALOG_LEVEL)
		-- Log dialog display for debugging
		debug("Export dialog shown: " .. (data.title or "unknown"))
	end,
	OnHide = function(self)
		self.editBox:SetText("")
		-- Explicitly release memory
		collectgarbage("step", 100)
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	OnAccept = function(self, data)
		self:Hide()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
-- Create the import popup dialog with chunked processing
StaticPopupDialogs[DIALOG_PREFIX .. "IMPORT"] = {
	text = "%s",
	button1 = "Accept",
	button2 = "Cancel",
	hasEditBox = true,
	editBoxWidth = EDITBOX_WIDTH,
	maxLetters = 0,
	OnShow = function(self)
		self.editBox:SetText("")
		self.editBox:SetFocus()
		self:SetFrameStrata(DIALOG_STRATA)
		self:SetFrameLevel(DIALOG_LEVEL)
		-- Reset processing flag on show
		isProcessingImport = false
	end,
	OnAccept = function(self, data)
		local importString = self.editBox:GetText()
		if importString == "" then
			debug("Import failed: Empty string provided")
			print("|cff1784d1Bag Customizer for ElvUI:|r No import string provided.")
			return
		end

		-- Prevent multiple concurrent import operations
		if isProcessingImport then
			debug("Import aborted: Already processing another import")
			print("|cff1784d1Bag Customizer for ElvUI:|r Already processing an import. Please wait...")
			return
		end

		isProcessingImport = true
		-- Display a loading message
		print("|cff1784d1Bag Customizer for ElvUI:|r Processing import string...")
		-- For large imports, use the chunked processing
		if #importString > MAX_IMPORT_CHUNK_SIZE then
			debug("Using chunked import for large string: " .. #importString .. " characters")
			addon:ProcessLargeImport(importString, data)
		else
			-- For smaller imports, process immediately
			addon:ProcessImport(importString, data)
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
-- Theme load confirmation dialog with improved framestrata handling
StaticPopupDialogs[DIALOG_PREFIX .. "LOAD_THEME_CONFIRM"] = {
	text = "Do you want to load the theme '%s' now?",
	button1 = "Yes",
	button2 = "No",
	OnShow = function(self)
		self:SetFrameStrata(DIALOG_STRATA)
		self:SetFrameLevel(DIALOG_LEVEL)
	end,
	OnAccept = function(self, data)
		addon:LoadTheme(data.themeName)
		debug("Loading theme: " .. data.themeName)
		-- Refresh frames with the new theme
		addon:RefreshFramesAfterThemeChange()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
-- Theme deletion confirmation with improved messaging
StaticPopupDialogs[DIALOG_PREFIX .. "DELETE_THEME_CONFIRM"] = {
	text = "Are you sure you want to delete the theme '%s'? This cannot be undone.",
	button1 = "Yes",
	button2 = "No",
	OnShow = function(self)
		self:SetFrameStrata(DIALOG_STRATA)
		self:SetFrameLevel(DIALOG_LEVEL)
	end,
	OnAccept = function(self, data)
		debug("Deleting theme: " .. data.themeName)
		addon:DeleteTheme(data.themeName)
		-- Force refresh of options panel - simplified timer usage
		if E.Libs and E.Libs.AceConfigDialog then
			E.Libs.AceConfigDialog:SelectGroup("ElvUI", "bagCustomizer", "themesTab")
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
-- Reset all settings confirmation with improved handling
StaticPopupDialogs[DIALOG_PREFIX .. "RESET_ALL_CONFIRM"] = {
	text = "Are you sure you want to reset ALL settings and custom themes? This action cannot be undone!",
	button1 = "Yes",
	button2 = "No",
	OnShow = function(self)
		self:SetFrameStrata(DIALOG_STRATA)
		self:SetFrameLevel(DIALOG_LEVEL)
	end,
	OnAccept = function()
		debug("Resetting all settings and themes")
		addon:ResetAllSettings()
		-- Refresh frames with the new default settings
		addon:RefreshFramesAfterThemeChange()
		-- Clear memory after reset
		collectgarbage("collect")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
-- =======================================
-- FRAME REFRESH INTEGRATION (OPTIMIZED)
-- =======================================
-- Refresh all frames after a theme change - Direct ElvUI integration instead of using FrameFinder
function addon:RefreshFramesAfterThemeChange()
	debug("Refreshing frames after theme change")
	-- If ThemeManager has a notification function, use it
	if addon.elements and addon.elements.themeManager and addon.elements.themeManager.NotifyModulesOfThemeChange then
		debug("Using ThemeManager to notify modules")
		addon.elements.themeManager:NotifyModulesOfThemeChange()
		return
	end

	-- Fallback: Direct ElvUI bag updates instead of using FrameFinder
	local B = E:GetModule("Bags")
	if B then
		-- Update all bag slots if function exists
		if B.UpdateAllBagSlots then
			B:UpdateAllBagSlots()
		end

		-- Update all bank slots if bank is open
		if B.BankFrame and B.BankFrame:IsShown() and B.UpdateBankFrameSlots then
			B:UpdateBankFrameSlots()
		end

		-- Update layout if method exists
		if B.Layout then
			B:Layout()
		end
	end

	-- Update all modules directly
	if addon.elements then
		for name, element in pairs(addon.elements) do
			if name ~= "importExportDialog" and element.UpdateAll then
				debug("Directly updating module: " .. name)
				element:UpdateAll()
			end
		end
	end

	-- Also trigger a general update
	addon:Update("ThemeChangeViaDialog", true)
end

-- =======================================
-- IMPROVED PROCESSING FUNCTIONS
-- =======================================
-- Process large imports in chunks to prevent UI freezes
function addon:ProcessLargeImport(importString, dialogData)
	debug("Beginning chunked import processing")
	local stringLen = #importString
	local processedLen = 0
	local chunkSize = MAX_IMPORT_CHUNK_SIZE
	-- Store string temporarily
	addon.importStringTemp = importString
	-- Display progress message
	local statusFrame = addon:CreateImportStatusFrame()
	statusFrame:Show()
	-- Function to process next chunk
	local function processNextChunk()
		-- Update progress display
		local progress = math.floor((processedLen / stringLen) * 100)
		statusFrame:UpdateProgress(progress)
		-- If we've processed everything, finalize
		if processedLen >= stringLen then
			debug("Import processing complete")
			statusFrame:Hide()
			-- Finalize the import
			addon:FinalizeImport(addon.importStringTemp, dialogData)
			-- Clean up
			addon.importStringTemp = nil
			isProcessingImport = false
			return
		end

		-- Process next chunk
		processedLen = processedLen + chunkSize
		-- Schedule next chunk with a small delay
		C_Timer.After(0.01, processNextChunk)
	end

	-- Start the chunked processing
	processNextChunk()
end

-- Create a progress frame for import operations
function addon:CreateImportStatusFrame()
	if not addon.importStatusFrame then
		local frame = CreateFrame("Frame", "BCZEImportStatusFrame", UIParent, "BackdropTemplate")
		frame:SetSize(300, 80)
		frame:SetPoint("CENTER")
		frame:SetFrameStrata("DIALOG")
		frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		frame:SetBackdropColor(0, 0, 0, 0.8)
		frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
		-- Add a title
		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		title:SetPoint("TOP", 0, -10)
		title:SetText("Processing Import")
		frame.title = title
		-- Add progress text
		local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("CENTER", 0, 0)
		text:SetText("0%")
		frame.text = text
		-- Add progress bar
		local bar = CreateFrame("StatusBar", nil, frame)
		bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		bar:SetStatusBarColor(0, 0.7, 0.3)
		bar:SetMinMaxValues(0, 100)
		bar:SetValue(0)
		bar:SetSize(260, 20)
		bar:SetPoint("BOTTOM", 0, 15)
		frame.bar = bar
		-- Update function
		function frame:UpdateProgress(percent)
			self.bar:SetValue(percent)
			self.text:SetText(percent .. "%")
		end

		addon.importStatusFrame = frame
	end

	return addon.importStatusFrame
end

-- Process a normal import operation
function addon:ProcessImport(importString, dialogData)
	-- Use protected call to catch errors
	local success, result = pcall(function()
		if dialogData.isTheme then
			-- Make sure we don't pass an empty string as the name
			local themeName = dialogData.themeName
			if themeName and themeName == "" then
				themeName = nil
			end

			return addon:ImportTheme(importString, themeName)
		else
			addon.importString = importString
			return addon:ImportSettings(importString)
		end
	end)
	-- Handle result
	addon:HandleImportResult(success, result, dialogData)
	-- Always reset flag
	isProcessingImport = false
end

-- Finalize import after chunked processing
function addon:FinalizeImport(importString, dialogData)
	debug("Finalizing import process")
	-- Use the same process as normal imports
	addon:ProcessImport(importString, dialogData)
	-- Clear the temporary string to free memory
	addon.importStringTemp = nil
	collectgarbage("collect")
end

-- Handle import result with improved error reporting
function addon:HandleImportResult(success, result, dialogData)
	if not success then
		-- An error occurred during import
		debug("Import error: " .. tostring(result))
		print("|cff1784d1Bag Customizer for ElvUI:|r Import failed with error: ", result)
		print("|cff1784d1Bag Customizer for ElvUI:|r Please make sure you've copied the entire export string.")
	elseif not result then
		-- Import function returned false
		debug("Import failed: Invalid data format")
		print("|cff1784d1Bag Customizer for ElvUI:|r Import failed. Please check your import string.")
	else
		-- Import was successful
		debug("Import successful")
		print("|cff1784d1Bag Customizer for ElvUI:|r Import successful!")
		-- Invalidate caches to ensure settings take effect
		if addon.InvalidateCache then
			addon:InvalidateCache()
		end

		-- Refresh UI frames with the new settings
		addon:RefreshFramesAfterThemeChange()
		-- Check if we need to offer loading the theme
		if dialogData.isTheme and type(result) == "string" then
			-- Simplified: Use a single timer call instead of nested calls
			StaticPopup_Show(DIALOG_PREFIX .. "LOAD_THEME_CONFIRM", result, nil, { themeName = result })
		end

		-- Force refresh of options panel if it's open
		addon:RefreshOptionsPanel(dialogData.isTheme)
	end
end

-- Refresh the options panel - Optimized with direct selection
function addon:RefreshOptionsPanel(isThemeTab)
	if E.Libs and E.Libs.AceConfigDialog and E.Libs.AceConfigDialog.OpenFrames
		and E.Libs.AceConfigDialog.OpenFrames.ElvUI then
		-- Simplified timer usage - single timer instead of nested timers
		C_Timer.After(0.2, function()
			E.Libs.AceConfigDialog:SelectGroup("ElvUI", "bagCustomizer")
			-- Select the themes tab if we imported a theme
			if isThemeTab then
				E.Libs.AceConfigDialog:SelectGroup("ElvUI", "bagCustomizer", "themesTab")
			end
		end)
	end
end

-- =======================================
-- DIALOG MANAGEMENT FUNCTIONS
-- =======================================
-- Show export popup with generated export string
function addon:ShowExportPopup(title, exportFunc)
	local exportString = ""
	-- Try to get the export string using the provided function
	if type(exportFunc) == "function" then
		exportString = exportFunc() or ""
		-- Or use theme export if title contains "Theme"
	elseif title:find("Theme") then
		exportString = self:ExportTheme(self.selectedExportTheme) or ""
		-- Otherwise use settings export
	else
		exportString = self:ExportSettings() or ""
	end

	if exportString == "" then
		debug("Export failed: Empty export string generated")
		print("|cff1784d1Bag Customizer for ElvUI:|r Failed to generate export string.")
		return
	end

	-- Open the popup with the export string
	StaticPopup_Show(DIALOG_PREFIX .. "EXPORT", title, nil, {
		exportString = exportString,
		title = title,
	})
end

-- Show import popup with improved data handling
function addon:ShowImportPopup(title, isTheme, themeName)
	StaticPopup_Show(DIALOG_PREFIX .. "IMPORT", title, nil, {
		isTheme = isTheme,
		themeName = themeName,
		title = title,
	})
end

-- Show theme export popup with error checking
function addon:ShowThemeExportPopup()
	local themeName = self.selectedExportTheme
	-- Validate the theme exists and is not a built-in theme
	if not themeName or themeName == "" then
		debug("Theme export failed: No theme selected")
		print("|cff1784d1Bag Customizer for ElvUI:|r Please select a theme to export.")
		return
	end

	if themeName:sub(1, 1) == "*" then
		debug("Theme export failed: Cannot export built-in theme")
		print("|cff1784d1Bag Customizer for ElvUI:|r Built-in themes cannot be exported.")
		return
	end

	local title = "Export Theme: " .. themeName
	self:ShowExportPopup(title, function()
		return self:ExportTheme(themeName)
	end)
end

-- Show theme import popup with consistent UI
function addon:ShowThemeImportPopup()
	self:ShowImportPopup("Import Theme", true, self.themeImportName)
end

-- Function to confirm loading a theme with validated input
function addon:ConfirmLoadTheme(themeName)
	if not themeName or themeName == "" then
		debug("Load theme failed: No theme name provided")
		return
	end

	StaticPopup_Show(DIALOG_PREFIX .. "LOAD_THEME_CONFIRM", themeName, nil, { themeName = themeName })
end

-- Confirm theme deletion with safety checks
function addon:ConfirmDeleteTheme(themeName)
	if not themeName then
		debug("Delete theme failed: No theme name provided")
		return
	end

	-- Prevent deleting built-in themes
	if themeName:sub(1, 1) == "*" then
		debug("Delete theme failed: Cannot delete built-in theme")
		print("|cff1784d1Bag Customizer for ElvUI:|r Built-in themes cannot be deleted.")
		return
	end

	StaticPopup_Show(DIALOG_PREFIX .. "DELETE_THEME_CONFIRM", themeName, nil, { themeName = themeName })
end

-- Confirm resetting all settings with enhanced UI
function addon:ConfirmResetAllSettings()
	StaticPopup_Show(DIALOG_PREFIX .. "RESET_ALL_CONFIRM")
end

-- Dialog close helper function
function addon:CloseDialogs()
	StaticPopup_Hide(DIALOG_PREFIX .. "EXPORT")
	StaticPopup_Hide(DIALOG_PREFIX .. "IMPORT")
	StaticPopup_Hide(DIALOG_PREFIX .. "LOAD_THEME_CONFIRM")
	StaticPopup_Hide(DIALOG_PREFIX .. "DELETE_THEME_CONFIRM")
	StaticPopup_Hide(DIALOG_PREFIX .. "RESET_ALL_CONFIRM")
	-- Also close legacy dialogs for backward compatibility
	StaticPopup_Hide("BagCustomizer_for_ElvUI_EXPORT")
	StaticPopup_Hide("BagCustomizer_for_ElvUI_IMPORT")
	StaticPopup_Hide("BagCustomizer_for_ElvUI_LOAD_THEME_CONFIRM")
	StaticPopup_Hide("BagCustomizer_for_ElvUI_DELETE_THEME_CONFIRM")
	StaticPopup_Hide("BagCustomizer_for_ElvUI_RESET_ALL_CONFIRM")
end

-- Compatibility function for older code
addon.CreateCustomImportExportDialog = function()
	debug("CreateCustomImportExportDialog called (deprecated)")
end
-- Direct event handling instead of using complex callback system
-- Register with ElvUI's events directly
if addon.RegisterEvent then
	addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		addon:CloseDialogs()
	end)
	addon:RegisterEvent("PLAYER_LOGOUT", function()
		-- Clear any temporary storage
		addon.importString = nil
		addon.importStringTemp = nil
		addon.selectedExportTheme = nil
		isProcessingImport = false
	end)
else
	-- Fallback to the existing event system if needed
	addon:RegisterElementUpdate("importExportDialog", function(reason)
		if reason == "PLAYER_ENTERING_WORLD" then
			addon:CloseDialogs()
		elseif reason == "PLAYER_LOGOUT" then
			-- Clear any temporary storage
			addon.importString = nil
			addon.importStringTemp = nil
			addon.selectedExportTheme = nil
			isProcessingImport = false
		end
	end)
end

-- Simplified memory management
if addon.elements then
	addon.elements.importExportDialog = {
		CleanupMemory = function()
			addon.importString = nil
			addon.importStringTemp = nil
			collectgarbage("collect")
		end,

		UpdateAll = function(self)
			-- Nothing to update in this module
			debug("ImportExportDialog: UpdateAll called")
		end,
	}
end

-- Debug message when module loads
debug("ImportExportDialog module loaded")
