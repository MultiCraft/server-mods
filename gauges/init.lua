local enable_damage = minetest.settings:get_bool("enable_damage")
local vector_distance = vector.distance

local function add_gauge(player)
	if player and player:is_player() then
		local entity = minetest.add_entity(player:get_pos(), "gauges:hp_bar")

		entity:set_attach(player, "", {x = 0, y = 19, z = 0}, {x = 0, y = 0, z = 0})
		entity:get_luaentity().wielder = player
	end
end

minetest.register_entity("gauges:hp_bar", {
	visual = "sprite",
	visual_size = {x = 0.8, y = 0.8/16, z = 0.8},
	textures = {"blank.png"},
	collisionbox = {0},
	physical = false,

	on_step = function(self)
		local player = self.wielder
		local gauge  = self.object

		if not enable_damage or
				not player or not player:is_player() then
			gauge:remove()
			return
		elseif vector_distance(player:get_pos(), gauge:get_pos()) > 3 then
			gauge:remove()
			add_gauge(player)
			return
		end

		local hp     = player:get_hp()     <= 20 and player:get_hp()     or 20
		local breath = player:get_breath() <  10 and player:get_breath() or 11

		if self.hp ~= hp or self.breath ~= breath then
			gauge:set_properties({
				textures = {
					"health_" .. hp .. ".png^" ..
					"breath_" .. breath .. ".png"
				}
			})
			self.hp     = hp
			self.breath = breath
		end
	end
})

if enable_damage then
	minetest.register_on_joinplayer(function(player)
		minetest.after(1, add_gauge, player)
	end)
end
