-- ****************** HEY, LISTEN!!!! ******************
--If you're here because you want to change the mod to silent mode, you are in the wrong place.
--You should use the Mod Options menu to change this mod's settings. 
--If you do not have a Mod Options menu, you must upgrade from BLT to SuperBLT: https://superblt.znix.xyz/

_G.EverythingMeth = EverythingMeth or {}
EverythingMeth.settings = {
	enabled = true,
	ingred_chatmode = 2,
	ingred_hintmode = true,
	ingred_repeat = false,
	added_chatmode = 1,
	added_hintmode = false,
	done_chatmode = 1,
	done_hintmode = false,
	fail_chatmode = 3,
	fail_hintmode = true,
	remove_blur = false,
	meth_manager_enabled = false,
	ingred_lines = true,
	ingred_contours = false,
	anti_spam = false,
	msg_prefix_mode = 3,
	msg_prefix = "",
	host_only_pmsg = true,
	language_name = "en.txt",
	_language_index = 2 --don't bother changing this, it doesn't do anything except VISUALLY change which language is selected in the multiple choice menu
}

EverythingMeth.populated_languages_menu = false
EverythingMeth.languages = {} --populated later

EverythingMeth.path = ModPath
EverythingMeth.loc_path = EverythingMeth.path .. "loc/"
EverythingMeth.save_path = SavePath .. "everythingmeth.json"
EverythingMeth.contours_save_path = SavePath .. "everythingmeth_contours.txt"

EverythingMeth._last_ingredient = "Fish-shaped volatile organic compounds and sediment-shaped sediment" --placeholder

function EverythingMeth:Load()
	local file = io.open(self.save_path, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
	else
		self:Save()
	end

	local contours_file = io.open(self.contours_save_path, "r")
	if (contours_file) then
		self.settings.ingred_contours = contours_file:read("*all") == "true"
	else
		self:Save()
	end
end

function EverythingMeth:Save()
	local file = io.open(self.save_path,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end

	local contours_file = io.open(self.contours_save_path, "w+")
	if contours_file then
		contours_file:write(tostring(self.settings.ingred_contours))
		contours_file:close()
	end
end

function EverythingMeth:IsEnabled()
	return self.settings.enabled
end

function EverythingMeth:GetLanguage()
	return self.settings.language_name
end

function EverythingMeth:DebugEnabled() 
	return false
end

function EverythingMeth:ShouldRepeatIngredients()
	return self.settings.ingred_repeat
end

function EverythingMeth:GetOutputType(dialog_id)
	local s = self.settings
	local chatmode = s[dialog_id .. "_chatmode"] or 3
	local hintmode = s[dialog_id .. "_hintmode"] or false

	return chatmode,hintmode
end

function EverythingMeth:Toggle_Enabled(enabled)
	if enabled == nil then 
		self.settings.enabled = not self.settings.enabled
	else
		self.settings.enabled = enabled
	end
	return self.settings.enabled
end

function EverythingMeth:ShouldRemoveBlur()
	return self.settings.remove_blur
	
end

function EverythingMeth:LocalizeLine(id)
	return managers.localization:text("everythingmeth_" .. tostring(id))
end

function EverythingMeth:LoadLanguageFiles()
	for i,filename in ipairs(SystemFS:list(self.loc_path)) do 
		local file = io.open(self.loc_path .. filename, "r")
		if file then
			local localized_strings = json.decode(file:read("*all"))
			local lang_name = localized_strings and (type(localized_strings) == "table") and localized_strings.everythingmeth_language_name
			if lang_name then 
				self.languages[filename] = {
					index = i,
					localized_language_name = lang_name,
					localization = localized_strings
				}
			end
		
		end
		if filename == self:GetLanguage() then 
			self.settings._language_index = i
			-- language order is not guaranteed- particularly if a new language is added which interferes with the alphabetical order-
			-- which is why the filename is saved and not the index number of the language,
			-- and the index number is "generated" on load instead of being written here in settings
		end
	end
end

function EverythingMeth:LoadLanguage(localizationmanager,user_language)
	localizationmanager = localizationmanager or managers.localization
	if localizationmanager then 
		user_language = user_language or self:GetLanguage()
		local language_data = user_language and self.languages[user_language]
		local ization = language_data and language_data.localization  --get it? local-ization? hahahahaha please clap --good one man
		if ization then 
			if self:DebugEnabled() then 
				log("EverythingMeth: Loading localization for " .. user_language)
			end
			self.settings._language_index = language_data.index
			localizationmanager:add_localized_strings(ization)
		end
	elseif self:DebugEnabled() then 
		log("EverythingMeth: ERROR! Failed to find LocalizationManager!")
	end
end

EverythingMeth:Load()
EverythingMeth:LoadLanguageFiles()

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_EverythingMeth",
	callback(EverythingMeth,EverythingMeth,"LoadLanguage")
)

Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_EverythingMeth", function(menu_manager)
	
	MenuCallbackHandler.callback_everythingmeth_toggle_enabled = function(self,item)
		local value = item:value() == "on"
		EverythingMeth:Toggle_Enabled(value)
		EverythingMeth:Save()
	end
	
	MenuCallbackHandler.callback_everythingmeth_refocus = function(self)
		if EverythingMeth.populated_languages_menu then
			return
		end
		
		local menu_item = MenuHelper:GetMenu("everythingmeth_options") or {_items = {}}
		for _,item in pairs(menu_item._items) do 
			if item._parameters and item._parameters.name == "everythingmeth_select_language" then 
				for lang_name,lang_data in pairs(EverythingMeth.languages) do 
					item:add_option(
						CoreMenuItemOption.ItemOption:new(
							{
								_meta = "option",
								text_id = lang_data.localized_language_name,
								value = lang_data.index,
								localize = false
							}
						)
					)
				end
				item:set_value(EverythingMeth.settings._language_index)
				break
			end
		end	
		EverythingMeth.populated_languages_menu = true
	end
	
	MenuCallbackHandler.callback_everythingmeth_select_language = function(self,item) --populate multiplechoice with profile options
		for lang_name,lang_data in pairs(EverythingMeth.languages) do 
			if lang_data.index == tonumber(item:value()) then 
				EverythingMeth.settings.language_name = lang_name
				EverythingMeth:Save()
				EverythingMeth:LoadLanguage(nil,lang_name)
				return
			end
		end
	end	
	
	MenuCallbackHandler.callback_everythingmeth_keybind_toggle = function(self)
		local value = EverythingMeth:Toggle_Enabled()
		if managers.hud then 
			managers.hud:show_hint({text = EverythingMeth:LocalizeLine("toggled_" .. tostring(value))})
		end
		--don't save from keybind
	end
	
	MenuCallbackHandler.callback_everythingmeth_ingred_chatmode = function(self,item)
		local value = tonumber(item:value())
		EverythingMeth.settings.ingred_chatmode = value
		EverythingMeth:Save()
	end
	MenuCallbackHandler.callback_everythingmeth_ingred_hintmode = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.ingred_hintmode = value
		EverythingMeth:Save()
	end
	MenuCallbackHandler.callback_everythingmeth_ingred_repeat = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.ingred_repeat = value
		EverythingMeth:Save()
	end
	
	MenuCallbackHandler.callback_everythingmeth_added_chatmode = function(self,item)
		local value = tonumber(item:value())
		EverythingMeth.settings.added_chatmode = value
		EverythingMeth:Save()
	end
	MenuCallbackHandler.callback_everythingmeth_added_hintmode = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.added_hintmode = value
		EverythingMeth:Save()
	end
	
	MenuCallbackHandler.callback_everythingmeth_done_chatmode = function(self,item)
		local value = tonumber(item:value())
		EverythingMeth.settings.done_chatmode = value
		EverythingMeth:Save()
	end
	MenuCallbackHandler.callback_everythingmeth_done_hintmode = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.done_hintmode = value
		EverythingMeth:Save()
	end
	
	MenuCallbackHandler.callback_everythingmeth_fail_chatmode = function(self,item)
		local value = tonumber(item:value())
		EverythingMeth.settings.fail_chatmode = value
		EverythingMeth:Save()
	end
	MenuCallbackHandler.callback_everythingmeth_fail_hintmode = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.fail_hintmode = value
		EverythingMeth:Save()
	end
	
	MenuCallbackHandler.callback_everythingmeth_remove_blur_toggle = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.remove_blur = value
		EverythingMeth:Save()
	end

	MenuCallbackHandler.callback_everythingmeth_meth_manager_toggle_enabled = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.meth_manager_enabled = value
		EverythingMeth:Save()
	end
	
	MenuCallbackHandler.callback_everythingmeth_ingred_lines_toggle = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.ingred_lines = value
		EverythingMeth:Save()
	end

	MenuCallbackHandler.callback_everythingmeth_ingred_contours_toggle = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.ingred_contours = value
		EverythingMeth:Save()
	end

	MenuCallbackHandler.callback_everythingmeth_anti_spam_toggle = function(self,item)
		local value = item:value() == "on"
		EverythingMeth.settings.anti_spam = value
		EverythingMeth:Save()
	end
	
	MenuCallbackHandler.callback_everythingmeth_msg_prefix_mode = function(self,item)
		local value = tonumber(item:value())
		local prefix_table = {"[Everything Meth]: ", "[Meth Helper]: ", ""}
		EverythingMeth.settings.msg_prefix_mode = value
		EverythingMeth.settings.msg_prefix = prefix_table[value]
		EverythingMeth:Save()
	end

	MenuCallbackHandler.callback_everythingmeth_host_only_public_msg = function(self,item)
		local value = item:value() == "on"
		if not value then
			QuickMenu:new(
				EverythingMeth:LocalizeLine("host_only_public_msg_title"),
				EverythingMeth:LocalizeLine("host_only_public_msg_warning"),
				{
					{
						text = EverythingMeth:LocalizeLine("disable"),
						callback = function ()
							EverythingMeth.settings.host_only_pmsg = value
						end
					},
					{
						text = EverythingMeth:LocalizeLine("cancel"),
						callback = function ()
							MenuHelper:ResetItemsToDefaultValue(
								item,
								{ ["everythingmeth_host_only_public_msg"] = true },
								true)
						end
					}
				},
				true
			)
		else
			EverythingMeth.settings.host_only_pmsg = value
		end
	end
	MenuCallbackHandler.callback_everythingmeth_close = function(self)
--		EverythingMeth:Save() --redundant since the mod saves after any setting change
	end
	MenuHelper:LoadFromJsonFile(EverythingMeth.path .. "menu/options.txt", EverythingMeth, EverythingMeth.settings)

end)