-- Bag Customizer for ElvUI - Border customization (Simplified)
--
-- This module handles custom borders for bag frames and elements.
-- Modified to only apply to regular bag frames, not bank frames.
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags")
local addon = E:GetModule("BagCustomizer")
-- Create element namespace
addon.elements = addon.elements or {}
addon.elements.miscBorders = {}
local MiscBorders = addon.elements.miscBorders
-- Core state management
MiscBorders.backdropCache = {}
MiscBorders.containerBorderApplied = false
MiscBorders.containerOverlay = nil
MiscBorders.updateLock = false
-- Simplified debug function
local function debug(msg)
	-- Defensive check
	if not E.db then return end

	if not E.db.bagCustomizer then return end

	if not E.db.bagCustomizer.debug then return end

	local debugEnabled = (E.db.bagCustomizer.miscBorders and E.db.bagCustomizer.miscBorders.debug) or
			(E.db.bagCustomizer.borders and E.db.bagCustomizer.borders.debug)
	if not debugEnabled then return end

	print("|cFF00FF00Bag Customizer [" .. date("%H:%M:%S") .. "][MiscBorders]:|r " .. tostring(msg))
end

-- Helper functions
function MiscBorders:IsTooltipFrame(frame)
	if not frame then return false end

	-- Direct reference check for GameTooltip
	if frame == GameTooltip then return true end

	local name = frame:GetName() or ""
	if name:find("Tooltip") or name:find("tooltip") then return true end

	if frame.GetObjectType and frame:GetObjectType() == "GameTooltip" then return true end

	if frame.SetTooltipBackdropStyle or frame.GetTooltipData then return true end

	return false
end

-- Check if a frame is a bank-related frame
function MiscBorders:IsBankFrame(frame)
	-- Use addon's IsBankFrame function if available
	if addon.IsBankFrame then
		return addon:IsBankFrame(frame)
	end

	if not frame then return false end

	-- Basic name check as fallback
	local name = frame:GetName() or ""
	if name:find("Bank") or name:find("Warband") or name:find("Reagent") then return true end

	-- Check if it's ElvUI's bank frame
	if B.BankFrame and frame == B.BankFrame then return true end

	-- Check parent
	local parent = frame:GetParent()
	if parent then
		return self:IsBankFrame(parent)
	end

	return false
end

function MiscBorders:ShouldUseContainerBorder()
	if not E.db then return false end

	if not E.db.bagCustomizer then return false end

	local db = E.db.bagCustomizer
	return db and
			db.enabled and
			db.borders and
			db.borders.enable and
			db.frameHeight and
			db.frameHeight.enable
end

local function isValidFrame(frame, frameType)
	if not frame or type(frame) ~= "table" or not frame.GetObjectType then return false end

	local success, objectType = pcall(frame.GetObjectType, frame)
	return success and (not frameType or objectType == frameType)
end

-- Core border functionality
function MiscBorders:UpdateBorderTexturePaths()
	debug("Border texture paths loaded from settings")
end

-- Revert to the original method for hiding ElvUI borders
function MiscBorders:HandleDefaultBorders(frame, hide)
	if not frame or self:IsBankFrame(frame) then
		debug("HandleDefaultBorders: No valid frame provided or bank frame detected")
		return
	end

	-- Set the alpha value based on whether we want to hide or show
	local borderAlpha = hide and 0 or 1
	debug("Handling default borders for " .. (frame:GetName() or "unnamed") .. ", hide=" .. tostring(hide))
	-- Direct operation on backdrop if it exists (more reliable)
	if frame.backdrop then
		if frame.backdrop.SetBackdropBorderColor then
			local r, g, b = unpack(E.media.bordercolor)
			frame.backdrop:SetBackdropBorderColor(r, g, b, borderAlpha)
			debug("Applied border color with alpha " .. borderAlpha)
		end
	end

	-- Process frame borders
	for i = 1, select("#", frame:GetRegions()) do
		local region = select(i, frame:GetRegions())
		if region and region:IsObjectType("Texture") then
			local drawLayer = region:GetDrawLayer()
			if drawLayer == "BORDER" then
				local r, g, b = region:GetVertexColor()
				region:SetVertexColor(r, g, b, borderAlpha)
			end
		end
	end

	-- Also check the backdrop regions
	if frame.backdrop then
		for i = 1, select("#", frame.backdrop:GetRegions()) do
			local region = select(i, frame.backdrop:GetRegions())
			if region and region:IsObjectType("Texture") then
				local drawLayer = region:GetDrawLayer()
				if drawLayer == "BORDER" then
					local r, g, b = region:GetVertexColor()
					region:SetVertexColor(r, g, b, borderAlpha)
				end
			end
		end
	end

	-- Force a frame update to make changes visible immediately
	frame:SetAlpha(0.99)
	C_Timer.After(0.01, function()
		frame:SetAlpha(1)
	end)
end

function MiscBorders:GetBackdropForStyle(style, settings)
	if not settings then settings = {} end

	local size = settings.size or 12
	local cacheKey = style .. "_" .. size
	-- Return cached backdrop if available
	if self.backdropCache[cacheKey] then return self.backdropCache[cacheKey] end

	-- Validate style
	if not addon.borderTextures or not addon.borderTextures[style] then
		debug("Invalid border style: " .. (style or "nil") .. ", defaulting to tooltip")
		style = "tooltip"
		cacheKey = style .. "_" .. size
		if self.backdropCache[cacheKey] then return self.backdropCache[cacheKey] end
	end

	-- Create base backdrop
	local backdrop = {
		edgeFile = addon.borderTextures[style],
		edgeSize = size,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	}
	-- Apply style-specific adjustments
	local styleAdjustments = {
		achievement = { edgeSizeMult = 1.3, insets = 5 },
		gold = { edgeSizeMult = 1.4, insets = 5 },
		parchment = { edgeSizeMult = 1.2, insets = 5 },
		wowui = { edgeSizeMult = 1.5, insets = 5 },
		thin = { isSpecial = true },
	}
	local adjustment = styleAdjustments[style]
	if adjustment then
		if adjustment.isSpecial then return nil end

		if adjustment.edgeSizeMult then
			backdrop.edgeSize = size * adjustment.edgeSizeMult
		end

		if adjustment.insets then
			local insetValue = adjustment.insets
			backdrop.insets = {
				left = insetValue,
				right = insetValue,
				top = insetValue,
				bottom = insetValue,
			}
		end
	end

	-- Cache and return
	self.backdropCache[cacheKey] = backdrop
	return backdrop
end

function MiscBorders:ApplyThinBorder(frame, settings)
	if not frame or not frame._BCZ_borderOverlay then return end

	-- Hide existing backdrop
	if frame._BCZ_borderOverlay.SetBackdrop then
		frame._BCZ_borderOverlay:SetBackdrop(nil)
	end

	-- Set up colors
	local r, g, b = 1, 1, 1
	if settings and settings.color then
		r = settings.color.r or 1
		g = settings.color.g or 1
		b = settings.color.b or 1
	elseif E.db and E.db.bagCustomizer and E.db.bagCustomizer.borders and E.db.bagCustomizer.borders.color then
		r = E.db.bagCustomizer.borders.color.r or 1
		g = E.db.bagCustomizer.borders.color.g or 1
		b = E.db.bagCustomizer.borders.color.b or 1
	end

	local a = 1
	local thickness = 1
	if settings and settings.size then
		thickness = math.max(1, settings.size * 0.3)
	end

	-- Create textures if needed
	if not frame._BCZ_borderOverlay._BCZ_thinBorders then
		frame._BCZ_borderOverlay._BCZ_thinBorders = {}
		local sides = { "TOP", "BOTTOM", "LEFT", "RIGHT" }
		for _, side in ipairs(sides) do
			if addon.GetPooledTexture then
				frame._BCZ_borderOverlay._BCZ_thinBorders[side] = addon:GetPooledTexture(
					frame._BCZ_borderOverlay, "OVERLAY", 7)
			else
				frame._BCZ_borderOverlay._BCZ_thinBorders[side] =
						frame._BCZ_borderOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
			end
		end
	end

	-- Position and show textures
	for side, tex in pairs(frame._BCZ_borderOverlay._BCZ_thinBorders) do
		tex:SetColorTexture(r, g, b, a)
		if side == "TOP" then
			tex:ClearAllPoints()
			tex:SetPoint("TOPLEFT", frame._BCZ_borderOverlay, "TOPLEFT", 0, 0)
			tex:SetPoint("TOPRIGHT", frame._BCZ_borderOverlay, "TOPRIGHT", 0, 0)
			tex:SetHeight(thickness)
		elseif side == "BOTTOM" then
			tex:ClearAllPoints()
			tex:SetPoint("BOTTOMLEFT", frame._BCZ_borderOverlay, "BOTTOMLEFT", 0, 0)
			tex:SetPoint("BOTTOMRIGHT", frame._BCZ_borderOverlay, "BOTTOMRIGHT", 0, 0)
			tex:SetHeight(thickness)
		elseif side == "LEFT" then
			tex:ClearAllPoints()
			tex:SetPoint("TOPLEFT", frame._BCZ_borderOverlay, "TOPLEFT", 0, -thickness)
			tex:SetPoint("BOTTOMLEFT", frame._BCZ_borderOverlay, "BOTTOMLEFT", 0, thickness)
			tex:SetWidth(thickness)
		elseif side == "RIGHT" then
			tex:ClearAllPoints()
			tex:SetPoint("TOPRIGHT", frame._BCZ_borderOverlay, "TOPRIGHT", 0, -thickness)
			tex:SetPoint("BOTTOMRIGHT", frame._BCZ_borderOverlay, "BOTTOMRIGHT", 0, thickness)
			tex:SetWidth(thickness)
		end

		tex:Show()
	end

	debug("Applied thin border")
end

function MiscBorders:ApplyBackdropBorder(frame, borderStyle, settings)
	if not frame or not frame._BCZ_borderOverlay then return end

	-- Hide any thin borders
	if frame._BCZ_borderOverlay._BCZ_thinBorders then
		for _, tex in pairs(frame._BCZ_borderOverlay._BCZ_thinBorders) do
			tex:Hide()
		end
	end

	-- Get and apply backdrop
	local backdrop = self:GetBackdropForStyle(borderStyle, settings)
	if not backdrop then return end

	if frame._BCZ_borderOverlay.SetBackdrop then
		frame._BCZ_borderOverlay:SetBackdrop(backdrop)
		frame._BCZ_borderOverlay:SetBackdropColor(0, 0, 0, 0) -- Transparent background
		-- Set border color
		local r, g, b = 1, 1, 1
		if settings and settings.color then
			r = settings.color.r or 1
			g = settings.color.g or 1
			b = settings.color.b or 1
		elseif E.db and E.db.bagCustomizer and E.db.bagCustomizer.borders and E.db.bagCustomizer.borders.color then
			r = E.db.bagCustomizer.borders.color.r or 1
			g = E.db.bagCustomizer.borders.color.g or 1
			b = E.db.bagCustomizer.borders.color.b or 1
		end

		local a = 1
		-- Use custom color for certain styles
		if borderStyle == "wowui" and (r == 1 and g == 1 and b == 1) then
			r, g, b = 1, 1, 1 -- Pure white
		end

		if frame._BCZ_borderOverlay.SetBackdropBorderColor then
			frame._BCZ_borderOverlay:SetBackdropBorderColor(r, g, b, a)
		end

		-- Clean up scripts and masks
		frame._BCZ_borderOverlay:SetScript("OnUpdate", nil)
		if frame._BCZ_borderOverlay._BCZ_topBorderMask then
			frame._BCZ_borderOverlay._BCZ_topBorderMask:Hide()
		end

		if frame._BCZ_borderOverlay._BCZ_bottomBorderMask then
			frame._BCZ_borderOverlay._BCZ_bottomBorderMask:Hide()
		end

		debug("Applied " .. borderStyle .. " border")
	elseif Backdrop and Backdrop.ApplyBackdrop then
		Backdrop.ApplyBackdrop(frame._BCZ_borderOverlay, backdrop)
		debug("Applied " .. borderStyle .. " border via Backdrop.ApplyBackdrop")
	else
		debug("Failed to apply border - no backdrop method available")
	end
end

function MiscBorders:GetSearchBox(frame)
	if not isValidFrame(frame) or self:IsBankFrame(frame) then return nil end

	-- Direct property access
	if frame.SearchBox and isValidFrame(frame.SearchBox, "EditBox") then
		return frame.SearchBox
	end

	if frame.editBox and isValidFrame(frame.editBox, "EditBox") then
		return frame.editBox
	end

	-- Look for EditBox among children
	for i = 1, frame:GetNumChildren() do
		local child = select(i, frame:GetChildren())
		if child and child:IsObjectType("EditBox") then
			return child
		end
	end

	return nil
end

function MiscBorders:IsAnyBagVisible()
	-- Check only main bag frame, not bank
	if B.BagFrame and B.BagFrame:IsShown() then
		return true
	end

	-- Check alternative frame names
	local frameNames = { "ElvUI_ContainerFrame", "ElvUIBags", "ElvUI_BagFrame" }
	for _, name in ipairs(frameNames) do
		local frame = _G[name]
		if frame and frame:IsShown() and not self:IsBankFrame(frame) then
			return true
		end
	end

	return false
end

-- Core border application functions
function MiscBorders:ApplyBorder(frame, elementType)
	if not frame or self:IsBankFrame(frame) then
		debug("ApplyBorder: No valid frame provided or bank frame detected")
		return
	end

	-- Skip tooltips and extension panels
	if self:IsTooltipFrame(frame) then
		debug("Skipping border application to tooltip frame")
		return
	end

	if frame._BCZ_isExtensionPanel then
		debug("Never applying border to extension panel directly")
		if frame._BCZ_borderOverlay then frame._BCZ_borderOverlay:Hide() end

		return
	end

	-- Skip main frame if container border should be used
	if self:ShouldUseContainerBorder() and elementType == "mainFrame" then
		if frame._BCZ_borderOverlay then
			frame._BCZ_borderOverlay:Hide()
			debug("Hiding " .. elementType .. " border due to container border being used")
		end

		return
	end

	-- Check if borders enabled and this element should have one
	if not E.db or not E.db.bagCustomizer or not E.db.bagCustomizer.borders or not E.db.bagCustomizer.borders.enable then
		if frame._BCZ_borderOverlay then frame._BCZ_borderOverlay:Hide() end

		return
	end

	local borderSettings = E.db.bagCustomizer.borders
	-- Initialize elements table if needed
	if not borderSettings.elements then
		borderSettings.elements = {
			mainFrame = true,
			searchBar = true,
			vendorGrays = true,
			toggleBars = true,
			cleanup = true,
			stack = true,
			minimap = false,
			frameHeight = true,
		}
	end

	-- Skip if this element shouldn't have a border
	if not borderSettings.elements[elementType] then
		if frame._BCZ_borderOverlay then frame._BCZ_borderOverlay:Hide() end

		return
	end

	debug("Applying border to " .. elementType .. ": " .. (frame:GetName() or "unnamed"))
	-- Initialize element-specific settings
	local defaultSettings = {
		size = 12,
		inset = 0,
		style = borderSettings.style or "tooltip",
		color = CopyTable(borderSettings.color or { r = 1, g = 1, b = 1 }),
		alpha = 1,
	}
	if not borderSettings.mainFrame then borderSettings.mainFrame = CopyTable(defaultSettings) end

	if not borderSettings.searchBar then
		borderSettings.searchBar = CopyTable(defaultSettings)
		borderSettings.searchBar.size = 10
	end

	if not borderSettings.buttons then
		borderSettings.buttons = CopyTable(defaultSettings)
		borderSettings.buttons.size = 8
	end

	if not borderSettings.minimap then borderSettings.minimap = CopyTable(defaultSettings) end

	-- Get element-specific settings
	local elementSettings
	if elementType == "mainFrame" then
		elementSettings = borderSettings.mainFrame
	elseif elementType == "searchBar" then
		elementSettings = borderSettings.searchBar
	elseif elementType == "minimap" then
		elementSettings = borderSettings.minimap
	else
		elementSettings = borderSettings.buttons
	end

	-- Ensure settings are complete
	if not elementSettings then
		elementSettings = CopyTable(defaultSettings)
	end

	if not elementSettings.inset then elementSettings.inset = 0 end

	if not elementSettings.color then
		elementSettings.color = CopyTable(borderSettings.color or { r = 1, g = 1, b = 1 })
	end

	-- Create border overlay if needed
	if not frame._BCZ_borderOverlay then
		if BackdropTemplateMixin then
			frame._BCZ_borderOverlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
		else
			frame._BCZ_borderOverlay = CreateFrame("Frame", nil, frame)
		end

		frame._BCZ_borderOverlay:SetFrameLevel(frame:GetFrameLevel() + 5)
		debug("Created new border overlay for " .. elementType)
	end

	-- Position the overlay
	frame._BCZ_borderOverlay:ClearAllPoints()
	frame._BCZ_borderOverlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -elementSettings.inset, elementSettings.inset)
	frame._BCZ_borderOverlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", elementSettings.inset, -elementSettings.inset)
	-- Apply border
	local borderStyle = elementSettings.style or "tooltip"
	if borderStyle == "thin" then
		self:ApplyThinBorder(frame, elementSettings)
	else
		self:ApplyBackdropBorder(frame, borderStyle, elementSettings)
	end

	frame._BCZ_borderOverlay:Show()
end

function MiscBorders:ApplyBorderToContainer()
	local containerOverlay = self.containerOverlay
	-- Validate container overlay
	if not containerOverlay then
		debug("No container overlay available")
		if addon.TriggerEvent then
			addon:TriggerEvent("REQUEST_CONTAINER_OVERLAY")
		end

		return
	end

	-- Skip if not visible
	if not containerOverlay:IsShown() then
		debug("Container overlay not shown, skipping border application")
		return
	end

	-- Skip if already applied
	if self.containerBorderApplied and containerOverlay._BCZ_borderApplied then
		return
	end

	debug("Applying border to container overlay")
	-- Hide individual borders
	self:HideIndividualFrameBorders()
	-- Verify settings
	if not self:ShouldUseContainerBorder() then
		debug("Container border should not be used based on settings")
		return
	end

	-- Check border settings
	if not E.db or not E.db.bagCustomizer or not E.db.bagCustomizer.borders or not E.db.bagCustomizer.borders.mainFrame then
		debug("No border settings for main frame")
		return
	end

	local borderSettings = E.db.bagCustomizer.borders
	-- Skip if disabled
	if borderSettings.elements and borderSettings.elements.mainFrame == false then
		debug("Container border not shown because mainFrame borders are disabled")
		if containerOverlay._BCZ_borderOverlay then
			containerOverlay._BCZ_borderOverlay:Hide()
		end

		return
	end

	local settings = borderSettings.mainFrame
	-- Create overlay if needed
	if not containerOverlay._BCZ_borderOverlay then
		if BackdropTemplateMixin then
			containerOverlay._BCZ_borderOverlay = CreateFrame("Frame", nil, containerOverlay, "BackdropTemplate")
		else
			containerOverlay._BCZ_borderOverlay = CreateFrame("Frame", nil, containerOverlay)
		end

		containerOverlay._BCZ_borderOverlay:SetFrameLevel(containerOverlay:GetFrameLevel() + 5)
		debug("Created new border overlay for container")
	end

	-- Position overlay
	containerOverlay._BCZ_borderOverlay:ClearAllPoints()
	containerOverlay._BCZ_borderOverlay:SetPoint("TOPLEFT", containerOverlay, "TOPLEFT", -settings.inset, settings.inset)
	containerOverlay._BCZ_borderOverlay:SetPoint("BOTTOMRIGHT", containerOverlay, "BOTTOMRIGHT", settings.inset,
		-settings.inset)
	-- Apply border style
	local borderStyle = settings.style or "tooltip"
	if borderStyle == "thin" then
		self:ApplyThinBorder(containerOverlay, settings)
		debug("Applied thin border to container")
	else
		local backdrop = self:GetBackdropForStyle(borderStyle, settings)
		if backdrop and containerOverlay._BCZ_borderOverlay.SetBackdrop then
			containerOverlay._BCZ_borderOverlay:SetBackdrop(backdrop)
			containerOverlay._BCZ_borderOverlay:SetBackdropColor(0, 0, 0, 0) -- Transparent background
			-- Set border color
			local r = settings.color and settings.color.r or (borderSettings.color and borderSettings.color.r) or 1
			local g = settings.color and settings.color.g or (borderSettings.color and borderSettings.color.g) or 1
			local b = settings.color and settings.color.b or (borderSettings.color and borderSettings.color.b) or 1
			local a = 1
			if containerOverlay._BCZ_borderOverlay.SetBackdropBorderColor then
				containerOverlay._BCZ_borderOverlay:SetBackdropBorderColor(r, g, b, a)
				debug("Set container backdrop border color: " .. r .. ", " .. g .. ", " .. b)
			end
		end

		debug("Applied " .. borderStyle .. " border to container")
	end

	containerOverlay._BCZ_borderOverlay:Show()
	debug("Border overlay shown for container")
	-- Mark as applied
	containerOverlay._BCZ_borderApplied = true
	self.containerBorderApplied = true
	-- Notify
	if addon.TriggerEvent then
		addon:TriggerEvent("BORDERS_APPLIED_TO_CONTAINER", containerOverlay)
	end
end

function MiscBorders:HideIndividualFrameBorders()
	local bagFrame = B.BagFrame
	if not bagFrame then return end

	if bagFrame._BCZ_borderOverlay then
		bagFrame._BCZ_borderOverlay:Hide()
		debug("Hidden main frame border")
	end
end

-- Applying borders with anti-loop protection
function MiscBorders:ApplyBordersToAllElements()
	-- Add global protection against too-frequent updates
	self.lastBorderUpdate = self.lastBorderUpdate or 0
	local now = GetTime()
	if now - self.lastBorderUpdate < 0.1 then
		return
	end

	self.lastBorderUpdate = now
	-- Skip if addon is disabled
	if not E.db or not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then
		self:RevertAllBorders()
		return
	end

	-- Skip if borders are disabled
	local bordersEnabled = E.db.bagCustomizer and E.db.bagCustomizer.borders and E.db.bagCustomizer.borders.enable == true
	if not bordersEnabled then
		self:RevertAllBorders()
		return
	end

	-- Apply only to regular bag frame, not bank
	local containerFrame = B.BagFrame
	if not containerFrame or self:IsBankFrame(containerFrame) then
		debug("No valid container frame found or bank frame detected")
		return
	end

	-- Apply default border handling first for all cases
	self:HandleDefaultBorders(containerFrame, E.db.bagCustomizer.hideDefaultBorders)
	-- Apply container overlay border if applicable
	if self:ShouldUseContainerBorder() then
		self:HideIndividualFrameBorders()
		-- Prevent recursion
		local lastBorderApplied = self.containerBorderApplied
		self:ApplyBorderToContainer()
		-- If container overlay border applied or was applied before, only handle buttons and search box
		if self.containerBorderApplied or lastBorderApplied then
			local searchBox = self:GetSearchBox(containerFrame)
			if searchBox then
				self:ApplyBorder(searchBox, "searchBar")
			end

			-- Apply to buttons
			local buttons = {
				{ frame = containerFrame.vendorGraysButton, type = "vendorGrays" },
				{ frame = containerFrame.bagsButton, type = "toggleBars" },
				{ frame = containerFrame.sortButton, type = "cleanup" },
				{ frame = containerFrame.stackButton, type = "stack" },
			}
			for _, button in ipairs(buttons) do
				if button.frame and not self:IsBankFrame(button.frame) then
					self:ApplyBorder(button.frame, button.type)
				end
			end

			return
		end
	end

	-- Fallback: Apply individual borders
	debug("Applying individual borders (container border not being used)")
	-- Apply main frame border
	self:ApplyBorder(containerFrame, "mainFrame")
	-- Apply search bar border
	local searchBox = self:GetSearchBox(containerFrame)
	if searchBox then
		self:ApplyBorder(searchBox, "searchBar")
	end

	-- Apply button borders
	local buttons = {
		{ frame = containerFrame.vendorGraysButton, type = "vendorGrays" },
		{ frame = containerFrame.bagsButton, type = "toggleBars" },
		{ frame = containerFrame.sortButton, type = "cleanup" },
		{ frame = containerFrame.stackButton, type = "stack" },
	}
	for _, button in ipairs(buttons) do
		if button.frame and not self:IsBankFrame(button.frame) then
			self:ApplyBorder(button.frame, button.type)
		end
	end

	-- Gentle frame update
	containerFrame:SetAlpha(0.99)
	C_Timer.After(0.1, function() containerFrame:SetAlpha(1) end)
	-- Trigger event
	if addon.TriggerEvent then
		addon:TriggerEvent("BORDERS_APPLIED_TO_ELEMENTS")
	end
end

function MiscBorders:RevertAllBorders()
	debug("Reverting all borders")
	-- Reset state
	self.containerBorderApplied = false
	-- Hide container overlay border
	if self.containerOverlay and self.containerOverlay._BCZ_borderOverlay then
		self.containerOverlay._BCZ_borderOverlay:Hide()
		self.containerOverlay._BCZ_borderApplied = nil
	end

	-- Handle regular bag frame only
	local containerFrame = B.BagFrame
	if containerFrame and not self:IsBankFrame(containerFrame) then
		-- Restore default borders
		self:HandleDefaultBorders(containerFrame, false)
		-- Hide custom borders
		if containerFrame._BCZ_borderOverlay then
			containerFrame._BCZ_borderOverlay:Hide()
		end

		-- Hide search bar border
		local searchBox = self:GetSearchBox(containerFrame)
		if searchBox and searchBox._BCZ_borderOverlay then
			searchBox._BCZ_borderOverlay:Hide()
		end

		-- Hide button borders
		local buttons = {
			containerFrame.vendorGraysButton,
			containerFrame.bagsButton,
			containerFrame.sortButton,
			containerFrame.stackButton,
		}
		for _, button in ipairs(buttons) do
			if button and button._BCZ_borderOverlay then
				button._BCZ_borderOverlay:Hide()
			end
		end
	end

	-- Hide minimap border
	local minimap = _G["Minimap"]
	if minimap and minimap._BCZ_borderOverlay then
		minimap._BCZ_borderOverlay:Hide()
	end

	-- Trigger event
	if addon.TriggerEvent then
		addon:TriggerEvent("BORDERS_REMOVED")
	end
end

function MiscBorders:ForceRedraw()
	if self.updateLock then
		debug("ForceRedraw: Skipped - already updating")
		return
	end

	debug("ForceRedraw: Forcing immediate update")
	self.updateLock = true
	self.backdropCache = {}
	self.containerBorderApplied = false
	-- First, explicitly handle default borders for main frame
	local containerFrame = B.BagFrame
	if containerFrame and containerFrame:IsShown() and not self:IsBankFrame(containerFrame) then
		self:HandleDefaultBorders(containerFrame, E.db.bagCustomizer and E.db.bagCustomizer.hideDefaultBorders)
	end

	-- Then apply all borders
	self:ApplyBordersToAllElements()
	-- Secondary refresh after a short delay
	C_Timer.After(0.1, function()
		-- Re-handle default borders to ensure they're applied properly
		if containerFrame and containerFrame:IsShown() and not self:IsBankFrame(containerFrame) then
			self:HandleDefaultBorders(containerFrame, E.db.bagCustomizer and E.db.bagCustomizer.hideDefaultBorders)
		end

		-- Unlock after another delay
		C_Timer.After(0.1, function() self.updateLock = false end)
	end)
end

function MiscBorders:ClearCache()
	debug("Border cache cleared")
	-- Reset cache and state
	self.backdropCache = {}
	self.containerBorderApplied = false
	-- Release frame borders
	local function releaseFrameBorders(frame)
		if not frame or self:IsBankFrame(frame) then return end

		if frame._BCZ_borderOverlay then
			-- Release thin border textures
			if frame._BCZ_borderOverlay._BCZ_thinBorders then
				for _, tex in pairs(frame._BCZ_borderOverlay._BCZ_thinBorders) do
					if addon.ReleaseTexture then
						addon:ReleaseTexture(tex)
					else
						tex:SetTexture(nil)
						tex:Hide()
					end
				end

				frame._BCZ_borderOverlay._BCZ_thinBorders = nil
			end

			-- Clean up overlay
			frame._BCZ_borderOverlay:Hide()
			frame._BCZ_borderOverlay = nil
		end
	end

	-- Release container overlay border
	if self.containerOverlay and self.containerOverlay._BCZ_borderOverlay then
		if self.containerOverlay._BCZ_borderOverlay._BCZ_thinBorders then
			for _, tex in pairs(self.containerOverlay._BCZ_borderOverlay._BCZ_thinBorders) do
				if addon.ReleaseTexture then
					addon:ReleaseTexture(tex)
				else
					tex:SetTexture(nil)
					tex:Hide()
				end
			end

			self.containerOverlay._BCZ_borderOverlay._BCZ_thinBorders = nil
		end

		self.containerOverlay._BCZ_borderOverlay:Hide()
		self.containerOverlay._BCZ_borderOverlay = nil
		self.containerOverlay._BCZ_borderApplied = nil
	end

	-- Clean up regular bag frame only
	if B.BagFrame and not self:IsBankFrame(B.BagFrame) then
		releaseFrameBorders(B.BagFrame)
	end

	-- Clean up minimap
	local minimap = _G["Minimap"]
	if minimap and minimap._BCZ_borderOverlay then
		minimap._BCZ_borderOverlay:Hide()
		minimap._BCZ_borderOverlay = nil
	end

	-- Force update
	C_Timer.After(0.1, function()
		if addon and addon.FullUpdate then
			addon:FullUpdate()
		end
	end)
	-- Trigger event
	if addon.TriggerEvent then
		addon:TriggerEvent("BORDER_CACHE_CLEARED")
	end
end

-- Event and options handling
function MiscBorders:SetupOptionHandlers()
	if E.Options and E.Options.args and E.Options.args.bagCustomizer and
			E.Options.args.bagCustomizer.args and E.Options.args.bagCustomizer.args.borders then
		-- Hook hideDefaultBorders setting
		if E.Options.args.bagCustomizer.args.borders.args and
				E.Options.args.bagCustomizer.args.borders.args.hideDefaultBorders then
			-- Store original setter if not already stored
			if not E.Options.args.bagCustomizer.args.borders.args.hideDefaultBorders.originalSet then
				E.Options.args.bagCustomizer.args.borders.args.hideDefaultBorders.originalSet =
						E.Options.args.bagCustomizer.args.borders.args.hideDefaultBorders.set
			end

			-- Override the setter
			E.Options.args.bagCustomizer.args.borders.args.hideDefaultBorders.set =
					function(info, value)
						debug("hideDefaultBorders setting changed to: " .. tostring(value))
						-- Call original setter
						if info.originalSet then
							info.originalSet(info, value)
						else
							if E.db and E.db.bagCustomizer then
								E.db.bagCustomizer.hideDefaultBorders = value
							end
						end

						-- Ensure setting is saved
						if E.db and E.db.bagCustomizer then
							E.db.bagCustomizer.hideDefaultBorders = value
						end

						-- Apply changes immediately to visible frames
						local containerFrame = B.BagFrame
						if containerFrame and containerFrame:IsShown() and not self:IsBankFrame(containerFrame) then
							self:HandleDefaultBorders(containerFrame, value)
						end

						-- Reset state flags and force complete redraw
						self.containerBorderApplied = false
						self.backdropCache = {}
						-- Delayed redraw to ensure setting takes effect
						C_Timer.After(0.1, function()
							self:ForceRedraw()
							-- Additional refresh for bags
							if containerFrame then
								containerFrame:SetAlpha(0.99)
								C_Timer.After(0.1, function() containerFrame:SetAlpha(1) end)
							end
						end)
					end
			debug("Replaced hideDefaultBorders option handler")
		end
	end
end

-- Prevent container update loop
function MiscBorders:SetupContainerEvents()
	if addon.RegisterForEvent then
		-- Add update cooldown tracking
		self.lastContainerUpdate = 0
		-- Container overlay created
		addon:RegisterForEvent("CONTAINER_OVERLAY_CREATED", function(overlay)
			debug("Container overlay created event received")
			-- Apply cooldown to prevent spam
			local now = GetTime()
			if now - self.lastContainerUpdate < 0.5 then
				debug("Skipping update due to cooldown")
				return
			end

			self.lastContainerUpdate = now
			self.containerOverlay = overlay
			if not self.updateLock and self:ShouldUseContainerBorder() and
					B.BagFrame and B.BagFrame:IsShown() and not self:IsBankFrame(B.BagFrame) then
				self.containerBorderApplied = false
				-- Handle default borders immediately
				if B.BagFrame then
					self:HandleDefaultBorders(B.BagFrame, E.db.bagCustomizer and E.db.bagCustomizer.hideDefaultBorders)
				end

				self:ApplyBorderToContainer()
			end
		end)
		-- Container overlay updated - with anti-loop protection
		addon:RegisterForEvent("CONTAINER_OVERLAY_UPDATED", function(overlay)
			debug("Container overlay updated event received")
			-- Apply cooldown to prevent spam
			local now = GetTime()
			if now - self.lastContainerUpdate < 0.5 then
				debug("Skipping update due to cooldown")
				return
			end

			self.lastContainerUpdate = now
			self.containerOverlay = overlay
			self.containerBorderApplied = false
			if not self.updateLock and self:ShouldUseContainerBorder() and
					B.BagFrame and B.BagFrame:IsShown() and not self:IsBankFrame(B.BagFrame) then
				-- Handle default borders immediately
				if B.BagFrame then
					self:HandleDefaultBorders(B.BagFrame, E.db.bagCustomizer and E.db.bagCustomizer.hideDefaultBorders)
				end

				-- Delayed border application to prevent cascading updates
				C_Timer.After(0.1, function()
					if self.containerOverlay and self.containerOverlay:IsShown() then
						self:ApplyBorderToContainer()
					end
				end)
			end
		end)
		-- Request container overlay
		addon:RegisterForEvent("REQUEST_CONTAINER_OVERLAY", function()
			-- Apply cooldown to prevent spam
			local now = GetTime()
			if now - self.lastContainerUpdate < 0.5 then
				debug("Skipping request due to cooldown")
				return
			end

			C_Timer.After(0.05, function()
				if not self.containerOverlay then
					if addon.containerOverlay then
						self.containerOverlay = addon.containerOverlay
						debug("Found container overlay from addon environment")
					end

					if addon.TriggerEvent then
						addon:TriggerEvent("CREATE_CONTAINER_OVERLAY")
					end

					-- Longer delay to prevent update cascade
					C_Timer.After(0.3, function()
						if self.containerOverlay then
							self:ApplyBorderToContainer()
						end
					end)
				end
			end)
		end)
	end
end

-- Module initialization
function MiscBorders:Initialize()
	-- Defensive checks at initialization
	if not E or not E.db then
		C_Timer.After(1, function() self:Initialize() end)
		return
	end

	-- Ensure the bagCustomizer table exists
	if not E.db.bagCustomizer then
		E.db.bagCustomizer = {}
	end

	-- Initialize settings
	if not E.db.bagCustomizer.miscBorders then
		E.db.bagCustomizer.miscBorders = {}
	end

	if E.db.bagCustomizer.miscBorders.debug == nil then
		E.db.bagCustomizer.miscBorders.debug = false
	end

	debug("Initializing MiscBorders module")
	-- Initialize textures and cache
	self:UpdateBorderTexturePaths()
	self:ClearCache()
	-- Set up option handlers and events
	self:SetupOptionHandlers()
	self:SetupContainerEvents()
	-- Register for events from other modules
	-- NOTE: Removed duplicate event registrations for CONTAINER_OVERLAY_CREATED and CONTAINER_OVERLAY_UPDATED
	-- Create update frame
	self.updateFrame = CreateFrame("Frame")
	self.updateFrame:SetScript("OnUpdate", function(_, elapsed)
		-- Only check every 2 seconds
		self.updateFrame.timeSinceLastCheck = (self.updateFrame.timeSinceLastCheck or 0) + elapsed
		if self.updateFrame.timeSinceLastCheck < 2 then return end

		self.updateFrame.timeSinceLastCheck = 0
		-- Skip if bags not visible or in combat
		if not self:IsAnyBagVisible() or InCombatLockdown() then
			if self.containerOverlay and self.containerOverlay:IsShown() then
				self.containerOverlay:Hide()
			end

			return
		end

		-- Apply borders only to non-bank frames
		self.containerBorderApplied = false
		self:ApplyBordersToAllElements()
	end)
	-- Hook into module toggle
	if addon.ToggleModule then
		hooksecurefunc(addon, "ToggleModule", function()
			C_Timer.After(0.2, function()
				debug("Module toggle detected")
				self.containerBorderApplied = false
				if E.db and E.db.bagCustomizer and E.db.bagCustomizer.enabled then
					if E.db.bagCustomizer.borders and E.db.bagCustomizer.borders.enable then
						debug("Module enabled and borders enabled, applying borders")
						self:ForceRedraw()
					end
				else
					debug("Module disabled, reverting borders")
					self:RevertAllBorders()
				end
			end)
		end)
	end

	-- Set up frame events
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("BAG_CLOSED")
	eventFrame:RegisterEvent("BAG_OPEN")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	eventFrame:SetScript("OnEvent", function(_, event)
		if event == "BAG_CLOSED" then
			if self.containerOverlay then
				self.containerOverlay:Hide()
				debug("Hiding container overlay due to BAG_CLOSED event")
			end

			-- ADDED: Force clean removal of any leftover borders
			C_Timer.After(0.1, function()
				self:RevertAllBorders()
			end)
		elseif event == "BAG_OPEN" or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_ENTERING_WORLD" then
			if self:IsAnyBagVisible() then
				C_Timer.After(0.1, function() self:ApplyBordersToAllElements() end)
			end
		end
	end)
	-- Register with addon's update system
	if addon.RegisterElementUpdate then
		addon:RegisterElementUpdate("MiscBorders", function() self:ApplyBordersToAllElements() end)
	end

	debug("MiscBorders module initialized")
	-- Trigger initialized event
	if addon.TriggerEvent then
		addon:TriggerEvent("MISCBORDERS_MODULE_INITIALIZED")
	end
end

-- Register with initialization
if addon.RegisterElement then
	addon:RegisterElement("MiscBorders")
else
	-- Fallback initialization
	MiscBorders:Initialize()
end

-- Return module
return MiscBorders
