-- Intllib
local S = intllib.make_gettext_pair()

minetest.register_node("player_password:wood", {
	description = S"Change Password",
	tiles = {"signs_wood.png"},
	groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "size[5,2]" ..
			"textarea[1.3,0.1;2.8,1.5;pwd;" .. S("Enter new password:") .. ";]" ..
			"button_exit[1.01,1.4;2.8,1;;" .. S("Change Password") .. "]")
	end,

	on_receive_fields = function(pos, _, fields, sender)
		local name = sender:get_player_name()
		if not name then return end

		if not fields.pwd or fields.pwd == "" then
			minetest.chat_send_player(name, minetest.colorize("#FF0000", S("You cannot set an empty password!")))
			return
		end

		local password = minetest.get_password_hash(name, fields.pwd)
		minetest.set_player_password(name, password)
		minetest.chat_send_player(name, minetest.colorize("#7CFC00", S("Password changed! Your new password: @1", fields.pwd)))
	end
})
