local cmds = require "apcmds"

local zones = require "apzones"
local defs = require("apzonedefs").DEFS

-- The zone the PLAYER is standing in (not the zombie), so a kill only counts towards a zone
-- the player is actually in and therefore has access to. Zone rectangles don't overlap.
local function playerZoneKey(player)
    local x, y = player:getX(), player:getY()
    for _, key in ipairs(zones.ZONES) do
        for _, r in ipairs(defs[key].points) do
            if x >= r[1] and x < r[3] and y >= r[2] and y < r[4] then
                return key
            end
        end
    end
    return nil
end

-- Counts kills made by local players. The total and the per-zone counts are saved with the world
local function zombieKilled(zombie)
    if not zombie then return end

    local wd = cmds.worldData()
    if not wd.slot then return end -- this world isn't linked to an archipelago yet

    -- Only credit a local player's own kill (the event fires for every zombie death).
    local killer = zombie:getAttackedBy()
    if not killer or not instanceof(killer, "IsoPlayer") or not killer:isLocalPlayer() then return end

    wd.kills = (wd.kills or 0) + 1

    local zone = playerZoneKey(killer)
    local zoneEntry = ""
    if zone then
        wd.zoneKills = wd.zoneKills or {}
        wd.zoneKills[zone] = (wd.zoneKills[zone] or 0) + 1
        zoneEntry = ":" .. zone .. "=" .. wd.zoneKills[zone]
    end

    if require("apclient").is_connected == 1 then
        cmds.sendmsg("KILLCNT:" .. tostring(wd.kills) .. zoneEntry)
    end
end

Events.OnZombieDead.Add(zombieKilled)