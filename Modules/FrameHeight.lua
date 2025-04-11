-- ElvUI Bag Customizer - Frame Height module with Top Border Extension
-- Version: 1.3 (Cleanup & Robustness)
local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule("Bags")
local addon = E:GetModule("BagCustomizer")
local module = {}
addon.elements.frameHeight = module
-- Standardized debug function (Simplified)
local debugPrefix = "|cFF00FF00Bag Customizer ["
local debugSuffix = "][frameHeight]:|r "
local function debug(msg)
	-- Defensive check
	if not E.db or not E.db.bagCustomizer then return end

	-- Check if global debug is enabled
	if not E.db.bagCustomizer.debug then return end

	-- Check if module-specific debug is enabled
	if not E.db.bagCustomizer.frameHeight or
			not E.db.bagCustomizer.frameHeight.debug then
		return
	end

	-- Output the message directly
	local timestamp = date("%H:%M:%S")
	print(debugPrefix .. timestamp .. debugSuffix .. tostring(msg))
end

-- Store extension panels and overlay
local extensionPanels = {}
module.containerOverlay = nil
-- Timer ONLY for UpdateContainerOverlay debounce
module.overlayUpdateTimer = nil
-- Determine if the module is enabled
function module:IsModuleEnabled()
	return E.db.bagCustomizer and E.db.bagCustomizer.enabled ~= false and E.db.bagCustomizer.frameHeight and
			E.db.bagCustomizer.frameHeight.enable
end

-- Debounced function ONLY for updating the overlay (with pcall)
function module:DebouncedUpdateOverlay()
	if self.overlayUpdateTimer then return end -- Already scheduled

	self.overlayUpdateTimer = C_Timer.After(0.01, function()
		local success, err = pcall(function()        -- Wrap logic in pcall
			local timerHandle = module.overlayUpdateTimer -- Capture handle
			module.overlayUpdateTimer = nil            -- Clear handle *before* executing logic
			-- debug("DebouncedUpdateOverlay Timer START") -- Keep if needed
			if not module:IsModuleEnabled() then return end

			local frame = B.BagFrame
			if frame and frame:IsShown() and not addon:IsBankFrame(frame) then
				local panel = extensionPanels["bag"]
				if panel and panel:IsShown() and frame._BCZ_topBorderPanel == panel then
					-- debug("DebouncedUpdateOverlay Timer: Panel valid -> UpdateContainerOverlay")
					module:UpdateContainerOverlay() -- Update Overlay
				else
					-- debug("DebouncedUpdateOverlay Timer: Panel invalid, skipping overlay update.")
					if module.containerOverlay and module.containerOverlay:IsShown() then module.containerOverlay:Hide() end
				end
			else
				-- debug("DebouncedUpdateOverlay Timer: Frame hidden/bank, skipping overlay update.")
				if module.containerOverlay and module.containerOverlay:IsShown() then module.containerOverlay:Hide() end
			end

			-- debug("DebouncedUpdateOverlay Timer END")
		end)
		if not success then
			print(debugPrefix .. " ERROR in DebouncedUpdateOverlay Timer: " .. tostring(err))
			-- Ensure timer handle is cleared even on error if pcall didn't reach that line
			if module.overlayUpdateTimer then module.overlayUpdateTimer = nil end
		end
	end)
end

function module:Initialize()
	debug("Initialize START")
	self.hooksSet = false
	self:SetupHooks()
	self:CreateContainerOverlay()
	self:SetupEvents()
	if addon.RegisterForEvent then
		addon:RegisterForEvent("BACKGROUND_COLOR_CHANGED", function()
			-- debug("BACKGROUND_COLOR_CHANGED event -> UpdatePanelColors, DebouncedUpdateOverlay")
			self:UpdatePanelColors()
			self:DebouncedUpdateOverlay()
		end)
	end

	if addon.Update then
		hooksecurefunc(addon, "Update", function()
			if B.BagFrame and B.BagFrame:IsShown() and not addon:IsBankFrame(B.BagFrame) then
				module:CreateTopBorderPanel()
				module:DebouncedUpdateOverlay()
			else
				if module.containerOverlay and module.containerOverlay:IsShown() then
					module.containerOverlay:Hide()
				end
			end
		end)
	end

	if addon.RevertAllCustomizations then
		hooksecurefunc(addon, "RevertAllCustomizations",
			function()
				debug("RevertAllCustomizations -> Cleanup"); self:Cleanup()
			end)
	end

	debug("Initialize END")
end

function module:SetupEvents()
	-- debug("SetupEvents START") -- Less critical debug
	addon:RegisterEvent("PLAYER_ENTERING_WORLD", function() self:HandleBagEvent("PLAYER_ENTERING_WORLD") end)
	addon:RegisterEvent("BAG_UPDATE_DELAYED", function() self:HandleBagEvent("BAG_UPDATE_DELAYED") end)
	addon:RegisterEvent("BAG_OPEN", function() self:HandleBagEvent("BAG_OPEN") end)
	addon:RegisterEvent("BAG_CLOSED", function() self:HandleBagEvent("BAG_CLOSED") end)
	-- debug("SetupEvents END") -- Less critical debug
end

function module:HandleBagEvent(event)
	-- debug("HandleBagEvent START: " .. event) -- Can be spammy
	if addon.inCombat and event ~= "BAG_OPEN" then return end

	if not self:IsModuleEnabled() then
		self:Cleanup(); return
	end

	if event == "BAG_OPEN" then
		-- debug("HandleBagEvent(BAG_OPEN) -> CreatePanel, DebouncedOverlay")
		if not self.containerOverlay then self:CreateContainerOverlay() end

		local panel = self:CreateTopBorderPanel()
		if panel then self:DebouncedUpdateOverlay() end
	elseif event == "BAG_CLOSED" then
		-- debug("HandleBagEvent(BAG_CLOSED) -> Immediate Hide/Remove")
		if self.overlayUpdateTimer then
			C_Timer.Cancel(self.overlayUpdateTimer); self.overlayUpdateTimer = nil
		end

		if self.containerOverlay then self.containerOverlay:Hide() end

		self:RemoveTopBorderPanel()
	else                                   -- Handle BAG_UPDATE_DELAYED / PLAYER_ENTERING_WORLD
		C_Timer.After(0.1, function()
			local success, err = pcall(function() -- Add pcall here too
				-- debug("HandleBagEvent("..event..") Timer START")
				if B.BagFrame and B.BagFrame:IsShown() and not addon:IsBankFrame(B.BagFrame) then
					-- debug("HandleBagEvent("..event..") Timer -> CreatePanel, DebouncedOverlay")
					local panel = module:CreateTopBorderPanel()
					if panel then module:DebouncedUpdateOverlay() end
				else
					-- debug("HandleBagEvent("..event..") Timer: Bags not shown -> Ensure Hidden/Removed")
					if module.overlayUpdateTimer then
						C_Timer.Cancel(module.overlayUpdateTimer); module.overlayUpdateTimer = nil
					end

					if module.containerOverlay and module.containerOverlay:IsShown() then module.containerOverlay:Hide() end

					module:RemoveTopBorderPanel()
				end

				-- debug("HandleBagEvent("..event..") Timer END")
			end)
			if not success then print(debugPrefix .. " ERROR in HandleBagEvent Timer (" .. event .. "): " .. tostring(err)) end
		end)
	end

	-- debug("HandleBagEvent END: " .. event)
end

function module:SetupHooks()
	if self.hooksSet then return end

	debug("SetupHooks START")
	-- Hook Layout -> Immediate Panel Check, Debounced Overlay
	hooksecurefunc(B, "Layout", function(_, isBank)
		if isBank or (addon.inCombat and not (B.BagFrame and B.BagFrame:IsShown())) then return end

		local panel = module:CreateTopBorderPanel()
		if panel then module:DebouncedUpdateOverlay() end
	end)
	-- Hook ToggleBags -> Direct Hide
	if B.ToggleBags then
		hooksecurefunc(B, "ToggleBags", function()
			if not B.BagFrame then return end

			if not B.BagFrame:IsShown() then
				-- debug("ToggleBags Hook: Detected Close -> Immediate Hide/Remove")
				if module.overlayUpdateTimer then
					C_Timer.Cancel(module.overlayUpdateTimer); module.overlayUpdateTimer = nil
				end

				if module.containerOverlay then module.containerOverlay:Hide() end

				module:RemoveTopBorderPanel()
			end
		end)
	end

	-- Hook SetPoint -> Reposition Panel & IMMEDIATE Overlay Update
	if B.BagFrame then
		hooksecurefunc(B.BagFrame, "SetPoint", function(frame)
			if addon:IsBankFrame(frame) then return end

			C_Timer.After(0.05, function()
				local success, err = pcall(function() -- Add pcall
					-- debug("SetPoint Timer START")
					if not frame or not frame:IsShown() or addon:IsBankFrame(frame) then return end

					local panel = extensionPanels["bag"]
					if panel and panel:IsShown() and frame._BCZ_topBorderPanel == panel then
						-- debug("SetPoint Timer: Panel valid -> Reposition Panel & Immediate Overlay Update")
						panel:ClearAllPoints(); panel:SetPoint("BOTTOM", frame, "TOP", 0, 0); panel:SetPoint("LEFT", frame, "LEFT", 0,
							0); panel:SetWidth(frame:GetWidth())
						module:UpdateContainerOverlay()
						if addon.TriggerEvent then addon:TriggerEvent("BAG_FRAME_MOVED", frame) end
					else
						-- debug("SetPoint Timer: Panel invalid -> CreatePanel, DebouncedOverlay")
						local new_panel = module:CreateTopBorderPanel()
						if new_panel then module:DebouncedUpdateOverlay() end
					end

					-- debug("SetPoint Timer END")
				end)
				if not success then print(debugPrefix .. " ERROR in SetPoint Timer: " .. tostring(err)) end
			end)
		end)
		-- Hook OnSizeChanged -> IMMEDIATE Overlay Update
		local sizeChangedHookFlag = "_BCZ_FrameHeightHooked_v1_3_Size"
		if not B.BagFrame[sizeChangedHookFlag] then
			B.BagFrame:HookScript("OnSizeChanged", function(frameSelf)
				local success, err = pcall(function() -- Add pcall
					-- debug("OnSizeChanged START")
					local panel = extensionPanels["bag"]
					if panel and panel:IsShown() and frameSelf._BCZ_topBorderPanel == panel then
						-- debug("OnSizeChanged: Panel valid -> Adjust Panel & Immediate Overlay Update")
						panel:ClearAllPoints(); panel:SetPoint("BOTTOM", frameSelf, "TOP", 0, 0); panel:SetPoint("LEFT", frameSelf,
							"LEFT", 0, 0); panel:SetWidth(frameSelf:GetWidth())
						module:UpdateContainerOverlay()
						if addon.TriggerEvent then addon:TriggerEvent("BAG_FRAME_RESIZED", frameSelf) end
					else
						-- debug("OnSizeChanged: Panel invalid -> CreatePanel, Debounced Overlay")
						local new_panel = module:CreateTopBorderPanel()
						if new_panel then module:DebouncedUpdateOverlay() end
					end

					-- debug("OnSizeChanged END")
				end)
				if not success then print(debugPrefix .. " ERROR in OnSizeChanged: " .. tostring(err)) end
			end)
			B.BagFrame[sizeChangedHookFlag] = true
			-- debug("Hooked OnSizeChanged")
		end

		-- Hook OnHide -> Direct Hide
		local hideHookFlag = "_BCZ_OnHideHooked_v1_3_Hide"
		if not B.BagFrame[hideHookFlag] then
			B.BagFrame:HookScript("OnHide", function()
				-- debug("Frame OnHide Hook -> Hiding Overlay")
				if module.overlayUpdateTimer then
					C_Timer.Cancel(module.overlayUpdateTimer); module.overlayUpdateTimer = nil
				end

				if module.containerOverlay then module.containerOverlay:Hide() end
			end)
			B.BagFrame[hideHookFlag] = true
			-- debug("Hooked OnHide")
		end
	end

	-- Hook Background Update -> Colors + Debounced Overlay
	if addon.elements.background and addon.elements.background.UpdateAll then
		hooksecurefunc(addon.elements.background, "UpdateAll", function()
			self:UpdatePanelColors()
			self:DebouncedUpdateOverlay()
		end)
	end

	-- Hook Settings Change -> Remove + Create + Debounced Overlay
	if E.Options and E.Options.args.bagCustomizer and E.Options.args.bagCustomizer.args.frameHeight and E.Options.args.bagCustomizer.args.frameHeight.args.bagSpacing then
		local originalSet = E.Options.args.bagCustomizer.args.frameHeight.args.bagSpacing.set
		E.Options.args.bagCustomizer.args.frameHeight.args.bagSpacing.set = function(info, value)
			if originalSet then originalSet(info, value) else E.db.bagCustomizer.frameHeight.bagSpacing = value end

			self:RemoveTopBorderPanel()
			local panel = self:CreateTopBorderPanel()
			if panel then self:DebouncedUpdateOverlay() end
		end
		-- debug("Hooked Settings")
	end

	self.hooksSet = true
	debug("SetupHooks END")
end

-- Get the correct background color to use
function module:GetBackgroundColor()
	-- Check if InventoryBackgroundAdjust module is enabled and use its color if available
	if E.db.bagCustomizer and
			E.db.bagCustomizer.inventoryBackgroundAdjust and
			E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor and
			E.db.bagCustomizer.inventoryBackgroundAdjust.color then
		local color = E.db.bagCustomizer.inventoryBackgroundAdjust.color
		local opacity = E.db.bagCustomizer.inventoryBackgroundAdjust.opacity or 1
		return color.r, color.g, color.b, opacity
	else
		-- Use ElvUI default color
		local defaultColor = E.media.backdropcolor
		return defaultColor[1], defaultColor[2], defaultColor[3], 1
	end
end

function module:UpdatePanelColors()
	for key, panel in pairs(extensionPanels) do
		if panel and panel:IsShown() then
			local r, g, b, a = self:GetBackgroundColor()
			if panel.bg then panel.bg:SetColorTexture(r, g, b, a) end
		end
	end

	-- debug("Updated panel colors") -- Less critical debug
end

function module:CreateContainerOverlay()
	-- debug("CreateContainerOverlay START") -- Less critical debug
	if not self:IsModuleEnabled() then
		if self.containerOverlay then self.containerOverlay:Hide() end; return
	end

	local bagFrame = B.BagFrame
	if not bagFrame or addon:IsBankFrame(bagFrame) then return end

	if not self.containerOverlay then
		-- debug("CreateContainerOverlay: Creating NEW Frame")
		self.containerOverlay = CreateFrame("Frame", "ElvUIBagCustomizer_ContainerOverlay", UIParent)
		local bg = addon:GetPooledTexture(self.containerOverlay, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0,
			0); self.containerOverlay.bg = bg
		self.containerOverlay:EnableMouse(false)
		self.containerOverlay:Hide()
	end

	self.containerOverlay:SetFrameStrata(bagFrame:GetFrameStrata())
	self.containerOverlay:SetFrameLevel(bagFrame:GetFrameLevel() + 1)
	if addon.TriggerEvent then addon:TriggerEvent("CONTAINER_OVERLAY_CREATED", self.containerOverlay) end

	-- debug("CreateContainerOverlay END")
	return self.containerOverlay
end

function module:UpdateContainerOverlay()
	-- debug("UpdateContainerOverlay START") -- Can be spammy
	if not self.containerOverlay then
		self:CreateContainerOverlay(); return
	end

	if not self:IsModuleEnabled() then
		if self.containerOverlay:IsShown() then self.containerOverlay:Hide() end; return
	end

	local bagFrame = B.BagFrame
	if not bagFrame or addon:IsBankFrame(bagFrame) then
		if self.containerOverlay:IsShown() then self.containerOverlay:Hide() end; return
	end

	if not bagFrame:IsShown() then
		if self.containerOverlay:IsShown() then self.containerOverlay:Hide() end; return
	end

	local fhPanel = extensionPanels["bag"]
	if not fhPanel or not fhPanel:IsShown() or bagFrame._BCZ_topBorderPanel ~= fhPanel then
		if self.containerOverlay:IsShown() then self.containerOverlay:Hide() end; return
	end

	-- Position and Show
	self.containerOverlay:ClearAllPoints()
	self.containerOverlay:SetPoint("BOTTOMLEFT", bagFrame, "BOTTOMLEFT", 0, 0)
	self.containerOverlay:SetPoint("TOPRIGHT", fhPanel, "TOPRIGHT", 0, 0)
	self.containerOverlay:Show()
	if addon.TriggerEvent then addon:TriggerEvent("CONTAINER_OVERLAY_UPDATED", self.containerOverlay) end

	-- debug("UpdateContainerOverlay END")
end

function module:CreateTopBorderPanel()
	local frame = B.BagFrame
	-- debug("CreateTopBorderPanel START") -- Can be spammy
	if not self:IsModuleEnabled() then
		self:RemoveTopBorderPanel(); return nil
	end

	if not frame or addon:IsBankFrame(frame) or not frame:IsShown() then return nil end

	local key = "bag"; local existingPanel = extensionPanels[key]
	if existingPanel and existingPanel:IsShown() and frame._BCZ_topBorderPanel == existingPanel then
		if existingPanel:GetWidth() ~= frame:GetWidth() then existingPanel:SetWidth(frame:GetWidth()) end

		existingPanel:ClearAllPoints(); existingPanel:SetPoint("BOTTOM", frame, "TOP", 0, 0); existingPanel:SetPoint("LEFT",
			frame, "LEFT", 0, 0)
		return existingPanel
	end

	if existingPanel or frame._BCZ_topBorderPanel then self:RemoveTopBorderPanel(); end

	local spacing = E.db.bagCustomizer.frameHeight.bagSpacing or 45
	local panel = CreateFrame("Frame", "ElvUIBagCustomizer_TopBorderPanel_" .. key, frame)
	panel:SetFrameStrata(frame:GetFrameStrata()); panel:SetFrameLevel(frame:GetFrameLevel())
	panel:SetWidth(frame:GetWidth()); panel:SetHeight(spacing);
	panel:SetPoint("BOTTOM", frame, "TOP", 0, 0); panel:SetPoint("LEFT", frame, "LEFT", 0, 0)
	local bg = addon:GetPooledTexture(panel, "BACKGROUND"); bg:SetAllPoints(); panel.bg = bg
	local r, g, b, a = self:GetBackgroundColor(); bg:SetColorTexture(r, g, b, a)
	panel:EnableMouse(true)
	panel:SetScript("OnMouseDown",
		function(self, button)
			if button == "LeftButton" and IsShiftKeyDown() then
				local frame = B.BagFrame; self.movingStartX, self.movingStartY = GetCursorPosition(); self.frameStartX = frame
						:GetLeft(); self.frameStartY = frame:GetTop(); self.customMoving = true; self:SetScript("OnUpdate",
					function(self, elapsed)
						if self.customMoving then
							local cursorX, cursorY = GetCursorPosition(); local deltaX = (cursorX - self.movingStartX) /
									UIParent:GetScale(); local deltaY = (cursorY - self.movingStartY) / UIParent:GetScale(); frame
									:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.frameStartX + deltaX,
								self.frameStartY + deltaY)
						end
					end)
			elseif (button == "LeftButton" or button == "RightButton") and IsControlKeyDown() then
				module:ResetFramePosition()
			end
		end)
	panel:SetScript("OnMouseUp",
		function(self, button)
			if button == "LeftButton" and self.customMoving then
				self.customMoving = false; self:SetScript("OnUpdate", nil); C_Timer.After(0.1,
					function()
						local success, err = pcall(module.UpdateContainerOverlay, module); if not success then
							print(debugPrefix ..
								" MouseUp Timer ERROR: " .. tostring(err))
						end; if addon.TriggerEvent then
							addon:TriggerEvent(
								"BAG_FRAME_MOVED", B.BagFrame)
						end
					end)
			end
		end)
	extensionPanels[key] = panel
	frame._BCZ_topBorderPanel = panel
	-- debug("Created top border panel") -- Less critical debug
	if addon.TriggerEvent then addon:TriggerEvent("TOP_BORDER_PANEL_CREATED", panel, frame) end

	-- debug("CreateTopBorderPanel END")
	return panel
end

function module:ResetFramePosition()
	-- debug("ResetFramePosition START")
	local frame = B.BagFrame
	if frame and frame.mover then
		frame:ClearAllPoints(); frame:SetPoint(frame.mover.POINT or "BOTTOMRIGHT", frame.mover)
		local panel = self:CreateTopBorderPanel()
		if panel then self:DebouncedUpdateOverlay() end

		if addon.TriggerEvent then addon:TriggerEvent("BAG_FRAME_POSITION_RESET", frame) end
	end

	-- debug("ResetFramePosition END")
end

function module:RemoveTopBorderPanel()
	-- debug("RemoveTopBorderPanel START")
	if self.overlayUpdateTimer then
		C_Timer.Cancel(self.overlayUpdateTimer); self.overlayUpdateTimer = nil
	end

	local key = "bag"; local panel = extensionPanels[key]; local frame = B.BagFrame
	if panel then
		if addon.TriggerEvent then addon:TriggerEvent("TOP_BORDER_PANEL_REMOVED", panel) end

		addon:ReleaseFrame(panel, "Frame"); extensionPanels[key] = nil
		if frame and frame._BCZ_topBorderPanel == panel then frame._BCZ_topBorderPanel = nil end
	elseif frame and frame._BCZ_topBorderPanel then
		local orphanedPanel = frame._BCZ_topBorderPanel
		addon:ReleaseFrame(orphanedPanel, "Frame"); frame._BCZ_topBorderPanel = nil
	end

	-- debug("RemoveTopBorderPanel END")
end

function module:UpdateLayout()
	-- debug("UpdateLayout START")
	if not self:IsModuleEnabled() then
		self:Cleanup(); return
	end

	self:RemoveTopBorderPanel()
	local panel = self:CreateTopBorderPanel()
	if not self.containerOverlay then self:CreateContainerOverlay() end

	if panel then self:DebouncedUpdateOverlay() end

	-- debug("UpdateLayout END")
end

function module:Cleanup()
	debug("Cleanup START")
	if self.overlayUpdateTimer then
		C_Timer.Cancel(self.overlayUpdateTimer); self.overlayUpdateTimer = nil
	end

	if self.containerOverlay then
		self.containerOverlay:Hide()
		if addon.ReleaseFrame then addon:ReleaseFrame(self.containerOverlay, "Frame") end

		self.containerOverlay = nil
	end

	self:RemoveTopBorderPanel()
	self.hooksSet = false
	debug("Cleanup END")
end

return module
