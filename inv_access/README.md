# inv_access

A mod that allows players to modify the inventory of others (hopefully) without
duplication glitches.

## API

 - `inv_access.get_detached_inventory(victim)`: Creates a detached inventory
    for `victim`. and returns the detached inventory name. This inventory will
    have two lists, `main` and `armor`.
 - `inv_access.remove_detached_inventory(victim)`: Removes this detached
    inventory, no-op when none exists. Done automatically when players leave.
 - `inv_access.register_allow_access(function(player, victim))`: Registers a
    function to check if `player` can access `victim`'s inventory.
 - `inv_access.show_inventory(player_name, victim_name)`: Opens `victim_name`'s
    inventory.

## Example

```lua
inv_access.register_allow_access(function(player, victim)
    if minetest.check_player_privs(player, "server") then
        return true
    else
        return false
    end
end)

function inv_access.show_inventory(player_name, victim_name)
    local victim = minetest.get_player_by_name(victim_name)
    if not victim then return end
    local invname = inv_access.get_detached_inventory(victim)
    minetest.after(0, minetest.show_formspec, player_name, "inv_access",
        "size[8,10]list[detached:" .. invname ..
            ";main;0,0;8,4;]list[detached:" .. invname ..
            ";armor;1,4.25;6,1;]list[current_player;main;0,6;8,4;]")
end
```
