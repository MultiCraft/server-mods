--[[

Copyright 2018 - Auke Kok <sofar@foo-projects.org>

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR
BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE.

]]--

local S = minetest.get_mod_storage()
assert(S)
local G = minetest.settings
assert(G)

local function nightandday()
	minetest.after(3.7, nightandday)

	local ds = S:get_int("day_time_speed") or 72
	local ns = S:get_int("night_time_speed") or 72

	local t = minetest.get_timeofday()
	local cts = tonumber(G:get("time_speed"))

	if t > 0.25 and t <= 0.75 then
		if cts ~= ds then
			G:set("time_speed", ds)
		end
	else
		if cts ~= ns then
			G:set("time_speed", ns)
		end
	end
end

minetest.register_chatcommand("nightandday", {
	params = "nightandday server",
	description = "Change day and night speeds",
	privs = {server = true},
	func = function(name, param)
		local p = string.split(param, " ", false, 2, false)
		if #p == 2 then
			local ds = tonumber(p[1])
			local ns = tonumber(p[2])
			if ds < 1 or ns < 1 then
				return false, "Usage: /nightandday dayspeed nightspeed"
			end
			S:set_int("day_time_speed", ds)
			S:set_int("night_time_speed", ns)
			return true, "Speeds set to: " .. ds .. ", " .. ns
		else
			return false, "Usage: /nightandday dayspeed nightspeed"
		end
	end
})

minetest.after(3.7, nightandday)
