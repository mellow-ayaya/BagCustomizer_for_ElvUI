-- Bag Customizer for ElvUI - InventoryBackgroundAdjust customization
--
-- This module handles the customization of bag frame backgrounds.
-- Features:
-- - Custom background colors and opacity
-- - Efficient texture caching to improve performance
-- - Proper cleanup when customizations are disabled
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags") -- Direct reference to Bags module
local addon = E:GetModule("BagCustomizer")
-- Create element namespace
addon.elements.inventoryBackgroundAdjust = {}
local InventoryBackgroundAdjust = addon.elements.inventoryBackgroundAdjust
-- Named constants for better code readability
local BACKDROP_LAYER = "BACKGROUND"
local BACKDROP_SUBLAYER = 1
local DEFAULT_ALPHA = function()
	return E.media and E.media.backdropfadecolor and E.media.backdropfadecolor[4] or 0.8
end
-- Simple debug function
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][inventoryBackgroundAdjust]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.inventoryBackgroundAdjust or
			not E.db.bagCustomizer.inventoryBackgroundAdjust.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- Simplified frame validation that doesn't rely on FrameFinder
local function isValidFrame(frame)
	return frame and type(frame) == "table" and frame.GetObjectType and frame:GetObjectType()
end

--[[
    ApplyBackdropStyle: Applies custom backdrop styling to a bag frame
    @param frame: The container frame to modify
    @return: nil
]]
function InventoryBackgroundAdjust:ApplyBackdropStyle(frame)
	-- Simple frame validation
	if not isValidFrame(frame) then
		debug("ApplyBackdropStyle: Invalid frame provided")
		return
	end

	-- Skip bank/warbank frames
	if addon:IsBankFrame(frame) then
		debug("ApplyBackdropStyle: Skipping bank frame")
		return
	end

	-- Track performance in debug mode
	local startTime
	if E.db.bagCustomizer and E.db.bagCustomizer.debug then
		startTime = debugprofilestop()
	end

	-- Validate settings exist
	if not E.db.bagCustomizer or not E.db.bagCustomizer.inventoryBackgroundAdjust then
		debug("ApplyBackdropStyle: Settings missing")
		return
	end

	-- Skip intensive processing during combat if bags aren't visible
	if InCombatLockdown() and not frame:IsVisible() then
		debug("ApplyBackdropStyle: Skipping during combat (bags not visible)")
		return
	end

	-- Cache specific Textures on first run for performance
	if not frame._BCZ_backdropCache then
		frame._BCZ_backdropCache = {}
		-- Find center texture (only once)
		if frame.backdrop then
			debug("Searching for center texture in backdrop")
			for i = 1, select("#", frame.backdrop:GetRegions()) do
				local region = select(i, frame.backdrop:GetRegions())
				if region and region:IsObjectType("Texture") then
					local drawLayer, subLayer = region:GetDrawLayer()
					if drawLayer == BACKDROP_LAYER and subLayer == BACKDROP_SUBLAYER then
						frame._BCZ_backdropCache.centerTexture = region
						debug("Found center texture in backdrop")
						-- Store original colors - capture from ElvUI's settings for accuracy
						local defColor = E.media.backdropfadecolor
						local r, g, b, a = defColor[1], defColor[2], defColor[3], defColor[4]
						-- Only capture the current texture color if it hasn't been modified yet
						if not frame._BCZ_colorModified then
							r, g, b, a = region:GetVertexColor()
						end

						frame._BCZ_backdropCache.originalColor = { r = r, g = g, b = b, a = a }
						debug("Stored original backdrop color: r=" .. r .. " g=" .. g .. " b=" .. b .. " a=" .. a)
						break
					end
				end
			end
		end

		-- Cache frame background Textures
		frame._BCZ_backdropCache.backgroundTextures = {}
		for i = 1, select("#", frame:GetRegions()) do
			local region = select(i, frame:GetRegions())
			if region and region:IsObjectType("Texture") and region:GetDrawLayer() == BACKDROP_LAYER then
				table.insert(frame._BCZ_backdropCache.backgroundTextures, region)
				debug("Cached a background texture from frame")
			end
		end
	end

	-- Check if the add-on is enabled
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then
		debug("Add-on disabled, restoring defaults")
		self:RevertBackdropStyle(frame)
		return
	end

	-- Check if background color is enabled
	if not E.db.bagCustomizer.inventoryBackgroundAdjust or not E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor then
		debug("Background color disabled, restoring defaults")
		-- If disabled, use default ElvUI colors
		self:RevertBackdropStyle(frame)
		return
	end

	-- Apply custom background color and opacity
	local color = E.db.bagCustomizer.inventoryBackgroundAdjust.color or { r = 0.1, g = 0.1, b = 0.1 }
	local opacity = E.db.bagCustomizer.inventoryBackgroundAdjust.opacity or 0.5
	debug("Applying color: r=" .. color.r .. " g=" .. color.g .. " b=" .. color.b .. " a=" .. opacity)
	-- Skip update if settings haven't changed (optimization)
	if frame._BCZ_backdropCache.lastAppliedColor then
		local lastColor = frame._BCZ_backdropCache.lastAppliedColor
		if lastColor.r == color.r and lastColor.g == color.g and
				lastColor.b == color.b and lastColor.a == opacity then
			debug("Skipping backdrop update - no change in settings")
			return
		end
	end

	-- Mark that we're modifying colors
	frame._BCZ_colorModified = true
	-- Apply directly to cached texture for best performance
	if frame._BCZ_backdropCache.centerTexture then
		frame._BCZ_backdropCache.centerTexture:SetVertexColor(color.r, color.g, color.b)
		frame._BCZ_backdropCache.centerTexture:SetAlpha(opacity)
		debug("Applied color to cached center texture")
	end

	if frame.backdrop then
		-- Apply to the backdrop's background center texture
		for i = 1, select("#", frame.backdrop:GetRegions()) do
			local region = select(i, frame.backdrop:GetRegions())
			if region and region:IsObjectType("Texture") then
				local drawLayer, subLayer = region:GetDrawLayer()
				-- Target the center texture of the backdrop
				if drawLayer == BACKDROP_LAYER and subLayer == BACKDROP_SUBLAYER then
					region:SetVertexColor(color.r, color.g, color.b)
					region:SetAlpha(opacity)
					debug("Applied color to backdrop region")
				end
			end
		end
	end

	-- Also process cached background Textures from the main frame
	if frame._BCZ_backdropCache.backgroundTextures then
		for _, region in ipairs(frame._BCZ_backdropCache.backgroundTextures) do
			region:SetVertexColor(color.r, color.g, color.b)
			region:SetAlpha(opacity)
		end

		debug("Applied color to " .. #frame._BCZ_backdropCache.backgroundTextures .. " cached background Textures")
	end

	-- Store the applied settings to avoid redundant updates
	frame._BCZ_backdropCache.lastAppliedColor = {
		r = color.r,
		g = color.g,
		b = color.b,
		a = opacity,
	}
	-- Notify other modules about color change
	if addon.TriggerEvent then
		addon:TriggerEvent("BACKGROUND_COLOR_CHANGED")
	end

	-- Log performance metrics in debug mode
	if startTime then
		debug(string.format("ApplyBackdropStyle took %.2f ms", debugprofilestop() - startTime))
	end
end

--[[
    RevertBackdropStyle: Reverts backdrop style to ElvUI defaults
    @param frame: The container frame to revert
    @return: nil
]]
function InventoryBackgroundAdjust:RevertBackdropStyle(frame)
	if not isValidFrame(frame) then
		debug("RevertBackdropStyle: Invalid frame provided")
		return
	end

	-- Skip bank/warbank frames
	if addon:IsBankFrame(frame) then
		debug("RevertBackdropStyle: Skipping bank frame")
		return
	end

	-- Reset to proper ElvUI defaults for bags (they use backdropfadecolor, not backdropcolor)
	local defaultColor = E.media.backdropfadecolor
	-- Now we can extract both color and alpha from the same source
	local defaultR, defaultG, defaultB, defaultAlpha = defaultColor[1], defaultColor[2], defaultColor[3], defaultColor[4]
	debug("Reverting backdrop style to defaults: r=" ..
		defaultR .. " g=" .. defaultG .. " b=" .. defaultB .. " a=" .. defaultAlpha)
	-- Use cached regions if available for better performance
	if frame._BCZ_backdropCache then
		-- Restore center texture if we cached it
		if frame._BCZ_backdropCache.centerTexture and frame._BCZ_backdropCache.originalColor then
			local originalColor = frame._BCZ_backdropCache.originalColor
			debug("Restoring original color: r=" ..
				originalColor.r .. " g=" .. originalColor.g .. " b=" .. originalColor.b .. " a=" .. originalColor.a)
			frame._BCZ_backdropCache.centerTexture:SetVertexColor(originalColor.r, originalColor.g, originalColor.b)
			frame._BCZ_backdropCache.centerTexture:SetAlpha(originalColor.a)
			debug("Restored original color to center texture")
		elseif frame._BCZ_backdropCache.centerTexture then
			-- Fallback to ElvUI defaults
			frame._BCZ_backdropCache.centerTexture:SetVertexColor(defaultR, defaultG, defaultB)
			frame._BCZ_backdropCache.centerTexture:SetAlpha(defaultAlpha)
			debug("Restored ElvUI default color to center texture")
		end

		-- Restore cached background Textures
		if frame._BCZ_backdropCache.backgroundTextures then
			for _, region in ipairs(frame._BCZ_backdropCache.backgroundTextures) do
				region:SetVertexColor(defaultR, defaultG, defaultB)
				region:SetAlpha(defaultAlpha)
			end

			debug("Restored default colors to " .. #frame._BCZ_backdropCache.backgroundTextures .. " background Textures")
		end

		-- Clear the last applied color cache
		frame._BCZ_backdropCache.lastAppliedColor = nil
		return
	end

	-- Fallback method if cache doesn't exist
	debug("Cache not found, using fallback revert method")
	if frame.backdrop then
		for i = 1, select("#", frame.backdrop:GetRegions()) do
			local region = select(i, frame.backdrop:GetRegions())
			if region and region:IsObjectType("Texture") then
				local drawLayer, subLayer = region:GetDrawLayer()
				if drawLayer == BACKDROP_LAYER and subLayer == BACKDROP_SUBLAYER then
					region:SetVertexColor(defaultR, defaultG, defaultB)
					region:SetAlpha(defaultAlpha)
				end
			end
		end
	end

	-- Reset the main frame background Textures
	for i = 1, select("#", frame:GetRegions()) do
		local region = select(i, frame:GetRegions())
		if region and region:IsObjectType("Texture") and region:GetDrawLayer() == BACKDROP_LAYER then
			region:SetVertexColor(defaultR, defaultG, defaultB)
			region:SetAlpha(defaultAlpha)
		end
	end
end

--[[
    UpdateAll: Updates all background settings for open frames
    @return: nil
]]
function InventoryBackgroundAdjust:UpdateAll()
	debug("Updating all backgrounds")
	-- Check if the add-on is enabled
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then
		debug("Add-on disabled, restoring defaults on all frames")
		self:RevertAll()
		return
	end

	-- Check if this specific module is enabled
	if not E.db.bagCustomizer.inventoryBackgroundAdjust or not E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor then
		debug("Module disabled, restoring defaults on all frames")
		self:RevertAll()
		return
	end

	-- Skip intensive processing during combat if bags aren't visible
	local B = E:GetModule("Bags")
	local containerFrame = B.BagFrame -- Direct reference to BagFrame
	if InCombatLockdown() and not (containerFrame and containerFrame:IsVisible()) then
		debug("UpdateAll: Skipping during combat (bags not visible)")
		return
	end

	-- Apply to container frame (directly) - skip bank frames
	if containerFrame and not addon:IsBankFrame(containerFrame) then
		self:ApplyBackdropStyle(containerFrame)
	end
end

--[[
    RevertAll: Reverts all frames to default
    @return: nil
]]
function InventoryBackgroundAdjust:RevertAll()
	debug("Reverting all backgrounds to default")
	-- Revert container frame (direct reference) - skip bank frames
	local B = E:GetModule("Bags")
	if B.BagFrame and not addon:IsBankFrame(B.BagFrame) then
		self:RevertBackdropStyle(B.BagFrame)
	end
end

--[[
    ClearCache: Clears backdrop cache (used when settings change)
    @return: nil
]]
function InventoryBackgroundAdjust:ClearCache()
	debug("Clearing backdrop cache")
	-- Clear container frame cache - skip bank frames
	local B = E:GetModule("Bags")
	if B.BagFrame and not addon:IsBankFrame(B.BagFrame) then
		-- More thoroughly clear the cache
		if B.BagFrame._BCZ_backdropCache then
			wipe(B.BagFrame._BCZ_backdropCache)
		end

		B.BagFrame._BCZ_backdropCache = nil
	end
end

--[[
    Cleanup: Performs cleanup when module is disabled
    @return: nil
]]
function InventoryBackgroundAdjust:Cleanup()
	debug("InventoryBackgroundAdjust module cleanup")
	self:RevertAll()
	self:ClearCache()
	-- Force ElvUI to update its bag display to ensure it applies its own styling
	local B = E:GetModule("Bags")
	if B and B.UpdateAllBagSlots then
		B:UpdateAllBagSlots()
	end

	debug("Cleanup complete")
end

--[[
    Initialize: Sets up the InventoryBackgroundAdjust module
    @return: nil
]]
function InventoryBackgroundAdjust:Initialize()
	debug("Initializing InventoryBackgroundAdjust module")
	-- Register with the addon's system using direct hook if available
	if addon.RegisterElementUpdate then
		addon:RegisterElementUpdate("inventoryBackgroundAdjust", function(reason, immediate)
			if reason == nil then
				self:UpdateAll()
			elseif reason == "cleanup" or (type(reason) == "string" and reason:find("Revert")) then
				debug("Received revert signal: " .. tostring(reason))
				self:RevertAll()
			else
				self:UpdateAll()
			end
		end)
	end

	-- Direct hook to ElvUI bag updates
	local B = E:GetModule("Bags")
	if B and B.UpdateAllBagSlots then
		hooksecurefunc(B, "UpdateAllBagSlots", function()
			self:UpdateAll()
		end)
	end

	-- Hook into addon update
	if addon.Update then
		hooksecurefunc(addon, "Update", function()
			self:UpdateAll()
		end)
	end

	-- Hook for addon disabled state
	if addon.RevertAllCustomizations then
		hooksecurefunc(addon, "RevertAllCustomizations", function()
			debug("RevertAllCustomizations called, reverting all backgrounds")
			self:RevertAll()
		end)
	end

	-- Hook into settings changes
	if E.Options and E.Options.args and E.Options.args.bagCustomizer then
		local colorOptionPath = E.Options.args.bagCustomizer.args.AdvancedTab
		if colorOptionPath and colorOptionPath.args and
				colorOptionPath.args.inventoryWindow and
				colorOptionPath.args.inventoryWindow.args and
				colorOptionPath.args.inventoryWindow.args.backgroundGroup and
				colorOptionPath.args.inventoryWindow.args.backgroundGroup.args and
				colorOptionPath.args.inventoryWindow.args.backgroundGroup.args.color then
			local originalSet = colorOptionPath.args.inventoryWindow.args.backgroundGroup.args.color.set
			colorOptionPath.args.inventoryWindow.args.backgroundGroup.args.color.set = function(...)
				-- Clear cache before applying new settings
				self:ClearCache()
				if originalSet then
					originalSet(...)
				end

				-- Notify other modules about color change
				if addon.TriggerEvent then
					addon:TriggerEvent("BACKGROUND_COLOR_CHANGED")
				end
			end
		end
	end

	-- Register with event system for profile changes
	if addon.RegisterForEvent then
		addon:RegisterForEvent("PROFILE_CHANGED", function()
			debug("Profile changed, forcing complete background reset")
			self:ClearCache()
			-- Force a complete reset
			self:RevertAll()
			-- Small delay before applying new settings
			C_Timer.After(0.1, function()
				self:UpdateAll()
			end)
		end)
	end

	debug("InventoryBackgroundAdjust module initialized")
end

-- Register with initialization (using direct method, not FF)
if addon.RegisterElement then
	addon:RegisterElement("inventoryBackgroundAdjust")
else
	-- Fallback initialization
	InventoryBackgroundAdjust:Initialize()
end

-- Return module
return InventoryBackgroundAdjust
