-- ElvUI Bag Customizer - Custom Textures
-- This module handles custom Textures for bag frames including:
-- - UI Background Textures (borders, frames, etc.)
-- - Artistic Background Textures (characters, landscapes, art)
-- - Top decorative Textures
-- Close button Textures are now handled in MiscTextures.lua
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags") -- Direct reference to ElvUI Bags module
local addon = E:GetModule("BagCustomizer")
-- CHANGED: Create element using standard method
addon.elements.mainTextures = {}
local MainTextures = addon.elements.mainTextures
-- Simple debug function
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][textures]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.mainTextures or
			not E.db.bagCustomizer.mainTextures.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- Use centralized texture dimensions function
function MainTextures:GetTextureDimensions(path)
	return addon:GetTextureDimensions(path)
end

-- Helper function to determine if a specific frame should be updated
function MainTextures:ShouldUpdateFrame(frame)
	-- Skip if frame isn't provided or visible
	if not frame or not frame:IsShown() then
		return false
	end

	-- Skip if in combat and optimization is enabled
	if InCombatLockdown() and not addon:IsAnyBagVisible() then
		return false
	end

	-- Skip if addon not enabled
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then
		return false
	end

	-- Skip if frame is a bank frame - THIS IS THE KEY ADDITION
	if addon:IsBankFrame(frame) then
		debug("Textures: Skipping bank frame: " .. (frame:GetName() or "unnamed"))
		return false
	end

	return true
end

-- Apply background Textures to the frame
function MainTextures:ApplyBackgroundTextures(frame)
	if not self:ShouldUpdateFrame(frame) then
		return
	end

	-- First apply the UI background if enabled
	self:ApplyUIBackground(frame)
	-- Then apply the art background if enabled
	self:ApplyArtBackground(frame)
	debug("Textures: Applied background Textures")
end

-- Apply UI background texture (frames, borders, etc.)
function MainTextures:ApplyUIBackground(frame)
	if not self:ShouldUpdateFrame(frame) then
		return
	end

	-- Check if UI background is enabled
	if not E.db.bagCustomizer.uiBackground or not E.db.bagCustomizer.uiBackground.enable then
		-- Remove UI background if it exists but is disabled
		if frame._BCZ_uiBackground then
			addon:ReleaseTexture(frame._BCZ_uiBackground)
			frame._BCZ_uiBackground = nil
		end

		-- Remove texture container if it exists but is disabled
		if frame._BCZ_uiTextureContainer then
			frame._BCZ_uiTextureContainer:Hide()
			addon:ReleaseFrame(frame._BCZ_uiTextureContainer, "Frame")
			frame._BCZ_uiTextureContainer = nil
		end

		return
	end

	local settings = E.db.bagCustomizer.uiBackground
	-- Use single texture method for UI background
	-- Clean up any texture container if it exists
	if frame._BCZ_uiTextureContainer then
		frame._BCZ_uiTextureContainer:Hide()
		addon:ReleaseFrame(frame._BCZ_uiTextureContainer, "Frame")
		frame._BCZ_uiTextureContainer = nil
	end

	-- Skip if texture is "None" (empty string)
	if settings.texture == "" then
		-- Clean up any existing texture
		if frame._BCZ_uiBackground then
			addon:ReleaseTexture(frame._BCZ_uiBackground)
			frame._BCZ_uiBackground = nil
		end

		return
	end

	-- Create UI background texture if it doesn't exist
	if not frame._BCZ_uiBackground then
		-- Create with ARTWORK, -2 draw layer (below art background)
		frame._BCZ_uiBackground = addon:GetPooledTexture(frame, "ARTWORK", -2)
		debug("Textures: Created new UI background for frame: " .. (frame:GetName() or "unnamed"))
	end

	-- Configure the texture
	local texturePath = addon:GetMediaPath("inventoryBackgroundAdjust", settings.texture)
	frame._BCZ_uiBackground:SetTexture(texturePath)
	frame._BCZ_uiBackground:SetAlpha(settings.alpha)
	-- Calculate size based on frame dimensions and scale
	local width = frame:GetWidth() * settings.scale
	local height = frame:GetHeight() * settings.scale
	frame._BCZ_uiBackground:SetSize(width, height)
	-- Position the texture
	frame._BCZ_uiBackground:ClearAllPoints()
	frame._BCZ_uiBackground:SetPoint(settings.point, frame, settings.point, settings.xOffset, settings.yOffset)
	-- Fix texture coordinates
	frame._BCZ_uiBackground:SetTexCoord(0, 1, 0, 1)
	-- Ensure the texture is visible
	frame._BCZ_uiBackground:Show()
	debug("Textures: Applied UI background texture: " .. settings.texture)
end

-- Apply artistic background texture (characters, landscapes, art) - With Static Fade Option
function MainTextures:ApplyArtBackground(frame)
	if not self:ShouldUpdateFrame(frame) then
		return
	end

	-- Cleanup potentially orphaned elements from other methods
	if frame._BCZ_fadeOverlay then
		addon:ReleaseTexture(frame._BCZ_fadeOverlay)
		frame._BCZ_fadeOverlay = nil
	end

	if frame._BCZ_artBackgroundShader then
		if frame._BCZ_artBackground then
			frame._BCZ_artBackground:SetPixelShader(nil); frame._BCZ_artBackground:SetTexture(1, nil);
		end

		frame._BCZ_artBackgroundShader = nil
	end

	-- Check if art background is enabled
	if not E.db.bagCustomizer.artBackground or not E.db.bagCustomizer.artBackground.enable then
		-- Remove art background if it exists but is disabled
		if frame._BCZ_artBackground then
			addon:ReleaseTexture(frame._BCZ_artBackground)
			frame._BCZ_artBackground = nil
		end

		-- Remove the mask if it exists
		if frame._BCZ_artBackgroundMask then
			-- No need to call RemoveMaskTexture here as the art background is already gone/being removed
			addon:ReleaseTexture(frame._BCZ_artBackgroundMask)
			frame._BCZ_artBackgroundMask = nil
		end

		return -- Exit if disabled
	end

	local settings = E.db.bagCustomizer.artBackground
	-- --- Art Background Setup ---
	if not frame._BCZ_artBackground then
		frame._BCZ_artBackground = addon:GetPooledTexture(frame, "ARTWORK", -1)
		debug("Textures: Created new art background for frame: " .. (frame:GetName() or "unnamed"))
	end

	if not frame._BCZ_artBackground or not frame._BCZ_artBackground:IsObjectType("Texture") then
		debug("Textures: ERROR - frame._BCZ_artBackground is not a valid Texture object!")
		if frame._BCZ_artBackgroundMask then
			addon:ReleaseTexture(frame._BCZ_artBackgroundMask); frame._BCZ_artBackgroundMask = nil;
		end

		return
	end

	local texturePath = addon:GetMediaPath("inventoryBackgroundAdjust", settings.texture)
	frame._BCZ_artBackground:SetTexture(texturePath) -- Sampler 0
	frame._BCZ_artBackground:SetAlpha(settings.alpha or 1)
	local frameWidth, frameHeight = frame:GetWidth(), frame:GetHeight()
	local horizontalSize, verticalSize = (settings.horizontalSize or 100) / 100, (settings.verticalSize or 100) / 100
	-- Calculate initial dimensions
	local artWidth = frameWidth * horizontalSize * (settings.scale or 1)
	local artHeight = frameHeight * verticalSize * (settings.scale or 1)
	-- Apply aspect ratio maintenance if enabled
	if settings.maintainArtAspectRatio and texturePath and texturePath ~= "" then -- Check texturePath too
		local textureWidth, textureHeight = self:GetTextureDimensions(texturePath)
		if textureWidth > 0 and textureHeight > 0 then
			local originalAspectRatio = textureWidth / textureHeight
			local currentAspectRatio = artWidth / artHeight
			if currentAspectRatio > originalAspectRatio then
				artWidth = artHeight * originalAspectRatio
			else
				artHeight = artWidth / originalAspectRatio
			end

			debug("Textures: Maintaining art aspect ratio: " .. originalAspectRatio)
		end
	end

	frame._BCZ_artBackground:SetSize(artWidth, artHeight)
	frame._BCZ_artBackground:ClearAllPoints()
	frame._BCZ_artBackground:SetPoint(settings.point or "CENTER", frame, settings.point or "CENTER", settings.xOffset or 0,
		settings.yOffset or 0)
	local artLeft, artRight, artTop, artBottom = 0, 1, 0, 1
	if settings.cropHorizontally then
		local cropAmount = (settings.cropHorizontalAmount or 0) / 100; artLeft = cropAmount; artRight = 1 - cropAmount;
	end

	if settings.cropVertically then
		local cropAmount = (settings.cropVerticalAmount or 0) / 100; artTop = cropAmount; artBottom = 1 - cropAmount;
	end

	frame._BCZ_artBackground:SetTexCoord(artLeft, artRight, artTop, artBottom)
	frame._BCZ_artBackground:SetDesaturated(settings.desaturate or false)
	if settings.useTint then
		local r, g, b = (settings.tintColor and settings.tintColor.r or 1),
				(settings.tintColor and settings.tintColor.g or 1), (settings.tintColor and settings.tintColor.b or 1)
		frame._BCZ_artBackground:SetVertexColor(r, g, b)
	else
		frame._BCZ_artBackground:SetVertexColor(1, 1, 1)
	end

	frame._BCZ_artBackground:Show()
	-- --- End Art Background Setup ---
	-- --- Static Edge Fading using AddMaskTexture ---
	if settings.useEdgeFade then
		-- Get the filename directly from settings (e.g., "alpha_fade_soft_circular.tga" or "")
		local maskFilename = settings.maskShape
		local fadeTexturePath = nil
		-- Check if a valid mask filename is selected (not nil or empty string)
		if maskFilename and maskFilename ~= "" then
			fadeTexturePath = addon:GetMediaPath("masks", maskFilename)
			debug("Textures: Using static mask file (direct): " .. fadeTexturePath)
		else
			debug("Textures: No valid mask filename selected.")
		end

		-- Proceed only if we got a valid path
		if fadeTexturePath then
			-- Create the mask texture object if it doesn't exist
			if not frame._BCZ_artBackgroundMask then
				frame._BCZ_artBackgroundMask = frame:CreateMaskTexture(nil, "ARTWORK")
				debug("Textures: Created new MaskTexture widget for frame: " .. (frame:GetName() or "unnamed"))
				if frame._BCZ_artBackground and frame._BCZ_artBackground.AddMaskTexture then
					frame._BCZ_artBackground:AddMaskTexture(frame._BCZ_artBackgroundMask)
				else
					debug("Textures: ERROR - Could not add mask, parent art background invalid.")
				end

				debug("Textures: Attached MaskTexture widget to art background.")
				frame._BCZ_artBackgroundMask._BCZ_hadMasks = true
			end

			-- Ensure the mask widget is valid
			if not frame._BCZ_artBackgroundMask or not frame._BCZ_artBackgroundMask:IsObjectType("MaskTexture") then
				debug("Textures: ERROR - frame._BCZ_artBackgroundMask is not a valid MaskTexture object!")
				if frame._BCZ_artBackground and frame._BCZ_artBackground.RemoveMaskTexture then
					frame._BCZ_artBackground:RemoveMaskTexture(frame._BCZ_artBackgroundMask)
				end
			else
				-- Set the texture file for the mask
				frame._BCZ_artBackgroundMask:SetTexture(fadeTexturePath, "CLAMP", "CLAMP")
				local maskWidth, maskHeight = artWidth, artHeight -- Start with art background dimensions
				-- Apply mask aspect ratio maintenance if enabled
				if settings.maintainMaskAspectRatio then
					-- Check fadeTexturePath is valid before getting dimensions
					if fadeTexturePath then
						local maskTextureWidth, maskTextureHeight = self:GetTextureDimensions(fadeTexturePath)
						if maskTextureWidth > 0 and maskTextureHeight > 0 then
							local maskAspectRatio = maskTextureWidth / maskTextureHeight
							local currentMaskAspectRatio = maskWidth / maskHeight
							if currentMaskAspectRatio > maskAspectRatio then
								maskWidth = maskHeight * maskAspectRatio
							else
								maskHeight = maskWidth / maskAspectRatio
							end

							debug("Textures: Maintaining mask aspect ratio: " .. maskAspectRatio)
						else
							debug("Textures: Could not get valid dimensions for mask texture: " .. fadeTexturePath)
						end
					else
						debug("Textures: Skipping dimension check for mask aspect ratio (no valid path).")
					end
				end

				-- Position and size the mask widget explicitly
				frame._BCZ_artBackgroundMask:ClearAllPoints()
				frame._BCZ_artBackgroundMask:SetPoint(settings.point or "CENTER", frame, settings.point or "CENTER",
					settings.xOffset or 0, settings.yOffset or 0)
				frame._BCZ_artBackgroundMask:SetSize(maskWidth, maskHeight)
				frame._BCZ_artBackgroundMask:SetTexCoord(0, 1, 0, 1)
				frame._BCZ_artBackgroundMask:SetScale(1.0)
				frame._BCZ_artBackgroundMask:Show()
				debug("Textures: Applied static mask using AddMaskTexture.")
			end
		else
			-- No valid mask path derived, ensure the mask is removed/hidden
			if frame._BCZ_artBackgroundMask then
				if frame._BCZ_artBackground and frame._BCZ_artBackground.RemoveMaskTexture then
					frame._BCZ_artBackground
							:RemoveMaskTexture(frame._BCZ_artBackgroundMask);
				end

				addon:ReleaseTexture(frame._BCZ_artBackgroundMask)
				frame._BCZ_artBackgroundMask = nil
				debug("Textures: Removed MaskTexture (No valid path derived).")
			end
		end
	else
		-- useEdgeFade is disabled, remove/hide mask if it exists
		if frame._BCZ_artBackgroundMask then
			if frame._BCZ_artBackground and frame._BCZ_artBackground.RemoveMaskTexture then
				frame._BCZ_artBackground
						:RemoveMaskTexture(frame._BCZ_artBackgroundMask);
			end

			addon:ReleaseTexture(frame._BCZ_artBackgroundMask)
			frame._BCZ_artBackgroundMask = nil
			debug("Textures: Removed MaskTexture (Fade disabled).")
		end
	end

	-- --- End Static Edge Fading ---
	debug("Textures: Applied art background texture: " ..
		settings.texture .. " with static fade: " .. tostring(settings.useEdgeFade))
end

-- Helper function to directly get the search box from ElvUI frames
function MainTextures:GetSearchBox(frame)
	if not frame then return nil end

	-- For BagFrame
	if frame == B.BagFrame then
		if B.BagFrame.SearchEditBox then
			return B.BagFrame.SearchEditBox
		elseif B.BagFrame.SearchBox then
			return B.BagFrame.SearchBox
		elseif B.BagFrame.editBox then
			return B.BagFrame.editBox
		end
	end

	-- Ignore Bank frames completely
	if addon:IsBankFrame(frame) then
		return nil
	end

	-- For direct property access
	if frame.SearchEditBox then
		return frame.SearchEditBox
	end

	if frame.SearchBox then
		return frame.SearchBox
	end

	if frame.editBox then
		return frame.editBox
	end

	-- Fallback to searching children if needed
	for i = 1, frame:GetNumChildren() do
		local child = select(i, frame:GetChildren())
		if child and child:IsObjectType("EditBox") then
			return child
		end
	end

	return nil
end

-- Apply top texture (from top of frame to below search bar)
function MainTextures:ApplyTopTexture(frame, searchBar)
	if not self:ShouldUpdateFrame(frame) then
		return
	end

	-- Get search bar if not provided
	if not searchBar then
		searchBar = self:GetSearchBox(frame)
		if not searchBar then
			debug("Textures: ApplyTopTexture: Missing searchBar")
			return
		end
	end

	if not E.db.bagCustomizer.topTexture or not E.db.bagCustomizer.topTexture.enable then
		-- Remove top texture if it exists but is disabled
		if frame._BCZ_topTexture then
			addon:ReleaseTexture(frame._BCZ_topTexture)
			frame._BCZ_topTexture = nil
		end

		-- Remove top texture container if it exists but is disabled
		if frame._BCZ_topTextureContainer then
			frame._BCZ_topTextureContainer:Hide()
			addon:ReleaseFrame(frame._BCZ_topTextureContainer, "Frame")
			frame._BCZ_topTextureContainer = nil
		end

		return
	end

	local settings = E.db.bagCustomizer.topTexture
	local useSlice = settings.useSlice or false
	if useSlice then
		-- Use 3-slice scaling
		self:ApplySlicedTopTexture(frame, settings)
	else
		-- Use traditional single texture (original code)
		self:ApplySingleTopTexture(frame, settings)
	end

	debug("Textures: Applied top texture: " .. settings.texture)
end

-- Apply a single stretched top texture
function MainTextures:ApplySingleTopTexture(frame, settings)
	-- Clean up any texture container if it exists
	if frame._BCZ_topTextureContainer then
		frame._BCZ_topTextureContainer:Hide()
		addon:ReleaseFrame(frame._BCZ_topTextureContainer, "Frame")
		frame._BCZ_topTextureContainer = nil
	end

	-- Create custom texture if it doesn't exist
	if not frame._BCZ_topTexture then
		frame._BCZ_topTexture = addon:GetPooledTexture(frame, "ARTWORK", -3)
		debug("Textures: Created new topTexture for frame: " .. (frame:GetName() or "unnamed"))
	end

	-- Configure the texture with path caching
	local texturePath = addon:GetMediaPath("top", settings.texture)
	frame._BCZ_topTexture:SetTexture(texturePath)
	frame._BCZ_topTexture:SetAlpha(settings.alpha)
	-- Clear previous position
	frame._BCZ_topTexture:ClearAllPoints()
	-- Calculate dimensions and position
	local frameWidth = frame:GetWidth() or 400
	local textureHeight = settings.height or 40 -- Default height
	-- Apply width adjustment if specified
	local widthAdjust = settings.widthAdjust or 0
	local textureWidth = (frameWidth + widthAdjust) * (settings.scale or 1)
	-- Set size - APPLY SCALE TO HEIGHT TOO FOR CONSISTENCY WITH SLICED METHOD
	frame._BCZ_topTexture:SetSize(textureWidth, textureHeight * (settings.scale or 1))
	-- Position the texture
	frame._BCZ_topTexture:SetPoint("TOP", frame, "TOP", settings.xOffset or 0, settings.yOffset or 0)
	-- Fix texture coordinates
	frame._BCZ_topTexture:SetTexCoord(0, 1, 0, 1)
	-- Ensure it's visible
	frame._BCZ_topTexture:Show()
end

-- Apply 3-slice top texture (left, middle, right)
function MainTextures:ApplySlicedTopTexture(frame, settings)
	-- Get texture path
	local texturePath = addon:GetMediaPath("top", settings.texture)
	-- Get actual texture dimensions (use manual if provided)
	local textureWidth = settings.manualDimensions and settings.textureWidth or 200
	local textureHeight = settings.manualDimensions and settings.textureHeight or 30
	-- Calculate breakpoints based on user settings
	local leftBreakPct = settings.leftBreakPct or 10  -- Default 15%
	local rightBreakPct = settings.rightBreakPct or 95 -- Default 85%
	-- Convert to texture coordinates (0-1 scale)
	local leftBreakCoord = leftBreakPct / 100
	local rightBreakCoord = rightBreakPct / 100
	-- Calculate pixel sizes for the frame
	local frameWidth = frame:GetWidth()
	-- Apply width adjustment
	local widthAdjust = settings.widthAdjust or 4
	local baseTextureWidth
	if settings.customWidth and settings.customWidth > 0 then
		baseTextureWidth = settings.customWidth
	else
		baseTextureWidth = frameWidth + widthAdjust
	end

	-- Apply scale to the height
	local baseHeight = settings.height or 42
	local scale = settings.scale or 1
	local height = baseHeight * scale
	-- IMPORTANT: Keep aspectRatio definition for tiling code
	local aspectRatio = textureWidth / textureHeight
	-- Calculate directly scaled width based on adjusted frame width
	local scaledTextureWidth = baseTextureWidth * scale
	-- Clean up any single texture if it exists
	if frame._BCZ_topTexture then
		addon:ReleaseTexture(frame._BCZ_topTexture)
		frame._BCZ_topTexture = nil
	end

	-- Create container if needed
	if not frame._BCZ_topTextureContainer then
		frame._BCZ_topTextureContainer = CreateFrame("Frame", nil, frame)
	end

	-- Get container
	local container = frame._BCZ_topTextureContainer
	-- Ensure segments exist
	if not container.Left then
		container.Left = container:CreateTexture(nil, "ARTWORK", nil, -3)
	end

	if not container.Middle then
		container.Middle = container:CreateTexture(nil, "ARTWORK", nil, -3)
	end

	if not container.Right then
		container.Right = container:CreateTexture(nil, "ARTWORK", nil, -3)
	end

	local leftTex = container.Left
	local middleTex = container.Middle
	local rightTex = container.Right
	-- Show container
	container:Show()
	-- Calculate the width of each section with the scaled width
	local edgeSize = settings.edgeSize or 24
	local leftEdgeWidth = edgeSize
	local rightEdgeWidth = edgeSize
	-- Middle section must fill the remaining space (stretching/tiling as needed)
	local middleWidth = scaledTextureWidth - leftEdgeWidth - rightEdgeWidth
	-- Set container position - allowing for centering with scale and width adjustment
	container:ClearAllPoints()
	-- Center the container horizontally if using custom width
	if settings.customWidth and settings.customWidth > 0 then
		local xCenterOffset = (frameWidth - baseTextureWidth) / 2
		container:SetPoint("TOP", frame, "TOP",
			(settings.xOffset or 0) + xCenterOffset,
			settings.yOffset or 0)
	else
		container:SetPoint("TOP", frame, "TOP", settings.xOffset or 0, settings.yOffset or 0)
	end

	container:SetSize(scaledTextureWidth, height)
	leftTex:ClearAllPoints()
	leftTex:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	rightTex:ClearAllPoints()
	rightTex:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
	-- Set Textures
	leftTex:SetTexture(texturePath)
	middleTex:SetTexture(texturePath)
	rightTex:SetTexture(texturePath)
	-- Set texture coordinates for left, middle, right
	leftTex:SetTexCoord(0, leftBreakCoord, 0, 1)
	middleTex:SetTexCoord(leftBreakCoord, rightBreakCoord, 0, 1)
	rightTex:SetTexCoord(rightBreakCoord, 1, 0, 1)
	-- Set sizes - with scaled dimensions
	leftTex:SetSize(leftEdgeWidth, height)
	middleTex:SetSize(middleWidth, height)
	rightTex:SetSize(rightEdgeWidth, height)
	-- Set alphas
	leftTex:SetAlpha(settings.alpha)
	middleTex:SetAlpha(settings.alpha)
	rightTex:SetAlpha(settings.alpha)
	-- Use tiling for middle section if enabled
	local useTiling = settings.useTiling or false
	if useTiling then
		-- Hide the regular middle texture
		middleTex:Hide()
		-- Left and right segments
		leftTex:SetDrawLayer("ARTWORK", -3)
		leftTex:Show()
		rightTex:SetDrawLayer("ARTWORK", -3)
		rightTex:Show()
		-- Calculate middle section dimensions
		local middleTexPct = (rightBreakPct - leftBreakPct) / 100
		-- Use scaled aspectRatio for tile width calculation
		local tileWidth = math.floor(height * aspectRatio * middleTexPct)
		local tileSpacing = settings.tileSpacing or 0
		local tileOffset = settings.tileOffset or 0
		-- Calculate how many tiles we need
		local availableSpace = middleWidth - tileOffset
		local tilesNeeded = math.max(1, math.floor(availableSpace / (tileWidth + tileSpacing)))
		-- Initialize or clear tile table
		container.middleTiles = container.middleTiles or {}
		-- Special case for single tile - make it fill the exact space
		if tilesNeeded == 1 then
			if not container.middleTiles[1] then
				container.middleTiles[1] = container:CreateTexture(nil, "ARTWORK", nil, -3)
			end

			local tile = container.middleTiles[1]
			tile:SetTexture(texturePath)
			tile:SetTexCoord(leftBreakCoord, rightBreakCoord, 0, 1)
			-- Clear any previous points
			tile:ClearAllPoints()
			-- Set tile to EXACTLY middle width with a tiny bit of overlap to prevent seams
			tile:SetSize(middleWidth + 0.5, height)
			-- Position with exact alignment, adding a minor offset to eliminate gaps
			tile:SetPoint("TOPLEFT", leftTex, "TOPRIGHT", -0.25, 0)
			tile:SetPoint("TOPRIGHT", rightTex, "TOPLEFT", 0.25, 0)
			tile:SetAlpha(settings.alpha)
			tile:Show()
			-- Hide any excess tiles
			for i = 2, #container.middleTiles do
				if container.middleTiles[i] then
					container.middleTiles[i]:Hide()
				end
			end
		else
			-- Multiple tile case - ensure complete coverage
			for i = 1, tilesNeeded do
				if not container.middleTiles[i] then
					container.middleTiles[i] = container:CreateTexture(nil, "ARTWORK", nil, -3)
				end

				local tile = container.middleTiles[i]
				tile:SetTexture(texturePath)
				tile:SetTexCoord(leftBreakCoord, rightBreakCoord, 0, 1)
				-- Clear any previous points
				tile:ClearAllPoints()
				-- Preserve aspect ratio for tiles
				tile:SetSize(tileWidth, height)
				-- Position with offset and spacing, adding a small overlap between tiles
				local tileOverlap = 0.5 -- Add a small overlap to prevent seams
				local xPos = (tileWidth + tileSpacing - tileOverlap) * (i - 1) + tileOffset
				-- First tile needs to connect directly to the left edge
				if i == 1 then
					tile:SetPoint("TOPLEFT", leftTex, "TOPRIGHT", 0, 0)
				else
					tile:SetPoint("TOPLEFT", leftTex, "TOPRIGHT", xPos, 0)
				end

				-- Last tile should stretch to meet the right edge if needed
				if i == tilesNeeded then
					-- Check if we need to stretch the last tile
					local rightEdgePos = leftTex:GetWidth() + middleWidth - 5
					local lastTilePos = xPos + tileWidth
					if lastTilePos < rightEdgePos then
						-- Stretch the last tile to fill any gap
						tile:SetWidth(tileWidth + (rightEdgePos - lastTilePos))
					end
				end

				tile:SetAlpha(settings.alpha)
				tile:Show()
			end

			-- Hide excess tiles
			for i = tilesNeeded + 1, #container.middleTiles do
				if container.middleTiles[i] then
					container.middleTiles[i]:Hide()
				end
			end
		end
	else
		-- Use stretched middle section (no tiling)
		-- Hide any tiles if they exist
		if container.middleTiles then
			for i = 1, #container.middleTiles do
				if container.middleTiles[i] then
					container.middleTiles[i]:Hide()
				end
			end
		end

		-- Set up the main segments
		leftTex:SetDrawLayer("ARTWORK", -3)
		leftTex:Show()
		rightTex:SetDrawLayer("ARTWORK", -3)
		rightTex:Show()
		-- Middle (stretched) segment
		middleTex:SetDrawLayer("ARTWORK", -3)
		middleTex:ClearAllPoints()
		middleTex:SetPoint("TOPLEFT", leftTex, "TOPRIGHT", 0, 0)
		middleTex:SetPoint("TOPRIGHT", rightTex, "TOPLEFT", 0, 0)
		middleTex:Show()
	end

	-- Add cleanup function to the container
	container.Cleanup = function()
		if container.Left then
			container.Left:Hide()
		end

		if container.Middle then
			container.Middle:Hide()
		end

		if container.Right then
			container.Right:Hide()
		end

		if container.middleTiles then
			for i = 1, #container.middleTiles do
				if container.middleTiles[i] then
					container.middleTiles[i]:Hide()
				end
			end
		end
	end
	debug("Textures: Applied sliced top texture: " .. settings.texture)
end

-- Pre-cache texture dimensions for common Textures
function MainTextures:PreCacheDimensions()
	local textureTypes = { "inventoryBackgroundAdjust", "top", "closeButton" }
	local commonTextures = {
		"UIFrameMetal2xa2_top.tga",
		"close.tga",
		"background.tga",
		"np.tga",
	}
	for _, textureType in ipairs(textureTypes) do
		for _, texture in ipairs(commonTextures) do
			local path = addon:GetMediaPath(textureType, texture)
			-- This will cache the dimensions
			self:GetTextureDimensions(path)
		end
	end

	debug("Textures: Pre-cached texture dimensions for common Textures")
end

-- Clear texture path cache
function MainTextures:ClearCache()
	debug("Textures: Texture dimensions cache cleared")
	-- Let ResourceManager handle cache clearing
	addon:ClearTextureCache()
end

-- Clear unused texture caches when bags are closed
function MainTextures:ClearUnusedTextureCache()
	-- Let ResourceManager handle cache trimming
	debug("Textures: Requesting texture cache trim")
	-- This empty function can be kept as a placeholder for compatibility
end

-- Update all Textures for a frame
function MainTextures:UpdateFrame(frame, forceRebuild)
	if not frame then
		debug("Textures: UpdateFrame called with nil frame")
		return
	end

	if not self:ShouldUpdateFrame(frame) then
		debug("Textures: Skipping update for frame: " .. (frame:GetName() or "unnamed"))
		return
	end

	-- If forceRebuild is requested, clean up existing Textures first
	if forceRebuild then
		debug("Textures: Performing forced rebuild of Textures for " .. (frame:GetName() or "unnamed"))
		self:RevertFrame(frame)
	end

	-- Apply background Textures
	self:ApplyBackgroundTextures(frame)
	-- Apply top texture with search box
	local searchBox = self:GetSearchBox(frame)
	if searchBox then
		debug("Textures: Found searchBox, applying top texture")
		self:ApplyTopTexture(frame, searchBox)
	else
		debug("Textures: No searchBox found for frame: " .. (frame:GetName() or "unnamed"))
	end

	-- Apply close button texture through MiscTextures module
	local MiscTextures = addon:GetCachedModule("miscTextures")
	if MiscTextures and MiscTextures.ApplyCloseButtonTexture then
		debug("Textures: Applying close button texture")
		MiscTextures:ApplyCloseButtonTexture(frame)
	end

	debug("Textures: Updated frame " .. (frame:GetName() or "unnamed"))
end

-- Revert all Textures for a frame
function MainTextures:RevertFrame(frame)
	if not frame then return end

	-- Clean up UI background
	if frame._BCZ_uiBackground then
		addon:ReleaseTexture(frame._BCZ_uiBackground)
		frame._BCZ_uiBackground = nil
	end

	-- Clean up art background
	if frame._BCZ_artBackground then
		addon:ReleaseTexture(frame._BCZ_artBackground)
		frame._BCZ_artBackground = nil
	end

	-- Clean up the mask texture IF it exists
	if frame._BCZ_artBackgroundMask then
		-- No need to call RemoveMaskTexture here as the art background is already gone/being removed
		addon:ReleaseTexture(frame._BCZ_artBackgroundMask) -- Or :Hide() if not pooling
		frame._BCZ_artBackgroundMask = nil
	end

	-- Clean up top texture (single)
	if frame._BCZ_topTexture then
		addon:ReleaseTexture(frame._BCZ_topTexture)
		frame._BCZ_topTexture = nil
	end

	-- Clean up top texture container (sliced)
	if frame._BCZ_topTextureContainer then
		if frame._BCZ_topTextureContainer.Cleanup then frame._BCZ_topTextureContainer.Cleanup(); end

		if frame._BCZ_topTextureContainer.Left then frame._BCZ_topTextureContainer.Left:Hide(); end

		if frame._BCZ_topTextureContainer.Middle then frame._BCZ_topTextureContainer.Middle:Hide(); end

		if frame._BCZ_topTextureContainer.Right then frame._BCZ_topTextureContainer.Right:Hide(); end

		if frame._BCZ_topTextureContainer.middleTiles then
			for i, tile in ipairs(frame._BCZ_topTextureContainer.middleTiles) do if tile then tile:Hide(); end end
		end

		frame._BCZ_topTextureContainer:Hide()
		addon:ReleaseFrame(frame._BCZ_topTextureContainer, "Frame") -- Release if pooled
		frame._BCZ_topTextureContainer = nil
	end

	-- Call MiscTextures to clean up close button if available
	local MiscTextures = addon:GetCachedModule("miscTextures")
	if MiscTextures and MiscTextures.CleanupCloseButton then
		MiscTextures:CleanupCloseButton(frame)
	end

	debug("Textures: Reverted all Textures for frame: " .. (frame:GetName() or "unnamed"))
end

-- Main revert function to revert all frames
function MainTextures:Revert()
	-- Only revert the regular bag frame, not bank frames
	if B.BagFrame then
		self:RevertFrame(B.BagFrame)
	end

	-- Clear caches
	self:ClearCache()
	debug("Textures: Reverted all Textures")
end

-- Layout update function for when frame dimensions change
function MainTextures:UpdateLayout()
	-- Only update the regular bag frame layout
	if B.BagFrame and B.BagFrame:IsShown() and not addon:IsBankFrame(B.BagFrame) then
		self:UpdateFrameLayout(B.BagFrame)
	end
end

function MainTextures:UpdateFrameLayout(frame)
	if not self:ShouldUpdateFrame(frame) then
		return
	end

	-- Update only UI backgrounds that need precise positioning
	if frame._BCZ_uiBackground and E.db.bagCustomizer.uiBackground and E.db.bagCustomizer.uiBackground.enable then
		local settings = E.db.bagCustomizer.uiBackground
		-- Recalculate size based on frame dimensions and scale
		local width = frame:GetWidth() * settings.scale
		local height = frame:GetHeight() * settings.scale
		frame._BCZ_uiBackground:SetSize(width, height)
		-- Update position if needed
		frame._BCZ_uiBackground:ClearAllPoints()
		frame._BCZ_uiBackground:SetPoint(settings.point, frame, settings.point, settings.xOffset, settings.yOffset)
	end

	-- Update art background layout
	if frame._BCZ_artBackground and E.db.bagCustomizer.artBackground and E.db.bagCustomizer.artBackground.enable then
		local settings = E.db.bagCustomizer.artBackground
		-- Calculate frame dimensions
		local frameWidth = frame:GetWidth()
		local frameHeight = frame:GetHeight()
		-- Calculate texture dimensions based on sizing settings
		local horizontalSize = (settings.horizontalSize or 100) / 100
		local verticalSize = (settings.verticalSize or 100) / 100
		local artWidth = frameWidth * horizontalSize
		local artHeight = frameHeight * verticalSize
		-- Apply additional scaling if needed
		artWidth = artWidth * settings.scale
		artHeight = artHeight * settings.scale
		-- Apply aspect ratio maintenance if enabled
		local texturePath = addon:GetMediaPath("inventoryBackgroundAdjust", settings.texture) -- Get path for art texture
		if settings.maintainArtAspectRatio and texturePath and texturePath ~= "" then       -- Check path validity
			local textureWidth, textureHeight = self:GetTextureDimensions(texturePath)
			if textureWidth > 0 and textureHeight > 0 then
				local originalAspectRatio = textureWidth / textureHeight
				local currentAspectRatio = artWidth / artHeight
				if currentAspectRatio > originalAspectRatio then
					artWidth = artHeight * originalAspectRatio
				else
					artHeight = artWidth / originalAspectRatio
				end

				debug("Textures: Maintaining art aspect ratio during layout update: " .. originalAspectRatio)
			end
		end

		-- Update texture size and position
		frame._BCZ_artBackground:SetSize(artWidth, artHeight)
		frame._BCZ_artBackground:ClearAllPoints()
		frame._BCZ_artBackground:SetPoint(settings.point, frame, settings.point, settings.xOffset, settings.yOffset)
		-- Also update mask if it exists and edge fade is enabled
		if frame._BCZ_artBackgroundMask and settings.useEdgeFade then
			local maskWidth, maskHeight = artWidth, artHeight -- Start with art background dimensions
			-- Apply mask aspect ratio maintenance if enabled
			if settings.maintainMaskAspectRatio then
				-- Get the mask filename directly from settings
				local maskFilename = settings.maskShape
				local fadeTexturePath = nil
				if maskFilename and maskFilename ~= "" then
					fadeTexturePath = addon:GetMediaPath("masks", maskFilename)
				end

				-- Check fadeTexturePath is valid before getting dimensions
				if fadeTexturePath then
					local maskTextureWidth, maskTextureHeight = self:GetTextureDimensions(fadeTexturePath)
					if maskTextureWidth > 0 and maskTextureHeight > 0 then
						local maskAspectRatio = maskTextureWidth / maskTextureHeight
						local currentMaskAspectRatio = maskWidth / maskHeight
						if currentMaskAspectRatio > maskAspectRatio then
							maskWidth = maskHeight * maskAspectRatio
						else
							maskHeight = maskWidth / maskAspectRatio
						end

						debug("Textures: Maintaining mask aspect ratio during layout update: " .. maskAspectRatio)
					else
						debug("Textures: Could not get valid dimensions for mask texture during layout update: " .. fadeTexturePath)
					end
				else
					debug("Textures: Skipping dimension check for mask aspect ratio during layout update (no valid path).")
				end
			end

			-- Update mask size and position
			frame._BCZ_artBackgroundMask:SetSize(maskWidth, maskHeight)
			frame._BCZ_artBackgroundMask:ClearAllPoints()
			frame._BCZ_artBackgroundMask:SetPoint(settings.point, frame, settings.point, settings.xOffset, settings.yOffset)
		end
	end

	-- Also update top texture
	local searchBox = self:GetSearchBox(frame)
	if searchBox then
		self:ApplyTopTexture(frame, searchBox)
	end

	-- Update close button through MiscTextures
	local MiscTextures = addon:GetCachedModule("miscTextures")
	if MiscTextures and MiscTextures.ApplyCloseButtonTexture then
		MiscTextures:ApplyCloseButtonTexture(frame)
	end
end

-- Helper function to determine if module updates should be skipped
function MainTextures:ShouldSkipUpdate()
	-- Check if we're in combat and optimization is enabled
	return InCombatLockdown() and not addon:IsAnyBagVisible()
end

-- Initialize the module
function MainTextures:Initialize()
	debug("Textures: Initializing module")
	-- Set up local cache
	self.textureDimensionsCache = {}
	-- Pre-cache dimensions for common Textures
	self:PreCacheDimensions()
	-- Make sure we have compatibility with core functions
	addon.pendingTextureCalls = addon.pendingTextureCalls or {}
	-- Function to handle bag updates with appropriate delay
	local function DelayedBagUpdate(frame, forceRebuild)
		-- Skip bank frames completely
		if addon:IsBankFrame(frame) then
			debug("Textures: Skipping delayed update for bank frame: " .. (frame:GetName() or "unnamed"))
			return
		end

		-- Cancel any existing bag update timers for this frame
		local frameName = frame:GetName() or tostring(frame)
		if addon.pendingTextureCalls[frameName] then
			addon.pendingTextureCalls[frameName]:Cancel()
			addon.pendingTextureCalls[frameName] = nil
		end

		-- Create a new timer with a short delay
		addon.pendingTextureCalls[frameName] = C_Timer.NewTimer(0.1, function()
			debug("Textures: Processing delayed bag update for " .. frameName)
			MainTextures:UpdateFrame(frame, forceRebuild)
			addon.pendingTextureCalls[frameName] = nil
		end)
	end

	-- Register with update system if it exists
	if addon.updateSystem then
		addon.updateSystem:RegisterModuleUpdate("maintextures", function(reason, immediate)
			debug("Textures: Update triggered by: " .. (reason or "unknown"))
			-- Only update regular bag frame, not bank frames
			if B.BagFrame and B.BagFrame:IsShown() and not addon:IsBankFrame(B.BagFrame) then
				-- Check if this is a first-time open that needs special handling
				local isFirstOpen = reason and (
					reason:find("first") or
					reason:find("Initial") or
					reason == "PLAYER_ENTERING_WORLD event" or
					reason == "B:OpenBags hook"
				)
				if immediate then
					self:UpdateFrame(B.BagFrame, isFirstOpen)
				else
					DelayedBagUpdate(B.BagFrame, isFirstOpen)
				end
			end
		end)
		-- Register for bag close events to clear unused Textures
		addon.updateSystem:RegisterEvent("BAG_CLOSED", function()
			if not addon:IsAnyBagVisible() then
				C_Timer.After(0.3, function()
					self:ClearUnusedTextureCache()
				end)
			end
		end)
	else
		-- Fallback if UpdateSystem not available
		addon:RegisterElementUpdate("mainTextures", function(reason, immediate)
			debug("Textures: Update triggered by: " .. (reason or "unknown"))
			-- Only update regular bag frame, not bank frames
			if B.BagFrame and B.BagFrame:IsShown() and not addon:IsBankFrame(B.BagFrame) then
				local isFirstOpen = reason and (
					reason:find("first") or
					reason:find("Initial") or
					reason == "PLAYER_ENTERING_WORLD event" or
					reason == "B:OpenBags hook"
				)
				if immediate then
					self:UpdateFrame(B.BagFrame, isFirstOpen)
				else
					DelayedBagUpdate(B.BagFrame, isFirstOpen)
				end
			end
		end)
		-- Hook bag closing for cleanup if updateSystem isn't available
		if B.CloseBags then
			hooksecurefunc(B, "CloseBags", function()
				C_Timer.After(0.3, function()
					if not addon:IsAnyBagVisible() then
						self:ClearUnusedTextureCache()
					end
				end)
			end)
		end
	end

	-- Only hook regular bag frame operations, not bank
	if B.OpenBags then
		hooksecurefunc(B, "OpenBags", function()
			if B.BagFrame and not addon:IsBankFrame(B.BagFrame) then
				debug("Textures: B.OpenBags hook triggered")
				DelayedBagUpdate(B.BagFrame, false)
			end
		end)
	end

	-- Only hook regular bag frame, not bank frame
	if B.BagFrame then
		B.BagFrame:HookScript("OnShow", function()
			if not addon:IsBankFrame(B.BagFrame) then
				debug("Textures: BagFrame OnShow triggered")
				DelayedBagUpdate(B.BagFrame, false)
			end
		end)
	end

	-- Force initial update for visible bags (only regular bags, not banks)
	C_Timer.After(1, function()
		if B.BagFrame and B.BagFrame:IsShown() and not addon:IsBankFrame(B.BagFrame) then
			self:UpdateFrame(B.BagFrame, true)
		end
	end)
	debug("Textures: Module initialized")
end

-- ADDED: Register with initialization
if addon.RegisterElement then
	addon:RegisterElement("mainTextures")
else
	-- Fallback initialization
	MainTextures:Initialize()
end

-- Return module for reference
return MainTextures
