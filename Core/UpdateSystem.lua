-- ElvUI Bag Customizer - Update System
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

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.updateSystem or
			not E.db.bagCustomizer.updateSystem.debug then
		return
	end

	-- Output the message with module name
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
-- Make sure the module is properly initialized early
function UpdateSystem:OnInitialize()
	debug("Early initialization of UpdateSystem module")
	-- Register all our functions to make them available to the core addon
	self.lastUpdateTimes = {}
end

-- COMBAT OPTIMIZATION FUNCTIONS --
function UpdateSystem:OptimizeForCombat()
	-- Enter combat mode
	addon.inCombat = true
	debug("Entered combat - optimizing performance")
	-- Cancel any pending updates
	if addon.updateTimer then
		addon.updateTimer:Cancel()
		addon.updateTimer = nil
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
	-- Disable any visual-only updates during combat
	self.combatSuspended = true
	-- Trigger combat event via event bus
	addon:TriggerEvent("COMBAT_STARTED")
end

function UpdateSystem:RestoreFromCombat()
	-- Exit combat mode
	addon.inCombat = false
	debug("Exited combat - restoring normal functionality")
	-- Register all events in one batch with small separate delays
	self:RegisterCombatEvents()
	-- Reset suspension flag
	self.combatSuspended = false
	-- Update if bags are visible after a small delay to ensure UI is stable
	C_Timer.After(0.3, function()
		if addon:IsAnyBagVisible() then
			self:Update("Combat ended with bags open", false)
		end
	end)
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
			-- Fallback to core method if ResourceManager isn't available
			addon:CleanupMemory(false)
		end
	end)
	-- Trigger combat event via event bus
	addon:TriggerEvent("COMBAT_ENDED")
end

-- Register combat events in one batch with small delays to avoid UI hitching
function UpdateSystem:RegisterCombatEvents()
	-- Register CURSOR_CHANGED after a small delay
	C_Timer.After(0.1, function()
		addon:RegisterEvent("CURSOR_CHANGED", function()
			if addon.inCombat then return end

			if CursorHasItem() then
				-- An item is being moved
				if not self.cursorChangingItem then
					self.cursorChangingItem = true
					C_Timer.After(0.1, function()
						self.cursorChangingItem = false
						if addon:IsAnyBagVisible() then
							self:Update("CURSOR_CHANGED - item being moved", false)
						end
					end)
				end
			else
				-- Item was just placed somewhere
				if not self.cursorChangedRecently then
					self.cursorChangedRecently = true
					C_Timer.After(0.1, function()
						self.cursorChangedRecently = false
						if addon:IsAnyBagVisible() then
							self:Update("CURSOR_CHANGED - item placement", false)
							-- Update slot borders after a short delay if needed
							if addon.elements.inventorySlots and addon:IsAnyBagVisible() then
								C_Timer.After(0.2, function()
									addon.elements.inventorySlots:UpdateAll()
								end)
							end
						end
					end)
				end
			end
		end)
	end)
	-- Register ITEM_PUSH after a small delay
	C_Timer.After(0.15, function()
		addon:RegisterEvent("ITEM_PUSH", function()
			if addon.inCombat then return end

			-- Use flag to prevent multiple simultaneous updates
			if not self.itemPushProcessing then
				self.itemPushProcessing = true
				C_Timer.After(0.1, function()
					if addon:IsAnyBagVisible() then
						self:Update("ITEM_PUSH event", false)
						-- Update slot borders after a delay if needed
						C_Timer.After(0.2, function()
							self.itemPushProcessing = false
							if addon.elements.inventorySlots and addon:IsAnyBagVisible() then
								addon.elements.inventorySlots:UpdateAll()
							end
						end)
					else
						self.itemPushProcessing = false
					end
				end)
			end
		end)
	end)
	-- Register BAG_UPDATE_DELAYED after a small delay
	C_Timer.After(0.2, function()
		addon:RegisterEvent("BAG_UPDATE_DELAYED", function()
			if addon.inCombat then return end

			-- Throttle updates
			local now = GetTime()
			if self.lastBagUpdateTime and (now - self.lastBagUpdateTime < 0.25) then
				return
			end

			self.lastBagUpdateTime = now
			if addon:IsAnyBagVisible() then
				self:Update("BAG_UPDATE_DELAYED event", false)
			end
		end)
	end)
end

-- HOOKS AND EVENTS --
function UpdateSystem:SetupHooks()
	-- Remove any existing hooks first
	addon:UnhookAll()
	-- Hook ElvUI's bag module for updates, with combat awareness
	addon:SecureHook(B, "Layout", function()
		-- Skip during intense combat or if performance issues detected
		if addon.inCombat then
			local bagsVisible = addon:IsAnyBagVisible()
			if not bagsVisible then
				return -- Skip updates for invisible bags
			end

			-- Throttle updates even if bags are visible
			local now = GetTime()
			if self.lastLayoutUpdate and (now - self.lastLayoutUpdate < 0.5) then
				return
			end

			self.lastLayoutUpdate = now
		end

		self:Update("B:Layout hook", false)
	end)
	-- Hook bag open/close with improved combat awareness
	addon:RawHook(B, "OpenBags", function(...)
		addon.hooks[B].OpenBags(...)
		-- Track that bags are open
		addon.bagsOpen = true
		-- Apply updates based on combat state
		if addon.inCombat then
			-- Minimal updates during combat
			C_Timer.After(0.1, function()
				if addon.elements.borders then
					addon.elements.borders:ApplyBordersToAllElements()
				end

				local background = addon:GetCachedModule("background")
				if background then
					-- Direct reference to ElvUI bag frame
					if B.BagFrame then
						background:ApplyBackdropStyle(B.BagFrame)
					end
				end
			end)
		else
			-- Full update outside combat
			self:Update("B:OpenBags hook", true)
			-- Check if this is the first time opening bags
			if addon.firstTimeOpens.bags then
				addon.firstTimeOpens.bags = false
				-- Refresh all borders after initial open
				C_Timer.After(0.2, function()
					if addon:IsAnyBagVisible() then
						addon:RefreshAllBorders()
					end
				end)
			end
		end
	end, true)
	-- Enhanced CloseBags hook with improved memory management
	addon:RawHook(B, "CloseBags", function(...)
		-- Call original method
		addon.hooks[B].CloseBags(...)
		-- Track that bags are closed
		addon.bagsOpen = false
		-- Schedule cleanup after a short delay
		C_Timer.After(0.3, function()
			-- Clean up memory when bags close
			local ResourceManager = addon:GetCachedModule("resourceManager")
			if ResourceManager and ResourceManager.CleanupMemory then
				ResourceManager:CleanupMemory(true)
			else
				-- Fallback to core method if ResourceManager isn't available
				addon:CleanupMemory(true)
			end

			-- Additional cleanup for texture caches
			local MainTextures = addon:GetCachedModule("mainTextures")
			if MainTextures and MainTextures.ClearUnusedTextureCache then
				MainTextures:ClearUnusedTextureCache()
			end

			-- More aggressive resource reclamation
			local ResourceManager = addon:GetCachedModule("resourceManager")
			if ResourceManager and ResourceManager.CleanUnusedPoolObjects then
				ResourceManager:CleanUnusedPoolObjects()
			else
				-- Fallback to core method if ResourceManager isn't available
				addon:CleanUnusedPoolObjects()
			end
		end)
	end, true)
	-- Hook standard WoW bag functions with combat awareness
	self:HookStandardBagFunctions()
	-- Hook Warband bank detection
	self:SetupWarbandBankDetection()
	-- Track that hooks are initialized
	addon.hooksInitialized = true
	debug("All hooks established")
end

-- Hook standard WoW bag functions
function UpdateSystem:HookStandardBagFunctions()
	-- Hook OpenBackpack
	addon:SecureHook("OpenBackpack", function()
		if addon.inCombat then
			-- Minimal updates during combat
			C_Timer.After(0.1, function()
				if addon.elements.borders then
					addon.elements.borders:ApplyBordersToAllElements()
				end

				local background = addon:GetCachedModule("background")
				if background then
					-- Direct reference to ElvUI bag frame
					if B.BagFrame then
						background:ApplyBackdropStyle(B.BagFrame)
					end
				end
			end)
		else
			-- Full update outside combat
			self:Update("OpenBackpack hook", true)
		end
	end)
	-- Hook OpenAllBags
	addon:SecureHook("OpenAllBags", function()
		if addon.inCombat then
			C_Timer.After(0.1, function()
				if addon.elements.borders then
					addon.elements.borders:ApplyBordersToAllElements()
				end

				local background = addon:GetCachedModule("background")
				if background and addon:IsAnyBagVisible() then
					-- Direct reference to ElvUI bag frame
					if B.BagFrame then
						background:ApplyBackdropStyle(B.BagFrame)
					end
				end
			end)
		else
			self:Update("OpenAllBags hook", true)
		end
	end)
	-- Hook ToggleAllBags
	addon:SecureHook("ToggleAllBags", function()
		if addon.inCombat then
			C_Timer.After(0.1, function()
				if addon:IsAnyBagVisible() then
					if addon.elements.borders then
						addon.elements.borders:ApplyBordersToAllElements()
					end

					local background = addon:GetCachedModule("background")
					if background then
						-- Direct reference to ElvUI bag frame
						if B.BagFrame then
							background:ApplyBackdropStyle(B.BagFrame)
						end
					end
				end
			end)
		else
			self:Update("ToggleAllBags hook", true)
		end
	end)
	-- Hook ElvUI bag assignment with combat awareness
	if B.AssignBagFunctionality then
		addon:SecureHook(B, "AssignBagFunctionality", function()
			if addon.inCombat then
				return -- Skip during combat
			end

			C_Timer.After(0.1, function()
				-- Update slot borders for bag assignments
				if addon.elements.inventorySlots then
					addon.elements.inventorySlots:ResetCache()
					addon.elements.inventorySlots:UpdateAll()
				end
			end)
		end)
	end
end

-- Set up detection for the warband bank tab
function UpdateSystem:SetupWarbandBankDetection()
	-- Hook the BankFrameTab button clicks to detect warband bank tab
	for i = 1, 5 do
		local tab = _G["BankFrameTab" .. i]
		if tab then
			tab:HookScript("OnClick", function()
				local tabText = tab:GetText() or ""
				if tabText:find("Warband") and addon.firstTimeOpens.warbandBank then
					addon.firstTimeOpens.warbandBank = false
					C_Timer.After(0.2, function()
						if B.BankFrame and B.BankFrame:IsShown() then
							self:Update("WarbandBankFirstOpen", true)
						end
					end)
				end
			end)
		end
	end

	debug("Warband bank detection set up")
end

-- Register all event handlers
function UpdateSystem:RegisterEventHandlers()
	-- Register bank frame events
	addon:RegisterEvent("BANKFRAME_OPENED", function()
		if addon.inCombat then
			-- Minimal update during combat
			C_Timer.After(0.1, function()
				if addon.elements.borders and addon:IsAnyBagVisible() then
					addon.elements.borders:ApplyBordersToAllElements()
				end
			end)
		else
			-- Full update
			self:Update("BANKFRAME_OPENED event", true)
			-- Check if this is the first time opening the bank
			if addon.firstTimeOpens.bank then
				addon.firstTimeOpens.bank = false
				C_Timer.After(0.2, function()
					if B.BankFrame and B.BankFrame:IsShown() then
						addon:RefreshAllBorders()
					end
				end)
			end
		end
	end)
	-- Handle player entering world - USE A CALLBACK FUNCTION INSTEAD OF METHOD NAME
	addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		self:OnPlayerEnteringWorld()
	end)
	-- Handle addon loading - USE A CALLBACK FUNCTION INSTEAD OF METHOD NAME
	addon:RegisterEvent("ADDON_LOADED", function(_, addonName)
		self:OnAddonLoaded(_, addonName)
	end)
	-- Combat event handlers
	addon:RegisterEvent("PLAYER_REGEN_DISABLED", function()
		self:OptimizeForCombat()
	end)
	addon:RegisterEvent("PLAYER_REGEN_ENABLED", function()
		self:RestoreFromCombat()
	end)
	-- Add BAG_CLOSED event for memory cleanup
	addon:RegisterEvent("BAG_CLOSED", function()
		-- Schedule cleanup after all bag operations complete
		C_Timer.After(1, function()
			if not addon:IsAnyBagVisible() then
				local ResourceManager = addon:GetCachedModule("resourceManager")
				if ResourceManager and ResourceManager.CleanupMemory then
					ResourceManager:CleanupMemory(true)
				else
					-- Fallback to core method if ResourceManager isn't available
					addon:CleanupMemory(true)
				end
			end
		end)
	end)
	debug("All event handlers registered")
end

-- Event handlers
function UpdateSystem:OnPlayerEnteringWorld()
	-- Reset first-time opens
	addon.firstTimeOpens = {
		bags = true,
		bank = true,
		warbandBank = true,
	}
	C_Timer.After(1, function()
		self:Update("PLAYER_ENTERING_WORLD event", true)
	end)
	debug("Player entering world processed")
end

function UpdateSystem:OnAddonLoaded(_, addonName)
	if addonName == "BagCustomizer_for_ElvUI" or addonName == "ElvUI" then
		C_Timer.After(0.5, function()
			self:Update("ADDON_LOADED event: " .. addonName, true)
		end)
		debug("Addon loaded: " .. addonName)
	end
end

-- MainTextures.lua helper
function UpdateSystem:ShouldSkipModuleUpdate()
	return self.combatSuspended and not addon:IsAnyBagVisible()
end

-- CONSOLIDATED UPDATE SYSTEM --
-- Main update function - the single entry point for all updates
function UpdateSystem:Update(reason, immediate)
	-- Skip if disabled
	if not E.db.bagCustomizer or not E.db.bagCustomizer.enabled then
		if not self.disabledCleanupDone then
			-- Simple cleanup of customizations
			self:RevertAllCustomizations()
			self.disabledCleanupDone = true
		end

		return
	end

	-- Skip ALL processing when bags aren't visible (except minimap)
	local bagsVisible = addon:IsAnyBagVisible()
	if not bagsVisible then
		-- Only handle minimap border if needed
		if E.db.bagCustomizer.borders and
				E.db.bagCustomizer.borders.enable and
				E.db.bagCustomizer.borders.elements.minimap then
			self:ApplyMinimapBorder()
		end

		return
	end

	-- Optimized first update check
	local isFirstUpdate = false
	if reason then
		if firstUpdateReasons[reason] then
			-- Direct lookup is faster than string patterns
			isFirstUpdate = true
		elseif reason:find("first") or reason:find("Initial") then
			-- Fall back to pattern matching only when needed
			isFirstUpdate = true
		end
	end

	-- If first update, pass forceRebuild=true to texture module
	if addon.elements.mainTextures and isFirstUpdate then
		-- Force complete texture rebuild on major events
		if B.BagFrame and B.BagFrame:IsShown() then
			addon.elements.mainTextures:UpdateFrame(B.BagFrame, true)
		end

		if B.BankFrame and B.BankFrame:IsShown() then
			addon.elements.mainTextures:UpdateFrame(B.BankFrame, true)
		end
	end

	-- Skip most updates during combat if bags aren't shown
	if addon.inCombat then
		if not bagsVisible then
			debug("Update skipped during combat (bags not visible): " .. (reason or "unknown"))
			return
		else
			-- Even with bags visible, limit update frequency in combat
			if not immediate and self.lastCombatUpdate and (GetTime() - self.lastCombatUpdate < 0.5) then
				debug("Update throttled during combat: " .. (reason or "unknown"))
				return
			end

			self.lastCombatUpdate = GetTime()
		end
	end

	self.disabledCleanupDone = false
	-- Debug logging
	debug("Update requested: " .. (reason or "unknown") .. (immediate and " (immediate)" or ""))
	-- Implement debouncing
	local now = GetTime()
	local updateType = reason or "general"
	self.lastUpdateTimes = self.lastUpdateTimes or {}
	-- Skip redundant updates of the same type unless forced
	if not immediate and self.lastUpdateTimes[updateType] and (now - self.lastUpdateTimes[updateType] < 0.3) then
		debug("Skipping redundant update of type: " .. updateType)
		return
	end

	-- Update the timestamp
	self.lastUpdateTimes[updateType] = now
	-- Cancel existing timer if it exists
	if addon.updateTimer then
		addon.updateTimer:Cancel()
		addon.updateTimer = nil
	end

	-- Schedule update based on immediate flag
	if immediate then
		-- Do immediate update
		self:UpdateOpenBags()
	else
		-- Schedule delayed update with variable timing based on combat status
		local delay = addon.inCombat and 0.2 or 0.1
		addon.updateTimer = C_Timer.NewTimer(delay, function()
			self:UpdateOpenBags()
			addon.updateTimer = nil
		end)
	end

	-- Notify element update callbacks (but throttle during combat)
	if addon.elementUpdateCallbacks and (not addon.inCombat or immediate) then
		for elementName, updateFunc in pairs(addon.elementUpdateCallbacks) do
			if type(updateFunc) == "function" then
				-- Use pcall to prevent errors in element update callbacks from breaking the whole update
				local success, errorMsg = pcall(function()
					updateFunc(reason, immediate)
				end)
				if not success then
					debug("Error in element update callback for " .. elementName .. ": " .. tostring(errorMsg))
				end
			end
		end
	end

	-- Trigger update event via event bus
	addon:TriggerEvent("UPDATE_REQUESTED", reason, immediate)
end

-- Update only currently open bags - simplified to avoid nested timers
function UpdateSystem:UpdateOpenBags()
	-- Skip if in combat and frames still processing
	if addon.inCombat and self.processingFrames then
		return
	end

	self.processingFrames = true
	-- Sequential updates with a single timer chain
	-- Update container frame if showing
	if B.BagFrame and B.BagFrame:IsShown() then
		self:ExecuteUpdate(B.BagFrame)
	end

	-- Update bank frame if showing
	if B.BankFrame and B.BankFrame:IsShown() then
		self:ExecuteUpdate(B.BankFrame)
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

-- Update a specific frame with all customizations
function UpdateSystem:ExecuteUpdate(targetFrame)
	-- Skip if in combat and no bag is visible
	if self:ShouldSkipModuleUpdate() then
		debug("ExecuteUpdate: Skipping module update due to combat/visibility.") -- Added debug
		return
	end

	if not targetFrame then
		-- This block seems redundant if ExecuteUpdate is always called with a targetFrame
		-- from UpdateOpenBags. Consider removing or refining if targetFrame can be nil.
		-- Update each visible frame
		-- if B.BagFrame and B.BagFrame:IsShown() then
		-- 	self:ExecuteUpdate(B.BagFrame)
		-- end
		-- if B.BankFrame and B.BankFrame:IsShown() then
		-- 	self:ExecuteUpdate(B.BankFrame)
		-- end
		debug("ExecuteUpdate: Called with nil targetFrame, exiting.") -- Added debug
		return
	end

	debug("ExecuteUpdate: Starting update for " .. targetFrame:GetName()) -- Added debug
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
	self:UpdateSearchAndBorders(targetFrame)  -- This handles search bar backdrop
	-- <<<< ADD EXPLICIT STACK BUTTON POSITIONING >>>>
	if not addon:IsBankFrame(targetFrame) then -- Only apply to non-bank frames
		local searchBarModule = addon:GetCachedModule("searchBar")
		if searchBarModule and searchBarModule.ApplyStackButtonPosition then
			searchBarModule:ApplyStackButtonPosition(targetFrame)
			-- Removed debug from previous attempt as ApplyStackButtonPosition has its own debug now.
		else
			debug("ExecuteUpdate: Could not find searchBar module or ApplyStackButtonPosition for " .. targetFrame:GetName())
		end
	end

	-- <<<< END ADDED CODE >>>>
	-- Step 3: Update miscellaneous Textures
	local MiscTextures = addon:GetCachedModule("miscTextures")
	if MiscTextures then
		MiscTextures:UpdateFrame(targetFrame)
	end

	-- Step 4: Update slots with proper ordering
	self:UpdateSlots(targetFrame)
	-- Step 5: Update module layouts (e.g., FrameHeight)
	self:UpdateAllModuleLayouts()
	debug("ExecuteUpdate: Finished update for " .. targetFrame:GetName()) -- Added debug
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

-- Update helper
function UpdateSystem:UpdateAllModuleLayouts()
	for elementName, element in pairs(addon.elements) do
		if element.UpdateLayout then
			debug("Running layout update for: " .. elementName)
			element:UpdateLayout()
		end
	end
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

-- CONSOLIDATED REVERT SYSTEM --
-- Revert all customizations back to default
function UpdateSystem:RevertAllCustomizations()
	debug("Reverting all customizations")
	addon:ResetAllResourceCaches()
	-- IMPORTANT FIX: First, clean up all mask Textures from buttons
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
	local inventorySlots = addon:GetCachedModule("inventorySlots")
	if inventorySlots then
		inventorySlots:RevertAllSlots()
	end

	-- ADDITIONAL FIX: Clear all texture caches
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
