--
-- inv_access: Allows players to access the inventory of others
-- See README.md for API documentation
--
-- Copyright © 2020 by luk3yx
-- Copyright © 2021 MultiCraft Development Team
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.

-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
--

inv_access = {}

local invs = {}

local allow_access_funcs = {}
local function allow_access(player, victim)
	if player:get_player_name() == victim:get_player_name() then
		return false
	end

	for _, func in ipairs(allow_access_funcs) do
		if func(player, victim) then
			return true
		end
	end
end

local function update_reverse(player_inv, detached_inv)
	detached_inv:set_size("main", player_inv:get_size("main"))
	detached_inv:set_list("main", player_inv:get_list("main"))

	local armor_inv = minetest.get_inventory({
		type = "detached",
		name = player_inv:get_location().name .. "_armor"
	})
	if armor_inv then
		detached_inv:set_size("armor", armor_inv:get_size("armor"))
		detached_inv:set_list("armor", armor_inv:get_list("armor"))
	end
end

local function get_detached_inv_funcs(name)
	local function update(action, player, detached_inv, stack)
		-- Log
		local to_from = "into"
		if action == "move" then
			to_from = "in"
		elseif action == "take" then
			to_from = "from"
		end
		local msg = ("[inv_access] %s %ss %s %s %s's inventory"):format(
			player:get_player_name(), action,
			stack and stack:to_string() or "an item", to_from, name
		)
		minetest.log("action", msg)

		local victim = assert(minetest.get_player_by_name(name))
		local inv = victim:get_inventory()
		inv:set_list("main", detached_inv:get_list("main"))

		local armor_inv = minetest.get_inventory({
			type = "detached",
			name = name .. "_armor"
		})
		if armor_inv then
			armor_inv:set_list("armor", detached_inv:get_list("armor"))
			armor:save_armor_inventory(victim)
			armor:set_player_armor(victim)
		end
	end

	-- Update detached inventories on allow_* callbacks.
	-- This prevents any duplication bugs that may be introduced when other
	-- mods add/remove items to/from player inventories.
	local function update_detached(detached_inv)
		local victim = minetest.get_player_by_name(name)
		if victim then
			local inv = victim:get_inventory()
			update_reverse(inv, detached_inv)
		end
		return victim
	end

	return {
		allow_move = function(inv, from_list, _, to_list, _, count, player)
			local victim = update_detached(inv, from_list, to_list)
			if victim and to_list == "main" and
					allow_access(player, victim) then
				return count
			end
			return 0
		end,

		allow_put = function(inv, listname, _, stack, player)
			local victim = update_detached(inv, listname)
			if victim and listname == "main" and
					allow_access(player, victim) then
				return stack:get_count()
			end
			return 0
		end,

		allow_take = function(inv, listname, _, stack, player)
			local victim = update_detached(inv, listname)
			if victim and allow_access(player, victim) then
				return stack:get_count()
			end
			return 0
		end,

		on_move = function(inv, _, _, _, _, _, player)
			update("move", player, inv)
		end,
		on_put = function(inv, _, _, stack, player)
			update("put", player, inv, stack)
		end,
		on_take = function(inv, _, _, stack, player)
			update("take", player, inv, stack)
		end
	}
end

function inv_access.get_detached_inventory(victim)
	assert(minetest.is_player(victim))
	local name = victim:get_player_name()
	local invname = "inv_access:" .. name
	if not invs[name] then
		local detached_inv = minetest.create_detached_inventory(invname,
			get_detached_inv_funcs(name))
		invs[name] = detached_inv
		update_reverse(victim:get_inventory(), detached_inv)
	end
	return invname
end

-- Update detached inventories if the player moves items to/from the list
minetest.register_on_player_inventory_action(function(player, _, inv)
	local detached_inv = invs[player:get_player_name()]
	if detached_inv then
		update_reverse(inv, detached_inv)
	end
end)

function inv_access.remove_detached_inventory(victim)
	local name = victim:get_player_name()
	if invs[name] then
		minetest.remove_detached_inventory("inv_access:" .. name)
		invs[name] = nil
	end
end

minetest.register_on_leaveplayer(inv_access.remove_detached_inventory)

function inv_access.register_allow_access(func)
	table.insert(allow_access_funcs, func)
end

local function make_cells(x, y, w, h)
	local cells = {}
	local i = 1
	for x2 = x, x + w - 1 do
		for y2 = y, y + h - 1 do
			cells[i] = "item_image[" .. x2 .. "," .. y2 .. ";1,1;default:cell]"
			i = i + 1
		end
	end
	return table.concat(cells)
end

local fs = "size[9,11.6]" ..
	default.gui_bg ..
	default.listcolors ..
	"background[0,0;0,0;formspec_background_color.png;true]" ..
	"background[-0.19,2.68;9.4,9.43;formspec_inventory.png]" ..
	"image[7.95,6.03;1.1,1.1;^[colorize:#D6D5E6]]" ..
	"image_button_exit[8.4,-0.1;0.75,0.75;close.png;exit;;true;" ..
		"false;close_pressed.png]" ..
	"list[current_player;main;0.01,7.4;9,3;9]" ..
	"list[current_player;main;0.01,10.62;9,1;]" ..
	make_cells(0, 1, 9, 3) ..
	make_cells(0, 4.22, 9, 1)

function inv_access.show_inventory(player_name, victim_name)
	local player = minetest.get_player_by_name(player_name)
	local victim = minetest.get_player_by_name(victim_name)
	if not player or not victim then return false end
	local invname = inv_access.get_detached_inventory(victim)
	minetest.after(0, minetest.show_formspec, player_name, "inv_access",
		fs ..
		"image[0,-0.1;1,1;" .. player_api.preview(victim, nil, true) .. "]" ..
		"label[1,0.1;" .. minetest.formspec_escape("Inventory of " ..
			victim_name) .. "]" ..
		"list[detached:" .. invname .. ";main;0,1;9,3;9]" ..
		"list[detached:" .. invname .. ";main;0,4.22;9,1;]" ..
		"label[5,5.5;Player's armor]" ..
		"image[5,6.04;1,1;formspec_cell.png^3d_armor_inv_helmet.png]" ..
		"image[6,6.04;1,1;formspec_cell.png^3d_armor_inv_chestplate.png]" ..
		"image[7,6.04;1,1;formspec_cell.png^3d_armor_inv_leggings.png]" ..
		"image[8,6.04;1,1;formspec_cell.png^3d_armor_inv_boots.png]" ..
		"list[detached:" .. invname .. ";armor;5,6.04;4,1;]"
	)
	return true
end

local function check_privs(player)
	return minetest.check_player_privs(player, "moderator") or
		minetest.check_player_privs(player, "server")
end

inv_access.register_allow_access(check_privs)

minetest.register_chatcommand("inventory", {
	description = "Opens the inventory of a player.",
	params = "<player>",
	func = function(name, param)
		if not check_privs(name) then
			return false, "Insufficient privileges"
		elseif inv_access.show_inventory(name, param) then
			return true
		else
			return false, "The specified player is not online."
		end
	end
})
minetest.register_chatcommand_alias("inv", "inventory")
