-- ElvUI Bag Customizer - Currency and Textures Module
local E = unpack(ElvUI)
local addon = E:GetModule("BagCustomizer")
-- Create module with consistent naming
local currencyAndTextures = {}
addon.elements.currencyAndTextures = currencyAndTextures
-- For backward compatibility - maintain original namespaces
addon.elements.currency = currencyAndTextures
addon.elements.miscTextures = currencyAndTextures
-- Cache frequently accessed functions for performance
local GetWidth, GetHeight = UIParent.GetWidth, UIParent.GetHeight
local ClearAllPoints, SetPoint = UIParent.ClearAllPoints, UIParent.SetPoint
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
-- ==========================================
-- Module Configuration - Reference from Settings
-- ==========================================
-- Constants
local BOTTOM_OFFSET = 8
local MINIMAL_PADDING = 8
-- ==========================================
-- State Tracking
-- ==========================================
local isHooked = false
local originalLayout = nil
local inUpdate = false -- Prevent recursive updates
local currentDimensions = {}
-- Track active textures
currencyAndTextures.activeTextures = {}
-- ==========================================
-- Debug Function - Using consistent pattern
-- ==========================================
local function debug(section, msg)
	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return
	end

	if not E.db.bagCustomizer.debug then
		return
	end

	local moduleDebug = false
	if section == "currency" then
		moduleDebug = E.db.bagCustomizer.currency and E.db.bagCustomizer.currency.debug
	elseif section == "miscTextures" then
		moduleDebug = E.db.bagCustomizer.miscTextures and E.db.bagCustomizer.miscTextures.debug
	end

	if not moduleDebug then
		return
	end

	-- Use timestamp format consistent with Core.lua
	local timestamp = date("%H:%M:%S")
	print("|cFF00FF00Bag Customizer [" .. timestamp .. "]:|r [" .. section .. "] " .. tostring(msg))
end

-- ==========================================
-- Utility Functions
-- ==========================================
local function GetBagsModule()
	return E:GetModule("Bags")
end

function currencyAndTextures:IsAnyBagVisible()
	local f = self:GetBagFrame()
	return f and f:IsShown()
end

function currencyAndTextures:ShouldSkipUpdate(isGoldTextUpdate)
	-- If this is a gold text update, allow it even in combat
	if isGoldTextUpdate then
		return false
	end

	return addon.inCombat and not self:IsAnyBagVisible()
end

function currencyAndTextures:ShouldUpdateFrame(frame)
	if not frame or not frame:IsShown() then
		return false
	end

	if self:ShouldSkipUpdate() then
		return false
	end

	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return false
	end

	if not E.db.bagCustomizer.enabled then
		return false
	end

	-- Additional check to ensure we never affect bank frames
	if self:IsBankFrame(frame) then
		return false
	end

	return true
end

function currencyAndTextures:GetBagFrame()
	local B = GetBagsModule()
	if B and B.BagFrame then
		return B.BagFrame
	end

	return self:FindBagFrame()
end

function currencyAndTextures:FindBagFrame()
	local B = GetBagsModule()
	if B then
		if B.BagFrame and B.BagFrame:IsShown() then
			return B.BagFrame
		end

		if B.BagFrameHolder and B.BagFrameHolder:IsShown() then
			return B.BagFrameHolder
		end
	end

	local names = { "ElvUI_ContainerFrame", "ElvUIBags", "ElvUI_BagFrame" }
	for _, n in ipairs(names) do
		local f = _G[n]
		if f and f:IsShown() then
			return f
		end
	end

	return nil
end

function currencyAndTextures:IsBankFrame(frame)
	if not frame then
		return false
	end

	local n = frame:GetName() or ""
	if n:find("Bank") or n:find("bank") then
		return true
	end

	local B = GetBagsModule()
	if B and ((B.BankFrame and frame == B.BankFrame) or (B.WarbankFrame and frame == B.WarbankFrame)) then
		return true
	end

	if frame.bankID or frame.isBank or frame.bagFrameType == "BANK" then
		return true
	end

	return false
end

-- Texture tracking integrated with resource pool
function currencyAndTextures:TrackTexture(texture, owner, key)
	if not texture or not owner then
		return
	end

	local ownerKey = owner:GetName() or tostring(owner)
	if not self.activeTextures[ownerKey] then
		self.activeTextures[ownerKey] = {}
	end

	local old = self.activeTextures[ownerKey][key]
	if old and old ~= texture then
		-- Simply hide old texture instead of releasing it
		old:Hide()
		old:SetParent(nil)
	end

	self.activeTextures[ownerKey][key] = texture
end

function currencyAndTextures:ReleaseTrackedTextures(owner, key)
	if not owner then
		return
	end

	local ownerKey = owner:GetName() or tostring(owner)
	if not self.activeTextures[ownerKey] then
		return
	end

	if key then
		if self.activeTextures[ownerKey][key] then
			pcall(function()
				-- Use the addon's texture release function
				addon:ReleaseTexture(self.activeTextures[ownerKey][key])
				self.activeTextures[ownerKey][key] = nil
			end)
		end
	else
		for k, t in pairs(self.activeTextures[ownerKey]) do
			pcall(function()
				addon:ReleaseTexture(t)
			end)
		end

		self.activeTextures[ownerKey] = nil
	end
end

function currencyAndTextures:CreateOrReuseTexture(parent, layer, sublayer, key)
	-- Always use pooled texture from ResourceManager
	local texture = addon:GetPooledTexture(parent, layer, sublayer)
	if texture and parent and key then
		self:TrackTexture(texture, parent, key)
	end

	return texture
end

-- ==========================================
-- Dimension Calculations
-- ==========================================
function currencyAndTextures:GetEffectiveTextureHeight()
	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return 24
	end

	local rowHeight = 24
	local offset = E.db.bagCustomizer.textureHeightOffset or 0
	return rowHeight + offset
end

function currencyAndTextures:CalculateDimensions()
	currentDimensions = {}
	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		currentDimensions.paddingSizeBRBC = 24
		currentDimensions.paddingSizeBRAC = 34
		currentDimensions.rowHeight = 30
		return currentDimensions
	end

	local B = GetBagsModule()
	local bagFrame = self:GetBagFrame()
	local currencyButton = bagFrame and bagFrame.currencyButton
	-- Set default dimensions from settings
	currentDimensions.paddingSizeBRBC = E.db.bagCustomizer.currencyPaddingSize or 24
	currentDimensions.paddingSizeBRAC = E.db.bagCustomizer.currencyTopPadding or 34
	currentDimensions.rowHeight = 30 -- Reference height for a single row
	-- Store the current actual height if the button exists (might be useful for debugging or other calcs)
	local actualHeight = 0
	if currencyButton and currencyButton:IsShown() then
		actualHeight = floor(currencyButton:GetHeight() + 0.5)
	end

	currentDimensions.currencyFrameActualHeight = actualHeight -- Store for potential reference
	-- *** The numCurrencyRows calculation is intentionally REMOVED here ***
	-- It will be calculated accurately inside the B.Layout hook after ElvUI positions the tokens.
	-- Calculate dimensions related to the gold text/texture positioning
	local baseTextureHeight = self:GetEffectiveTextureHeight()
	if E.db.bagCustomizer.goldAnchorPosition == "BOTTOM_RIGHT_BELOW" then
		local baseY = 8
		local heightAdjust = 0
		currentDimensions.goldTextYPos = baseY + heightAdjust -- Y position relative to bag bottom for gold text/texture
	end

	-- Calculate the height for the gold text background texture
	local goldTextureOffset = E.db.bagCustomizer.textureHeightOffset or -4
	currentDimensions.goldTextureHeight = currentDimensions.rowHeight + goldTextureOffset
	-- Return the dimensions table (without numCurrencyRows)
	return currentDimensions
end

-- ==========================================
-- Layout Hook & Padding
-- ==========================================
function currencyAndTextures:ResetInventoryTopOffset(frame)
	frame = frame or self:GetBagFrame()
	if not frame then
		return
	end

	if frame._BCZ_originalHeight ~= nil then
		frame:SetHeight(frame._BCZ_originalHeight)
		frame._BCZ_originalHeight = nil
	end

	if frame._BCZ_originalTopOffset ~= nil then
		frame.topOffset = frame._BCZ_originalTopOffset
		frame._BCZ_originalTopOffset = nil
	end

	local currencyFrame = frame.currencyButton
	if currencyFrame then
		if currencyFrame._BCZ_originalHeight then
			currencyFrame:SetHeight(currencyFrame._BCZ_originalHeight)
			currencyFrame._BCZ_originalHeight = nil
			currencyFrame._BCZ_HeightIncreased = nil
		end

		if currencyFrame._BCZ_originalXOffset ~= nil then
			local p, rT, rP, _, yO = currencyFrame:GetPoint(1)
			if p then
				currencyFrame:SetPoint(p, rT, rP, currencyFrame._BCZ_originalXOffset, yO)
			end

			currencyFrame._BCZ_originalXOffset = nil
		end
	end
end

function currencyAndTextures:ApplyCurrencyPaddingBRBCLayout(B, currencyFrame, bagFrame, skipVerticalPadding)
	local paddingSize = currentDimensions.paddingSizeBRBC or 24
	local currentHeight = currencyFrame:GetHeight()
	-- Store original values if not already stored
	if bagFrame._BCZ_originalTopOffset == nil then
		bagFrame._BCZ_originalTopOffset = bagFrame.topOffset or 0
	end

	if bagFrame._BCZ_originalHeight == nil then
		bagFrame._BCZ_originalHeight = bagFrame:GetHeight()
	end

	if currencyFrame._BCZ_originalHeight == nil then
		currencyFrame._BCZ_originalHeight = currentHeight
	end

	if currencyFrame._BCZ_originalXOffset == nil then
		local _, _, _, xO, _ = currencyFrame:GetPoint(1)
		currencyFrame._BCZ_originalXOffset = xO or 0
	end

	-- Apply vertical adjustments only if not skipped
	if not skipVerticalPadding then
		currencyFrame:SetHeight(currentHeight + paddingSize)
		currencyFrame._BCZ_HeightIncreased = true
		local newTopOffset = bagFrame._BCZ_originalTopOffset + paddingSize
		local newHeight = bagFrame._BCZ_originalHeight + paddingSize
		bagFrame.topOffset = newTopOffset
		bagFrame:SetHeight(newHeight)
	end

	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return
	end

	-- Apply horizontal padding if needed (always do this)
	local horizontalPadding = E.db.bagCustomizer.currencyHorizontalPadding or 0
	if horizontalPadding ~= 0 then
		local p, rT, rP, _, yO = currencyFrame:GetPoint(1)
		if p then
			debug("currency", "Applying horizontal padding: " .. horizontalPadding ..
				" to currency frame in mode " .. (E.db.bagCustomizer.goldAnchorPosition or "unknown"))
			currencyFrame:SetPoint(p, rT, rP, currencyFrame._BCZ_originalXOffset + horizontalPadding, yO)
			currencyFrame:SetPoint(p, rT, rP, currencyFrame._BCZ_originalXOffset + horizontalPadding, yO)
		end
	end
end

function currencyAndTextures:ApplyCurrencyPaddingBRACLayout(B, currencyFrame, bagFrame)
	local paddingSize = currentDimensions.paddingSizeBRAC or 34
	local currentHeight = currencyFrame:GetHeight()
	-- Store original values if not already stored for this cycle
	if bagFrame._BCZ_originalTopOffset == nil then
		bagFrame._BCZ_originalTopOffset = bagFrame.topOffset or 0
	end

	if bagFrame._BCZ_originalHeight == nil then
		bagFrame._BCZ_originalHeight = bagFrame:GetHeight()
	end

	if currencyFrame._BCZ_originalHeight == nil then
		currencyFrame._BCZ_originalHeight = currentHeight
	end

	if currencyFrame._BCZ_originalXOffset == nil then
		local _, _, _, xO, _ = currencyFrame:GetPoint(1)
		currencyFrame._BCZ_originalXOffset = xO or 0
	end

	-- 1. Adjust currency frame height FIRST
	currencyFrame:SetHeight(currentHeight + paddingSize)
	currencyFrame._BCZ_HeightIncreased = true
	-- 2. Adjust bag frame geometry
	local newTopOffset = bagFrame._BCZ_originalTopOffset + paddingSize
	local newHeight = bagFrame._BCZ_originalHeight + paddingSize
	bagFrame.topOffset = newTopOffset
	bagFrame:SetHeight(newHeight)
	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return
	end

	-- 3. Apply Horizontal Padding to currency frame
	local horizontalPadding = E.db.bagCustomizer.currencyHorizontalPadding or 0
	if horizontalPadding ~= 0 then
		local p, rT, rP, _, yO = currencyFrame:GetPoint(1)
		if p then
			currencyFrame:SetPoint(p, rT, rP, currencyFrame._BCZ_originalXOffset + horizontalPadding, yO)
		end
	end

	-- 4. Adjust Token Y Positions AFTER frame resize
	debug("currency", "BRAC Layout: Attempting token adjustment via simplified child iteration...")
	local tokensAdjusted = 0
	local childCount = currencyFrame:GetNumChildren()
	for i = 1, childCount do
		local child = select(i, currencyFrame:GetChildren())
		-- Check if it's a Button and if it's currently shown
		if child and child:IsObjectType("Button") and child:IsShown() then
			-- Assume any shown button child is a token for this test
			local point, relativeTo, relativePoint, x, y = child:GetPoint(1)
			if point then -- Check if GetPoint returns valid data
				debug("currency",
					" -> Adjusting Child #" .. i .. " ('" ..
					(child:GetName() or "Unnamed") .. "') Y from " ..
					y .. " to " .. (y - paddingSize))
				child:ClearAllPoints()
				child:SetPoint(point, relativeTo, relativePoint, x, y - paddingSize) -- Apply adjustment
				tokensAdjusted = tokensAdjusted + 1
			else
				debug("currency", " -> Child #" .. i .. " ('" ..
					(child:GetName() or "Unnamed") .. "') - GetPoint failed.")
			end
		end
	end

	debug("currency", "BRAC Layout: Finished token adjustment attempt. Adjusted " .. tokensAdjusted .. " children.")
end

function currencyAndTextures:HandleNoCurrenciesBRBC(bagFrame)
	-- Use the standard currency padding instead of minimal padding
	local paddingSize = currentDimensions.paddingSizeBRBC or 24
	if bagFrame._BCZ_originalTopOffset == nil then
		bagFrame._BCZ_originalTopOffset = bagFrame.topOffset or 0
	end

	if bagFrame._BCZ_originalHeight == nil then
		bagFrame._BCZ_originalHeight = bagFrame:GetHeight()
	end

	local newTopOffset = bagFrame._BCZ_originalTopOffset + paddingSize
	local newHeight = bagFrame._BCZ_originalHeight + paddingSize
	bagFrame.topOffset = newTopOffset
	bagFrame:SetHeight(newHeight)
	-- Store the virtual currency height in dimensions for other functions to use
	currentDimensions.virtualCurrencyHeight = paddingSize
	debug("currency", "HandleNoCurrenciesBRBC: Applied padding: " .. paddingSize)
end

function currencyAndTextures:HandleNoCurrenciesBRAC(bagFrame)
	-- Use the standard currency padding instead of minimal padding
	local paddingSize = currentDimensions.paddingSizeBRAC or 34
	if bagFrame._BCZ_originalTopOffset == nil then
		bagFrame._BCZ_originalTopOffset = bagFrame.topOffset or 0
	end

	if bagFrame._BCZ_originalHeight == nil then
		bagFrame._BCZ_originalHeight = bagFrame:GetHeight()
	end

	local newTopOffset = bagFrame._BCZ_originalTopOffset + paddingSize
	local newHeight = bagFrame._BCZ_originalHeight + paddingSize
	bagFrame.topOffset = newTopOffset
	bagFrame:SetHeight(newHeight)
	-- Store the virtual currency height in dimensions for other functions to use
	currentDimensions.virtualCurrencyHeight = paddingSize
	debug("currency", "HandleNoCurrenciesBRAC: Applied padding: " .. paddingSize)
end

function currencyAndTextures:SetupHooks(isEnabled)
	local B = GetBagsModule()
	if not B then return end

	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		if isHooked then
			debug("currency", "SetupHooks: Database not available, unhooking.")
			self:UnhookAll()
			self:ResetGoldText()
		end

		return
	end

	if (not E.db.bagCustomizer.enabled or not isEnabled or not E.db.bagCustomizer.currencyModuleEnabled) then
		if isHooked then
			debug("currency", "SetupHooks: Disabling/Unhooking.")
			self:UnhookAll()
			self:ResetGoldText()
			if self:IsAnyBagVisible() and B.Layout then
				B:Layout()
			end
		end

		return
	end

	if isEnabled and E.db.bagCustomizer.enabled and E.db.bagCustomizer.currencyModuleEnabled and not isHooked then
		if not originalLayout then
			originalLayout = B.Layout
			debug("currency", "Hooking B.Layout function")
			B.Layout = function(self, isBank)
				if inUpdate then return end

				inUpdate = true
				-- Reset frame offsets before original layout
				local frameToReset = isBank and B.BankFrame or B.BagFrame
				if frameToReset then
					currencyAndTextures:ResetInventoryTopOffset(frameToReset)
				end

				-- Call original layout function with error protection
				local success, err = pcall(originalLayout, self, isBank)
				if not success then
					debug("currency", "ERROR in original B.Layout: " .. tostring(err))
				end

				-- Get current bag frame
				local bagFrame = isBank and B.BankFrame or B.BagFrame
				-- Check if we should proceed
				if not bagFrame or not bagFrame:IsShown() then
					inUpdate = false
					return
				end

				-- Added defensive check for E.db and E.db.bagCustomizer
				if not E or not E.db or not E.db.bagCustomizer then
					inUpdate = false
					return
				end

				if not E.db.bagCustomizer.currencyModuleEnabled or
						not E.db.bagCustomizer.enabled then
					inUpdate = false
					return
				end

				-- Skip if this is a bank frame
				if isBank or currencyAndTextures:IsBankFrame(bagFrame) then
					inUpdate = false
					return
				end

				-- Calculate accurate dimensions AFTER original layout
				currencyAndTextures:CalculateDimensions()
				-- Setup currency information
				local currencyFrame = bagFrame.currencyButton
				local actualRows = 0
				local hasTokens = false
				if currencyFrame and self.numTrackedTokens > 0 then
					local actualHeight = currencyFrame:GetHeight()
					actualRows = (actualHeight > 0) and math.floor(actualHeight / 24 + 0.5) or 0
					debug("currency",
						"Layout Hook: Calculated actualRows = " .. actualRows .. " from height " .. actualHeight)
					hasTokens = actualRows > 0
				else
					debug("currency", "Layout Hook: No currency button or 0 tokens.")
				end

				debug("currency", "Layout Hook: Calculated actualRows = " .. actualRows ..
					", hasTokens = " .. tostring(hasTokens) ..
					", Mode = " .. E.db.bagCustomizer.goldAnchorPosition)
				currentDimensions.numCurrencyRows = actualRows
				-- Get current mode and debug it
				local anchorPos = E.db.bagCustomizer.goldAnchorPosition
				debug("currency", "Processing mode: " .. anchorPos)
				-- Process each mode in clear if/elseif blocks
				-- DEFAULT MODE
				if anchorPos == "DEFAULT" then
					debug("currency", "DEFAULT MODE TRIGGERED")
					if E.db.bagCustomizer.fixGoldTextStrata then
						currencyAndTextures:ApplyGoldTextFix(bagFrame)
					end

					currencyAndTextures:ApplyCloseButtonTexture(bagFrame)
					-- CURRENCY_ONLY MODE
				elseif anchorPos == "CURRENCY_ONLY" then
					debug("currency", "CURRENCY_ONLY MODE TRIGGERED")
					debug("currency", "CURRENCY_ONLY MODE: hasTokens = " .. tostring(hasTokens) ..
						", numTrackedTokens = " .. (self.numTrackedTokens or 0))
					-- Disable gold texture
					currencyAndTextures:RevertGoldTextTexture(bagFrame)
					-- Apply currency frame padding with vertical padding skipped
					if currencyFrame then
						currencyAndTextures:ApplyCurrencyPaddingBRBCLayout(self, currencyFrame, bagFrame, true)
					end

					debug("currency", "CURRENCY_ONLY pre-texture decision: currencyFrame exists = " ..
						tostring(currencyFrame ~= nil) .. ", hasTokens = " .. tostring(hasTokens) ..
						", texture enabled = " .. tostring(E.db.bagCustomizer.currencyTexture and
							E.db.bagCustomizer.currencyTexture.enable))
					-- Apply the currency texture - EXACT SAME FORMAT as BRAC/BRBC
					if currencyFrame and hasTokens and E.db.bagCustomizer.currencyTexture and E.db.bagCustomizer.currencyTexture.enable then
						currencyAndTextures:ApplyCurrencyFrameTexture(bagFrame)
					else
						currencyAndTextures:RevertCurrencyFrameTexture(bagFrame)
					end

					-- Apply gold text fix if needed
					if E.db.bagCustomizer.fixGoldTextStrata then
						currencyAndTextures:ApplyGoldTextFix(bagFrame)
					end

					-- Apply close button texture
					currencyAndTextures:ApplyCloseButtonTexture(bagFrame)
					-- GOLD_ONLY MODE
				elseif anchorPos == "GOLD_ONLY" then
					debug("currency", "GOLD_ONLY MODE TRIGGERED")
					-- Disable currency texture
					currencyAndTextures:RevertCurrencyFrameTexture(bagFrame)
					-- Apply gold text position and texture
					currencyAndTextures:RepositionGoldText(bagFrame)
					if E.db.bagCustomizer.goldTextTexture and E.db.bagCustomizer.goldTextTexture.enable then
						currencyAndTextures:ApplyGoldTextTexture(bagFrame)
					end

					-- Apply gold text fix if needed
					if E.db.bagCustomizer.fixGoldTextStrata then
						currencyAndTextures:ApplyGoldTextFix(bagFrame)
					end

					-- Apply close button texture
					currencyAndTextures:ApplyCloseButtonTexture(bagFrame)
					-- BOTTOM_CURRENCY_TOP_GOLD MODE
				elseif anchorPos == "BOTTOM_CURRENCY_TOP_GOLD" then
					debug("currency", "BCTG MODE TRIGGERED")
					-- 1. EXPLICITLY call RepositionGoldText to restore original position
					currencyAndTextures:RepositionGoldText(bagFrame)
					-- 2. Apply currency frame padding like CO mode
					if currencyFrame then
						currencyAndTextures:ApplyCurrencyPaddingBRBCLayout(self, currencyFrame, bagFrame, true)
					end

					-- 3. Apply currency texture - EXACT SAME FORMAT as BRAC/BRBC
					if currencyFrame and hasTokens and E.db.bagCustomizer.currencyTexture and E.db.bagCustomizer.currencyTexture.enable then
						currencyAndTextures:ApplyCurrencyFrameTexture(bagFrame)
					else
						currencyAndTextures:RevertCurrencyFrameTexture(bagFrame)
					end

					-- 4. Apply gold texture
					if E.db.bagCustomizer.goldTextTexture and E.db.bagCustomizer.goldTextTexture.enable then
						currencyAndTextures:ApplyGoldTextTexture(bagFrame)
					else
						currencyAndTextures:RevertGoldTextTexture(bagFrame)
					end

					-- 5. Apply gold text fix if needed
					if E.db.bagCustomizer.fixGoldTextStrata then
						currencyAndTextures:ApplyGoldTextFix(bagFrame)
					end

					-- 6. Apply close button texture
					currencyAndTextures:ApplyCloseButtonTexture(bagFrame)
					-- BOTTOM_RIGHT_BELOW MODE
				elseif anchorPos == "BOTTOM_RIGHT_BELOW" then
					debug("currency", "BOTTOM_RIGHT_BELOW MODE TRIGGERED")
					if currencyFrame then
						if hasTokens then
							currencyAndTextures:ApplyCurrencyPaddingBRBCLayout(self, currencyFrame, bagFrame)
						else
							currencyAndTextures:HandleNoCurrenciesBRBC(bagFrame)
						end
					else
						currencyAndTextures:HandleNoCurrenciesBRBC(bagFrame)
					end

					currencyAndTextures:RepositionGoldText(bagFrame)
					if E.db.bagCustomizer.fixGoldTextStrata then
						currencyAndTextures:ApplyGoldTextFix(bagFrame)
					end

					-- Apply currency frame texture
					if currencyFrame and hasTokens and E.db.bagCustomizer.currencyTexture and E.db.bagCustomizer.currencyTexture.enable then
						currencyAndTextures:ApplyCurrencyFrameTexture(bagFrame)
					else
						currencyAndTextures:RevertCurrencyFrameTexture(bagFrame)
					end

					-- Apply gold texture
					if E.db.bagCustomizer.goldTextTexture and E.db.bagCustomizer.goldTextTexture.enable then
						currencyAndTextures:ApplyGoldTextTexture(bagFrame)
					else
						currencyAndTextures:RevertGoldTextTexture(bagFrame)
					end

					-- Apply close button texture
					currencyAndTextures:ApplyCloseButtonTexture(bagFrame)
					-- BOTTOM_RIGHT_ABOVE MODE
				elseif anchorPos == "BOTTOM_RIGHT_ABOVE" then
					debug("currency", "BOTTOM_RIGHT_ABOVE MODE TRIGGERED")
					if currencyFrame then
						if hasTokens then
							currencyAndTextures:ApplyCurrencyPaddingBRACLayout(self, currencyFrame, bagFrame)
						else
							currencyAndTextures:HandleNoCurrenciesBRAC(bagFrame)
						end
					else
						currencyAndTextures:HandleNoCurrenciesBRAC(bagFrame)
					end

					currencyAndTextures:RepositionGoldText(bagFrame)
					if E.db.bagCustomizer.fixGoldTextStrata then
						currencyAndTextures:ApplyGoldTextFix(bagFrame)
					end

					-- Apply currency frame texture
					if currencyFrame and hasTokens and E.db.bagCustomizer.currencyTexture and E.db.bagCustomizer.currencyTexture.enable then
						currencyAndTextures:ApplyCurrencyFrameTexture(bagFrame)
					else
						currencyAndTextures:RevertCurrencyFrameTexture(bagFrame)
					end

					-- Apply gold texture
					if E.db.bagCustomizer.goldTextTexture and E.db.bagCustomizer.goldTextTexture.enable then
						currencyAndTextures:ApplyGoldTextTexture(bagFrame)
					else
						currencyAndTextures:RevertGoldTextTexture(bagFrame)
					end

					-- Apply close button texture
					currencyAndTextures:ApplyCloseButtonTexture(bagFrame)
					-- FALLBACK (unknown mode)
				else
					debug("currency", "UNKNOWN MODE: " .. anchorPos)
					-- Apply close button texture as minimal action
					currencyAndTextures:ApplyCloseButtonTexture(bagFrame)
				end

				inUpdate = false
				-- Trigger event for dimension updates - using event bus
				addon:TriggerEvent("CURRENCY_DIMENSIONS_UPDATED", currentDimensions)
			end -- End B.Layout function
		end -- End if not originalLayout

		isHooked = true
		debug("currency", "Successfully setup Layout hook.")
	end
end

function currencyAndTextures:UnhookAll()
	local B = GetBagsModule()
	if not B then
		return
	end

	if isHooked then
		if originalLayout then
			B.Layout = originalLayout
			originalLayout = nil
			debug("currency", "Restored B.Layout")
		end

		isHooked = false
		debug("currency", "Removed hooks.")
	end
end

-- ==========================================
-- Gold Text Positioning & Fix
-- ==========================================
function currencyAndTextures:UpdateGoldTextPositionImmediately()
	local bagFrame = self:GetBagFrame()
	if not bagFrame or not bagFrame.goldText then
		return
	end

	-- Skip most checks for immediate updates
	if not E or not E.db or not E.db.bagCustomizer then
		return
	end

	if not E.db.bagCustomizer.enabled or not E.db.bagCustomizer.currencyModuleEnabled then
		return
	end

	debug("currency", "Immediate gold text update triggered")
	-- Apply gold text positioning without delays
	self:RepositionGoldText(bagFrame)
	-- Apply gold text texture if enabled
	if E.db.bagCustomizer.goldTextTexture and E.db.bagCustomizer.goldTextTexture.enable then
		self:ApplyGoldTextTexture(bagFrame)
	end

	-- Apply gold text fix if needed
	if E.db.bagCustomizer.fixGoldTextStrata then
		self:ApplyGoldTextFix(bagFrame)
	end
end

function currencyAndTextures:RepositionGoldText(bagFrame)
	bagFrame = bagFrame or self:GetBagFrame()
	if not bagFrame or self:IsBankFrame(bagFrame) then
		return
	end

	local goldText = bagFrame.goldText
	if not goldText then
		return
	end

	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return
	end

	if not E.db.bagCustomizer.enabled or not E.db.bagCustomizer.currencyModuleEnabled then
		return
	end

	local anchorPos = E.db.bagCustomizer.goldAnchorPosition
	debug("currency", "RepositionGoldText: Processing mode " .. anchorPos)
	-- For DEFAULT mode - restore original position
	if anchorPos == "DEFAULT" then
		-- Restore original position if we have stored it
		if goldText._origPoints then
			debug("currency", "RepositionGoldText: Restoring original position")
			goldText:ClearAllPoints()
			for i = 1, #goldText._origPoints do
				goldText:SetPoint(unpack(goldText._origPoints[i]))
			end

			-- Don't set _origPoints to nil, we might need it again when switching modes
		end

		return
	end

	-- Handle GOLD_ONLY and BOTTOM_CURRENCY_TOP_GOLD the same way
	if anchorPos == "GOLD_ONLY" or anchorPos == "BOTTOM_CURRENCY_TOP_GOLD" then
		-- Store original points if this is first time we're modifying position
		if not goldText._origPoints then
			goldText._origPoints = {}
			for i = 1, goldText:GetNumPoints() do
				goldText._origPoints[i] = { goldText:GetPoint(i) }
			end

			debug("currency", "GO/BCTG: Stored original position")
		end

		-- Get user-defined offsets
		local xOffsetUser = E.db.bagCustomizer.goldTextXOffset or 0
		local yOffsetUser = E.db.bagCustomizer.goldTextYOffset or 0
		-- Add internal -10x offset specific to these modes
		local internalXOffset = -10
		-- Apply identical positioning for both modes
		goldText:ClearAllPoints()
		-- Use original position as base but apply offsets
		if goldText._origPoints and #goldText._origPoints > 0 then
			local origPoint = goldText._origPoints[1]
			local point, relativeTo, relativePoint, x, y = unpack(origPoint)
			goldText:SetPoint(point, relativeTo, relativePoint,
				x + xOffsetUser + internalXOffset, y + yOffsetUser)
			debug("currency", "GO/BCTG: Applied offsets: user(" .. xOffsetUser .. "," ..
				yOffsetUser .. "), internal(" .. internalXOffset .. ",0)")
		else
			-- Fallback if no original points stored
			goldText:SetPoint("BOTTOMRIGHT", bagFrame, "BOTTOMRIGHT",
				-6 + xOffsetUser + internalXOffset, 6 + yOffsetUser)
		end

		return
	end

	-- Only BRBC and BRAC modes should reach this point
	-- Store original points if this is first time we're modifying position
	if not goldText._origPoints then
		goldText._origPoints = {}
		for i = 1, goldText:GetNumPoints() do
			goldText._origPoints[i] = { goldText:GetPoint(i) }
		end

		debug("currency", "RepositionGoldText: Stored original position")
	end

	local dims = currentDimensions
	goldText:ClearAllPoints()
	local xOffsetUser = E.db.bagCustomizer.goldTextXOffset or 0
	local yOffsetUser = E.db.bagCustomizer.goldTextYOffset or 0
	local xPadding = E.db.bagCustomizer.currencyHorizontalPadding or 1
	local xOffsetInternal = -30
	if anchorPos == "BOTTOM_RIGHT_ABOVE" then
		-- BRAC positioning
		local currencyFrame = bagFrame.currencyButton
		if currencyFrame and currencyFrame:IsShown() then
			-- Two-point anchoring for precise positioning (existing code)
			goldText:SetPoint("RIGHT", bagFrame, "RIGHT",
				xOffsetInternal + xOffsetUser, 0)
			goldText:SetPoint("TOP", currencyFrame, "TOP",
				0, -4 + yOffsetUser)
		else
			-- No currency frame case - create a virtual positioning that's consistent
			local virtualPadding = currentDimensions.virtualCurrencyHeight or currentDimensions.paddingSizeBRAC or 34
			local baseOffset = BOTTOM_OFFSET * 2
			local virtualOffset = virtualPadding - 10 -- Adjust this value to position gold text appropriately
			goldText:SetPoint("BOTTOMRIGHT", bagFrame, "BOTTOMRIGHT",
				xOffsetInternal + xOffsetUser,
				baseOffset + virtualOffset + yOffsetUser)
			debug("currency", "RepositionGoldText: Virtual BRAC positioning with offset: " .. virtualOffset)
		end
	else
		-- BRBC positioning
		local yPosCalculated = dims.goldTextYPos or (BOTTOM_OFFSET + 2)
		-- For no currency case, adjust the position to respect the virtual padding
		if not bagFrame.currencyButton or not bagFrame.currencyButton:IsShown() then
			local virtualPadding = currentDimensions.virtualCurrencyHeight or 0
			if virtualPadding > 0 then
				-- Position gold text in the space created by HandleNoCurrenciesBRBC
				yPosCalculated = BOTTOM_OFFSET + (virtualPadding / 2)
				debug("currency", "RepositionGoldText: Virtual BRBC positioning with offset: " .. yPosCalculated)
			end
		end

		goldText:SetPoint("BOTTOMRIGHT", bagFrame, "BOTTOMRIGHT",
			xOffsetInternal + xOffsetUser,
			yPosCalculated + yOffsetUser)
	end
end

function currencyAndTextures:ApplyGoldTextFix(bagFrame)
	bagFrame = bagFrame or self:GetBagFrame()
	if not bagFrame then
		return
	end

	local goldText = bagFrame.goldText
	if not goldText then
		return
	end

	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return
	end

	if not E.db.bagCustomizer.enabled or not E.db.bagCustomizer.currencyModuleEnabled then
		return
	end

	if not E.db.bagCustomizer.fixGoldTextStrata then
		return
	end

	-- Create or get strata frame
	if not goldText._BCZ_strataFrame then
		goldText._BCZ_strataFrame = CreateFrame("Frame", nil, bagFrame)
		goldText:SetParent(goldText._BCZ_strataFrame)
	elseif goldText:GetParent() ~= goldText._BCZ_strataFrame then
		goldText:SetParent(goldText._BCZ_strataFrame)
	end

	goldText._BCZ_strataFrame:SetAllPoints(goldText)
	goldText._BCZ_strataFrame:SetFrameStrata("HIGH")
	goldText._BCZ_strataFrame:SetFrameLevel(7)
end

function currencyAndTextures:ResetGoldText()
	local bagFrame = self:GetBagFrame()
	if not bagFrame then
		return
	end

	local goldText = bagFrame.goldText
	if not goldText then
		return
	end

	if goldText._BCZ_strataFrame then
		goldText:SetParent(bagFrame)
		goldText._BCZ_strataFrame:Hide()
		goldText._BCZ_strataFrame = nil
	end

	if goldText._origPoints then
		goldText:ClearAllPoints()
		for i, pointData in ipairs(goldText._origPoints) do
			goldText:SetPoint(unpack(pointData))
		end

		goldText._origPoints = nil
		debug("currency", "Reset gold text position")
		local B = GetBagsModule()
		if self:IsAnyBagVisible() and B and B.Layout then
			C_Timer.After(0.05, function()
				if B and B.Layout then
					B:Layout()
				end
			end)
		end
	end
end

-- ==========================================
-- Texture Application Functions
-- ==========================================
function currencyAndTextures:ApplyCloseButtonTexture(frame)
	if self.isApplyingCloseButtonTexture then
		return
	end

	self.isApplyingCloseButtonTexture = true
	if not self:ShouldUpdateFrame(frame) or self:IsBankFrame(frame) then
		self:CleanupCloseButton(frame)
		self.isApplyingCloseButtonTexture = false
		return
	end

	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		self:CleanupCloseButton(frame)
		self.isApplyingCloseButtonTexture = false
		return
	end

	local settings = E.db.bagCustomizer.closeButtonTexture
	if not settings or not settings.enable then
		self:CleanupCloseButton(frame)
		self.isApplyingCloseButtonTexture = false
		return
	end

	-- Find close button
	local closeButton = frame.CloseButton or
			_G[(frame:GetName() or "") .. "CloseButton"] or
			_G[(frame:GetName() or "") .. "Close"]
	if not closeButton then
		for i = 1, frame:GetNumChildren() do
			local child = select(i, frame:GetChildren())
			if child and child:IsObjectType("Button") then
				local point1 = child:GetPoint(1)
				if point1 and point1:find("RIGHT") and point1:find("TOP") then
					closeButton = child
					break
				end
			end
		end
	end

	if not closeButton then
		self.isApplyingCloseButtonTexture = false
		return
	end

	-- Store original position if needed
	if not closeButton._BCZ_originalPoint then
		self:CaptureOriginalButtonPosition(closeButton, frame)
	end

	-- Apply button position and scale
	local allowYChanges = E.db.bagCustomizer.enableButtonYChanges
	local frameHeightPanel = frame._BCZ_topBorderPanel
	local frameHeightEnabled = E.db.bagCustomizer.frameHeight and E.db.bagCustomizer.frameHeight.enable
	local anchorToFrameHeight = settings.anchorToFrameHeight and frameHeightEnabled and frameHeightPanel
	local parentFrame = closeButton:GetParent()
	local anchorParent = anchorToFrameHeight and frameHeightPanel or parentFrame
	local buttonScale = settings.buttonScale or 1.0
	-- Apply button scale
	if buttonScale ~= 1.0 and closeButton._BCZ_originalWidth then
		closeButton:SetSize(closeButton._BCZ_originalWidth * buttonScale,
			closeButton._BCZ_originalHeight * buttonScale)
	elseif closeButton._BCZ_originalWidth then
		closeButton:SetSize(closeButton._BCZ_originalWidth,
			closeButton._BCZ_originalHeight)
	end

	-- Apply button positioning
	local buttonXOffset = settings.buttonXOffset or 0
	local buttonYOffset = (allowYChanges and settings.buttonYOffset) or
			(closeButton._BCZ_originalPoint and closeButton._BCZ_originalPoint.yOfs) or 0
	pcall(function()
		ClearAllPoints(closeButton)
		if anchorToFrameHeight then
			SetPoint(closeButton, "TOPRIGHT", anchorParent, "TOPRIGHT", buttonXOffset, buttonYOffset)
		else
			SetPoint(closeButton, "TOPRIGHT", parentFrame, "TOPRIGHT", buttonXOffset, buttonYOffset)
		end

		closeButton._BCZ_usingCustomAnchor = true
	end)
	-- Create overlay frame for texture
	local overlayName = "BagCustomizerCloseButtonOverlay_" .. (frame:GetName() or "unnamed")
	local overlay = _G[overlayName] or CreateFrame("Frame", overlayName, closeButton)
	overlay:SetFrameLevel(closeButton:GetFrameLevel() + 1)
	if not overlay.texture then
		overlay.texture = self:CreateOrReuseTexture(overlay, "OVERLAY", nil, "closeButtonOverlay")
	end

	-- Calculate texture size
	local textureWidth, textureHeight = GetWidth(closeButton), GetHeight(closeButton)
	local defaultTexture = "close_blizzard_modern.tga"
	local texturePath = addon:GetMediaPath("closeButton", settings.texture, defaultTexture)
	if not texturePath then
		self:CleanupCloseButton(frame)
		self.isApplyingCloseButtonTexture = false
		return
	end

	local textureAspect = 1.0 -- Default aspect ratio
	local scale = settings.scale or 1.3
	local scaledWidth = textureWidth * scale
	local scaledHeight = scaledWidth / textureAspect
	-- Position and show texture
	local textureXOffset = settings.textureXOffset or 0
	local textureYOffset = settings.textureYOffset or 0
	overlay:SetSize(scaledWidth, scaledHeight)
	ClearAllPoints(overlay)
	SetPoint(overlay, "CENTER", closeButton, "CENTER", textureXOffset, textureYOffset)
	overlay.texture:SetTexture(texturePath)
	overlay.texture:SetAllPoints()
	overlay.texture:SetTexCoord(0, 1, 0, 1)
	overlay.texture:SetAlpha(settings.alpha or 1.0)
	overlay:Show()
	-- Create glow texture
	local glowTexturePath =
	"Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\CloseButtonTextures\\close_button_glow.tga"
	if not overlay.glowTexture then
		overlay.glowTexture = self:CreateOrReuseTexture(overlay, "OVERLAY", 7, "closeButtonGlow")
	end

	overlay.glowTexture:SetTexture(glowTexturePath)
	overlay.glowTexture:SetSize(scaledWidth, scaledHeight)
	overlay.glowTexture:SetAllPoints(overlay)
	overlay.glowTexture:SetTexCoord(0, 1, 0, 1)
	overlay.glowTexture:SetBlendMode("ADD")
	overlay.glowTexture:SetAlpha(0.2)
	overlay.glowTexture:Hide()
	-- Add hover effect if not already hooked
	if not closeButton._BCZ_hover_hooked then
		closeButton:HookScript("OnEnter", function()
			if overlay.glowTexture then
				overlay.glowTexture:Show()
			end
		end)
		closeButton:HookScript("OnLeave", function()
			if overlay.glowTexture then
				overlay.glowTexture:Hide()
			end
		end)
		overlay:HookScript("OnHide", function()
			if overlay.glowTexture then
				overlay.glowTexture:Hide()
			end
		end)
		closeButton._BCZ_hover_hooked = true
	end

	self.isApplyingCloseButtonTexture = false
end

function currencyAndTextures:UpdateCurrencyHorizontalPadding()
	local frame = self:GetBagFrame()
	if not frame or not self:ShouldUpdateFrame(frame) then
		return
	end

	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return
	end

	local settings = E.db.bagCustomizer.currencyTexture -- Added this line
	local currentMode = E.db.bagCustomizer.goldAnchorPosition
	local currencyFrame = frame.currencyButton
	if not currencyFrame then
		return
	end

	local horizontalPadding = E.db.bagCustomizer.currencyHorizontalPadding or 0
	-- Update currency frame position
	if currencyFrame._BCZ_originalXOffset ~= nil then
		local p, rT, rP, _, yO = currencyFrame:GetPoint(1)
		if p then
			debug("currency", "Updating horizontal padding: " .. horizontalPadding)
			currencyFrame:SetPoint(p, rT, rP, currencyFrame._BCZ_originalXOffset + horizontalPadding, yO)
		end
	end

	-- Update texture position separately without a full texture rebuild
	if currencyFrame._BCZ_backdrop and currentMode ~= "CURRENCY_ONLY" and currentMode ~= "BOTTOM_CURRENCY_TOP_GOLD" then
		local currentPoint = { currencyFrame._BCZ_backdrop:GetPoint(1) }
		if #currentPoint >= 5 then
			-- Adjust the X offset (4th parameter) by the horizontal padding
			local anchor, relativeTo, relativePoint, _, yOffset = unpack(currentPoint)
			currencyFrame._BCZ_backdrop:ClearAllPoints()
			currencyFrame._BCZ_backdrop:SetPoint(anchor, relativeTo, relativePoint,
				(settings and settings.textureXOffset or 0), yOffset)
		end
	elseif currencyFrame._BCZ_3SliceContainer then
		-- Similar adjustment for 3-slice container if needed
	end

	-- Only update the frame, no need to rebuild everything
	if frame.currencyButton then
		self:ApplyCurrencyFrameTexture(frame)
	end
end

function currencyAndTextures:ApplyCurrencyFrameTexture(frame)
	-- Ensure we have a valid frame and it's not the bank
	if not self:ShouldUpdateFrame(frame) or self:IsBankFrame(frame) then
		self:RevertCurrencyFrameTexture(frame)
		return
	end

	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		self:RevertCurrencyFrameTexture(frame)
		return
	end

	local settings = E.db.bagCustomizer.currencyTexture
	-- Check if the feature is enabled in settings
	if not settings or not settings.enable then
		self:RevertCurrencyFrameTexture(frame)
		return
	end

	local currencyButton = frame.currencyButton
	-- Check if the target currency frame exists
	if not currencyButton then
		debug("miscTextures",
			"ApplyCurrencyFrameTexture: currencyButton not found on frame: " .. (frame:GetName() or "unnamed"))
		self:RevertCurrencyFrameTexture(frame)
		return
	end

	-- Get current mode for mode-specific behaviors
	local currentMode = E.db.bagCustomizer.goldAnchorPosition
	-- Check for disabling modes
	if currentMode == "GOLD_ONLY" or currentMode == "DEFAULT" then
		self:RevertCurrencyFrameTexture(frame)
		return
	end

	-- === Important: Read the potentially updated row count ===
	-- This value should have been set by the B.Layout hook if it ran recently.
	local currentNumRows = currentDimensions.numCurrencyRows or 0
	-- Add direct row counting mechanism as a fallback
	if currentNumRows == 0 then
		-- IMPORTANT: Check for actual tokens first
		local B = GetBagsModule()
		if B and B.numTrackedTokens and B.numTrackedTokens > 0 then
			-- Only count rows if there are actual tokens
			local actualHeight = currencyButton:GetHeight()
			if actualHeight > 0 then
				currentNumRows = math.floor(actualHeight / 24 + 0.5)
				debug("miscTextures", "Direct row counting: Found " .. currentNumRows .. " rows (from " ..
					B.numTrackedTokens .. " tokens)")
				currentDimensions.numCurrencyRows = currentNumRows
			end
		else
			debug("miscTextures", "Zero tokens detected, forcing currentNumRows = 0")
			currentNumRows = 0
			currentDimensions.numCurrencyRows = 0
		end
	end

	-- Identify special modes for custom handling
	local isSpecialMode = (currentMode == "CURRENCY_ONLY" or currentMode == "BOTTOM_CURRENCY_TOP_GOLD")
	-- UNIVERSAL CHECK: Don't show texture for zero currencies in ANY mode
	if currentNumRows == 0 then
		debug("miscTextures", "ApplyCurrencyFrameTexture: 0 currency rows detected, reverting texture.")
		self:RevertCurrencyFrameTexture(frame)
		return
	end

	-- === End Row Count Check ===
	local use3Slice = settings.use3Slice
	local width, height
	local baseHeight = self:GetEffectiveTextureHeight() -- Base height including global offset
	height = baseHeight                                -- Start with base height
	local heightSetByAutoFit = false
	-- 1. CALCULATE HEIGHT
	if settings.autoFitHeight then
		local currentFrameHeight = floor(currencyButton:GetHeight() + 0.5)
		-- Use the accurate row count from currentDimensions
		local numRows = currentNumRows
		local rowHeightOffset = settings.rowHeightOffset or 0
		local contentHeightBasis = 0
		local globalHeightOffset = E.db.bagCustomizer.textureHeightOffset or -4
		if isSpecialMode then
			-- Special handling for CO and BCTG modes
			if currentFrameHeight > 0 then
				-- Don't subtract padding for special modes since we're not adding vertical padding
				contentHeightBasis = currentFrameHeight
				debug("miscTextures",
					"Special Mode AutoFitHeight: CurrentH=" .. currentFrameHeight ..
					", Rows=" .. numRows)
				-- Ensure minimum height
				contentHeightBasis = max(currentDimensions.rowHeight or 24, contentHeightBasis)
				-- Calculate height based on content
				local specialHeightAdjust = -6
				height = contentHeightBasis + rowHeightOffset + globalHeightOffset + specialHeightAdjust
				-- Adjust for multiple rows
				local extraRows = numRows - 1
				if extraRows > 0 then
					local scaleFactor = 1.0
					-- A bit of legacy code, kept just in case
					if extraRows > 1 then
						scaleFactor = 1
					end

					-- Define how much extra height per additional row
					local extraRowPadding = 2
					height = height + (extraRows * extraRowPadding * 3 * scaleFactor)
				end

				-- Add mode-specific small adjustment
				height = height + 6 -- Small boost for visibility in special modes
			else
				-- Fallback if no valid height/rows
				height = baseHeight + rowHeightOffset + 4
			end
		else
			-- Original behavior for BRAC/BRBC modes
			local paddingApplied = (currentMode == "BOTTOM_RIGHT_BELOW") and
					(currentDimensions.paddingSizeBRBC or 24) or
					(currentDimensions.paddingSizeBRAC or 34)
			if currentFrameHeight > 0 then
				-- Use current frame height minus the padding *applied by our addon*
				contentHeightBasis = currentFrameHeight - paddingApplied
				debug("miscTextures",
					"AutoFitHeight: CurrentH=" .. currentFrameHeight ..
					", Pad=" .. paddingApplied ..
					", Basis=" .. contentHeightBasis ..
					", Rows=" .. numRows)
				-- Ensure minimum height and calculate final height
				contentHeightBasis = max(currentDimensions.rowHeight or 24, contentHeightBasis)
				-- Start with content basis, add row offset, add global offset
				height = contentHeightBasis + rowHeightOffset + globalHeightOffset
				-- Adjust for multiple rows
				local extraRows = numRows - 1
				if extraRows > 0 then
					local scaleFactor = 1.0
					-- Define how much extra height per additional row
					local extraRowPadding = 4
					height = height + (extraRows * extraRowPadding * scaleFactor)
				end
			else
				-- Fallback if no valid height/rows, but use base + row offsets
				height = baseHeight + rowHeightOffset -- baseHeight already includes global offset
			end
		end

		debug("miscTextures", "Final autofit height calculated: " .. height)
	else
		-- Non-autofit handling - apply mode-specific adjustments for special modes
		if isSpecialMode then
			-- Special height calculation for CO and BCTG modes
			debug("miscTextures", "Using special height calculation for " .. currentMode)
			-- Base height calculation
			local rowHeightOffset = settings.rowHeightOffset or 0
			-- Start with a sensible default height
			height = baseHeight + rowHeightOffset
			-- Apply mode-specific adjustments
			if currentMode == "CURRENCY_ONLY" then
				-- For CO mode, add extra height to make it more visible
				height = height + 2
			elseif currentMode == "BOTTOM_CURRENCY_TOP_GOLD" then
				-- For BCTG mode, slight adjustment to fit better
				height = height + 2
			end

			heightSetByAutoFit = true -- Mark as handled
			debug("miscTextures", "Special mode height calculated: " .. height)
		else
			-- Fallbacks if autoFit isn't enabled for regular modes
			if settings.height and settings.height > 0 then
				height = settings.height -- User override takes precedence
			else
				-- Apply rowHeightOffset to the base height (which includes global offset)
				height = baseHeight + (settings.rowHeightOffset or 0)
			end
		end
	end

	-- 2. CALCULATE WIDTH
	local shouldMatchHolderFrameWidth = settings.matchHolderFrameWidth and currentMode ~= "DEFAULT"
	local holderFrame = frame.holderFrame
	-- Start with currency button's width as default
	width = GetWidth(currencyButton)
	if shouldMatchHolderFrameWidth and holderFrame then
		width = holderFrame:GetWidth() -- Match holder frame width if specified
	elseif settings.width and settings.width > 0 then
		width = settings.width       -- Use user-defined width if specified and not matching holder
	end

	-- Apply width adjustment modifier
	if settings.widthAdjustment and settings.widthAdjustment ~= 0 then
		width = width + settings.widthAdjustment
	end

	-- 3. APPLY SCALE
	if settings.scale and settings.scale ~= 1 then
		width = width * settings.scale
		height = height * settings.scale
	end

	-- Ensure minimum dimensions - very important!
	width = max(50, width)  -- Minimum width: 50
	height = max(20, height) -- Minimum height: 20
	-- 4. POSITIONING SETUP
	local xOffset = settings.textureXOffset or 0
	xOffset = xOffset + (E.db.bagCustomizer.currencyHorizontalPadding or 0)
	local yOffset = settings.textureYOffset or 0
	-- Apply special Y offsets for CO and BCTG modes
	if currentMode == "CURRENCY_ONLY" or currentMode == "BOTTOM_CURRENCY_TOP_GOLD" then
		-- REPLACE THIS SECTION with row-based positioning
		-- Calculate offset based on number of rows for CO/BCTG
		local numRows = currentDimensions.numCurrencyRows or 1
		if numRows > 1 then
			-- For multiple rows, calculate an offset that centers vertically
			local rowHeight = 24 -- Base height of a currency row
			local extraRows = numRows - 1
			-- Scale factor to control how much adjustment per row
			local scaleFactor = 0.1 -- Adjust this value to fine-tune
			-- Calculate progressive offset (more rows = more upward offset)
			local rowBasedOffset = (extraRows * rowHeight * scaleFactor)
			yOffset = yOffset - rowBasedOffset
			debug("miscTextures",
				"Applied row-based center offset for CO/BCTG: " .. (-rowBasedOffset) .. " (rows: " .. numRows .. ")")
		else
			-- Single row case - keep original slight adjustment
			yOffset = yOffset -- - 2
		end
	end

	local frameAnchor = "CENTER" -- Default anchor
	-- Adjust anchor and Y offset based on the current currency/gold mode
	if currentMode == "BOTTOM_RIGHT_BELOW" then
		frameAnchor = "CENTER"
		local paddingSize = currentDimensions.paddingSizeBRBC or 24
		yOffset = yOffset + (paddingSize / 2)
	elseif currentMode == "BOTTOM_RIGHT_ABOVE" then
		frameAnchor = "CENTER"
		local paddingSize = currentDimensions.paddingSizeBRAC or 24
		yOffset = yOffset - (paddingSize / 2)
	else -- DEFAULT mode or other cases
		-- Allow user-defined anchor for DEFAULT mode
		local validAnchors = {
			TOP = 1, BOTTOM = 1, CENTER = 1, TOPLEFT = 1, TOPRIGHT = 1, BOTTOMLEFT = 1, BOTTOMRIGHT = 1,
		}
		frameAnchor = validAnchors[settings.textureAnchor] and settings.textureAnchor or "CENTER"
	end

	local precisePosData = {
		anchor = frameAnchor,
		xOffset = xOffset,
		yOffset = yOffset,
	}
	-- 5. APPLY TEXTURE (3-Slice or Standard)
	local defaultTexture = "currency_blizzard_modern.tga" -- Define a default texture
	local texturePath = addon:GetMediaPath("currency", settings.texture, defaultTexture)
	if not texturePath then
		self:RevertCurrencyFrameTexture(frame)
		return
	end

	if use3Slice then
		-- Cleanup standard backdrop if switching to 3-slice
		if currencyButton._BCZ_backdrop then
			if currencyButton._BCZ_backdrop:GetObjectType() == "Texture" then
				addon:ReleaseTexture(currencyButton._BCZ_backdrop)
			end

			currencyButton._BCZ_backdrop = nil
			self:ReleaseTrackedTextures(frame, "currencyBackdrop")
		end

		local settingsCopy = CopyTable(settings)    -- Pass relevant settings
		settingsCopy.precisePosition = precisePosData -- Pass calculated position data
		-- Apply the 3-slice texture using the helper function
		self:Apply3SliceTexture(currencyButton, settingsCopy, texturePath, width, height, "currency")
	else
		-- Cleanup 3-slice container if switching to standard
		if currencyButton._BCZ_3SliceContainer then
			if currencyButton._BCZ_3SliceContainer.Cleanup then
				currencyButton._BCZ_3SliceContainer:Cleanup()
			end

			currencyButton._BCZ_3SliceContainer:Hide()
			currencyButton._BCZ_3SliceContainer = nil
		end

		-- Create a new texture using resource pooling
		if currencyButton._BCZ_backdrop then
			addon:ReleaseTexture(currencyButton._BCZ_backdrop)
			currencyButton._BCZ_backdrop = nil
		end

		currencyButton._BCZ_backdrop = self:CreateOrReuseTexture(currencyButton, "ARTWORK", 0, "currencyBackdrop")
		-- Apply texture path with error handling
		local textureApplied = false
		if not pcall(function()
					currencyButton._BCZ_backdrop:SetTexture(texturePath)
					textureApplied = true
				end) then
			debug("miscTextures", "Error setting standard currency texture path: " .. texturePath .. ". Using default.")
			pcall(function()
				currencyButton._BCZ_backdrop:SetTexture(addon:GetMediaPath("currency", defaultTexture))
				textureApplied = true
			end)
		end

		if not textureApplied then
			debug("miscTextures", "Failed to set any texture on currency backdrop")
		end

		-- Apply size, position, and alpha with safe values
		currencyButton._BCZ_backdrop:SetSize(width, height)
		currencyButton._BCZ_backdrop:ClearAllPoints()
		currencyButton._BCZ_backdrop:SetPoint(frameAnchor, currencyButton, frameAnchor, xOffset, yOffset)
		currencyButton._BCZ_backdrop:SetTexCoord(0, 1, 0, 1)
		currencyButton._BCZ_backdrop:SetAlpha(settings.alpha or 0.7)
		currencyButton._BCZ_backdrop:Show()
		debug("miscTextures", "Standard backdrop applied - Size: " .. width .. "x" .. height ..
			", Anchor: " .. frameAnchor .. ", Alpha: " .. (settings.alpha or 0.7))
	end
end

function currencyAndTextures:CalculateGoldTextWidth(goldText)
	if not goldText then return 0 end

	-- Get the raw text from the gold text element
	local goldString = goldText:GetText() or ""
	-- Remove color codes (format: |cAARRGGBB...text...|r)
	local cleanString = goldString:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	-- Remove texture references/icons (format: |T...path...:0|t)
	cleanString = cleanString:gsub("|T.-|t", "")
	-- Calculate length based on character count
	local textLength = string.len(cleanString)
	-- Debug output for visibility
	debug("currency", "Gold text parsed: Raw='" .. goldString ..
		"', Clean='" .. cleanString .. "', Length=" .. textLength)
	-- Calculate width: base of ~7 pixels per character plus padding
	local charWidth = 9                                              -- Average width per character in pixels
	local padding = 63                                               -- Padding to ensure texture extends beyond text
	local calculatedWidth = max(textLength * charWidth + padding, 60) -- Minimum width of 60
	debug("currency", "Calculated gold width: " .. calculatedWidth ..
		" (from " .. textLength .. " chars at " .. charWidth .. "px each + " .. padding .. "px padding)")
	return calculatedWidth
end

function currencyAndTextures:ApplyGoldTextTexture(frame)
	if not self:ShouldUpdateFrame(frame) or self:IsBankFrame(frame) then
		self:RevertGoldTextTexture(frame)
		return
	end

	-- Defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		self:RevertGoldTextTexture(frame)
		return
	end

	local settings = E.db.bagCustomizer.goldTextTexture
	if not settings or not settings.enable then
		self:RevertGoldTextTexture(frame)
		return
	end

	local currentMode = E.db.bagCustomizer.goldAnchorPosition
	if not E.db.bagCustomizer.currencyModuleEnabled or currentMode == "DEFAULT" then
		self:RevertGoldTextTexture(frame)
		return
	end

	local goldText = frame.goldText
	if not goldText then
		return
	end

	-- Initialize width and height at the function level
	local width, height = 20, 1
	local use3Slice = settings.use3Slice
	if not goldText._strataFrame then
		goldText._strataFrame = CreateFrame("Frame", nil, frame)
		goldText._strataFrame:SetFrameStrata("HIGH")
		goldText._strataFrame:SetFrameLevel(2)
	end

	local strataFrame = goldText._strataFrame
	local holderFrame = frame.holderFrame
	local shouldMatchHolder = settings.matchHolderFrameWidth and holderFrame
	-- Check if auto width is enabled and match holder is not active
	if settings.autoWidth and not shouldMatchHolder then
		-- Calculate width dynamically based on the gold text string
		width = currencyAndTextures:CalculateGoldTextWidth(goldText)
		-- Apply widthModifier to autoWidth
		if settings.widthModifier and settings.widthModifier ~= 0 then
			width = width + settings.widthModifier
			debug("miscTextures", "Applied widthModifier " .. settings.widthModifier ..
				" to auto width: " .. (width - settings.widthModifier) .. " → " .. width)
		end
	else
		-- Default width handling based on mode
		if shouldMatchHolder then
			width = holderFrame:GetWidth() + (settings.widthModifier or 0)
		else
			width = settings.width or goldText:GetWidth()
		end

		-- Apply widthModifier for non-auto width when not using shouldMatchHolder
		-- (since it's already applied above for shouldMatchHolder)
		if not shouldMatchHolder and settings.widthModifier and settings.widthModifier ~= 0 then
			width = width + settings.widthModifier
			debug("miscTextures", "Applied widthModifier to fixed width: " .. width)
		end
	end

	-- Mode-specific handling
	if currentMode == "GOLD_ONLY" or currentMode == "BOTTOM_CURRENCY_TOP_GOLD" then
		local GO_HEIGHT_ADJUSTMENT = 0
		local GO_X_OFFSET = 16
		local GO_Y_OFFSET = 0
		if not settings.autoHeight and settings.height and settings.height > 0 then
			height = settings.height
		else
			local baseHeight = self:GetEffectiveTextureHeight()
			local heightAdjust = settings.heightAdjustment + GO_HEIGHT_ADJUSTMENT
			height = baseHeight + heightAdjust
		end

		if settings.scale and settings.scale ~= 1 then
			width = width * settings.scale
			height = height * settings.scale
		end

		height = max(1, height)
		width = max(50, width)
		strataFrame:SetSize(width, height)
		local userXOffset = E.db.bagCustomizer.goldTextXOffset or 0
		local userYOffset = E.db.bagCustomizer.goldTextYOffset or 0
		strataFrame:ClearAllPoints()
		strataFrame:SetPoint("RIGHT", goldText, "RIGHT", GO_X_OFFSET, GO_Y_OFFSET + userYOffset)
		debug("miscTextures", "Dynamic gold texture - Width: " .. width ..
			", Using RIGHT anchor with offset: " .. GO_X_OFFSET)
		strataFrame:Show()
	else
		if shouldMatchHolder then
			width = holderFrame:GetWidth() + (settings.widthModifier or 0)
		end

		width = max(20, width)
		local baseHeight = currentDimensions.goldTextureHeight or self:GetEffectiveTextureHeight()
		height = baseHeight + (settings.heightAdjustment or 0)
		if settings.scale and settings.scale ~= 1 then
			width = width * settings.scale
			height = height * settings.scale
		end

		height = max(1, height)
		strataFrame:SetSize(width, height)
		strataFrame:ClearAllPoints()
		local xOffset, yOffset
		local shouldAnchorToHolder = settings.anchorToHolderFrame
		if currentMode == "BOTTOM_RIGHT_ABOVE" and shouldAnchorToHolder then
			local currencyFrame = frame.currencyButton
			if currencyFrame then
				xOffset = settings.holderFrameXOffset or 0
				yOffset = settings.holderFrameYOffset or 0
				local userPadding = E.db.bagCustomizer.currencyTopPadding or 34
				local xPadding = E.db.bagCustomizer.currencyHorizontalPadding or 1
				xOffset = xOffset - xPadding / 2
				local anchorOffsetY = -10
				strataFrame:SetPoint("CENTER", currencyFrame, "TOP",
					xOffset, anchorOffsetY + yOffset)
			else
				xOffset = settings.xOffset or 0
				yOffset = settings.yOffset or 0
				strataFrame:SetPoint("CENTER", goldText, "CENTER", xOffset, yOffset)
			end
		elseif shouldAnchorToHolder and holderFrame then
			xOffset = settings.holderFrameXOffset or 0
			yOffset = settings.holderFrameYOffset or 0
			local adjustedY = 8
			strataFrame:SetPoint("CENTER", holderFrame, "BOTTOM", xOffset, yOffset + adjustedY)
		else
			xOffset = settings.xOffset or 0
			yOffset = settings.yOffset or 0
			local adjustedY = 1
			strataFrame:SetPoint("CENTER", goldText, "CENTER", xOffset, yOffset + adjustedY)
		end
	end

	strataFrame:Show()
	if use3Slice then
		if goldText._BCZ_backdrop then
			if goldText._BCZ_backdrop:GetObjectType() == "Texture" then
				addon:ReleaseTexture(goldText._BCZ_backdrop)
			end

			goldText._BCZ_backdrop = nil
			self:ReleaseTrackedTextures(frame, "goldTextBackdrop")
		end

		local settingsCopy = CopyTable(settings)
		settingsCopy.precisePosition = {
			anchor = "CENTER",
			xOffset = 0,
			yOffset = 0,
		}
		local defaultTexture = "currency_blizzard_modern.tga"
		local texturePath = addon:GetMediaPath("goldtext", settings.texture, defaultTexture)
		if not texturePath then
			self:RevertGoldTextTexture(frame)
			return
		end

		debug("miscTextures",
			"Calling Apply3SliceTexture with width: " .. tostring(width) .. ", height: " .. tostring(height))
		if type(width) ~= "number" or type(height) ~= "number" then
			debug("miscTextures", "ERROR: Invalid dimensions - width: " .. tostring(width) .. ", height: " .. tostring(height))
			width = width or 100
			height = height or 30
		end

		self:Apply3SliceTexture(strataFrame, settingsCopy, texturePath, width, height, "goldText")
	else
		if strataFrame._BCZ_3SliceContainer then
			if strataFrame._BCZ_3SliceContainer.Cleanup then
				strataFrame._BCZ_3SliceContainer:Cleanup()
			end

			strataFrame._BCZ_3SliceContainer:Hide()
			strataFrame._BCZ_3SliceContainer = nil
		end

		if goldText._BCZ_backdrop then
			addon:ReleaseTexture(goldText._BCZ_backdrop)
			goldText._BCZ_backdrop = nil
		end

		goldText._BCZ_backdrop = self:CreateOrReuseTexture(strataFrame, "ARTWORK", nil, "goldTextBackdrop")
		local defaultTexture = "currency_blizzard_modern.tga"
		local texturePath = addon:GetMediaPath("goldtext", settings.texture, defaultTexture)
		if not texturePath then
			self:RevertGoldTextTexture(frame)
			return
		end

		local textureApplied = false
		if not pcall(function()
					goldText._BCZ_backdrop:SetTexture(texturePath)
					textureApplied = true
				end) then
			debug("miscTextures", "Error setting gold texture path: " .. texturePath)
			pcall(function()
				goldText._BCZ_backdrop:SetTexture(addon:GetMediaPath("goldtext", defaultTexture))
				textureApplied = true
			end)
		end

		if not textureApplied then
			debug("miscTextures", "Failed to set any texture on gold text backdrop")
			return
		end

		goldText._BCZ_backdrop:SetAllPoints(strataFrame)
		goldText._BCZ_backdrop:SetTexCoord(0, 1, 0, 1)
		goldText._BCZ_backdrop:SetAlpha(settings.alpha or 0.7)
		goldText._BCZ_backdrop:Show()
		debug("miscTextures", "Gold text standard backdrop applied - Size: " .. width .. "x" .. height ..
			", Alpha: " .. (settings.alpha or 0.7))
	end
end

function currencyAndTextures:Apply3SliceTexture(parentFrame, settings, texturePath, width, height, frameType)
	-- Debug output to track execution
	debug("miscTextures", "Enter Apply3SliceTexture: frameType=" .. (frameType or "nil") ..
		", width=" .. (width or "nil") .. ", height=" .. (height or "nil"))
	-- Guard against nil parameters
	if not parentFrame then
		debug("miscTextures", "ERROR: parentFrame is nil in Apply3SliceTexture")
		return nil
	end

	if not settings then
		debug("miscTextures", "ERROR: settings is nil in Apply3SliceTexture")
		return nil
	end

	if not texturePath then
		debug("miscTextures", "ERROR: texturePath is nil in Apply3SliceTexture")
		return nil
	end

	-- Safe texture release function
	local function safeReleaseTexture(texture)
		if texture and type(texture) == "table" and texture.GetObjectType and texture:GetObjectType() == "Texture" then
			pcall(function() texture:Hide() end)
			pcall(function() addon:ReleaseTexture(texture) end)
			return true
		end

		return false
	end

	-- Clean up existing backdrop if any - with enhanced error checking
	if parentFrame._BCZ_backdrop then
		local key = (frameType == "currency" and "currencyBackdrop") or
				(frameType == "goldText" and "goldTextBackdrop")
		if key then
			-- Use pcall to safely check object type
			local isTexture = pcall(function()
				return parentFrame._BCZ_backdrop:GetObjectType() == "Texture"
			end)
			if isTexture then
				safeReleaseTexture(parentFrame._BCZ_backdrop)
			end

			parentFrame._BCZ_backdrop = nil
			-- Safely get the owner
			local owner = nil
			if frameType == "currency" then
				owner = parentFrame
			elseif frameType == "goldText" and parentFrame.GetParent then
				owner = parentFrame:GetParent()
			end

			if owner then
				pcall(function() self:ReleaseTrackedTextures(owner, key) end)
			end
		end
	end

	-- Create container frame if needed
	if not parentFrame._BCZ_3SliceContainer then
		parentFrame._BCZ_3SliceContainer = CreateFrame("Frame", nil, parentFrame)
		if parentFrame._BCZ_3SliceContainer then
			local level = parentFrame:GetFrameLevel() + (frameType == "goldText" and 5 or 1)
			parentFrame._BCZ_3SliceContainer:SetFrameLevel(level)
		else
			debug("miscTextures", "ERROR: Failed to create container frame")
			return nil
		end
	end

	local container = parentFrame._BCZ_3SliceContainer
	if not container then
		debug("miscTextures", "ERROR: Container is nil")
		return nil
	end

	-- Add safety check for dimensions
	if not width or width <= 0 or not height or height <= 0 then
		debug("miscTextures", "ERROR: Invalid dimensions in Apply3SliceTexture: width=" ..
			tostring(width) .. ", height=" .. tostring(height))
		width = width or 100
		height = height or 30
	end

	-- Use precalculated height if available and different
	if frameType == "currency" and settings.autoFitHeight then
		if currentDimensions then
			local calculatedHeight = currentDimensions.calculatedHeight
			if calculatedHeight and calculatedHeight > 0 and calculatedHeight ~= height then
				debug("miscTextures", "Using precalculated height: " .. calculatedHeight .. " instead of " .. height)
				height = calculatedHeight
			end
		end
	end

	-- Position the container - with error handling
	pcall(function() container:SetSize(width, height) end)
	pcall(function() container:ClearAllPoints() end)
	if settings.precisePosition then
		local pp = settings.precisePosition
		if pp and pp.anchor then
			pcall(function()
				container:SetPoint(pp.anchor, parentFrame, pp.anchor,
					(pp.xOffset or 0), (pp.yOffset or 0))
			end)
		else
			pcall(function() container:SetPoint("CENTER", parentFrame, "CENTER") end)
		end
	else
		pcall(function() container:SetPoint("CENTER", parentFrame, "CENTER") end)
	end

	pcall(function() container:Show() end)
	-- Calculate texture coordinates
	local leftBreakPct = (settings.leftBreakPct or 5)
	local rightBreakPct = (settings.rightBreakPct or 95)
	if rightBreakPct - leftBreakPct < 5 then
		rightBreakPct = leftBreakPct + 5
	end

	local leftCoord = leftBreakPct / 100
	local rightCoord = rightBreakPct / 100
	local alpha = settings.alpha or 0.7
	-- Check if we're using vertical tiling for the middle section (only for currency)
	local useVerticalTiling = frameType == "currency" and
			settings.useVerticalTiling and
			height > 30
	debug("miscTextures", "Using vertical tiling: " .. tostring(useVerticalTiling) ..
		", Texture: " .. texturePath)
	-- Clean up any existing textures - with extensive safety checks
	if container.textures then
		-- Create a copy of textures to avoid modification during iteration
		local texturesToClean = {}
		pcall(function()
			for k, v in pairs(container.textures) do
				texturesToClean[k] = v
			end
		end)
		-- Clean up each texture safely
		for key, texture in pairs(texturesToClean) do
			if texture then
				if type(texture) == "table" and key == "middleTiles" then
					-- Handle the middle tiles array
					local tilesToClean = {}
					pcall(function()
						for i = 1, #texture do
							if texture[i] then
								table.insert(tilesToClean, texture[i])
							end
						end
					end)
					for _, tileTexture in ipairs(tilesToClean) do
						safeReleaseTexture(tileTexture)
					end
				else
					-- Handle regular textures
					safeReleaseTexture(texture)
				end
			end
		end
	end

	-- Create a new textures table
	container.textures = {}
	-- Calculate sizes
	local edgeWidth = settings.edgeSize or 14
	local edgeHeight = settings.edgeHeight or 10 -- Height of top/bottom edges
	local middleWidth = math.max(1, width - (edgeWidth * 2))
	local middleHeight = math.max(1, height - (edgeHeight * 2))
	-- Helper function to safely create and set up a texture
	local function createSafeTexture(name)
		local texture = nil
		local success = pcall(function()
			texture = self:CreateOrReuseTexture(container, "ARTWORK")
		end)
		if success and texture then
			container.textures[name] = texture
			return texture
		else
			debug("miscTextures", "Failed to create texture: " .. name)
			return nil
		end
	end

	-- Apply texture function with safety checks
	local function applySafeTexture(texture, coords)
		if not texture then return false end

		return pcall(function()
			texture:SetTexture(texturePath)
			if coords then
				texture:SetTexCoord(coords.left or 0, coords.right or 1,
					coords.top or 0, coords.bottom or 1)
			end

			texture:SetAlpha(alpha)
			texture:Show()
		end)
	end

	-- Safe function to position a texture
	local function positionTexture(texture, points)
		if not texture then return false end

		return pcall(function()
			texture:ClearAllPoints()
			for _, point in ipairs(points) do
				if point.relativeTo then
					texture:SetPoint(point.point, point.relativeTo,
						point.relativePoint, point.x or 0, point.y or 0)
				else
					texture:SetPoint(point.point, point.x or 0, point.y or 0)
				end
			end

			if points.size then
				texture:SetSize(points.size.width, points.size.height)
			elseif points.width then
				texture:SetWidth(points.width)
			end
		end)
	end

	if useVerticalTiling then
		debug("miscTextures", "Setting up border+tiled textures...")
		-- Create all textures first to avoid nil references
		local textureElements = {
			"topLeft", "topRight", "bottomLeft", "bottomRight",
			"topEdge", "bottomEdge", "leftEdge", "rightEdge",
		}
		for _, name in ipairs(textureElements) do
			createSafeTexture(name)
		end

		-- Position corner textures
		if container.textures.topLeft then
			positionTexture(container.textures.topLeft, {
				{ point = "TOPLEFT", relativeTo = container, relativePoint = "TOPLEFT" },
				size = { width = edgeWidth, height = edgeHeight },
			})
		end

		if container.textures.topRight then
			positionTexture(container.textures.topRight, {
				{ point = "TOPRIGHT", relativeTo = container, relativePoint = "TOPRIGHT" },
				size = { width = edgeWidth, height = edgeHeight },
			})
		end

		if container.textures.bottomLeft then
			positionTexture(container.textures.bottomLeft, {
				{ point = "BOTTOMLEFT", relativeTo = container, relativePoint = "BOTTOMLEFT" },
				size = { width = edgeWidth, height = edgeHeight },
			})
		end

		if container.textures.bottomRight then
			positionTexture(container.textures.bottomRight, {
				{ point = "BOTTOMRIGHT", relativeTo = container, relativePoint = "BOTTOMRIGHT" },
				size = { width = edgeWidth, height = edgeHeight },
			})
		end

		-- Position edge textures - with safety checks
		if container.textures.topEdge and container.textures.topLeft and container.textures.topRight then
			positionTexture(container.textures.topEdge, {
				{ point = "TOPLEFT", relativeTo = container.textures.topLeft, relativePoint = "TOPRIGHT" },
				{ point = "BOTTOMRIGHT", relativeTo = container.textures.topRight, relativePoint = "BOTTOMLEFT" },
			})
		end

		if container.textures.bottomEdge and container.textures.bottomLeft and container.textures.bottomRight then
			positionTexture(container.textures.bottomEdge, {
				{ point = "TOPLEFT", relativeTo = container.textures.bottomLeft, relativePoint = "TOPRIGHT" },
				{ point = "BOTTOMRIGHT", relativeTo = container.textures.bottomRight, relativePoint = "BOTTOMLEFT" },
			})
		end

		if container.textures.leftEdge and container.textures.topLeft and container.textures.bottomLeft then
			positionTexture(container.textures.leftEdge, {
				{ point = "TOPLEFT", relativeTo = container.textures.topLeft, relativePoint = "BOTTOMLEFT" },
				{ point = "BOTTOMRIGHT", relativeTo = container.textures.bottomLeft, relativePoint = "TOPRIGHT" },
			})
		end

		if container.textures.rightEdge and container.textures.topRight and container.textures.bottomRight then
			positionTexture(container.textures.rightEdge, {
				{ point = "TOPLEFT", relativeTo = container.textures.topRight, relativePoint = "BOTTOMLEFT" },
				{ point = "BOTTOMRIGHT", relativeTo = container.textures.bottomRight, relativePoint = "TOPRIGHT" },
			})
		end

		-- Create middle tiles with extra safety
		local tileHeight = settings.tileHeight or 24 -- Default tile height
		local numTiles = math.ceil(middleHeight / tileHeight)
		debug("miscTextures", "Creating " .. numTiles .. " tiles for middle section")
		container.textures.middleTiles = {}
		for i = 1, numTiles do
			local tileName = "middleTile" .. i
			local tile = createSafeTexture(tileName)
			if tile then
				table.insert(container.textures.middleTiles, tile)
				-- Calculate position and size for this tile
				local tileTop = (i - 1) * tileHeight
				local tileBottom = math.min(i * tileHeight, middleHeight)
				local actualTileHeight = tileBottom - tileTop
				-- Only proceed if we have the needed reference textures
				if container.textures.leftEdge then
					-- Set position and size safely
					pcall(function()
						tile:ClearAllPoints()
						tile:SetPoint("TOPLEFT", container.textures.leftEdge, "TOPRIGHT", 0, -tileTop)
						tile:SetSize(middleWidth, actualTileHeight)
					end)
					-- Apply texture - only the middle portion
					pcall(function()
						tile:SetTexture(texturePath)
						tile:SetTexCoord(leftCoord, rightCoord, 0.4, 0.6) -- Use only the middle section of texture
						tile:SetAlpha(alpha)
						tile:Show()
					end)
				end
			end
		end

		-- Apply textures to all the border pieces
		local borderTextures = {
			{ texture = "topLeft", coords = { left = 0, right = leftCoord, top = 0, bottom = 0.3 } },
			{ texture = "topRight", coords = { left = rightCoord, right = 1, top = 0, bottom = 0.3 } },
			{ texture = "bottomLeft", coords = { left = 0, right = leftCoord, top = 0.7, bottom = 1 } },
			{ texture = "bottomRight", coords = { left = rightCoord, right = 1, top = 0.7, bottom = 1 } },
			{ texture = "topEdge", coords = { left = leftCoord, right = rightCoord, top = 0, bottom = 0.3 } },
			{ texture = "bottomEdge", coords = { left = leftCoord, right = rightCoord, top = 0.7, bottom = 1 } },
			{ texture = "leftEdge", coords = { left = 0, right = leftCoord, top = 0.3, bottom = 0.7 } },
			{ texture = "rightEdge", coords = { left = rightCoord, right = 1, top = 0.3, bottom = 0.7 } },
		}
		for _, texInfo in ipairs(borderTextures) do
			if container.textures[texInfo.texture] then
				applySafeTexture(container.textures[texInfo.texture], texInfo.coords)
			end
		end
	else
		debug("miscTextures", "Setting up standard 3-slice textures...")
		-- Create and position the left, middle and right sections - with safety checks
		local textureElements = { "left", "middle", "right" }
		for _, name in ipairs(textureElements) do
			createSafeTexture(name)
		end

		-- Position textures safely
		if container.textures.left then
			positionTexture(container.textures.left, {
				{ point = "TOPLEFT", relativeTo = container, relativePoint = "TOPLEFT" },
				{ point = "BOTTOMLEFT", relativeTo = container, relativePoint = "BOTTOMLEFT" },
				width = edgeWidth,
			})
		end

		if container.textures.middle and container.textures.left then
			positionTexture(container.textures.middle, {
				{ point = "TOPLEFT", relativeTo = container.textures.left, relativePoint = "TOPRIGHT" },
				{ point = "BOTTOMRIGHT", relativeTo = container, relativePoint = "BOTTOMRIGHT", x = -edgeWidth },
			})
		end

		if container.textures.right then
			positionTexture(container.textures.right, {
				{ point = "TOPRIGHT", relativeTo = container, relativePoint = "TOPRIGHT" },
				{ point = "BOTTOMRIGHT", relativeTo = container, relativePoint = "BOTTOMRIGHT" },
				width = edgeWidth,
			})
		end

		-- Apply textures with safety
		if container.textures.left then
			applySafeTexture(container.textures.left, { left = 0, right = leftCoord, top = 0, bottom = 1 })
		end

		if container.textures.middle then
			applySafeTexture(container.textures.middle, { left = leftCoord, right = rightCoord, top = 0, bottom = 1 })
		end

		if container.textures.right then
			applySafeTexture(container.textures.right, { left = rightCoord, right = 1, top = 0, bottom = 1 })
		end
	end

	-- Add cleanup function with extensive safety checks
	container.Cleanup = function(self)
		debug("miscTextures", "Executing Cleanup function")
		-- Safely hide the container
		pcall(function() self:Hide() end)
		if self.textures then
			-- Make a copy of the keys to avoid modification during iteration
			local keys = {}
			pcall(function()
				for k in pairs(self.textures) do
					table.insert(keys, k)
				end
			end)
			for _, key in ipairs(keys) do
				local texture = self.textures[key]
				if texture then
					if key == "middleTiles" and type(texture) == "table" then
						-- Handle the middleTiles array specially
						local tileCount = #texture
						debug("miscTextures", "Cleaning up " .. tileCount .. " middle tiles")
						for i = tileCount, 1, -1 do -- iterate backward to avoid index issues
							local tileTexture = texture[i]
							if tileTexture then
								-- Extra careful checking
								local hasHideMethod = pcall(function() return type(tileTexture.Hide) == "function" end)
								if hasHideMethod then
									pcall(function() tileTexture:Hide() end)
									pcall(function() addon:ReleaseTexture(tileTexture) end)
								end

								-- Remove from the array to avoid double cleanup
								pcall(function() texture[i] = nil end)
							end
						end
					else
						-- Regular texture cleanup
						local hasHideMethod = pcall(function() return type(texture.Hide) == "function" end)
						if hasHideMethod then
							pcall(function() texture:Hide() end)
							pcall(function() addon:ReleaseTexture(texture) end)
						end
					end
				end
			end

			-- Clear the textures table
			self.textures = nil
		end

		debug("miscTextures", "Cleanup complete")
	end
	debug("miscTextures", "Exit Apply3SliceTexture successfully")
	return container
end

-- ==========================================
-- Cleanup & Update Functions
-- ==========================================
function currencyAndTextures:RevertCurrencyFrameTexture(frame)
	debug("miscTextures", "RevertCurrencyFrameTexture called for frame: " ..
		(frame and (frame:GetName() or "unnamed") or "nil") ..
		", Mode: " .. (E.db and E.db.bagCustomizer and E.db.bagCustomizer.goldAnchorPosition or "unknown"))
	if not frame then
		return
	end

	local currencyButton = frame.currencyButton
	if not currencyButton then
		return
	end

	if currencyButton._BCZ_3SliceContainer then
		if currencyButton._BCZ_3SliceContainer.Cleanup then
			currencyButton._BCZ_3SliceContainer:Cleanup()
		end

		currencyButton._BCZ_3SliceContainer:Hide()
		currencyButton._BCZ_3SliceContainer = nil
	end

	self:ReleaseTrackedTextures(frame, "currencyBackdrop")
	if currencyButton._BCZ_backdrop then
		if currencyButton._BCZ_backdrop:GetObjectType() == "Texture" then
			addon:ReleaseTexture(currencyButton._BCZ_backdrop)
		end

		currencyButton._BCZ_backdrop = nil
	end

	debug("miscTextures", "TEXTURE STATE: Removed currency texture")
end

function currencyAndTextures:RevertGoldTextTexture(frame)
	if not frame then
		return
	end

	local goldText = frame.goldText
	if not goldText then
		return
	end

	if goldText._strataFrame and goldText._strataFrame._BCZ_3SliceContainer then
		if goldText._strataFrame._BCZ_3SliceContainer.Cleanup then
			goldText._strataFrame._BCZ_3SliceContainer:Cleanup()
		end

		goldText._strataFrame._BCZ_3SliceContainer:Hide()
		goldText._strataFrame._BCZ_3SliceContainer = nil
	end

	self:ReleaseTrackedTextures(frame, "goldTextBackdrop")
	if goldText._BCZ_backdrop then
		if goldText._BCZ_backdrop:GetObjectType() == "Texture" then
			addon:ReleaseTexture(goldText._BCZ_backdrop)
		end

		goldText._BCZ_backdrop = nil
	end

	if goldText._strataFrame then
		goldText._strataFrame:Hide()
	end
end

function currencyAndTextures:CleanupCloseButton(frame)
	if addon and addon._skipCloseButtonCleanup then -- MODIFIED LINE (Check addon object)
		print("miscTextures", "CleanupCloseButton: Skipping cleanup due to addon flag.")
		addon._skipCloseButtonCleanup = false        -- Reset the flag on the addon object
		return                                       -- Exit without cleaning up
	end

	if not frame then
		return
	end

	self:ReleaseTrackedTextures(frame, "closeButtonOverlay")
	self:ReleaseTrackedTextures(frame, "closeButtonGlow")
	local closeButton = frame.CloseButton or
			_G[(frame:GetName() or "") .. "CloseButton"] or
			_G[(frame:GetName() or "") .. "Close"]
	if not closeButton then
		for i = 1, frame:GetNumChildren() do
			local child = select(i, frame:GetChildren())
			if child and child:IsObjectType("Button") then
				local point1 = child:GetPoint(1)
				if point1 and point1:find("RIGHT") and point1:find("TOP") then
					closeButton = child
					break
				end
			end
		end
	end

	if closeButton then
		if closeButton._BCZ_originalPoint and closeButton._BCZ_usingCustomAnchor then
			local orig = closeButton._BCZ_originalPoint
			ClearAllPoints(closeButton)
			SetPoint(closeButton, orig.point, orig.relativeTo, orig.relativePoint, orig.xOfs, orig.yOfs)
		end

		if closeButton._BCZ_originalWidth then
			closeButton:SetSize(closeButton._BCZ_originalWidth, closeButton._BCZ_originalHeight)
		end

		closeButton._BCZ_originalPoint = nil
		closeButton._BCZ_originalWidth = nil
		closeButton._BCZ_originalHeight = nil
		closeButton._BCZ_usingCustomAnchor = nil
		closeButton._BCZ_hover_hooked = nil
	end

	local overlayName = "BagCustomizerCloseButtonOverlay_" .. (frame:GetName() or "unnamed")
	local overlay = _G[overlayName]
	if overlay then
		overlay:Hide()
		if overlay.texture then
			addon:ReleaseTexture(overlay.texture)
			overlay.texture = nil
		end

		if overlay.glowTexture then
			addon:ReleaseTexture(overlay.glowTexture)
			overlay.glowTexture = nil
		end

		overlay:SetParent(nil)
		_G[overlayName] = nil
	end
end

function currencyAndTextures:CaptureOriginalButtonPosition(closeButton, frame)
	if not closeButton then
		return
	end

	local point, relativeTo, relativePoint, x, y = closeButton:GetPoint(1)
	closeButton._BCZ_originalPoint = {
		point = point or "TOPRIGHT",
		relativeTo = relativeTo or frame,
		relativePoint = relativePoint or "TOPRIGHT",
		xOfs = x or 0,
		yOfs = y or 0,
	}
	closeButton._BCZ_originalWidth = closeButton:GetWidth()
	closeButton._BCZ_originalHeight = closeButton:GetHeight()
end

function currencyAndTextures:DelayedCurrencyCheck()
	-- Check if database is available
	if not E or not E.db or not E.db.bagCustomizer then
		debug("currency", "Database not available for delayed currency check, trying again later.")
		C_Timer.After(1, function() self:DelayedCurrencyCheck() end)
		return
	end

	debug("currency", "Running delayed currency row detection")
	-- Skip if currency module is disabled
	if not E.db.bagCustomizer.currencyModuleEnabled then
		debug("currency", "Currency module disabled, skipping delayed check.")
		return
	end

	-- Check if there are bags visible
	local bagFrame = self:GetBagFrame() -- Use FindBagFrame for better chance
	if not bagFrame or not bagFrame:IsShown() then
		debug("currency", "No bags visible for delayed currency check")
		return
	end

	-- Instead of calculating rows here, just trigger an update.
	-- The B.Layout hook will handle accurate row calculation when it runs.
	debug("currency", "Bags visible, triggering update for delayed currency check.")
	self:UpdateBagFrames() -- This will call UpdateFrame -> Apply textures.
end

-- ==========================================
-- Update Functions
-- ==========================================
function currencyAndTextures:ForceUpdate()
	if self.isRefreshing then
		return
	end

	self.isRefreshing = true
	debug("currency", "Force update: Using simple ElvUI refresh")
	-- Get ElvUI's Bags module directly
	local B = E:GetModule("Bags")
	-- We know this works because this is what happens during a reload
	if B and B.Layout then
		-- Force a complete layout refresh using ElvUI's own system
		C_Timer.After(0.05, function()
			-- This is the proper ElvUI way to update the layout
			B:Layout(false) -- false = not bank
			-- Release the lock after a short delay
			C_Timer.After(0.2, function()
				self.isRefreshing = false
				debug("currency", "Force update: Refresh completed")
			end)
		end)
	else
		-- Fallback if B.Layout isn't available
		self.isRefreshing = false
	end
end

function currencyAndTextures:UpdateFrame(frame)
	if not self:ShouldUpdateFrame(frame) then
		return
	end

	debug("miscTextures", "UpdateFrame: Updating frame '" .. (frame:GetName() or "unnamed") .. "'")
	self:CalculateDimensions() -- Always calculate latest dimensions
	-- Apply textures that are safe to apply immediately
	self:ApplyCloseButtonTexture(frame)
	self:ApplyGoldTextTexture(frame)
	-- Added defensive check for E.db and E.db.bagCustomizer
	if not E or not E.db or not E.db.bagCustomizer then
		return
	end

	-- Check if currency texture needs deferred application
	local currencySettings = E.db.bagCustomizer.currencyTexture
	local anchorPos = E.db.bagCustomizer.goldAnchorPosition
	if currencySettings and currencySettings.enable and currencySettings.autoFitHeight and
			(anchorPos == "BOTTOM_RIGHT_BELOW" or anchorPos == "BOTTOM_RIGHT_ABOVE") then
		-- If autoFit is enabled, ApplyCurrencyFrameTexture is already scheduled by the Layout hook's C_Timer.After(0)
		debug("miscTextures", "UpdateFrame: ApplyCurrencyFrameTexture deferred by Layout hook.")
	else
		-- Apply immediately if autoFit is off or feature disabled/default mode
		self:ApplyCurrencyFrameTexture(frame)
	end
end

function currencyAndTextures:UpdateBagFrames(specificFrame)
	if specificFrame then
		self:UpdateFrame(specificFrame)
		return
	end

	local bagFrame = self:FindBagFrame()
	if bagFrame then
		self:UpdateFrame(bagFrame)
	end

	-- Skip bank frames completely
end

function currencyAndTextures:UpdateSettings()
	debug("currency", "UpdateSettings triggered")
	-- Added defensive check for E.db
	if not E or not E.db then
		debug("currency", "E.db not available in UpdateSettings, trying again later.")
		C_Timer.After(1, function() self:UpdateSettings() end)
		return
	end

	-- Added defensive check for E.db.bagCustomizer
	if not E.db.bagCustomizer then
		debug("currency", "E.db.bagCustomizer not available in UpdateSettings, trying again later.")
		C_Timer.After(1, function() self:UpdateSettings() end)
		return
	end

	local previousMode = self.currentMode
	local currentMode = E.db.bagCustomizer.goldAnchorPosition
	self.currentMode = currentMode
	-- If this is a mode change, force gold text reset
	if previousMode and previousMode ~= currentMode then
		debug("currency", "DIAGNOSTIC - Mode changed from " .. previousMode .. " to " .. currentMode)
		-- Always reset gold text position when changing modes
		self:ResetGoldText()
	end

	local B = GetBagsModule()
	-- Enhanced cleanup when module is disabled
	if not E.db.bagCustomizer.enabled or not E.db.bagCustomizer.currencyModuleEnabled then
		debug("currency", "Module disabled, performing thorough cleanup.")
		-- First reset stored dimensions to ensure clean state
		currentDimensions = {}
		-- Unhook any hooks that might reapply settings
		self:UnhookAll()
		-- Reset the gold text position and strata
		self:ResetGoldText()
		-- Reset any bag frames that might be visible
		local bagFrame = self:GetBagFrame()
		if bagFrame then
			-- Reset inventory offsets
			self:ResetInventoryTopOffset(bagFrame)
			-- Clean up textures
			self:RevertCurrencyFrameTexture(bagFrame)
			self:RevertGoldTextTexture(bagFrame)
			self:CleanupCloseButton(bagFrame)
			-- Force a layout refresh
			if self:IsAnyBagVisible() and B and B.Layout then
				C_Timer.After(0.05, function()
					if B and B.Layout then
						B:Layout()
					end
				end)
			end
		end

		return
	end

	-- Setup gold text strata fix hook if needed - this ensures it persists across layout updates
	if E.db.bagCustomizer.fixGoldTextStrata and not self.goldTextStrataHooked then
		if B and B.Layout then
			debug("currency", "Setting up gold text strata fix hook")
			hooksecurefunc(B, "Layout", function(bagModule, isBank)
				if isBank then return end

				-- Delay slightly to ensure gold text is fully initialized
				C_Timer.After(0.05, function()
					local bagFrame = self:GetBagFrame()
					if bagFrame and bagFrame:IsShown() and bagFrame.goldText then
						self:ApplyGoldTextFix(bagFrame)
					end
				end)
			end)
			self.goldTextStrataHooked = true
		end
	elseif not E.db.bagCustomizer.fixGoldTextStrata and self.goldTextStrataHooked then
		-- We can't unhook the function, but we can reset the gold text
		self:ResetGoldText()
	end

	-- Legacy setting compatibility
	E.db.bagCustomizer.reverseCurrencyGrowth = (E.db.bagCustomizer.goldAnchorPosition == "BOTTOM_RIGHT_BELOW")
	-- Apply different behavior based on mode
	local currentMode = E.db.bagCustomizer.goldAnchorPosition
	local bagFrame = self:GetBagFrame()
	-- Handle DEFAULT mode
	if currentMode == "DEFAULT" then
		if isHooked then
			debug("currency", "Switching to Default mode, unhooking.")
			self:UnhookAll()
			-- Complete texture and position cleanup for DEFAULT mode
			if bagFrame then
				self:ResetInventoryTopOffset(bagFrame)
				self:RevertCurrencyFrameTexture(bagFrame)
				self:RevertGoldTextTexture(bagFrame)
				-- We still want to maintain close button texture if enabled
				if E.db.bagCustomizer.closeButtonTexture and E.db.bagCustomizer.closeButtonTexture.enable then
					self:ApplyCloseButtonTexture(bagFrame)
				else
					self:CleanupCloseButton(bagFrame)
				end
			end

			-- Reset gold text position
			self:ResetGoldText()
			-- Force a layout update
			if self:IsAnyBagVisible() and B and B.Layout then
				C_Timer.After(0.05, function()
					if B and B.Layout then
						B:Layout()
					end
				end)
			end
		end

		-- For DEFAULT mode, still apply gold text strata fix if enabled with a delay
		if E.db.bagCustomizer.fixGoldTextStrata then
			C_Timer.After(0.1, function()
				self:ApplyGoldTextFix(bagFrame)
			end)
		else
			self:ResetGoldText()
		end

		return -- Exit early after handling DEFAULT mode
	end

	-- Handle non-DEFAULT modes
	-- CURRENCY_ONLY mode
	if currentMode == "CURRENCY_ONLY" then
		self:RevertGoldTextTexture(bagFrame)
		-- GOLD_ONLY mode
	elseif currentMode == "GOLD_ONLY" then
		self:RevertCurrencyFrameTexture(bagFrame)
	end

	-- Set up hooks for non-DEFAULT modes
	self:SetupHooks(true)
	-- Apply gold text strata fix if enabled for all non-DEFAULT modes with a delay
	if E.db.bagCustomizer.fixGoldTextStrata then
		C_Timer.After(0.1, function()
			self:ApplyGoldTextFix(bagFrame)
		end)
	end

	-- For all modes, trigger a layout update if bags are visible
	if self:IsAnyBagVisible() then
		if B and B.Layout then
			C_Timer.After(0.05, function()
				if B and B.Layout then
					B:Layout()
				else
					self:UpdateBagFrames()
				end
			end)
		else
			C_Timer.After(0.1, function()
				self:UpdateBagFrames()
			end)
		end
	end
end

function currencyAndTextures:RevertFrame(frame)
	if not frame then
		return
	end

	self:CleanupCloseButton(frame)
	self:RevertCurrencyFrameTexture(frame)
	self:RevertGoldTextTexture(frame)
	self:ReleaseTrackedTextures(frame)
end

-- ==========================================
-- Settings Update & Initialization
-- ==========================================
function currencyAndTextures:Initialize()
	debug("currency", "Initializing CurrencyAndTextures module")
	-- Added defensive check for E.db
	if not E or not E.db then
		debug("currency", "E.db not available in Initialize, trying again later.")
		C_Timer.After(1, function() self:Initialize() end)
		return
	end

	-- Default settings setup - these are now moved to Settings.lua
	self.activeTextures = {}
	-- Register for events using the core event system
	addon:RegisterForEvent("GOLD_TEXT_X_OFFSET_CHANGED", function(value)
		-- Added defensive check for E.db and E.db.bagCustomizer
		if not E or not E.db or not E.db.bagCustomizer then
			return
		end

		debug("currency", "Gold text X offset changed to: " .. tostring(value))
		currencyAndTextures:RepositionGoldText()
		currencyAndTextures:ApplyGoldTextTexture(currencyAndTextures:GetBagFrame())
	end)
	addon:RegisterForEvent("GOLD_TEXT_Y_OFFSET_CHANGED", function(value)
		-- Added defensive check for E.db and E.db.bagCustomizer
		if not E or not E.db or not E.db.bagCustomizer then
			return
		end

		debug("currency", "Gold text Y offset changed to: " .. tostring(value))
		currencyAndTextures:RepositionGoldText()
		currencyAndTextures:ApplyGoldTextTexture(currencyAndTextures:GetBagFrame())
	end)
	addon:RegisterForEvent("CURRENCY_TEXTURE_CHANGED", function()
		-- Added defensive check for E.db and E.db.bagCustomizer
		if not E or not E.db or not E.db.bagCustomizer then
			return
		end

		debug("currency", "Currency texture settings changed")
		currencyAndTextures:ForceUpdate()
	end)
	addon:RegisterForEvent("GOLD_TEXT_TEXTURE_CHANGED", function()
		-- Added defensive check for E.db and E.db.bagCustomizer
		if not E or not E.db or not E.db.bagCustomizer then
			return
		end

		debug("currency", "Gold text texture settings changed")
		currencyAndTextures:ForceUpdate()
	end)
	addon:RegisterForEvent("PADDING_CHANGED", function(value)
		-- Added defensive check for E.db and E.db.bagCustomizer
		if not E or not E.db or not E.db.bagCustomizer then
			return
		end

		debug("currency", "Padding changed to: " .. tostring(value))
		currencyAndTextures:UpdateCurrencyHorizontalPadding()
		currencyAndTextures:ForceUpdate()
	end)
	addon:RegisterForEvent("GOLD_ANCHOR_POSITION_CHANGED", function(newMode)
		-- Added defensive check for E.db and E.db.bagCustomizer
		if not E or not E.db or not E.db.bagCustomizer then
			return
		end

		debug("currency", "DIAGNOSTIC - Gold Anchor Position changed to: " .. tostring(newMode))
		-- Force an update even when there are no currencies
		currencyAndTextures:UpdateSettings()
		-- Force ElvUI to update bags
		local B = E:GetModule("Bags")
		if B and B.Layout and currencyAndTextures:IsAnyBagVisible() then
			C_Timer.After(0.1, function()
				if B and B.Layout then
					B:Layout(false) -- false = not bank
					-- Do a secondary update to catch any issues
					C_Timer.After(0.2, function()
						currencyAndTextures:UpdateBagFrames()
					end)
				end
			end)
		end
	end)
	addon:RegisterForEvent("CURRENCY_MODULE_ENABLED", function(enabled)
		-- Added defensive check for E.db and E.db.bagCustomizer
		if not E or not E.db or not E.db.bagCustomizer then
			return
		end

		debug("currency", "Currency module " .. (enabled and "enabled" or "disabled"))
		self:UpdateSettings()
	end)
	addon:RegisterForEvent("BAGS_INITIALIZED", function()
		debug("currency", "Bags initialized, scheduling currency row check")
		C_Timer.After(0.5, function()
			self:DelayedCurrencyCheck()
		end)
	end)
	addon:RegisterForEvent("CURRENCY_DIMENSIONS_UPDATED", function(dims)
		currentDimensions = dims
		if self:IsAnyBagVisible() then
			self:UpdateBagFrames()
		end
	end)
	addon:RegisterForEvent("BAG_FRAME_MOVED", function(f)
		if f and f:IsShown() then
			C_Timer.After(0.1, function()
				self:ApplyCloseButtonTexture(f)
			end)
		end
	end)
	addon:RegisterForEvent("BAG_FRAME_RESIZED", function(f)
		if f and f:IsShown() then
			C_Timer.After(0.1, function()
				self:UpdateBagFrames(f)
			end)
		end
	end)
	addon:RegisterForEvent("PROFILE_CHANGED", function()
		debug("currency", "Profile changed, scheduling refresh after short delay")
		-- Added more comprehensive handling of profile changes
		self:UnhookAll()
		self:ResetGoldText()
		currentDimensions = {}
		-- Wait longer before reinitializing to ensure ElvUI has time to apply new profile settings
		C_Timer.After(0.5, function()
			if not E or not E.db then
				debug("currency", "E.db not available after profile change, retrying later")
				C_Timer.After(1, function() self:UpdateSettings() end)
				return
			end

			if not E.db.bagCustomizer then
				debug("currency", "E.db.bagCustomizer not available after profile change, retrying later")
				C_Timer.After(1, function() self:UpdateSettings() end)
				return
			end

			self:UpdateSettings()
		end)
	end)
	addon:RegisterForEvent("COMBAT_STARTED", function()
		-- When combat starts, cancel any expensive operations
		if self.textureUpdateTimer then
			self.textureUpdateTimer:Cancel()
			self.textureUpdateTimer = nil
		end
	end)
	addon:RegisterForEvent("COMBAT_ENDED", function()
		-- When combat ends, update textures if bags are visible
		if self:IsAnyBagVisible() then
			C_Timer.After(0.2, function()
				self:UpdateBagFrames()
			end)
		end
	end)
	addon:RegisterForEvent("GLOBAL_TOGGLE_CHANGED", function(enabled)
		-- Added defensive check for E.db and E.db.bagCustomizer
		if not E or not E.db or not E.db.bagCustomizer then
			return
		end

		debug("currency", "Global toggle changed to: " .. (enabled and "enabled" or "disabled"))
		-- Force a full settings update with no delay
		self:UpdateSettings()
		-- If disabled, ensure a complete reset of all components
		if not enabled then
			local bagFrame = self:GetBagFrame()
			if bagFrame then
				self:ResetInventoryTopOffset(bagFrame)
				self:RevertCurrencyFrameTexture(bagFrame)
				self:RevertGoldTextTexture(bagFrame)
				self:CleanupCloseButton(bagFrame)
				self:ResetGoldText()
				-- Force the original layout function to run for a clean reset
				local B = GetBagsModule()
				if B and B.Layout and originalLayout then
					C_Timer.After(0.1, function()
						if self:IsAnyBagVisible() then
							originalLayout(B, false) -- Call original without using our hook
						end
					end)
				end
			end
		end
	end)
	-- Register explicit callback for profile changes through ElvUI's system
	E:RegisterCallback("OnProfileChanged", function()
		debug("currency", "ElvUI OnProfileChanged callback received")
		-- Clean up and then reinitialize after a delay
		currencyAndTextures:Cleanup()
		C_Timer.After(0.5, function()
			currencyAndTextures:Initialize()
		end)
	end)
	-- Hook ElvUI Bag Module events
	local B = GetBagsModule()
	if B then
		local function DelayedUpdate()
			-- Immediately reposition gold text first
			currencyAndTextures:UpdateGoldTextPositionImmediately()
			-- Then do the normal delayed update for other elements
			C_Timer.After(0.15, function()
				if not E or not E.db or not E.db.bagCustomizer then
					return
				end

				if E.db.bagCustomizer.enabled and E.db.bagCustomizer.currencyModuleEnabled then
					currencyAndTextures:UpdateBagFrames()
				end
			end)
		end

		if B.OpenBags then
			hooksecurefunc(B, "OpenBags", DelayedUpdate)
		end

		if B.ToggleBags then
			hooksecurefunc(B, "ToggleBags", DelayedUpdate)
		end

		if B.OpenBank then
			hooksecurefunc(B, "OpenBank", DelayedUpdate)
		end

		-- Try to hook into the function that updates gold text
		if B.UpdateGoldText then
			hooksecurefunc(B, "UpdateGoldText", function()
				-- Check if module is enabled and bags are visible
				if not E or not E.db or not E.db.bagCustomizer then
					return
				end

				if E.db.bagCustomizer.enabled and
						E.db.bagCustomizer.currencyModuleEnabled and
						currencyAndTextures:IsAnyBagVisible() then
					-- Get current mode
					local currentMode = E.db.bagCustomizer.goldAnchorPosition
					-- Only update for relevant modes
					if currentMode == "GOLD_ONLY" or currentMode == "BOTTOM_CURRENCY_TOP_GOLD" then
						C_Timer.After(0.05, function() -- Short delay to ensure gold text is updated
							local bagFrame = currencyAndTextures:GetBagFrame()
							if bagFrame and bagFrame:IsShown() then
								currencyAndTextures:ApplyGoldTextTexture(bagFrame)
							end
						end)
					end
				end
			end)
			debug("currency", "Successfully hooked into B.UpdateGoldText")
		else
			-- Alternative hook if UpdateGoldText doesn't exist
			-- This is a backup method and might not catch all updates
			if B.Layout then
				hooksecurefunc(B, "Layout", function()
					C_Timer.After(0.1, function()
						if not E or not E.db or not E.db.bagCustomizer then
							return
						end

						if currencyAndTextures:IsAnyBagVisible() then
							local currentMode = E.db.bagCustomizer.goldAnchorPosition
							if currentMode == "GOLD_ONLY" or currentMode == "BOTTOM_CURRENCY_TOP_GOLD" then
								local bagFrame = currencyAndTextures:GetBagFrame()
								if bagFrame and bagFrame.goldText then
									currencyAndTextures:ApplyGoldTextTexture(bagFrame)
								end
							end
						end
					end)
				end)
				debug("currency", "Hooked into B.Layout as fallback for gold updates")
			end
		end

		addon:RegisterEvent("LOADING_SCREEN_DISABLED", function()
			-- Immediate gold text update after loading screen finishes
			C_Timer.After(0.1, function()
				currencyAndTextures:UpdateGoldTextPositionImmediately()
			end)
		end)
		-- Add event hook for player money changes
		addon:RegisterEvent("PLAYER_MONEY", function()
			if not E or not E.db or not E.db.bagCustomizer then
				return
			end

			if currencyAndTextures:IsAnyBagVisible() then
				local currentMode = E.db.bagCustomizer.goldAnchorPosition
				if currentMode == "GOLD_ONLY" or currentMode == "BOTTOM_CURRENCY_TOP_GOLD" then
					C_Timer.After(0.05, function()
						local bagFrame = currencyAndTextures:GetBagFrame()
						if bagFrame and bagFrame:IsShown() then
							currencyAndTextures:ApplyGoldTextTexture(bagFrame)
						end
					end)
				end
			end
		end)
	end

	-- Register global events via addon's event system
	addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		-- Immediate update for gold text positioning
		C_Timer.After(0.1, function()
			currencyAndTextures:UpdateGoldTextPositionImmediately()
		end)
		-- Keep the existing delayed full update
		C_Timer.After(3, function()
			currencyAndTextures:UpdateSettings()
			C_Timer.After(2, function()
				currencyAndTextures:DelayedCurrencyCheck()
			end)
		end)
	end)
	addon:RegisterEvent("UI_SCALE_CHANGED", function()
		C_Timer.After(0.2, function()
			self:UpdateSettings()
		end)
	end)
	-- Hook ElvUI profile update
	if E.UpdateAll then
		hooksecurefunc(E, "UpdateAll", function()
			C_Timer.After(0.2, function()
				self:UpdateSettings()
			end)
		end)
	end

	-- Initial update after setup
	C_Timer.After(0.5, function()
		-- Check if module is enabled before initial update
		if E and E.db and E.db.bagCustomizer and
				E.db.bagCustomizer.enabled and
				E.db.bagCustomizer.currencyModuleEnabled then
			self:UpdateBagFrames()
		end
	end)
	debug("currency", "CurrencyAndTextures module initialization complete")
end

function currencyAndTextures:Cleanup()
	debug("currency", "Cleaning up CurrencyAndTextures module")
	self:UnhookAll()
	self:ResetGoldText()
	-- Release textures, conditionally skipping close button ones
	local ownersToClean = {}
	-- Safter iteration: collect keys first
	for ownerKey in pairs(self.activeTextures) do
		table.insert(ownersToClean, ownerKey)
	end

	local flagWasCheckedAndTrue = false -- Keep track if we actually skipped something
	for _, ownerKey in ipairs(ownersToClean) do
		local texturesToClean = {}
		if self.activeTextures[ownerKey] then -- Check owner still exists
			-- Collect keys for safer iteration
			for key in pairs(self.activeTextures[ownerKey]) do
				table.insert(texturesToClean, key)
			end

			for _, key in ipairs(texturesToClean) do
				local texture = self.activeTextures[ownerKey] and self.activeTextures[ownerKey][key]
				if texture then
					local shouldReleaseAndRemove = true
					-- Check if we should skip releasing AND removing this specific texture
					if addon and addon._skipCloseButtonCleanup and (key == "closeButtonOverlay" or key == "closeButtonGlow") then
						debug("currency", "Cleanup: Skipping release AND removal of texture key '" .. key .. "' due to addon flag.")
						shouldReleaseAndRemove = false
						flagWasCheckedAndTrue = true -- Mark that we used the flag
					end

					if shouldReleaseAndRemove then
						-- Release the texture if not skipping
						pcall(addon.ReleaseTexture, addon, texture)
						-- Remove from tracking ONLY if released/removed
						if self.activeTextures[ownerKey] then
							self.activeTextures[ownerKey][key] = nil
						end

						-- else: If skipping, DO NOT release and DO NOT remove from tracking
						-- This leaves the texture object potentially active and still tracked
					end
				end
			end

			-- Clean up owner entry if now empty AFTER processing all its textures
			if self.activeTextures[ownerKey] and next(self.activeTextures[ownerKey]) == nil then
				self.activeTextures[ownerKey] = nil
			end
		end
	end

	-- If the flag was set and used, we need to ensure the full CleanupCloseButton logic
	-- (resetting position, etc.) doesn't run accidentally later if the settings *did* change.
	-- However, if the flag was *intended* to be used (because settings are same),
	-- but wasn't actually encountered in the loop (e.g., textures weren't active for some reason),
	-- we still need to reset the flag.
	-- Therefore, reset the flag unconditionally *after* the loop is done checking it.
	if addon and addon._skipCloseButtonCleanup then
		debug("currency", "Cleanup: Resetting skip flag post-loop.")
		addon._skipCloseButtonCleanup = false
	end

	-- Rest of cleanup
	isHooked = false
	originalLayout = nil
	inUpdate = false
	currentDimensions = {}
	if addon.CleanupMemory then
		addon:CleanupMemory(true)
	end

	debug("currency", "CurrencyAndTextures module cleanup complete")
end

-- Register the module with the core addon
if addon.RegisterElement then
	addon:RegisterElement("currencyAndTextures", currencyAndTextures)
else
	addon.elements.currencyAndTextures = currencyAndTextures
	currencyAndTextures:Initialize()
end

return currencyAndTextures
