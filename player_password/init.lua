-- Intllib
local S = intllib.make_gettext_pair()

minetest.register_node("player_password:wood", {
	description = S("Change Password"),
	tiles = {"signs_wood.png"},
	groups = {oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Change Password"))
		meta:set_string("formspec", "size[5,2]" ..
			"textarea[1.3,0.1;2.8,1.5;pwd;" .. S("Enter new password:") .. ";${sign_text}]" ..
			"button_exit[1.01,1.4;2.8,1;;" .. S("Change Password") .. "]")
	end,

	on_receive_fields = function(pos, _, fields, sender)
		local name = sender:get_player_name()
		local pwd = fields.pwd
		if not name or not pwd then return end

		if pwd == "" then
			minetest.chat_send_player(name,
				minetest.colorize("#FF0000", S("You cannot set an empty password!")))
			return
		end
		if #pwd < 3 then
			minetest.chat_send_player(name,
				minetest.colorize("#FF0000", S("The password is too short! Minimum length - 3 characters.")))
			return
		end
		if #pwd > 24 then
			minetest.chat_send_player(name,
				minetest.colorize("#FF0000", S("The password is too long! Maximum length - 24 characters.")))
			return
		end
		if pwd:find("[^a-zA-Z0-9%-_]") then
			minetest.chat_send_player(name,
				minetest.colorize("#FF0000", S("The password contains prohibited characters! Use only Latin letters or numbers.")))
		end

		local password = minetest.get_password_hash(name, pwd)
		minetest.set_player_password(name, password)
		minetest.chat_send_player(name, minetest.colorize("#7CFC00", S("Password changed! Your new password: @1", pwd)))
	end
})
