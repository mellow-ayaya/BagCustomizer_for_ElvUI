--[[
    Bag Customizer for ElvUI
    Copyright (C) 2025 Mellow_ayaya

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
-- Bag Customizer for ElvUI - Options.lua
local E, L, V, P, G = unpack(ElvUI)
local addon = E:GetModule("BagCustomizer")
-- Helper functions for options creation
local function EnsureSettings(path)
	if not E.db.bagCustomizer then E.db.bagCustomizer = {} end

	if path and not E.db.bagCustomizer[path] then
		E.db.bagCustomizer[path] = {}
	end

	return path and E.db.bagCustomizer[path] or E.db.bagCustomizer
end

local function CreateHeaderGroup(name, order)
	return {
		order = order,
		type = "group",
		name = name,
		guiInline = true,
		args = {},
	}
end

-- Throttle for CurrencyAndTextures
local throttleTimer = nil
local function ThrottleUpdate()
	if throttleTimer then
		throttleTimer:Cancel()
		throttleTimer = nil
	end

	throttleTimer = C_Timer.NewTimer(0.1, function()
		local BCurrency = addon.elements.currencyAndTextures
		if BCurrency and BCurrency.UpdateSettings then
			BCurrency:UpdateSettings()
		end
	end)
end

-------------------------------------------
-- Modular options section start
-------------------------------------------
-- Debug
local function CreateDebugOptions()
	local debugOptions = {
		order = 900,
		type = "group",
		name = "Debug",
		guiInline = true,
		args = {
			header = {
				order = 1,
				type = "header",
				name = "Debug Settings",
			},
			description = {
				order = 2,
				type = "description",
				name = "Configure debugging for BagCustomizer modules. Debug messages appear in the chat window.",
			},
			masterToggle = {
				order = 3,
				type = "toggle",
				name = "Enable Debugging",
				desc =
				"Master toggle for all debugging. When disabled, no debug messages will appear regardless of module settings.",
				width = "full",
				get = function() return E.db.bagCustomizer.debug end,
				set = function(_, value)
					E.db.bagCustomizer.debug = value
					if value then
						print("|cFF00FF00Bag Customizer:|r Debug mode enabled.")
					else
						print("|cFF00FF00Bag Customizer:|r Debug mode disabled.")
					end
				end,
			},
			moduleHeader = {
				order = 10,
				type = "header",
				name = "Module Debug Settings",
			},
			moduleDesc = {
				order = 11,
				type = "description",
				name = "Enable or disable debugging for specific modules:",
			},

			-- Core module debug toggle
			coreModule = {
				order = 20,
				type = "toggle",
				name = "Core",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.core == nil then
						E.db.bagCustomizer.core = {}
					end

					if E.db.bagCustomizer.core.debug == nil then
						E.db.bagCustomizer.core.debug = true
					end

					return E.db.bagCustomizer.core.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.core == nil then
						E.db.bagCustomizer.core = {}
					end

					E.db.bagCustomizer.core.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- Settings module debug toggle
			settingsModule = {
				order = 21,
				type = "toggle",
				name = "Settings",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.settings == nil then
						E.db.bagCustomizer.settings = {}
					end

					if E.db.bagCustomizer.settings.debug == nil then
						E.db.bagCustomizer.settings.debug = true
					end

					return E.db.bagCustomizer.settings.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.settings == nil then
						E.db.bagCustomizer.settings = {}
					end

					E.db.bagCustomizer.settings.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- ResourceManager module debug toggle
			resourceManagerModule = {
				order = 22,
				type = "toggle",
				name = "Resource Manager",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.resourceManager == nil then
						E.db.bagCustomizer.resourceManager = {}
					end

					if E.db.bagCustomizer.resourceManager.debug == nil then
						E.db.bagCustomizer.resourceManager.debug = true
					end

					return E.db.bagCustomizer.resourceManager.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.resourceManager == nil then
						E.db.bagCustomizer.resourceManager = {}
					end

					E.db.bagCustomizer.resourceManager.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- UpdateSystem module debug toggle
			updateSystemModule = {
				order = 23,
				type = "toggle",
				name = "Update System",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.updateSystem == nil then
						E.db.bagCustomizer.updateSystem = {}
					end

					if E.db.bagCustomizer.updateSystem.debug == nil then
						E.db.bagCustomizer.updateSystem.debug = true
					end

					return E.db.bagCustomizer.updateSystem.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.updateSystem == nil then
						E.db.bagCustomizer.updateSystem = {}
					end

					E.db.bagCustomizer.updateSystem.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- FrameHeight module debug toggle
			frameHeightModule = {
				order = 24,
				type = "toggle",
				name = "Bag Height",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.frameHeight == nil then
						E.db.bagCustomizer.frameHeight = {}
					end

					if E.db.bagCustomizer.frameHeight.debug == nil then
						E.db.bagCustomizer.frameHeight.debug = true
					end

					return E.db.bagCustomizer.frameHeight.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.frameHeight == nil then
						E.db.bagCustomizer.frameHeight = {}
					end

					E.db.bagCustomizer.frameHeight.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- Background module debug toggle
			inventoryBackgroundAdjustModule = {
				order = 25,
				type = "toggle",
				name = "InventoryBackgroundAdjust",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.inventoryBackgroundAdjust == nil then
						E.db.bagCustomizer.inventoryBackgroundAdjust = {}
					end

					if E.db.bagCustomizer.inventoryBackgroundAdjust.debug == nil then
						E.db.bagCustomizer.inventoryBackgroundAdjust.debug = true
					end

					return E.db.bagCustomizer.inventoryBackgroundAdjust.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.inventoryBackgroundAdjust == nil then
						E.db.bagCustomizer.inventoryBackgroundAdjust = {}
					end

					E.db.bagCustomizer.inventoryBackgroundAdjust.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- Textures module debug toggle
			mainTexturesModule = {
				order = 26,
				type = "toggle",
				name = "MainTextures",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.mainTextures == nil then
						E.db.bagCustomizer.mainTextures = {}
					end

					if E.db.bagCustomizer.mainTextures.debug == nil then
						E.db.bagCustomizer.mainTextures.debug = true
					end

					return E.db.bagCustomizer.mainTextures.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.mainTextures == nil then
						E.db.bagCustomizer.mainTextures = {}
					end

					E.db.bagCustomizer.mainTextures.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- MiscTextures module debug toggle
			MiscTexturesModule = {
				order = 27,
				type = "toggle",
				name = "Misc Textures",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.miscTextures == nil then
						E.db.bagCustomizer.miscTextures = {}
					end

					if E.db.bagCustomizer.miscTextures.debug == nil then
						E.db.bagCustomizer.miscTextures.debug = true
					end

					return E.db.bagCustomizer.miscTextures.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.miscTextures == nil then
						E.db.bagCustomizer.miscTextures = {}
					end

					E.db.bagCustomizer.miscTextures.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- Currencies module debug toggle
			currencyModule = {
				order = 28,
				type = "toggle",
				name = "currency",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.currency == nil then
						E.db.bagCustomizer.currency = {}
					end

					if E.db.bagCustomizer.currency.debug == nil then
						E.db.bagCustomizer.currency.debug = true
					end

					return E.db.bagCustomizer.currency.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.currency == nil then
						E.db.bagCustomizer.currency = {}
					end

					E.db.bagCustomizer.currency.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- MiscBorders module debug toggle
			MiscBordersModule = {
				order = 29,
				type = "toggle",
				name = "Misc Borders",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.miscBorders == nil then
						E.db.bagCustomizer.miscBorders = {}
					end

					if E.db.bagCustomizer.miscBorders.debug == nil then
						E.db.bagCustomizer.miscBorders.debug = true
					end

					return E.db.bagCustomizer.miscBorders.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.miscBorders == nil then
						E.db.bagCustomizer.miscBorders = {}
					end

					E.db.bagCustomizer.miscBorders.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- SearchBar module debug toggle
			searchBarModule = {
				order = 30,
				type = "toggle",
				name = "Search Bar",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.searchBar == nil then
						E.db.bagCustomizer.searchBar = {}
					end

					if E.db.bagCustomizer.searchBar.debug == nil then
						E.db.bagCustomizer.searchBar.debug = true
					end

					return E.db.bagCustomizer.searchBar.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.searchBar == nil then
						E.db.bagCustomizer.searchBar = {}
					end

					E.db.bagCustomizer.searchBar.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- BindText module debug toggle
			bindTextModule = {
				order = 31,
				type = "toggle",
				name = "Bind Text",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.bindText == nil then
						E.db.bagCustomizer.bindText = {}
					end

					if E.db.bagCustomizer.bindText.debug == nil then
						E.db.bagCustomizer.bindText.debug = true
					end

					return E.db.bagCustomizer.bindText.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.bindText == nil then
						E.db.bagCustomizer.bindText = {}
					end

					E.db.bagCustomizer.bindText.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- InventorySlots module debug toggle
			inventorySlotsModule = {
				order = 32,
				type = "toggle",
				name = "Inventory Slots",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.inventorySlots == nil then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if E.db.bagCustomizer.inventorySlots.debug == nil then
						E.db.bagCustomizer.inventorySlots.debug = true
					end

					return E.db.bagCustomizer.inventorySlots.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.inventorySlots == nil then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- ThemeManager module debug toggle
			themeManagerModule = {
				order = 33,
				type = "toggle",
				name = "Theme Manager",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.themeManager == nil then
						E.db.bagCustomizer.themeManager = {}
					end

					if E.db.bagCustomizer.themeManager.debug == nil then
						E.db.bagCustomizer.themeManager.debug = true
					end

					return E.db.bagCustomizer.themeManager.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.themeManager == nil then
						E.db.bagCustomizer.themeManager = {}
					end

					E.db.bagCustomizer.themeManager.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},

			-- ImportExportDialog module debug toggle
			importExportDialogModule = {
				order = 34,
				type = "toggle",
				name = "Import/Export Dialog",
				width = 1.2,
				get = function()
					if E.db.bagCustomizer.importExportDialog == nil then
						E.db.bagCustomizer.importExportDialog = {}
					end

					if E.db.bagCustomizer.importExportDialog.debug == nil then
						E.db.bagCustomizer.importExportDialog.debug = true
					end

					return E.db.bagCustomizer.importExportDialog.debug
				end,
				set = function(_, value)
					if E.db.bagCustomizer.importExportDialog == nil then
						E.db.bagCustomizer.importExportDialog = {}
					end

					E.db.bagCustomizer.importExportDialog.debug = value
					if value and not E.db.bagCustomizer.debug then
						print("|cFFFFFF00Note:|r Master debug toggle is OFF. Enable it to see debug messages.")
					end
				end,
			},
		},
	}
	return debugOptions
end

-- Utility
-- ThemeManager.lua
local function CreateThemeOptions()
	local themeOptions = {
		order = 1,
		type = "group",
		name = "",
		guiInline = true,
		args = {
			themesInfo = {
				order = 1,
				type = "description",
				name = "",
				fontSize = "medium",
				width = "full",
			},
			saveTheme = {
				order = 2,
				type = "group",
				name = "Save current settings as Theme",
				guiInline = true,
				args = {
					themeName = {
						order = 1,
						type = "input",
						name = "Save Theme as..",
						width = 2,
						get = function()
							return addon.tempThemeName or ""
						end,
						set = function(_, value)
							addon.tempThemeName = value
						end,
					},
					saveButton = {
						order = 2,
						type = "execute",
						name = "Save",
						width = 0.5,
						func = function()
							if addon.tempThemeName and addon.tempThemeName ~= "" then
								addon:SaveTheme(addon.tempThemeName)
								addon.tempThemeName = ""
							end
						end,
						disabled = function()
							return not addon.tempThemeName or addon.tempThemeName == ""
						end,
					},
				},
			},
			manageThemes = {
				order = 3,
				type = "group",
				name = "Manage Themes",
				guiInline = true,
				args = {
					themeSelect = {
						order = 1,
						type = "select",
						name = "Select Theme",
						width = 2,
						values = function()
							return addon:GetThemesList()
						end,
						get = function()
							return addon.manageTheme
						end,
						set = function(_, value)
							addon.manageTheme = value
						end,
					},
					loadButton = {
						order = 2,
						type = "execute",
						name = "Load",
						width = 0.5,
						func = function()
							if addon.manageTheme then
								StaticPopupDialogs["BagCustomizer_for_ElvUI_LOAD_THEME_CONFIRM"] = {
									text = "Are you sure you want to load theme '" ..
											addon.manageTheme ..
											"'? This will overwrite your current settings.",
									button1 = "Yes",
									button2 = "No",
									OnShow = function(self)
										-- Set this dialog to appear on top
										self:SetFrameStrata "FULLSCREEN_DIALOG"
										self:SetFrameLevel(100)
									end,
									OnAccept = function()
										local themeName = addon.manageTheme
										addon:LoadTheme(themeName)
										-- Ensure the dialog is hidden
										C_Timer.After(0.1, function()
											StaticPopup_Hide
											"BagCustomizer_for_ElvUI_LOAD_THEME_CONFIRM"
										end)
									end,
									OnHide = function()
										-- Extra cleanup on hide
										collectgarbage "collect"
									end,
									timeout = 0,
									whileDead = true,
									hideOnEscape = true,
								}
								StaticPopup_Show "BagCustomizer_for_ElvUI_LOAD_THEME_CONFIRM"
							end
						end,
						disabled = function()
							return not addon.manageTheme
						end,
					},
					renameButton = {
						order = 3,
						type = "execute",
						name = "Rename",
						width = 0.5,
						func = function()
							if addon.manageTheme then
								StaticPopupDialogs["BagCustomizer_for_ElvUI_RENAME_THEME"] = {
									text = "Enter a new name for theme '" ..
											addon.manageTheme .. "':",
									button1 = "Rename",
									button2 = "Cancel",
									OnShow = function(self)
										-- Set this dialog to appear on top
										self:SetFrameStrata "FULLSCREEN_DIALOG"
										self:SetFrameLevel(100)
									end,
									OnAccept = function(self)
										local newName = self.editBox:GetText()
										if newName and newName ~= "" then
											local oldName = addon.manageTheme
											addon:RenameTheme(oldName, newName)
											addon.manageTheme = newName
											-- Force UI refresh
											if E.Libs and E.Libs.AceConfigDialog then
												E.Libs.AceConfigDialog:SelectGroup("ElvUI",
													"bagCustomizer", "themesTab")
											end
										end
									end,
									timeout = 0,
									whileDead = true,
									hideOnEscape = true,
									hasEditBox = true,
									editBoxWidth = 200,
								}
								StaticPopup_Show "BagCustomizer_for_ElvUI_RENAME_THEME"
							end
						end,
						disabled = function()
							return not addon.manageTheme
						end,
					},
					deleteButton = {
						order = 4,
						type = "execute",
						name = "Delete",
						width = 0.5,
						func = function()
							if addon.manageTheme then
								StaticPopupDialogs["BagCustomizer_for_ElvUI_DELETE_THEME_CONFIRM"] = {
									text = "Are you sure you want to delete theme '" ..
											addon.manageTheme .. "'? This cannot be undone.",
									button1 = "Yes",
									button2 = "No",
									OnShow = function(self)
										-- Set this dialog to appear on top
										self:SetFrameStrata "FULLSCREEN_DIALOG"
										self:SetFrameLevel(100)
									end,
									OnAccept = function()
										local themeName = addon.manageTheme
										addon:DeleteTheme(themeName)
										addon.manageTheme = nil
										-- Force UI refresh
										if E.Libs and E.Libs.AceConfigDialog then
											E.Libs.AceConfigDialog:SelectGroup("ElvUI",
												"bagCustomizer",
												"themesTab")
										end
									end,
									timeout = 0,
									whileDead = true,
									hideOnEscape = true,
								}
								StaticPopup_Show "BagCustomizer_for_ElvUI_DELETE_THEME_CONFIRM"
							end
						end,
						disabled = function()
							return not addon.manageTheme
						end,
					},
				},
			},
			ThemeExportImport = {
				order = 4,
				type = "group",
				name = "Export/Import a single Theme",
				guiInline = true,
				width = "full",
				args = {
					themeToExport = {
						order = 4,
						type = "select",
						name = "Select a Theme to Export",
						width = 2,
						values = function()
							local values = {}
							-- Only add user-created themes (those without an asterisk prefix)
							if BagCustomizer_for_ElvUIDB and BagCustomizer_for_ElvUIDB.themes then
								for themeName, _ in pairs(BagCustomizer_for_ElvUIDB.themes) do
									values[themeName] = themeName
								end
							end

							return values
						end,
						get = function()
							return addon.selectedExportTheme
						end,
						set = function(_, value)
							addon.selectedExportTheme = value
						end,
					},
					exportThemeButton = {
						order = 5,
						type = "execute",
						name = "Export",
						width = 0.5,
						func = function()
							addon:ShowThemeExportPopup()
						end,
					},
					-- Theme import section
					importThemeName = {
						order = 8,
						type = "input",
						name = "(|cFF00FFFFOptional*|r) Rename imported theme to:",
						desc =
						"If provided, the imported theme will use this name instead of the one in the export string.",
						width = 2,
						get = function()
							return addon.themeImportName or ""
						end,
						set = function(_, value)
							addon.themeImportName = value
						end,
					},
					importThemeButton = {
						order = 9,
						type = "execute",
						name = "Import",
						width = 0.5,
						func = function()
							addon:ShowThemeImportPopup()
						end,
					},
				},
			},
			GeneralExportImport = {
				order = 5,
				type = "group",
				name = "Export/Import all Themes and Settings",
				guiInline = true,
				args = {
					ExportButton = {
						order = 1,
						type = "execute",
						name = "Export All Themes and Settings",
						width = 2,
						func = function()
							addon:ShowExportPopup "Bag Customizer for ElvUI: Export Settings"
						end,
					},
					importButton = {
						order = 2,
						type = "execute",
						name = "Import All Themes and Settings",
						width = 2,
						func = function()
							addon:ShowImportPopup("Bag Customizer for ElvUI: Import Settings", false)
						end,
					},
				},
			},
			resetGroup = {
				order = 6,
				type = "group",
				name = "Reset All Settings and Delete all Themes",
				guiInline = true,
				args = {
					resetInfo = {
						order = 1,
						type = "description",
						name =
						"|cffff0000Warning:|r This will reset all settings to default AND delete your custom/imported themes. This action cannot be undone.",
						fontSize = "medium",
						width = 4,
					},
					resetButton = {
						order = 2,
						type = "execute",
						name = "Reset All Settings and Delete all Themes",
						width = 4,
						func = function()
							addon:ResetAllSettings()
						end,
						confirm = true,
						confirmText = "Are you sure you want to reset all settings to default?",
					},
				},
			},
		},
	}
	return themeOptions
end

-- Info
local function CreateWelcomeOptions()
	local welcomeOptions = {
		order = 1,
		type = "group",
		name = "",
		guiInline = true,
		args = {
			Info1 = {
				order = 1,
				type = "description",
				name = "|cFFFFD700Welcome to Bag Customizer for ElvUI!|r\n\n" ..
						"This addon's mission is to change the appearance of the ElvUI bags in order to make them as similar as possible to the default WoW bags, although you can also create your own Themes with your own style! |cFFFFD700The Bank and Warbank are not supported.|r\n\n\n" ..
						"|cFFFFD700Getting Started:|r\n" ..
						"1. Check out the default Theme! It should already be applied to your bags by default.\n" ..
						"2. Check out even more Themes! Head over to the Themes and Profiles tab and select one of the predefined Themes.\n" ..
						"3. Not quite happy with any of the default Themes? Use the \"Advanced\" tab to fine-tune specific elements.\n" ..
						"4. Save Your Theme: Once you're happy with your settings, save them as a theme for easy reuse.\n\n" ..
						"|cFFFFD700Good to know:|r\n" ..
						"• When applying a Theme or changing any settings in this addon, it's best to have your bag open - otherwise you may need to reload for the changes to apply properly.\n" ..
						"• Your settings and Themes are stored in your ElvUI Profile. If you want to keep your settings and themes across different ElvUI Profiles, you will need to export them in the Themes and Profiles tab.\n" ..
						"• Feature Toggle: Each component can be independently enabled/disabled without affecting others\n\n" ..
						"|cFFFFD700(Optional) ElvUI Settings:|r\n" ..
						"If you want to \"optimize\" your ElvUI bag settings in order to match the default bags more closely, consider using some or all of the below settings. Note: These are what worked best for me on 2560x1440 and ElvUI Scale set to 0.53.\n" ..
						"• Currency format: Icons only or Icons and Text(short).\n" ..
						"• Gold format: Blizzard Style\n" ..
						"• Show Coins checkbox Enabled\n" ..
						"• Bags Button size 39~44\n" ..
						"• Bags Button spacing ~4\n" ..
						"• Item Count, Info, Level fonts set to: Arial Narrow or Friz Quadrata TT\n\n" ..
						"|cFFFFD700Need Help?|r\n" ..
						"If you have questions or encounter issues, post them in the Curseforge comments. For issues specifically, please add debugging logs when possible (in the Debug tab, only enable the debugging for the relevant feature you're having issues with).",
				fontSize = "medium",
				width = "full",
			},
		},
	}
	return welcomeOptions
end

local function CreateAdvancedWelcomeTabOptions()
	local advancedWelcomeTabOptions = {
		order = 1,
		type = "group",
		name = "",
		guiInline = true,
		args = {
			sectionHeader = {
				order = 1,
				type = "header",
				name = "Advanced Settings Guide",
			},
			sectionIntro = {
				order = 2,
				type = "description",
				name =
				"This section provides controls for fine-tuning every aspect of your bag appearance. If you're new to the Advanced tab, check out the Tab navigation section below to more easily figure out where each option is. Alternatively, you can use the search bar in the ElvUI options to quickly find specific settings if you know what you're looking for.\n\n",
				fontSize = "medium",
				width = "full",
			},
			tabHeader = {
				order = 3,
				type = "header",
				name = "Tab Navigation",
			},
			tabDescription = {
				order = 4,
				type = "description",
				name =
						"• |cFFFFD700Window Body:|r Customize the Inventory background color, Top Texture, UI Texture (none by default) and Art Texture (none by default).\n" ..
						"• |cFFFFD700Layout:|r Customize the bag Close Button Texture, Close Button Position, Extra Bag Height, Search Bar and buttons settings.\n" ..
						"• |cFFFFD700Item Slots:|r Change the look of the inventory slots. This tab contains and manages it's own borders.\n" ..
						"• |cFFFFD700Gold & Currencies:|r Style and position gold display and currency frame.\n" ..
						"• |cFFFFD700Borders:|r Add borders to various elements, disable the default ElvUI Bag borders. The borders for the Item Slots are handled in the Item Slots tab.\n\n",
				fontSize = "medium",
				width = "full",
			},
			specialHeader = {
				order = 6,
				type = "header",
				name = "3 Slice Explained",
			},
			threeSliceDescription = {
				order = 7,
				type = "description",
				name = "Several texture options use \"3-Slice Scaling\" - this splits a texture into three parts:\n" ..
						"• Left edge (fixed size)\n" ..
						"• Middle section (stretches or repeats)\n" ..
						"• Right edge (fixed size)\n\n" ..
						"This method helps textures scale nicely without getting distorted. When enabled:\n" ..
						"1. Set the left and right edge percentages to define where the stretching/repeating happens\n" ..
						"2. Choose whether to stretch or repeat the middle section\n" ..
						"3. Adjust the edge size, breakpoints and, optionally, the tile spacing and offset settings\n\n",
				fontSize = "medium",
				width = "full",
			},
			customHeader = {
				order = 9,
				type = "header",
				name = "Custom Files",
			},
			customDescription = {
				order = 10,
				type = "description",
				name =
						"Excluding the Borders tab: In the Advanced tab, each dropdown lets you pick a custom file instead of the default ones. To use your custom files, add them to the appropriate folder in \\Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\ and make sure they have the correct names. For the best results, use the recommended sizes or at least try matching the aspect ratios.\n\n" ..
						"|cFFFFD700Window Body|r\n" ..
						"• Top Texture: folder TopTextures, file name top_custom1.tga, dimensions: 435x42 \n" ..
						"• UI Background Texture: folder InventoryBackgroundTextures, file name ui_custom1.tga, dimensions: 512x512 or match your bag size\n" ..
						"• Art Background: folder InventoryBackgroundTextures, file name art_custom1.tga, dimensions: 512x512 or match your bag size\n" ..
						"• Mask (Art Background fade shape): folder Masks, file name alpha_fade_custom1.tga, dimensions: 512x512 ideally\n\n" ..
						"|cFFFFD700Layout|r\n" ..
						"• Close button texture: folder CloseButtonTextures, file name close_custom1.tga, dimensions: 64x64\n\n" ..
						"|cFFFFD700Item Slots|r\n" ..
						"• Border Style: folder Buttons, file name custom_border.tga, dimensions: 64x64\n" ..
						"• Slot Texture: folder Buttons, file name custom_texture.tga, dimensions: 64x64 Note: The shape of this texture changes the shape of the inventory slots.\n" ..
						"• Highlight Texture: folder Buttons, file name custom_highlight.tga, dimensions: 64x64\n" ..
						"• Empty Slot Border style: folder Buttons, file name custom_texture.tga, dimensions: 64x64\n\n" ..
						"|cFFFFD700Currencies & Gold|r\n" ..
						"• Currencies: folder CurrencyTextures, file name currency_custom1.tga, dimensions: 354x52 or your bag's width\n" ..
						"• Gold: folder CurrencyTextures, file name gold_custom1.tga, dimensions: 354x52 or your bag's width\n\n" ..
						"|cFFFFD700Borders|r\n" ..
						"• Not supported\n",
				fontSize = "medium",
				width = "full",
			},
		},
	}
	return advancedWelcomeTabOptions
end

-- Modules
-- BindText.lua
local function CreateTextAdjustOptions()
	-- Create settings table if needed
	if not E.db.bagCustomizer.bindTextSettings then
		E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
	end

	local textAdjustOptions = {
		order = 5,
		type = "group",
		name = "Item text adjustments (BoE & WuE).",
		guiInline = true,
		args = {
			enableBindTextCustomization = {
				order = 1,
				type = "toggle",
				name = "Enable Module",
				desc = "Enable custom colors for 'Bind on Equip' and 'Warbound' text",
				width = 2,
				-- Apply the pattern + original side effects
				get = function()
					-- Safe read with default (assuming default for 'enable' is true or defined in defaults)
					if not E.db.bagCustomizer.bindTextSettings then
						return addon.defaults.bindTextSettings.enable
					end

					-- Handle case where enable might be nil even if bindTextSettings exists
					return E.db.bagCustomizer.bindTextSettings
							.enable -- No 'or default' needed if nil means false implicitly, but safer to check default
					-- return E.db.bagCustomizer.bindTextSettings.enable or addon.defaults.bindTextSettings.enable -- Use this if nil should fallback to default
				end,
				set = function(_, value)
					-- Safe write
					if not E.db.bagCustomizer.bindTextSettings then
						E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
					end

					E.db.bagCustomizer.bindTextSettings.enable = value
					-- Original side-effects START
					if value then
						-- Update all slots (standard pattern behavior)
						if addon.elements.bindText then
							addon.elements.bindText:UpdateAll()
						end
					else
						-- Reset all slots when disabled
						if addon.elements.bindText then
							addon.elements.bindText:ResetAll()
						end
					end

					-- Optional addon update notification
					addon:Update "BindTextToggle"
					-- Original side-effects END
				end,
			},
			poorQualityOption = {
				order = 2,
				type = "toggle",
				name = "Include Poor Quality Items",
				desc = "When enabled, bind text on grey (poor quality) items will also be customized.",
				width = 2,
				disabled = function()
					-- Use direct DB check for consistency with other disables
					return not E.db.bagCustomizer.bindTextSettings or
							not E.db.bagCustomizer.bindTextSettings.enable
				end,
				-- Apply the pattern
				get = function()
					-- Safe read with default
					if not E.db.bagCustomizer.bindTextSettings then
						return addon.defaults.bindTextSettings.applyToPoorQuality
					end

					-- Handle potential nil
					return E.db.bagCustomizer.bindTextSettings
							.applyToPoorQuality
				end,
				set = function(_, value)
					-- Safe write
					if not E.db.bagCustomizer.bindTextSettings then
						E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
					end

					E.db.bagCustomizer.bindTextSettings.applyToPoorQuality = value
					-- Update all slots (standard pattern behavior)
					if addon.elements.bindText then
						addon.elements.bindText:UpdateAll()
					end
				end,
			},
			applyToBindOnEquip = {
				order = 3,
				type = "toggle",
				name = "Enable adjustments for Bind on Equip Text",
				width = 2,
				disabled = function()
					-- Safe check - depends if module:GetSetting("enable") maps to E.db.bagCustomizer.bindTextSettings.enable
					-- Assuming it does, let's use the E.db path for consistency with other disables below
					return not E.db.bagCustomizer.bindTextSettings or
							not E.db.bagCustomizer.bindTextSettings.enable
				end,
				-- This already uses the requested pattern
				get = function()
					-- Safe read with default
					if not E.db.bagCustomizer.bindTextSettings then
						return addon.defaults.bindTextSettings.applyToBindOnEquip
					end

					return E.db.bagCustomizer.bindTextSettings.applyToBindOnEquip
				end,
				set = function(_, value)
					-- Safe write
					if not E.db.bagCustomizer.bindTextSettings then
						E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
					end

					E.db.bagCustomizer.bindTextSettings.applyToBindOnEquip = value
					-- Update all slots
					if addon.elements.bindText then
						addon.elements.bindText:UpdateAll()
					end
				end,
			},
			applyToWarbound = {
				order = 4,
				type = "toggle",
				name = "Enable adjustments for Warbound Text",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.bindTextSettings or
							not E.db.bagCustomizer.bindTextSettings.enable
				end,
				-- Apply the pattern
				get = function()
					-- Safe read with default
					if not E.db.bagCustomizer.bindTextSettings then
						return addon.defaults.bindTextSettings.applyToWarbound
					end

					return E.db.bagCustomizer.bindTextSettings.applyToWarbound
				end,
				set = function(_, value)
					-- Safe write
					if not E.db.bagCustomizer.bindTextSettings then
						E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
					end

					E.db.bagCustomizer.bindTextSettings.applyToWarbound = value
					-- Update all slots
					if addon.elements.bindText then
						addon.elements.bindText:UpdateAll()
					end
				end,
			},
			enableCustomColor = {
				order = 5,
				type = "toggle",
				name = "Use Custom Color",
				desc =
				"When enabled, uses the custom color set below. When disabled, adjusts brightness of the original item quality color.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.bindTextSettings or
							not E.db.bagCustomizer.bindTextSettings.enable
				end,
				-- Apply the pattern (field name is useCustomColor)
				get = function()
					-- Safe read with default
					if not E.db.bagCustomizer.bindTextSettings then
						return addon.defaults.bindTextSettings.useCustomColor
					end

					return E.db.bagCustomizer.bindTextSettings.useCustomColor
				end,
				set = function(_, value)
					-- Safe write
					if not E.db.bagCustomizer.bindTextSettings then
						E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
					end

					E.db.bagCustomizer.bindTextSettings.useCustomColor = value
					-- Update all slots
					if addon.elements.bindText then
						addon.elements.bindText:UpdateAll()
					end
				end,
			},
			customColorOption = {
				order = 6,
				type = "color",
				name = "Custom Color",
				desc = "Set the color for bind text",
				hasAlpha = false,
				width = 1,
				disabled = function()
					return not E.db.bagCustomizer.bindTextSettings or
							not E.db.bagCustomizer.bindTextSettings.enable or
							not E.db.bagCustomizer.bindTextSettings.useCustomColor
				end,
				-- Keep original specialized get/set for color components
				get = function()
					if not E.db.bagCustomizer.bindTextSettings or not E.db.bagCustomizer.bindTextSettings.color then
						-- Provide default color from defaults table if possible, otherwise fallback
						local defaultColor = addon.defaults.bindTextSettings.color or { r = 1, g = 1, b = 1 }
						return defaultColor.r, defaultColor.g, defaultColor.b
					end

					local c = E.db.bagCustomizer.bindTextSettings.color
					return c.r, c.g, c.b
				end,
				set = function(_, r, g, b)
					-- Safe write (slightly different structure needed for color)
					if not E.db.bagCustomizer.bindTextSettings then
						-- Create the structure, potentially copying defaults first
						E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
						-- Ensure color table exists after copy (in case defaults didn't have it)
						if not E.db.bagCustomizer.bindTextSettings.color then
							E.db.bagCustomizer.bindTextSettings.color = {}
						end
					elseif not E.db.bagCustomizer.bindTextSettings.color then
						-- Ensure color table exists if bindTextSettings exists but color doesn't
						E.db.bagCustomizer.bindTextSettings.color = {}
					end

					-- Set the color values
					E.db.bagCustomizer.bindTextSettings.color.r = r
					E.db.bagCustomizer.bindTextSettings.color.g = g
					E.db.bagCustomizer.bindTextSettings.color.b = b
					-- Update all slots with the new color
					if addon.elements.bindText then
						addon.elements.bindText:UpdateAll()
					end
				end,
			},
			brightnessOption = {
				order = 7,
				type = "range",
				name = "Brightness",
				desc =
				"Adjust the brightness of the bind text relative to the item quality color (100% = normal, >100% = brighter, <100% = darker)",
				min = 50,
				max = 250,
				step = 5,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.bindTextSettings or
							not E.db.bagCustomizer.bindTextSettings.enable or
							E.db.bagCustomizer.bindTextSettings.useCustomColor -- Assuming reading this safely now
				end,
				-- Apply the pattern (field name is brightness)
				get = function()
					-- Safe read with default
					if not E.db.bagCustomizer.bindTextSettings then
						return addon.defaults.bindTextSettings.brightness
					end

					-- Handle case where brightness might be nil even if bindTextSettings exists
					return E.db.bagCustomizer.bindTextSettings.brightness or addon.defaults.bindTextSettings.brightness
				end,
				set = function(_, value)
					-- Safe write
					if not E.db.bagCustomizer.bindTextSettings then
						E.db.bagCustomizer.bindTextSettings = E:CopyTable({}, addon.defaults.bindTextSettings)
					end

					E.db.bagCustomizer.bindTextSettings.brightness = value
					-- Update all slots
					if addon.elements.bindText then
						addon.elements.bindText:UpdateAll()
					end
				end,
			},
		},
	}
	return textAdjustOptions
end

-- CurrencyAndTextures.lua
local function CreateCloseButtonTextureOptions()
	local closeButtonTextureOptions = {
		order = 1,
		type = "group",
		name = "Close Button Texture",
		guiInline = true,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable Module",
				width = 2,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.enable
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {
							enable = value,
							texture = "close.tga",
							alpha = 1,
							scale = 1,
							buttonXOffsetPct = 0,
							buttonYOffsetPct = 0,
							textureXOffset = 0,
							textureYOffset = 0,
						}
					else
						E.db.bagCustomizer.closeButtonTexture.enable = value
					end

					if addon and addon.ApplyChanges then
						addon:DebouncedUpdate()
					end
				end,
			},
			texture = {
				order = 2,
				type = "select",
				name = "Texture Style",
				desc = "Select a texture for the close button",
				width = 2,
				values = addon.textureOptions.closeButton,
				disabled = function()
					return not E.db.bagCustomizer.closeButtonTexture or
							not E.db.bagCustomizer.closeButtonTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.texture or
							"close_blizzard_modern.tga"
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					E.db.bagCustomizer.closeButtonTexture.texture = value
					addon:DebouncedUpdate()
				end,
			},
			texturePositionHeader = {
				order = 3,
				type = "header",
				name = "Texture Position and Settings",
				width = "full",
			},
			alpha = {
				order = 4,
				type = "range",
				name = "Texture Opacity",
				desc = "Makes the Texture transparent, 0 is fully transparent, 1 is fully solid.",
				min = 0,
				max = 1,
				step = 0.01,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.closeButtonTexture or
							not E.db.bagCustomizer.closeButtonTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.alpha or 0.9
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					E.db.bagCustomizer.closeButtonTexture.alpha = value
					addon:DebouncedUpdate()
				end,
			},
			textureXOffset = {
				order = 5,
				type = "range",
				name = "Texture X Offset",
				desc =
				"Horizontal position of the texture overlay in pixels. Negative values move left, positive values move right.",
				min = -30,
				max = 30,
				step = 0.1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.closeButtonTexture or
							not E.db.bagCustomizer.closeButtonTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.textureXOffset or 0
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					E.db.bagCustomizer.closeButtonTexture.textureXOffset = value
					if addon and addon.ApplyChanges then
						addon:DebouncedUpdate()
					end
				end,
			},
			textureYOffset = {
				order = 6,
				type = "range",
				name = "Texture Y Offset",
				desc =
				"Vertical position of the texture overlay in pixels. Negative values move down, positive values move up.",
				min = -30,
				max = 30,
				step = 0.1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.closeButtonTexture or
							not E.db.bagCustomizer.closeButtonTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.textureYOffset or 0
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					E.db.bagCustomizer.closeButtonTexture.textureYOffset = value
					if addon and addon.ApplyChanges then
						addon:DebouncedUpdate()
					end
				end,
			},
			scale = {
				order = 7,
				type = "range",
				name = "Texture Scale",
				desc =
				"Scales the size of the Texture. Generally best to keep at the same value as the Button Scale.",
				min = 0.1,
				max = 3,
				step = 0.1,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.closeButtonTexture or
							not E.db.bagCustomizer.closeButtonTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.scale or 0.7
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					E.db.bagCustomizer.closeButtonTexture.scale = value
					addon:DebouncedUpdate()
				end,
			},
			-- Button position controls
			buttonPositionHeader = {
				order = 8,
				type = "header",
				name = "ElvUI Button Settings",
				width = "full",
			},
			anchorToFrameHeight = {
				order = 9,
				type = "toggle",
				name = "Anchor Inventory Close Button to Extra Bag Height Module.",
				desc =
				"Anchors the close button to the top right of the Extra Bag Height. The settings for that module can be found in the Layout tab.",
				width = "full",
				disabled = function()
					return not (E.db.bagCustomizer.closeButtonTexture and
								E.db.bagCustomizer.closeButtonTexture.enable) or
							not (E.db.bagCustomizer.frameHeight and
								E.db.bagCustomizer.frameHeight.enable)
				end,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.anchorToFrameHeight
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {
							enable = true,
							texture = "close.tga",
							alpha = 1,
							scale = 1,
							buttonXOffset = 0,
							buttonYOffset = 0,
							textureXOffset = 0,
							textureYOffset = 0,
							anchorToFrameHeight = value,
						}
					else
						E.db.bagCustomizer.closeButtonTexture.anchorToFrameHeight = value
					end

					if addon and addon.ApplyChanges then
						addon:DebouncedUpdate()
					end
				end,
			},
			buttonXOffset = {
				order = 10,
				type = "range",
				name = "Button X Offset",
				desc =
				"Horizontal position of the close button in pixels. Negative values move left, positive values move right.",
				min = -50,
				max = 50,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.closeButtonTexture or
							not E.db.bagCustomizer.closeButtonTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.buttonXOffset or -5
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					E.db.bagCustomizer.closeButtonTexture.buttonXOffset = value
					if addon and addon.ApplyChanges then
						addon:DebouncedUpdate()
					end
				end,
			},
			buttonYOffset = {
				order = 11,
				type = "range",
				name = "Button Y Offset",
				desc =
				"Vertical position of the close button in pixels. Negative values move down, positive values move up.",
				min = -50,
				max = 50,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.closeButtonTexture or
							not E.db.bagCustomizer.closeButtonTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.closeButtonTexture and
							E.db.bagCustomizer.closeButtonTexture.buttonYOffset or 0
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.closeButtonTexture then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					E.db.bagCustomizer.closeButtonTexture.buttonYOffset = value
					if addon and addon.ApplyChanges then
						addon:DebouncedUpdate()
					end
				end,
			},
			buttonScale = {
				order = 12,
				type = "range",
				name = "ElvUI Button Size Scale",
				desc =
				"Scale the size of the close button itself. Generally best to keep at the same value as the Texture Scale.",
				min = 0.5,
				max = 3.0,
				step = 0.05,
				width = 4,
				get = function()
					if type(E.db.bagCustomizer) ~= "table" then
						E.db.bagCustomizer = {}
					end

					if type(E.db.bagCustomizer.closeButtonTexture) ~= "table" then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					return E.db.bagCustomizer.closeButtonTexture.buttonScale or 1.0
				end,
				set = function(_, value)
					if type(E.db.bagCustomizer) ~= "table" then
						E.db.bagCustomizer = {}
					end

					if type(E.db.bagCustomizer.closeButtonTexture) ~= "table" then
						E.db.bagCustomizer.closeButtonTexture = {}
					end

					E.db.bagCustomizer.closeButtonTexture.buttonScale = value
					addon:DebouncedUpdate()
				end,
			},
		},
	}
	return closeButtonTextureOptions
end

local function CreatGeneralCurrencySettingsOptions()
	local generalCurrencySettingsOptions = {
		order = 2,
		type = "group",
		name = "Currencies, Gold text and shared settings",
		guiInline = true,
		args = {
			goldAnchorPosition = {
				order = 1,
				type = "select",
				name = "Gold & Currencies style",
				desc = "Choose where to position the gold text in relation to currencies",
				width = 4,
				disabled = function() return not E.db.bagCustomizer.currencyModuleEnabled end,
				values = {
					["DEFAULT"] = "ElvUI Default",
					["BOTTOM_CURRENCY_TOP_GOLD"] = "ElvUI with textures",
					["CURRENCY_ONLY"] = "Currency Texture Only",
					["GOLD_ONLY"] = "Gold Texture Only",
					["BOTTOM_RIGHT_BELOW"] = "Gold Bottom Right (Below Currencies)",
					["BOTTOM_RIGHT_ABOVE"] = "Gold Bottom Right (Above Currencies)",
				},
				sorting = { "DEFAULT", "BOTTOM_CURRENCY_TOP_GOLD", "CURRENCY_ONLY", "GOLD_ONLY", "BOTTOM_RIGHT_BELOW", "BOTTOM_RIGHT_ABOVE" },
				get = function() return E.db.bagCustomizer.goldAnchorPosition end,
				set = function(_, value)
					E.db.bagCustomizer.goldAnchorPosition = value
					-- Get addon module reference
					local addon = E:GetModule("BagCustomizer")
					-- Trigger specific event for this setting
					if addon.TriggerEvent then
						addon:TriggerEvent("GOLD_ANCHOR_POSITION_CHANGED", value)
					end

					-- Use addon's unified update system
					if addon.Update then
						addon:Update("GoldAnchorPositionChanged", true)
					else
						-- Fallback to original method
						ThrottleUpdate()
						-- Force ElvUI to update
						local B = E:GetModule("Bags")
						if B and B.Layout then
							C_Timer.After(0.1, function()
								B:Layout()
							end)
						end

						-- Refresh the options UI to update dependent options
						if E.Libs and E.Libs.AceConfigRegistry then
							E.Libs.AceConfigRegistry:NotifyChange("ElvUI")
						end
					end
				end,
			},
			fixGoldTextStrata = {
				order = 1.1,
				type = "toggle",
				name = "Fix Gold Text Strata|cFFFF0000*|r",
				desc =
				"Places gold text in a higher strata to prevent it from being hidden behind other elements. |cFFFF0000Best to leave this enabled in most situations.|r",
				width = 1,
				disabled = function() return not E.db.bagCustomizer.currencyModuleEnabled end,
				get = function() return E.db.bagCustomizer.fixGoldTextStrata end,
				set = function(_, value)
					E.db.bagCustomizer.fixGoldTextStrata = value
					-- Get addon module reference
					local addon = E:GetModule("BagCustomizer")
					-- Trigger specific event for this setting
					if addon.TriggerEvent then
						addon:TriggerEvent("FIX_GOLD_TEXT_STRATA_CHANGED", value)
					end

					-- Use addon's unified update system
					if addon.Update then
						addon:Update("FixGoldTextStrataChanged", true)
					else
						-- Fallback to original method
						ThrottleUpdate()
					end
				end,
			},
			spacer1 = {
				order = 1.2,
				type = "description",
				name = "",
				width = 3,
			},
			goldTextXOffset = {
				order = 2,
				type = "range",
				name = "Gold Text X Offset",
				desc = "Horizontal position adjustment for gold text",
				min = -100,
				max = 100,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition == "DEFAULT"
				end,
				get = function() return E.db.bagCustomizer.goldTextXOffset end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextXOffset = value
					-- Get addon module reference
					local addon = E:GetModule("BagCustomizer")
					-- Trigger specific event for this setting
					if addon.TriggerEvent then
						addon:TriggerEvent("GOLD_TEXT_X_OFFSET_CHANGED", value)
					end

					-- Use addon's unified update system
					if addon.Update then
						addon:Update("GoldTextXOffsetChanged", true)
					else
						-- Fallback to original method
						ThrottleUpdate()
					end
				end,
			},
			goldTextYOffset = {
				order = 3,
				type = "range",
				name = "Gold Text Y Offset",
				desc = "Vertical position adjustment for gold text",
				min = -50,
				max = 50,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition == "DEFAULT"
				end,
				get = function() return E.db.bagCustomizer.goldTextYOffset end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextYOffset = value
					-- Get addon module reference
					local addon = E:GetModule("BagCustomizer")
					-- Trigger specific event for this setting
					if addon.TriggerEvent then
						addon:TriggerEvent("GOLD_TEXT_Y_OFFSET_CHANGED", value)
					end

					-- Use addon's unified update system
					if addon.Update then
						addon:Update("GoldTextYOffsetChanged", true)
					else
						-- Fallback to original method
						ThrottleUpdate()
					end
				end,
			},
			currencyPaddingSize = {
				order = 4,
				type = "range",
				name = "Bottom Padding (Before Currencies Mode)",
				desc = "Amount of extra padding below currency when gold is shown below currency",
				min = 4,
				max = 50,
				step = 1,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition ~= "BOTTOM_RIGHT_BELOW"
				end,
				get = function() return E.db.bagCustomizer.currencyPaddingSize or 24 end,
				set = function(_, value)
					E.db.bagCustomizer.currencyPaddingSize = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("PADDING_CHANGED", value)
				end,
				hidden = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition ~= "BOTTOM_RIGHT_BELOW"
				end,
			},
			currencyTopPadding = {
				order = 5,
				type = "range",
				name = "Bottom Padding (After Currencies Mode)",
				desc = "Amount of extra padding above currency when gold is shown above currency",
				min = 4,
				max = 50,
				step = 1,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition ~= "BOTTOM_RIGHT_ABOVE"
				end,
				get = function() return E.db.bagCustomizer.currencyTopPadding or 34 end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTopPadding = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("PADDING_CHANGED", value)
				end,
				hidden = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition ~= "BOTTOM_RIGHT_ABOVE"
				end,
			},
			currencyHorizontalPadding = {
				order = 6,
				type = "range",
				name = "Currency Horizontal Padding",
				desc = "Amount of extra padding to right side of currency frame",
				min = -50,
				max = 50,
				step = 1,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled
				end,
				get = function() return E.db.bagCustomizer.currencyHorizontalPadding or 0 end,
				set = function(_, value)
					E.db.bagCustomizer.currencyHorizontalPadding = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("PADDING_CHANGED", value)
				end,
			},
			textureHeightOffset = {
				order = 7,
				type = "range",
				name = "Texture Height Offset",
				desc =
				"Adjusts texture height relative to standard row height (24px). The total height will be 24px plus this offset.",
				min = -15,
				max = 30,
				step = 1,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled
				end,
				get = function()
					return E.db.bagCustomizer.textureHeightOffset or 6
				end,
				set = function(_, value)
					E.db.bagCustomizer.textureHeightOffset = value
					-- Get addon module reference
					local addon = E:GetModule("BagCustomizer")
					-- Trigger specific event for this setting
					if addon.TriggerEvent then
						addon:TriggerEvent("TEXTURE_HEIGHT_OFFSET_CHANGED", value)
					end

					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
					-- Use addon's unified update system
					if addon.Update then
						addon:Update("TextureHeightOffsetChanged", true)
					else
						-- Fallback to original method
						ThrottleUpdate()
					end
				end,
			},
		},
	}
	return generalCurrencySettingsOptions
end

local function CreateGoldTextTextureOptions()
	local goldTextTextureOptions = {
		order = 3,
		type = "group",
		name = "Gold Texture",
		desc = "Customize the gold text appearance",
		guiInline = true,
		disabled = function()
			return E.db.bagCustomizer.goldAnchorPosition == "DEFAULT" or
					E.db.bagCustomizer.goldAnchorPosition == "CURRENCY_ONLY"
		end,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable Module",
				desc = "Enable custom gold text Textures.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition == "CURRENCY_ONLY" or
							E.db.bagCustomizer.goldAnchorPosition == "DEFAULT"
				end,
				get = function() return E.db.bagCustomizer.goldTextTexture.enable end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.enable = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			texture = {
				order = 2,
				type = "select",
				name = "Texture",
				desc = "Select the texture to use behind the gold text.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable
				end,
				values = function() return addon.textureOptions.goldtext end,
				get = function() return E.db.bagCustomizer.goldTextTexture.texture end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.texture = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			scale = {
				order = 3,
				type = "range",
				name = "Scale",
				desc = "Adjust the overall size of the gold text container.",
				min = 0.5,
				max = 3,
				step = 0.05,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable
				end,
				get = function() return E.db.bagCustomizer.goldTextTexture.scale end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.scale = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			alpha = {
				order = 4,
				type = "range",
				name = "Opacity",
				desc = "Adjust the transparency of the gold text background.",
				min = 0,
				max = 1,
				step = 0.01,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable
				end,
				get = function() return E.db.bagCustomizer.goldTextTexture.alpha end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.alpha = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			width = {
				order = 5,
				type = "range",
				name = "Width",
				desc = "Adjust the width of the gold text container.",
				width = 2,
				min = 50,
				max = 1000,
				step = 1,
				disabled = function()
					-- First check if the feature is disabled entirely
					if not E.db.bagCustomizer.goldTextTexture.enable then
						return true
					end

					-- Always disable if autoWidth is on (regardless of mode)
					if E.db.bagCustomizer.goldTextTexture.autoWidth then
						return true
					end

					-- Get current mode
					local currentMode = E.db.bagCustomizer.goldAnchorPosition
					local isSpecialMode = currentMode == "GOLD_ONLY" or currentMode == "BOTTOM_CURRENCY_TOP_GOLD"
					-- In special modes, we've already checked the critical conditions above
					if isSpecialMode then
						return false
					end

					-- In regular modes, also check the other conditions
					return E.db.bagCustomizer.goldTextTexture.preserveAspectRatio or
							E.db.bagCustomizer.goldTextTexture.matchHolderFrameWidth
				end,
				get = function() return E.db.bagCustomizer.goldTextTexture.width end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.width = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			height = {
				order = 6,
				type = "range",
				name = "Height",
				desc = "Adjust the height of the gold text container.",
				width = 2,
				min = 15,
				max = 80,
				step = 1,
				disabled = function()
					-- First check if the feature is disabled entirely
					if not E.db.bagCustomizer.goldTextTexture.enable then
						return true
					end

					-- Get current mode
					local currentMode = E.db.bagCustomizer.goldAnchorPosition
					local isSpecialMode = currentMode == "GOLD_ONLY" or currentMode == "BOTTOM_CURRENCY_TOP_GOLD"
					-- In special modes, only disable if autoHeight is on
					if isSpecialMode then
						return E.db.bagCustomizer.goldTextTexture.autoHeight or false
					end

					-- In regular modes, use the original conditions
					return E.db.bagCustomizer.goldTextTexture.autoHeight or
							E.db.bagCustomizer.goldTextTexture.preserveAspectRatio or
							E.db.bagCustomizer.goldTextTexture.matchHolderFrameWidth
				end,
				get = function() return E.db.bagCustomizer.goldTextTexture.height end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.height = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			goldTextAutoWidth = {
				order = 7,
				type = "toggle",
				name = "Auto Gold Texture Width|cFFFF0000*|r",
				desc =
				"Automatically adjust gold texture width based on gold amount. |cFFFF0000While|r |cFFFFD700\"Auto adjust Width while ancored to Bag\"|r |cFFFF0000is enabled, this option will not work.|r",
				width = "full",
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition == "DEFAULT" or
							not E.db.bagCustomizer.goldTextTexture or
							not E.db.bagCustomizer.goldTextTexture.enable
				end,
				get = function()
					if not E.db.bagCustomizer.goldTextTexture then return true end

					-- Return true by default if not set
					return E.db.bagCustomizer.goldTextTexture.autoWidth ~= false
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.goldTextTexture then E.db.bagCustomizer.goldTextTexture = {} end

					E.db.bagCustomizer.goldTextTexture.autoWidth = value
					-- Get addon module reference
					local addon = E:GetModule("BagCustomizer")
					-- Trigger specific event for this setting
					if addon.TriggerEvent then
						addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED", value)
					end

					-- Use addon's unified update system
					if addon.Update then
						addon:Update("GoldTextTextureChanged", true)
					else
						-- Fallback to original method
						ThrottleUpdate()
					end
				end,
			},
			widthModifier = {
				order = 8,
				type = "range",
				name = "Width Offset",
				desc =
				"Fine-tune the width when 'Match Holder Frame Width' is enabled. Add or subtract pixels from the width.",
				min = -30,
				max = 30,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable
				end,
				get = function()
					-- Handle conversion from old percentage format
					local value = E.db.bagCustomizer.goldTextTexture.widthModifier or 0
					-- If it's still in percentage format (0.6-1.4 or 60-140), convert to pixel offset
					if value ~= 0 and (value >= 0.6 and value <= 1.4) or (value >= 60 and value <= 140) then
						-- Assume base width of approximately 100px (adjust if needed)
						local baseWidth = 100
						-- Convert percentage to pixel offset
						if value >= 10 then -- old format (60-140)
							value = ((value / 100) - 1) * baseWidth
						else          -- new format (0.6-1.4)
							value = (value - 1) * baseWidth
						end

						-- Round to nearest integer
						value = math.floor(value + 0.5)
					end

					return value
				end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.widthModifier = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			heightAdjustment = {
				order = 9,
				type = "range",
				name = "Height Offset",
				desc = "Fine-tune the height of this texture",
				min = -20,
				max = 20,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.goldTextTexture.heightAdjustment or 0
				end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.heightAdjustment = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			autoFitHeader = {
				order = 9.9,
				type = "header",
				name = "Positioning Settings",
			},
			anchorToHolderFrame = {
				order = 10,
				type = "toggle",
				name = "Anchor to the Bag instead of Gold",
				desc =
				"Anchors the gold texture to the bottom of the holder frame instead of centering it on the gold text.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							E.db.bagCustomizer.goldAnchorPosition == "DEFAULT"
				end,
				get = function()
					return E.db.bagCustomizer.goldTextTexture.anchorToHolderFrame
				end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.anchorToHolderFrame = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			matchHolderFrameWidth = {
				order = 11,
				type = "toggle",
				name = "Auto adjust Width while anchored to Bag",
				desc = "Makes the gold texture width match the entire holder frame width.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							E.db.bagCustomizer.goldAnchorPosition == "DEFAULT"
				end,
				get = function()
					return E.db.bagCustomizer.goldTextTexture.matchHolderFrameWidth
				end,
				set = function(_, value)
					E.db.bagCustomizer.goldTextTexture.matchHolderFrameWidth = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			standardOffsets = {
				order = 12,
				type = "group",
				name = "Standard Position Offsets (Anchor to Bag disabled)",
				inline = true,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							E.db.bagCustomizer.goldTextTexture.matchHolderFrameWidth or
							E.db.bagCustomizer.goldTextTexture.anchorToHolderFrame
				end,
				args = {
					xOffset = {
						order = 1,
						type = "range",
						name = "X Offset",
						min = -50,
						max = 50,
						step = 1,
						width = 2,
						get = function()
							return E.db.bagCustomizer.goldTextTexture.xOffset
						end,
						set = function(_, value)
							E.db.bagCustomizer.goldTextTexture.xOffset = value
							local addon = E:GetModule("BagCustomizer")
							addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
						end,
					},
					yOffset = {
						order = 2,
						type = "range",
						name = "Y Offset",
						min = -50,
						max = 50,
						step = 1,
						width = 2,
						get = function()
							return E.db.bagCustomizer.goldTextTexture.yOffset
						end,
						set = function(_, value)
							E.db.bagCustomizer.goldTextTexture.yOffset = value
							local addon = E:GetModule("BagCustomizer")
							addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
						end,
					},
				},
			},
			holderFrameOffsets = {
				order = 13,
				type = "group",
				name = "Special Position Offsets (Anchor to Bag enabled)",
				inline = true,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							(not E.db.bagCustomizer.goldTextTexture.matchHolderFrameWidth and
								not E.db.bagCustomizer.goldTextTexture.anchorToHolderFrame)
				end,
				args = {
					holderFrameXOffset = {
						order = 1,
						type = "range",
						name = "X Offset",
						min = -50,
						max = 50,
						step = 1,
						width = 2,
						get = function()
							return E.db.bagCustomizer.goldTextTexture.holderFrameXOffset
						end,
						set = function(_, value)
							E.db.bagCustomizer.goldTextTexture.holderFrameXOffset = value
							local addon = E:GetModule("BagCustomizer")
							addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
						end,
					},
					holderFrameYOffset = {
						order = 2,
						type = "range",
						name = "Y Offset",
						min = -50,
						max = 50,
						step = 1,
						width = 2,
						get = function()
							return E.db.bagCustomizer.goldTextTexture.holderFrameYOffset
						end,
						set = function(_, value)
							E.db.bagCustomizer.goldTextTexture.holderFrameYOffset = value
							local addon = E:GetModule("BagCustomizer")
							addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
						end,
					},
				},
			},
			Header2 = {
				order = 14,
				type = "header",
				name = "3 Slice Settings",
			},
			use3Slice = {
				order = 15,
				type = "toggle",
				name = "Use 3-Slice Scaling",
				desc = "Split the texture into 3 parts: left, middle, and right edges",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable
				end,
				get = function()
					if not E.db.bagCustomizer.goldTextTexture.use3Slice then
						E.db.bagCustomizer.goldTextTexture.use3Slice = false
					end

					return E.db.bagCustomizer.goldTextTexture.use3Slice
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.goldTextTexture then
						E.db.bagCustomizer.goldTextTexture = CopyTable(addon.defaults
							.goldTextTexture)
					end

					E.db.bagCustomizer.goldTextTexture.use3Slice = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			useTiling = {
				order = 16,
				type = "toggle",
				name = "Tile Middle Section",
				desc = "Tile the middle section instead of stretching it",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							not E.db.bagCustomizer.goldTextTexture.use3Slice
				end,
				get = function()
					if not E.db.bagCustomizer.goldTextTexture.useTiling then
						E.db.bagCustomizer.goldTextTexture.useTiling = false
					end

					return E.db.bagCustomizer.goldTextTexture.useTiling
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.goldTextTexture then
						E.db.bagCustomizer.goldTextTexture = CopyTable(addon.defaults
							.goldTextTexture)
					end

					E.db.bagCustomizer.goldTextTexture.useTiling = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			edgeSize = {
				order = 17,
				type = "range",
				name = "Edge Size",
				desc = "Controls the pixel width of non-stretched edges in 3-slice mode",
				min = 1,
				max = 50,
				step = 0.5,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							not E.db.bagCustomizer.goldTextTexture.use3Slice
				end,
				get = function()
					if not E.db.bagCustomizer.goldTextTexture.edgeSize then
						E.db.bagCustomizer.goldTextTexture.edgeSize = 14
					end

					return E.db.bagCustomizer.goldTextTexture.edgeSize
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.goldTextTexture then
						E.db.bagCustomizer.goldTextTexture = CopyTable(addon.defaults
							.goldTextTexture)
					end

					E.db.bagCustomizer.goldTextTexture.edgeSize = value
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			leftBreakPct = {
				order = 18,
				type = "range",
				name = "Left Edge %",
				desc = "Where the left edge ends (percentage of texture width)",
				min = 5,
				max = 45,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							not E.db.bagCustomizer.goldTextTexture.use3Slice
				end,
				get = function()
					if not E.db.bagCustomizer.goldTextTexture.leftBreakPct then
						E.db.bagCustomizer.goldTextTexture.leftBreakPct = 15
					end

					return E.db.bagCustomizer.goldTextTexture.leftBreakPct
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.goldTextTexture then
						E.db.bagCustomizer.goldTextTexture = CopyTable(addon.defaults
							.goldTextTexture)
					end

					E.db.bagCustomizer.goldTextTexture.leftBreakPct = value
					-- Ensure right break is greater than left break
					if E.db.bagCustomizer.goldTextTexture.rightBreakPct <= value + 10 then
						E.db.bagCustomizer.goldTextTexture.rightBreakPct = math.min(value + 10,
							95)
					end

					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			rightBreakPct = {
				order = 19,
				type = "range",
				name = "Right Edge %",
				desc = "Where the right edge begins (percentage of texture width)",
				min = 55,
				max = 95,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							not E.db.bagCustomizer.goldTextTexture.use3Slice
				end,
				get = function()
					if not E.db.bagCustomizer.goldTextTexture.rightBreakPct then
						E.db.bagCustomizer.goldTextTexture.rightBreakPct = 85
					end

					return E.db.bagCustomizer.goldTextTexture.rightBreakPct
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.goldTextTexture then
						E.db.bagCustomizer.goldTextTexture = CopyTable(addon.defaults
							.goldTextTexture)
					end

					E.db.bagCustomizer.goldTextTexture.rightBreakPct = value
					-- Ensure left break is less than right break
					if E.db.bagCustomizer.goldTextTexture.leftBreakPct >= value - 10 then
						E.db.bagCustomizer.goldTextTexture.leftBreakPct = math.max(value - 10, 5)
					end

					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			tileSpacing = {
				order = 20,
				type = "range",
				name = "Tile Spacing",
				desc = "Space between each tile in pixels",
				min = -10,
				max = 20,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							not E.db.bagCustomizer.goldTextTexture.use3Slice or
							not E.db.bagCustomizer.goldTextTexture.useTiling
				end,
				get = function()
					if not E.db.bagCustomizer.goldTextTexture.tileSpacing then
						E.db.bagCustomizer.goldTextTexture.tileSpacing = 0
					end

					return E.db.bagCustomizer.goldTextTexture.tileSpacing
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.goldTextTexture then
						E.db.bagCustomizer.goldTextTexture = CopyTable(addon.defaults
							.goldTextTexture)
					end

					E.db.bagCustomizer.goldTextTexture.tileSpacing = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
			tileOffset = {
				order = 21,
				type = "range",
				name = "Tile Offset",
				desc = "Horizontal offset to start tiling from",
				min = -50,
				max = 50,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.goldTextTexture.enable or
							not E.db.bagCustomizer.goldTextTexture.use3Slice or
							not E.db.bagCustomizer.goldTextTexture.useTiling
				end,
				get = function()
					if not E.db.bagCustomizer.goldTextTexture.tileOffset then
						E.db.bagCustomizer.goldTextTexture.tileOffset = 0
					end

					return E.db.bagCustomizer.goldTextTexture.tileOffset
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.goldTextTexture then
						E.db.bagCustomizer.goldTextTexture = CopyTable(addon.defaults
							.goldTextTexture)
					end

					E.db.bagCustomizer.goldTextTexture.tileOffset = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("GOLD_TEXT_TEXTURE_CHANGED")
				end,
			},
		},
	}
	return goldTextTextureOptions
end

local function CreateCurrencyTextureOptions()
	local currencyTextureOptions = {
		order = 4,
		type = "group",
		name = "Currency Frame",
		desc = "Customize the currency frame appearance",
		guiInline = true,
		disabled = function() return E.db.bagCustomizer.goldAnchorPosition == "GOLD_ONLY" end,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable",
				desc = "Enable custom currency frame Textures.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyModuleEnabled or
							E.db.bagCustomizer.goldAnchorPosition == "GOLD_ONLY" or
							E.db.bagCustomizer.goldAnchorPosition == "DEFAULT"
				end,
				get = function() return E.db.bagCustomizer.currencyTexture.enable end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.enable = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			texture = {
				order = 2,
				type = "select",
				name = "Texture",
				desc = "Select the texture to use for the currency frame.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable
				end,
				values = function() return addon.textureOptions.currency end,
				get = function() return E.db.bagCustomizer.currencyTexture.texture end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.texture = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			scale = {
				order = 3,
				type = "range",
				name = "Scale",
				desc = "Adjust the size of the currency frame texture.",
				width = 2,
				min = 0.5,
				max = 2,
				step = 0.05,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable
				end,
				get = function() return E.db.bagCustomizer.currencyTexture.scale end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.scale = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			alpha = {
				order = 4,
				type = "range",
				name = "Alpha",
				desc = "Adjust the transparency of the currency frame texture.",
				width = 2,
				min = 0,
				max = 1,
				step = 0.01,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable
				end,
				get = function() return E.db.bagCustomizer.currencyTexture.alpha end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.alpha = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			width = {
				order = 5,
				type = "range",
				name = "Width",
				desc = "Adjust the width of the currency frame.",
				width = 2,
				min = 50,
				max = 300,
				step = 1,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							E.db.bagCustomizer.currencyTexture.preserveAspectRatio or
							E.db.bagCustomizer.currencyTexture.autoFitHeight
				end,
				get = function() return E.db.bagCustomizer.currencyTexture.width end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.width = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			height = {
				order = 7,
				type = "range",
				name = "Height",
				desc = "Adjust the height of the currency frame.",
				width = 2,
				min = 20,
				max = 100,
				step = 1,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							E.db.bagCustomizer.currencyTexture.preserveAspectRatio or
							E.db.bagCustomizer.currencyTexture.autoFitHeight
				end,
				get = function() return E.db.bagCustomizer.currencyTexture.height end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.height = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			widthAdjustment = {
				order = 8,
				type = "range",
				name = "Width Adjustment",
				desc =
				"Fine-tune the width of the currency texture by adding or subtracting pixels.",
				min = -30,
				max = 30,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.currencyTexture.widthAdjustment or 0
				end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.widthAdjustment = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			rowHeightOffset = {
				order = 9,
				type = "range",
				name = "Height Adjustment",
				desc =
				"Fine-tune the height when Auto Fit is enabled. Positive values make it taller, negative values make it shorter.",
				width = 2,
				min = -10,
				max = 10,
				step = 1,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyTexture.autoFitHeight
				end,
				get = function()
					return E.db.bagCustomizer.currencyTexture.rowHeightOffset or 0
				end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.rowHeightOffset = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			autoFitHeader = {
				order = 20,
				type = "header",
				name = "Auto Fit Settings",
			},
			autoFitHeight = {
				order = 21,
				type = "toggle",
				name = "Auto Fit Height",
				desc =
				"Reduces the height of the currency texture to make room for gold below. Uses the currency padding setting from layout options. Requires 'Add extra space for gold text' to be enabled.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyModuleEnabled
				end,
				get = function()
					return E.db.bagCustomizer.currencyTexture.autoFitHeight
				end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.autoFitHeight = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			matchHolderFrameWidth = {
				order = 22,
				type = "toggle",
				name = "Match Holder Frame Width",
				desc = "Makes the currency texture width match the entire holder frame width.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							E.db.bagCustomizer.goldAnchorPosition == "DEFAULT"
				end,
				get = function()
					return E.db.bagCustomizer.currencyTexture.matchHolderFrameWidth
				end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.matchHolderFrameWidth = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			texturePositionHeader = {
				order = 30,
				type = "header",
				name = "Texture Position",
			},
			textureXOffset = {
				order = 31,
				type = "range",
				name = "Texture X Offset",
				desc = "Horizontal offset for the texture relative to the currency button.",
				width = 2,
				min = -50,
				max = 50,
				step = 1,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.currencyTexture.textureXOffset or 0
				end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.textureXOffset = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			textureYOffset = {
				order = 31,
				type = "range",
				name = "Texture Y Offset",
				desc = "Vertical offset for the texture relative to the currency button.",
				width = 2,
				min = -50,
				max = 50,
				step = 1,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable
				end,
				get = function()
					return E.db.bagCustomizer.currencyTexture.textureYOffset or 0
				end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.textureYOffset = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			textureAnchor = {
				order = 32,
				type = "select",
				name = "Texture Anchor",
				desc = "Anchor point for the texture relative to the currency button.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable
				end,
				values = {
					["CENTER"] = "Center",
					["TOP"] = "Top",
					["BOTTOM"] = "Bottom",
				},
				get = function()
					return E.db.bagCustomizer.currencyTexture.textureAnchor or "CENTER"
				end,
				set = function(_, value)
					E.db.bagCustomizer.currencyTexture.textureAnchor = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			sliceHeader = {
				order = 40,
				type = "header",
				name = "Texture Position",
			},
			use3Slice = {
				order = 41,
				type = "toggle",
				name = "Use 3-Slice Scaling",
				desc = "Split the texture into 3 parts: left, middle, and right edges",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable
				end,
				get = function()
					if not E.db.bagCustomizer.currencyTexture.use3Slice then
						E.db.bagCustomizer.currencyTexture.use3Slice = false
					end

					return E.db.bagCustomizer.currencyTexture.use3Slice
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.currencyTexture then
						E.db.bagCustomizer.currencyTexture = CopyTable(addon.defaults
							.currencyTexture)
					end

					E.db.bagCustomizer.currencyTexture.use3Slice = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			useTiling = {
				order = 42,
				type = "toggle",
				name = "Tile Middle Section",
				desc = "Tile the middle section instead of stretching it",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyTexture.use3Slice
				end,
				get = function()
					if not E.db.bagCustomizer.currencyTexture.useTiling then
						E.db.bagCustomizer.currencyTexture.useTiling = false
					end

					return E.db.bagCustomizer.currencyTexture.useTiling
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.currencyTexture then
						E.db.bagCustomizer.currencyTexture = CopyTable(addon.defaults
							.currencyTexture)
					end

					E.db.bagCustomizer.currencyTexture.useTiling = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			useVerticalTiling = {
				order = 43,
				type = "toggle",
				name = "Tile Middle Vertically",
				desc =
				"Tile the middle section vertically instead of stretching it. Recommended for multi-row currency display. Requires a texture middle section suitable for vertical tiling.",
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyTexture.use3Slice
				end,
				get = function()
					if E.db.bagCustomizer.currencyTexture.useVerticalTiling == nil then
						E.db.bagCustomizer.currencyTexture.useVerticalTiling = true
					end

					return E.db.bagCustomizer.currencyTexture.useVerticalTiling
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.currencyTexture then
						E.db.bagCustomizer.currencyTexture = {}
					end

					E.db.bagCustomizer.currencyTexture.useVerticalTiling = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			edgeSize = {
				order = 44,
				type = "range",
				name = "Edge Size",
				desc = "Controls the pixel width of non-stretched edges in 3-slice mode",
				min = 5,
				max = 40,
				step = 1,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyTexture.use3Slice
				end,
				get = function()
					if not E.db.bagCustomizer.currencyTexture.edgeSize then
						E.db.bagCustomizer.currencyTexture.edgeSize = 14
					end

					return E.db.bagCustomizer.currencyTexture.edgeSize
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.currencyTexture then
						E.db.bagCustomizer.currencyTexture = CopyTable(addon.defaults
							.currencyTexture)
					end

					E.db.bagCustomizer.currencyTexture.edgeSize = value
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			leftBreakPct = {
				order = 45,
				type = "range",
				name = "Left Edge %",
				desc = "Where the left edge ends (percentage of texture width)",
				min = 5,
				max = 45,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyTexture.use3Slice
				end,
				get = function()
					if not E.db.bagCustomizer.currencyTexture.leftBreakPct then
						E.db.bagCustomizer.currencyTexture.leftBreakPct = 15
					end

					return E.db.bagCustomizer.currencyTexture.leftBreakPct
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.currencyTexture then
						E.db.bagCustomizer.currencyTexture = CopyTable(addon.defaults
							.currencyTexture)
					end

					E.db.bagCustomizer.currencyTexture.leftBreakPct = value
					-- Ensure right break is greater than left break
					if E.db.bagCustomizer.currencyTexture.rightBreakPct <= value + 10 then
						E.db.bagCustomizer.currencyTexture.rightBreakPct = math.min(value + 10,
							95)
					end

					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			rightBreakPct = {
				order = 46,
				type = "range",
				name = "Right Edge %",
				desc = "Where the right edge begins (percentage of texture width)",
				min = 55,
				max = 95,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyTexture.use3Slice
				end,
				get = function()
					if not E.db.bagCustomizer.currencyTexture.rightBreakPct then
						E.db.bagCustomizer.currencyTexture.rightBreakPct = 85
					end

					return E.db.bagCustomizer.currencyTexture.rightBreakPct
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.currencyTexture then
						E.db.bagCustomizer.currencyTexture = CopyTable(addon.defaults
							.currencyTexture)
					end

					E.db.bagCustomizer.currencyTexture.rightBreakPct = value
					-- Ensure left break is less than right break
					if E.db.bagCustomizer.currencyTexture.leftBreakPct >= value - 10 then
						E.db.bagCustomizer.currencyTexture.leftBreakPct = math.max(value - 10, 5)
					end

					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			tileSpacing = {
				order = 47,
				type = "range",
				name = "Tile Spacing",
				desc = "Space between each tile in pixels",
				min = -10,
				max = 20,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyTexture.use3Slice or
							not E.db.bagCustomizer.currencyTexture.useTiling
				end,
				get = function()
					if not E.db.bagCustomizer.currencyTexture.tileSpacing then
						E.db.bagCustomizer.currencyTexture.tileSpacing = 0
					end

					return E.db.bagCustomizer.currencyTexture.tileSpacing
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.currencyTexture then
						E.db.bagCustomizer.currencyTexture = CopyTable(addon.defaults
							.currencyTexture)
					end

					E.db.bagCustomizer.currencyTexture.tileSpacing = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
			tileOffset = {
				order = 48,
				type = "range",
				name = "Tile Offset",
				desc = "Horizontal offset to start tiling from",
				min = -50,
				max = 50,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.currencyTexture.enable or
							not E.db.bagCustomizer.currencyTexture.use3Slice or
							not E.db.bagCustomizer.currencyTexture.useTiling
				end,
				get = function()
					if not E.db.bagCustomizer.currencyTexture.tileOffset then
						E.db.bagCustomizer.currencyTexture.tileOffset = 0
					end

					return E.db.bagCustomizer.currencyTexture.tileOffset
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.currencyTexture then
						E.db.bagCustomizer.currencyTexture = CopyTable(addon.defaults
							.currencyTexture)
					end

					E.db.bagCustomizer.currencyTexture.tileOffset = value
					local addon = E:GetModule("BagCustomizer")
					addon:TriggerEvent("CURRENCY_TEXTURE_CHANGED")
				end,
			},
		},
	}
	return currencyTextureOptions
end
-- FrameHeight.lua
local function CreateFrameHeightTabOptions()
	local frameHeightTabOptions = {
		order = 2,
		type = "group",
		name = "Extra Bag Height",
		guiInline = true,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable Module",
				desc = "Increase bag height and add spacing at the top of the frame",
				width = "full",
				get = function()
					-- Directly check if the setting exists and is true
					if type(E.db.bagCustomizer) ~= "table" then
						E.db.bagCustomizer = {}
					end

					if type(E.db.bagCustomizer.frameHeight) ~= "table" then
						E.db.bagCustomizer.frameHeight = {}
					end

					return E.db.bagCustomizer.frameHeight.enable == true
				end,
				set = function(_, value)
					-- Make sure the path exists
					if type(E.db.bagCustomizer) ~= "table" then
						E.db.bagCustomizer = {}
					end

					if type(E.db.bagCustomizer.frameHeight) ~= "table" then
						E.db.bagCustomizer.frameHeight = {}
					end

					E.db.bagCustomizer.frameHeight.enable = value
					addon:DebouncedUpdate()
					-- Also update the module directly if possible
					local frameHeight = addon:GetModule("frameHeight")
					if frameHeight and frameHeight.UpdateLayout then
						frameHeight:UpdateLayout()
					end
				end,
			},
			bagSpacing = {
				order = 2,
				type = "range",
				name = "Extra Bag Height (Top)",
				desc = "Set the amount of extra vertical space at the top of the bag frame",
				min = 0,
				max = 100,
				step = 1,
				width = 4,
				disabled = function()
					if type(E.db.bagCustomizer) ~= "table" then
						return true
					end

					if type(E.db.bagCustomizer.frameHeight) ~= "table" then
						return true
					end

					return not E.db.bagCustomizer.frameHeight.enable
				end,
				get = function()
					if type(E.db.bagCustomizer) ~= "table" then
						E.db.bagCustomizer = {}
					end

					if type(E.db.bagCustomizer.frameHeight) ~= "table" then
						E.db.bagCustomizer.frameHeight = {}
					end

					return E.db.bagCustomizer.frameHeight.bagSpacing or 45
				end,
				set = function(_, value)
					if type(E.db.bagCustomizer) ~= "table" then
						E.db.bagCustomizer = {}
					end

					if type(E.db.bagCustomizer.frameHeight) ~= "table" then
						E.db.bagCustomizer.frameHeight = {}
					end

					E.db.bagCustomizer.frameHeight.bagSpacing = value
					addon:DebouncedUpdate()
					-- Also update the module directly if possible
					local frameHeight = addon:GetModule("frameHeight")
					if frameHeight and frameHeight.UpdateLayout then
						frameHeight:UpdateLayout()
					end
				end,
			},
		},
	}
	return frameHeightTabOptions
end

-- InventoryBackgroundAdjust.lua
local function CreateBackgroundGroupOptions()
	local backgroundGroupOptions = {
		order = 3,
		type = "group",
		name = "Background Color and Opacity",
		guiInline = true,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable Module",
				width = "full",
				get = function()
					if E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor == nil then
						E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor = true
					end

					return E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor
				end,
				set = function(_, value)
					E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor = value
					addon:DebouncedUpdate()
				end,
				disabled = function()
					return not E.db.bagCustomizer.enabled
				end,
			},
			colorPicker = {
				order = 2,
				type = "color",
				name = "Background Color",
				hasAlpha = false,
				width = 2,
				get = function()
					local c = E.db.bagCustomizer.inventoryBackgroundAdjust.color
					return c.r, c.g, c.b
				end,
				set = function(_, r, g, b)
					local c = E.db.bagCustomizer.inventoryBackgroundAdjust.color
					c.r, c.g, c.b = r, g, b
					addon:DebouncedUpdate()
				end,
				disabled = function()
					return not E.db.bagCustomizer.enabled or not E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor
				end,
			},
			opacity = {
				order = 3,
				type = "range",
				name = "Background Opacity",
				min = 0,
				max = 1,
				step = 0.01,
				width = 2,
				get = function() return E.db.bagCustomizer.inventoryBackgroundAdjust.opacity end,
				set = function(_, value)
					E.db.bagCustomizer.inventoryBackgroundAdjust.opacity = value
					addon:DebouncedUpdate()
				end,
				disabled = function()
					return not E.db.bagCustomizer.enabled or not E.db.bagCustomizer.inventoryBackgroundAdjust.enableColor
				end,
			},
		},
	}
	return backgroundGroupOptions
end

-- InventorySlots.lua
local function CreateInventorySlotsMainOptions()
	local inventorySlotsMainOptions = {
		order = 2,
		type = "group",
		name = "Inventory Slots Styles",
		guiInline = true,
		args = {
			presetStyle = {
				order = 1.5,
				type = "select",
				name = "Style Preset",
				desc = "Choose a preset style for slot borders and Textures",
				width = 4,
				values = function()
					local options = {}
					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots or not inventorySlots.presetComponentMap then
						return { ["none"] = "None Available" }
					end

					-- Use the full preset names from presetComponentMap
					for presetName, _ in pairs(inventorySlots.presetComponentMap) do
						-- Convert preset key to human-readable format with capitalization
						local displayName = presetName:gsub("_", " ")
						-- Capitalize each word
						displayName = displayName:gsub("(%a)([%w_']*)", function(first, rest)
							return first:upper() .. rest:lower()
						end)
						options[presetName] = displayName
					end

					return options
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then
						return "blizzard_modern"
					end

					local preset = E.db.bagCustomizer.inventorySlots.preset or
							"blizzard_modern"
					return preset
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					local settings = E.db.bagCustomizer.inventorySlots
					local previousPreset = settings.preset
					-- If switching FROM a custom preset, save current toggle states
					if previousPreset and previousPreset:match("^custom_%d$") then
						local customNum = previousPreset:match("custom_(%d)")
						if customNum then
							local storageKey = "custom" .. customNum .. "PresetSettings"
							-- Ensure the storage exists
							if not E.db.bagCustomizer[storageKey] then
								E.db.bagCustomizer[storageKey] = {}
							end

							-- Save current settings to the appropriate custom storage
							E.db.bagCustomizer[storageKey].disableElvUIHighlight = settings.disableElvUIHighlight
							E.db.bagCustomizer[storageKey].separateEmptyBorder = settings.separateEmptyBorder
							E.db.bagCustomizer[storageKey].applyMainBorderToEmptyAssigned = settings.applyMainBorderToEmptyAssigned
							E.db.bagCustomizer[storageKey].scaleFactor = settings.scaleFactor
							E.db.bagCustomizer[storageKey].globalScaleFactor = settings.globalScaleFactor
						end
					end

					-- Store the new preset value
					settings.preset = value
					-- Clear style component customizations (always reset these)
					settings.BorderStyle = nil
					settings.EmptyStyle = nil
					settings.NormalStyle = nil
					settings.HighlightStyle = nil
					settings.EmptyBorderStyle = nil
					-- Special handling for custom presets
					if value:match("^custom_%d$") then
						local customNum = value:match("custom_(%d)")
						if customNum then
							local storageKey = "custom" .. customNum .. "PresetSettings"
							-- Load saved custom preset settings
							if E.db.bagCustomizer[storageKey] then
								settings.disableElvUIHighlight = E.db.bagCustomizer[storageKey].disableElvUIHighlight
								settings.separateEmptyBorder = E.db.bagCustomizer[storageKey].separateEmptyBorder
								settings.applyMainBorderToEmptyAssigned = E.db.bagCustomizer[storageKey].applyMainBorderToEmptyAssigned
								settings.scaleFactor = E.db.bagCustomizer[storageKey].scaleFactor
								settings.globalScaleFactor = E.db.bagCustomizer[storageKey].globalScaleFactor
							end
						end

						settings.isCustomized = true
					else
						-- For regular presets, apply all preset settings
						local inventorySlots = addon.elements.inventorySlots
						local presetData = inventorySlots.presetComponentMap[value]
						local presetScale = presetData and presetData.ScaleFactor or 100
						settings.scaleFactor = presetScale
						settings.globalScaleFactor = presetScale / 100
						if presetData then
							settings.disableElvUIHighlight = presetData.disableElvUIHighlight or false
							settings.separateEmptyBorder = presetData.separateEmptyBorder or false
							settings.applyMainBorderToEmptyAssigned = presetData.applyMainBorderToEmptyAssigned or false
						else
							settings.disableElvUIHighlight = false
							settings.separateEmptyBorder = false
							settings.applyMainBorderToEmptyAssigned = false
						end

						settings.isCustomized = false
					end

					-- Clear cache and force ALL slots to be re-skinned
					if addon.elements.inventorySlots then
						-- Clear the cache first
						addon.elements.inventorySlots:ClearCache()
						-- Mark all buttons for reprocessing
						for button in pairs(addon.elements.inventorySlots.processedSlots) do
							if button and button._BCZ then
								button._BCZ_forceUpdate = true
							end
						end
					end

					addon:DebouncedUpdate "PresetChanged"
					-- Do a second update after a short delay to catch any stragglers
					C_Timer.After(0.2, function()
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateAll()
						end
					end)
				end,
			},
			--[[			BorderStyleDescriptionGroup = {
				order = 1.55,
				type = "group",
				name = "",
				guiInline = true,
				args = {
					presetDescription = {
						order = 1.55,
						type = "description",
						name = function()
							local preset = E.db.bagCustomizer.inventorySlots and
									E.db.bagCustomizer.inventorySlots.preset or
									"blizzard_modern"
							local descriptions = {
								["blizzard_modern"] =
								"For this style, it is recommended to keep the Separate Border for Empty Slots and Replace ElvUI Mouseover Highlight options enabled in order to replicate the Blizzard inventory as closely as possible.",

								["blizzard_modern_brightened"] =
								"Enhanced Blizzard borders with increased brightness for better visibility, combined with classic Blizzard Textures.",

								["elvui_rounded_border_and_blizzard_texture"] =
								"Rounded ElvUI borders with modern Blizzard slot Textures. It's recommended to use along with Elvui Highlight Rounded.",

								["custom (see instructions)"] =
								"Use your own custom borders and Textures. See instructions below for file requirements.",
							}
							-- Add fallback for any unexpected preset name
							if not descriptions[preset] then
								return "|cff3498dbStandard border and texture style for bag slots.|r"
							end

							return "|cff3498db" .. descriptions[preset] .. "|r"
						end,
						fontSize = "medium",
						width = "full",
						hidden = function()
							return not E.db.bagCustomizer.inventorySlots or
									not E.db.bagCustomizer.inventorySlots.enable
						end,
					},
					customInstructions = {
						order = 1.6,
						type = "description",
						name = function()
							if not E.db.bagCustomizer.inventorySlots or
									not E.db.bagCustomizer.inventorySlots.enable or
									E.db.bagCustomizer.inventorySlots.preset ~= "custom (see instructions)" then
								return ""
							end

							return
							"|cffff8000Custom Style Instructions:|r\nTo use custom borders and Textures, place your files in \\Interface\\AddOns\\BagCustomizer_for_ElvUI\\Media\\Buttons\\  and name them:\n- custom_border.tga\n- custom_texture.tga\n- custom_highlight.tga\n- custom_border_empty.tga (this one is optional)\nYou will need to /reload after adding the files, otherwise the game will not recognize them."
						end,
						fontSize = "medium",
						width = "full",
						hidden = function()
							return not E.db.bagCustomizer.inventorySlots or
									not E.db.bagCustomizer.inventorySlots.enable or
									E.db.bagCustomizer.inventorySlots.preset ~=
									"custom (see instructions)"
						end,
					},
			},
			},--]]
			borderStyle = {
				order = 1.6,
				type = "select",
				name = function()
					local settings = E.db.bagCustomizer.inventorySlots
					local inventorySlots = addon.elements.inventorySlots
					if not settings or not inventorySlots then
						return "Border Style"
					end

					local preset = settings.preset or "blizzard_modern"
					local presetStyle = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].Border
					local currentStyle = settings.BorderStyle
					if currentStyle and presetStyle and currentStyle ~= presetStyle then
						return "|cFFFF5500Border Style (Modified)|r"
					end

					return "Border Style"
				end,
				desc = "Choose a specific border texture",
				width = 1,
				values = function()
					local options = {}
					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return { ["none"] = "None Available" } end

					for key, _ in pairs(inventorySlots.availableTextures.Border) do
						options[key] = key:gsub("_", " "):gsub("^%l", string.upper)
					end

					return options
				end,
				get = function()
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return "blizzard" end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return "blizzard" end

					if settings.BorderStyle then
						return settings.BorderStyle
					else
						local preset = settings.preset or "blizzard_modern"
						if inventorySlots.presetComponentMap[preset] then
							return inventorySlots.presetComponentMap[preset].Border
						end

						return "blizzard"
					end
				end,
				set = function(_, value)
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return end

					settings.BorderStyle = value
					-- Check if this differs from preset
					local preset = settings.preset or "blizzard_modern"
					settings.isCustomized = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].Border ~= value
					-- Update buttons
					if inventorySlots then
						inventorySlots:ClearCache()
						addon:Update "BorderStyleChanged"
					end
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
			},
			emptyStyle = {
				order = 1.7,
				type = "select",
				name = function()
					local settings = E.db.bagCustomizer.inventorySlots
					local inventorySlots = addon.elements.inventorySlots
					if not settings or not inventorySlots then
						return "Slot Texture"
					end

					local preset = settings.preset or "blizzard_modern"
					local presetStyle = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].Empty
					local currentStyle = settings.EmptyStyle
					if currentStyle and presetStyle and currentStyle ~= presetStyle then
						return "|cFFFF5500Slot Texture (Modified)|r"
					end

					return "Slot Texture"
				end,
				desc = "Choose texture for both empty and filled slots",
				width = 1,
				values = function()
					local options = {}
					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return { ["none"] = "None Available" } end

					for key, _ in pairs(inventorySlots.availableTextures.Empty) do
						options[key] = key:gsub("_", " "):gsub("^%l", string.upper)
					end

					return options
				end,
				get = function()
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return "blizzard" end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return "blizzard" end

					if settings.EmptyStyle then
						return settings.EmptyStyle
					else
						local preset = settings.preset or "blizzard_modern"
						if inventorySlots.presetComponentMap[preset] then
							return inventorySlots.presetComponentMap[preset].Empty
						end

						return "blizzard"
					end
				end,
				set = function(_, value)
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return end

					-- Set both Empty and Normal to the same value
					settings.EmptyStyle = value
					settings.NormalStyle = value
					-- Check if this differs from preset
					local preset = settings.preset or "blizzard_modern"
					local wasCustomized = settings.isCustomized
					settings.isCustomized = wasCustomized or
							(inventorySlots.presetComponentMap[preset] and
								inventorySlots.presetComponentMap[preset].Empty ~= value)
					-- Update buttons
					if inventorySlots then
						inventorySlots:ClearCache()
						addon:Update "SlotTextureChanged"
					end
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
			},
			highlightStyle = {
				order = 1.9,
				type = "select",
				name = function()
					local settings = E.db.bagCustomizer.inventorySlots
					local inventorySlots = addon.elements.inventorySlots
					if not settings or not inventorySlots then
						return "Highlight Texture"
					end

					local preset = settings.preset or "blizzard_modern"
					local presetStyle = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].Highlight
					local currentStyle = settings.HighlightStyle
					if currentStyle and presetStyle and currentStyle ~= presetStyle then
						return "|cFFFF5500Highlight Texture (Modified)|r"
					end

					return "Highlight Texture"
				end,
				desc = "Choose a specific highlight texture",
				width = 1,
				values = function()
					local options = {}
					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return { ["none"] = "None Available" } end

					for key, _ in pairs(inventorySlots.availableTextures.Highlight) do
						options[key] = key:gsub("_", " "):gsub("^%l", string.upper)
					end

					return options
				end,
				get = function()
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return "blizzard" end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return "blizzard" end

					if settings.HighlightStyle then
						return settings.HighlightStyle
					else
						local preset = settings.preset or "blizzard_modern"
						if inventorySlots.presetComponentMap[preset] then
							return inventorySlots.presetComponentMap[preset].Highlight
						end

						return "blizzard"
					end
				end,
				set = function(_, value)
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return end

					settings.HighlightStyle = value
					-- Check if this differs from preset
					local preset = settings.preset or "blizzard_modern"
					local wasCustomized = settings.isCustomized
					settings.isCustomized = wasCustomized or
							(inventorySlots.presetComponentMap[preset] and
								inventorySlots.presetComponentMap[preset].Highlight ~= value)
					-- Update buttons
					if inventorySlots then
						inventorySlots:ClearCache()
						addon:Update "HighlightStyleChanged"
					end
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.disableElvUIHighlight
				end,
			},
			emptyBorderStyle = {
				order = 1.96,
				type = "select",
				name = function()
					local settings = E.db.bagCustomizer.inventorySlots
					local inventorySlots = addon.elements.inventorySlots
					if not settings or not inventorySlots then
						return "Empty Slot Border Style"
					end

					local preset = settings.preset or "blizzard_modern"
					local presetStyle = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].EmptyBorder
					local currentStyle = settings.EmptyBorderStyle
					if currentStyle and presetStyle and currentStyle ~= presetStyle then
						return "|cFFFF5500Empty Slot Border Style (Modified)|r"
					end

					return "Empty Slot Border Style"
				end,
				desc = "Choose a specific border texture for empty slots",
				width = 1,
				values = function()
					local options = {}
					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return { ["none"] = "None Available" } end

					for key, _ in pairs(inventorySlots.availableTextures.Border) do
						options[key] = key:gsub("_", " "):gsub("^%l", string.upper)
					end

					return options
				end,
				get = function()
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return "blizzard" end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return "blizzard" end

					if settings.EmptyBorderStyle then
						return settings.EmptyBorderStyle
					else
						-- Use preset's EmptyBorder component if available
						local preset = settings.preset or "blizzard_modern"
						if inventorySlots.presetComponentMap[preset] and inventorySlots.presetComponentMap[preset].EmptyBorder then
							return inventorySlots.presetComponentMap[preset].EmptyBorder
						end

						return "blizzard"
					end
				end,
				set = function(_, value)
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots then return end

					settings.EmptyBorderStyle = value
					-- Check if this differs from preset
					local preset = settings.preset or "blizzard_modern"
					local wasCustomized = settings.isCustomized
					settings.isCustomized = wasCustomized or
							(inventorySlots.presetComponentMap[preset] and
								inventorySlots.presetComponentMap[preset].EmptyBorder ~= value)
					-- Update buttons
					if inventorySlots then
						inventorySlots:ClearCache()
						addon:Update("EmptyBorderStyleChanged")
					end
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.separateEmptyBorder
				end,
			},
			disableElvUIHighlight = {
				order = 3,
				type = "toggle",
				name = function()
					local settings = E.db.bagCustomizer.inventorySlots
					local inventorySlots = addon.elements.inventorySlots
					if not settings or not inventorySlots then
						return "Replace Mouseover Highlight|cFFFFD700*|r"
					end

					local preset = settings.preset or "blizzard_modern"
					local presetValue = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].disableElvUIHighlight
					local currentValue = settings.disableElvUIHighlight
					if currentValue ~= nil and presetValue ~= nil and currentValue ~= presetValue then
						return "|cFFFF5500Replace Mouseover Highlight|cFFFFD700*|r (Modified)|r"
					end

					return "Replace Mouseover Highlight|cFFFFD700*|r"
				end,
				desc =
				"When enabled, removes ElvUI's default highlight effect on bag slots and uses only the custom highlight from this addon. \n\n|cFFFFD700Recommended for rounded edge border style and/or Textures, such as Blizzard Modern.|r",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					return E.db.bagCustomizer.inventorySlots and
							E.db.bagCustomizer.inventorySlots.disableElvUIHighlight
				end,
				set = function(_, value)
					-- Store the new value
					E.db.bagCustomizer.inventorySlots.disableElvUIHighlight = value
					-- If using a custom preset, save to the appropriate custom storage
					local preset = E.db.bagCustomizer.inventorySlots.preset
					if preset and preset:match("^custom_%d$") then
						local customNum = preset:match("custom_(%d)")
						if customNum then
							local storageKey = "custom" .. customNum .. "PresetSettings"
							if not E.db.bagCustomizer[storageKey] then
								E.db.bagCustomizer[storageKey] = {}
							end

							E.db.bagCustomizer[storageKey].disableElvUIHighlight = value
						end
					end

					if addon.elements.inventorySlots then
						addon:DebugPrint("Highlight toggle: " ..
							(value and "DISABLING ElvUI highlight" or "ENABLING ElvUI highlight"))
						-- Marks all buttons for update (no state reset needed)
						addon.elements.inventorySlots:UpdateAllHighlights()
						-- Force a full update to apply any other changes
						addon:Update("HighlightToggle", true)
					end
				end,
			},
			separateEmptyBorder = {
				order = 3.5,
				type = "toggle",
				name = function()
					local settings = E.db.bagCustomizer.inventorySlots
					local inventorySlots = addon.elements.inventorySlots
					if not settings or not inventorySlots then
						return "Separate Border for Empty Slots|cFFFF0000*|r"
					end

					local preset = settings.preset or "blizzard_modern"
					local presetValue = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].separateEmptyBorder
					local currentValue = settings.separateEmptyBorder
					if currentValue ~= nil and presetValue ~= nil and currentValue ~= presetValue then
						return "|cFFFF5500Separate Border for Empty Slots|cFFFF0000*|r (Modified)|r"
					end

					return "Separate Border for Empty Slots|cFFFF0000*|r"
				end,
				desc =
				"When enabled, allows you to select a different border texture for empty inventory slots. \n\n|cFFFF0000Always recommended if the style you're using has a dedicated empty border.|r",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then
						return false
					end

					return E.db.bagCustomizer.inventorySlots.separateEmptyBorder or false
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.separateEmptyBorder = value
					-- If using a custom preset, save to the appropriate custom storage
					local preset = E.db.bagCustomizer.inventorySlots.preset
					if preset and preset:match("^custom_%d$") then
						local customNum = preset:match("custom_(%d)")
						if customNum then
							local storageKey = "custom" .. customNum .. "PresetSettings"
							if not E.db.bagCustomizer[storageKey] then
								E.db.bagCustomizer[storageKey] = {}
							end

							E.db.bagCustomizer[storageKey].separateEmptyBorder = value
						end
					end

					-- Force update
					if addon.elements.inventorySlots then
						addon.elements.inventorySlots:ClearCache()
						addon:Update("SeparateEmptyBorderToggle")
					end
				end,
			},
			applyMainBorderToEmptyAssigned = {
				order = 3.6,
				type = "toggle",
				name = function()
					local settings = E.db.bagCustomizer.inventorySlots
					local inventorySlots = addon.elements.inventorySlots
					if not settings or not inventorySlots then
						return "Apply Main Border to Assigned Empty Slots|cFF00FFFF*|r"
					end

					local preset = settings.preset or "blizzard_modern"
					local presetValue = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].applyMainBorderToEmptyAssigned
					local currentValue = settings.applyMainBorderToEmptyAssigned
					if currentValue ~= nil and presetValue ~= nil and currentValue ~= presetValue then
						return "|cFFFF5500Apply Main Border to Assigned Empty Slots|cFF00FFFF*|r (Modified)|r"
					end

					return "Apply Main Border to Assigned Empty Slots|cFF00FFFF*|r"
				end,
				desc =
				"Forces empty slots in *assigned* bags (e.g., Equipment, Consumables) to use the main 'Border Style', even if 'Separate Border for Empty Slots' is enabled.\n\n|cFF00FFFFRecommended for ElvUI Styles.|r",
				width = 2, -- Use full width
				disabled = function()
					-- Disabled if the main module is disabled OR if separate empty borders are not enabled
					if not E.db.bagCustomizer.inventorySlots then return true end

					return not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.separateEmptyBorder
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then return false end

					return E.db.bagCustomizer.inventorySlots.applyMainBorderToEmptyAssigned or false
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then E.db.bagCustomizer.inventorySlots = {} end

					E.db.bagCustomizer.inventorySlots.applyMainBorderToEmptyAssigned = value
					-- If using a custom preset, save to the appropriate custom storage
					local preset = E.db.bagCustomizer.inventorySlots.preset
					if preset and preset:match("^custom_%d$") then
						local customNum = preset:match("custom_(%d)")
						if customNum then
							local storageKey = "custom" .. customNum .. "PresetSettings"
							if not E.db.bagCustomizer[storageKey] then
								E.db.bagCustomizer[storageKey] = {}
							end

							E.db.bagCustomizer[storageKey].applyMainBorderToEmptyAssigned = value
						end
					end

					-- Clear relevant caches and trigger an update
					if addon.elements.inventorySlots then
						addon.elements.inventorySlots:ClearCache()
						addon:Update("ApplyMainBorderToggle") -- Use a specific reason or refresh group
						-- addon:OptionsRefreshGroup("Bag Customizer", "inventorySlotsGroup")
					end
				end,
			},
			scaleFactor = {
				order = 4,
				type = "range",
				name = function()
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then
						return "Scale"
					end

					local preset = settings.preset or "blizzard_modern"
					local inventorySlots = addon.elements.inventorySlots
					local presetScale = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].ScaleFactor or 100
					local currentScale = settings.scaleFactor or 100
					if currentScale ~= presetScale then
						return "|cFFFF5500Scale Factor (Modified)|cFF00BBFF*|r"
					end

					return "Scale|r"
				end,
				desc =
				"Scale all border elements by this percentage. I recommend using values around 105.",
				min = 50,
				max = 200,
				step = 1,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					return E.db.bagCustomizer.inventorySlots and
							E.db.bagCustomizer.inventorySlots.scaleFactor or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					-- Store as percentage in options
					E.db.bagCustomizer.inventorySlots.scaleFactor = value
					-- Convert to decimal for the global scale factor
					E.db.bagCustomizer.inventorySlots.globalScaleFactor = value / 100
					-- Check if this differs from preset scale
					local preset = E.db.bagCustomizer.inventorySlots.preset or "blizzard_modern"
					local inventorySlots = addon.elements.inventorySlots
					local presetScale = inventorySlots.presetComponentMap[preset] and
							inventorySlots.presetComponentMap[preset].ScaleFactor or 100
					local wasCustomized = E.db.bagCustomizer.inventorySlots.isCustomized
					E.db.bagCustomizer.inventorySlots.isCustomized = wasCustomized or
							(value ~= presetScale)
					-- Call the update function
					addon.elements.inventorySlots:UpdateAllScales()
				end,
			},
			resetToPreset = {
				order = 99,
				type = "execute",
				name = "Reset to Preset Defaults",
				width = 4,
				hidden = function()
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then
						return true
					end

					local preset = settings.preset or "blizzard_modern"
					-- Always hide for custom presets
					if preset:match("^custom_%d$") then
						return true
					end

					local inventorySlots = addon.elements.inventorySlots
					if not inventorySlots or not inventorySlots.presetComponentMap then
						return true
					end

					local presetData = inventorySlots.presetComponentMap[preset]
					if not presetData then
						return true
					end

					local presetScale = presetData.ScaleFactor or 100
					local currentScale = settings.scaleFactor or 100
					local scaleModified = currentScale ~= presetScale
					-- Check if any of the new toggle options differ from preset defaults
					local highlightModified = settings.disableElvUIHighlight ~= (presetData.disableElvUIHighlight or false)
					local emptyBorderModified = settings.separateEmptyBorder ~= (presetData.separateEmptyBorder or false)
					local emptyAssignedModified = settings.applyMainBorderToEmptyAssigned ~=
							(presetData.applyMainBorderToEmptyAssigned or false)
					-- Show reset button if any setting is customized or modified
					return not (settings.isCustomized or scaleModified or
						highlightModified or emptyBorderModified or emptyAssignedModified)
				end,
				func = function()
					local settings = E.db.bagCustomizer.inventorySlots
					if not settings then return end

					-- Clear all component overrides
					settings.BorderStyle = nil
					settings.EmptyStyle = nil
					settings.NormalStyle = nil
					settings.HighlightStyle = nil
					settings.EmptyBorderStyle = nil
					-- Get the preset data
					local preset = settings.preset or "blizzard_modern"
					local inventorySlots = addon.elements.inventorySlots
					local presetData = inventorySlots.presetComponentMap[preset]
					-- Reset scale factor to preset's default
					local presetScale = presetData and presetData.ScaleFactor or 100
					settings.scaleFactor = presetScale
					settings.globalScaleFactor = presetScale / 100
					-- Reset the three toggle options to preset defaults
					if presetData then
						settings.disableElvUIHighlight = presetData.disableElvUIHighlight or false
						settings.separateEmptyBorder = presetData.separateEmptyBorder or false
						settings.applyMainBorderToEmptyAssigned = presetData.applyMainBorderToEmptyAssigned or false
					else
						-- Default values if preset data not found
						settings.disableElvUIHighlight = false
						settings.separateEmptyBorder = false
						settings.applyMainBorderToEmptyAssigned = false
					end

					settings.isCustomized = false
					-- Update UI
					if addon.elements.inventorySlots then
						addon.elements.inventorySlots:ClearCache()
						-- Force update on all buttons
						for button in pairs(addon.elements.inventorySlots.processedSlots) do
							if button and button._BCZ then
								button._BCZ_forceUpdate = true
							end
						end

						addon.elements.inventorySlots:UpdateAllScales()
						addon:Update "ResetToPreset"
					end
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
			},
		},
	}
	return inventorySlotsMainOptions
end

local function CreateInventorySlotsBrightnessOptions()
	local inventorySlotsBrightnessOptions = {
		order = 3,
		type = "group",
		name = "Borders Brightness Settings",
		guiInline = true,
		childGroups = "flow",
		args = {
			-- GLOBAL BRIGHTNESS CONTROL
			globalBrightness = {
				order = 2,
				type = "range",
				name = "Border Brightness for all inventory slots",
				desc =
				"Adjust the brightness of ALL borders. This affects all item quality borders and empty slot borders.",
				min = 10,
				max = 200,
				step = 5,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.globalBrightness or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.globalBrightness = value
					-- Update all borders immediately
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						-- Fallback to the old method if UpdateAllBrightness isn't available
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			-- TOGGLE FOR INDIVIDUAL BRIGHTNESS CONTROLS
			showIndividualBrightness = {
				order = 3,
				type = "toggle",
				name = "Individual Border Brightness Fine-Tuning",
				desc = "",
				width = "full",
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then
						return false
					end

					return E.db.bagCustomizer.inventorySlots.showIndividualBrightness or false
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.showIndividualBrightness = value
				end,
			},
			-- ITEM QUALITY SLIDERS
			poorBrightness = {
				order = 6,
				type = "range",
				name = "Poor",
				desc = "Adjust the brightness of borders for Poor (gray) quality items",
				width = 1,
				min = 10,
				max = 200,
				step = 5,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityBrightness[0] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						E.db.bagCustomizer.inventorySlots.qualityBrightness = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityBrightness[0] = value
					-- Use UpdateAllBrightness if available, otherwise fall back
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			commonBrightness = {
				order = 7,
				type = "range",
				name = "Common",
				desc = "Adjust the brightness of borders for Common (white) quality items",
				width = 1,
				min = 10,
				max = 200,
				step = 5,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityBrightness[1] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						E.db.bagCustomizer.inventorySlots.qualityBrightness = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityBrightness[1] = value
					-- Use UpdateAllBrightness if available
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			uncommonBrightness = {
				order = 8,
				type = "range",
				name = "Uncommon",
				desc = "Adjust the brightness of borders for Uncommon (green) quality items",
				width = 1,
				min = 10,
				max = 200,
				step = 5,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityBrightness[2] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						E.db.bagCustomizer.inventorySlots.qualityBrightness = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityBrightness[2] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			rareBrightness = {
				order = 9,
				type = "range",
				name = "Rare",
				desc = "Adjust the brightness of borders for Rare (blue) quality items",
				width = 1,
				min = 10,
				max = 200,
				step = 5,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityBrightness[3] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						E.db.bagCustomizer.inventorySlots.qualityBrightness = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityBrightness[3] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			epicBrightness = {
				order = 10,
				type = "range",
				name = "Epic",
				desc = "Adjust the brightness of borders for Epic (purple) quality items",
				width = 1,
				min = 10,
				max = 200,
				step = 5,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityBrightness[4] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						E.db.bagCustomizer.inventorySlots.qualityBrightness = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityBrightness[4] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			legendaryBrightness = {
				order = 11,
				type = "range",
				name = "Legendary",
				desc = "Adjust the brightness of borders for Legendary (orange) quality items",
				width = 1,
				min = 10,
				max = 200,
				step = 5,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityBrightness[5] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						E.db.bagCustomizer.inventorySlots.qualityBrightness = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityBrightness[5] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			artifactBrightness = {
				order = 12,
				type = "range",
				name = "Artifact",
				desc =
				"Adjust the brightness of borders for Artifact (light yellow) quality items",
				width = 1,
				min = 10,
				max = 200,
				step = 5,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityBrightness[6] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						E.db.bagCustomizer.inventorySlots.qualityBrightness = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityBrightness[6] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			heirloomBrightness = {
				order = 13,
				type = "range",
				name = "Heirloom",
				desc = "Adjust the brightness of borders for Heirloom (light blue) quality items",
				width = 1,
				min = 10,
				max = 200,
				step = 5,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityBrightness[7] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityBrightness then
						E.db.bagCustomizer.inventorySlots.qualityBrightness = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityBrightness[7] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			-- EMPTY SLOT BRIGHTNESS SLIDERS
			unassignedEmptySlotBrightness = {
				order = 15,
				type = "range",
				name = "Empty Slots",
				desc = "Adjust the brightness of borders for unassigned empty bag slots",
				min = 10,
				max = 200,
				step = 5,
				width = 2,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.emptySlotBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.emptySlotBrightness.unassigned or
							100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.emptySlotBrightness then
						E.db.bagCustomizer.inventorySlots.emptySlotBrightness = {
							unassigned = 100,
							assigned = 100,
						}
					end

					E.db.bagCustomizer.inventorySlots.emptySlotBrightness.unassigned = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
			assignedEmptySlotBrightness = {
				order = 16,
				type = "range",
				name = "Assigned Empty Slots",
				desc =
				"Adjust the brightness of borders for assigned empty bag slots (e.g., reagent bags, equipment bags)",
				min = 10,
				max = 200,
				step = 5,
				width = 2,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualBrightness
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.emptySlotBrightness then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.emptySlotBrightness.assigned or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.emptySlotBrightness then
						E.db.bagCustomizer.inventorySlots.emptySlotBrightness = {
							unassigned = 100,
							assigned = 100,
						}
					end

					E.db.bagCustomizer.inventorySlots.emptySlotBrightness.assigned = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllBrightness then
						addon.elements.inventorySlots:UpdateAllBrightness()
					else
						if addon.elements.inventorySlots then
							addon.elements.inventorySlots:UpdateBorderColors()
						end
					end
				end,
			},
		},
	}
	return inventorySlotsBrightnessOptions
end

local function CreateInventorySlotsIntensityOptions()
	local inventorySlotsIntensityOptions = {
		order = 4,
		type = "group",
		name = "Borders Color Intensity Settings",
		guiInline = true,
		childGroups = "flow",
		args = {
			-- GLOBAL COLOR INTENSITY CONTROL
			globalColorIntensityHeader = {
				order = 1,
				type = "description",
				name =
				"",
				fontSize = "medium",
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
			},
			globalColorIntensity = {
				order = 2,
				type = "range",
				name = "Color Intensity for all inventory slots",
				desc =
				"Adjust the color intensity of ALL borders. Higher values create more vivid colors with greater contrast.",
				min = 0,
				max = 300,
				step = 10,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.globalColorIntensity or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.globalColorIntensity = value
					-- Update all borders immediately
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			-- TOGGLE FOR INDIVIDUAL COLOR INTENSITY CONTROLS
			showIndividualColorIntensity = {
				order = 3,
				type = "toggle",
				name = "Individual Color Intensity Fine-Tuning",
				desc =
				"Allows you to customize color intensity for each quality level separately",
				width = "full",
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then
						return false
					end

					return E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity or
							false
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity = value
				end,
			},
			-- ITEM QUALITY SLIDERS
			poorColorIntensity = {
				order = 6,
				type = "range",
				name = "Poor",
				desc = "Adjust the color intensity of borders for Poor (gray) quality items",
				width = 1,
				min = 0,
				max = 300,
				step = 10,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityColorIntensity[0] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						E.db.bagCustomizer.inventorySlots.qualityColorIntensity = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityColorIntensity[0] = value
					-- Use UpdateAllColorSettings if available
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			commonColorIntensity = {
				order = 7,
				type = "range",
				name = "Common",
				desc = "Adjust the color intensity of borders for Common (white) quality items",
				width = 1,
				min = 0,
				max = 300,
				step = 10,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityColorIntensity[1] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						E.db.bagCustomizer.inventorySlots.qualityColorIntensity = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityColorIntensity[1] = value
					-- Use UpdateAllColorSettings if available
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			uncommonColorIntensity = {
				order = 8,
				type = "range",
				name = "Uncommon",
				desc = "Adjust the color intensity of borders for Uncommon (green) quality items",
				width = 1,
				min = 0,
				max = 300,
				step = 10,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityColorIntensity[2] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						E.db.bagCustomizer.inventorySlots.qualityColorIntensity = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityColorIntensity[2] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			rareColorIntensity = {
				order = 9,
				type = "range",
				name = "Rare",
				desc = "Adjust the color intensity of borders for Rare (blue) quality items",
				width = 1,
				min = 0,
				max = 300,
				step = 10,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityColorIntensity[3] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						E.db.bagCustomizer.inventorySlots.qualityColorIntensity = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityColorIntensity[3] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			epicColorIntensity = {
				order = 10,
				type = "range",
				name = "Epic",
				desc = "Adjust the color intensity of borders for Epic (purple) quality items",
				width = 1,
				min = 0,
				max = 300,
				step = 10,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityColorIntensity[4] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						E.db.bagCustomizer.inventorySlots.qualityColorIntensity = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityColorIntensity[4] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			legendaryColorIntensity = {
				order = 11,
				type = "range",
				name = "Legendary",
				desc =
				"Adjust the color intensity of borders for Legendary (orange) quality items",
				width = 1,
				min = 0,
				max = 300,
				step = 10,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityColorIntensity[5] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						E.db.bagCustomizer.inventorySlots.qualityColorIntensity = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityColorIntensity[5] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			artifactColorIntensity = {
				order = 12,
				type = "range",
				name = "Artifact",
				desc =
				"Adjust the color intensity of borders for Artifact (light yellow) quality items",
				width = 1,
				min = 0,
				max = 300,
				step = 10,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityColorIntensity[6] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						E.db.bagCustomizer.inventorySlots.qualityColorIntensity = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityColorIntensity[6] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			heirloomColorIntensity = {
				order = 13,
				type = "range",
				name = "Heirloom",
				desc =
				"Adjust the color intensity of borders for Heirloom (light blue) quality items",
				width = 1,
				min = 0,
				max = 300,
				step = 10,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.qualityColorIntensity[7] or 100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.qualityColorIntensity then
						E.db.bagCustomizer.inventorySlots.qualityColorIntensity = {}
					end

					E.db.bagCustomizer.inventorySlots.qualityColorIntensity[7] = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			-- EMPTY SLOT COLOR INTENSITY SLIDERS
			unassignedEmptySlotColorIntensity = {
				order = 15,
				type = "range",
				name = "Empty Slots",
				desc = "Adjust the color intensity of borders for unassigned empty bag slots",
				min = 0,
				max = 300,
				step = 10,
				width = 2,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity.unassigned or
							100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity then
						E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity = {
							unassigned = 100,
							assigned = 100,
						}
					end

					E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity.unassigned = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
			assignedEmptySlotColorIntensity = {
				order = 16,
				type = "range",
				name = "Assigned Empty Slots",
				desc =
				"Adjust the color intensity of borders for assigned empty bag slots (e.g., reagent bags, equipment bags)",
				min = 0,
				max = 300,
				step = 10,
				width = 2,
				hidden = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showIndividualColorIntensity
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity then
						return 100
					end

					return E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity.assigned or
							100
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					if not E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity then
						E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity = {
							unassigned = 100,
							assigned = 100,
						}
					end

					E.db.bagCustomizer.inventorySlots.emptySlotColorIntensity.assigned = value
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllColorSettings then
						addon.elements.inventorySlots:UpdateAllColorSettings()
					elseif addon.elements.inventorySlots then
						addon.elements.inventorySlots:UpdateBorderColors()
					end
				end,
			},
		},
	}
	return inventorySlotsIntensityOptions
end

local function CreateInventorySlotsMiscOptions()
	local inventorySlotsMiscOptions = {
		order = 6,
		type = "group",
		name = "Misc",
		guiInline = true,
		childGroups = "flow",
		args = {
			colorEmptySlotsByAssignment = {
				order = 2,
				type = "toggle",
				name = "Color Empty Slots by Bag Assignment",
				desc = "When enabled, empty slots will be colored based on their bag assignment (e.g. green for consumables)",
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then
						return false
					end

					return E.db.bagCustomizer.inventorySlots.colorEmptySlotsByAssignment or false
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.colorEmptySlotsByAssignment = value
					-- Update all empty slot textures
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllEmptySlotTextures then
						addon.elements.inventorySlots:UpdateAllEmptySlotTextures()
					end
				end,
			},
			emptySlotTextureAlpha = {
				order = 3,
				type = "range",
				name = "Empty Slot Texture Opacity",
				desc = "Adjust the opacity of empty slot textures",
				min = 0,
				max = 1,
				step = 0.05,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots then
						return 1.0
					end

					return E.db.bagCustomizer.inventorySlots.emptySlotTextureAlpha or 1.0
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.emptySlotTextureAlpha = value
					-- Update all empty slot textures
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllEmptySlotTextures then
						addon.elements.inventorySlots:UpdateAllEmptySlotTextures()
					end
				end,
			},
			textureSpacing1 = {
				order = 4,
				type = "description",
				name = " ",
				width = "full",
			},
			emptySlotAlphaAssigned = {
				order = 5,
				type = "range",
				name = "Assigned bags overlay strength",
				desc = "Adjust the strength of the overlay for empty bag slots from assigned bags",
				min = 0,
				max = 1,
				step = 0.05,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
				get = function()
					if not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.emptySlotAlphaAssigned then
						return 1.0
					end

					return E.db.bagCustomizer.inventorySlots.emptySlotAlphaAssigned
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.inventorySlots then
						E.db.bagCustomizer.inventorySlots = {}
					end

					E.db.bagCustomizer.inventorySlots.emptySlotAlphaAssigned = value
					-- Update all empty slot textures
					if addon.elements.inventorySlots and addon.elements.inventorySlots.UpdateAllEmptySlotTextures then
						addon.elements.inventorySlots:UpdateAllEmptySlotTextures()
					end
				end,
			},
			showPoorQualityBorders = {
				order = 21,
				type = "toggle",
				name = "Show Poor Quality Borders",
				desc = "Show borders for Poor (gray) quality items",
				width = 2,
				get = function() return E.db.bagCustomizer.inventorySlots.showPoorQualityBorders end,
				set = function(_, value)
					E.db.bagCustomizer.inventorySlots.showPoorQualityBorders = value
					addon.elements.inventorySlots:UpdateAllColorSettings()
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
			},
			poorQualityColor = {
				order = 22,
				type = "color",
				name = "Poor Quality Color",
				desc = "Border color for Poor quality items",
				width = 2,
				get = function()
					local color = E.db.bagCustomizer.inventorySlots.poorQualityColor or
							{ r = 0.61, g = 0.61, b = 0.61 }
					return color.r, color.g, color.b
				end,
				set = function(_, r, g, b)
					E.db.bagCustomizer.inventorySlots.poorQualityColor = E.db.bagCustomizer
							.inventorySlots.poorQualityColor or {}
					E.db.bagCustomizer.inventorySlots.poorQualityColor.r = r
					E.db.bagCustomizer.inventorySlots.poorQualityColor.g = g
					E.db.bagCustomizer.inventorySlots.poorQualityColor.b = b
					addon.elements.inventorySlots:UpdateAllColorSettings()
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showPoorQualityBorders
				end,
			},
			showCommonQualityBorders = {
				order = 23,
				type = "toggle",
				name = "Show Common Quality Borders",
				desc = "Show borders for Common (white) quality items",
				width = 2,
				get = function()
					return E.db.bagCustomizer.inventorySlots
							.showCommonQualityBorders
				end,
				set = function(_, value)
					E.db.bagCustomizer.inventorySlots.showCommonQualityBorders = value
					addon.elements.inventorySlots:UpdateAllColorSettings()
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable
				end,
			},
			commonQualityColor = {
				order = 24,
				type = "color",
				name = "Common Quality Color",
				desc = "Border color for Common quality items",
				width = 2,
				get = function()
					local color = E.db.bagCustomizer.inventorySlots.commonQualityColor or
							{ r = 1, g = 1, b = 1 }
					return color.r, color.g, color.b
				end,
				set = function(_, r, g, b)
					E.db.bagCustomizer.inventorySlots.commonQualityColor = E.db.bagCustomizer
							.inventorySlots.commonQualityColor or {}
					E.db.bagCustomizer.inventorySlots.commonQualityColor.r = r
					E.db.bagCustomizer.inventorySlots.commonQualityColor.g = g
					E.db.bagCustomizer.inventorySlots.commonQualityColor.b = b
					addon.elements.inventorySlots:UpdateAllColorSettings()
				end,
				disabled = function()
					return not E.db.bagCustomizer.inventorySlots or
							not E.db.bagCustomizer.inventorySlots.enable or
							not E.db.bagCustomizer.inventorySlots.showCommonQualityBorders
				end,
			},
		},
	}
	return inventorySlotsMiscOptions
end

-- MainTextures.lua
local function CreateTopTextureGroupOptions()
	local topTextureGroupOptions = {
		order = 2,
		type = "group",
		name = "Top Texture",
		guiInline = true,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable Module",
				width = 2,
				get = function()
					if not E.db.bagCustomizer.topTexture then
						E.db.bagCustomizer.topTexture = {
							enable = false,
							texture = "UIFrameMetal2xa2_top.tga",
							alpha = 0.7,
							scale = 1.0,
							point = "TOP",
							xOffset = 0,
							yOffset = 0,
							height = 50,
						}
					end

					return E.db.bagCustomizer.topTexture.enable
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.topTexture then
						E.db.bagCustomizer.topTexture = {
							enable = value,
							texture = "UIFrameMetal2xa2_top.tga",
							alpha = 0.7,
							scale = 1.0,
							point = "TOP",
							xOffset = 0,
							yOffset = 0,
							height = 50,
						}
					else
						E.db.bagCustomizer.topTexture.enable = value
					end

					C_Timer.After(0.1, function()
						addon:DebouncedUpdate()
					end)
				end,
			},
			texture = {
				order = 2,
				type = "select",
				name = "Texture Style",
				desc = "Select a texture for the top frame",
				width = 2,
				values = addon.textureOptions.topTexture,
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function() return E.db.bagCustomizer.topTexture.texture end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.texture = value
					addon:DebouncedUpdate()
				end,
			},
			textureHeader = {
				order = 2.1,
				type = "header",
				name = "Texture general Settings",
				width = "full",
			},
			scale = {
				order = 3,
				type = "range",
				name = "Scale",
				min = 0.1,
				max = 3,
				step = 0.01,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function() return E.db.bagCustomizer.topTexture.scale end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.scale = value
					addon:DebouncedUpdate()
				end,
			},
			alpha = {
				order = 4,
				type = "range",
				name = "Opacity",
				min = 0,
				max = 1,
				step = 0.01,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function() return E.db.bagCustomizer.topTexture.alpha end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.alpha = value
					addon:DebouncedUpdate()
				end,
			},
			xOffset = {
				order = 5,
				type = "range",
				name = "X Offset",
				min = -100,
				max = 100,
				step = 1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function() return E.db.bagCustomizer.topTexture.xOffset end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.xOffset = value
					addon:DebouncedUpdate()
				end,
			},
			yOffset = {
				order = 6,
				type = "range",
				name = "Y Offset",
				min = -100,
				max = 100,
				step = 1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function() return E.db.bagCustomizer.topTexture.yOffset end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.yOffset = value
					addon:DebouncedUpdate()
				end,
			},
			widthAdjust = {
				order = 6.9,
				type = "range",
				name = "Width Adjustment",
				desc = "Adjust the width of the top texture by adding or subtracting pixels.",
				min = -20,
				max = 20,
				step = 1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function() return E.db.bagCustomizer.topTexture.widthAdjust or 0 end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.widthAdjust = value
					addon:DebouncedUpdate()
				end,
			},
			heightAdjust = {
				order = 7,
				type = "range",
				name = "Height Adjust",
				min = 0,
				max = 200,
				step = 1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function() return E.db.bagCustomizer.topTexture.height end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.height = value
					addon:DebouncedUpdate()
				end,
			},
			sliceHeader = {
				order = 7.1,
				type = "header",
				name = "3 Slice Settings",
				width = "full",
			},
			useSlice = {
				order = 7.1,
				type = "toggle",
				name = "Use 3-Slice Scaling",
				desc = "Split the texture into 3 parts: left, middle, and right edges",
				width = 2,
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function()
					if not E.db.bagCustomizer.topTexture.useSlice then
						E.db.bagCustomizer.topTexture.useSlice = false
					end

					return E.db.bagCustomizer.topTexture.useSlice
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.useSlice = value
					addon:DebouncedUpdate()
				end,
			},
			useTiling = {
				order = 7.2,
				type = "toggle",
				name = "Tile Middle Section",
				desc = "Tile the middle section instead of stretching it",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.topTexture.enable or
							not E.db.bagCustomizer.topTexture.useSlice
				end,
				get = function()
					if not E.db.bagCustomizer.topTexture.useTiling then
						E.db.bagCustomizer.topTexture.useTiling = false
					end

					return E.db.bagCustomizer.topTexture.useTiling
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.useTiling = value
					addon:DebouncedUpdate()
				end,
			},
			edgeSize = {
				order = 7.21,
				type = "range",
				name = "Edge Size",
				desc = "Width of the left and right edge portions",
				min = 5,
				max = 50,
				step = 1,
				width = 4,
				disabled = function()
					return not E.db.bagCustomizer.topTexture.enable or
							not E.db.bagCustomizer.topTexture.useSlice
				end,
				get = function()
					if not E.db.bagCustomizer.topTexture.edgeSize then
						E.db.bagCustomizer.topTexture.edgeSize = 24
					end

					return E.db.bagCustomizer.topTexture.edgeSize
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.edgeSize = value
					addon:DebouncedUpdate()
				end,
			},
			leftBreakPct = {
				order = 7.3,
				type = "range",
				name = "Left Edge %",
				desc = "Where the left edge ends (percentage of texture width)",
				min = 5,
				max = 45,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.topTexture.enable or
							not E.db.bagCustomizer.topTexture.useSlice
				end,
				get = function()
					if not E.db.bagCustomizer.topTexture.leftBreakPct then
						E.db.bagCustomizer.topTexture.leftBreakPct = 15
					end

					return E.db.bagCustomizer.topTexture.leftBreakPct
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.leftBreakPct = value
					if E.db.bagCustomizer.topTexture.rightBreakPct <= value + 10 then
						E.db.bagCustomizer.topTexture.rightBreakPct = math.min(value + 10, 95)
					end

					addon:DebouncedUpdate()
				end,
			},
			rightBreakPct = {
				order = 7.4,
				type = "range",
				name = "Right Edge %",
				desc = "Where the right edge begins (percentage of texture width)",
				min = 55,
				max = 95,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.topTexture.enable or
							not E.db.bagCustomizer.topTexture.useSlice
				end,
				get = function()
					if not E.db.bagCustomizer.topTexture.rightBreakPct then
						E.db.bagCustomizer.topTexture.rightBreakPct = 85
					end

					return E.db.bagCustomizer.topTexture.rightBreakPct
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.rightBreakPct = value
					if E.db.bagCustomizer.topTexture.leftBreakPct >= value - 10 then
						E.db.bagCustomizer.topTexture.leftBreakPct = math.max(value - 10, 5)
					end

					addon:DebouncedUpdate()
				end,
			},
			tileSpacing = {
				order = 7.6,
				type = "range",
				name = "Tile Spacing",
				desc = "Space between each tile in pixels",
				min = -10,
				max = 20,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.topTexture.enable or
							not E.db.bagCustomizer.topTexture.useSlice or
							not E.db.bagCustomizer.topTexture.useTiling
				end,
				get = function()
					if not E.db.bagCustomizer.topTexture.tileSpacing then
						E.db.bagCustomizer.topTexture.tileSpacing = 0
					end

					return E.db.bagCustomizer.topTexture.tileSpacing
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.tileSpacing = value
					addon:DebouncedUpdate()
				end,
			},
			tileOffset = {
				order = 7.7,
				type = "range",
				name = "Tile Offset",
				desc = "Horizontal offset to start tiling from",
				min = -50,
				max = 50,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.topTexture.enable or
							not E.db.bagCustomizer.topTexture.useSlice or
							not E.db.bagCustomizer.topTexture.useTiling
				end,
				get = function()
					if not E.db.bagCustomizer.topTexture.tileOffset then
						E.db.bagCustomizer.topTexture.tileOffset = 0
					end

					return E.db.bagCustomizer.topTexture.tileOffset
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.tileOffset = value
					addon:DebouncedUpdate()
				end,
			},
			manualDimensions = {
				order = 8.0,
				type = "toggle",
				name = "Manual Dimensions for 3-Slice",
				desc =
				"Specify texture dimensions manually. This is only useful if you use 3 Slice and the texture you're trying to use is not exactly 200x30.",
				width = "full",
				disabled = function() return not E.db.bagCustomizer.topTexture.enable end,
				get = function() return E.db.bagCustomizer.topTexture.manualDimensions end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.manualDimensions = value
					addon:DebouncedUpdate()
				end,
			},
			textureWidth = {
				order = 8.1,
				type = "range",
				name = "Texture Width",
				min = 50,
				max = 512,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.topTexture.enable or
							not E.db.bagCustomizer.topTexture.manualDimensions
				end,
				get = function()
					return E.db.bagCustomizer.topTexture.textureWidth or 200
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.textureWidth = value
					addon:DebouncedUpdate()
				end,
			},
			textureHeight = {
				order = 8.2,
				type = "range",
				name = "Texture Height",
				min = 10,
				max = 256,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.topTexture.enable or
							not E.db.bagCustomizer.topTexture.manualDimensions
				end,
				get = function()
					return E.db.bagCustomizer.topTexture.textureHeight or 30
				end,
				set = function(_, value)
					E.db.bagCustomizer.topTexture.textureHeight = value
					addon:DebouncedUpdate()
				end,
			},
		},
	}
	return topTextureGroupOptions
end

local function CreateUiBackgroundGroupOptions()
	local uiBackgroundGroupOptions = {
		order = 4,
		type = "group",
		name = "UI Background Texture",
		guiInline = true,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable UI Background",
				width = 2,
				get = function()
					if not E.db.bagCustomizer.uiBackground then
						E.db.bagCustomizer.uiBackground = {
							enable = false,
							texture = "background.tga",
							alpha = 0.5,
							scale = 1.0,
							point = "CENTER",
							xOffset = 0,
							yOffset = 0,
						}
					end

					return E.db.bagCustomizer.uiBackground.enable
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.uiBackground then
						E.db.bagCustomizer.uiBackground = {
							enable = value,
							texture = "background.tga",
							alpha = 0.5,
							scale = 1.0,
							point = "CENTER",
							xOffset = 0,
							yOffset = 0,
						}
					else
						E.db.bagCustomizer.uiBackground.enable = value
					end

					addon:DebouncedUpdate()
				end,
			},
			texture = {
				order = 2,
				type = "select",
				name = "Texture Style",
				desc = "Select a texture for the UI background",
				width = 2,
				values = addon.textureOptions.uiBackground,
				disabled = function() return not E.db.bagCustomizer.uiBackground.enable end,
				get = function() return E.db.bagCustomizer.uiBackground.texture end,
				set = function(_, value)
					E.db.bagCustomizer.uiBackground.texture = value
					addon:DebouncedUpdate()
				end,
			},
			scale = {
				order = 3,
				type = "range",
				name = "Scale",
				min = 0.1,
				max = 3,
				step = 0.1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.uiBackground.enable end,
				get = function() return E.db.bagCustomizer.uiBackground.scale end,
				set = function(_, value)
					E.db.bagCustomizer.uiBackground.scale = value
					addon:DebouncedUpdate()
				end,
			},
			alpha = {
				order = 4,
				type = "range",
				name = "Opacity",
				min = 0,
				max = 1,
				step = 0.01,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.uiBackground.enable end,
				get = function() return E.db.bagCustomizer.uiBackground.alpha end,
				set = function(_, value)
					E.db.bagCustomizer.uiBackground.alpha = value
					addon:DebouncedUpdate()
				end,
			},
			positionHeader = {
				order = 5,
				type = "header",
				name = "Position",
				width = "full",
			},
			xOffset = {
				order = 6,
				type = "range",
				name = "X Offset",
				desc = "Horizontal offset from the anchor point",
				min = -100,
				max = 100,
				step = 1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.uiBackground.enable end,
				get = function() return E.db.bagCustomizer.uiBackground.xOffset or 0 end,
				set = function(_, value)
					E.db.bagCustomizer.uiBackground.xOffset = value
					addon:DebouncedUpdate()
				end,
			},
			yOffset = {
				order = 7,
				type = "range",
				name = "Y Offset",
				desc = "Vertical offset from the anchor point",
				min = -100,
				max = 100,
				step = 1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.uiBackground.enable end,
				get = function() return E.db.bagCustomizer.uiBackground.yOffset or 0 end,
				set = function(_, value)
					E.db.bagCustomizer.uiBackground.yOffset = value
					addon:DebouncedUpdate()
				end,
			},
			anchorPoint = {
				order = 8,
				type = "select",
				name = "Anchor Point",
				desc = "Choose where to anchor the texture on the frame",
				width = 4,
				values = {
					["CENTER"] = "Center",
					["TOP"] = "Top",
					["BOTTOM"] = "Bottom",
					["LEFT"] = "Left",
					["RIGHT"] = "Right",
					["TOPLEFT"] = "Top Left",
					["TOPRIGHT"] = "Top Right",
					["BOTTOMLEFT"] = "Bottom Left",
					["BOTTOMRIGHT"] = "Bottom Right",
				},
				disabled = function() return not E.db.bagCustomizer.uiBackground.enable end,
				get = function() return E.db.bagCustomizer.uiBackground.point or "CENTER" end,
				set = function(_, value)
					E.db.bagCustomizer.uiBackground.point = value
					addon:DebouncedUpdate()
				end,
			},
		},
	}
	return uiBackgroundGroupOptions
end

local function CreateArtBackgroundGroupOptions()
	local artBackgroundGroupOptions = {
		order = 5,
		type = "group",
		name = "Artistic Background",
		guiInline = true,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable Art Background",
				desc = "Show character art, landscapes, or custom images behind your inventory",
				width = 2,
				get = function()
					if not E.db.bagCustomizer.artBackground then
						E.db.bagCustomizer.artBackground = {
							enable = false,
							texture = "character.tga",
							alpha = 0.7,
							scale = 1.0,
							point = "CENTER",
							xOffset = 0,
							yOffset = 0,
							horizontalSize = 100,
							verticalSize = 100,
							cropHorizontally = false,
							cropVertically = false,
							cropHorizontalAmount = 20,
							cropVerticalAmount = 20,
							useEdgeFade = false,
							edgeFadeAmount = 0.3,
							desaturate = false,
							useTint = false,
							tintColor = { r = 1, g = 1, b = 1 },
						}
					end

					return E.db.bagCustomizer.artBackground.enable
				end,
				set = function(_, value)
					if not E.db.bagCustomizer.artBackground then
						E.db.bagCustomizer.artBackground = {
							enable = value,
							texture = "character.tga",
							alpha = 0.7,
							scale = 1.0,
							point = "CENTER",
							xOffset = 0,
							yOffset = 0,
							horizontalSize = 100,
							verticalSize = 100,
							cropHorizontally = false,
							cropVertically = false,
							cropHorizontalAmount = 20,
							cropVerticalAmount = 20,
							useEdgeFade = false,
							edgeFadeAmount = 0.3,
							desaturate = false,
							useTint = false,
							tintColor = { r = 1, g = 1, b = 1 },
						}
					else
						E.db.bagCustomizer.artBackground.enable = value
					end

					addon:DebouncedUpdate()
				end,
			},
			texture = {
				order = 2,
				type = "select",
				name = "Texture Style",
				desc = "Select a background art image",
				width = 2,
				values = addon.textureOptions.artBackground,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.texture end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.texture = value
					addon:DebouncedUpdate()
				end,
			},
			scale = {
				order = 3,
				type = "range",
				name = "Overall Scale",
				min = 0.1,
				max = 3,
				step = 0.1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.scale end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.scale = value
					addon:DebouncedUpdate()
				end,
			},
			alpha = {
				order = 4,
				type = "range",
				name = "Opacity",
				min = 0,
				max = 1,
				step = 0.01,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.alpha end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.alpha = value
					addon:DebouncedUpdate()
				end,
			},
			positionHeader = {
				order = 5,
				type = "header",
				name = "Position and Size",
				width = "full",
			},
			horizontalSize = {
				order = 6,
				type = "range",
				name = "Horizontal Size %",
				desc = "Size relative to the frame width (100% = full width)",
				min = 50,
				max = 200,
				step = 5,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.horizontalSize or 100 end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.horizontalSize = value
					addon:DebouncedUpdate()
				end,
			},
			verticalSize = {
				order = 7,
				type = "range",
				name = "Vertical Size %",
				desc = "Size relative to the frame height (100% = full height)",
				min = 50,
				max = 200,
				step = 5,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.verticalSize or 100 end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.verticalSize = value
					addon:DebouncedUpdate()
				end,
			},
			xOffset = {
				order = 8,
				type = "range",
				name = "X Offset",
				desc = "Horizontal offset from the anchor point",
				min = -100,
				max = 100,
				step = 1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.xOffset or 0 end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.xOffset = value
					addon:DebouncedUpdate()
				end,
			},
			yOffset = {
				order = 9,
				type = "range",
				name = "Y Offset",
				desc = "Vertical offset from the anchor point",
				min = -100,
				max = 100,
				step = 1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.yOffset or 0 end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.yOffset = value
					addon:DebouncedUpdate()
				end,
			},
			anchorPoint = {
				order = 10,
				type = "select",
				name = "Anchor Point",
				desc = "Choose where to anchor the art on the frame",
				width = 4,
				values = {
					["CENTER"] = "Center",
					["TOP"] = "Top",
					["BOTTOM"] = "Bottom",
					["LEFT"] = "Left",
					["RIGHT"] = "Right",
					["TOPLEFT"] = "Top Left",
					["TOPRIGHT"] = "Top Right",
					["BOTTOMLEFT"] = "Bottom Left",
					["BOTTOMRIGHT"] = "Bottom Right",
				},
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.point or "CENTER" end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.point = value
					addon:DebouncedUpdate()
				end,
			},
			cropHeader = {
				order = 11,
				type = "header",
				name = "Image Cropping",
				width = "full",
			},
			cropHorizontally = {
				order = 12,
				type = "toggle",
				name = "Crop Horizontally",
				desc = "Crop equal amounts from the left and right sides of the image",
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.cropHorizontally end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.cropHorizontally = value
					addon:DebouncedUpdate()
				end,
			},
			cropHorizontalAmount = {
				order = 13,
				type = "range",
				name = "Horizontal Crop %",
				desc = "Percentage to crop from each side (higher = more cropping)",
				min = 0,
				max = 40,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.artBackground.enable or
							not E.db.bagCustomizer.artBackground.cropHorizontally
				end,
				get = function()
					return E.db.bagCustomizer.artBackground.cropHorizontalAmount or
							20
				end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.cropHorizontalAmount = value
					addon:DebouncedUpdate()
				end,
			},
			cropVertically = {
				order = 14,
				type = "toggle",
				name = "Crop Vertically",
				desc = "Crop equal amounts from the top and bottom of the image",
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.cropVertically end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.cropVertically = value
					addon:DebouncedUpdate()
				end,
			},
			cropVerticalAmount = {
				order = 15,
				type = "range",
				name = "Vertical Crop %",
				desc = "Percentage to crop from top and bottom (higher = more cropping)",
				min = 0,
				max = 40,
				step = 1,
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.artBackground.enable or
							not E.db.bagCustomizer.artBackground.cropVertically
				end,
				get = function() return E.db.bagCustomizer.artBackground.cropVerticalAmount or 20 end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.cropVerticalAmount = value
					addon:DebouncedUpdate()
				end,
			},
			effectsHeader = {
				order = 16,
				type = "header",
				name = "Visual Effects",
				width = "full",
			},
			useEdgeFade = {
				order = 17,
				type = "toggle",
				name = "Use Edge Fade",
				desc = "Fade the edges of the image to blend with the background",
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.useEdgeFade end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.useEdgeFade = value
					addon:DebouncedUpdate()
				end,
			},
			maskShape = {
				order = 17.5,
				type = "select",
				name = "Fade Shape",
				desc = "Choose the shape of the edge fade effect",
				width = 2,
				values = addon.textureOptions.fadeMasks,
				disabled = function()
					return not E.db.bagCustomizer.artBackground.enable or
							not E.db.bagCustomizer.artBackground.useEdgeFade
				end,
				get = function() return E.db.bagCustomizer.artBackground.maskShape or "alpha_fade_soft_circular.tga" end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.maskShape = value
					addon:DebouncedUpdate()
				end,
			},
			useTint = {
				order = 19,
				type = "toggle",
				name = "Apply Color Tint",
				desc = "Apply a color tint to the image",
				width = 1.5,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.useTint end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.useTint = value
					addon:DebouncedUpdate()
				end,
			},
			tintColor = {
				order = 20,
				type = "color",
				name = "Tint Color",
				desc = "The color to apply as tint",
				hasAlpha = false,
				width = 1.5,
				disabled = function()
					return not E.db.bagCustomizer.artBackground.enable or
							not E.db.bagCustomizer.artBackground.useTint
				end,
				get = function()
					local color = E.db.bagCustomizer.artBackground.tintColor or
							{ r = 1, g = 1, b = 1 }
					return color.r, color.g, color.b
				end,
				set = function(_, r, g, b)
					E.db.bagCustomizer.artBackground.tintColor = { r = r, g = g, b = b }
					addon:DebouncedUpdate()
				end,
			},
			desaturate = {
				order = 21,
				type = "toggle",
				name = "Desaturate",
				desc = "Remove color from the image",
				width = 1,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.desaturate end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.desaturate = value
					addon:DebouncedUpdate()
				end,
			},
			maintainArtAspectRatio = {
				order = 22,
				type = "toggle",
				name = "Maintain Art Aspect Ratio",
				desc = "Keep the original proportions of the artwork when sizing. May not work properly for custom textures.",
				width = 2,
				disabled = function() return not E.db.bagCustomizer.artBackground.enable end,
				get = function() return E.db.bagCustomizer.artBackground.maintainArtAspectRatio end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.maintainArtAspectRatio = value
					addon:DebouncedUpdate()
				end,
			},
			maintainMaskAspectRatio = {
				order = 23,
				type = "toggle",
				name = "Maintain Mask Aspect Ratio",
				desc = "Keep the original proportions of the mask when sizing. May not work properly for custom masks.",
				width = 2,
				disabled = function()
					return not E.db.bagCustomizer.artBackground.enable or
							not E.db.bagCustomizer.artBackground.useEdgeFade
				end,
				get = function() return E.db.bagCustomizer.artBackground.maintainMaskAspectRatio end,
				set = function(_, value)
					E.db.bagCustomizer.artBackground.maintainMaskAspectRatio = value
					addon:DebouncedUpdate()
				end,
			},
		},
	}
	return artBackgroundGroupOptions
end

-- MiscBorders.lua
local function CreateBordersTabOptions()
	local bordersTabOptions = {
		order = 5,
		type = "group",
		name = "Borders",
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable Module",
				desc = "Apply custom borders to selected elements",
				width = 2,
				get = function()
					-- Directly check if the setting exists and is true
					if type(E.db.bagCustomizer) ~= "table" then
						E.db.bagCustomizer = {}
					end

					if type(E.db.bagCustomizer.borders) ~= "table" then
						E.db.bagCustomizer.borders = {}
					end

					return E.db.bagCustomizer.borders.enable == true
				end,
				set = function(_, value)
					-- Make sure the path exists
					if type(E.db.bagCustomizer) ~= "table" then
						E.db.bagCustomizer = {}
					end

					if type(E.db.bagCustomizer.borders) ~= "table" then
						E.db.bagCustomizer.borders = {}
					end

					E.db.bagCustomizer.borders.enable = value
					addon:DebouncedUpdate()
					addon:ApplyMinimapBorder()
				end,
			},
			hideDefaultBorders = {
				order = 1.5,
				type = "toggle",
				name = "Hide Default ElvUI Bag Window Border",
				desc =
				"Hide the default 1px border around the ElvUI Bag window. Recommended if you want to use a custom border on the bag window.",
				width = 2,
				disabled = function() return not E.db.bagCustomizer.borders.enable end,
				get = function() return E.db.bagCustomizer.hideDefaultBorders end,
				set = function(_, value)
					E.db.bagCustomizer.hideDefaultBorders = value
					addon:DebouncedUpdate()
				end,
			},
			bordersGroup = {
				order = 2,
				type = "group",
				name = "Add borders to:",
				guiInline = true,
				childGroups = "flow",
				args = {
					mainFrame = {
						order = 1,
						type = "toggle",
						name = "Inventory Window",
						width = 1,
						disabled = function() return not E.db.bagCustomizer.borders.enable end,
						get = function() return E.db.bagCustomizer.borders.elements.mainFrame end,
						set = function(_, value)
							E.db.bagCustomizer.borders.elements.mainFrame = value
							addon:DebouncedUpdate()
						end,
					},
					searchBar = {
						order = 2,
						type = "toggle",
						name = "Search Bar",
						width = 1,
						disabled = function() return not E.db.bagCustomizer.borders.enable end,
						get = function() return E.db.bagCustomizer.borders.elements.searchBar end,
						set = function(_, value)
							E.db.bagCustomizer.borders.elements.searchBar = value
							addon:DebouncedUpdate()
						end,
					},
					vendorGrays = {
						order = 3,
						type = "toggle",
						name = "Vendor Grays Button",
						width = 1,
						disabled = function() return not E.db.bagCustomizer.borders.enable end,
						get = function() return E.db.bagCustomizer.borders.elements.vendorGrays end,
						set = function(_, value)
							E.db.bagCustomizer.borders.elements.vendorGrays = value
							addon:DebouncedUpdate()
						end,
					},
					toggleBars = {
						order = 4,
						type = "toggle",
						name = "Toggle Bags Button",
						width = 1,
						disabled = function() return not E.db.bagCustomizer.borders.enable end,
						get = function() return E.db.bagCustomizer.borders.elements.toggleBars end,
						set = function(_, value)
							E.db.bagCustomizer.borders.elements.toggleBars = value
							addon:DebouncedUpdate()
						end,
					},
					cleanup = {
						order = 5,
						type = "toggle",
						name = "Cleanup Button",
						width = 1,
						disabled = function() return not E.db.bagCustomizer.borders.enable end,
						get = function() return E.db.bagCustomizer.borders.elements.cleanup end,
						set = function(_, value)
							E.db.bagCustomizer.borders.elements.cleanup = value
							addon:DebouncedUpdate()
						end,
					},
					stack = {
						order = 6,
						type = "toggle",
						name = "Stack Button",
						width = 1,
						disabled = function() return not E.db.bagCustomizer.borders.enable end,
						get = function() return E.db.bagCustomizer.borders.elements.stack end,
						set = function(_, value)
							E.db.bagCustomizer.borders.elements.stack = value
							addon:DebouncedUpdate()
						end,
					},
					minimap = {
						order = 7,
						type = "toggle",
						name = "Minimap",
						width = 1,
						disabled = function() return not E.db.bagCustomizer.borders.enable end,
						get = function() return E.db.bagCustomizer.borders.elements.minimap end,
						set = function(_, value)
							E.db.bagCustomizer.borders.elements.minimap = value
							addon:ApplyMinimapBorder()
						end,
					},
					bordersForItems = {
						order = 8,
						type = "description",
						name =
						"|cFFFF0000Note:|r Item Slots Borders settings are controlled by the Item Slots module, go to the Item Slots tab to adjust them.",
						width = "full",
						fontSize = "medium",
					},
				},
			},
			mainFrameSettings = {
				order = 14,
				type = "group",
				name = "Inventory Window Border Settings",
				inline = true,
				disabled = function()
					return not E.db.bagCustomizer.borders.enable or
							not E.db.bagCustomizer.borders.elements.mainFrame
				end,
				args = {
					style = {
						order = 0,
						type = "select",
						name = "Border Style",
						desc = "Choose the border style for the Inventory Window",
						width = 2,
						values = addon.borderStyles,
						get = function()
							-- Initialize style if not present
							if not E.db.bagCustomizer.borders.mainFrame.style then
								E.db.bagCustomizer.borders.mainFrame.style = E.db.bagCustomizer
										.borders.style or "tooltip"
							end

							return E.db.bagCustomizer.borders.mainFrame.style
						end,
						set = function(_, value)
							E.db.bagCustomizer.borders.mainFrame.style = value
							addon.elements.miscBorders:ClearCache()
							addon:DebouncedUpdate()
						end,
					},
					spacer1 = {
						order = 1,
						type = "description",
						name = "",
						width = 0.70,
					},
					color = {
						order = 2,
						type = "color",
						name = "Border Color",
						desc = "Set the color of the Inventory Window border",
						hasAlpha = true,
						width = 1,
						get = function()
							-- Initialize color if not present
							if not E.db.bagCustomizer.borders.mainFrame.color then
								E.db.bagCustomizer.borders.mainFrame.color = CopyTable(E.db
									.bagCustomizer.borders.color or { r = 1, g = 1, b = 1 })
								E.db.bagCustomizer.borders.mainFrame.alpha = E.db.bagCustomizer
										.borders.alpha or 1
							end

							return E.db.bagCustomizer.borders.mainFrame.color.r,
									E.db.bagCustomizer.borders.mainFrame.color.g,
									E.db.bagCustomizer.borders.mainFrame.color.b,
									E.db.bagCustomizer.borders.mainFrame.alpha
						end,
						set = function(_, r, g, b, a)
							if not E.db.bagCustomizer.borders.mainFrame.color then
								E.db.bagCustomizer.borders.mainFrame.color = {}
							end

							E.db.bagCustomizer.borders.mainFrame.color.r = r
							E.db.bagCustomizer.borders.mainFrame.color.g = g
							E.db.bagCustomizer.borders.mainFrame.color.b = b
							E.db.bagCustomizer.borders.mainFrame.alpha = a
							addon:DebouncedUpdate()
						end,
					},
					size = {
						order = 3,
						type = "range",
						name = "Border Size",
						min = 0,
						max = 24,
						step = 1,
						width = 2,
						get = function() return E.db.bagCustomizer.borders.mainFrame.size end,
						set = function(_, value)
							E.db.bagCustomizer.borders.mainFrame.size = value
							addon:DebouncedUpdate()
						end,
					},
					inset = {
						order = 5,
						type = "range",
						name = "Border Offset",
						min = -20,
						max = 20,
						step = 1,
						width = 2,
						get = function() return E.db.bagCustomizer.borders.mainFrame.inset end,
						set = function(_, value)
							E.db.bagCustomizer.borders.mainFrame.inset = value
							addon:DebouncedUpdate()
						end,
					},
				},
			},
			searchBarSettings = {
				order = 15,
				type = "group",
				name = "Search Bar Border Settings",
				inline = true,
				disabled = function()
					return not E.db.bagCustomizer.borders.enable or
							not E.db.bagCustomizer.borders.elements.searchBar
				end,
				args = {
					style = {
						order = 0,
						type = "select",
						name = "Border Style",
						desc = "Choose the border style for the Search Bar",
						width = 2,
						values = addon.borderStyles,
						get = function()
							-- Initialize style if not present
							if not E.db.bagCustomizer.borders.searchBar.style then
								E.db.bagCustomizer.borders.searchBar.style = E.db.bagCustomizer
										.borders.style or "tooltip"
							end

							return E.db.bagCustomizer.borders.searchBar.style
						end,
						set = function(_, value)
							E.db.bagCustomizer.borders.searchBar.style = value
							addon.elements.miscBorders:ClearCache()
							addon:DebouncedUpdate()
						end,
					},
					spacer1 = {
						order = 1,
						type = "description",
						name = "",
						width = 0.70,
					},
					color = {
						order = 2,
						type = "color",
						name = "Border Color",
						desc = "Set the color of the Search Bar border",
						hasAlpha = true,
						width = 1,
						get = function()
							-- Initialize color if not present
							if not E.db.bagCustomizer.borders.searchBar.color then
								E.db.bagCustomizer.borders.searchBar.color = CopyTable(E.db
									.bagCustomizer.borders.color or { r = 1, g = 1, b = 1 })
								E.db.bagCustomizer.borders.searchBar.alpha = E.db.bagCustomizer
										.borders.alpha or 1
							end

							return E.db.bagCustomizer.borders.searchBar.color.r,
									E.db.bagCustomizer.borders.searchBar.color.g,
									E.db.bagCustomizer.borders.searchBar.color.b,
									E.db.bagCustomizer.borders.searchBar.alpha
						end,
						set = function(_, r, g, b, a)
							if not E.db.bagCustomizer.borders.searchBar.color then
								E.db.bagCustomizer.borders.searchBar.color = {}
							end

							E.db.bagCustomizer.borders.searchBar.color.r = r
							E.db.bagCustomizer.borders.searchBar.color.g = g
							E.db.bagCustomizer.borders.searchBar.color.b = b
							E.db.bagCustomizer.borders.searchBar.alpha = a
							addon:DebouncedUpdate()
						end,
					},
					size = {
						order = 3,
						type = "range",
						name = "Border Size",
						min = 0,
						max = 24,
						step = 1,
						width = 2,
						get = function() return E.db.bagCustomizer.borders.searchBar.size end,
						set = function(_, value)
							E.db.bagCustomizer.borders.searchBar.size = value
							addon:DebouncedUpdate()
						end,
					},
					inset = {
						order = 5,
						type = "range",
						name = "Border Offset",
						min = -20,
						max = 20,
						step = 1,
						width = 2,
						get = function() return E.db.bagCustomizer.borders.searchBar.inset end,
						set = function(_, value)
							E.db.bagCustomizer.borders.searchBar.inset = value
							addon:DebouncedUpdate()
						end,
					},
				},
			},
			buttonsSettings = {
				order = 16,
				type = "group",
				name = "Inventory Buttons Border Settings",
				inline = true,
				disabled = function()
					return not E.db.bagCustomizer.borders.enable or
							(not E.db.bagCustomizer.borders.elements.vendorGrays and
								not E.db.bagCustomizer.borders.elements.toggleBars and
								not E.db.bagCustomizer.borders.elements.cleanup and
								not E.db.bagCustomizer.borders.elements.stack)
				end,
				args = {
					style = {
						order = 0,
						type = "select",
						name = "Border Style",
						desc = "Choose the border style for Inventory Buttons",
						width = 2,
						values = addon.borderStyles,
						get = function()
							-- Initialize style if not present
							if not E.db.bagCustomizer.borders.buttons.style then
								E.db.bagCustomizer.borders.buttons.style = E.db.bagCustomizer
										.borders.style or "tooltip"
							end

							return E.db.bagCustomizer.borders.buttons.style
						end,
						set = function(_, value)
							E.db.bagCustomizer.borders.buttons.style = value
							addon.elements.miscBorders:ClearCache()
							addon:DebouncedUpdate()
						end,
					},
					spacer1 = {
						order = 1,
						type = "description",
						name = "",
						width = 0.70,
					},
					color = {
						order = 2,
						type = "color",
						name = "Border Color",
						desc = "Set the color of the Inventory Buttons borders",
						hasAlpha = true,
						width = 1,
						get = function()
							-- Initialize color if not present
							if not E.db.bagCustomizer.borders.buttons.color then
								E.db.bagCustomizer.borders.buttons.color = CopyTable(E.db
									.bagCustomizer.borders.color or { r = 1, g = 1, b = 1 })
								E.db.bagCustomizer.borders.buttons.alpha = E.db.bagCustomizer
										.borders.alpha or 1
							end

							return E.db.bagCustomizer.borders.buttons.color.r,
									E.db.bagCustomizer.borders.buttons.color.g,
									E.db.bagCustomizer.borders.buttons.color.b,
									E.db.bagCustomizer.borders.buttons.alpha
						end,
						set = function(_, r, g, b, a)
							if not E.db.bagCustomizer.borders.buttons.color then
								E.db.bagCustomizer.borders.buttons.color = {}
							end

							E.db.bagCustomizer.borders.buttons.color.r = r
							E.db.bagCustomizer.borders.buttons.color.g = g
							E.db.bagCustomizer.borders.buttons.color.b = b
							E.db.bagCustomizer.borders.buttons.alpha = a
							addon:DebouncedUpdate()
						end,
					},
					size = {
						order = 3,
						type = "range",
						name = "Border Size",
						min = 0,
						max = 24,
						step = 1,
						width = 2,
						get = function() return E.db.bagCustomizer.borders.buttons.size end,
						set = function(_, value)
							E.db.bagCustomizer.borders.buttons.size = value
							addon:DebouncedUpdate()
						end,
					},
					inset = {
						order = 5,
						type = "range",
						name = "Border Offset",
						min = -20,
						max = 20,
						step = 1,
						width = 2,
						get = function() return E.db.bagCustomizer.borders.buttons.inset end,
						set = function(_, value)
							E.db.bagCustomizer.borders.buttons.inset = value
							addon:DebouncedUpdate()
						end,
					},
					borderdescription = {
						order = 6,
						type = "description",
						fontSize = "medium",
						name =
						"|cff3498dbThese settings affect the 4 buttons to the left of the search bar. For inventory slots borders settings, go to the Inventory Slots tab on the left.|r",
						width = "full",
					},
				},
			},
			minimapSettings = {
				order = 17,
				type = "group",
				name = "Minimap Border Settings",
				inline = true,
				disabled = function()
					return not E.db.bagCustomizer.borders.enable or
							not E.db.bagCustomizer.borders.elements.minimap
				end,
				args = {
					style = {
						order = 0,
						type = "select",
						name = "Border Style",
						desc = "Choose the border style for the Minimap",
						width = 2,
						values = addon.borderStyles,
						get = function()
							-- Initialize style if not present
							if not E.db.bagCustomizer.borders.minimap.style then
								E.db.bagCustomizer.borders.minimap.style = E.db.bagCustomizer
										.borders.style or "tooltip"
							end

							return E.db.bagCustomizer.borders.minimap.style
						end,
						set = function(_, value)
							E.db.bagCustomizer.borders.minimap.style = value
							addon.elements.miscBorders:ClearCache()
							addon:ApplyMinimapBorder()
						end,
					},
					spacer1 = {
						order = 1,
						type = "description",
						name = "",
						width = 0.70,
					},
					color = {
						order = 2,
						type = "color",
						name = "Border Color",
						desc = "Set the color of the Minimap border",
						hasAlpha = true,
						width = 1,
						get = function()
							-- Initialize color if not present
							if not E.db.bagCustomizer.borders.minimap.color then
								E.db.bagCustomizer.borders.minimap.color = CopyTable(E.db
									.bagCustomizer.borders.color or { r = 1, g = 1, b = 1 })
								E.db.bagCustomizer.borders.minimap.alpha = E.db.bagCustomizer
										.borders.alpha or 1
							end

							return E.db.bagCustomizer.borders.minimap.color.r,
									E.db.bagCustomizer.borders.minimap.color.g,
									E.db.bagCustomizer.borders.minimap.color.b,
									E.db.bagCustomizer.borders.minimap.alpha
						end,
						set = function(_, r, g, b, a)
							if not E.db.bagCustomizer.borders.minimap.color then
								E.db.bagCustomizer.borders.minimap.color = {}
							end

							E.db.bagCustomizer.borders.minimap.color.r = r
							E.db.bagCustomizer.borders.minimap.color.g = g
							E.db.bagCustomizer.borders.minimap.color.b = b
							E.db.bagCustomizer.borders.minimap.alpha = a
							addon:ApplyMinimapBorder()
						end,
					},
					size = {
						order = 3,
						type = "range",
						name = "Border Size",
						min = 0,
						max = 24,
						step = 1,
						width = 2,
						get = function() return E.db.bagCustomizer.borders.minimap.size end,
						set = function(_, value)
							E.db.bagCustomizer.borders.minimap.size = value
							addon:ApplyMinimapBorder()
						end,
					},
					inset = {
						order = 5,
						type = "range",
						name = "Border Offset",
						min = -20,
						max = 20,
						step = 1,
						width = 2,
						get = function() return E.db.bagCustomizer.borders.minimap.inset end,
						set = function(_, value)
							E.db.bagCustomizer.borders.minimap.inset = value
							addon:ApplyMinimapBorder()
						end,
					},
				},
			},
		},
	}
	return bordersTabOptions
end

-- SearchBar.lua
local function CreateSearchBarBackdropGroupOptions()
	local searchBarBackdropGroupOptions = {
		order = 3,
		type = "group",
		name = "Search Bar Settings",
		guiInline = true,
		args = {
			enable = {
				order = 1,
				type = "toggle",
				name = "Enable Module",
				desc = "Add a custom backdrop to the search bar",
				width = 2,
				get = function() return E.db.bagCustomizer.searchBarBackdrop.enable end,
				set = function(_, value)
					E.db.bagCustomizer.searchBarBackdrop.enable = value
					-- Use ApplyChanges which now includes the timer logic
					addon:ApplyChanges()
				end,
			},
			hideBorder = {
				order = 1,
				type = "toggle",
				name = "Hide Default Border",
				desc = "Hide the default border of the search bar",
				width = 2,
				disabled = function() return not E.db.bagCustomizer.searchBarBackdrop.enable end,
				get = function() return E.db.bagCustomizer.searchBarBackdrop.hideBorder end,
				set = function(_, value)
					E.db.bagCustomizer.searchBarBackdrop.hideBorder = value
					-- Use ApplyChanges which now includes the timer logic
					addon:ApplyChanges()
				end,
			},
			color = {
				order = 2,
				type = "color",
				name = "Backdrop Color",
				desc = "Set the color of the search bar backdrop",
				hasAlpha = false,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.searchBarBackdrop.enable end,
				get = function()
					local c = E.db.bagCustomizer.searchBarBackdrop.color
					return c.r, c.g, c.b
				end,
				set = function(_, r, g, b)
					local c = E.db.bagCustomizer.searchBarBackdrop.color
					c.r, c.g, c.b = r, g, b
					-- Use ApplyChanges which now includes the timer logic
					addon:ApplyChanges()
				end,
			},
			alpha = {
				order = 3,
				type = "range",
				name = "Backdrop Opacity",
				min = 0,
				max = 1,
				step = 0.01,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.searchBarBackdrop.enable end,
				get = function() return E.db.bagCustomizer.searchBarBackdrop.alpha end,
				set = function(_, value)
					E.db.bagCustomizer.searchBarBackdrop.alpha = value
					-- Use ApplyChanges which now includes the timer logic
					addon:ApplyChanges()
				end,
			},
			yOffsetSearchBar = {
				order = 7,
				type = "range",
				name = "Search Bar Vertical Offset",
				desc =
				"Adjust the vertical position of the search bar. Recommended to keep at the same value as the Buttons vertical offset, but you may need to adjust it a bit to match border edges.",
				min = -50,
				max = 100,
				step = 0.1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.searchBarBackdrop.enable end,
				get = function()
					-- Check if the setting exists, create it if not
					if E.db.bagCustomizer.searchBarBackdrop.yOffset == nil then
						E.db.bagCustomizer.searchBarBackdrop.yOffset = 0
					end

					return E.db.bagCustomizer.searchBarBackdrop.yOffset
				end,
				set = function(_, value)
					E.db.bagCustomizer.searchBarBackdrop.yOffset = value
					-- Use ApplyChanges which now includes the timer logic
					addon:ApplyChanges()
				end,
			},
			stackButtonYOffset = {
				order = 8,
				type = "range",
				name = "Buttons Vertical Offset",
				desc =
				"Adjust the vertical position of the buttons to the right of the Search bar.",
				min = -50,
				max = 100,
				step = 0.1,
				width = 2,
				disabled = function() return not E.db.bagCustomizer.searchBarBackdrop.enable end,
				get = function()
					if E.db.bagCustomizer.searchBarBackdrop.stackButtonYOffset == nil then
						E.db.bagCustomizer.searchBarBackdrop.stackButtonYOffset = 0
					end

					return E.db.bagCustomizer.searchBarBackdrop.stackButtonYOffset
				end,
				set = function(_, value)
					-- Store the new value
					E.db.bagCustomizer.searchBarBackdrop.stackButtonYOffset = value
					-- Use ApplyChanges which now includes the timer logic
					addon:ApplyChanges()
				end,
			},
		},
	}
	return searchBarBackdropGroupOptions
end

-------------------------------------------
-- Modular options section end
-------------------------------------------
-- Insert options into ElvUI config
function addon.InsertOptions()
	E.Options.args.bagCustomizer = {
		order = 99,
		type = "group",
		name = "Bag Customizer",
		childGroups = "tab",
		args = {
			enabled = {
				order = 0,
				type = "toggle",
				name = "Enable customizer",
				desc = "Enable bag customization features",
				width = 3,
				get = function() return E.db.bagCustomizer.enabled end,
				set = function(_, value)
					E.db.bagCustomizer.enabled = value
					addon:TriggerEvent("GLOBAL_TOGGLE_CHANGED", value)
					addon:DebouncedUpdate()
					addon:ApplyMinimapBorder()
				end,
			},
			welcomeTab = {
				order = 1,
				type = "group",
				name = "Welcome Page",
				args = {
					welcome = CreateWelcomeOptions(),
				},
			},
			themesTab = {
				order = 2,
				type = "group",
				name = "Themes and Profiles",
				args = {
					themes = CreateThemeOptions(),
				},
			},
			advancedTab = {
				order = 3,
				type = "group",
				name = "Advanced",
				childGroups = "tab",
				args = {
					advancedWelcomeTab = {
						order = 1,
						type = "group",
						name = "Tips & Navigation",
						args = {
							advancedWelcomeTab = CreateAdvancedWelcomeTabOptions(),
						},
					},
					inventoryWindowBody = {
						order = 1,
						type = "group",
						name = "Window Body",
						args = {
							topTextureGroupOptions = CreateTopTextureGroupOptions(),
							backgroundGroup = CreateBackgroundGroupOptions(),
							uiBackgroundGroup = CreateUiBackgroundGroupOptions(),
							artBackgroundGroup = CreateArtBackgroundGroupOptions(),
						},
					},
					layoutTab = {
						order = 2,
						type = "group",
						name = "Layout",
						args = {
							closeButtonTexture = CreateCloseButtonTextureOptions(),
							frameHeightTab = CreateFrameHeightTabOptions(),
							searchBarBackdropGroup = CreateSearchBarBackdropGroupOptions(),
						},
					},
					inventorySlotsTab = {
						order = 3,
						type = "group",
						name = "Item Slots",
						args = {
							enableInventorySlots = {
								order = 1,
								type = "toggle",
								name = "Enable Module",
								desc = "Apply borders and/or Textures to inventory slots",
								width = "full",
								get = function()
									if not E.db.bagCustomizer.inventorySlots then
										return false
									end

									return E.db.bagCustomizer.inventorySlots.enable or false
								end,
								set = function(_, value)
									if not E.db.bagCustomizer.inventorySlots then
										E.db.bagCustomizer.inventorySlots = {}
									end

									E.db.bagCustomizer.inventorySlots.enable = value
									addon:DebouncedUpdate()
								end,
							},
							inventorySlotsMain = CreateInventorySlotsMainOptions(),
							inventorySlotsBrightness = CreateInventorySlotsBrightnessOptions(),
							inventorySlotsIntensity = CreateInventorySlotsIntensityOptions(),
							textAdjust = CreateTextAdjustOptions(),
							inventorySlotsMisc = CreateInventorySlotsMiscOptions(),
						},
					},
					currenciesTab = {
						order = 4,
						type = "group",
						name = "Gold & Currencies",
						args = {
							currencyModuleEnabled = {
								order = 1,
								type = "toggle",
								name = "Enable Currency Module",
								desc = "Enables or disables the Currency module functionality.",
								width = "full",
								get = function() return E.db.bagCustomizer.currencyModuleEnabled end,
								set = function(_, value)
									E.db.bagCustomizer.currencyModuleEnabled = value
									-- Get addon module reference
									local addon = E:GetModule("BagCustomizer")
									-- Trigger specific event for this setting
									if addon.TriggerEvent then
										addon:TriggerEvent("CURRENCY_MODULE_ENABLED", value)
									end

									-- Use addon's unified update system
									if addon.Update then
										addon:Update("CurrencyModuleEnabledChanged", true)
									else
										-- Fallback to original method
										ThrottleUpdate()
										-- Force ElvUI to update
										local B = E:GetModule("Bags")
										if B and B.Layout then
											C_Timer.After(0.1, function()
												B:Layout()
											end)
										end

										-- Refresh the options UI to update dependent options
										if E.Libs and E.Libs.AceConfigRegistry then
											E.Libs.AceConfigRegistry:NotifyChange("ElvUI")
										end
									end
								end,
							},
							generalCurrencySettings = CreatGeneralCurrencySettingsOptions(),
							goldTextTexture = CreateGoldTextTextureOptions(),
							currencyTexture = CreateCurrencyTextureOptions(),
						},
					},
					bordersTab = CreateBordersTabOptions(),
				},
			},
			DebugTab = {
				order = 99,
				type = "group",
				name = "Debug",
				args = {
					debug = CreateDebugOptions(),
				},
			},
		},
	}
end
