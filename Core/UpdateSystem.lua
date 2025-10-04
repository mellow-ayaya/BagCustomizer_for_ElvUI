-- ElvUI Bag Customizer - Update System (Targeted Fix - Disabled Currency Events)
--
-- This file handles all update logic, event handling, and customization rendering.
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags")
local addon = E:GetModule("BagCustomizer")
-- Initialize the UpdateSystem module within the addon
addon.elements.updateSystem = {}
local UpdateSystem = addon.elements.updateSystem
-- Debug function optimization
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][UpdateSystem]:|r "
-- Module-specific debug function
local function debug(message)
	if not E.db or not E.db.bagCustomizer then return end

	if not E.db.bagCustomizer.debug then return end

	if not E.db.bagCustomizer.updateSystem or not E.db.bagCustomizer.updateSystem.debug then return end

	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(message))
end

-- Create lookup table for first update reasons
local firstUpdateReasons = {
	["PLAYER_ENTERING_WORLD event"] = true,
	["WarbandBankFirstOpen"] = true,
	["FullUpdate"] = true,
	["Initial update"] = true,
}
-- UNIFIED TIMER SYSTEM
local unifiedUpdateTimer = nil
local pendingUpdates = {}
local lastUpdateTime = 0
local UPDATE_DELAY = 0.4 -- Single delay for all updates (increased for 11.2 stability)
-- Unified update handler
local function ProcessUnifiedUpdate()
	if not addon or not E.db or not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then
		unifiedUpdateTimer = nil
		pendingUpdates = {}
		return
	end

	debug("Processing unified update with " .. #pendingUpdates .. " pending reasons")
	-- Determine if this should be an immediate update
	local isImmediate = false
	local isFirstUpdate = false
	for _, updateData in ipairs(pendingUpdates) do
		if updateData.immediate then
			isImmediate = true
		end

		if firstUpdateReasons[updateData.reason] or (updateData.reason and (updateData.reason:find("first") or updateData.reason:find("Initial"))) then
			isFirstUpdate = true
		end
	end

	-- Execute the actual update
	UpdateSystem:ExecuteUpdate("Unified: " .. (#pendingUpdates > 0 and pendingUpdates[1].reason or "unknown"), isImmediate,
		isFirstUpdate)
	-- Clear state
	unifiedUpdateTimer = nil
	pendingUpdates = {}
	lastUpdateTime = GetTime()
end

-- Queue an update with the unified system
local function QueueUpdate(reason, immediate)
	local now = GetTime()
	-- Skip if we just updated recently and this isn't urgent
	if not immediate and (now - lastUpdateTime) < 0.1 then
		debug("Skipping update due to recent update: " .. (reason or "unknown"))
		return
	end

	-- Add to pending updates
	table.insert(pendingUpdates, {
		reason = reason or "unknown",
		immediate = immediate or false,
		timestamp = now,
	})
	-- Cancel existing timer
	if unifiedUpdateTimer then
		unifiedUpdateTimer:Cancel()
	end

	-- Create new timer
	local delay = immediate and 0.1 or UPDATE_DELAY
	unifiedUpdateTimer = C_Timer.NewTimer(delay, ProcessUnifiedUpdate)
	debug("Queued update: " .. (reason or "unknown") .. (immediate and " (immediate)" or ""))
end

-- Make sure the module is properly initialized early
function UpdateSystem:OnInitialize()
	debug("Early initialization of UpdateSystem module")
	self.lastUpdateTimes = {}
	-- Initialize event throttling timers
	self.lastLayoutTrigger = 0
	self.lastBagUpdateEvent = 0
	self.lastCooldownUpdate = 0
	self.lastCurrencyUpdate = 0
	self.lastCurrencyDimensionsUpdate = 0
	self.lastItemLockChange = 0
	-- Detect WoW version for optimal timing
	local version = select(4, GetBuildInfo())
	if version >= 110200 then
		UPDATE_DELAY = 0.4 -- Longer delay for 11.2+
		debug("Detected WoW 11.2+ - using extended delays")
	else
		UPDATE_DELAY = 0.2 -- Original delay for older versions
		debug("Detected WoW <11.2 - using standard delays")
	end
end

-- COMBAT OPTIMIZATION FUNCTIONS
function UpdateSystem:OptimizeForCombat()
	addon.inCombat = true
	debug("Entered combat - optimizing performance")
	-- Cancel any pending updates
	if unifiedUpdateTimer then
		unifiedUpdateTimer:Cancel()
		unifiedUpdateTimer = nil
		pendingUpdates = {}
	end

	-- Disable texture updates during combat unless bags are visible
	if not addon:IsAnyBagVisible() then
		local MainTextures = addon:GetCachedModule("mainTextures")
		if MainTextures then
			MainTextures.skipUpdatesInCombat = true
		end
	end

	-- Notify BindText module of combat state
	local bindText = addon:GetCachedModule("bindText")
	if bindText and bindText.OptimizeForCombat then
		bindText:OptimizeForCombat()
	end

	-- Unregister non-critical events during combat
	addon:UnregisterEvent("CURSOR_CHANGED")
	addon:UnregisterEvent("ITEM_PUSH")
	addon:UnregisterEvent("BAG_UPDATE_DELAYED")
	self.combatSuspended = true
	addon:TriggerEvent("COMBAT_STARTED")
end

function UpdateSystem:RestoreFromCombat()
	addon.inCombat = false
	debug("Exited combat - restoring normal functionality")
	-- Register all events in one batch
	self:RegisterCombatEvents()
	self.combatSuspended = false
	-- Update if bags are visible after a delay to ensure UI is stable
	QueueUpdate("Combat ended with bags open", false)
	-- Re-enable texture updates
	local MainTextures = addon:GetCachedModule("mainTextures")
	if MainTextures then
		MainTextures.skipUpdatesInCombat = false
	end

	-- Force a cleanup to recover memory
	C_Timer.After(0.5, function()
		local ResourceManager = addon:GetCachedModule("resourceManager")
		if ResourceManager and ResourceManager.CleanupMemory then
			ResourceManager:CleanupMemory(false)
		else
			addon:CleanupMemory(false)
		end
	end)
	addon:TriggerEvent("COMBAT_ENDED")
end

function UpdateSystem:UpdateItemModules(reason)
	debug("UpdateItemModules called: " .. reason)
	-- Update inventory slots
	local inventorySlots = addon:GetCachedModule("inventorySlots")
	if inventorySlots and inventorySlots.UpdateAll then
		inventorySlots:UpdateAll()
	end

	-- Update bind text
	local bindText = addon:GetCachedModule("bindText")
	if bindText and bindText.ScheduleUpdateSequence then
		bindText:ScheduleUpdateSequence()
	end

	-- Search bar - if items are filtered/highlighted during searches
	local searchBar = addon:GetCachedModule("searchBar")
	if searchBar and searchBar.UpdateHighlights then
		searchBar:UpdateHighlights()
	end

	-- Resource manager - cleanup textures when items change to prevent memory leaks
	local resourceManager = addon:GetCachedModule("resourceManager")
	if resourceManager and resourceManager.CleanupSlotTextures then
		resourceManager:CleanupSlotTextures()
	end

	debug("Item modules updated: " .. reason)
end

-- Register combat events with unified timing
function UpdateSystem:RegisterCombatEvents()
	-- CURSOR_CHANGED with selective updates - no frame border rebuilds
	addon:RegisterEvent("CURSOR_CHANGED", function()
		if addon.inCombat then return end

		if CursorHasItem() then
			-- An item is being moved
			if not self.cursorChangingItem then
				self.cursorChangingItem = true
				-- Only update item modules, NOT frame borders
				self:UpdateItemModules("CURSOR_CHANGED - item being moved")
				C_Timer.After(UPDATE_DELAY + 0.1, function()
					self.cursorChangingItem = false
				end)
			end
		else
			-- Item was just placed somewhere
			if not self.cursorChangedRecently then
				self.cursorChangedRecently = true
				-- Only update item modules, NOT frame borders
				self:UpdateItemModules("CURSOR_CHANGED - item placement")
				C_Timer.After(UPDATE_DELAY + 0.1, function()
					self.cursorChangedRecently = false
				end)
			end
		end
	end)
	-- ITEM_PUSH with selective updates
	addon:RegisterEvent("ITEM_PUSH", function()
		if addon.inCombat then return end

		if not self.itemPushProcessing then
			self.itemPushProcessing = true
			-- Only update item modules, NOT frame borders
			self:UpdateItemModules("ITEM_PUSH event")
			C_Timer.After(UPDATE_DELAY + 0.2, function()
				self.itemPushProcessing = false
			end)
		end
	end)
	-- BAG_UPDATE_DELAYED with selective updates
	addon:RegisterEvent("BAG_UPDATE_DELAYED", function()
		if addon.inCombat then return end

		local now = GetTime()
		if self.lastBagUpdateTime and (now - self.lastBagUpdateTime < 0.25) then
			return
		end

		self.lastBagUpdateTime = now
		if addon:IsAnyBagVisible() then
			-- Only update item modules, NOT frame borders
			self:UpdateItemModules("BAG_UPDATE_DELAYED event")
		end
	end)
end

-- EVENT REGISTRATION (Selective Re-enable - Remove Likely Culprits)
function UpdateSystem:RegisterEventHandlers()
	-- Keep only the essential events that definitely don't cause the 5s issue
	-- Bank events (these were working fine)
	addon:RegisterEvent("BANKFRAME_OPENED", function()
		addon.bankOpen = true
		QueueUpdate("BANKFRAME_OPENED", false) -- Frame change - keep QueueUpdate
	end)
	addon:RegisterEvent("BANKFRAME_CLOSED", function()
		addon.bankOpen = false
		QueueUpdate("BANKFRAME_CLOSED", false) -- Frame change - keep QueueUpdate
	end)
	-- BAG_UPDATE with throttling (changed to selective updates)
	addon:RegisterEvent("BAG_UPDATE", function(bagID)
		if addon.inCombat then return end

		-- Throttle BAG_UPDATE events (can fire rapidly during item changes)
		local now = GetTime()
		if self.lastBagUpdateEvent and (now - self.lastBagUpdateEvent < 0.3) then
			return
		end

		self.lastBagUpdateEvent = now
		-- CHANGED: Use selective updates instead of QueueUpdate
		self:UpdateItemModules("BAG_UPDATE: " .. (bagID or "unknown"))
	end)
	-- KEEP THESE COMMENTED OUT (your disabled events):
	-- addon:RegisterEvent("BAG_UPDATE_COOLDOWN", function()
	--	if addon.inCombat then return end
	--	local now = GetTime()
	--	if self.lastCooldownUpdate and (now - self.lastCooldownUpdate < 0.5) then
	--		return
	--	end
	--	self.lastCooldownUpdate = now
	--	QueueUpdate("BAG_UPDATE_COOLDOWN", false)
	-- end)
	-- addon:RegisterEvent("CURRENCY_DISPLAY_UPDATE", function()
	--	if addon.inCombat then return end
	--	local now = GetTime()
	--	if self.lastCurrencyUpdate and (now - self.lastCurrencyUpdate < 1.0) then
	--		return
	--	end
	--	self.lastCurrencyUpdate = now
	--	QueueUpdate("CURRENCY_DISPLAY_UPDATE", false)
	-- end)
	addon:RegisterForEvent("CURRENCY_DIMENSIONS_UPDATED", function(dimensions)
		if not addon.inCombat and addon:IsAnyBagVisible() then
			local now = GetTime()
			if self.lastCurrencyDimensionsUpdate and (now - self.lastCurrencyDimensionsUpdate < 0.5) then
				return
			end

			self.lastCurrencyDimensionsUpdate = now
			QueueUpdate("CURRENCY_DIMENSIONS_UPDATED", false) -- Frame layout change - keep QueueUpdate
		end
	end)
	-- Keep item lock changes as they're needed for item movement (changed to selective updates)
	addon:RegisterEvent("ITEM_LOCK_CHANGED", function()
		if not addon.inCombat then
			-- Throttle item lock changes (rapid during item movement)
			local now = GetTime()
			if self.lastItemLockChange and (now - self.lastItemLockChange < 0.2) then
				return
			end

			self.lastItemLockChange = now
			-- CHANGED: Use selective updates instead of QueueUpdate
			self:UpdateItemModules("ITEM_LOCK_CHANGED")
		end
	end)
	debug("Event handlers registered with selective item updates")
end

-- HOOKS SETUP
function UpdateSystem:SetupHooks()
	-- Remove any existing hooks first
	addon:UnhookAll()
	-- Hook ElvUI's bag module for updates with aggressive layout throttling
	addon:SecureHook(B, "Layout", function()
		-- Throttle ALL layout updates more aggressively (ElvUI runs layout corrections every ~5s)
		local now = GetTime()
		if self.lastLayoutTrigger and (now - self.lastLayoutTrigger < 2.0) then
			return -- Skip layout updates if they happened less than 2 seconds ago
		end

		self.lastLayoutTrigger = now
		if addon.inCombat then
			local bagsVisible = addon:IsAnyBagVisible()
			if not bagsVisible then return end

			if self.lastLayoutUpdate and (now - self.lastLayoutUpdate < 0.5) then
				return
			end

			self.lastLayoutUpdate = now
		end

		QueueUpdate("B:Layout hook", false)
	end)
	-- Hook bag open/close
	if B.OpenBags then
		hooksecurefunc(B, "OpenBags", function()
			addon.bagsOpen = true
			if addon.inCombat then
				-- Minimal updates during combat
				C_Timer.After(0.1, function()
					if addon.elements.borders then
						addon.elements.borders:ApplyBordersToAllElements()
					end

					local background = addon:GetCachedModule("background")
					if background and B.BagFrame then
						background:ApplyBackdropStyle(B.BagFrame)
					end
				end)
			else
				-- Apply borders immediately for bag opening to reduce initial lag
				debug("B:OpenBags detected - applying borders immediately")
				UpdateSystem:ExecuteUpdate("B:OpenBags hook (immediate)", true, false)
				-- Check if this is the first time opening bags
				if addon.firstTimeOpens.bags then
					addon.firstTimeOpens.bags = false
					-- Refresh all borders after initial open
					C_Timer.After(UPDATE_DELAY + 0.1, function()
						if addon:IsAnyBagVisible() then
							addon:RefreshAllBorders()
						end
					end)
				end
			end
		end)
	end

	addon:RawHook(B, "OpenBags", function(...)
		addon.hooks[B].OpenBags(...)
		addon.bagsOpen = true
		if addon.inCombat then
			-- Minimal updates during combat
			C_Timer.After(0.1, function()
				if addon.elements.borders then
					addon.elements.borders:ApplyBordersToAllElements()
				end

				local background = addon:GetCachedModule("background")
				if background and B.BagFrame then
					background:ApplyBackdropStyle(B.BagFrame)
				end
			end)
		else
			-- Apply borders immediately for bag opening to reduce initial lag
			debug("B:OpenBags detected - applying borders immediately")
			UpdateSystem:ExecuteUpdate("B:OpenBags hook (immediate)", true, false)
			-- Check if this is the first time opening bags
			if addon.firstTimeOpens.bags then
				addon.firstTimeOpens.bags = false
				-- Refresh all borders after initial open
				C_Timer.After(UPDATE_DELAY + 0.1, function()
					if addon:IsAnyBagVisible() then
						addon:RefreshAllBorders()
					end
				end)
			end
		end
	end, true)
	-- Enhanced bag close detection
	if B.BagFrame then
		B.BagFrame:HookScript("OnHide", function()
			addon.bagsOpen = false
			-- Schedule cleanup after bags close
			C_Timer.After(0.3, function()
				local ResourceManager = addon:GetCachedModule("resourceManager")
				if ResourceManager and ResourceManager.CleanupMemory then
					ResourceManager:CleanupMemory(true)
				else
					addon:CleanupMemory(true)
				end

				-- Additional cleanup for texture caches
				local MainTextures = addon:GetCachedModule("mainTextures")
				if MainTextures and MainTextures.ClearUnusedTextureCache then
					MainTextures:ClearUnusedTextureCache()
				end

				-- More aggressive resource reclamation
				if ResourceManager and ResourceManager.CleanUnusedPoolObjects then
					ResourceManager:CleanUnusedPoolObjects()
				else
					addon:CleanUnusedPoolObjects()
				end
			end)
		end)
	end

	-- Hook standard WoW bag functions
	self:HookStandardBagFunctions()
	self:SetupWarbandBankDetection()
	addon.hooksInitialized = true
	debug("All hooks established with unified timing")
end

-- Hook standard WoW bag functions
function UpdateSystem:HookStandardBagFunctions()
	-- Hook OpenBackpack
	addon:SecureHook("OpenBackpack", function()
		if addon.inCombat then
			C_Timer.After(0.1, function()
				if addon.elements.borders then
					addon.elements.borders:ApplyBordersToAllElements()
				end

				local background = addon:GetCachedModule("background")
				if background and B.BagFrame then
					background:ApplyBackdropStyle(B.BagFrame)
				end
			end)
		else
			-- Apply borders immediately for bag opening to reduce delay
			debug("OpenBackpack detected - applying borders immediately")
			UpdateSystem:ExecuteUpdate("OpenBackpack hook (immediate)", true, false)
		end
	end)
	-- Hook OpenAllBags
	addon:SecureHook("OpenAllBags", function()
		if addon.inCombat then
			C_Timer.After(0.1, function()
				if addon.elements.borders then
					addon.elements.borders:ApplyBordersToAllElements()
				end
			end)
		else
			-- Apply borders immediately for bag opening to reduce delay
			debug("OpenAllBags detected - applying borders immediately")
			UpdateSystem:ExecuteUpdate("OpenAllBags hook (immediate)", true, false)
		end
	end)
	-- Hook CloseAllBags
	addon:SecureHook("CloseAllBags", function()
		QueueUpdate("CloseAllBags hook", false)
	end)
end

-- Setup warband bank detection
function UpdateSystem:SetupWarbandBankDetection()
	if not C_Bank or not C_Bank.FetchDepositedMoney then return end

	addon:RegisterEvent("BANKFRAME_OPENED", function()
		if addon.firstTimeOpens.warbandBank then
			addon.firstTimeOpens.warbandBank = false
			QueueUpdate("WarbandBankFirstOpen", true)
		end
	end)
end

-- Event handlers
function UpdateSystem:OnPlayerEnteringWorld()
	addon.firstTimeOpens = {
		bags = true,
		bank = true,
		warbandBank = true,
	}
	QueueUpdate("PLAYER_ENTERING_WORLD event", true)
	debug("Player entering world processed")
end

function UpdateSystem:OnAddonLoaded(_, addonName)
	if addonName == "BagCustomizer_for_ElvUI" or addonName == "ElvUI" then
		QueueUpdate("ADDON_LOADED event: " .. addonName, true)
		debug("Addon loaded: " .. addonName)
	end
end

function UpdateSystem:ShouldSkipModuleUpdate()
	return self.combatSuspended and not addon:IsAnyBagVisible()
end

-- MAIN UPDATE FUNCTION
function UpdateSystem:Update(reason, immediate)
	-- Skip if disabled
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then
		if not self.disabledCleanupDone then
			self:RevertAllCustomizations()
			self.disabledCleanupDone = true
		end

		return
	end

	-- Use unified timer system
	QueueUpdate(reason, immediate)
end

-- Update only currently open bags - simplified to avoid nested timers
function UpdateSystem:UpdateOpenBags(isFirstUpdate)
	-- Skip if in combat and frames still processing
	if addon.inCombat and self.processingFrames then
		return
	end

	self.processingFrames = true
	-- Update container frame if showing
	if B.BagFrame and B.BagFrame:IsShown() then
		self:UpdateFrame(B.BagFrame, false, isFirstUpdate)
	end

	-- Update bank frame if showing
	if B.BankFrame and B.BankFrame:IsShown() then
		self:UpdateFrame(B.BankFrame, false, isFirstUpdate)
	end

	-- Handle minimap
	if E.db.bagCustomizer.borders and
			E.db.bagCustomizer.borders.enable and
			E.db.bagCustomizer.borders.elements.minimap then
		self:ApplyMinimapBorder()
	end

	-- Get current currency dimensions if available
	local currencyAndTextures = addon:GetCachedModule("currencyAndTextures")
	if currencyAndTextures and currencyAndTextures.CalculateDimensions then
		local dimensions = currencyAndTextures:CalculateDimensions()
		-- Trigger dimension update event if needed
		if dimensions and dimensions.changed then
			addon:TriggerEvent("CURRENCY_DIMENSIONS_UPDATED", dimensions)
		end
	end

	-- Clear processing flag
	C_Timer.After(0.1, function()
		self.processingFrames = false
	end)
	-- Trigger update event via event bus
	addon:TriggerEvent("UPDATE_COMPLETE")
end

-- Execute the actual update (now called from unified system)
function UpdateSystem:ExecuteUpdate(source, immediate, isFirstUpdate)
	debug("ExecuteUpdate: " ..
		(type(source) == "table" and (source:GetName() or tostring(source)) or tostring(source or "unknown")))
	if not addon.bagsInitialized and not immediate then return end

	-- Skip updates when ElvUI options are being manipulated
	if _G.ElvUI_OptionsUI and _G.ElvUI_OptionsUI.OpeningOrClosing then
		debug("Skipping update while ElvUI options are being modified")
		return
	end

	self.disabledCleanupDone = false
	-- Skip most processing when bags aren't visible (except minimap)
	local bagsVisible = addon:IsAnyBagVisible()
	if not bagsVisible then
		if E.db.bagCustomizer.borders and
				E.db.bagCustomizer.borders.enable and
				E.db.bagCustomizer.borders.elements.minimap then
			self:ApplyMinimapBorder()
		end

		return
	end

	-- Skip most updates during combat if bags aren't shown
	if addon.inCombat then
		if not bagsVisible then
			debug("Update skipped during combat (bags not visible): " .. (source or "unknown"))
			return
		else
			-- Even with bags visible, limit update frequency in combat
			if not immediate and self.lastCombatUpdate and (GetTime() - self.lastCombatUpdate < 0.5) then
				debug("Update throttled during combat: " .. (source or "unknown"))
				return
			end

			self.lastCombatUpdate = GetTime()
		end
	end

	-- Trigger update event
	addon:TriggerEvent("UPDATE_REQUESTED", source, immediate)
	-- Execute actual update
	self:UpdateOpenBags(isFirstUpdate)
end

-- Update a specific frame with all customizations
function UpdateSystem:UpdateFrame(targetFrame, immediate, isFirstUpdate)
	-- Skip if in combat and no bag is visible
	if self:ShouldSkipModuleUpdate() then
		debug("UpdateFrame: Skipping module update due to combat/visibility.")
		return
	end

	if not targetFrame then
		debug("UpdateFrame: Called with nil targetFrame, exiting.")
		return
	end

	debug("UpdateFrame: Starting update for " .. targetFrame:GetName())
	-- Get currency dimensions if this is a bag frame (not bank)
	if not addon:IsBankFrame(targetFrame) then
		local currencyAndTextures = addon:GetCachedModule("currencyAndTextures")
		if currencyAndTextures and currencyAndTextures.CalculateDimensions then
			self.currentCurrencyDimensions = currencyAndTextures:CalculateDimensions()
		end
	end

	-- Step 1: Update frame backgrounds and Textures
	self:UpdateBackgroundsAndTextures(targetFrame)
	-- Step 2: Update search bar backdrop (via UpdateSearchAndBorders) AND stack button position
	self:UpdateSearchAndBorders(targetFrame)
	-- Add explicit stack button positioning
	if not addon:IsBankFrame(targetFrame) then
		local searchBarModule = addon:GetCachedModule("searchBar")
		if searchBarModule and searchBarModule.ApplyStackButtonPosition then
			searchBarModule:ApplyStackButtonPosition(targetFrame)
		else
			debug("UpdateFrame: Could not find searchBar module or ApplyStackButtonPosition for " .. targetFrame:GetName())
		end
	end

	-- Step 3: Update miscellaneous Textures
	local MiscTextures = addon:GetCachedModule("miscTextures")
	if MiscTextures then
		MiscTextures:UpdateFrame(targetFrame)
	end

	-- Step 4: Update slots with proper ordering
	self:UpdateSlots(targetFrame)
	-- Step 5: Update module layouts (e.g., FrameHeight)
	self:UpdateAllModuleLayouts()
	debug("UpdateFrame: Finished update for " .. targetFrame:GetName())
end

-- Update backgrounds and Textures for a frame
function UpdateSystem:UpdateBackgroundsAndTextures(frame)
	-- Get background module with lazy loading
	local background = addon:GetCachedModule("background")
	if background then
		background:ApplyBackdropStyle(frame)
	end

	-- Get MainTextures module with lazy loading
	local MainTextures = addon:GetCachedModule("mainTextures")
	if MainTextures then
		-- Use the new background Textures method
		MainTextures:ApplyBackgroundTextures(frame)
		-- Apply close button texture if needed
		if frame.CloseButton and
				E.db.bagCustomizer.closeButtonTexture and
				E.db.bagCustomizer.closeButtonTexture.enable then
			MainTextures:ApplyCloseButtonTexture(frame)
		end
	end
end

-- Update search bar and borders for a frame
function UpdateSystem:UpdateSearchAndBorders(frame)
	-- Validate frame
	if not frame then return end

	-- Find search box directly
	local searchBox
	if frame == B.BagFrame then
		searchBox = frame.SearchBox or frame.editBox
	elseif frame == B.BankFrame then
		searchBox = frame.SearchBox or frame.editBox
	end

	-- If direct access failed, try to find via children
	if not searchBox and frame:GetNumChildren() > 0 then
		for i = 1, frame:GetNumChildren() do
			local child = select(i, frame:GetChildren())
			if child and child:IsObjectType("EditBox") then
				searchBox = child
				break
			end
		end
	end

	-- Apply search bar styling if search box was found
	if searchBox then
		local searchBar = addon:GetCachedModule("searchBar")
		if searchBar then
			searchBar:ApplySearchBarBackdrop(searchBox)
		end

		local MainTextures = addon:GetCachedModule("mainTextures")
		if MainTextures and
				E.db.bagCustomizer.topTexture and
				E.db.bagCustomizer.topTexture.enable then
			MainTextures:ApplyTopTexture(frame, searchBox)
		end
	end

	-- Apply borders
	local MiscBorders = addon:GetCachedModule("miscBorders")
	if MiscBorders then
		MiscBorders:ApplyBordersToAllElements()
	end
end

-- Update bag slots
function UpdateSystem:UpdateSlots(frame)
	-- Apply slot borders if enabled
	local inventorySlots = addon:GetCachedModule("inventorySlots")
	if inventorySlots and E.db.bagCustomizer.inventorySlots and E.db.bagCustomizer.inventorySlots.enable then
		inventorySlots:UpdateAll()
	end

	-- Apply bind text customization if enabled
	local bindText = addon:GetCachedModule("bindText")
	if bindText and E.db.bagCustomizer.bindTextSettings and E.db.bagCustomizer.bindTextSettings.enable then
		bindText:UpdateAll()
	end
end

-- Update helper
function UpdateSystem:UpdateAllModuleLayouts()
	for elementName, element in pairs(addon.elements) do
		if element.UpdateLayout then
			debug("Running layout update for: " .. elementName)
			element:UpdateLayout()
		end
	end
end

-- Apply minimap border
function UpdateSystem:ApplyMinimapBorder()
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled or
			not E.db.bagCustomizer.borders or not E.db.bagCustomizer.borders.enable then
		-- Hide minimap border if it exists
		local minimap = _G["Minimap"]
		if minimap and minimap._BCZ_borderOverlay then
			minimap._BCZ_borderOverlay:Hide()
		end

		return
	end

	-- Skip if minimap borders are disabled
	if not E.db.bagCustomizer.borders.elements.minimap then
		-- Need to explicitly hide the border when disabled
		local minimap = _G["Minimap"]
		if minimap and minimap._BCZ_borderOverlay then
			minimap._BCZ_borderOverlay:Hide()
		end

		return
	end

	-- Apply border to minimap
	local minimap = _G["Minimap"]
	if minimap then
		-- Use MiscBorders instead of borders
		local MiscBorders = addon:GetCachedModule("miscBorders")
		if MiscBorders then
			MiscBorders:ApplyBorder(minimap, "minimap")
			debug("Applied border to minimap")
		else
			debug("ERROR: Could not get MiscBorders module")
		end
	else
		debug("ERROR: Could not find Minimap object")
	end
end

-- CONSOLIDATED REVERT SYSTEM
-- Revert all customizations back to default
function UpdateSystem:RevertAllCustomizations()
	debug("Reverting all customizations")
	addon:ResetAllResourceCaches()
	-- First, clean up all mask Textures from buttons
	local inventorySlots = addon:GetCachedModule("inventorySlots")
	if inventorySlots and inventorySlots.processedSlots then
		for button in pairs(inventorySlots.processedSlots) do
			if button and button._BCZ and button._BCZ.customIcon and button._BCZ.iconMask then
				-- Safely remove mask Textures
				pcall(function()
					button._BCZ.customIcon:RemoveMaskTexture(button._BCZ.iconMask)
				end)
				-- Clear mask texture
				if button._BCZ.iconMask then
					button._BCZ.iconMask:SetTexture(nil)
				end
			end
		end
	end

	-- Revert all elements that have special cleanup methods
	if addon.elements then
		for elementName, element in pairs(addon.elements) do
			-- First check for Cleanup as it's the most comprehensive
			if element.Cleanup then
				debug("Running Cleanup for: " .. elementName)
				element:Cleanup()
				-- Fall back to specific revert methods
			elseif element.Revert or element.RevertAllSlots or element.RevertFrame then
				debug("Reverting element: " .. elementName)
				if element.Revert then element:Revert() end

				if element.RevertAllSlots then
					-- Get frames to revert using direct ElvUI references
					if B.BagFrame then element:RevertAllSlots(B.BagFrame) end

					if B.BankFrame then element:RevertAllSlots(B.BankFrame) end
				end

				if element.RevertFrame then
					-- Revert both container and bank frame using direct ElvUI references
					if B.BagFrame then element:RevertFrame(B.BagFrame) end

					if B.BankFrame then element:RevertFrame(B.BankFrame) end
				end
			end
		end
	end

	-- Revert frame borders
	local borders = addon:GetCachedModule("borders")
	if borders then
		borders:RevertAllBorders()
	end

	-- Revert Textures
	self:RevertTextures()
	-- Revert bind text customizations
	local bindText = addon:GetCachedModule("bindText")
	if bindText then
		bindText:Revert()
	end

	-- Revert background and slots for bag frame
	if B.BagFrame then
		local background = addon:GetCachedModule("background")
		if background then
			background:RevertBackdropStyle(B.BagFrame)
		end

		-- Revert search bar - direct access
		local searchBox = B.BagFrame.SearchBox or B.BagFrame.editBox
		if not searchBox then
			-- Try to find via children
			for i = 1, B.BagFrame:GetNumChildren() do
				local child = select(i, B.BagFrame:GetChildren())
				if child and child:IsObjectType("EditBox") then
					searchBox = child
					break
				end
			end
		end

		if searchBox then
			local searchBar = addon:GetCachedModule("searchBar")
			if searchBar then
				searchBar:RevertSearchBarBackdrop(searchBox)
			end
		end
	end

	-- Revert bank frame
	if B.BankFrame then
		local background = addon:GetCachedModule("background")
		if background then
			background:RevertBackdropStyle(B.BankFrame)
		end

		-- Revert search bar - direct access
		local bankSearchBox = B.BankFrame.SearchBox or B.BankFrame.editBox
		if not bankSearchBox then
			-- Try to find via children
			for i = 1, B.BankFrame:GetNumChildren() do
				local child = select(i, B.BankFrame:GetChildren())
				if child and child:IsObjectType("EditBox") then
					bankSearchBox = child
					break
				end
			end
		end

		if bankSearchBox then
			local searchBar = addon:GetCachedModule("searchBar")
			if searchBar then
				searchBar:RevertSearchBarBackdrop(bankSearchBox)
			end
		end
	end

	-- Revert slot shape
	if inventorySlots then
		inventorySlots:RevertAllSlots()
	end

	-- Clear all texture caches
	if inventorySlots then
		-- Clear button Textures cache
		if type(inventorySlots.buttonTexturesCache) == "table" then
			for k in pairs(inventorySlots.buttonTexturesCache) do
				inventorySlots.buttonTexturesCache[k] = nil
			end
		end

		-- Clear color cache
		if type(inventorySlots.colorCache) == "table" then
			for k in pairs(inventorySlots.colorCache) do
				inventorySlots.colorCache[k] = nil
			end
		end

		-- Reset ElvUI highlight cache
		inventorySlots.extractedElvUIHighlight = nil
	end

	-- Force garbage collection to clean up Textures
	collectgarbage("collect")
	debug("All customizations reverted and cleaned up")
end

-- Consolidated texture reversion
function UpdateSystem:RevertTextures()
	-- Revert bag frame Textures
	if B.BagFrame then
		self:RevertFrameTextures(B.BagFrame)
	end

	-- Revert bank frame Textures
	if B.BankFrame then
		self:RevertFrameTextures(B.BankFrame)
	end

	-- Clear texture path cache
	addon:ClearTextureCache()
	debug("All Textures reverted and properly released")
end

-- Helper function to revert Textures for a frame with texture property cleanup optimization
function UpdateSystem:RevertFrameTextures(frame)
	-- Safety check
	if not frame then return end

	-- Define texture properties to clean up
	local textureProperties = {
		"_BCZ_uiBackground",
		"_BCZ_artBackground",
		"_BCZ_customTexture",
		"_BCZ_topTexture",
	}
	-- Clean up textures
	for _, prop in ipairs(textureProperties) do
		if frame[prop] then
			addon:ReleaseTexture(frame[prop])
			frame[prop] = nil
		end
	end

	-- Special handling for containers
	if frame._BCZ_artBackgroundMask then
		frame._BCZ_artBackgroundMask:Hide()
		frame._BCZ_artBackgroundMask = nil
	end

	if frame._BCZ_textureContainer then
		frame._BCZ_textureContainer:Hide()
	end

	-- Special handling for top texture container
	if frame._BCZ_topTextureContainer then
		local containerParts = { "Left", "Middle", "Right" }
		for _, part in ipairs(containerParts) do
			if frame._BCZ_topTextureContainer[part] then
				addon:ReleaseTexture(frame._BCZ_topTextureContainer[part])
			end
		end

		frame._BCZ_topTextureContainer:Hide()
	end
end

-- Legacy convenience functions that all call the main Update function
function UpdateSystem:DebouncedUpdate(reason, immediate)
	self:Update(reason, immediate)
end

function UpdateSystem:ApplyChanges()
	self:Update("ApplyChanges", true)
end

function UpdateSystem:ThrottledUpdate()
	self:Update("ThrottledUpdate", false)
end

function UpdateSystem:FullUpdate()
	self:Update("FullUpdate", true)
end

function UpdateSystem:UpdateLayout()
	-- Check if layout module exists
	if addon.elements and addon.elements.layout then
		addon.elements.layout:UpdateLayout()
	else
		-- Log error if layout module is missing
		debug("Error: Layout module not found!")
	end
end

-- Module registration system
function UpdateSystem:RegisterModuleUpdate(moduleName, updateFunc)
	self.moduleUpdates = self.moduleUpdates or {}
	self.moduleUpdates[moduleName] = updateFunc
	debug("Registered module update: " .. moduleName)
end

function UpdateSystem:RegisterEvent(eventName, handler)
	addon:RegisterForEvent(eventName, handler)
end

-- Initialize function for UpdateSystem module
function UpdateSystem:Initialize()
	debug("Initializing UpdateSystem module")
	-- Set up initial state
	self.lastUpdateTimes = {}
	-- Register with main addon
	addon:RegisterElementUpdate("updateSystem", function(reason, immediate)
		-- Special handling for certain update types
		if reason == "REFRESH_REQUESTED" then
			self:FullUpdate()
		end
	end)
	-- Track initialization
	self.initialized = true
	debug("UpdateSystem module initialized")
end

-- Initialize early
UpdateSystem:OnInitialize()
-- Make sure this module is available to the core addon
addon.elements.updateSystem = UpdateSystem
