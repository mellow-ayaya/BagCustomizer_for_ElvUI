-- InventorySlots.lua: Enhanced appearance for bag slots
-- Optimized Version with performance enhancements
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags")
local addon = E:GetModule("BagCustomizer")
-- Create module
addon.elements.inventorySlots = {}
local module = addon.elements.inventorySlots
-- Cache globals for performance
local _G = _G
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local GetTime = GetTime
local C_Timer = C_Timer
local math_min = math.min
local math_max = math.max
-- OPTIMIZATION: Add update queue system
local updateQueue = {}
local isUpdateScheduled = false
-- Cache for ElvUI highlight properties
local extractedElvUIHighlight = nil
-- Cache for assigned bags
local assignedBagsCache = {}
local assignedBagsCacheTime = 0
local CACHE_DURATION = 0.3 -- seconds
-- Color enhancement cache
local colorCache = {}
-- Track processed slots
local processedSlots = {}
-- OPTIMIZATION: Track visibility results
local visibilityCache = {}
local lastVisibilityUpdate = 0
-- Replace the local definitions with references to the core definitions
local availableTextures = addon.slotBorderTextures
local presetComponentMap = addon.slotBorderPresetMap
local presetTextures = addon.slotBorderPresets
local defaultTextures = addon.defaultSlotTextures
-- List of regions in ElvUI bag slots we need to handle
local slotRegions = {
	-- Button frame Textures
	"TopLeftCorner",
	"TopRightCorner",
	"BottomLeftCorner",
	"BottomRightCorner",
	"TopEdge",
	"BottomEdge",
	"LeftEdge",
	"RightEdge",
	"Center",
	-- Slot Textures
	"NormalTexture" }
-- Button Textures cache
local buttonTexturesCache = {}
-- Track last settings to detect changes
local lastSettings = {}
-- Last enabled state for toggle detection
local lastEnabled = nil
local lastModuleEnabled = nil
-- Simple debug function
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][inventorySlots]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.inventorySlots or
			not E.db.bagCustomizer.inventorySlots.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- Function to check if a frame is a bank frame
function module:IsBankFrame(frame)
	-- Use the core function if available
	if addon.IsBankFrame then
		return addon:IsBankFrame(frame)
	end

	-- Fallback implementation if core function isn't available
	if not frame then return false end

	local name = frame:GetName() or ""
	if name:find("Bank") or name:find("bank") then return true end

	if B and ((B.BankFrame and frame == B.BankFrame) or (B.WarbankFrame and frame == B.WarbankFrame)) then
		return true
	end

	if frame.bankID or frame.isBank or frame.bagFrameType == "BANK" then
		return true
	end

	return false
end

-- Function to check if a bag ID belongs to bank
function module:IsBankBag(bagID)
	-- If no bag ID, it's not a bank bag
	if not bagID then return false end

	-- Special case for reagent bag in player inventory
	if bagID == -3 then -- Inventory reagent bag in modern WoW
		return false
	end

	-- Special case for reagent bag (ID 5) in some WoW versions
	-- Only consider it a bank bag if it's not currently active in a player inventory frame
	if bagID == 5 then
		-- Check if this is the inventory reagent bag
		local isInventoryReagentBag = false
		-- Try to detect if this is a reagent bag in player inventory
		if B and B.BagFrame and B.BagFrame.Bags and B.BagFrame.Bags[5] then
			-- If it's visible in the player's bag frame, it's not a bank bag
			isInventoryReagentBag = true
		end

		if isInventoryReagentBag then
			return false
		end
	end

	-- Standard bank bags are 5+ (except for the special case above)
	return bagID >= 5
end

-- Function to create textures using the pool system
function module:CreatePooledTexture(parent, layer, sublayer)
	return addon:GetPooledTexture(parent, layer, sublayer)
end

-- Get the current button Textures based on selected preset (cached)
local function GetButtonTextures()
	-- Get settings
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings then return defaultTextures end

	-- Get the preset from settings
	local preset = settings.preset or "blizzard_modern"
	-- Check if we have a cached copy
	local cacheKey = preset
	-- Add any custom component selections to cache key
	if settings.BorderStyle then cacheKey = cacheKey .. "-b" .. settings.BorderStyle end

	if settings.EmptyBorderStyle then cacheKey = cacheKey .. "-eb" .. settings.EmptyBorderStyle end

	if settings.EmptyStyle then cacheKey = cacheKey .. "-e" .. settings.EmptyStyle end

	if settings.NormalStyle then cacheKey = cacheKey .. "-n" .. settings.NormalStyle end

	if settings.HighlightStyle then cacheKey = cacheKey .. "-h" .. settings.HighlightStyle end

	if buttonTexturesCache[cacheKey] then
		return buttonTexturesCache[cacheKey]
	end

	-- Start with the complete preset Textures
	local baseTextures = presetTextures[preset] or defaultTextures
	local resultTextures = {
		Normal = baseTextures.Normal,
		Border = baseTextures.Border,
		Highlight = baseTextures.Highlight,
		Empty = baseTextures.Empty,
		EmptyBorder = baseTextures.EmptyBorder or baseTextures.Border, -- Default to the same as Border
		ScaleFactor = baseTextures.ScaleFactor or 100,               -- Get scale factor from preset
	}
	-- Apply any custom component selections that exist
	if settings.BorderStyle and availableTextures.Border[settings.BorderStyle] then
		resultTextures.Border = availableTextures.Border[settings.BorderStyle]
	end

	-- Handle EmptyBorder style
	if settings.EmptyBorderStyle and availableTextures.Border[settings.EmptyBorderStyle] then
		-- User explicitly set an EmptyBorderStyle
		resultTextures.EmptyBorder = availableTextures.Border[settings.EmptyBorderStyle]
	elseif presetComponentMap[preset] and presetComponentMap[preset].EmptyBorder then
		-- Use preset's EmptyBorder if defined and no explicit override
		local emptyBorderStyle = presetComponentMap[preset].EmptyBorder
		if availableTextures.Border[emptyBorderStyle] then
			resultTextures.EmptyBorder = availableTextures.Border[emptyBorderStyle]
		end
	end

	if settings.EmptyStyle and availableTextures.Empty[settings.EmptyStyle] then
		resultTextures.Empty = availableTextures.Empty[settings.EmptyStyle]
	end

	if settings.NormalStyle and availableTextures.Normal[settings.NormalStyle] then
		resultTextures.Normal = availableTextures.Normal[settings.NormalStyle]
	end

	if settings.HighlightStyle and availableTextures.Highlight[settings.HighlightStyle] then
		resultTextures.Highlight = availableTextures.Highlight[settings.HighlightStyle]
	end

	-- Cache the result
	buttonTexturesCache[cacheKey] = resultTextures
	return resultTextures
end

-- OPTIMIZATION: Selective cache invalidation
function module:InvalidateTextureCache(componentType)
	if not componentType then
		-- If no specific component, clear entire cache
		buttonTexturesCache = {}
		return
	end

	-- Only clear cache entries containing this component
	local keysToRemove = {}
	for cacheKey in pairs(buttonTexturesCache) do
		if componentType == "preset" or cacheKey:find(componentType) then
			keysToRemove[cacheKey] = true
		end
	end

	for key in pairs(keysToRemove) do
		buttonTexturesCache[key] = nil
	end
end

-- Get assigned bags more efficiently with better caching
function module:CollectAssignedBags(forceRefresh)
	-- Only use cache if it's recent and we're not forcing refresh
	local currentTime = GetTime()
	if not forceRefresh and assignedBagsCacheTime > 0 and
			(currentTime - assignedBagsCacheTime) < CACHE_DURATION then
		return assignedBagsCache
	end

	-- Build new assigned bags data
	local assignedBags = {}
	-- Method 1: Direct DB path for bag filters - this is the most reliable
	if E.db.bags and E.db.bags.bagFilters then
		-- Only process regular bags (0-4)
		for bagID = 0, 4 do
			local filterType = E.db.bags.bagFilters[bagID]
			if filterType and filterType ~= "" then
				assignedBags[bagID] = filterType
			end
		end
	end

	-- Method 2: Use IsSpecialtyBag as a fallback
	if B.IsSpecialtyBag then
		-- Only process regular bags (0-4)
		for bagID = 0, 4 do
			if not assignedBags[bagID] then -- Only check if not already assigned
				local bagType = B:IsSpecialtyBag(bagID)
				if bagType and bagType ~= "Normal" then
					assignedBags[bagID] = bagType
				end
			end
		end
	end

	-- Store in cache with current timestamp
	assignedBagsCache = assignedBags
	assignedBagsCacheTime = currentTime
	-- Extra validation - compare with previous cache to detect major changes
	local cacheChanged = false
	if self.previousAssignedBagsCache then
		for bagID = 0, 4 do
			if assignedBags[bagID] ~= self.previousAssignedBagsCache[bagID] then
				cacheChanged = true
				break
			end
		end
	end

	-- Store the current cache for future comparison
	self.previousAssignedBagsCache = {}
	for bagID = 0, 4 do
		self.previousAssignedBagsCache[bagID] = assignedBags[bagID]
	end

	-- OPTIMIZATION: Batch updates when bag assignments change
	if cacheChanged then
		self:ResetCache()
		-- Queue all buttons for update instead of forcing immediate updates
		self:BatchUpdateButtons(true)
	end

	return assignedBags
end

-- OPTIMIZATION: Batch button updates
function module:BatchUpdateButtons(forceUpdate)
	if not addon:IsAnyBagVisible() then return end

	local count = 0
	for button in pairs(processedSlots) do
		if button and button:IsVisible() and button._BCZ then
			-- Skip bank slots
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			-- Skip if this is a bank bag
			if bagID and self:IsBankBag(bagID) then
				-- Skip bank bags
				return
			end

			-- Skip if button is in a bank frame
			if button:GetParent() and self:IsBankFrame(button:GetParent()) then
				return
			end

			if forceUpdate then
				button._BCZ_forceUpdate = true
			end

			self:QueueButtonForUpdate(button)
			count = count + 1
		end
	end

	debug("InventorySlots: Queued " .. count .. " buttons for batch update")
end

-- OPTIMIZATION: Queue button for update
function module:QueueButtonForUpdate(button)
	if not button then return end

	-- Skip bank slots
	local bagID = button.bagID
	if not bagID and button:GetParent() and button:GetParent():GetID() then
		bagID = button:GetParent():GetID()
	end

	-- Skip if this is a bank bag
	if bagID and self:IsBankBag(bagID) then
		return
	end

	-- Skip if button is in a bank frame
	if button:GetParent() and self:IsBankFrame(button:GetParent()) then
		return
	end

	updateQueue[button] = true
	if not isUpdateScheduled then
		isUpdateScheduled = true
		C_Timer.After(0.01, function()
			self:ProcessUpdateQueue()
		end)
	end
end

-- OPTIMIZATION: Process queued updates
function module:ProcessUpdateQueue()
	local count = 0
	local startTime = GetTime()
	local timeLimit = 0.016 -- About 1 frame at 60fps
	for button in pairs(updateQueue) do
		if button and button._BCZ and self:IsSlotVisible(button) then
			-- Skip bank slots
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			-- Skip if this is a bank bag
			if bagID and self:IsBankBag(bagID) then
				updateQueue[button] = nil
				return
			end

			-- Skip if button is in a bank frame
			if button:GetParent() and self:IsBankFrame(button:GetParent()) then
				updateQueue[button] = nil
				return
			end

			self:UpdateSlot(button)
			count = count + 1
		end

		updateQueue[button] = nil
		-- Check if we're taking too long and need to split work
		if count % 10 == 0 and (GetTime() - startTime) > timeLimit then
			break
		end
	end

	-- Check if we need another frame to finish updates
	if next(updateQueue) then
		C_Timer.After(0.01, function()
			self:ProcessUpdateQueue()
		end)
	else
		isUpdateScheduled = false
	end

	debug("InventorySlots: Processed " .. count .. " queued updates")
end

-- Pre-calculate assigned bag colors for performance
function module:InitializeColors()
	local settings = E.db.bagCustomizer.inventorySlots
	self.commonColors = {
		empty = {
			r = settings.emptySlotColor and settings.emptySlotColor.r or 1.0,
			g = settings.emptySlotColor and settings.emptySlotColor.g or 1.0,
			b = settings.emptySlotColor and settings.emptySlotColor.b or 1.0,
			a = settings.emptySlotOpacity or 1,
		},
	}
	-- Pre-calculate some assigned bag colors for cache acceleration
	self.cachedFilterColors = {}
	if E.db.bags and E.db.bags.bagFilters then
		-- Only process regular bags (0-4)
		for bagID = 0, 4 do
			local filterType = E.db.bags.bagFilters[bagID]
			if filterType and filterType ~= "" then
				local r, g, b = self:GetAssignedBagColor(filterType)
				if not self.cachedFilterColors[filterType] then
					self.cachedFilterColors[filterType] = { r = r, g = g, b = b }
				end
			end
		end
	end
end

-- Get the color for an assigned bag based on filter type
function module:GetAssignedBagColor(filterType)
	-- Check our pre-calculated color cache first
	if self.cachedFilterColors and self.cachedFilterColors[filterType] then
		local color = self.cachedFilterColors[filterType]
		return color.r, color.g, color.b
	end

	-- Default color (white) if we can't determine the type
	local r, g, b = 1, 1, 1
	-- For quest items
	if type(filterType) == "string" and
			(filterType == "QuestItems" or filterType == "Quest") then
		if B.QuestColors and B.QuestColors.questItem then
			return B.QuestColors.questItem.r, B.QuestColors.questItem.g,
					B.QuestColors.questItem.b
		end
	end

	-- For reagent bags
	if type(filterType) == "string" and
			(filterType == "Reagent" or filterType == "Reagents") then
		if B.ProfessionColors and B.BagIndice and B.BagIndice.reagent then
			local color = B.ProfessionColors[B.BagIndice.reagent]
			if color then return color.r, color.g, color.b end
		elseif E.db.bags.colors and E.db.bags.colors.profession and
				E.db.bags.colors.profession.reagent then
			local color = E.db.bags.colors.profession.reagent
			return color.r, color.g, color.b
		end
	end

	-- For standard bag assignments
	if B.AssignmentColors then
		-- Try to map string filter types to numeric flags
		local flag = nil
		if type(filterType) == "string" then
			if filterType == "Equipment" or filterType == "EquipmentSet" then
				flag = FILTER_FLAG_EQUIPMENT
			elseif filterType == "Consumable" or filterType == "Consumables" then
				flag = FILTER_FLAG_CONSUMABLES
			elseif filterType == "TradeGoods" then
				flag = FILTER_FLAG_TRADE_GOODS
			elseif filterType == "Junk" then
				flag = FILTER_FLAG_JUNK
			end
		else
			flag = filterType -- If it's already a numeric flag
		end

		-- Try to get color from assignment colors
		if flag and B.AssignmentColors[flag] then
			local color = B.AssignmentColors[flag]
			return color.r, color.g, color.b
		end
	end

	-- Fall back to direct ElvUI colors
	if type(filterType) == "string" and E.db.bags.colors and
			E.db.bags.colors.assignment then
		local lowerFilter = filterType:lower()
		for colorKey, colorValue in pairs(E.db.bags.colors.assignment) do
			if lowerFilter == colorKey:lower() then
				return colorValue.r, colorValue.g, colorValue.b
			end
		end
	end

	-- Return default white color
	return r, g, b
end

-- New function to enhance colors (make more vivid)
function module:EnhanceColors(r, g, b, intensity)
	-- Default intensity if not specified
	intensity = intensity or 1.0
	-- Generate a cache key
	local cacheKey = string.format("%.3f_%.3f_%.3f_%.3f", r, g, b, intensity)
	-- Check cache first
	if colorCache[cacheKey] then
		return unpack(colorCache[cacheKey])
	end

	-- Calculate how far each component is from gray (0.5)
	local rDist = r - 0.5
	local gDist = g - 0.5
	local bDist = b - 0.5
	-- Amplify this distance, which makes colors more vivid
	r = 0.5 + rDist * intensity
	g = 0.5 + gDist * intensity
	b = 0.5 + bDist * intensity
	-- Clamp values between 0 and 1
	r = math_max(0, math_min(1, r))
	g = math_max(0, math_min(1, g))
	b = math_max(0, math_min(1, b))
	-- Store in cache
	colorCache[cacheKey] = { r, g, b }
	return r, g, b
end

-- Apply global brightness to any color
function module:ApplyGlobalBrightness(r, g, b)
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings then
		return r, g, b -- No change if no settings
	end

	-- Apply global brightness as a percentage
	if settings.globalBrightness ~= nil then
		local brightness = settings.globalBrightness / 100
		r = math_min(r * brightness, 1)
		g = math_min(g * brightness, 1)
		b = math_min(b * brightness, 1)
	end

	-- Apply color intensity if enabled
	if settings.globalColorIntensity ~= nil and settings.globalColorIntensity > 100 then
		local intensity = settings.globalColorIntensity / 100
		r, g, b = self:EnhanceColors(r, g, b, intensity)
	end

	return r, g, b
end

-- Apply brightness to empty slot colors
function module:ApplyEmptySlotBrightness(r, g, b, isAssigned)
	local settings = E.db.bagCustomizer.inventorySlots
	-- For unassigned slots, just apply global adjustments
	if not isAssigned then
		return self:ApplyGlobalBrightness(r, g, b)
	end

	-- For assigned slots, apply brightness
	if not settings.emptySlotBrightness then
		settings.emptySlotBrightness = {
			assigned = 100,
		}
	end

	-- Apply brightness to assigned slots
	local brightness = (settings.emptySlotBrightness.assigned or 100) / 100
	r = math_min(r * brightness, 1)
	g = math_min(g * brightness, 1)
	b = math_min(b * brightness, 1)
	-- Apply color intensity if available
	if settings.emptySlotColorIntensity and settings.emptySlotColorIntensity.assigned then
		local intensity = settings.emptySlotColorIntensity.assigned
		if intensity > 100 then
			intensity = intensity / 100
			r, g, b = self:EnhanceColors(r, g, b, intensity)
		end
	end

	-- Apply global adjustments
	return self:ApplyGlobalBrightness(r, g, b)
end

-- Apply brightness and color to empty slot textures
function module:ApplyEmptySlotTextureSettings(button, isAssigned, filterType)
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings or not button._BCZ then return end

	-- Get base alpha value for all empty slots
	local baseAlpha = settings.emptySlotTextureAlpha or 1.0
	-- Apply base alpha to the button art frame
	if button._BCZ.buttonArt then
		button._BCZ.buttonArt:SetAlpha(baseAlpha)
	end

	-- Keep border at full opacity
	if button._BCZ.borderFrame then
		button._BCZ.borderFrame:SetAlpha(1)
	end

	local emptyTexture = button._BCZ.emptyTexture
	-- Set default color (white)
	local r, g, b = 1, 1, 1
	-- Handle assigned bag coloring
	if settings.colorEmptySlotsByAssignment and isAssigned and filterType then
		-- Get the color for this assigned bag
		r, g, b = self:GetAssignedBagColor(filterType)
		-- Apply brightness adjustment (using the remaining assigned brightness setting)
		local brightness = 100
		if settings.emptySlotTextureBrightness and settings.emptySlotTextureBrightness.assigned then
			brightness = settings.emptySlotTextureBrightness.assigned
		end

		brightness = brightness / 100
		r = math_min(r * brightness, 1)
		g = math_min(g * brightness, 1)
		b = math_min(b * brightness, 1)
		-- Apply global brightness
		r, g, b = self:ApplyGlobalBrightness(r, g, b)
		-- Apply assigned slot specific alpha for the color overlay
		local colorAlpha = settings.emptySlotAlphaAssigned or 1.0
		-- Apply the color with assigned alpha value
		emptyTexture:SetVertexColor(r, g, b, 1)
		emptyTexture:SetAlpha(colorAlpha) -- This controls the opacity of the colored overlay
	else
		-- For unassigned slots, use full color but respect base alpha
		emptyTexture:SetVertexColor(1, 1, 1, 1)
		emptyTexture:SetAlpha(baseAlpha)
	end
end

-- Initialize brightness and color intensity settings
function module:InitializeBrightnessSettings()
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings then
		settings = {}
		E.db.bagCustomizer.inventorySlots = settings
	end

	-- Initialize texture alpha setting
	if settings.textureAlpha == nil then
		settings.textureAlpha = 1.0 -- Default to 100% opacity
	end

	-- Initialize global brightness
	if settings.globalBrightness == nil then
		settings.globalBrightness = 100 -- Default 100%
	end

	-- Initialize global color intensity
	if settings.globalColorIntensity == nil then
		settings.globalColorIntensity = 100 -- Default 100%
	end

	-- Initialize individual brightnesses toggle
	if settings.showIndividualBrightness == nil then
		settings.showIndividualBrightness = false -- Hidden by default
	end

	-- Initialize individual color intensity toggle
	if settings.showIndividualColorIntensity == nil then
		settings.showIndividualColorIntensity = false -- Hidden by default
	end

	-- Initialize empty slot brightness settings
	if not settings.emptySlotBrightness then
		settings.emptySlotBrightness = {
			unassigned = 100, -- Default 100%
			assigned = 100, -- Default 100%
		}
	else
		-- Make sure both properties exist
		if settings.emptySlotBrightness.unassigned == nil then
			settings.emptySlotBrightness.unassigned = 100
		end

		if settings.emptySlotBrightness.assigned == nil then
			settings.emptySlotBrightness.assigned = 100
		end
	end

	-- Initialize empty slot color intensity settings
	if not settings.emptySlotColorIntensity then
		settings.emptySlotColorIntensity = {
			unassigned = 100, -- Default 100%
			assigned = 100, -- Default 100%
		}
	else
		-- Make sure both properties exist
		if settings.emptySlotColorIntensity.unassigned == nil then
			settings.emptySlotColorIntensity.unassigned = 100
		end

		if settings.emptySlotColorIntensity.assigned == nil then
			settings.emptySlotColorIntensity.assigned = 100
		end
	end

	-- Initialize quality brightness settings if needed
	if not settings.qualityBrightness then
		settings.qualityBrightness = {}
	end

	-- Set defaults for all item qualities (0-7)
	for i = 0, 7 do
		if settings.qualityBrightness[i] == nil then
			settings.qualityBrightness[i] = 100
		end
	end

	-- Initialize global scale factor
	if settings.globalScaleFactor == nil then
		settings.globalScaleFactor = 1.0 -- Default 100%
	end

	-- Initialize quality color intensity settings
	if not settings.qualityColorIntensity then
		settings.qualityColorIntensity = {}
	end

	-- Set defaults for all item qualities (0-7)
	for i = 0, 7 do
		if settings.qualityColorIntensity[i] == nil then
			settings.qualityColorIntensity[i] = 100
		end
	end

	-- Add new settings for separate empty slot borders
	if settings.separateEmptyBorder == nil then
		settings.separateEmptyBorder = false
	end

	-- Store current settings to detect changes
	self:SaveCurrentSettings()
	-- Debug the values to help troubleshoot
	debug("InventorySlots: Color settings initialized - " ..
		"Global Brightness=" .. (settings.globalBrightness or "nil") ..
		", Global Color Intensity=" .. (settings.globalColorIntensity or "nil"))
end

-- Save current settings state to detect changes
function module:SaveCurrentSettings()
	if not E.db.bagCustomizer or not E.db.bagCustomizer.inventorySlots then return end

	local settings = E.db.bagCustomizer.inventorySlots
	lastSettings = {
		enable = settings.enable,
		preset = settings.preset,
		BorderStyle = settings.BorderStyle,
		EmptyBorderStyle = settings.EmptyBorderStyle,
		EmptyStyle = settings.EmptyStyle,
		NormalStyle = settings.NormalStyle,
		HighlightStyle = settings.HighlightStyle,
		separateEmptyBorder = settings.separateEmptyBorder,
		applyMainBorderToEmptyAssigned = settings.applyMainBorderToEmptyAssigned,
	}
	-- Also store global enabled state
	lastEnabled = E.db.bagCustomizer and E.db.bagCustomizer.enabled
	lastModuleEnabled = settings.enable
end

-- Check if settings have changed
function module:HaveSettingsChanged()
	if not E.db.bagCustomizer or not E.db.bagCustomizer.inventorySlots then
		return lastEnabled ~= nil or lastModuleEnabled ~= nil
	end

	local settings = E.db.bagCustomizer.inventorySlots
	-- Check for enabled state changes
	if lastEnabled ~= (E.db.bagCustomizer and E.db.bagCustomizer.enabled) or
			lastModuleEnabled ~= settings.enable then
		return true
	end

	-- Check for style changes
	if lastSettings.preset ~= settings.preset or
			lastSettings.BorderStyle ~= settings.BorderStyle or
			lastSettings.EmptyBorderStyle ~= settings.EmptyBorderStyle or
			lastSettings.EmptyStyle ~= settings.EmptyStyle or
			lastSettings.NormalStyle ~= settings.NormalStyle or
			lastSettings.HighlightStyle ~= settings.HighlightStyle or
			lastSettings.separateEmptyBorder ~= settings.separateEmptyBorder or
			lastSettings.applyMainBorderToEmptyAssigned ~= settings.applyMainBorderToEmptyAssigned then
		return true
	end

	return false
end

-- Update all border colors when brightness or color intensity setting change
function module:UpdateAllColorSettings()
	-- OPTIMIZATION: Only mark buttons for update instead of forcing updates
	for button in pairs(processedSlots) do
		if button and button._BCZ then
			-- Skip bank slots
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			-- Skip if this is a bank bag
			if bagID and self:IsBankBag(bagID) then
				return
			end

			-- Skip if button is in a bank frame
			if button:GetParent() and self:IsBankFrame(button:GetParent()) then
				return
			end

			button._BCZ_forceUpdate = true
			-- Clear cached border colors
			button._BCZ.lastBorderR = nil
			button._BCZ.lastBorderG = nil
			button._BCZ.lastBorderB = nil
			self:QueueButtonForUpdate(button)
		end
	end

	-- Clear color cache
	colorCache = {}
	-- OPTIMIZATION: Batch scale factor updates
	self:UpdateAllScaleFactors()
end

-- For backward compatibility
function module:UpdateAllBrightness()
	self:UpdateAllColorSettings()
end

-- Update border colors (also for backward compatibility)
function module:UpdateBorderColors()
	self:UpdateAllColorSettings()
end

-- Apply all color adjustments (brightness and intensity) based on item quality
function module:ApplyBrightnessToColor(r, g, b, button)
	if not E.db.bagCustomizer.inventorySlots then
		return r, g, b
	end

	local settings = E.db.bagCustomizer.inventorySlots
	local quality = button.quality or button.rarity
	-- First apply quality-specific brightness if available
	if quality and settings.qualityBrightness and
			settings.qualityBrightness[quality] ~= nil then
		local qualityBrightness = settings.qualityBrightness[quality]
		local brightness = qualityBrightness / 100
		-- Apply quality-specific brightness
		r = math_min(r * brightness, 1)
		g = math_min(g * brightness, 1)
		b = math_min(b * brightness, 1)
	end

	-- Apply quality-specific color intensity if available
	if quality and settings.qualityColorIntensity and
			settings.qualityColorIntensity[quality] ~= nil then
		local qualityIntensity = settings.qualityColorIntensity[quality]
		if qualityIntensity > 100 then
			local intensity = qualityIntensity / 100
			r, g, b = self:EnhanceColors(r, g, b, intensity)
		end
	end

	-- Then apply global adjustments
	return self:ApplyGlobalBrightness(r, g, b)
end

-- Get ElvUI highlight properties
function module:GetElvUIHighlightProperties()
	-- Return cached values if we already extracted them
	if extractedElvUIHighlight then
		return extractedElvUIHighlight
	end

	-- Try to find an ElvUI-styled button to extract from
	local sampleButtons = {
		_G["ElvUI_BarPet1"], _G["ElvUI_Bar1Button1"], _G["ElvUIBag0"], _G["ElvUI_ChatButton1"] }
	-- Try each potential button until we find one
	for _, button in ipairs(sampleButtons) do
		if button and button:GetHighlightTexture() then
			local highTex = button:GetHighlightTexture()
			local texture = highTex:GetTexture()
			local r, g, b, a = highTex:GetVertexColor()
			local blendMode = highTex:GetBlendMode()
			-- Cache the extracted properties
			extractedElvUIHighlight = {
				texture = texture or E.media.blankTex,
				color = { r = r or 1, g = g or 1, b = b or 1, a = a or 0.3 },
				blendMode = blendMode or "ADD",
			}
			return extractedElvUIHighlight
		end
	end

	-- Fallback to using ElvUI's media values if extraction fails
	extractedElvUIHighlight = {
		texture = E.media.blankTex,
		color = {
			r = E.media.rgbvaluecolor[1],
			g = E.media.rgbvaluecolor[2],
			b = E.media.rgbvaluecolor[3],
			a = 0.3,
		},
		blendMode = "ADD",
	}
	return extractedElvUIHighlight
end

-- Configure highlight system for a button
function module:ToggleHighlightSystem(button, useElvUI)
	if not button or not button._BCZ then return end

	-- Remove any existing highlight texture completely
	if button:GetHighlightTexture() then
		button:SetHighlightTexture("")
	end

	if useElvUI then
		-- Get ElvUI's highlight properties
		local hlProps = self:GetElvUIHighlightProperties()
		-- Apply ElvUI-style highlight
		button:SetHighlightTexture(hlProps.texture)
		local highTex = button:GetHighlightTexture()
		if highTex then
			highTex:SetVertexColor(hlProps.color.r, hlProps.color.g, hlProps.color.b, hlProps.color.a)
			highTex:SetBlendMode(hlProps.blendMode)
			highTex:SetAllPoints()
		end

		-- Hide our custom highlight
		if button._BCZ.highlightTexture then
			button._BCZ.highlightTexture:Hide()
		end
	else
		-- Use our custom highlight system - Blank out ElvUI's highlight
		button:SetHighlightTexture("Interface\\AddOns\\ElvUI\\Core\\Media\\Textures\\Blank")
		local highTex = button:GetHighlightTexture()
		if highTex then
			highTex:SetAlpha(0)
		end

		-- Make sure our custom highlight is ready
		if button._BCZ.highlightTexture then
			-- Just apply current texture to make sure it's updated
			button._BCZ.highlightTexture:SetTexture(GetButtonTextures().Highlight)
		end
	end
end

-- Main function for button skinning
function module:SkinButton(button)
	-- Skip if addon is disabled globally or module is disabled
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then return end

	-- Skip if this is a bank bag or bank frame
	local bagID = button.bagID
	if not bagID and button:GetParent() and button:GetParent():GetID() then
		bagID = button:GetParent():GetID()
	end

	-- Skip if this is a bank bag
	if bagID and self:IsBankBag(bagID) then
		return
	end

	-- Skip if button is in a bank frame
	if button:GetParent() and self:IsBankFrame(button:GetParent()) then
		return
	end

	-- Get current settings
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings or not settings.enable then return end

	-- Get current texture set
	local currentTextures = GetButtonTextures()
	-- Skip if already processed with current preset UNLESS force flag is set
	local style = settings.style or "Rounded"
	local preset = settings.preset or "blizzard_modern"
	-- Include the highlight setting in buttonState
	local buttonState = style ..
			"-" .. preset .. "-" .. (settings.disableElvUIHighlight and "noHighlight" or "highlight")
	-- Add style components to buttonState to detect individual style changes
	if settings.BorderStyle then buttonState = buttonState .. "-b" .. settings.BorderStyle end

	if settings.EmptyBorderStyle then buttonState = buttonState .. "-eb" .. settings.EmptyBorderStyle end

	if settings.EmptyStyle then buttonState = buttonState .. "-e" .. settings.EmptyStyle end

	if settings.NormalStyle then buttonState = buttonState .. "-n" .. settings.NormalStyle end

	if settings.HighlightStyle then buttonState = buttonState .. "-h" .. settings.HighlightStyle end

	-- Only skip if not forcing update and already processed with current style
	if not button._BCZ_forceUpdate and
			processedSlots[button] == buttonState and
			button._BCZ and
			button._BCZ.lastPreset == preset then
		return
	end

	-- Clear the force update flag
	button._BCZ_forceUpdate = nil
	-- Mark as processed with current style and preset
	processedSlots[button] = buttonState
	-- Store original state
	button._BCZ = button._BCZ or {}
	button._BCZ.hidden = button._BCZ.hidden or {}
	button._BCZ.state = "initial"
	-- Store original highlight texture if we haven't already
	if button:GetHighlightTexture() and not button._BCZ.originalHighlight then
		local highTex = button:GetHighlightTexture()
		if highTex then
			button._BCZ.originalHighlight = {
				texture = highTex:GetTexture(),
				alpha = highTex:GetAlpha(),
				blendMode = highTex:GetBlendMode(),
			}
		end
	end

	-- CREATE FRAMES before creating Textures
	-- 1. Create button art frame (below everything)
	if not button._BCZ.buttonArt then
		button._BCZ.buttonArt = CreateFrame("Frame", nil, button)
		button._BCZ.buttonArt:SetFrameStrata(button:GetFrameStrata())
		button._BCZ.buttonArt:SetFrameLevel(button:GetFrameLevel() - 1)
		-- Apply scale factor right at creation
		local scaleFactor = settings.globalScaleFactor or 1.0
		button._BCZ.buttonArt:ClearAllPoints()
		button._BCZ.buttonArt:SetPoint("CENTER", button, "CENTER", 0, 0)
		button._BCZ.buttonArt:SetSize(button:GetWidth() * scaleFactor, button:GetHeight() * scaleFactor)
		-- Apply custom alpha if slot is empty
		if not button.hasItem and settings.emptySlotTextureAlpha then
			button._BCZ.buttonArt:SetAlpha(settings.emptySlotTextureAlpha)
		end
	end

	-- 2. Create border frame (above everything else)
	if not button._BCZ.borderFrame then
		button._BCZ.borderFrame = CreateFrame("Frame", nil, button)
		button._BCZ.borderFrame:SetFrameLevel(button:GetFrameLevel() + 0) -- lowered from +15 to +2
		button._BCZ.borderFrame:SetAllPoints()
	end

	-- Create Textures and configure the button
	-- Create our custom highlight texture
	if not button._BCZ.highlightTexture then
		button._BCZ.highlightTexture = button._BCZ.borderFrame:CreateTexture(nil, "ARTWORK", nil, 6)
		button._BCZ.highlightTexture:SetAllPoints()
		button._BCZ.highlightTexture:SetTexture(currentTextures.Highlight)
		button._BCZ.highlightTexture:SetVertexColor(1, 1, 1, 1)
		button._BCZ.highlightTexture:Hide() -- Default hidden
	else
		button._BCZ.highlightTexture:SetTexture(currentTextures.Highlight)
	end

	-- Create standard button Textures
	-- 1. Background/normal texture replacement
	if not button._BCZ.normalTexture then
		button._BCZ.normalTexture = button._BCZ.buttonArt:CreateTexture(nil, "BACKGROUND")
		button._BCZ.normalTexture:SetAllPoints()
	end

	button._BCZ.normalTexture:SetTexture(currentTextures.Normal)
	button._BCZ.normalTexture:SetVertexColor(1, 1, 1, 1)                                     -- Keep vertex color at full
	button._BCZ.normalTexture:SetAlpha(E.db.bagCustomizer.inventorySlots.textureAlpha or 1.0) -- Apply global alpha
	button._BCZ.normalTexture:Show()
	-- 2. Empty slot texture (shows when slot is empty)
	if not button._BCZ.emptyTexture then
		button._BCZ.emptyTexture = button._BCZ.buttonArt:CreateTexture(nil, "ARTWORK", nil, 2)
		button._BCZ.emptyTexture:SetAllPoints()
		button._BCZ.emptyTexture:Hide() -- Default hidden
	end

	button._BCZ.emptyTexture:SetTexture(currentTextures.Empty)
	button._BCZ.emptyTexture:SetVertexColor(1, 1, 1, 1) -- Ensure full opacity
	-- 3. Border texture
	if not button._BCZ.borderTexture then
		button._BCZ.borderTexture = button._BCZ.borderFrame:CreateTexture(nil, "ARTWORK", nil, 4)
		button._BCZ.borderTexture:SetAllPoints()
	end

	button._BCZ.borderTexture:SetTexture(currentTextures.Border)
	button._BCZ.borderTexture:SetVertexColor(1, 1, 1, 1) -- Ensure full opacity
	button._BCZ.borderTexture:Show()                    -- Show by default
	-- Get all texture regions in the button - Just the basic frame parts
	local regions = {}
	for _, regionName in ipairs(slotRegions) do
		if button[regionName] then
			regions[regionName] = button[regionName]
		end
	end

	-- Hide the original frame Textures
	for name, region in pairs(regions) do
		if region.SetTexture then
			-- Store original texture if we don't have it yet
			if not button._BCZ.hidden[name] then
				button._BCZ.hidden[name] = {
					texture = region:GetTexture(),
					shownState = region:IsShown(),
					alpha = region:GetAlpha(),
				}
			end

			-- Hide this texture
			region:SetTexture(nil)
			region:SetAlpha(0)
			region:Hide()
		end
	end

	-- Set up highlight functionality
	if not button._BCZ.highlightHooked then
		-- Hook mouse events for our custom highlight
		button:HookScript("OnEnter", function()
			if button._BCZ and button._BCZ.highlightTexture and
					settings.disableElvUIHighlight then
				button._BCZ.highlightTexture:Show()
			end
		end)
		button:HookScript("OnLeave", function()
			if button._BCZ and button._BCZ.highlightTexture then
				button._BCZ.highlightTexture:Hide()
			end
		end)
		button._BCZ.highlightHooked = true
	end

	-- Configure highlight system for this button
	self:ToggleHighlightSystem(button, not settings.disableElvUIHighlight)
	-- Handle the item texture (icon)
	self:HandleItemTexture(button)
	-- Update current slot state
	self:UpdateSlot(button)
	-- Hook into ElvUI's update functions for this button
	if not button._BCZ.updateHooked and button.UpdateSlotInfo then
		hooksecurefunc(button, "UpdateSlotInfo", function(self)
			module:QueueButtonForUpdate(self)
		end)
		button._BCZ.updateHooked = true
	end

	-- Hook the IconBorder specifically
	if button.IconBorder and not button._BCZ.iconBorderHooked then
		button.IconBorder:HookScript("OnShow", function()
			if button._BCZ and button._BCZ.borderTexture then
				-- Check quality to exclude common items from ElvUI colors
				local quality = button.quality or button.rarity
				if quality == 1 then
					-- For common items, check if borders should be visible
					local settings = E.db.bagCustomizer.inventorySlots
					local r, g, b = 1, 1, 1
					local alpha = 0 -- Default alpha 0 (invisible)
					if settings.showCommonQualityBorders then
						alpha = 1 -- Show border only if option enabled
						if settings.commonQualityColor then
							r, g, b = settings.commonQualityColor.r, settings.commonQualityColor.g,
									settings.commonQualityColor.b
						end
					end

					-- Apply brightness adjustment
					r, g, b = module:ApplyBrightnessToColor(r, g, b, button)
					button._BCZ.borderTexture:SetVertexColor(r, g, b, alpha)
					button._BCZ.borderTexture:Show() -- Keep texture active but transparent
				else
					-- For other qualities, use ElvUI colors
					local r, g, b = button.IconBorder:GetVertexColor()
					if r and g and b then
						-- Apply brightness adjustment
						r, g, b = module:ApplyBrightnessToColor(r, g, b, button)
						button._BCZ.borderTexture:SetVertexColor(r, g, b, 1)
					end

					button._BCZ.borderTexture:Show()
				end
			end
		end)
		button.IconBorder:HookScript("OnHide", function()
			if button._BCZ and button._BCZ.borderTexture and not button.hasItem then
				-- Only hide if it's not an empty slot
				button._BCZ.borderTexture:Hide()
			end
		end)
		button._BCZ.iconBorderHooked = true
	end

	-- Apply scale factor
	self:ApplyScaleToButton(button)
	-- Store current preset to detect changes
	button._BCZ.lastPreset = preset
end

-- Handle the item icon texture
function module:HandleItemTexture(button)
	local iconTexture = button.icon or button.IconTexture
	if not iconTexture then return end

	-- Store original icon texture state if we haven't already
	if not button._BCZ.iconOriginal then
		button._BCZ.iconOriginal = {
			texCoord = { iconTexture:GetTexCoord() },
			points = {},
		}
		-- Store original points
		local numPoints = iconTexture:GetNumPoints()
		for i = 1, numPoints do
			local point, relativeTo, relativePoint, xOfs, yOfs = iconTexture:GetPoint(i)
			button._BCZ.iconOriginal.points[i] = {
				point, relativeTo, relativePoint, xOfs, yOfs }
		end
	end

	-- Get settings and current Textures
	local settings = E.db.bagCustomizer.inventorySlots
	local currentTextures = GetButtonTextures()
	local scaleFactor = settings.globalScaleFactor or 1.0
	-- Create a container frame for the icon that can be scaled
	if not button._BCZ.iconContainer then
		button._BCZ.iconContainer = CreateFrame("Frame", nil, button)
		button._BCZ.iconContainer:SetFrameStrata(button:GetFrameStrata())
		button._BCZ.iconContainer:SetFrameLevel(button:GetFrameLevel()) -- Same as button, not above
		button._BCZ.iconContainer:SetPoint("CENTER", button, "CENTER", 0, 0)
		button._BCZ.iconContainer:SetSize(button:GetWidth(), button:GetHeight())
	end

	-- Apply current scale to the container
	button._BCZ.iconContainer:SetSize(button:GetWidth() * scaleFactor, button:GetHeight() * scaleFactor)
	-- Create our own icon texture inside the container
	if not button._BCZ.customIcon then
		button._BCZ.customIcon = button._BCZ.iconContainer:CreateTexture(nil, "ARTWORK")
		button._BCZ.customIcon:SetAllPoints(button._BCZ.iconContainer)
		button._BCZ.customIcon:SetTexture(iconTexture:GetTexture())
		-- Add ElvUI's standard icon crop to remove the built-in borders
		button._BCZ.customIcon:SetTexCoord(0.046, 0.954, 0.046, 0.954)
		-- Create a mask for our custom icon
		button._BCZ.iconMask = button._BCZ.iconContainer:CreateMaskTexture()
		button._BCZ.iconMask:SetAllPoints(button._BCZ.iconContainer)
		button._BCZ.iconMask:SetTexture(currentTextures.Normal)
		-- Apply the mask to our custom icon
		button._BCZ.customIcon:AddMaskTexture(button._BCZ.iconMask)
	else
		-- Update the custom icon with current texture
		button._BCZ.customIcon:SetTexture(iconTexture:GetTexture())
		-- Update the mask texture
		if button._BCZ.iconMask then
			button._BCZ.iconMask:SetTexture(currentTextures.Normal)
		end
	end

	-- Hide the original icon
	iconTexture:SetAlpha(0)
	-- Create a unique update function for this specific texture
	if not button._BCZ.iconUpdateFunc then
		button._BCZ.iconUpdateFunc = function()
			self:UpdateItemTexture(button)
		end
		-- Hook SetTexture to maintain our customization
		hooksecurefunc(iconTexture, "SetTexture", button._BCZ.iconUpdateFunc)
	end
end

-- Update the item texture
function module:UpdateItemTexture(button)
	if not button or not button._BCZ then return end

	local iconTexture = button.icon or button.IconTexture
	if not iconTexture or not button._BCZ.customIcon then return end

	-- If the original icon's texture changes, update our custom icon
	if iconTexture:GetTexture() then
		button._BCZ.customIcon:SetTexture(iconTexture:GetTexture())
		-- Re-apply the ElvUI standard crop when texture updates
		button._BCZ.customIcon:SetTexCoord(0.046, 0.954, 0.046, 0.954)
	end
end

-- Apply scale factor to a button's custom elements
function module:ApplyScaleToButton(button)
	if not button or not button._BCZ then return end

	local settings = E.db.bagCustomizer.inventorySlots
	if not settings then return end

	-- Get base scale factor
	local scaleFactor = settings.globalScaleFactor or 1.0
	-- Add the correct button spacing to the effective scale factor
	local spacing = (E.db.bags.bagButtonSpacing or 2) - 1     -- This is the correct path!
	local effectiveScaleFactor = scaleFactor + (spacing / 100) -- Convert spacing to decimal
	debug("Applying scale: base=" .. tostring(scaleFactor) ..
		", spacing=" .. tostring(spacing) ..
		", effective=" .. tostring(effectiveScaleFactor))
	-- Scale the button art frame using the EFFECTIVE scale factor
	if button._BCZ.buttonArt then
		button._BCZ.buttonArt:ClearAllPoints()
		button._BCZ.buttonArt:SetPoint("CENTER", button, "CENTER", 0, 0)
		local width, height = button:GetWidth(), button:GetHeight()
		button._BCZ.buttonArt:SetSize(width * effectiveScaleFactor, height * effectiveScaleFactor)
	end

	-- Apply the same effective scale to other components
	if button._BCZ.borderFrame then
		button._BCZ.borderFrame:ClearAllPoints()
		button._BCZ.borderFrame:SetPoint("CENTER", button, "CENTER", 0, 0)
		local width, height = button:GetWidth(), button:GetHeight()
		button._BCZ.borderFrame:SetSize(width * effectiveScaleFactor, height * effectiveScaleFactor)
	end

	if button._BCZ.iconContainer then
		button._BCZ.iconContainer:ClearAllPoints()
		button._BCZ.iconContainer:SetPoint("CENTER", button, "CENTER", 0, 0)
		button._BCZ.iconContainer:SetSize(button:GetWidth() * effectiveScaleFactor, button:GetHeight() * effectiveScaleFactor)
		if button._BCZ.iconMask then
			local currentTextures = GetButtonTextures()
			button._BCZ.iconMask:SetTexture(currentTextures.Normal)
		end
	end

	-- Make sure all textures fill their frames
	if button._BCZ.normalTexture then button._BCZ.normalTexture:SetAllPoints(button._BCZ.buttonArt) end

	if button._BCZ.emptyTexture then button._BCZ.emptyTexture:SetAllPoints(button._BCZ.buttonArt) end

	if button._BCZ.borderTexture then button._BCZ.borderTexture:SetAllPoints(button._BCZ.borderFrame) end

	if button._BCZ.highlightTexture then button._BCZ.highlightTexture:SetAllPoints(button._BCZ.borderFrame) end
end

-- OPTIMIZATION: Batch update for all scale factors
function module:UpdateAllScaleFactors()
	debug("InventorySlots: Updating all scale factors - IMMEDIATE")
	-- Force complete texture cache invalidation for scale changes
	buttonTexturesCache = {}
	-- Force immediate scale update for all buttons
	for button in pairs(processedSlots) do
		if button and button._BCZ then
			-- Skip bank slots
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			-- Skip if this is a bank bag
			if bagID and self:IsBankBag(bagID) then
				return
			end

			-- Skip if button is in a bank frame
			if button:GetParent() and self:IsBankFrame(button:GetParent()) then
				return
			end

			-- Apply scale immediately
			self:ApplyScaleToButton(button)
			-- Force update other aspects of the button
			button._BCZ_forceUpdate = true
			self:UpdateSlot(button)
		end
	end

	-- Clear update queue and scheduled updates
	updateQueue = {}
	isUpdateScheduled = false
end

-- Alias function to match the options UI
function module:UpdateAllScales()
	self:UpdateAllScaleFactors()
end

-- Apply preset scale factor
function module:ApplyPresetScaleFactor()
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings then return end

	local preset = settings.preset or "blizzard_modern"
	local baseTextures = presetTextures[preset] or defaultTextures
	-- Only apply preset scale factor if the user hasn't manually changed it
	if not settings.userModifiedScale then
		-- Get scale factor from preset or use default
		local scaleFactor = baseTextures.ScaleFactor or 100
		-- Update settings
		settings.scaleFactor = scaleFactor
		settings.globalScaleFactor = scaleFactor / 100
		-- Update all scales
		self:UpdateAllScales()
	end
end

-- OPTIMIZATION: Improved visibility detection with caching
function module:IsSlotVisible(slot)
	if not slot then return false end

	-- Skip bank slots
	local bagID = slot.bagID
	if not bagID and slot:GetParent() and slot:GetParent():GetID() then
		bagID = slot:GetParent():GetID()
	end

	-- Skip if this is a bank bag
	if bagID and self:IsBankBag(bagID) then
		return false
	end

	-- Skip if slot is in a bank frame
	if slot:GetParent() and self:IsBankFrame(slot:GetParent()) then
		return false
	end

	-- If slot is alpha 0 or hidden, it's not visible
	if not slot:IsVisible() or slot:GetAlpha() == 0 then
		return false
	end

	-- Check if we have a recent visibility result cached
	local currentTime = GetTime()
	if slot._BCZ and slot._BCZ.lastVisibilityCheck and
			(currentTime - slot._BCZ.lastVisibilityCheck) < 0.25 then
		return slot._BCZ.isVisible
	end

	-- Only do expensive checks if the cache refresh timer has elapsed
	if currentTime - lastVisibilityUpdate < 0.1 then
		-- Check for frame-specific visibility cache
		if visibilityCache[slot] ~= nil then
			return visibilityCache[slot]
		end
	else
		-- Clear visibility cache periodically
		visibilityCache = {}
		lastVisibilityUpdate = currentTime
	end

	-- Skip slots that are very distant from camera
	local scale = slot:GetEffectiveScale()
	if scale < 0.1 then
		-- Cache the result
		visibilityCache[slot] = false
		if slot._BCZ then
			slot._BCZ.lastVisibilityCheck = currentTime
			slot._BCZ.isVisible = false
		end

		return false -- Extremely small/distant slots
	end

	-- Skip if off-screen (more aggressive check)
	local left, bottom, width, height = slot:GetRect()
	if not left or not bottom then
		-- Cache the result
		visibilityCache[slot] = false
		if slot._BCZ then
			slot._BCZ.lastVisibilityCheck = currentTime
			slot._BCZ.isVisible = false
		end

		return false
	end

	local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
	if (left + width < 0 or left > screenWidth or
				bottom + height < 0 or bottom > screenHeight) then
		-- Cache the result
		visibilityCache[slot] = false
		if slot._BCZ then
			slot._BCZ.lastVisibilityCheck = currentTime
			slot._BCZ.isVisible = false
		end

		return false
	end

	-- Find the scroll frame
	local frame = slot:GetParent()
	if not frame then
		-- Cache the result
		visibilityCache[slot] = true
		if slot._BCZ then
			slot._BCZ.lastVisibilityCheck = currentTime
			slot._BCZ.isVisible = true
		end

		return true
	end

	local scrollFrame
	if frame.ScrollFrame then
		scrollFrame = frame.ScrollFrame
	elseif frame:GetParent() and frame:GetParent().ScrollFrame then
		scrollFrame = frame:GetParent().ScrollFrame
	end

	-- If no scrollframe, the slot is always visible
	if not scrollFrame then
		-- Cache the result
		visibilityCache[slot] = true
		if slot._BCZ then
			slot._BCZ.lastVisibilityCheck = currentTime
			slot._BCZ.isVisible = true
		end

		return true
	end

	-- Check visibility based on scroll position
	local scrollOffset = scrollFrame:GetVerticalScroll() or 0
	local viewHeight = scrollFrame:GetHeight() or 0
	local slotTop = slot:GetTop()
	local slotBottom = slot:GetBottom()
	local frameTop = scrollFrame:GetTop()
	if not slotTop or not slotBottom or not frameTop then
		-- Default to visible if calculations can't be performed
		visibilityCache[slot] = true
		if slot._BCZ then
			slot._BCZ.lastVisibilityCheck = currentTime
			slot._BCZ.isVisible = true
		end

		return true
	end

	local buffer = 50
	local isVisible = (slotBottom < frameTop + scrollOffset + buffer) and
			(slotTop > frameTop + scrollOffset - viewHeight - buffer)
	-- Cache the result
	visibilityCache[slot] = isVisible
	if slot._BCZ then
		slot._BCZ.lastVisibilityCheck = currentTime
		slot._BCZ.isVisible = isVisible
	end

	return isVisible
end

-- OPTIMIZATION: Simplified UpdateSlot with more efficient throttling
function module:UpdateSlot(button)
	if not button or not button._BCZ then return end

	-- Skip bank slots
	local bagID = button.bagID
	if not bagID and button:GetParent() and button:GetParent():GetID() then
		bagID = button:GetParent():GetID()
	end

	-- Skip if this is a bank bag
	if bagID and self:IsBankBag(bagID) then
		return
	end

	-- Skip if button is in a bank frame
	if button:GetParent() and self:IsBankFrame(button:GetParent()) then
		return
	end

	local settings = E.db.bagCustomizer.inventorySlots
	-- More efficient state checks
	local hasItem = button.hasItem
	local state = hasItem and "filled" or "empty"
	-- OPTIMIZATION: Improved throttling with higher thresholds
	if not button._BCZ_forceUpdate and button._BCZ.lastUpdateTime and
			button._BCZ.state == state then
		local now = GetTime()
		-- Use a larger throttle window (150ms instead of 120ms)
		if now - button._BCZ.lastUpdateTime < 0.15 then
			-- For border color changes, only update if color changed significantly
			if hasItem and button.IconBorder and button.IconBorder:IsShown() then
				local r, g, b = button.IconBorder:GetVertexColor()
				-- Skip if no color available
				if not r or not g or not b then return end

				-- Skip if colors are similar (higher threshold of 0.04)
				if button._BCZ.lastBorderR and
						math.abs(r - button._BCZ.lastBorderR) < 0.04 and
						math.abs(g - button._BCZ.lastBorderG) < 0.04 and
						math.abs(b - button._BCZ.lastBorderB) < 0.04 then
					return
				end
			else
				-- Safe to skip for non-border updates
				return
			end
		end
	end

	-- Record update time and state
	button._BCZ.lastUpdateTime = GetTime()
	button._BCZ.state = state
	-- Get current texture set in case it has changed
	local currentTextures = GetButtonTextures()
	-- Update Textures in case preset has changed
	if button._BCZ.normalTexture then
		button._BCZ.normalTexture:SetTexture(currentTextures.Normal)
	end

	if button._BCZ.emptyTexture then
		button._BCZ.emptyTexture:Show()
		-- Get assigned bag information
		local assignedBags = self:CollectAssignedBags(false)
		local bagID = button.bagID
		if not bagID and button:GetParent() and button:GetParent():GetID() then
			bagID = button:GetParent():GetID()
		end

		-- Check if this bag is assigned
		local filterType = bagID and assignedBags[bagID]
		local isAssigned = filterType ~= nil and filterType ~= ""
		-- Apply empty slot texture settings with assignment info
		self:ApplyEmptySlotTextureSettings(button, isAssigned, filterType)
		-- Store that this is an assigned bag for tracking
		if isAssigned then
			button._BCZ_isAssignedBag = true
			button._BCZ_assignmentType = filterType
		else
			button._BCZ_isAssignedBag = nil
			button._BCZ_assignmentType = nil
		end

		-- Store the current assignment state
		button._BCZ.lastFilterType = filterType
	end

	if button._BCZ.borderTexture then
		button._BCZ.borderTexture:SetTexture(currentTextures.Border)
	end

	local textureAlpha = settings.textureAlpha or 1.0
	if hasItem then
		-- Filled slot
		if button._BCZ.emptyTexture then button._BCZ.emptyTexture:Hide() end

		if button._BCZ.normalTexture then button._BCZ.normalTexture:SetAlpha(textureAlpha) end

		-- Handle item quality borders
		local quality = button.quality or button.rarity
		-- Check for our custom quality border settings
		local useCustomBorder = false
		local customColor = nil
		if quality == 0 and settings.showPoorQualityBorders then -- Poor quality
			useCustomBorder = true
			customColor = settings.poorQualityColor
		elseif quality == 1 and settings.showCommonQualityBorders then -- Common quality
			useCustomBorder = true
			customColor = settings.commonQualityColor
		end

		if useCustomBorder and customColor then
			-- Apply our custom color with brightness adjustments
			local r, g, b = customColor.r, customColor.g, customColor.b
			-- Apply brightness adjustment
			r, g, b = self:ApplyBrightnessToColor(r, g, b, button)
			button._BCZ.borderTexture:SetVertexColor(r, g, b, 1) -- Always alpha 1
			button._BCZ.borderTexture:Show()
			-- Record border color for throttling
			button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = r, g, b
		else
			-- Standard ElvUI border handling
			if button.IconBorder and button.IconBorder:IsShown() and button._BCZ.borderTexture then
				-- Make sure we're using the regular border texture
				button._BCZ.borderTexture:SetTexture(currentTextures.Border)
				-- Check quality to exclude common items from ElvUI colors
				local quality = button.quality or button.rarity
				if quality == 1 then
					-- For common items, check if borders should be visible
					local r, g, b = 1, 1, 1
					local alpha = 0 -- Default alpha 0 (invisible)
					if settings.showCommonQualityBorders then
						alpha = 1 -- Show border only if option enabled
						if settings.commonQualityColor then
							r, g, b = settings.commonQualityColor.r, settings.commonQualityColor.g,
									settings.commonQualityColor.b
						end
					end

					-- Apply brightness adjustment
					r, g, b = self:ApplyBrightnessToColor(r, g, b, button)
					button._BCZ.borderTexture:SetVertexColor(r, g, b, alpha)
					button._BCZ.borderTexture:Show() -- Keep texture active but transparent
					-- Record border color for throttling
					button._BCZ.lastBorderR = r
					button._BCZ.lastBorderG = g
					button._BCZ.lastBorderB = b
				else
					-- For other qualities, use ElvUI colors
					local r, g, b = button.IconBorder:GetVertexColor()
					if r and g and b then
						-- Apply brightness adjustment
						r, g, b = self:ApplyBrightnessToColor(r, g, b, button)
						button._BCZ.borderTexture:SetVertexColor(r, g, b, 1)
						button._BCZ.borderTexture:Show()
						-- Record border color for throttling
						button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = r, g, b
					else
						-- Default quality color
						button._BCZ.borderTexture:SetVertexColor(1, 1, 1, 1)
						button._BCZ.borderTexture:Show()
						-- Record border color for throttling
						button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = 1, 1, 1
					end
				end
			else
				-- No quality border shown by ElvUI
				button._BCZ.borderTexture:Hide()
				-- Clear border color cache
				button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = nil, nil, nil
			end
		end
	else
		-- Empty slot
		if button._BCZ.emptyTexture then
			button._BCZ.emptyTexture:Show()
			--  button._BCZ.emptyTexture:SetAlpha(textureAlpha) -- commented out due to new, adjustable alpha setting
		end

		if button._BCZ.normalTexture then button._BCZ.normalTexture:SetAlpha(textureAlpha) end

		if button._BCZ.borderFrame then
			button._BCZ.borderFrame:SetAlpha(1) -- Ensure parent frame is fully opaque
		end

		-- Determine which border texture to use for the empty slot
		if button._BCZ.borderTexture then
			local borderTextureToUse = currentTextures.Border  -- Default to the main border texture
			local isAssigned = button._BCZ_isAssignedBag or false -- Get assigned status determined below
			-- Check the NEW option first for assigned bags
			if settings.applyMainBorderToEmptyAssigned and isAssigned then
				-- If option is enabled and the slot is in an assigned bag, force use of the main border.
				borderTextureToUse = currentTextures.Border
				-- Otherwise, fall back to the 'separateEmptyBorder' logic
			elseif settings.separateEmptyBorder then
				-- If separate borders are enabled (and the new option didn't apply), use the specific EmptyBorder.
				borderTextureToUse = currentTextures.EmptyBorder
				-- else: If separate borders are disabled, the default (currentTextures.Border) is already set.
			end

			-- Apply the chosen border texture
			button._BCZ.borderTexture:SetTexture(borderTextureToUse)
			-- Handle empty slot border color based on assigned bag status
			-- Get fresh assigned bags data without forcing cache invalidation
			local assignedBags = self:CollectAssignedBags(false)
			-- If we can determine the bagID, check if the bag is assigned
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			if bagID then
				-- Check if this bag is assigned - verify filterType is not empty string
				local filterType = assignedBags[bagID]
				-- Re-evaluate isAssigned here for color logic consistency
				isAssigned = filterType ~= nil and filterType ~= ""
				-- Store assignment status for border texture logic above and general tracking
				button._BCZ_isAssignedBag = isAssigned
				button._BCZ_assignmentType = isAssigned and filterType or nil
				if isAssigned then
					-- Get the color for this assigned bag
					local r, g, b = self:GetAssignedBagColor(filterType)
					-- Apply brightness adjustment for assigned empty slots
					r, g, b = self:ApplyEmptySlotBrightness(r, g, b, true)
					-- Apply the color to the border
					button._BCZ.borderTexture:SetVertexColor(r, g, b, settings.emptySlotOpacity or 1)
					button._BCZ.borderTexture:Show()
					-- Record border color for throttling
					button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = r, g, b
				else
					-- For unassigned bags, use the default empty slot color
					if settings.emptySlotColor then
						-- Get color values, apply brightness, then set the color
						local r, g, b = settings.emptySlotColor.r or 1.0,
								settings.emptySlotColor.g or 1.0,
								settings.emptySlotColor.b or 1.0
						-- Apply brightness adjustment for unassigned empty slots
						r, g, b = self:ApplyEmptySlotBrightness(r, g, b, false)
						button._BCZ.borderTexture:SetVertexColor(r, g, b, settings.emptySlotOpacity or 1)
						button._BCZ.borderTexture:Show()
						-- Record border color for throttling
						button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = r, g, b
					else
						-- Fallback if color not set (shouldn't happen with initialization)
						button._BCZ.borderTexture:SetVertexColor(1, 1, 1, settings.emptySlotOpacity or 1)
						button._BCZ.borderTexture:Show()
						button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = 1, 1, 1
					end
				end

				-- Store the current assignment state more clearly
				button._BCZ.lastFilterType = filterType
			else
				-- If we can't determine the bagID, fall back to default empty slot color
				button._BCZ_isAssignedBag = false -- Mark as not assigned if ID unknown
				button._BCZ_assignmentType = nil
				if settings.emptySlotColor then
					-- Get color values, apply brightness, then set the color
					local r, g, b = settings.emptySlotColor.r or 1.0,
							settings.emptySlotColor.g or 1.0,
							settings.emptySlotColor.b or 1.0
					-- Apply brightness adjustment for unassigned empty slots
					r, g, b = self:ApplyEmptySlotBrightness(r, g, b, false)
					button._BCZ.borderTexture:SetVertexColor(r, g, b, settings.emptySlotOpacity or 1)
					button._BCZ.borderTexture:Show()
					-- Record border color for throttling
					button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = r, g, b
				else
					-- Fallback
					button._BCZ.borderTexture:SetVertexColor(1, 1, 1, settings.emptySlotOpacity or 1)
					button._BCZ.borderTexture:Show()
					button._BCZ.lastBorderR, button._BCZ.lastBorderG, button._BCZ.lastBorderB = 1, 1, 1
				end
			end
		end
	end

	-- Clear force update flag after processing
	button._BCZ_forceUpdate = nil
end

-- OPTIMIZATION: More efficient frame processing
function module:ProcessFrame(frame)
	if not frame or not frame.Bags then return end

	-- Skip bank frames
	if self:IsBankFrame(frame) then
		debug("InventorySlots: Skipping bank frame")
		return
	end

	-- Skip if addon is disabled globally
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then return end

	-- Skip if module is disabled
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings or not settings.enable then return end

	local visibleButtonCount = 0
	local processedCount = 0
	-- Process each bag directly - but batch operations
	for _, bagID in ipairs(frame.BagIDs or {}) do
		-- Skip bank bags (5-11)
		if self:IsBankBag(bagID) then
			return
		end

		if frame.Bags and frame.Bags[bagID] then
			local slotsInBag = B:GetContainerNumSlots(bagID)
			for slotID = 1, slotsInBag do
				local slot = frame.Bags[bagID][slotID]
				if slot then
					visibleButtonCount = visibleButtonCount + 1
					-- Only process visible slots
					if self:IsSlotVisible(slot) then
						self:SkinButton(slot)
						processedCount = processedCount + 1
					end
				end
			end
		end
	end

	debug("InventorySlots: Processed " .. processedCount .. " of " .. visibleButtonCount .. " slots")
end

-- OPTIMIZATION: Optimized update all function
function module:UpdateAll()
	-- Skip if addon is disabled globally
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then
		self:RevertAllSlots()
		return
	end

	-- Skip if module is disabled
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings or not settings.enable then
		self:RevertAllSlots()
		return
	end

	-- OPTIMIZATION: Reset visibility cache
	visibilityCache = {}
	lastVisibilityUpdate = GetTime()
	-- Update regular bags - SIMPLIFIED
	local containerFrame = B.BagFrame
	if containerFrame and containerFrame:IsShown() then
		self:ProcessFrame(containerFrame)
	end

	-- NO LONGER PROCESS BANK FRAMES
	-- We're skipping bank frames entirely now
	-- Save current settings after update
	self:SaveCurrentSettings()
end

-- Update all empty slot textures when settings change
function module:UpdateAllEmptySlotTextures()
	debug("InventorySlots: Updating all empty slot textures")
	-- Clear color cache to ensure fresh colors
	colorCache = {}
	for button in pairs(processedSlots) do
		if button and button._BCZ and not button.hasItem then
			-- Skip bank slots
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			-- Skip if this is a bank bag
			if bagID and self:IsBankBag(bagID) then
				return
			end

			-- Skip if button is in a bank frame
			if button:GetParent() and self:IsBankFrame(button:GetParent()) then
				return
			end

			button._BCZ_forceUpdate = true
			self:QueueButtonForUpdate(button)
		end
	end
end

-- Better cleanup of frames and Textures
function module:CleanupButton(button)
	if not button or not button._BCZ then return end

	-- Hide all frames first
	if button._BCZ.buttonArt then
		button._BCZ.buttonArt:Hide()
		button._BCZ.buttonArt:SetParent(nil)
	end

	if button._BCZ.borderFrame then
		button._BCZ.borderFrame:Hide()
		button._BCZ.borderFrame:SetParent(nil)
	end

	if button._BCZ.iconContainer then
		button._BCZ.iconContainer:Hide()
		button._BCZ.iconContainer:SetParent(nil)
	end

	-- Clean up all Textures
	if button._BCZ.normalTexture then
		button._BCZ.normalTexture:SetTexture(nil)
		button._BCZ.normalTexture:Hide()
	end

	if button._BCZ.emptyTexture then
		button._BCZ.emptyTexture:SetTexture(nil)
		button._BCZ.emptyTexture:Hide()
	end

	if button._BCZ.borderTexture then
		button._BCZ.borderTexture:SetTexture(nil)
		button._BCZ.borderTexture:Hide()
	end

	if button._BCZ.highlightTexture then
		button._BCZ.highlightTexture:SetTexture(nil)
		button._BCZ.highlightTexture:Hide()
	end

	if button._BCZ.customIcon then
		if button._BCZ.iconMask then
			pcall(function() button._BCZ.customIcon:RemoveMaskTexture(button._BCZ.iconMask) end)
		end

		button._BCZ.customIcon:SetTexture(nil)
		button._BCZ.customIcon:Hide()
	end

	if button._BCZ.iconMask then
		button._BCZ.iconMask:SetTexture(nil)
	end
end

-- Cleanup resources and revert a single slot
function module:RevertSlot(button)
	if not button or not button._BCZ then return end

	-- First clean up all our frames and Textures
	self:CleanupButton(button)
	-- Restore original Textures
	if button._BCZ.hidden then
		for name, original in pairs(button._BCZ.hidden) do
			if button[name] then
				if original.texture then
					button[name]:SetTexture(original.texture)
				end

				if original.shownState then
					button[name]:Show()
				else
					button[name]:Hide()
				end

				button[name]:SetAlpha(original.alpha or 1)
			end
		end
	end

	-- Restore original icon
	local iconTexture = button.icon or button.IconTexture
	if iconTexture then
		-- Show the original icon again
		iconTexture:SetAlpha(1)
		-- Restore position
		if button._BCZ.iconOriginal then
			iconTexture:ClearAllPoints()
			if button._BCZ.iconOriginal.points and #button._BCZ.iconOriginal.points > 0 then
				for i, pointData in ipairs(button._BCZ.iconOriginal.points) do
					iconTexture:SetPoint(unpack(pointData))
				end
			else
				-- Fallback
				iconTexture:SetAllPoints()
			end

			-- Restore texture coordinates
			if button._BCZ.iconOriginal.texCoord then
				iconTexture:SetTexCoord(unpack(button._BCZ.iconOriginal.texCoord))
			end
		end
	end

	-- Properly restore ElvUI highlight system
	button:SetHighlightTexture("")                    -- Clear any existing highlight
	local hlProps = self:GetElvUIHighlightProperties() -- Get ElvUI properties
	button:SetHighlightTexture(hlProps.texture)
	local highTex = button:GetHighlightTexture()
	if highTex then
		highTex:SetVertexColor(hlProps.color.r, hlProps.color.g, hlProps.color.b, hlProps.color.a)
		highTex:SetBlendMode(hlProps.blendMode)
		highTex:SetAllPoints()
	end

	-- Clear references to our customizations (already cleaned up above)
	button._BCZ = nil
	-- Remove from processed list
	processedSlots[button] = nil
end

-- Revert all slots in a frame
function module:RevertFrameSlots(frame)
	if not frame or not frame.Bags then return end

	-- Skip bank frames entirely
	if self:IsBankFrame(frame) then
		return
	end

	-- Process each bag
	for _, bagID in ipairs(frame.BagIDs or {}) do
		-- Skip bank bags
		if self:IsBankBag(bagID) then
			return
		end

		if frame.Bags and frame.Bags[bagID] then
			for slotID = 1, B:GetContainerNumSlots(bagID) do
				local slot = frame.Bags[bagID][slotID]
				if slot then self:RevertSlot(slot) end
			end
		end
	end
end

-- Revert all slots
function module:RevertAllSlots()
	-- Make a copy of the processed slots to avoid modification during iteration
	local buttonsToRevert = {}
	for button in pairs(processedSlots) do
		-- Skip bank slots
		local bagID = button.bagID
		if not bagID and button:GetParent() and button:GetParent():GetID() then
			bagID = button:GetParent():GetID()
		end

		-- Skip if this is a bank bag
		if bagID and self:IsBankBag(bagID) then
			return
		end

		-- Skip if button is in a bank frame
		if button:GetParent() and self:IsBankFrame(button:GetParent()) then
			return
		end

		table.insert(buttonsToRevert, button)
	end

	-- Revert each button
	for _, button in ipairs(buttonsToRevert) do
		self:RevertSlot(button)
	end

	-- Clear processed list just to be sure
	processedSlots = {}
	-- Clear texture caches
	buttonTexturesCache = {}
	colorCache = {}
	updateQueue = {}
	isUpdateScheduled = false
	debug("InventorySlots: Reverted all slots successfully")
end

-- Reset cache for assigned bags
function module:ResetCache()
	-- Clear the cache table and timestamp
	assignedBagsCache = {}
	assignedBagsCacheTime = 0
	extractedElvUIHighlight = nil -- Reset highlight cache too
	colorCache = {}              -- Reset color cache too
	-- OPTIMIZATION: Only selectively clear texture cache
	self:InvalidateTextureCache()
	-- OPTIMIZATION: Use batch update system instead of direct updates
	self:BatchUpdateButtons(true)
end

-- OPTIMIZATION: Selective cache clearing
function module:ClearCache()
	-- Clear button Textures cache
	self:InvalidateTextureCache()
	-- Clear color cache
	colorCache = {}
	-- Mark buttons for update using the batch system
	self:BatchUpdateButtons(true)
end

-- Refresh ElvUI highlight cache
function module:RefreshElvUIHighlightCache()
	extractedElvUIHighlight = nil
end

-- OPTIMIZATION: Improved bag update function
function module:ForceUpdateBagBorders(bagID)
	-- Skip bank bags
	if self:IsBankBag(bagID) then
		return
	end

	-- Reset assigned bag cache
	assignedBagsCache = {}
	assignedBagsCacheTime = 0
	debug("InventorySlots: Force updating borders for bag " .. bagID)
	-- Collect buttons to update
	local buttonsToUpdate = {}
	-- Check container frame
	local containerFrame = B.BagFrame
	if containerFrame and containerFrame:IsShown() and containerFrame.Bags and containerFrame.Bags[bagID] then
		local numSlots = B:GetContainerNumSlots(bagID)
		for slotID = 1, numSlots do
			local slot = containerFrame.Bags[bagID][slotID]
			if slot then
				tinsert(buttonsToUpdate, slot)
			end
		end
	end

	-- Batch update all collected buttons
	for _, button in ipairs(buttonsToUpdate) do
		if button._BCZ then
			button._BCZ.state = nil
			button._BCZ_isAssignedBag = nil
			button._BCZ_forceUpdate = true
		end

		self:QueueButtonForUpdate(button)
	end

	debug("InventorySlots: Queued " .. #buttonsToUpdate .. " buttons from bag " .. bagID .. " for update")
end

-- OPTIMIZATION: Fixed ToggleState function to prevent flickering
function module:ToggleState()
	-- Get current state
	local isEnabled = E.db.bagCustomizer and E.db.bagCustomizer.enabled
	local isModuleEnabled = isEnabled and E.db.bagCustomizer.inventorySlots and E.db.bagCustomizer.inventorySlots.enable
	debug("InventorySlots: ToggleState called - Addon enabled: " .. tostring(isEnabled) ..
		", Module enabled: " .. tostring(isModuleEnabled))
	-- Store previous state
	local wasEnabled = lastEnabled and lastModuleEnabled
	local willBeEnabled = isEnabled and isModuleEnabled
	-- Only revert if we're actually turning off the module
	if wasEnabled and not willBeEnabled then
		self:RevertAllSlots()
	end

	-- Clear all caches to ensure a clean state
	self:InvalidateTextureCache()
	colorCache = {}
	assignedBagsCache = {}
	assignedBagsCacheTime = 0
	extractedElvUIHighlight = nil
	-- Only proceed with initialization if both addon and module are enabled
	if isEnabled and isModuleEnabled then
		-- Schedule an update to re-apply styles
		C_Timer.After(0.1, function()
			debug("InventorySlots: Re-applying styles after toggle")
			self:UpdateAll()
		end)
	else
		debug("InventorySlots: Module is now disabled")
	end

	-- Save the new state
	self:SaveCurrentSettings()
	-- Flag for combat-aware update
	self.needsFullUpdate = true
end

-- Monitor settings changes
function module:CheckSettingsChanged()
	if self:HaveSettingsChanged() then
		debug("InventorySlots: Settings change detected, applying changes")
		-- Handle enable/disable toggle specifically
		local isEnabled = E.db.bagCustomizer and E.db.bagCustomizer.enabled
		local isModuleEnabled = isEnabled and E.db.bagCustomizer.inventorySlots and
				E.db.bagCustomizer.inventorySlots.enable
		if (lastEnabled ~= isEnabled) or (lastModuleEnabled ~= isModuleEnabled) then
			-- Handle module toggle
			self:ToggleState()
		else
			-- Handle style changes - use selective cache invalidation
			local settings = E.db.bagCustomizer.inventorySlots
			-- Check what's changed and invalidate selectively
			if lastSettings.preset ~= settings.preset then
				self:InvalidateTextureCache("preset")
			end

			if lastSettings.EmptyStyle ~= settings.EmptyStyle then
				self:InvalidateTextureCache("EmptyStyle")
			end

			if lastSettings.NormalStyle ~= settings.NormalStyle then
				self:InvalidateTextureCache("NormalStyle")
			end

			if lastSettings.HighlightStyle ~= settings.HighlightStyle then
				self:InvalidateTextureCache("HighlightStyle")
			end

			if lastSettings.BorderStyle ~= settings.BorderStyle or
					lastSettings.EmptyBorderStyle ~= settings.EmptyBorderStyle or
					lastSettings.separateEmptyBorder ~= settings.separateEmptyBorder or
					lastSettings.applyMainBorderToEmptyAssigned ~= settings.applyMainBorderToEmptyAssigned then
				-- Invalidate relevant caches if border settings changed
				self:InvalidateTextureCache("BorderStyle")
				self:InvalidateTextureCache("EmptyBorderStyle")
				debug("InventorySlots: Border setting changed, invalidating border caches.")
			end

			-- Batch update buttons
			self:BatchUpdateButtons(true)
		end

		-- Save current settings for future comparison
		self:SaveCurrentSettings()
	end
end

-- OPTIMIZATION: Consolidated hook functionality
function module:SetupHooks()
	-- OPTIMIZATION: Track whether hooks are already set up
	if self.hooksInitialized then return end

	self.hooksInitialized = true
	-- Create hook table for organization
	local hooks = {}
	-- Hook before slot is created - single timer with delay
	hooks.createSlot = function(_, bagFrame, bagID, slotID)
		-- Skip bank bags
		if self:IsBankBag(bagID) then
			return
		end

		-- Skip if frame is a bank frame
		if self:IsBankFrame(bagFrame) then
			return
		end

		-- Use a queue for creation events
		C_Timer.After(0.01, function()
			if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then return end

			if not bagFrame or not bagFrame.Bags then return end

			local slot = bagFrame.Bags[bagID] and bagFrame.Bags[bagID][slotID]
			if slot then self:SkinButton(slot) end
		end)
	end
	-- Hook when entire bags are updated
	hooks.layout = function()
		-- Use a single update timer
		if not self.layoutUpdateScheduled then
			self.layoutUpdateScheduled = true
			C_Timer.After(0.05, function()
				self.layoutUpdateScheduled = false
				if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then return end

				self:UpdateAll()
			end)
		end
	end
	-- Hook when individual slots update
	hooks.updateSlot = function(_, bagFrame, bagID, slotID)
		-- Skip bank bags
		if self:IsBankBag(bagID) then
			return
		end

		-- Skip if frame is a bank frame
		if self:IsBankFrame(bagFrame) then
			return
		end

		if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then return end

		if not bagFrame or not bagFrame.Bags then return end

		local slot = bagFrame.Bags[bagID] and bagFrame.Bags[bagID][slotID]
		if slot and processedSlots[slot] then
			-- Queue the button for update instead of immediate update
			self:QueueButtonForUpdate(slot)
		end
	end
	-- OPTIMIZATION: Consolidated bag open/close hooks
	local function OnBagOpen()
		if not self.bagOpenUpdateScheduled then
			self.bagOpenUpdateScheduled = true
			C_Timer.After(0.15, function() -- Slightly longer delay for better experience
				self.bagOpenUpdateScheduled = false
				if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then return end

				self:UpdateAll()
			end)
		end
	end

	-- Apply all hooks
	if B.CreateSlot and not self.hookedCreateSlot then
		hooksecurefunc(B, "CreateSlot", hooks.createSlot)
		self.hookedCreateSlot = true
	end

	if B.Layout and not self.hookedLayout then
		hooksecurefunc(B, "Layout", hooks.layout)
		self.hookedLayout = true
	end

	if B.UpdateSlot and not self.hookedUpdateSlot then
		hooksecurefunc(B, "UpdateSlot", hooks.updateSlot)
		self.hookedUpdateSlot = true
	end

	-- Hook when the texture of a slot changes (for item icons)
	if not self.hookedSetItemButtonTexture then
		hooksecurefunc("SetItemButtonTexture", function(button, texture)
			if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then return end

			-- Skip bank slots
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			-- Skip if this is a bank bag
			if bagID and self:IsBankBag(bagID) then
				return
			end

			-- Skip if button is in a bank frame
			if button:GetParent() and self:IsBankFrame(button:GetParent()) then
				return
			end

			if button and processedSlots[button] then
				self:UpdateItemTexture(button)
			end
		end)
		self.hookedSetItemButtonTexture = true
	end

	-- Apply consolidated bag open/close hooks
	if not self.hookedBagOpen then
		hooksecurefunc("OpenBackpack", OnBagOpen)
		hooksecurefunc("OpenAllBags", OnBagOpen)
		hooksecurefunc("ToggleAllBags", OnBagOpen)
		self.hookedBagOpen = true
	end

	-- Create a settings watcher frame to detect changes in real-time
	if not self.settingsWatcher then
		self.settingsWatcher = CreateFrame("Frame")
		self.settingsWatcher.elapsed = 0
		self.settingsWatcher:SetScript("OnUpdate", function(_, elapsed)
			self.settingsWatcher.elapsed = self.settingsWatcher.elapsed + elapsed
			if self.settingsWatcher.elapsed >= 0.5 then -- Check every half second
				self.settingsWatcher.elapsed = 0
				self:CheckSettingsChanged()
			end
		end)
	end
end

-- Set up hooks for bag assignment changes
function module:SetupAssignmentHooks()
	-- OPTIMIZATION: Use a consolidated assignment change detection function
	local function OnBagAssignmentChanged(bagID)
		if not bagID then return end

		-- Skip bank bags
		if self:IsBankBag(bagID) then
			return
		end

		-- Schedule a single update for this bag
		C_Timer.After(0.05, function()
			self:ForceUpdateBagBorders(bagID)
		end)
	end

	-- Hook bag assignment function with immediate updates
	if B.AssignBagFunctionality and not self.hookedAssignBagFunctionality then
		hooksecurefunc(B, "AssignBagFunctionality", function(_, bagButton, filterType)
			if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then return end

			local bagID = bagButton and bagButton:GetID()
			if bagID and not self:IsBankBag(bagID) then
				OnBagAssignmentChanged(bagID)
			end
		end)
		self.hookedAssignBagFunctionality = true
	end

	-- Also hook into SetBagAssignmentInfo if it exists
	if B.SetBagAssignmentInfo and not self.hookedSetBagAssignmentInfo then
		hooksecurefunc(B, "SetBagAssignmentInfo", function(_, bagID)
			-- Skip bank bags
			if bagID and not self:IsBankBag(bagID) then
				OnBagAssignmentChanged(bagID)
			end
		end)
		self.hookedSetBagAssignmentInfo = true
	end

	-- Listen for right-clicks on bag slots (if not already hooked)
	if not self.hookedBagButtons then
		for i = 0, 4 do -- Only regular bags, not bank bags
			local bagButton = _G["ElvUIBag" .. i]
			if bagButton then
				bagButton:HookScript("OnClick", function(self, button)
					if button == "RightButton" then
						local bagID = self:GetID()
						OnBagAssignmentChanged(bagID)
					end
				end)
			end
		end

		self.hookedBagButtons = true
	end

	-- OPTIMIZATION: Consolidated event handlers
	local function OnBagUpdate(bagID)
		if not addon:IsAnyBagVisible() then return end

		-- Skip bank bags
		if bagID and self:IsBankBag(bagID) then
			return
		end

		-- If specific bagID is provided, only update that bag
		if bagID and bagID >= 0 and bagID <= 4 then
			C_Timer.After(0.05, function()
				self:ForceUpdateBagBorders(bagID)
			end)
		else
			-- Otherwise queue a full update with cache reset
			if not self.fullUpdateScheduled then
				self.fullUpdateScheduled = true
				C_Timer.After(0.2, function()
					self.fullUpdateScheduled = false
					self:ResetCache()
					self:UpdateAll()
				end)
			end
		end
	end

	-- Create a single event frame for bag updates
	if not self.bagEventFrame then
		self.bagEventFrame = CreateFrame("Frame")
		self.bagEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		self.bagEventFrame:RegisterEvent("BAG_UPDATE")
		self.bagEventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
		self.bagEventFrame:SetScript("OnEvent", function(_, event, arg1)
			if event == "BAG_UPDATE" then
				OnBagUpdate(arg1) -- arg1 is bagID
			else
				OnBagUpdate() -- Full update for other events
			end
		end)
	end

	-- Hook into ElvUI's pre-update all slots function
	if B.PreUpdateAllSlots and not self.hookedPreUpdateAllSlots then
		hooksecurefunc(B, "PreUpdateAllSlots", function()
			self:ResetCache()
		end)
		self.hookedPreUpdateAllSlots = true
	end

	-- Listen for ElvUI profile changes
	if E.data and E.data.RegisterCallback and not self.profileChangeHooked then
		E.data.RegisterCallback(self, "OnProfileChanged", function()
			C_Timer.After(0.3, function()
				self:ResetCache()
				self:UpdateAll()
			end)
		end)
		self.profileChangeHooked = true
	end

	-- Hook into ElvUI Config Open/Close if not already hooked
	if E.ConfigModeDialog and not self.configDialogHooked then
		E.ConfigModeDialog:HookScript("OnShow", function()
			-- Config window opened
			C_Timer.After(0.5, function()
				self:CheckSettingsChanged()
			end)
		end)
		E.ConfigModeDialog:HookScript("OnHide", function()
			-- Config window closed, settings may have changed
			C_Timer.After(0.5, function()
				self:CheckSettingsChanged()
			end)
		end)
		self.configDialogHooked = true
	end
end

-- Hook into ElvUI's options callback system
function module:SetupOptionsCallbacks()
	-- If the addon has a callback system for options changes
	if addon.OptionsCallback and not self.optionCallbackHooked then
		addon.OptionsCallback("InventorySlots", function(optionPath)
			debug("InventorySlots: Option changed: " .. (optionPath or "unknown"))
			-- Special handling for scale options - apply immediately
			if optionPath == "globalScaleFactor" or optionPath == "scaleFactor" or
					optionPath:find("Scale") or optionPath:find("scale") then
				debug("InventorySlots: Scale setting changed - applying immediately")
				-- Force complete cache invalidation for scale changes
				buttonTexturesCache = {}
				-- Update scale immediately without delay
				self:UpdateAllScaleFactors()
				return -- Skip further processing
			end

			-- OPTIMIZATION: Selective cache invalidation based on option path
			if optionPath == "preset" then
				self:InvalidateTextureCache("preset")
			elseif optionPath:find("Style") then
				self:InvalidateTextureCache(optionPath)
			elseif optionPath:find("Color") or optionPath:find("Brightness") or
					optionPath:find("Intensity") or optionPath:find("Opacity") then
				-- Just clear color cache for color-related settings
				colorCache = {}
			else
				-- For other settings, clear all caches
				self:InvalidateTextureCache()
			end

			-- Apply changes
			C_Timer.After(0.05, function()
				-- Check if this was a toggle
				if optionPath == "enable" or optionPath == "inventorySlots.enable" then
					self:ToggleState()
				else
					-- For other settings, queue button updates
					self:BatchUpdateButtons(true)
				end
			end)
		end)
		self.optionCallbackHooked = true
	end
end

-- Update highlight settings for all processed buttons
function module:UpdateAllHighlights()
	debug("InventorySlots: Updating all highlights")
	local settings = E.db.bagCustomizer.inventorySlots
	if not settings or not settings.enable then
		return
	end

	local useElvUI = not settings.disableElvUIHighlight
	debug("InventorySlots: Setting all highlights to use " ..
		(useElvUI and "ElvUI" or "custom") .. " system")
	-- OPTIMIZATION: Batch highlight updates
	for button in pairs(processedSlots) do
		if button and button._BCZ then
			-- Skip bank slots
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			-- Skip if this is a bank bag
			if bagID and self:IsBankBag(bagID) then
				return
			end

			-- Skip if button is in a bank frame
			if button:GetParent() and self:IsBankFrame(button:GetParent()) then
				return
			end

			self:ToggleHighlightSystem(button, useElvUI)
			self:QueueButtonForUpdate(button)
		end
	end
end

-- Method for UpdateHighlightState which might be called from options
function module:UpdateHighlightState()
	debug("InventorySlots: Updating highlight state")
	self:UpdateAllHighlights()
end

function module:UpdateEmptySlotBorderStyles()
	debug("InventorySlots: Explicitly updating empty slot border styles")
	-- First, invalidate relevant texture caches
	self:InvalidateTextureCache("BorderStyle")
	self:InvalidateTextureCache("EmptyBorderStyle")
	-- Force refresh of assigned bags
	self:CollectAssignedBags(true)
	-- Then directly update all empty slots
	local count = 0
	for button in pairs(processedSlots) do
		if button and button._BCZ and not button.hasItem then
			-- Skip bank slots
			local bagID = button.bagID
			if not bagID and button:GetParent() and button:GetParent():GetID() then
				bagID = button:GetParent():GetID()
			end

			-- Skip if this is a bank bag
			if bagID and self:IsBankBag(bagID) then
				return
			end

			-- Skip if button is in a bank frame
			if button:GetParent() and self:IsBankFrame(button:GetParent()) then
				return
			end

			-- For empty slots, explicitly update border textures
			if button._BCZ.borderTexture then
				local settings = E.db.bagCustomizer.inventorySlots
				local currentTextures = GetButtonTextures()
				-- Determine assigned status
				local assignedBags = self:CollectAssignedBags(false)
				local isAssigned = false
				if bagID then
					local filterType = assignedBags[bagID]
					isAssigned = filterType ~= nil and filterType ~= ""
					button._BCZ_isAssignedBag = isAssigned
					button._BCZ_assignmentType = isAssigned and filterType or nil
				end

				-- Explicitly determine border texture based on current settings
				local borderTextureToUse = currentTextures.Border -- Default
				if settings.applyMainBorderToEmptyAssigned and isAssigned then
					borderTextureToUse = currentTextures.Border
				elseif settings.separateEmptyBorder then
					borderTextureToUse = currentTextures.EmptyBorder
				end

				-- Force apply the border texture
				button._BCZ.borderTexture:SetTexture(borderTextureToUse)
				-- Force update to ensure color is correct too
				button._BCZ_forceUpdate = true
				self:UpdateSlot(button)
				count = count + 1
			end
		end
	end

	debug("InventorySlots: Updated border styles for " .. count .. " empty slot buttons")
end

-- Clear the color cache
function module:ClearColorCache()
	colorCache = {}
end

-- Reset internal state before a forced theme/import update
function module:ResetForForcedUpdate()
	debug("InventorySlots: Resetting state for forced update.")
	-- 1. Clear Core Caches
	buttonTexturesCache = {}
	colorCache = {}
	visibilityCache = {}
	assignedBagsCache = {}
	assignedBagsCacheTime = 0
	extractedElvUIHighlight = nil -- Reset highlight cache too
	-- 2. Clear Update Queue System
	updateQueue = {}
	isUpdateScheduled = false
	-- 3. Reset Throttling State on Existing Skinned Buttons
	--    This ensures the next UpdateSlot call won't be throttled.
	local count = 0
	for button, _ in pairs(processedSlots) do
		if button and button._BCZ then
			-- Clear values that UpdateSlot uses for throttling checks
			button._BCZ.lastUpdateTime = nil
			button._BCZ.lastBorderR = nil -- Clear cached border color
			button._BCZ.lastBorderG = nil
			button._BCZ.lastBorderB = nil
			button._BCZ.lastFilterType = nil       -- Clear cached assignment
			button._BCZ.state = "needs_forced_update" -- Set a unique state to ensure comparison fails
			count = count + 1
		end
	end

	debug("InventorySlots: Reset throttling state for " .. count .. " processed slots.")
	-- 4. Clear the main processed slots list itself?
	--    NO - Keep this list. Reverting slots is only needed on disable/reset.
	--    We just need to ensure the *next* update fully re-evaluates these slots.
	-- processedSlots = {} -- DO NOT DO THIS HERE
	collectgarbage("step", 50) -- Minor GC nudge
end

-- Initialize the module
function module:Initialize()
	-- Setup hooks into ElvUI's bag implementation
	self:SetupHooks()
	-- Setup hooks for bag assignment changes
	self:SetupAssignmentHooks()
	-- Setup options callbacks
	self:SetupOptionsCallbacks()
	-- Initialize colors for performance
	self:InitializeColors()
	-- Initialize brightness settings (global and individual)
	self:InitializeBrightnessSettings()
	-- Add combat-aware initialization
	self.pendingInitialization = false
	-- Register for combat end event
	addon:RegisterForEvent("COMBAT_ENDED", function()
		if self.pendingInitialization then
			self.pendingInitialization = false
			debug("InventorySlots: Combat ended - completing deferred initialization")
			C_Timer.After(0.2, function()
				self:UpdateAll()
			end)
		end
	end)
	-- Modify the existing RegisterElementUpdate function
	addon:RegisterElementUpdate("inventorySlots", function(reason, immediate)
		if addon.inCombat then
			local isFirstUpdate = reason and (reason:find("first") or reason:find("Initial"))
			if isFirstUpdate then
				-- Mark for initialization after combat
				self.pendingInitialization = true
				debug("InventorySlots: Deferring initialization until combat ends")
				return
			end

			if addon:IsAnyBagVisible() then
				-- Limited updates during combat
				if self.needsFullUpdate then
					self.needsFullUpdate = false
					C_Timer.After(0.2, function()
						self:UpdateAll()
					end)
				end
			end
		else
			-- Normal non-combat updates...
			local isFirstUpdate = reason and (reason:find("first") or reason:find("Initial"))
			if immediate or isFirstUpdate then
				-- Immediate full update
				self:UpdateAll()
			else
				-- Batch updates for better performance
				self:BatchUpdateButtons(false)
			end
		end
	end)
	-- Initial state check after a delay
	C_Timer.After(1.0, function()
		-- Force a complete state check
		self:ToggleState()
	end)
	-- First-time open detection (#3)
	C_Timer.After(0.2, function()
		if addon:IsAnyBagVisible() and addon.firstTimeOpens and
				addon.firstTimeOpens.bags == false then
			-- Bags already open when addon loaded
			debug("InventorySlots: Detected bags already open - applying styles")
			self:UpdateAll()
		end
	end)
	debug("InventorySlots: Module initialized")
end

function module:Cleanup()
	debug("InventorySlots: Performing full module cleanup")
	-- Revert all slots to original state
	self:RevertAllSlots()
	-- Clear all caches thoroughly
	buttonTexturesCache = {}
	colorCache = {}
	visibilityCache = {}
	-- Clear update queue system
	updateQueue = {}
	isUpdateScheduled = false
	debug("InventorySlots: Cleanup complete")
end

-- Reset all caches and force update
function module:ResetAll()
	-- Clear all caches
	assignedBagsCache = {}
	assignedBagsCacheTime = 0
	self:InvalidateTextureCache()
	extractedElvUIHighlight = nil
	colorCache = {}
	visibilityCache = {}
	lastVisibilityUpdate = 0
	-- Batch update buttons
	self:BatchUpdateButtons(true)
end

-- Expose module functions
module.availableTextures = availableTextures
module.presetComponentMap = presetComponentMap
module.processedSlots = processedSlots
module.GetButtonTextures = GetButtonTextures
module.UpdateAllTextureAlpha = module.UpdateAllTextureAlpha
-- Register the module
addon.elements.inventorySlots = module
