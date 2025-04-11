--[[

    ElvUI Bag Customizer

    Copyright (C) 2025 Mellow_ayaya



    This program is free software: you can redistribute it and/or modify

    it under the terms of the GNU General Public License as published by

    the Free Software Foundation, either version 3 of the License, or

    (at your option) any later version.

]]
-- ElvUI Bag Customizer - Core module
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags")
local EP = LibStub("LibElvUIPlugin-1.0")
local addon = E:NewModule("BagCustomizer", "AceHook-3.0", "AceEvent-3.0")
-- Ensure ElvUI is enabled
if not E then
	print("|cFFFF0000BagCustomizer_for_ElvUI:|r This addon requires ElvUI to be enabled.")
	return
end

-- Create namespace for addon components
addon.elements = {}    -- Store element-specific functions
addon.inCombat = false -- Combat status
addon._themeUpdateTimer = nil
addon.elementUpdateCallbacks = {}
-- Resource pools
addon.texturePool = {}
addon.framePool = {}
-- Track first time opening of bags
addon.firstTimeOpens = {

	bags = true,

	bank = true,

	warbandBank = true,

}
-- Add a module reference cache
addon.moduleCache = {}
-- Debug function optimization
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][core]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.core or

			not E.db.bagCustomizer.core.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- ==========================================
-- Event Bus System
-- ==========================================
-- Initialize event system storage
addon.eventListeners = {}
-- Register for events
function addon:RegisterForEvent(event, callback)
	if not self.eventListeners[event] then
		self.eventListeners[event] = {}
	end

	-- Add callback to event listeners
	table.insert(self.eventListeners[event], callback)
	debug("Registered listener for event: " .. event)
	return true
end

-- Unregister from events
function addon:UnregisterFromEvent(event, callback)
	if not self.eventListeners[event] then
		return false
	end

	-- Find and remove callback
	for i, registeredCallback in ipairs(self.eventListeners[event]) do
		if registeredCallback == callback then
			table.remove(self.eventListeners[event], i)
			debug("Unregistered listener from event: " .. event)
			return true
		end
	end

	return false
end

-- Trigger events
function addon:TriggerEvent(event, arg1, arg2, arg3, arg4, arg5)
	if not self.eventListeners[event] then
		-- Ignore specific events that commonly have no listeners
		if event ~= "BORDERS_APPLIED_TO_CONTAINER" then
			debug("No listeners registered for event: " .. event)
		end

		return 0
	end

	if not self.eventListeners[event] then
		debug("No listeners registered for event: " .. event)
		return 0
	end

	local count = 0
	-- Make a copy of the listeners table to prevent issues if callbacks register/unregister
	local listeners = {}
	for i, callback in ipairs(self.eventListeners[event]) do
		listeners[i] = callback
		count = count + 1
	end

	-- Call each listener with error protection
	for _, callback in ipairs(listeners) do
		local success, err = pcall(function()
			callback(arg1, arg2, arg3, arg4, arg5)
		end)
		if not success then
			debug("Error in event handler for '" .. event .. "': " .. tostring(err))
		end
	end

	debug("Triggered event '" .. event .. "' with " .. count .. " listeners")
	return count
end

-- Initialize the event system
local function InitializeEventSystem()
	debug("Initializing event system")
	-- Reset event listeners
	addon.eventListeners = {}
	-- Register core events that modules might need
	addon:RegisterForEvent("MODULE_ENABLED", function(moduleName, enabled)
		debug("Module '" .. moduleName .. "' " .. (enabled and "enabled" or "disabled"))
	end)
	-- Legacy event support - hook the old functions to trigger events
	if addon.ToggleModule then
		local originalToggleModule = addon.ToggleModule
		addon.ToggleModule = function(self, moduleName, enable)
			local result = originalToggleModule(self, moduleName, enable)
			-- Trigger event for module toggle
			self:TriggerEvent("MODULE_ENABLED", moduleName, enable)
			-- Also trigger a more specific event for the module
			self:TriggerEvent(moduleName .. "_ENABLED", enable)
			return result
		end
	end

	debug("Event system initialized")
end

function addon:IsBankFrame(frame)
	if not frame then
		return false
	end

	local n = frame:GetName() or ""
	if n:find("Bank") or n:find("bank") then
		return true
	end

	local B = E:GetModule("Bags")
	if B and ((B.BankFrame and frame == B.BankFrame) or (B.WarbankFrame and frame == B.WarbankFrame)) then
		return true
	end

	if frame.bankID or frame.isBank or frame.bagFrameType == "BANK" then
		return true
	end

	return false
end

-- Initialize debug settings - add to your Initialize function
function addon:InitializeDebugSettings()
	-- Ensure the main debug toggle exists
	if E.db.bagCustomizer.debug == nil then
		E.db.bagCustomizer.debug = addon.defaults.debug or false
	end

	-- Ensure core module has debug settings
	if not E.db.bagCustomizer.core then
		E.db.bagCustomizer.core = {}
	end

	-- Use default value from your defaults table instead of hardcoded true
	if E.db.bagCustomizer.core.debug == nil then
		E.db.bagCustomizer.core.debug = (addon.defaults.core and addon.defaults.core.debug) or false
	end

	debug("Debug settings initialized")
end

-- Validate if a frame is a bag frame
function addon:IsBagFrame(frame)
	return frame and (frame == B.BagFrame or frame == B.BankFrame)
end

-- Get module with lazy loading
function addon:GetModule(moduleName)
	if not self.loadedModules then
		self.loadedModules = {}
	end

	if not self.loadedModules[moduleName] then
		if not self.elements[moduleName] then
			debug("Module not found: " .. moduleName)
			return nil
		end

		self.loadedModules[moduleName] = self.elements[moduleName]
		-- Initialize if needed
		if self.loadedModules[moduleName].Initialize then
			debug("Initializing module: " .. moduleName)
			self.loadedModules[moduleName]:Initialize()
		end
	end

	return self.loadedModules[moduleName]
end

-- Get module with caching
function addon:GetCachedModule(moduleName)
	if not self.moduleCache[moduleName] then
		self.moduleCache[moduleName] = self:GetModule(moduleName)
	end

	return self.moduleCache[moduleName]
end

-- Clear module cache on profile changes
function addon:ClearModuleCache()
	wipe(self.moduleCache)
end

-- Register element for updates
function addon:RegisterElementUpdate(elementName, updateFunc)
	if type(updateFunc) ~= "function" then
		debug("Failed to register element update for " .. elementName .. " - updateFunc is not a function")
		return
	end

	self.elementUpdateCallbacks = self.elementUpdateCallbacks or {}
	self.elementUpdateCallbacks[elementName] = updateFunc
	debug("Registered element update for " .. elementName)
end

-- Check if any bags are visible
function addon:IsAnyBagVisible()
	return (B.BagFrame and B.BagFrame:IsShown()) or (B.BankFrame and B.BankFrame:IsShown())
end

-- Refresh all borders, including ElvUI's defaults
function addon:RefreshAllBorders()
	debug("Refreshing all borders")
	-- Get UpdateSystem module reference
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.Update then
		UpdateSystem:Update("RefreshAllBorders", true)
	else
		-- For backward compatibility
		self:Update("RefreshAllBorders", true)
	end

	-- For regular bags
	if B.BagFrame and B.BagFrame:IsShown() and B.Layout then
		B:Layout()
	end

	-- For bank
	if B.BankFrame and B.BankFrame:IsShown() then
		self:ExecuteUpdate(B.BankFrame)
	end

	-- Force update slot borders if enabled
	local inventorySlots = self:GetCachedModule("inventorySlots")
	if inventorySlots and E.db.bagCustomizer.inventorySlots and E.db.bagCustomizer.inventorySlots.enable then
		if inventorySlots.UpdateAll then
			inventorySlots:UpdateAll()
		end
	end
end

-- Setup hooks - STUB that calls the UpdateSystem version
-- TODO: Update all module references to call UpdateSystem:SetupHooks() directly
function addon:SetupHooks()
	debug("SetupHooks called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.SetupHooks then
		UpdateSystem:SetupHooks()
		return
	end

	-- Legacy implementation if UpdateSystem module isn't available
	-- Skip if already hooked
	if self.hooksInitialized then return end

	-- Hook ElvUI bag functions directly
	self:SecureHook(B, "Layout", function()
		if not self.isUpdating then
			self.isUpdating = true
			self:Update("BagLayout")
			self.isUpdating = false
		end
	end)
	-- Hook bag opening/closing events
	self:SecureHook("OpenBackpack", function()
		self:Update("OpenBackpack")
	end)
	self:SecureHook("OpenAllBags", function()
		self:Update("OpenAllBags")
	end)
	self:SecureHook("CloseAllBags", function()
		-- Only update if we're not in combat
		if not self.inCombat then
			self:Update("CloseAllBags")
		end
	end)
	self.hooksInitialized = true
	debug("All hooks established")
end

-- Register essential event handlers - STUB for backward compatibility
-- TODO: Update all module references to call UpdateSystem:RegisterEventHandlers() directly
function addon:RegisterEventHandlers()
	debug("RegisterEventHandlers called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.RegisterEventHandlers then
		UpdateSystem:RegisterEventHandlers()
		return
	end

	-- Legacy implementation if UpdateSystem module isn't available
	-- Core gameplay events
	self:RegisterEvent("BAG_UPDATE", function()
		if not self.inCombat then
			self:Update("BAG_UPDATE")
		end
	end)
	self:RegisterEvent("BAG_UPDATE_COOLDOWN", function()
		if not self.inCombat then
			self:Update("BAG_UPDATE_COOLDOWN")
		end
	end)
	-- Bank events
	self:RegisterEvent("BANKFRAME_OPENED", function()
		self:Update("BANKFRAME_OPENED")
	end)
	self:RegisterEvent("BANKFRAME_CLOSED", function()
		self:Update("BANKFRAME_CLOSED")
	end)
	-- Add this event handler
	self:RegisterEvent("CURRENCY_DIMENSIONS_UPDATED", function(dimensions)
		if not self.inCombat and self:IsAnyBagVisible() then
			self:Update("CURRENCY_DIMENSIONS_UPDATED")
		end
	end)
	-- Item events (only update when not in combat)
	self:RegisterEvent("ITEM_LOCK_CHANGED", function()
		if not self.inCombat then
			self:Update("ITEM_LOCK_CHANGED")
		end
	end)
	-- Handle ElvUI profile changes
	self:RegisterEvent("ELVUI_CONFIG_CHANGED", function()
		self:HandleProfileChange()
	end)
	debug("All event handlers registered")
end

-- Handle ElvUI profile changes
function addon:HandleProfileChange()
	debug("ElvUI profile changed - restoring addon settings")
	-- Ensure our settings structure exists with proper defaults
	if not E.db.bagCustomizer then
		-- If P.bagCustomizer exists, use it as the source of defaults
		if P.bagCustomizer then
			E.db.bagCustomizer = CopyTable(P.bagCustomizer)
			debug("Restored from ElvUI profile defaults")
		else
			-- Otherwise use our addon defaults
			E.db.bagCustomizer = CopyTable(addon.defaults)
			debug("Restored from addon defaults")
		end
	else
		-- Ensure all expected settings exist
		for key, defaultValue in pairs(addon.defaults) do
			if E.db.bagCustomizer[key] == nil then
				if type(defaultValue) == "table" then
					E.db.bagCustomizer[key] = CopyTable(defaultValue)
				else
					E.db.bagCustomizer[key] = defaultValue
				end
			end
		end
	end

	-- Re-initialize debug file settings if they don't exist
	if not E.db.bagCustomizer.debugLuaFiles then
		E.db.bagCustomizer.debugLuaFiles = {}
		if self.debugLuaFiles then
			for file in pairs(self.debugLuaFiles) do
				E.db.bagCustomizer.debugLuaFiles[file] = true
			end
		end
	end

	-- Clear module cache on profile changes
	self:ClearModuleCache()
	-- Update UI if bags are visible
	if self:IsAnyBagVisible() then
		self:Update("ProfileChanged", true)
	end

	-- Trigger profile change event for modules
	self:TriggerEvent("PROFILE_CHANGED")
	debug("Profile change handling complete")
end

-- NEW FUNCTION: Set up proper hooks to ElvUI's profile system
function addon:SetupProfileSystem()
	-- Copy our defaults to ElvUI's profile system if not already done
	if not P.bagCustomizer then
		P.bagCustomizer = CopyTable(addon.defaults)
		debug("Registered default settings with ElvUI profile system")
	end

	-- Hook directly into ElvUI's profile system
	-- This is the most reliable way to detect profile changes
	hooksecurefunc(E, "UpdateDB", function()
		self:HandleProfileChange()
	end)
	-- Use reliable events as backup to catch any changes
	-- This replaces the non-existent ELVUI_CONFIG_UPDATED event
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(0.5, function()
			self:HandleProfileChange()
		end)
	end)
	-- Also register for loading screen end as another backup
	self:RegisterEvent("LOADING_SCREEN_DISABLED", function()
		C_Timer.After(0.5, function()
			self:HandleProfileChange()
		end)
	end)
	debug("Profile system initialized")
end

-- Handle first bag open
function addon:OnFirstBagOpen()
	-- Only run once
	if self.bagsInitialized then return end

	-- Check if bags exist yet
	if not B.BagFrame then
		debug("OnFirstBagOpen called but no container frame found, deferring initialization")
		return
	end

	debug("First bag open detected - completing initialization")
	self.bagsInitialized = true
	-- Complete initialization
	self:SetupHooks()
	self:RegisterEventHandlers()
	-- Single update call with slight delay for safety
	C_Timer.After(0.5, function()
		self:Update("Initial update", true)
	end)
	-- Trigger event for bag initialization
	self:TriggerEvent("BAGS_INITIALIZED")
end

-- Update function - STUB that calls UpdateSystem version
-- TODO: Update all references to call UpdateSystem:Update() directly
function addon:Update(source, force)
	debug("Update called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.Update then
		UpdateSystem:Update(source, force)
		return
	end

	-- Legacy implementation if UpdateSystem module isn't available
	if not self.bagsInitialized and not force then return end

	-- Skip updates when ElvUI options are being manipulated
	if _G.ElvUI_OptionsUI and _G.ElvUI_OptionsUI.OpeningOrClosing then
		debug("Skipping update while ElvUI options are being modified")
		return
	end

	-- Don't stack updates, use a single timer
	if self.updateTimer then
		self.updateTimer:Cancel()
		self.updateTimer = nil
	end

	-- Create a single timer for the update
	self.updateTimer = C_Timer.NewTimer(0.1, function()
		self:ExecuteUpdate(source)
		self.updateTimer = nil
	end)
	-- Trigger update event
	self:TriggerEvent("UPDATE_REQUESTED", source, force)
end

-- Execute the actual update - STUB for backward compatibility
-- TODO: Update references to call UpdateSystem:ExecuteUpdate() directly
function addon:ExecuteUpdate(source)
	debug("ExecuteUpdate called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.ExecuteUpdate then
		UpdateSystem:ExecuteUpdate(source)
		return
	end

	debug("Executing update from: " .. tostring(source))
	-- Update bag frame
	if B.BagFrame and B.BagFrame:IsShown() then
		-- Call element update callbacks
		for elementName, updateFunc in pairs(self.elementUpdateCallbacks) do
			if updateFunc then
				updateFunc(B.BagFrame)
			end
		end
	end

	-- Update bank frame
	if B.BankFrame and B.BankFrame:IsShown() then
		-- Call element update callbacks
		for elementName, updateFunc in pairs(self.elementUpdateCallbacks) do
			if updateFunc then
				updateFunc(B.BankFrame)
			end
		end
	end

	-- Trigger event for update complete
	self:TriggerEvent("UPDATE_COMPLETE", source)
end

-- Combat optimization - STUB that calls UpdateSystem version
-- TODO: Update all module references to call UpdateSystem:OptimizeForCombat() directly
function addon:OptimizeForCombat()
	debug("OptimizeForCombat called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.OptimizeForCombat then
		UpdateSystem:OptimizeForCombat()
		return
	end

	-- Legacy implementation if UpdateSystem module isn't available
	self.inCombat = true
	debug("Entering combat - optimizing addon performance")
	-- Cancel any pending updates
	if self.updateTimer then
		self.updateTimer:Cancel()
		self.updateTimer = nil
	end

	-- Cancel any other timers that might be running
	if self.borderRefreshTimer then
		self.borderRefreshTimer:Cancel()
		self.borderRefreshTimer = nil
	end

	-- Trigger combat state change event
	self:TriggerEvent("COMBAT_STARTED")
end

-- Restore from combat optimizations - STUB that calls UpdateSystem version
-- TODO: Update all module references to call UpdateSystem:RestoreFromCombat() directly
function addon:RestoreFromCombat()
	debug("RestoreFromCombat called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.RestoreFromCombat then
		UpdateSystem:RestoreFromCombat()
		return
	end

	-- Legacy implementation if UpdateSystem module isn't available
	self.inCombat = false
	debug("Exiting combat - restoring addon functionality")
	-- Only update if bags are visible
	if self:IsAnyBagVisible() then
		self:Update("CombatEnd", true)
	end

	-- Trigger combat state change event
	self:TriggerEvent("COMBAT_ENDED")
end

-- Initialize modules in correct sequence
function addon:InitializeModules()
	debug("Initializing modules")
	-- Define module initialization order
	local moduleOrder = {

		"themeManager",            -- Theme manager for settings

		"mainTextures",            -- Textures needed by other modules

		"inventoryBackgroundAdjust", -- Background before other visual elements

		"inventorySlots",          -- Before bindText

		"miscTextures",            -- After Textures

		"bindText",                -- After inventorySlots

		"searchBar",               -- Last UI element

		"miscBorders",

		"frameHeight",

	}
	-- Initialize modules in order
	for _, moduleName in ipairs(moduleOrder) do
		if self.elements[moduleName] and self.elements[moduleName].Initialize then
			debug("Initializing module: " .. moduleName)
			self.elements[moduleName]:Initialize()
		end
	end

	-- Single layout update after initialization
	C_Timer.After(0.5, function()
		for elementName, element in pairs(self.elements) do
			if element.UpdateLayout then
				element:UpdateLayout()
			end
		end
	end)
	debug("All modules initialized")
	-- Trigger modules initialized event
	self:TriggerEvent("MODULES_INITIALIZED")
end

-- Memory cleanup - STUB that calls ResourceManager version
-- TODO: Update all references to call ResourceManager:CleanupMemory() directly
function addon:CleanupMemory(deep)
	debug("CleanupMemory called from Core - redirecting to ResourceManager")
	local ResourceManager = self:GetCachedModule("resourceManager")
	if ResourceManager and ResourceManager.CleanupMemory then
		ResourceManager:CleanupMemory(deep)
		return
	end

	-- If ResourceManager is not available, perform a basic cleanup
	collectgarbage("collect")
	debug("Basic memory cleanup performed (ResourceManager not available)")
end

-- Clean up unused pool objects - STUB that calls ResourceManager version
-- TODO: Update all references to call ResourceManager:CleanUnusedPoolObjects() directly
function addon:CleanUnusedPoolObjects()
	debug("CleanUnusedPoolObjects called from Core - redirecting to ResourceManager")
	local ResourceManager = self:GetCachedModule("resourceManager")
	if ResourceManager and ResourceManager.CleanUnusedPoolObjects then
		ResourceManager:CleanUnusedPoolObjects()
		return
	end

	-- If ResourceManager is not available, perform a basic cleanup
	collectgarbage("collect")
	debug("Basic unused objects cleanup performed (ResourceManager not available)")
end

-- Initialize addon
function addon:Initialize()
	-- Perform ESSENTIAL setup first, even if in combat
	-- 1. Ensure the main DB table exists
	if not E.db.bagCustomizer then
		E.db.bagCustomizer = {}
		debug("Core Initialize: Created E.db.bagCustomizer table.")
	end

	-- 2. Ensure essential flags/settings exist using defaults
	-- Make sure addon.defaults is available here, might need loading earlier if not
	if addon.defaults then
		-- Ensure 'enabled' exists, default to true? or false? Check your defaults.
		if E.db.bagCustomizer.enabled == nil then
			E.db.bagCustomizer.enabled = addon.defaults.enabled -- Or true/false directly
			debug("Core Initialize: Set default 'enabled' state: " .. tostring(E.db.bagCustomizer.enabled))
		end

		-- Ensure 'debug' exists
		if E.db.bagCustomizer.debug == nil then
			E.db.bagCustomizer.debug = addon.defaults.debug or false
			debug("Core Initialize: Set default 'debug' state: " .. tostring(E.db.bagCustomizer.debug))
		end

		-- Add any other absolutely critical flags needed before full init
	else
		-- Fallback if defaults aren't loaded yet (less ideal)
		if E.db.bagCustomizer.enabled == nil then E.db.bagCustomizer.enabled = true end

		if E.db.bagCustomizer.debug == nil then E.db.bagCustomizer.debug = false end

		debug("Core Initialize: WARNING - addon.defaults not found, using hardcoded basic settings.")
	end

	-- Now check for combat
	if UnitAffectingCombat("player") then
		debug("Player is in combat - delaying full initialization")
		-- Ensure event is registered only once if Initialize is somehow called again
		if not addon._combatInitPending then
			addon:RegisterEvent("PLAYER_REGEN_ENABLED", function()
				-- Check if already unregistered or handled to prevent errors
				if not addon._combatInitPending then return end

				addon:UnregisterEvent("PLAYER_REGEN_ENABLED")
				addon._combatInitPending = false -- Mark as handled
				debug("Combat ended - proceeding with full initialization")
				addon:Initialize()           -- Call Initialize AGAIN after combat drops
			end)
			addon._combatInitPending = true -- Mark as pending
		end

		return -- Exit Initialize early, but essential DB setup is done
	end

	-- Clear the flag if we proceeded without being in combat
	addon._combatInitPending = false
	-- === FULL INITIALIZATION (Only runs if NOT in combat initially, or on the second call after combat) ===
	debug("Addon Initialization - Proceeding with full setup.")
	-- Set up initial state (safe to run again if called post-combat)
	addon.texturePool = {}
	addon.framePool = {}
	addon.loadedModules = {} -- Resetting these might be needed if called post-combat
	addon.moduleCache = {}
	collectgarbage("collect")
	-- Initialize the event system FIRST (safe to run again)
	InitializeEventSystem()
	-- Add hook to detect ElvUI settings panel opening and closing (safe to run again)
	if E.Libs and E.Libs.AceConfigDialog and not addon._aceHooked then -- Add flag to prevent duplicate hooks
		addon:SecureHook(E.Libs.AceConfigDialog, "Open", function()
			-- ... (rest of AceConfigDialog Open hook) ...
		end)
		addon:SecureHook(E.Libs.AceConfigDialog, "Close", function()
			-- ... (rest of AceConfigDialog Close hook) ...
		end)
		addon._aceHooked = true
	end

	-- Initialize full settings structure (safe to run again)
	-- This will ensure the rest of the settings exist after combat drops
	if addon.defaults then
		addon:EnsureSettings(addon.defaults, E.db.bagCustomizer)
	end

	-- Setup Profile System (safe to run again, hooks have internal checks or use SecureHook)
	addon:SetupProfileSystem()
	-- Initialize debug settings (safe to run again)
	addon:InitializeDebugSettings()
	-- Pre-cache Textures (safe to run again)
	addon:PreCacheCommonTextures()
	-- Initialize modules (safe to run again, GetModule has checks)
	addon:InitializeModules()
	-- Register with ElvUI (safe to run again, EP:RegisterPlugin likely handles duplicates)
	if EP and EP.RegisterPlugin then
		EP:RegisterPlugin("BagCustomizer_for_ElvUI", addon.InsertOptions)
	end

	-- Set up hooks to complete initialization on first bag open (safe to run again, SecureHook prevents duplicates)
	addon:SecureHook("OpenBackpack", function() addon:OnFirstBagOpen() end)
	addon:SecureHook("OpenAllBags", function() addon:OnFirstBagOpen() end)
	addon:SecureHook("ToggleAllBags", function() addon:OnFirstBagOpen() end)
	addon:RegisterEvent("BANKFRAME_OPENED", function() addon:OnFirstBagOpen() end) -- RegisterEvent safe
	-- Register essential events (safe to run again, RegisterEvent handles duplicates)
	-- No need to re-register PLAYER_REGEN_*, they are handled by the combat check block
	addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		addon.firstTimeOpens = { bags = true, bank = true, warbandBank = true }
		C_Timer.After(1, function()
			addon:Update("PLAYER_ENTERING_WORLD event", true)
		end)
		debug("Player entering world processed")
	end)
	addon:RegisterEvent("ADDON_LOADED", function(_, addonName)
		if addonName == "BagCustomizer_for_ElvUI" or addonName == "ElvUI" then
			C_Timer.After(0.5, function()
				addon:Update("ADDON_LOADED event: " .. addonName, true)
			end)
			debug("Addon loaded: " .. addonName)
		end
	end)
	-- Do NOT register combat handlers here, they are handled by Optimize/Restore now
	-- Set up periodic memory cleanup (safe to run again, cancels previous timer)
	if addon.memoryCleanupTimer then
		addon.memoryCleanupTimer:Cancel()
	end

	addon.memoryCleanupTimer = C_Timer.NewTicker(120, function()
		collectgarbage("step", 500)
	end)
	debug("Full initialization complete.")
	addon:TriggerEvent("INITIALIZATION_COMPLETE")
end

-- Module cleanup
function addon:CleanupModules()
	debug("Cleaning up all modules")
	-- Notify modules of pending cleanup
	self:TriggerEvent("MODULES_CLEANUP_STARTED")
	-- Cleanup in reverse dependency order
	for _, moduleName in ipairs({

		"bindText", "miscTextures", "inventorySlots",

		"searchBar", "inventoryBackgroundAdjust", "mainTextures",

		"themeManager",

	}) do
		if self.elements[moduleName] and self.elements[moduleName].Cleanup then
			debug("Cleaning up module: " .. moduleName)
			self.elements[moduleName]:Cleanup()
		end
	end

	-- Clean up resource pools
	self.texturePool = {}
	self.framePool = {}
	self.moduleCache = {}
	collectgarbage("collect")
	debug("Module cleanup complete")
	-- Trigger cleanup complete event
	self:TriggerEvent("MODULES_CLEANUP_COMPLETED")
end

-- PreCacheCommonTextures - STUB for backward compatibility
-- TODO: Update references to call ResourceManager:PreCacheCommonTextures() directly
function addon:PreCacheCommonTextures()
	debug("PreCacheCommonTextures called from Core - redirecting to ResourceManager")
	local ResourceManager = self:GetCachedModule("resourceManager")
	if ResourceManager and ResourceManager.PreCacheCommonTextures then
		ResourceManager:PreCacheCommonTextures()
		return
	end

	debug("ResourceManager not available for PreCacheCommonTextures")
end

-- Add proper ApplyMinimapBorder stub that will be called from Options.lua
function addon:ApplyMinimapBorder()
	debug("ApplyMinimapBorder called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.ApplyMinimapBorder then
		UpdateSystem:ApplyMinimapBorder()
		return
	end

	-- Fallback implementation if UpdateSystem module isn't loaded yet
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
		-- Use MiscBorders module if available
		local MiscBorders = self:GetCachedModule("miscBorders")
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

function addon:DebouncedUpdate(reason, immediate)
	debug("DebouncedUpdate called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem") -- Fixed typo
	if UpdateSystem and UpdateSystem.DebouncedUpdate then
		UpdateSystem:DebouncedUpdate(reason, immediate)
		return
	end

	-- Fallback to Update if UpdateSystem module isn't loaded yet
	self:Update(reason, immediate)
end

-- ApplyChanges with fixed typo
function addon:ApplyChanges()
	debug("ApplyChanges called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.ApplyChanges then -- Fixed method name
		UpdateSystem:ApplyChanges()
		return
	end

	-- Fallback to Update if UpdateSystem module isn't loaded yet
	self:Update("ApplyChanges", true)
end

-- Add proper FullUpdate stub that will be called from Options.lua
function addon:FullUpdate()
	debug("FullUpdate called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.FullUpdate then
		UpdateSystem:FullUpdate()
		return
	end

	-- Fallback to Update if UpdateSystem module isn't loaded yet
	self:Update("FullUpdate", true)
end

-- Add proper ThrottledUpdate stub that will be called from Options.lua
function addon:ThrottledUpdate()
	debug("ThrottledUpdate called from Core - redirecting to UpdateSystem")
	local UpdateSystem = self:GetCachedModule("updateSystem")
	if UpdateSystem and UpdateSystem.ThrottledUpdate then
		UpdateSystem:ThrottledUpdate()
		return
	end

	-- Fallback to Update if UpdateSystem module isn't loaded yet
	self:Update("ThrottledUpdate", false)
end

-- EnsureSettings - Keep in Core since Settings module may depend on it
function addon:EnsureSettings(defaults, current)
	if type(defaults) ~= "table" then return end

	if type(current) ~= "table" then current = {} end

	for k, v in pairs(defaults) do
		if type(v) == "table" then
			if current[k] == nil then
				current[k] = {}
			elseif type(current[k]) ~= "table" then
				current[k] = {}
			end

			-- Recursively ensure settings for nested tables
			self:EnsureSettings(v, current[k])
		elseif current[k] == nil then
			-- For primitive types, simply copy if missing
			current[k] = v
		end
	end

	debug("Settings ensured and initialized")
	return current
end

-- Register debug slash command
SLASH_BAGCUSTOMIZERDEBUG1 = "/bcdebug"
SlashCmdList["BAGCUSTOMIZERDEBUG"] = function()
	local addon = E:GetModule("BagCustomizer")
	if addon then
		addon:DumpDebugSettings()
	end
end
-- Add a slash command to reset debug settings
SLASH_BAGCUSTOMIZERRESET1 = "/bcreset"
SlashCmdList["BAGCUSTOMIZERRESET"] = function()
	local addon = E:GetModule("BagCustomizer")
	if addon then
		addon:ResetDebugSettings()
	end
end
-- Register with ElvUI
E:RegisterModule(addon:GetName())
