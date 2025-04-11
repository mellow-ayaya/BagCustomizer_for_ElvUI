-- Bag Customizer for ElvUI - Bind Text module
-- Version: 6.0
-- Focus: Bag-only support, performance optimizations, memory management
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags")              -- Get ElvUI Bags module
local addon = E:GetModule("BagCustomizer") -- Get main addon module
-- Check if ElvUI Bags module loaded
if not B then
	print("|cFFFF0000Bag Customizer Error: ElvUI Bags module (B) not found! Cannot initialize bindText module.|r")
	return -- Stop loading this file if Bags module isn't available
end

-- Create module namespace
local module = {}
addon.elements.bindText = module
module.coloredSlots = {} -- Tracks slots with custom colors applied
-- ==========================================
-- Configuration
-- ==========================================
local CONFIG = {
	FLICKER_CHECK_INTERVAL = 0.1,
	ACTIVITY_MONITOR_DURATION = 3,
	MAX_MOVEMENT_UPDATE_ATTEMPTS = 6,
	MAX_SORT_UPDATE_ATTEMPTS = 10,
	UPDATE_ATTEMPT_INTERVAL = 0.12,
	INITIAL_SORT_DELAY = 0.3,
	SORT_UPDATE_INTERVAL_MULTIPLIER = 1.1,
	USE_FUNCTION_REPLACEMENT = true,
	MAX_PENDING_UPDATE_AGE = 3,
	REGULAR_BAG_ID_START = 0,
	REGULAR_BAG_ID_END = 4, -- Only process bags 0-4 (regular bags)
}
-- ==========================================
-- Debug function (with throttling)
-- ==========================================
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][bindText]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.bindText or
			not E.db.bagCustomizer.bindText.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- Check if we're using Retail WoW
local isRetail = _G.C_Container ~= nil
-- Safe slot iteration helper to prevent C overflow
function module:SafeGetContainerNumSlots(bagID)
	if not bagID then return 0 end

	local success, numSlots
	if isRetail then
		success, numSlots = pcall(function() return C_Container.GetContainerNumSlots(bagID) end)
	else
		success, numSlots = pcall(function() return GetContainerNumSlots(bagID) end)
	end

	if success and numSlots and type(numSlots) == "number" then
		return numSlots
	end

	return 0 -- Return safe default
end

-- Safe frame/region iteration helper
function module:SafeGetRegions(parent)
	if not parent then return {} end

	local regions = {}
	local success, result = pcall(function()
		local count = parent:GetNumRegions() or 0
		for i = 1, count do
			local region = select(i, parent:GetRegions())
			if region then table.insert(regions, region) end
		end

		return regions
	end)
	if success then
		return result
	end

	return {} -- Return safe empty table
end

-- Safe table wipe function
function module:SafeWipe(t)
	if type(t) ~= "table" then return end

	wipe(t)
end

-- ==========================================
-- State Management Functions
-- ==========================================
function module:IsModuleEnabled()
	local success, result = pcall(function()
		return E.db.bagCustomizer and E.db.bagCustomizer.enabled and
				E.db.bagCustomizer.bindTextSettings and E.db.bagCustomizer.bindTextSettings.enable
	end)
	return success and result or false
end

function module:IsEnabled()
	return self:IsModuleEnabled()
end

-- Helper function to check if a bagID is a regular bag (not bank/reagent bank)
function module:IsRegularBag(bagID)
	if not bagID then return false end

	-- Use constants for regular bag range
	return bagID >= CONFIG.REGULAR_BAG_ID_START and bagID <= CONFIG.REGULAR_BAG_ID_END
end

-- ==========================================
-- Module Initialization
-- ==========================================
function module:Initialize()
	debug("Initializing bindText module... (v6)")
	-- Ensure settings tables exist
	if not E.db.bagCustomizer then E.db.bagCustomizer = {} end

	if not E.db.bagCustomizer.bindText then E.db.bagCustomizer.bindText = E:CopyTable({}, P.bagCustomizer.bindText) end

	if not E.db.bagCustomizer.bindTextSettings then
		E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, P.bagCustomizer.bindTextSettings)
	end

	-- Ensure settings tables exist
	self:EnsureSettingsExist()
	-- Initialize state tracking
	module.replacedFunctions = {}
	module.pendingUpdates = {}
	module.activeColorApplier = false
	module.lastBagActivity = 0
	module.isSorting = false
	module.updateTimers = {}
	module.updateSequenceScheduled = false
	module.combatSuspended = false
	-- Setup hooks and events
	self:SetupEvents() -- Setup events now, including BAGS_INITIALIZED handler
	self:SetupContinuousMonitoring()
	-- Initial update after a delay
	C_Timer.After(0.6, function()
		if self:IsModuleEnabled() then
			debug("Performing initial UpdateAll")
			self:UpdateAll()
		end
	end)
	debug("bindText module initialization complete (v6)")
end

-- ==========================================
-- Setup Hooks (Now called later)
-- ==========================================
function module:SetupHooks()
	if self.hooksSet then
		debug("SetupHooks called again, skipping.")
		return
	end

	debug("Setting up hooks... (v6 - Deferred Call)")
	-- Hook ElvUI's slot update function (Keep for general updates)
	if B and B.UpdateSlot then
		addon:SecureHook(B, "UpdateSlot", function(_, frame, bagID, slotID)
			if not self:IsModuleEnabled() or self.isSorting or not self:IsRegularBag(bagID) then return end

			module.lastBagActivity = GetTime()
			self:QueueSlotUpdate(frame, bagID, slotID)
		end)
		debug("Hooked B:UpdateSlot.")
	end

	-- Hook ElvUI's item info update function (Keep for general updates)
	if B and B.SetItemInfo then
		addon:SecureHook(B, "SetItemInfo", function(_, frame, bagID, slotID)
			if not self:IsModuleEnabled() or self.isSorting or not self:IsRegularBag(bagID) then return end

			module.lastBagActivity = GetTime()
			self:QueueSlotUpdate(nil, bagID, slotID, frame)
		end)
		debug("Hooked B:SetItemInfo.")
	end

	-- Hook ElvUI's layout function (Keep, might fire after sort completion sometimes)
	if B and B.Layout then
		addon:SecureHook(B, "Layout", function()
			if not self:IsModuleEnabled() then return end

			if module.isSorting then
				debug("Layout hook fired during sort - deferring to SchedulePostSortUpdate")
				return
			end

			debug("Layout hook fired - scheduling update sequence")
			module.lastBagActivity = GetTime()
			self:ScheduleUpdateSequence()
		end)
		debug("Hooked B:Layout.")
	end

	-- == CRITICAL: Hook sorting functions ==
	local function OnSortDetected(sortType)
		if not module:IsModuleEnabled() then
			debug("OnSortDetected called for " .. sortType .. " BUT MODULE DISABLED!")
			return
		end

		debug("OnSortDetected executing for " .. sortType .. " (isSorting was: " .. tostring(module.isSorting) .. ")")
		if module.isSorting then
			return
		end

		debug("=========================================")
		debug(">>> SORT DETECTED VIA: " .. sortType)
		debug("=========================================")
		module.lastBagActivity = GetTime()
		module.isSorting = true
		self:SchedulePostSortUpdate()
	end

	-- *** PRIMARY TARGET: B:SortingFadeBags ***
	if B and B.SortingFadeBags then
		debug("Attempting to hook B:SortingFadeBags...")
		addon:SecureHook(B, "SortingFadeBags", function(bagFrame, sortingSlots)
			if sortingSlots == true then -- Explicitly check for true
				OnSortDetected("B:SortingFadeBags")
			end
		end)
	else
		debug("ERROR: B:SortingFadeBags function NOT FOUND! Cannot reliably detect ElvUI sort start.")
	end

	-- *** Fallback Target: B.SortBags ***
	if B and B.SortBags then
		debug("Attempting to hook B.SortBags (fallback)...")
		addon:SecureHook(B, "SortBags", function(...)
			OnSortDetected("B.SortBags")
		end)
	else
		debug("Warning: B.SortBags not found during hook setup.")
	end

	-- Blizzard Hooks
	if isRetail then
		if C_Container.SortBags then
			hooksecurefunc(C_Container, "SortBags", function()
				OnSortDetected("Blizzard C_Container.SortBags")
			end)
		end
	else -- Classic
		if _G.SortBags then
			hooksecurefunc("SortBags", function()
				OnSortDetected("Classic SortBags")
			end)
		end
	end

	-- Hook bag frame show events (Keep)
	local function OnFrameShow(frameName)
		if not self:IsModuleEnabled() then return end

		if module.isSorting then
			debug(frameName .. " Show hook fired during sort - deferring update")
			return
		end

		debug(frameName .. " Show hook fired - scheduling update sequence")
		module.lastBagActivity = GetTime()
		C_Timer.After(0.1, function()
			if not module.isSorting and self:IsModuleEnabled() then
				self:ScheduleUpdateSequence()
			end
		end)
	end

	if B.BagFrame and B.BagFrame.Show then
		addon:SecureHook(B.BagFrame, "Show", function() OnFrameShow("BagFrame") end)
	end

	-- Hook item movement APIs (Keep)
	local function OnItemPickup(bagID, slotID)
		if not self:IsModuleEnabled() or not self:IsRegularBag(bagID) then return end

		module.lastBagActivity = GetTime()
		debug("Item picked up from bag " .. bagID .. ", slot " .. slotID)
		module.activeBagID = bagID
		if CONFIG.USE_FUNCTION_REPLACEMENT then self:ProtectAllBindTexts() end
	end

	local function OnItemActivity()
		if not self:IsModuleEnabled() or module.isSorting then return end

		module.lastBagActivity = GetTime()
		debug("Item activity detected (Use/Delete/Split/Put) - scheduling update sequence")
		self:ScheduleUpdateSequence()
	end

	if isRetail then
		if C_Container and C_Container.PickupContainerItem then
			hooksecurefunc(C_Container, "PickupContainerItem", OnItemPickup)
		end

		for _, funcName in ipairs({ "UseContainerItem", "DeleteCursorItem", "SplitContainerItem" }) do
			if C_Container and C_Container[funcName] then hooksecurefunc(C_Container, funcName, OnItemActivity) end
		end
	else -- Classic WoW
		if _G.PickupContainerItem then hooksecurefunc("PickupContainerItem", OnItemPickup) end

		for _, funcName in ipairs({ "UseContainerItem", "DeleteCursorItem", "SplitContainerItem", "PutItemInBag" }) do
			if _G[funcName] then hooksecurefunc(_G, funcName, OnItemActivity) end
		end
	end

	-- Create a frame to track cursor state changes (Keep)
	if not self.cursorTracker then
		self.cursorTracker = CreateFrame("Frame")
		self.cursorTracker.elapsed = 0
		self.cursorTracker:SetScript("OnUpdate", function(_, elapsed)
			if not self:IsModuleEnabled() then return end

			self.cursorTracker.elapsed = self.cursorTracker.elapsed + elapsed
			if self.cursorTracker.elapsed < 0.05 then return end

			self.cursorTracker.elapsed = 0
			local hasItem = CursorHasItem()
			if hasItem and not self.cursorHasItem then
				self.cursorHasItem = true
				module.lastBagActivity = GetTime()
				if CONFIG.USE_FUNCTION_REPLACEMENT then self:ProtectAllBindTexts() end
			elseif not hasItem and self.cursorHasItem then
				self.cursorHasItem = nil
				module.lastBagActivity = GetTime()
				self.activeBagID = nil
				if not module.isSorting then
					debug("Cursor item dropped - scheduling update sequence")
					self:ScheduleUpdateSequence()
				else
					debug("Cursor item dropped during sort - deferring update to post-sort sequence")
				end
			end
		end)
	end

	self.hooksSet = true -- Mark hooks as set
	debug("Hooks setup complete for bindText module (v6)")
end

-- ==========================================
-- Schedule Post Sort Update (Recursive Implementation)
-- ==========================================
function module:SchedulePostSortUpdate()
	debug(">>> Entering SchedulePostSortUpdate <<<")
	-- Ensure previous function replacements are cleared
	if CONFIG.USE_FUNCTION_REPLACEMENT then
		debug("Restoring any existing function replacements before post-sort sequence")
		self:RestoreAllFunctions()
	end

	-- Clear pending individual slot updates queue
	if next(module.pendingUpdates) then
		debug("Clearing pending individual slot updates queue.")
		self:SafeWipe(module.pendingUpdates)
	end

	-- Cancel any existing timers
	for _, timer in ipairs(module.updateTimers) do
		if timer.Cancel then timer:Cancel() end
	end

	self:SafeWipe(module.updateTimers)
	-- Create recursive update function
	local function processAttempt(attemptNum, maxAttempts)
		if not module.isSorting or not module:IsModuleEnabled() then
			debug("Sort flag no longer active or module disabled - aborting sequence")
			module.isSorting = false
			return
		end

		debug(string.format("Post-sort update attempt %d/%d", attemptNum, maxAttempts))
		if attemptNum == 1 then
			debug("Clearing coloredSlots cache for fresh post-sort update.")
			wipe(module.coloredSlots) -- Clear cache only on first attempt
		end

		self:UpdateAll() -- Update colors
		if CONFIG.USE_FUNCTION_REPLACEMENT and attemptNum < maxAttempts then
			debug("Protecting bind texts (Post-Sort Attempt " .. attemptNum .. ")")
			self:ProtectAllBindTexts() -- Re-apply protection
		end

		if attemptNum == maxAttempts then
			debug(">>> Post-sort update sequence COMPLETE <<<")
			module.isSorting = false
			if CONFIG.USE_FUNCTION_REPLACEMENT then
				debug("Restoring functions after completing post-sort sequence.")
				self:RestoreAllFunctions() -- Final restore
			end
		else
			-- Schedule next attempt
			local nextDelay = CONFIG.UPDATE_ATTEMPT_INTERVAL * CONFIG.SORT_UPDATE_INTERVAL_MULTIPLIER
			local timer = C_Timer.After(nextDelay, function()
				processAttempt(attemptNum + 1, maxAttempts)
			end)
			module.updateTimers[1] = timer -- Replace timer instead of adding
		end
	end

	-- Start with first attempt after initial delay
	module.updateTimers = {}
	module.updateTimers[1] = C_Timer.After(CONFIG.INITIAL_SORT_DELAY, function()
		debug(">>> Post-Sort Initial Timer Fired (" .. CONFIG.INITIAL_SORT_DELAY .. "s) <<<")
		processAttempt(1, CONFIG.MAX_SORT_UPDATE_ATTEMPTS)
	end)
end

-- ==========================================
-- Setup Events (Now triggers SetupHooks)
-- ==========================================
function module:SetupEvents()
	debug("Setting up event handlers...")
	-- Handle profile changes
	addon:RegisterForEvent("PROFILE_CHANGED", function()
		debug("Profile changed - updating bind text settings")
		simpleDebugEnabled = nil -- Reset debug cache check
		C_Timer.After(0.5, function()
			module.isSorting = false
			if self:IsModuleEnabled() then
				debug("Profile changed, scheduling update sequence.")
				self:ScheduleUpdateSequence()
			else
				debug("Profile changed, module disabled, resetting.")
				self:ResetAll()
			end
		end)
	end)
	-- Handle combat events
	addon:RegisterForEvent("COMBAT_STARTED", function()
		self:OptimizeForCombat()
	end)
	addon:RegisterForEvent("COMBAT_ENDED", function()
		module.combatSuspended = false
		if addon:IsAnyBagVisible() then
			self:ScheduleUpdateSequence()
		end
	end)
	-- Handle bag closure for memory management
	addon:RegisterForEvent("BAG_CLOSED", function()
		-- Delay cleanup to ensure all bags are truly closed
		C_Timer.After(1, function()
			if not addon:IsAnyBagVisible() then
				-- Clear colored slots cache to prevent memory leaks
				wipe(module.coloredSlots)
				-- Restore any function replacements
				if CONFIG.USE_FUNCTION_REPLACEMENT then
					self:RestoreAllFunctions()
				end
			end
		end)
	end)
	-- *** SETUP HOOKS HERE ***
	addon:RegisterForEvent("BAGS_INITIALIZED", function()
		debug("BAGS_INITIALIZED received.")
		-- Attempt to setup hooks now that bags should be ready
		if not module.hooksSet then
			debug("BAGS_INITIALIZED -> Calling SetupHooks.")
			self:SetupHooks()
		else
			debug("BAGS_INITIALIZED -> Hooks already set, scheduling update.")
		end

		module.isSorting = false
		self:ScheduleUpdateSequence() -- Schedule an update regardless
	end)
	-- Register handlers for various inventory update events
	local events = {
		["BAG_UPDATE"] = function(bagID)
			if module.isSorting or not self:IsRegularBag(bagID) then return end

			module.lastBagActivity = GetTime()
			self:ScheduleUpdateSequence()
		end,
		["BAG_UPDATE_DELAYED"] = function()
			if module.isSorting then return end

			module.lastBagActivity = GetTime()
			self:ScheduleUpdateSequence()
		end,
		["ITEM_LOCK_CHANGED"] = function(bagID, slotID, isLocked)
			if module.isSorting or not self:IsRegularBag(bagID) then return end

			module.lastBagActivity = GetTime()
			if not isLocked and not CursorHasItem() then
				debug("ITEM_LOCK_CHANGED detected (item unlocked/placed) for " ..
					bagID .. "_" .. slotID .. " - scheduling update sequence")
				self:ScheduleUpdateSequence()
			end
		end,
		["ITEM_PUSH"] = function(bagID, slotID, itemID)
			if module.isSorting or not self:IsRegularBag(bagID) then return end

			debug("ITEM_PUSH detected - scheduling update sequence")
			module.lastBagActivity = GetTime()
			self:ScheduleUpdateSequence()
		end,
		["INVENTORY_SEARCH_UPDATE"] = function()
			if module.isSorting then return end

			debug("INVENTORY_SEARCH_UPDATE - scheduling update sequence")
			module.lastBagActivity = GetTime()
			self:ScheduleUpdateSequence()
		end,
	}
	for event, handler in pairs(events) do
		addon:RegisterForEvent(event, function(...)
			if self:IsModuleEnabled() then handler(...) end
		end)
	end

	-- Register with the addon's core update system if it has one
	addon:RegisterElementUpdate("bindText", function()
		if module.isSorting then
			debug("Addon core update 'bindText' received during sort - skipping.")
			return
		end

		debug("Addon core update 'bindText' received - scheduling update sequence")
		module.lastBagActivity = GetTime()
		self:ScheduleUpdateSequence()
	end)
	debug("Event handlers registered for bindText module")
end

-- ==========================================
-- CustomizeBindText
-- ==========================================
function module:CustomizeBindText(bindText, slot, bagID, slotID, itemID)
	if not bindText or not bindText.SetTextColor then return end

	local text = bindText:GetText() or ""
	if text == "" then return end

	local bindTextSettings = E.db.bagCustomizer.bindTextSettings
	debug(string.format("CustomizeBindText [%s_%s]: itemID=%s, text='%s'. Current applyToPoorQuality setting = %s",
		tostring(bagID), tostring(slotID), tostring(itemID), text,
		tostring(bindTextSettings and bindTextSettings.applyToPoorQuality)))
	local itemRarity = slot.rarity or 0
	local isPoorQuality = (itemRarity == 0)
	if isPoorQuality then
		debug(string.format(
			"CustomizeBindText [%s_%s]: Item is POOR quality (rarity 0). Checking setting applyToPoorQuality = %s",
			tostring(bagID), tostring(slotID), tostring(bindTextSettings.applyToPoorQuality)))
	end

	local skipPoorQuality = isPoorQuality and not bindTextSettings.applyToPoorQuality
	if isPoorQuality then
		debug(string.format("CustomizeBindText [%s_%s]: POOR item - Calculated skipPoorQuality = %s",
			tostring(bagID), tostring(slotID), tostring(skipPoorQuality)))
	end

	local shouldCustomize = false
	if text:find("BoE") and bindTextSettings.applyToBindOnEquip and not skipPoorQuality then
		shouldCustomize = true
	elseif text:find("WuE") and bindTextSettings.applyToWarbound and not skipPoorQuality then
		shouldCustomize = true
	elseif text:find("BoU") and bindTextSettings.applyToBindOnUse and not skipPoorQuality then -- Assuming BoU exists based on code
		shouldCustomize = true
	end

	if isPoorQuality then
		debug(string.format("CustomizeBindText [%s_%s]: POOR item - Final shouldCustomize = %s",
			tostring(bagID), tostring(slotID), tostring(shouldCustomize)))
	end

	local key = bagID .. "_" .. slotID
	local wasPreviouslyColored = module.coloredSlots[key] and module.coloredSlots[key].bindText == bindText
	if shouldCustomize then
		if isPoorQuality then
			debug(string.format("CustomizeBindText [%s_%s]: POOR item - Applying custom color/brightness.",
				tostring(bagID), tostring(slotID)))
		end

		local r, g, b, a = 1, 1, 1, 1
		if bindTextSettings.useCustomColor then
			r, g, b = bindTextSettings.color.r, bindTextSettings.color.g, bindTextSettings.color.b
		else
			-- Use ElvUI's function to get the *actual* quality color, even for poor
			local qr, qg, qb = B:GetItemQualityColor(itemRarity)
			local brightness = (bindTextSettings.brightness or 150) / 100
			r = math.min(1, qr * brightness)
			g = math.min(1, qg * brightness)
			b = math.min(1, qb * brightness)
		end

		bindText:SetTextColor(r, g, b, a)
		-- Update tracking
		if not wasPreviouslyColored or module.coloredSlots[key].color[1] ~= r or module.coloredSlots[key].color[2] ~= g or module.coloredSlots[key].color[3] ~= b then
			module.coloredSlots[key] = {
				bindText = bindText, rarity = itemRarity, bindType = text, itemID = itemID, color = { r, g, b, a },
			}
		end
	else
		-- Condition is FALSE now. Check if we NEED to reset the color.
		if wasPreviouslyColored then
			debug(string.format(
				"CustomizeBindText [%s_%s]: Item no longer meets criteria (shouldCustomize=false), but WAS colored. Resetting color.",
				tostring(bagID), tostring(slotID)))
			-- Reset to default ElvUI quality color
			local qr, qg, qb = B:GetItemQualityColor(itemRarity)
			bindText:SetTextColor(qr, qg, qb) -- Apply the default quality color
			-- Remove from tracked colored slots
			module.coloredSlots[key] = nil
		else
			-- Item shouldn't be customized, and wasn't tracked as colored by us, do nothing.
			if isPoorQuality then
				debug(string.format(
					"CustomizeBindText [%s_%s]: POOR item - Not applying color (shouldCustomize is false) and wasn't previously colored by us. Returning.",
					tostring(bagID), tostring(slotID)))
			end
		end

		-- No return here, let the function end naturally after potential reset
	end
end

-- ==========================================
-- SetupContinuousMonitoring
-- ==========================================
function module:SetupContinuousMonitoring()
	if self.colorMonitor then return end -- Already set up

	self.colorMonitor = CreateFrame("Frame")
	self.colorMonitor.elapsed = 0
	self.colorMonitor:SetScript("OnUpdate", function(_, elapsed)
		if not module:IsModuleEnabled() or addon.inCombat or module.isSorting then return end -- Skip if disabled, in combat, or sorting

		self.colorMonitor.elapsed = self.colorMonitor.elapsed + elapsed
		if self.colorMonitor.elapsed < CONFIG.FLICKER_CHECK_INTERVAL then return end

		self.colorMonitor.elapsed = 0
		local timeSinceActivity = GetTime() - module.lastBagActivity
		if timeSinceActivity < CONFIG.ACTIVITY_MONITOR_DURATION then
			self:MonitorForColorFlicker()
		end
	end)
	debug("Set up continuous color monitoring")
end

-- ==========================================
-- MonitorForColorFlicker
-- ==========================================
function module:MonitorForColorFlicker()
	if not self:IsModuleEnabled() or not addon:IsAnyBagVisible() then return end

	local success, err = pcall(function()
		local function CheckBagFrame(bagFrame)
			if bagFrame and bagFrame:IsShown() and bagFrame.Bags then
				for _, bagID in ipairs(bagFrame.BagIDs) do
					-- Only check regular bags
					if self:IsRegularBag(bagID) and bagFrame.Bags[bagID] then
						local numSlots = B:GetContainerNumSlots(bagID)
						for slotID = 1, numSlots do
							local slot = bagFrame.Bags[bagID][slotID]
							if slot and slot:IsShown() and slot.hasItem then
								self:CheckAndFixBindTextColor(slot, bagID, slotID)
							end
						end
					end
				end
			end
		end

		if B.BagFrames then
			for _, bagFrame in pairs(B.BagFrames) do CheckBagFrame(bagFrame) end
		end
	end)
	if not success then debug("Error in MonitorForColorFlicker: " .. tostring(err)) end
end

-- ==========================================
-- CheckAndFixBindTextColor
-- ==========================================
function module:CheckAndFixBindTextColor(slot, bagID, slotID)
	local bindText = slot.bindType
	if not bindText or not bindText.GetText or not bindText:GetText() or bindText:GetText() == "" then return end

	local key = bagID .. "_" .. slotID
	local data = module.coloredSlots[key]
	if not data or not data.color then return end

	local r, g, b = bindText:GetTextColor()
	local targetColor = data.color
	local function colorsMatch(c1, c2) return math.abs(c1 - c2) < 0.01 end

	if not (colorsMatch(r, targetColor[1]) and colorsMatch(g, targetColor[2]) and colorsMatch(b, targetColor[3])) then
		bindText:SetTextColor(unpack(targetColor))
	end
end

-- ==========================================
-- ScheduleUpdateSequence
-- ==========================================
function module:ScheduleUpdateSequence()
	if module.isSorting then
		debug("Skipping ScheduleUpdateSequence because sorting is active."); return
	end

	if self.updateSequenceScheduled then
		debug("Skipping ScheduleUpdateSequence because one is already scheduled/running."); return
	end

	debug("Scheduling standard update sequence")
	self.updateSequenceScheduled = true
	if CONFIG.USE_FUNCTION_REPLACEMENT then
		debug("Restoring functions before standard sequence"); self:RestoreAllFunctions()
	end

	-- Cancel any existing timers
	for _, timer in ipairs(module.updateTimers) do
		if timer.Cancel then timer:Cancel() end
	end

	self:SafeWipe(module.updateTimers)
	-- Create recursive update function
	local function processAttempt(attemptNum, maxAttempts)
		if module.isSorting then
			debug("Standard update attempt " .. attemptNum .. " skipped: Sorting started during delay.")
			if attemptNum == maxAttempts then self.updateSequenceScheduled = false end

			return
		end

		if not self:IsModuleEnabled() then
			debug("Standard update attempt " .. attemptNum .. " skipped: Module disabled during delay.")
			if attemptNum == maxAttempts then self.updateSequenceScheduled = false end

			return
		end

		debug("Standard update attempt " .. attemptNum .. "/" .. maxAttempts)
		self:UpdateAll()
		if CONFIG.USE_FUNCTION_REPLACEMENT and attemptNum <= maxAttempts / 2 then
			debug("Protecting bind texts (Standard Attempt " .. attemptNum .. ")")
			self:ProtectAllBindTexts()
		end

		if attemptNum == maxAttempts then
			debug("Standard update sequence complete")
			if CONFIG.USE_FUNCTION_REPLACEMENT then
				debug("Restoring functions after standard sequence.")
				self:RestoreAllFunctions()
			end

			module.activeBagID = nil
			self.updateSequenceScheduled = false
		else
			-- Schedule next attempt
			local timer = C_Timer.After(CONFIG.UPDATE_ATTEMPT_INTERVAL, function()
				processAttempt(attemptNum + 1, maxAttempts)
			end)
			module.updateTimers[1] = timer -- Replace timer instead of adding
		end
	end

	-- Start with first attempt
	module.updateTimers[1] = C_Timer.After(0.01, function()
		processAttempt(1, CONFIG.MAX_MOVEMENT_UPDATE_ATTEMPTS)
	end)
end

-- ==========================================
-- QueueSlotUpdate
-- ==========================================
function module:QueueSlotUpdate(frame, bagID, slotID, slotFrame)
	if module.isSorting or not self:IsRegularBag(bagID) then return end

	if not bagID or not slotID then return end

	local key = bagID .. "_" .. slotID
	module.pendingUpdates[key] = { frame = frame, bagID = bagID, slotID = slotID, slotFrame = slotFrame, time = GetTime() }
	if not module.activeColorApplier then
		module.activeColorApplier = true
		C_Timer.After(0.01, function() self:ProcessPendingUpdates() end)
		C_Timer.After(0.1, function() self:ProcessPendingUpdates() end)
		C_Timer.After(0.3, function()
			self:ProcessPendingUpdates(); module.activeColorApplier = false
		end)
	end
end

-- ==========================================
-- ProcessPendingUpdates
-- ==========================================
function module:ProcessPendingUpdates()
	if module.isSorting then
		if next(module.pendingUpdates) then
			debug("Clearing pending updates queue due to active sort.")
			self:SafeWipe(module.pendingUpdates)
		end

		module.activeColorApplier = false
		return
	end

	if not next(module.pendingUpdates) then return end

	local success, err = pcall(function()
		local currentTime = GetTime()
		local updatesToProcess = {}
		for key in pairs(module.pendingUpdates) do table.insert(updatesToProcess, key) end

		for _, key in ipairs(updatesToProcess) do
			local updateInfo = module.pendingUpdates[key]
			if updateInfo then
				self:ProcessSpecificSlot(updateInfo.frame, updateInfo.bagID, updateInfo.slotID, updateInfo.slotFrame)
				module.pendingUpdates[key] = nil
				-- Clean up old updates
				if currentTime - updateInfo.time > CONFIG.MAX_PENDING_UPDATE_AGE then
					module.pendingUpdates[key] = nil
				end
			end
		end
	end)
	if not success then debug("Error in ProcessPendingUpdates: " .. tostring(err)) end
end

-- ==========================================
-- ProcessSpecificSlot
-- ==========================================
function module:ProcessSpecificSlot(frame, bagID, slotID, slotFrame)
	if not self:IsRegularBag(bagID) then return end

	local success, err = pcall(function()
		local slot = slotFrame
		if not slot then
			if frame and frame.Bags and frame.Bags[bagID] then slot = frame.Bags[bagID][slotID] end
		end

		if not slot and bagID ~= nil and slotID ~= nil then
			if B.BagFrames then
				for _, bagFrame in pairs(B.BagFrames) do
					if bagFrame and bagFrame.Bags and bagFrame.Bags[bagID] then
						slot = bagFrame.Bags[bagID][slotID]
						if slot then break end
					end
				end
			end
		end

		if not slot or not slot:IsShown() then return end

		local key = bagID .. "_" .. slotID
		if not slot.hasItem then
			if module.coloredSlots[key] then module.coloredSlots[key] = nil end

			return
		end

		local itemID = self:GetItemIDFromBagSlot(bagID, slotID)
		if not itemID then
			if module.coloredSlots[key] then module.coloredSlots[key] = nil end

			return
		end

		local oldData = module.coloredSlots[key]
		if oldData and oldData.itemID ~= itemID then module.coloredSlots[key] = nil end

		self:FindAndProcessBindTexts(slot, bagID, slotID, itemID)
	end)
	if not success then debug("Error in ProcessSpecificSlot for " .. bagID .. "_" .. slotID .. ": " .. tostring(err)) end
end

-- ==========================================
-- FindAndProcessBindTexts
-- ==========================================
function module:FindAndProcessBindTexts(slot, bagID, slotID, itemID)
	local bindTextsFound = {}
	local processedRegions = {}
	local function AddBindText(region)
		if region and region:IsObjectType("FontString") and not processedRegions[region] then
			local text = region:GetText() or ""
			if text:find("BoE") or text:find("WuE") or text:find("BoU") then
				table.insert(bindTextsFound, region)
				processedRegions[region] = true
			end
		end
	end

	if slot.bindType then AddBindText(slot.bindType) end

	if slot.BottomInfo then
		local regions = self:SafeGetRegions(slot.BottomInfo)
		for _, region in ipairs(regions) do
			AddBindText(region)
		end
	end

	if #bindTextsFound > 0 then
		for _, bindText in ipairs(bindTextsFound) do self:CustomizeBindText(bindText, slot, bagID, slotID, itemID) end
	end
end

-- ==========================================
-- ProtectAllBindTexts
-- ==========================================
function module:ProtectAllBindTexts()
	if not CONFIG.USE_FUNCTION_REPLACEMENT then return end

	local success, err = pcall(function()
		self:RestoreAllFunctions()
		local protectedCount = 0
		local function ProtectBagFrame(bagFrame)
			if not bagFrame or not bagFrame:IsShown() or not bagFrame.Bags then return end

			for _, bagID in ipairs(bagFrame.BagIDs or {}) do
				-- Only process regular bags
				if self:IsRegularBag(bagID) and bagFrame.Bags[bagID] then
					local numSlots = self:SafeGetContainerNumSlots(bagID)
					for slotID = 1, numSlots do
						local slot = bagFrame.Bags[bagID] and bagFrame.Bags[bagID][slotID]
						if slot and slot:IsShown() and slot.hasItem then
							if self:ProtectBindTextsInSlot(slot, bagID, slotID) then
								protectedCount = protectedCount + 1
							end
						end
					end
				end
			end
		end

		if B.BagFrames then
			for _, bagFrame in pairs(B.BagFrames) do ProtectBagFrame(bagFrame) end
		end
	end)
	if not success then debug("Error in ProtectAllBindTexts: " .. tostring(err)) end
end

-- ==========================================
-- ProtectBindTextsInSlot
-- ==========================================
function module:ProtectBindTextsInSlot(slot, bagID, slotID)
	if not CONFIG.USE_FUNCTION_REPLACEMENT then return false end

	local protected = false
	local bindTextsToProtect = {}
	local processedRegions = {}
	local function AddBindTextToProtect(region)
		if region and region:IsObjectType("FontString") and not processedRegions[region] then
			local text = region:GetText() or ""
			if text:find("BoE") or text:find("WuE") or text:find("BoU") then
				table.insert(bindTextsToProtect, region)
				processedRegions[region] = true
			end
		end
	end

	if slot.bindType then AddBindTextToProtect(slot.bindType) end

	if slot.BottomInfo then
		local regions = self:SafeGetRegions(slot.BottomInfo)
		for _, region in ipairs(regions) do
			AddBindTextToProtect(region)
		end
	end

	for _, bindText in ipairs(bindTextsToProtect) do
		if self:ProtectBindTextWithFunctionReplacement(bindText, slot, bagID, slotID) then protected = true end
	end

	return protected
end

-- ==========================================
-- ProtectBindTextWithFunctionReplacement
-- ==========================================
function module:ProtectBindTextWithFunctionReplacement(bindText, slot, bagID, slotID)
	if not CONFIG.USE_FUNCTION_REPLACEMENT then return false end

	if not bindText or not bindText.SetTextColor or bindText._BCZ_protected then return false end

	local bindTextSettings = E.db.bagCustomizer.bindTextSettings
	local text = bindText:GetText() or ""
	local itemRarity = slot.rarity or 0
	local isPoorQuality = (itemRarity == 0)
	local skipPoorQuality = isPoorQuality and not bindTextSettings.applyToPoorQuality
	local bindTypeCategory = nil
	if text:find("BoE") and bindTextSettings.applyToBindOnEquip and not skipPoorQuality then
		bindTypeCategory = "BoE"
	elseif text:find("WuE") and bindTextSettings.applyToWarbound and not skipPoorQuality then
		bindTypeCategory = "WuE"
	elseif text:find("BoU") and bindTextSettings.applyToBindOnUse and not skipPoorQuality then
		bindTypeCategory = "BoU"
	end

	if not bindTypeCategory then return false end

	local r, g, b, a = 1, 1, 1, 1
	if bindTextSettings.useCustomColor then
		r, g, b = bindTextSettings.color.r, bindTextSettings.color.g, bindTextSettings.color.b
	else
		local qr, qg, qb = B:GetItemQualityColor(itemRarity)
		local brightness = (bindTextSettings.brightness or 150) / 100
		r = math.min(1, qr * brightness)
		g = math.min(1, qg * brightness)
		b = math.min(1, qb * brightness)
	end

	if not module.replacedFunctions[bindText] then module.replacedFunctions[bindText] = bindText.SetTextColor end

	bindText.SetTextColor = function(self, _, _, _, _) return module.replacedFunctions[bindText](self, r, g, b, a) end
	bindText._BCZ_protected = true
	bindText:SetTextColor(r, g, b, a)
	local key = bagID .. "_" .. slotID
	local itemID = self:GetItemIDFromBagSlot(bagID, slotID)
	module.coloredSlots[key] = {
		bindText = bindText,
		rarity = itemRarity,
		bindType = text,
		itemID = itemID,
		color = { r, g, b, a },
	}
	return true
end

-- ==========================================
-- RestoreAllFunctions
-- ==========================================
function module:RestoreAllFunctions()
	if not CONFIG.USE_FUNCTION_REPLACEMENT then return end

	local success, err = pcall(function()
		local count = 0
		for bindText, originalFunc in pairs(module.replacedFunctions) do
			if bindText and bindText.SetTextColor and bindText._BCZ_protected and originalFunc then
				bindText.SetTextColor = originalFunc
				bindText._BCZ_protected = nil
				count = count + 1
			end
		end

		if count > 0 then debug("Restored " .. count .. " original SetTextColor functions.") end

		self:SafeWipe(module.replacedFunctions)
	end)
	if not success then debug("Error in RestoreAllFunctions: " .. tostring(err)) end
end

-- ==========================================
-- GetItemIDFromBagSlot
-- ==========================================
function module:GetItemIDFromBagSlot(bagID, slotID)
	local success, itemID
	if not bagID or not slotID or bagID < BACKPACK_CONTAINER or slotID < 1 then return nil end

	if isRetail then
		success, itemID = pcall(C_Container.GetContainerItemID, bagID, slotID)
	elseif _G.GetContainerItemID then
		success, itemID = pcall(GetContainerItemID, bagID, slotID)
	else
		success = false
	end

	if success and itemID then return itemID else return nil end
end

-- ==========================================
-- UpdateAll
-- ==========================================
function module:UpdateAll()
	if addon.inCombat and not addon:IsAnyBagVisible() then return end

	if module.combatSuspended and not addon:IsAnyBagVisible() then return end

	local processedSlots = 0
	local success, err = pcall(function()
		local function UpdateContainerFrame(containerFrame)
			if not containerFrame or not containerFrame:IsShown() or not containerFrame.Bags then return end

			for _, bagID in ipairs(containerFrame.BagIDs or {}) do
				-- Only process regular bags
				if self:IsRegularBag(bagID) and containerFrame.Bags[bagID] then
					local numSlots = self:SafeGetContainerNumSlots(bagID)
					for slotID = 1, numSlots do
						if slotID > 0 then -- Extra validation
							local slot = containerFrame.Bags[bagID][slotID]
							if slot and slot:IsShown() then
								self:ProcessSpecificSlot(containerFrame, bagID, slotID, slot)
								processedSlots = processedSlots + 1
							end
						end
					end
				end
			end
		end

		if B.BagFrames then
			for _, bagFrame in pairs(B.BagFrames) do UpdateContainerFrame(bagFrame) end
		end
	end)
	if not success then debug("Error during UpdateAll execution: " .. tostring(err)) end
end

-- ==========================================
-- ResetAll
-- ==========================================
function module:ResetAll()
	debug("Resetting all bind text customizations")
	local success, err = pcall(function()
		module.isSorting = false -- Ensure sorting flag is off
		-- Restore any replaced functions FIRST
		if CONFIG.USE_FUNCTION_REPLACEMENT then
			self:RestoreAllFunctions()
		end

		local resetCount = 0
		local slotsToUpdate = {} -- Store {bagFrame, bagID, slotID}
		-- Identify slots that might need updating (previously colored or currently visible)
		-- Option 1: Use stored keys (might miss slots if cache cleared)
		--[[
        for key, data in pairs(module.coloredSlots) do
            local bagID, slotID = strsplit("_", key)
            bagID = tonumber(bagID)
            slotID = tonumber(slotID)
            if bagID and slotID then
                -- We still need the frame context... this is tricky
            end
        end
        --]]

		-- Option 2: Iterate through currently visible slots (Safer)
		if B.BagFrames then
			for _, bagFrame in pairs(B.BagFrames) do
				if bagFrame and bagFrame:IsShown() and bagFrame.Bags then -- Check visibility
					for _, bagID in ipairs(bagFrame.BagIDs or {}) do
						if self:IsRegularBag(bagID) and bagFrame.Bags[bagID] then
							local numSlots = self:SafeGetContainerNumSlots(bagID)
							for slotID = 1, numSlots do
								local slot = bagFrame.Bags[bagID][slotID]
								-- Check if the slot exists and has item text regions ElvUI might manage
								if slot and slot:IsShown() and (slot.bindType or slot.BottomInfo) then
									-- Store info needed for B:UpdateSlot
									table.insert(slotsToUpdate, { frame = bagFrame, bagID = bagID, slotID = slotID })
									resetCount = resetCount + 1
									-- Do NOT set color here anymore
									--[[
                                    if slot.bindType and slot.bindType.SetTextColor then
                                        slot.bindType:SetTextColor(1, 1, 1, 1) -- REMOVED
                                    end
                                    if slot.BottomInfo then
                                        -- Iterate regions and set to white -- REMOVED
                                    end
                                    --]]
								end
							end
						end
					end
				end
			end
		end

		-- Wipe internal caches AFTER identifying slots but BEFORE triggering updates
		self:SafeWipe(module.coloredSlots)
		self:SafeWipe(module.pendingUpdates)
		self:SafeWipe(module.updateTimers)
		self:SafeWipe(module.replacedFunctions) -- Ensure this is wiped if not done elsewhere
		module.lastBagActivity = 0
		module.activeColorApplier = false
		module.updateSequenceScheduled = false
		module.isSorting = false -- Re-assert
		-- Now trigger ElvUI's update for the affected slots
		if B and B.UpdateSlot then
			debug("Attempting to reset colors via B:UpdateSlot for " .. #slotsToUpdate .. " slots.")
			for _, updateInfo in ipairs(slotsToUpdate) do
				-- Add pcall for safety around external calls
				local updateSuccess, updateErr = pcall(B.UpdateSlot, B, updateInfo.frame, updateInfo.bagID, updateInfo.slotID)
				if not updateSuccess then
					debug("Error calling B:UpdateSlot for " ..
						updateInfo.bagID .. "_" .. updateInfo.slotID .. ": " .. tostring(updateErr))
				end
			end
		else
			debug("Cannot find B:UpdateSlot to reset colors properly. Layout may appear incorrect until next bag update.")
			-- Fallback: Trigger a broader layout update if UpdateSlot isn't available (less ideal)
			if B and B.Layout then B:Layout() end
		end

		addon:TriggerEvent("BINDTEXT_RESET_COMPLETE")
	end)
	if not success then
		debug("Error during ResetAll execution: " .. tostring(err))
	end
end

-- ==========================================
-- Revert
-- ==========================================
function module:Revert()
	debug("Reverting bind text customizations (calling ResetAll)")
	self:ResetAll()
	addon:TriggerEvent("BINDTEXT_REVERT_COMPLETE")
end

-- ==========================================
-- OptimizeForCombat
-- ==========================================
function module:OptimizeForCombat()
	if next(module.pendingUpdates) then wipe(module.pendingUpdates) end

	module.activeColorApplier = false
	-- Cancel any pending update timers
	for _, timer in ipairs(module.updateTimers) do
		if timer.Cancel then timer:Cancel() end
	end

	self:SafeWipe(module.updateTimers)
	-- Suspend updates during combat when bags aren't visible
	module.combatSuspended = not addon:IsAnyBagVisible()
end

-- ==========================================
-- UpdateLayout
-- ==========================================
function module:UpdateLayout()
	debug("Bind Text UpdateLayout triggered")
	simpleDebugEnabled = nil -- Recache debug status on layout update (potential profile change)
	if not self:IsModuleEnabled() then
		debug("Module disabled, calling ResetAll.")
		self:ResetAll()
	else
		debug("Module enabled, scheduling update sequence.")
		module.isSorting = false
		self:ScheduleUpdateSequence()
	end
end

-- ==========================================
-- UI Options helpers
-- ==========================================
function module:EnsureSettingsExist()
	if not E.db.bagCustomizer then
		E.db.bagCustomizer = {}
	end

	if not E.db.bagCustomizer.bindTextSettings then
		E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
	end
end

function module:GetSetting(property, defaultValue)
	self:EnsureSettingsExist()
	if E.db.bagCustomizer.bindTextSettings[property] ~= nil then
		return E.db.bagCustomizer.bindTextSettings[property]
	end

	return defaultValue ~= nil and defaultValue or addon.defaults.bindTextSettings[property]
end

-- ==========================================
-- Cleanup
-- ==========================================
function module:Cleanup()
	debug("Cleaning up bindText module...")
	if self.colorMonitor then
		self.colorMonitor:SetScript("OnUpdate", nil)
		self.colorMonitor = nil
		debug("Stopped color monitor.")
	end

	if self.cursorTracker then
		self.cursorTracker:SetScript("OnUpdate", nil)
		self.cursorTracker = nil
		debug("Stopped cursor tracker.")
	end

	self:ResetAll()
	addon:TriggerEvent("BINDTEXT_CLEANUP_COMPLETE")
	debug("bindText module cleanup complete.")
end

-- ==========================================
-- Return the module table for external use
-- ==========================================
return module
