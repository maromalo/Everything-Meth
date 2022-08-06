local dialog_ids = {
--bain's lines
	["pln_rt1_12"] = "added",
	["pln_rt1_23"] = "fail",
	["pln_rt1_20"] = "mu",
	["pln_rt1_22"] = "cs",
	["pln_rt1_24"] = "hcl",
	["pln_rt1_28"] = "added",
	["Play_pln_nai_16"] = "fail", --this and 15 both play on lab rats, not sure which i should use. 16 seems to only play on lab rats
	["pln_rat_stage1_20"] = "mu",
	["pln_rat_stage1_22"] = "cs",
	["pln_rat_stage1_24"] = "hcl",
	["pln_rat_stage1_28"] = "done",
	
--locke's lines
	["Play_loc_mex_cook_03"] = "mu",
	["Play_loc_mex_cook_04"] = "cs",
	["Play_loc_mex_cook_05"] = "hcl",
	["Play_loc_mex_cook_14"] = "done", --used when you have not stashed the requisite amount of bags
	["Play_loc_mex_cook_17"] = "done", --used when you have secured enough bags to escape
	["Play_loc_mex_cook_22"] = "added",
	["Play_loc_mex_cook_12"] = "fail"
}

EverythingMeth.disallowedIngredientsTable = {
	["mu"] = {["unit"] = "units/payday2/pickups/gen_pku_methlab_bubbling/gen_pku_methlab_bubbling", ["textid"] = "hud_int_methlab_bubbling"},
	["cs"] = {["unit"] = "units/payday2/pickups/gen_pku_methlab_caustic_cooler/gen_pku_methlab_caustic_cooler", ["textid"] = "hud_int_methlab_caustic_cooler"},
	["hcl"] = {["unit"] = "units/payday2/pickups/gen_pku_methlab_liquid_meth/gen_pku_methlab_liquid_meth", ["textid"] = "hud_int_methlab_gas_to_salt"}
}
EverythingMeth.disallowedIngredientsUnit = {}
EverythingMeth.disallowedIngredientsTextId = {}
EverythingMeth._last_state = {}

local original_queue_dialog = DialogManager.queue_dialog
--Hooks:PostHook(DialogManager,"queue_dialog","DialogManagerQueueDialog_EverythingMeth",function(self,id,params)
function DialogManager:queue_dialog(id, ...)
	if not EverythingMeth:IsEnabled() then 
		--everythingmeth is set to disabled in mod options, so do nothing
		return original_queue_dialog(self, id, ...)
	end
	local line_type = dialog_ids[tostring(id)]
	if not line_type then 
		--line is not on the list of catalogued meth cooking lines, so do nothing
		return original_queue_dialog(self, id, ...)
	end
	local chatmode,hintmode
	local output
	if (line_type == "mu") or (line_type == "cs") or (line_type == "hcl") then

		if EverythingMeth.settings.meth_manager_enabled then
			EverythingMeth.disallowedIngredientsUnit = {}
			EverythingMeth.disallowedIngredientsTextId = {}
			for k, v in pairs(EverythingMeth.disallowedIngredientsTable) do
				if k ~= line_type then
					table.insert(EverythingMeth.disallowedIngredientsUnit, v["unit"])
					table.insert(EverythingMeth.disallowedIngredientsTextId, v["textid"])
				end
			end
		end

		chatmode,hintmode = EverythingMeth:GetOutputType("ingred")
		if (line_type ~= EverythingMeth._last_ingredient) or EverythingMeth:ShouldRepeatIngredients() then 
			output = EverythingMeth:LocalizeLine(line_type)
		end
		EverythingMeth._last_ingredient = line_type
	elseif (line_type == "fail") or (line_type == "added") or (line_type == "done") then 
		chatmode,hintmode = EverythingMeth:GetOutputType(line_type)
		output = EverythingMeth:LocalizeLine(line_type)
		EverythingMeth._last_ingredient = line_type
	end
	
	if output then 
		local private_prefix = "[" .. EverythingMeth:LocalizeLine("prefix") .. "]"
		local color = Color("5FE1FF") --cyan
		if chatmode == 1 then 
			managers.chat:_receive_message(1,private_prefix,output,color)
		elseif chatmode == 2 then 
			managers.chat:send_message(ChatManager.GAME, managers.network.account:username() or "Offline", EverythingMeth.settings.msg_prefix .. output)
		elseif chatmode == 3 then 
			--nothing
		end
		if hintmode then 
			managers.hud:show_hint({text = output})
		end
	end

	if EverythingMeth.settings.ingred_lines then
		return original_queue_dialog(self, id, ...)
	end
end

--Meth Manager
function EverythingMeth:can_self_interact(peer_id, unit)
	if #EverythingMeth.disallowedIngredientsUnit == 2 and unit and alive(unit) and unit.name then
		return unit:name() ~= Idstring(EverythingMeth.disallowedIngredientsUnit[1]) and unit:name() ~= Idstring(EverythingMeth.disallowedIngredientsUnit[2])
	end
	return true
end

function EverythingMeth:can_peer_interact(peer_id, tweak_data_id)
	if #EverythingMeth.disallowedIngredientsTextId == 2 then
		return tweak_data.interaction[tweak_data_id].text_id ~= EverythingMeth.disallowedIngredientsTextId[1] and tweak_data.interaction[tweak_data_id].text_id ~= EverythingMeth.disallowedIngredientsTextId[2]
	end
	return true
end

function EverythingMeth:send_message_to_peer(peer, message) 
	if managers.network:session() then
		peer:send("send_chat_message", ChatManager.GAME, "[" .. EverythingMeth:LocalizeLine("prefix") .. "] " .. message)
	end
end

function EverythingMeth:tase_player(peer_id) 
	local player_unit = managers.criminals:character_unit_by_peer_id(peer_id)
	local player_down_time = player_unit:character_damage():down_time()
	local player_id = player_unit:id()

	managers.network:session():send_to_peers_synched("sync_player_movement_state", player_unit, "tased", player_down_time, player_id)

	self._last_state[peer_id] = player_unit:movement():current_state_name()
	player_unit:movement():sync_movement_state("tased", player_down_time)
end

function EverythingMeth:untase_player(peer_id) 
	local player_unit = managers.criminals:character_unit_by_peer_id(peer_id)
	local player_down_time = player_unit:character_damage():down_time()
	local player_id = player_unit:id()

	if self._last_state[peer_id] ~= "" then
		managers.network:session():send_to_peers_synched("sync_player_movement_state", player_unit, self._last_state[peer_id], player_down_time, player_id)
		player_unit:movement():sync_movement_state(self._last_state[peer_id], player_down_time)
		self._last_state[peer_id] = ""
	end
end


local SE_interact_original = ObjectInteractionManager.interact
function ObjectInteractionManager:interact(player)
	if EverythingMeth.settings.meth_manager_enabled then
		if not EverythingMeth:can_self_interact(_G.LuaNetworking:LocalPeerID(), self._active_unit) then
			managers.hud:show_hint({text = EverythingMeth:LocalizeLine("fail"), time = 3})
			return false
		end
	end
	return SE_interact_original(self, player)
end

Hooks:PostHook(UnitNetworkHandler, "sync_teammate_progress", "EverythingMeth_UnitNetworkHandler", function(self, type_index, enabled, tweak_data_id, timer, success, sender)
	if not EverythingMeth.settings.meth_manager_enabled or not _G.LuaNetworking:IsHost() or type_index ~= 1 or success == true then
		return
	end
	local peer = self._verify_sender(sender)
	local peer_id = peer and peer:id()

	if peer_id then
		if not EverythingMeth:can_peer_interact(peer_id, tweak_data_id) then
			if enabled == true then
				managers.hud:show_hint({text = tostring(peer:name()) .. EverythingMeth:LocalizeLine("teamfail"), time = 3})
				EverythingMeth:send_message_to_peer(peer, EverythingMeth:LocalizeLine("fail"))
				EverythingMeth:tase_player(peer_id) --tased in order to prevent a peer from adding the wrong ingredient
			else
				EverythingMeth:untase_player(peer_id)
			end
		end
	end
end)

--[[	Other voicelines: (paraphrasing most)
	Play_loc_mex_cook_##:
		01 says "let's get started cooking"
		06 says "see any of that ingredient anywhere?"
		12 says "oh no, i had a feeling that was wrong" (wrong ingredient/explosion)
		13 says "first batch done"
		15 says "check the trucks for ingredients"
		16 says "that's enough loot, you can either keep cooking or leave when you want" 
		18 says "there's more ingredients around here if you look"
		19 says "hokay, let's have a look." (exact wording, no variants)
		20 says "that should get the process going" (cooking process)
		21 says "pour it in!" (generic cooking reminder)
		23 says "lost power, please restore it"
		
	Play_loc_count_gen_##:
		01 through 08 are used for counting;
		09 says "a couple more"
		10 says "one more"
		11 says "keep going"
		12 says "we have enough"
	
		13 through 15 are for post-heist, i believe
		13 says "maybe we'll get it right next time" (failure/methlab blown?)
		14 says "not bad, maybe next time we can get more (adequate amount but not extra)
		15 says "well done, this will bring a nice amount of change!" (large amount gotten)
--]]