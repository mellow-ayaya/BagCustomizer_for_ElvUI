-- Bag Customizer for ElvUI - Search bar customization
--
-- This module handles customization of the search bar in REGULAR bag frames only.
-- Features:
-- - Custom background color and opacity for search bars
-- - Y position offset control
-- - Proper cleanup when customizations are disabled
local E, L, V, P, G = unpack(ElvUI)
local addon = E:GetModule("BagCustomizer")
local B = E:GetModule("Bags") -- Direct reference to ElvUI bags module
-- Create element namespace
addon.elements = addon.elements or {}
addon.elements.searchBar = {}
local SearchBar = addon.elements.searchBar
-- Store references to customized elements for proper cleanup
SearchBar._customizedSearchBars = {}
SearchBar._customizedStackButtons = {}
SearchBar._positionUpdateTimer = nil
SearchBar._layerUpdateTimer = nil
-- Simple debug function
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][searchBar]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.searchBar or
			not E.db.bagCustomizer.searchBar.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- Check if a frame is a bank-related frame by leveraging core function
local function IsBankFrame(frame)
	-- Use addon's IsBankFrame function if available
	if addon.IsBankFrame then
		return addon:IsBankFrame(frame)
	end

	if not frame then return false end

	-- Basic name check as fallback
	local name = frame:GetName() or ""
	if name:find("Bank") or name:find("Warband") or name:find("Reagent") then
		return true
	end

	-- Check parent frames recursively
	local parent = frame:GetParent()
	if parent then
		return IsBankFrame(parent)
	end

	return false
end

-- Save original position data
local function SaveOriginalPosition(frame)
	-- Prevent saving if already saved or if frame is invalid
	if not frame or not frame.GetPoint or frame._BCZ_originalPosition then return end

	frame._BCZ_originalPosition = {}
	for i = 1, frame:GetNumPoints() do
		local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(i)
		if point then -- Ensure we got valid point data
			table.insert(frame._BCZ_originalPosition, {
				point = point,
				relativeTo = relativeTo,
				relativePoint = relativePoint,
				xOfs = xOfs,
				yOfs = yOfs,
			})
		end
	end

	debug("Saved original position for " ..
		(frame:GetName() or "unnamed") .. " with " .. #frame._BCZ_originalPosition .. " anchor points")
end

-- Restore original position data
local function RestoreOriginalPosition(frame)
	-- Only restore if data exists and frame is valid
	if not frame or not frame.SetPoint or not frame._BCZ_originalPosition then return end

	frame:ClearAllPoints()
	for _, pointData in ipairs(frame._BCZ_originalPosition) do
		-- Ensure relativeTo frame still exists, otherwise default to UIParent
		local relativeFrame = pointData.relativeTo
		if relativeFrame and not relativeFrame:IsObjectType("Frame") then
			debug("WARNING: Relative frame for point restore no longer exists, defaulting to UIParent for " ..
				(frame:GetName() or "unnamed"))
			relativeFrame = UIParent
		end

		frame:SetPoint(
			pointData.point,
			relativeFrame, -- Use potentially adjusted relative frame
			pointData.relativePoint,
			pointData.xOfs,
			pointData.yOfs
		)
	end

	frame._BCZ_originalPosition = nil
	debug("Restored original position for " .. (frame:GetName() or "unnamed"))
end

-- Get search box directly from a container frame (regular bags only)
local function GetSearchBox(containerFrame)
	if not containerFrame then return nil end

	-- Skip bank-related frames (checked at container level now)
	if IsBankFrame(containerFrame) then
		debug("Skipping bank-related container frame for search box")
		return nil
	end

	-- Direct property access - most likely case in current ElvUI
	if containerFrame.SearchBox and containerFrame.SearchBox:IsObjectType("EditBox") then
		return containerFrame.SearchBox
	end

	-- Alternative property names
	if containerFrame.editBox and containerFrame.editBox:IsObjectType("EditBox") then
		return containerFrame.editBox
	end

	-- Fallback: Look for EditBox children (only if containerFrame itself isn't bank-related)
	if containerFrame.GetChildren then
		for i = 1, containerFrame:GetNumChildren() do
			local child = select(i, containerFrame:GetChildren())
			if child and child:IsObjectType("EditBox") then
				-- If it has a searchIcon or Instructions with "Search" text, it's likely the search box
				if (child.searchIcon) or
						(child.Instructions and child.Instructions:GetText() == "Search") then
					return child
				end
			end
		end

		-- Last resort: any EditBox
		for i = 1, containerFrame:GetNumChildren() do
			local child = select(i, containerFrame:GetChildren())
			if child and child:IsObjectType("EditBox") then
				return child
			end
		end
	end

	return nil
end

-- Apply custom styling to search bar
-- @param searchBar: The search bar EditBox frame
function SearchBar:ApplySearchBarBackdrop(searchBar)
	if not searchBar or not searchBar.IsObjectType or not searchBar:IsObjectType("EditBox") then
		debug("ApplySearchBarBackdrop: Invalid searchBar provided.")
		return
	end

	-- Double check it's not somehow part of a bank frame
	if IsBankFrame(searchBar) then return end

	local settings = E.db.bagCustomizer and E.db.bagCustomizer.searchBarBackdrop
	local globalEnabled = E.db.bagCustomizer and E.db.bagCustomizer.enabled
	local featureEnabled = settings and settings.enable
	-- Revert if addon disabled, feature disabled, or search bar is no longer valid
	if not globalEnabled or not featureEnabled then
		self:RevertSearchBarBackdrop(searchBar)
		return
	end

	-- Apply color to the SearchEditBox's backdrop
	if searchBar.backdrop then
		-- Store original colors for later restoration
		if not searchBar._BCZ_originalBackdropColor then
			local r, g, b, a = searchBar.backdrop:GetBackdropColor()
			searchBar._BCZ_originalBackdropColor = { r, g, b, a }
		end

		if not searchBar._BCZ_originalBorderColor and searchBar.backdrop.SetBackdropBorderColor then
			-- Use GetBackdropBorderColor if available, otherwise assume default
			local r, g, b, a
			if searchBar.backdrop.GetBackdropBorderColor then
				r, g, b, a = searchBar.backdrop:GetBackdropBorderColor()
			else
				r, g, b, a = unpack(E.media.bordercolor) -- Fallback to ElvUI default
			end

			searchBar._BCZ_originalBorderColor = { r, g, b, a or 1 }
		end

		-- Apply our custom colors
		searchBar.backdrop:SetBackdropColor(
			settings.color.r,
			settings.color.g,
			settings.color.b,
			settings.alpha
		)
		-- Handle border visibility based on the setting
		if searchBar.backdrop.SetBackdropBorderColor then
			if settings.hideBorder then
				searchBar.backdrop:SetBackdropBorderColor(0, 0, 0, 0) -- Transparent border
			else
				-- Restore original border color if we have it
				if searchBar._BCZ_originalBorderColor then
					searchBar.backdrop:SetBackdropBorderColor(unpack(searchBar._BCZ_originalBorderColor))
				else
					-- Fall back to ElvUI default border color if GetBackdropBorderColor wasn't available
					searchBar.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
				end
			end
		end

		-- Handle Y offset positioning
		if settings.yOffset and settings.yOffset ~= 0 then
			SaveOriginalPosition(searchBar) -- Save original position if not already saved
			if searchBar._BCZ_originalPosition and #searchBar._BCZ_originalPosition > 0 then
				searchBar:ClearAllPoints()
				for i, pointData in ipairs(searchBar._BCZ_originalPosition) do
					-- Ensure relativeTo frame still exists
					local relativeFrame = pointData.relativeTo
					if relativeFrame and not relativeFrame:IsObjectType("Frame") then
						debug("WARNING: Relative frame for offset application no longer exists, defaulting to UIParent for " ..
							(searchBar:GetName() or "unnamed"))
						relativeFrame = UIParent
					end

					searchBar:SetPoint(
						pointData.point,
						relativeFrame,
						pointData.relativePoint,
						pointData.xOfs,
						pointData.yOfs + settings.yOffset -- Apply offset to Y
					)
				end

				debug("Applied Y offset: " .. settings.yOffset .. " to " .. (searchBar:GetName() or "unnamed"))
			else
				debug("ERROR: No original position saved/found, can't apply Y offset to " .. (searchBar:GetName() or "unnamed"))
			end
		else
			-- If offset is 0, restore original position if it was previously modified
			if searchBar._BCZ_originalPosition then
				RestoreOriginalPosition(searchBar)
			end
		end

		-- Mark as customized and store reference if not already stored
		if not searchBar._BCZ_searchBarCustomized then
			searchBar._BCZ_searchBarCustomized = true
			self._customizedSearchBars[searchBar] = true -- Use frame as key
			debug("Applied search bar backdrop styling to " .. (searchBar:GetName() or "unnamed"))
		end
	else
		debug("Search bar " .. (searchBar:GetName() or "unnamed") .. " has no backdrop to customize")
	end
end

-- Revert search bar styling
-- @param searchBar: The search bar EditBox frame
function SearchBar:RevertSearchBarBackdrop(searchBar)
	if not searchBar or not searchBar:IsObjectType("EditBox") or not searchBar._BCZ_searchBarCustomized then
		-- If not customized, ensure it's removed from our tracking table just in case
		if searchBar then self._customizedSearchBars[searchBar] = nil end

		return
	end

	local name = searchBar:GetName() or "unnamed"
	-- Restore backdrop color
	if searchBar.backdrop and searchBar.backdrop.SetBackdropColor then
		if searchBar._BCZ_originalBackdropColor then
			searchBar.backdrop:SetBackdropColor(unpack(searchBar._BCZ_originalBackdropColor))
		else
			-- Fallback to ElvUI default colors if original wasn't stored (shouldn't happen often)
			searchBar.backdrop:SetBackdropColor(unpack(E.media.backdropcolor))
			debug("Warning: Original backdrop color not found for " .. name .. ", reverting to ElvUI default.")
		end
	end

	searchBar._BCZ_originalBackdropColor = nil -- Clear stored original
	-- Restore border color
	if searchBar.backdrop and searchBar.backdrop.SetBackdropBorderColor then
		if searchBar._BCZ_originalBorderColor then
			searchBar.backdrop:SetBackdropBorderColor(unpack(searchBar._BCZ_originalBorderColor))
		else
			-- Fallback to ElvUI default border color
			searchBar.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			debug("Warning: Original border color not found for " .. name .. ", reverting to ElvUI default.")
		end
	end

	searchBar._BCZ_originalBorderColor = nil -- Clear stored original
	-- Restore original position if we changed it
	if searchBar._BCZ_originalPosition then
		RestoreOriginalPosition(searchBar)
	end

	searchBar._BCZ_searchBarCustomized = nil
	self._customizedSearchBars[searchBar] = nil -- Remove from tracking
	debug("Reverted search bar styling for " .. name)
end

-- Find stack button in a container frame (regular bags only)
function SearchBar:FindStackButton(containerFrame)
	if not containerFrame or IsBankFrame(containerFrame) then
		return nil
	end

	-- First check for direct property
	if containerFrame.stackButton and containerFrame.stackButton:IsObjectType("Button") then
		return containerFrame.stackButton
	end

	-- Global name lookup (less reliable, but might exist)
	local stackButton = _G["ElvUI_ContainerFrameStackButton"]
	if stackButton and stackButton:IsObjectType("Button") and stackButton:GetParent() == containerFrame then
		return stackButton
	end

	-- Find by name pattern within children
	if containerFrame.GetChildren then
		for _, child in ipairs({ containerFrame:GetChildren() }) do
			local name = child:GetName() or ""
			-- Be more specific if possible, ElvUI might use consistent naming
			if (name == "ElvUI_ContainerFrameStackButton" or name:find("StackButton")) and
					child:IsObjectType("Button") then
				return child
			end
		end
	end

	return nil
end

-- Apply stack button positioning (regular bags only)
-- Apply stack button positioning (regular bags only)
function SearchBar:ApplyStackButtonPosition(containerFrame)
	if not containerFrame or IsBankFrame(containerFrame) then
		return
	end

	local stackButton = self:FindStackButton(containerFrame)
	if not stackButton then
		-- Don't debug spam if stack button simply doesn't exist for this container
		return
	end

	local settings = E.db.bagCustomizer and E.db.bagCustomizer.searchBarBackdrop
	local globalEnabled = E.db.bagCustomizer and E.db.bagCustomizer.enabled
	local featureEnabled = settings and settings.enable
	local offset = settings and settings.stackButtonYOffset or 0
	-- DEBUG ADDED: Check the flag status *before* the revert decision
	local buttonName = stackButton:GetName() or "unnamed button"
	local isCustomizedFlag = stackButton._BCZ_stackButtonCustomized -- Capture value for debug
	debug("ApplyStackButtonPosition: Checking button '" ..
		buttonName .. "'. Customized flag is: " .. tostring(isCustomizedFlag))
	-- Revert if addon disabled, feature disabled, offset is 0, or button invalid
	if not globalEnabled or not featureEnabled or offset == 0 then
		-- DEBUG ADDED: Confirm entering the revert path
		debug("ApplyStackButtonPosition: Conditions met to REVERT button '" .. buttonName .. "'. Attempting call...")
		self:RevertStackButtonPosition(stackButton) -- Pass the button directly
		return                                    -- Important: Exit after attempting revert
	end

	-- If we get here, we are applying (or reapplying) the customization
	-- No need to get name again, already have buttonName
	debug("Found stack button: " .. buttonName)
	-- Save original position if not already saved
	SaveOriginalPosition(stackButton)
	-- Apply Y offset
	if stackButton._BCZ_originalPosition and #stackButton._BCZ_originalPosition > 0 then
		stackButton:ClearAllPoints()
		for i, pointData in ipairs(stackButton._BCZ_originalPosition) do
			local relativeFrame = pointData.relativeTo
			if relativeFrame and not relativeFrame:IsObjectType("Frame") then
				debug("WARNING: Relative frame for offset application no longer exists, defaulting to UIParent for " ..
					buttonName)
				relativeFrame = UIParent
			end

			stackButton:SetPoint(
				pointData.point,
				relativeFrame,
				pointData.relativePoint,
				pointData.xOfs,
				pointData.yOfs + offset -- Apply offset
			)
		end

		debug("Applied Y offset (" .. offset .. ") to stack button: " .. buttonName)
		-- Mark as customized and store reference if not already stored
		-- Store flag directly on the button now
		-- Set the flag *every time* we successfully apply the offset, in case of frame recreation
		if not stackButton._BCZ_stackButtonCustomized then
			debug("Marked stack button customized: " .. buttonName)
		end

		stackButton._BCZ_stackButtonCustomized = true -- Ensure flag is set
		self._customizedStackButtons[stackButton] = true
	else
		debug("ERROR: No original position saved for stack button " .. buttonName .. ", can't apply Y offset")
	end
end

-- Revert stack button positioning
-- @param stackButton: The Button frame to revert
function SearchBar:RevertStackButtonPosition(stackButton)
	-- Check if the button is valid and was actually customized by us
	if not stackButton or not stackButton:IsObjectType("Button") or not stackButton._BCZ_stackButtonCustomized then
		-- If not customized, ensure it's removed from our tracking table just in case
		if stackButton then self._customizedStackButtons[stackButton] = nil end

		return
	end

	local name = stackButton:GetName() or "unnamed button"
	-- Restore original position if we have it
	if stackButton._BCZ_originalPosition then
		RestoreOriginalPosition(stackButton)
	else
		debug("Warning: Original position data not found for stack button " .. name .. ", cannot restore.")
	end

	stackButton._BCZ_stackButtonCustomized = nil
	self._customizedStackButtons[stackButton] = nil -- Remove from tracking
	debug("Reverted stack button positioning for " .. name)
end

-- Apply styling to all known regular bag frames
function SearchBar:ApplyToAllBagFrames()
	if not B or not B.BagFrames then return end

	local processedFrames = {} -- Prevent processing same container multiple times if referenced differently
	for frameName, containerFrame in pairs(B.BagFrames) do
		if containerFrame and not processedFrames[containerFrame] and not IsBankFrame(containerFrame) then
			local searchBox = GetSearchBox(containerFrame)
			if searchBox then
				self:ApplySearchBarBackdrop(searchBox)
			end

			-- ApplyStackButtonPosition now finds the button itself
			self:ApplyStackButtonPosition(containerFrame)
			processedFrames[containerFrame] = true
		end
	end
end

-- Revert all customizations applied by this module
function SearchBar:ResetAll()
	debug("ResetAll called - Reverting all search bar and stack button customizations.")
	-- Iterate over copies of the keys to avoid modification issues during iteration
	local searchBarsToReset = {}
	for bar in pairs(self._customizedSearchBars) do
		table.insert(searchBarsToReset, bar)
	end

	for _, bar in ipairs(searchBarsToReset) do
		if bar and bar:IsObjectType("EditBox") then -- Check validity before reverting
			self:RevertSearchBarBackdrop(bar)
		else
			self._customizedSearchBars[bar] = nil -- Remove invalid entry
		end
	end

	local buttonsToReset = {}
	for btn in pairs(self._customizedStackButtons) do
		table.insert(buttonsToReset, btn)
	end

	for _, btn in ipairs(buttonsToReset) do
		if btn and btn:IsObjectType("Button") then -- Check validity before reverting
			self:RevertStackButtonPosition(btn)
		else
			self._customizedStackButtons[btn] = nil -- Remove invalid entry
		end
	end

	-- Ensure tables are cleared even if revert failed for some reason
	self._customizedSearchBars = {}
	self._customizedStackButtons = {}
	debug("ResetAll finished.")
end

-- Cancel any pending update timers
function SearchBar:CancelTimers()
	if self._positionUpdateTimer then
		self._positionUpdateTimer:Cancel()
		self._positionUpdateTimer = nil
		debug("Cancelled position update timer.")
	end

	if self._layerUpdateTimer then
		self._layerUpdateTimer:Cancel()
		self._layerUpdateTimer = nil
		debug("Cancelled layer update timer.")
	end
end

-- Hook into the bag frame creation/update to apply our styling (for regular bags only)
function SearchBar:Initialize()
	debug("Initializing SearchBar module for regular bags only")
	if not B then
		debug("Bags module not found, cannot initialize SearchBar")
		return
	end

	-- Hook Layout
	if B.Layout then
		hooksecurefunc(B, "Layout", function()
			-- This can fire frequently, maybe add a small delay or check if needed?
			-- For now, apply directly.
			debug("SearchBar: B.Layout hook triggered")
			self:ApplyToAllBagFrames()
		end)
	else
		debug("B.Layout not found, styling might not apply correctly on layout changes.")
	end

	-- Hook PositionBagFrames
	if B.PositionBagFrames then
		hooksecurefunc(B, "PositionBagFrames", function()
			if addon.inCombat then return end

			if not self._positionUpdateTimer then -- Use NewTimer for cancellable handle
				self._positionUpdateTimer = C_Timer.NewTimer(0.05, function()
					self._positionUpdateTimer = nil
					if addon:IsAnyBagVisible() then -- Check visibility before applying
						debug("PositionBagFrames Timer Fired - Applying")
						self:ApplyToAllBagFrames()
					end
				end)
			end
		end)
	else
		debug("B.PositionBagFrames not found, positioning hooks unavailable.")
	end

	-- Hook ToggleLayer
	if B.ToggleLayer then
		hooksecurefunc(B, "ToggleLayer", function()
			if not self._layerUpdateTimer then -- Use NewTimer for cancellable handle
				self._layerUpdateTimer = C_Timer.NewTimer(0.05, function()
					self._layerUpdateTimer = nil
					if addon:IsAnyBagVisible() then -- Check visibility before applying
						debug("ToggleLayer Timer Fired - Applying")
						self:ApplyToAllBagFrames()
					end
				end)
			end
		end)
	else
		debug("B.ToggleLayer not found, layer change hooks unavailable.")
	end

	-- Apply to any existing regular bag frames immediately
	self:ApplyToAllBagFrames()
	debug("SearchBar module initialized for regular bags only")
end

-- Called when the addon module is disabled or reloaded
function SearchBar:Disable()
	debug("Disabling SearchBar module...")
	self:CancelTimers()
	self:ResetAll()
	-- NOTE: Unhooking hooksecurefunc requires external libraries (like AceHook)
	-- or storing the original function. Relying on ElvUI's module handling
	-- or /reload to clear hooks for now.
	debug("SearchBar module disabled.")
end

-- Update all search bars in regular bags (e.g., when settings change)
function SearchBar:UpdateAll()
	debug("SearchBar: UpdateAll called (likely from settings change)")
	-- Simply re-applying will handle both enabling/disabling features and value changes
	self:ApplyToAllBagFrames()
end

-- Register with main addon's initialization system
-- Assumes the main addon ('addon') has RegisterElement and calls Initialize/Disable methods
if addon.RegisterElement then
	addon:RegisterElement("searchBar", SearchBar) -- Pass the SearchBar table itself
else
	-- Fallback if RegisterElement doesn't exist (less ideal)
	SearchBar:Initialize()
	-- Hook into addon's ApplyChanges function if it exists (less robust than proper module handling)
	if addon.ApplyChanges then
		hooksecurefunc(addon, "ApplyChanges", function()
			SearchBar:UpdateAll()
		end)
	end

	-- Manually trigger Disable on ADDON_DISABLED? Less clean.
	-- It's better if the main addon handles calling SearchBar:Disable()
	debug(
		"Warning: addon.RegisterElement not found. Using fallback initialization. Proper disable/reset might not occur without main addon support.")
end
