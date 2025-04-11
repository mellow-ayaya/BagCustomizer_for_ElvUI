-- ElvUI Bag Customizer - Resource Manager
--
-- This file handles texture/frame pooling and memory management.
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags")
local addon = E:GetModule("BagCustomizer")
-- Debug function optimization
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][ResourceManager]:|r "
-- Module-specific debug function
local function debug(message)
	-- First check if E.db.bagCustomizer exists
	if not E.db or not E.db.bagCustomizer then return end

	-- Then proceed with existing checks
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.resourceManager or
			not E.db.bagCustomizer.resourceManager.debug then
		return
	end

	-- Output the message with module name
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(message))
end

-- Initialize the ResourceManager module within the addon
addon.elements.resourceManager = {}
local ResourceManager = addon.elements.resourceManager
-- Initialize pool containers if they don't exist
addon.texturePool = addon.texturePool or {}
addon.framePool = addon.framePool or {}
-- Cache default layer values
local DEFAULT_LAYER = "ARTWORK"
local DEFAULT_SUBLAYER = 0
-- POOLING SYSTEM --
-- Get a texture from the pool or create a new one
function addon:GetPooledTexture(parent, layer, sublayer)
	if not parent then return nil end

	-- Assign defaults once
	layer = layer or DEFAULT_LAYER
	sublayer = sublayer or DEFAULT_SUBLAYER
	-- Simple pool retrieval - no nested loop
	local texture = #self.texturePool > 0 and table.remove(self.texturePool) or nil
	-- Quick validation without loop
	if texture and not (texture.SetTexture and texture:GetObjectType() == "Texture") then
		texture = nil
	end

	if texture then
		-- Reuse existing texture
		texture:SetParent(parent)
		texture:ClearAllPoints()
		texture:SetDrawLayer(layer, sublayer)
		texture:Show()
		debug("Reused texture from pool")
	else
		-- Create new texture
		texture = parent:CreateTexture(nil, layer, nil, sublayer)
		debug("Created new texture (pool empty)")
	end

	return texture
end

-- Return a texture to the pool with special handling for mask Textures
function addon:ReleaseTexture(texture)
	if not texture then return end

	-- Quick check for mask-related properties
	local isMaskTexture = texture._BCZ_hadMasks or (texture.AddMaskTexture and texture.RemoveMaskTexture)
	-- Handle the case where we're given a frame with a texture property
	if texture.texture then
		if isMaskTexture then
			-- Just clean it up but don't pool it
			texture.texture:ClearAllPoints()
			texture.texture:SetTexture(nil)
			texture.texture:Hide()
			return
		end

		-- Normal pooling for non-mask Textures
		if type(texture.texture) == "table" and texture.texture.SetTexture then
			texture.texture:ClearAllPoints()
			texture.texture:SetTexture(nil)
			texture.texture:Hide()
			table.insert(self.texturePool, texture.texture)
		end
	else
		if isMaskTexture then
			-- Just clean it up but don't pool it
			texture:ClearAllPoints()
			texture:SetTexture(nil)
			texture:Hide()
			return
		end

		-- Normal pooling for non-mask Textures
		texture:ClearAllPoints()
		texture:SetTexture(nil)
		texture:Hide()
		table.insert(self.texturePool, texture)
	end
end

-- Completely reset all texture caches and pools
function addon:ResetAllResourceCaches()
	debug("Performing complete resource cache reset")
	-- 1. Clear texture path cache
	texturePathCache = {}
	-- 2. Clear texture dimensions cache
	textureDimensions = {}
	-- 3. Clear texture existence cache
	addon.textureExists = {}
	-- 4. Reset texture pool with enhanced cleanup
	for i = #self.texturePool, 1, -1 do
		local texture = self.texturePool[i]
		if texture then
			-- Full reset of all properties
			texture:ClearAllPoints()
			texture:SetTexture(nil)
			texture:SetVertexColor(1, 1, 1, 1)
			texture:SetDesaturated(false)
			texture:SetBlendMode("BLEND")
			texture:SetAlpha(1)
			-- Remove all mask Textures
			if texture.GetNumMaskTextures and texture:GetNumMaskTextures() > 0 then
				for j = texture:GetNumMaskTextures(), 1, -1 do
					local mask = select(j, texture:GetMaskTextures())
					if mask then
						texture:RemoveMaskTexture(mask)
					end
				end
			end
		end
	end

	-- Empty the pool entirely
	self.texturePool = {}
	-- 5. Reset frame pool
	self.framePool = {}
	-- 6. Force garbage collection
	collectgarbage("collect")
	debug("All resource caches reset successfully")
end

-- Get a frame from the pool or create a new one
function addon:GetPooledFrame(parent, frameType, template)
	-- Set default frameType if not provided
	frameType = frameType or "Frame"
	-- Try to get from pool - simplified lookup
	local frame
	local index
	for i, pooledFrame in ipairs(self.framePool) do
		if pooledFrame.frameType == frameType then
			frame = pooledFrame.frame
			index = i
			break
		end
	end

	if frame and index then
		-- Remove from pool
		table.remove(self.framePool, index)
		-- Reuse existing frame
		frame:SetParent(parent)
		frame:ClearAllPoints()
		frame:Show()
		debug("Reused " .. frameType .. " from pool")
	else
		-- Create new frame
		if frameType == "Frame" then
			if BackdropTemplateMixin and template == "BackdropTemplate" then
				frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
			else
				frame = CreateFrame("Frame", nil, parent, template)
			end
		else
			frame = CreateFrame(frameType, nil, parent, template)
		end

		debug("Created new " .. frameType .. " (pool empty)")
	end

	return frame
end

-- Return a frame to the pool
function addon:ReleaseFrame(frame, frameType)
	if not frame then return end

	-- Clean up the frame
	frame:ClearAllPoints()
	frame:Hide()
	-- Add to pool
	table.insert(self.framePool, {
		frame = frame,
		frameType = frameType or "Frame",
	})
end

-- MEMORY MANAGEMENT --
-- Memory cleanup function (gentler version)
function ResourceManager:CleanupMemory(deep)
	-- Don't run cleanup if the settings panel is open to avoid UI freezes
	if _G.ElvUI_OptionsUI and _G.ElvUI_OptionsUI.IsShown and _G.ElvUI_OptionsUI:IsShown() then
		return
	end

	-- Track the last cleanup time to prevent excessive calls
	local now = GetTime()
	if self.lastCleanupTime and (now - self.lastCleanupTime < 5) then
		return -- Don't clean up more than once every 5 seconds
	end

	self.lastCleanupTime = now
	-- For backward compatibility
	local anyBagVisible = addon:IsAnyBagVisible()
	-- Only do deep cleanup when bags are closed or when explicitly requested
	if deep or not anyBagVisible then
		local MainTextures = addon:GetCachedModule("mainTextures")
		if MainTextures and MainTextures.ClearCache then
			pcall(function() MainTextures:ClearCache() end)
		end

		-- Use gentle collection instead of a forced one
		collectgarbage("step", 1000) -- Process 1000 items per step, far gentler
	end

	-- Use the more aggressive cleanup function if bags aren't visible
	if not anyBagVisible then
		self:CleanUnusedPoolObjects()
	else
		-- Standard cleanup (always perform)
		-- Release unused pooled objects if we have too many
		local MAX_TEXTURES = 50
		local KEEP_TEXTURES = 30
		if #addon.texturePool > MAX_TEXTURES then
			-- Keep only a reasonable number of Textures in the pool
			while #addon.texturePool > KEEP_TEXTURES do
				local texture = table.remove(addon.texturePool)
				-- Make sure the texture is fully cleaned up
				if texture then
					texture:SetTexture(nil)
					texture:ClearAllPoints()
					-- No need to call :Hide() as it's already done when releasing
				end
			end

			debug("Reduced texture pool from " .. MAX_TEXTURES .. "+ to " .. #addon.texturePool)
		end

		local MAX_FRAMES = 20
		local KEEP_FRAMES = 10
		if #addon.framePool > MAX_FRAMES then
			-- Keep only a reasonable number of frames in the pool
			while #addon.framePool > KEEP_FRAMES do
				table.remove(addon.framePool)
			end

			debug("Reduced frame pool from " .. MAX_FRAMES .. "+ to " .. #addon.framePool)
		end
	end

	-- Clear update timers (simplified timer management)
	if addon.updateTimer then
		addon.updateTimer:Cancel()
		addon.updateTimer = nil
	end

	-- Only replace the timer if it doesn't exist or we're doing deep cleanup
	if deep or not addon.memoryCleanupTimer then
		if addon.memoryCleanupTimer then
			addon.memoryCleanupTimer:Cancel()
		end

		-- Set up a single periodic cleanup that only runs when needed
		addon.memoryCleanupTimer = C_Timer.NewTicker(60, function()
			-- Only run when conditions are good
			if not InCombatLockdown() and not addon:IsAnyBagVisible() then
				collectgarbage("step", 1000)
			end
		end)
	end

	debug("Memory cleanup completed")
end

-- Clean up object pools more aggressively
function ResourceManager:CleanUnusedPoolObjects()
	-- Check if any bag is visible using direct ElvUI references
	local anyBagVisible = addon:IsAnyBagVisible()
	-- Only run when bags are closed
	if anyBagVisible then return end

	-- Clean texture pool more aggressively
	if #addon.texturePool > 10 then
		while #addon.texturePool > 5 do
			local texture = table.remove(addon.texturePool)
			if texture then
				texture:SetTexture(nil)
			end
		end

		debug("Reduced texture pool to 5 Textures")
	end

	-- Clean frame pool similarly
	if #addon.framePool > 5 then
		while #addon.framePool > 3 do
			table.remove(addon.framePool)
		end

		debug("Reduced frame pool to 3 frames")
	end

	debug("Unused pool objects cleaned up")
end

-- TEXTURE PATH MANAGEMENT --
-- Single unified texture cache
local texturePathCache = {}
-- Get texture with optimized caching
function addon:GetCachedTexture(frame, key, layer, sublayer)
	frame._BCZ_Textures = frame._BCZ_Textures or {}
	if not frame._BCZ_Textures[key] then
		-- Create and cache the texture
		frame._BCZ_Textures[key] = frame:CreateTexture(nil, layer or "ARTWORK", nil, sublayer or 0)
		debug("Created new texture with key: " .. key)
	end

	return frame._BCZ_Textures[key]
end

-- Global texture validation cache
addon.textureExists = addon.textureExists or {}
-- Function to check if a texture exists
function addon:TextureExists(texturePath)
	if not texturePath then return false end

	-- Check cache first
	if addon.textureExists[texturePath] ~= nil then
		return addon.textureExists[texturePath]
	end

	-- For interface paths, assume they exist
	if texturePath:find("^Interface\\") then
		addon.textureExists[texturePath] = true
		return true
	end

	-- For addon media paths, check if file exists
	-- This is a simplified check - in practice you'd need a more robust solution
	local exists = true -- Assume it exists
	addon.textureExists[texturePath] = exists
	return exists
end

-- Texture dimensions cache
local textureDimensions = {}
-- Get texture dimensions with improved caching
function addon:GetTextureDimensions(texturePath)
	-- Check cache first
	if textureDimensions[texturePath] then
		return textureDimensions[texturePath][1], textureDimensions[texturePath][2]
	end

	-- Hard-coded known dimensions - expanded with all known values
	local knownDimensions = {

		-- Buttons
		["blizzard_border_modern.tga"] = { 64, 64 },
		["blizzard_border_modern_empty.tga"] = { 64, 64 },
		["blizzard_highlight_modern.tga"] = { 64, 64 },
		["blizzard_texture_modern.tga"] = { 64, 64 },
		["elvui_border.tga"] = { 64, 64 },
		["elvui_border_empty.tga"] = { 64, 64 },
		["elvui_border_rounded.tga"] = { 64, 64 },
		["elvui_border_rounded_empty.tga"] = { 64, 64 },
		["elvui_highlight.tga"] = { 64, 64 },
		["elvui_highlight_rounded.tga"] = { 64, 64 },
		["elvui_texture.tga"] = { 64, 64 },
		["elvui_texture_rounded.tga"] = { 64, 64 },

		-- Currency textures
		["currency_blizzard_modern.tga"] = { 354, 52 },
		["currency_blizzard_classic.tga"] = { 354, 52 },
		["currency_cataclysm.tga"] = { 354, 52 },
		["currency_northrend.tga"] = { 354, 52 },
		["currency_custom1.tga"] = { 354, 52 },
		["currency_custom2.tga"] = { 354, 52 },
		["currency_custom3.tga"] = { 354, 52 },
		["gold_blizzard_modern.tga"] = { 354, 52 },
		["gold_blizzard_classic.tga"] = { 354, 52 },
		["gold_custom1.tga"] = { 354, 52 },
		["gold_custom2.tga"] = { 354, 52 },
		["gold_custom3.tga"] = { 354, 52 },

		-- Close button textures
		["close_blizzard_modern.tga"] = { 64, 64 },
		["close_blizzard_classic.tga"] = { 64, 64 },
		["close_blizzard_modern_borderless.tga"] = { 64, 64 },
		["close_cataclysm.tga"] = { 64, 64 },
		["close_northrend.tga"] = { 64, 64 },
		["close_custom1.tga"] = { 64, 64 },
		["close_custom2.tga"] = { 64, 64 },
		["close_custom3.tga"] = { 64, 64 },
		["close_button_glow.tga"] = { 64, 64 },

		-- Inventory background textures
		["art_cataclysm.tga"] = { 660, 660 },
		["art_cataclysm_wide.tga"] = { 668, 1000 },
		["art_cataclysm_2.tga"] = { 785, 1213 },
		["art_northrend.tga"] = { 800, 800 },

		-- Masks
		["alpha_fade_soft_circular.tga"] = { 512, 512 },
		["alpha_fade_soft_circular_small.tga"] = { 512, 512 },
		["alpha_fade_soft_circular_large.tga"] = { 512, 512 },
		["alpha_fade_soft_elliptical.tga"] = { 512, 512 },
		["alpha_fade_soft_elliptical_small.tga"] = { 512, 512 },
		["alpha_fade_soft_elliptical_large.tga"] = { 512, 512 },
		["alpha_fade_soft_square.tga"] = { 512, 512 },
		["alpha_fade_soft_square_small.tga"] = { 512, 512 },
		["alpha_fade_soft_square_large.tga"] = { 512, 512 },
		["alpha_fade_hard_square.tga"] = { 512, 512 },
		["alpha_fade_hard_square_small.tga"] = { 512, 512 },
		["alpha_fade_hard_square_large.tga"] = { 512, 512 },
		["alpha_fade_hard_circular.tga"] = { 512, 512 },
		["alpha_fade_hard_circular_small.tga"] = { 512, 512 },
		["alpha_fade_hard_circular_large.tga"] = { 512, 512 },
		["alpha_fade_hard_elliptical.tga"] = { 512, 512 },
		["alpha_fade_hard_elliptical_small.tga"] = { 512, 512 },
		["alpha_fade_hard_elliptical_large.tga"] = { 512, 512 },

		-- Top textures
		["top_blizzard_modern.tga"] = { 435, 42 },

	}
	-- Extract filename from path for checking against known dimensions
	local filename = texturePath:match("([^\\]-)$")
	-- Return known dimensions if we have them
	if filename and knownDimensions[filename] then
		textureDimensions[texturePath] = knownDimensions[filename]
		return knownDimensions[filename][1], knownDimensions[filename][2]
	end

	-- For unknown textures, use detection method
	debug("Measuring dimensions for " .. texturePath)
	local frame = CreateFrame("Frame")
	local tempTexture = frame:CreateTexture(nil, "BACKGROUND")
	tempTexture:SetTexture(texturePath)
	-- Get natural dimensions
	local width, height = tempTexture:GetSize()
	-- Clean up
	tempTexture:SetTexture(nil)
	frame:Hide()
	-- If dimensions can't be determined, use defaults
	if not width or width == 0 then width = 256 end

	if not height or height == 0 then height = 256 end

	-- Cache the result
	textureDimensions[texturePath] = { width, height }
	return width, height
end

--  list available Textures
function addon:GetTextureList(textureType)
	-- Default Textures for each type
	local defaults = {
		-- Currency Textures
		currency = {
			["Blizzard"] = "Blizzard (Default)",
			["Simple"] = "Simple",
			["Ornate"] = "Ornate",
			["Round"] = "Round",
			["Square"] = "Square",
			["Metal"] = "Metal",
			["Gold"] = "Gold",
			["Silver"] = "Silver",
			["Copper"] = "Copper",
		},
		-- Gold text Textures
		goldtext = {
			["Blizzard"] = "Blizzard (Default)",
			["Simple"] = "Simple",
			["Ornate"] = "Ornate",
			["Round"] = "Round",
			["Square"] = "Square",
			["Metal"] = "Metal",
			["Gold"] = "Gold",
			["Coin"] = "Coin",
			["Leather"] = "Leather",
		},
		-- Border Textures
		border = {
			["tooltip"] = "Tooltip",
			["thin"] = "Thin",
			["flat"] = "Flat",
			["gold"] = "Gold",
			["silver"] = "Silver",
			["copper"] = "Copper",
		},
		-- Fallback for other types
		default = {
			["Blizzard"] = "Blizzard (Default)",
			["Simple"] = "Simple",
			["Ornate"] = "Ornate",
		},
	}
	-- Return the appropriate list based on type
	return defaults[textureType] or defaults.default
end

-- Get media path with caching
function addon:GetMediaPath(textureType, textureName)
	-- Handle nil input
	if not textureName or textureName == "" then
		return nil
	end

	-- Create a unique cache key
	local cacheKey = textureType .. "|" .. textureName
	-- Check cache first
	if texturePathCache[cacheKey] then
		return texturePathCache[cacheKey]
	end

	-- Skip calculation for full paths
	if textureName:find("^Interface\\") then
		texturePathCache[cacheKey] = textureName
		return textureName
	end

	-- Calculate path using lookup table for better performance
	local basePath = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\"
	local pathMap = {
		closeButton = "CloseButtonTextures\\",
		inventoryBackgroundAdjust = "InventoryBackgroundTextures\\",
		top = "TopTextures\\",
		empty = "EmptySlotsIcons\\",
		border = "Borders\\",
		currency = "CurrencyTextures\\",
		goldtext = "CurrencyTextures\\",
		masks = "Masks\\",
	}
	local subfolder = pathMap[textureType] or ""
	local result = basePath .. subfolder .. textureName
	-- Store in cache
	texturePathCache[cacheKey] = result
	return result
end

-- Pre-cache common Textures for performance
function ResourceManager:PreCacheCommonTextures()
	-- Pre-cache common border Textures
	for style, _ in pairs(addon.borderStyles or {}) do
		if addon.borderTextures then
			addon.borderTextures[style] = addon.borderTextures[style]
		end
	end

	-- Pre-cache dimensions for common Textures
	local MainTextures = addon:GetCachedModule("mainTextures")
	if MainTextures and MainTextures.PreCacheDimensions then
		MainTextures:PreCacheDimensions()
	end

	debug("Pre-cached common Textures")
end

-- Clear texture dimensions cache
function addon:ClearTextureDimensionsCache()
	textureDimensions = {}
	debug("Texture dimensions cache cleared")
end

-- Clear texture cache
function addon:ClearTextureCache()
	texturePathCache = {}
	-- Also clear dimensions cache for complete refresh
	self:ClearTextureDimensionsCache()
	debug("Texture cache cleared")
end

-- Debug print with conditional execution for performance
function addon:DebugPrint(...)
	if E.db.bagCustomizer and E.db.bagCustomizer.debug then
		local msg = table.concat({ ... }, " ")
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffBagCustomizer:|r " .. msg)
	end
end

-- InventorySlots texture definitions
addon.slotBorderTextures = {
	Border = {
		["blizzard_modern"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_border_modern.tga",
		["blizzard_modern_empty"] =
		"Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_border_modern_empty.tga",
		["blizzard_classic"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_border_classic.tga",
		["elvui"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border.tga",
		["elvui_empty"] =
		"Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border_empty.tga",
		["elvui_rounded"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border_rounded.tga",
		["elvui_rounded_empty"] =
		"Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_border_rounded_empty.tga",
		["custom"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_border.tga",
	},
	Normal = {
		["blizzard_modern"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_modern.tga",
		["blizzard_classic"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_classic.tga",
		["elvui"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_texture.tga",
		["elvui_rounded"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_texture_rounded.tga",
		["custom"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_texture.tga",
	},
	Empty = {
		["blizzard_modern"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_modern.tga",
		["blizzard_classic"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_texture_classic.tga",
		["elvui"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_texture.tga",
		["elvui_rounded"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_texture_rounded.tga",
		["custom"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_texture.tga",
	},
	Highlight = {
		["blizzard_modern"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_highlight_modern.tga",
		["blizzard_classic"] =
		"Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\blizzard_highlight_classic.tga",
		["elvui"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_highlight.tga",
		["elvui_rounded"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\elvui_highlight_rounded.tga",
		["custom"] = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\custom_highlight.tga",
	},
}
-- Default fallback Textures for slot borders
addon.defaultSlotTextures = {
	Border = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\border.tga",
	EmptyBorder = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\border.tga",
	Empty = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\empty.tga",
	Normal = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\empty.tga",
	Highlight = "Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\highlight.tga",
	ScaleFactor = 100,
}
addon.maskShapeToFileMap = {
	["Soft Circular"] = "alpha_fade_soft_circular.tga",
	["Soft Circular Small"] = "alpha_fade_soft_circular_small.tga",
	["Soft Circular Large"] = "alpha_fade_soft_circular_large.tga",
	["Soft Elliptical"] = "alpha_fade_soft_elliptical.tga",
	["Soft Elliptical Small"] = "alpha_fade_soft_elliptical_small.tga",
	["Soft Elliptical Large"] = "alpha_fade_soft_elliptical_large.tga",
	["Soft Square"] = "alpha_fade_soft_square.tga",
	["Soft Square Small"] = "alpha_fade_soft_square_small.tga",
	["Soft Square Large"] = "alpha_fade_soft_square_large.tga",
	["Hard Square"] = "alpha_fade_hard_square.tga",
	["Hard Square Small"] = "alpha_fade_hard_square_small.tga",
	["Hard Square Large"] = "alpha_fade_hard_square_large.tga",
	["Hard Circular"] = "alpha_fade_hard_circular.tga",
	["Hard Circular Small"] = "alpha_fade_hard_circular_small.tga",
	["Hard Circular Large"] = "alpha_fade_hard_circular_large.tga",
	["Hard Elliptical"] = "alpha_fade_hard_elliptical.tga",
	["Hard Elliptical Small"] = "alpha_fade_hard_elliptical_small.tga",
	["Hard Elliptical Large"] = "alpha_fade_hard_elliptical_large.tga",
	["Custom1"] = "alpha_fade_custom1.tga",
	["Custom2"] = "alpha_fade_custom2.tga",
	["Custom3"] = "alpha_fade_custom3.tga",
}
-- Initialize function for ResourceManager module
function ResourceManager:Initialize()
	debug("Initializing ResourceManager module")
	-- Register with main addon
	addon:RegisterElementUpdate("resourceManager", function(reason, immediate)
		-- Handle resource-specific update logic here
		if reason == "MEMORY_CLEANUP_REQUESTED" then
			self:CleanupMemory(immediate)
		end
	end)
	-- Initial cache setup
	self:PreCacheCommonTextures()
	debug("ResourceManager module initialized")
end
