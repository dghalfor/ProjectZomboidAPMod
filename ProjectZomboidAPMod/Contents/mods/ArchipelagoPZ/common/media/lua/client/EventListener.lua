local cmds = require "apcmds"
 
local function zombieKilled(zombie)
    if not zombie then return end
 
    local wd = cmds.worldData()
    if not wd.slot then return end 
 
    -- local player, not random burning down
    local killer = zombie:getAttackedBy()
    if not killer or not instanceof(killer, "IsoPlayer") or not killer:isLocalPlayer() then return end
 
    wd.kills = (wd.kills or 0) + 1
 
    if require("apclient").is_connected == 1 then
        cmds.sendmsg("KILLCNT:" .. tostring(wd.kills))
    end
end
 
Events.OnZombieDead.Add(zombieKilled)
 