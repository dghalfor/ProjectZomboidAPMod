local ap = {}
local cmds = require("apcmds")
local zones = require("apzones")
local lasttick = 0
ap.is_connected = 0

-- The first time you connect to a client, it will force that to be the new permanent one
local function linkWorld(msg)
    local seed, slot = string.match(msg, "^AP_READY:([^:]*):(.*)$")
    if not slot then return false end
    local wd = cmds.worldData()
    if not wd.slot then
        wd.slot = slot
        wd.seed = seed
        return true
    end
    if wd.slot == slot and wd.seed == seed then
        return true
    end
    getPlayer():addLineChatElement("This world is linked to Archipelago slot " .. wd.slot .. " (seed " .. tostring(wd.seed) .. ")")
    return false
end
 
local function handle(msg)
    if msg == "AP_QUIT" then
        getPlayer():addLineChatElement("AP Client Disconnected. Press HOME to reconnect")
        ap.disconnect()
        return true
    elseif msg == "RESEND" then
        cmds.resendmsg()
        print("ReSending...")
    elseif string.match(msg, "^ZONEBASE:") then
        -- Zone kill counts rebuilt from the checked locations (e.g. the world was started over).
        -- A zone the world already has a count for is left alone: the world's record wins.
        local wd = cmds.worldData()
        wd.zoneKills = wd.zoneKills or {}
        for zone, count in string.gmatch(msg:sub(10), "([^=,]+)=(%d+)") do
            if wd.zoneKills[zone] == nil then
                wd.zoneKills[zone] = tonumber(count)
            end
        end
    elseif string.match(msg, "^AP_RAND_FOOD_") then
        local num = tonumber(string.match(msg, "%d+$"))
        cmds.giveRandomFood(getPlayer(), 1, num)
    elseif string.match(msg, "^AP_RAND_CLOTH_") then
        local num = tonumber(string.match(msg, "%d+$"))
        cmds.giveRandomCloth(getPlayer(), 1, num)
    elseif string.match(msg, "^AP_RAND_MEDIC_") then
        local num = tonumber(string.match(msg, "%d+$"))
        cmds.giveRandomMedic(getPlayer(), 1, num)
    elseif msg:sub(1, 7) == "Map of " then
        local name = msg:sub(8):match("^%s*(.-)%s*$")
        local ok, info = zones.unlock(name)
        print("[AP-DEBUG] unlock('" .. name .. "') -> " .. tostring(ok) .. ", " .. tostring(info)) -- temporary
        local p = getPlayer()
        if p then
            p:addLineChatElement(ok and ("Zone unlocked: " .. info) or info)
        end
    else
        print("Msg from ap: " .. msg)
    end
    return false
end
 
local function recvmsg()
    local file = getFileReader("aptalk.txt", false)
    if file then
        -- Read every line: Archipelago can send many items at once.
        local lines = {}
        local line = file:readLine()
        while line do
            if line:len() > 0 then
                table.insert(lines, line)
            end
            line = file:readLine()
        end
        file:close()
        if #lines > 0 then
            local clearmsg = getFileWriter("aptalk.txt", false, false)
            if clearmsg then
                clearmsg:write("")
                clearmsg:close()
            end
            for _, msg in ipairs(lines) do
                print("[AP-DEBUG] recv: " .. msg) -- temporary
                -- "ITEM:<server index>:<message>". Archipelago resends every item on every
                -- sync, so skip indexes this world already received. Map unlocks are simply
                -- re-applied each time.
                local idx, payload = string.match(msg, "^ITEM:(%d+):(.*)$")
                if idx then
                    local wd = cmds.worldData()
                    idx = tonumber(idx)
                    if idx >= (wd.serverIndex or 0) then
                        wd.serverIndex = idx + 1
                        if handle(payload) then return end
                    elseif payload:sub(1, 7) == "Map of " then
                        handle(payload)
                    end
                elseif handle(msg) then
                    return
                end
            end
        end
    end
end
 
local function initconn()
    local file = getFileReader("aptalk.txt", true)
    if file then
        local msg = file:readLine()
        file:close()
        if msg and msg:len() > 0 and msg ~= "" then
            if string.match(msg, "^AP_READY") and linkWorld(msg) then
                local clearmsg = getFileWriter("aptalk.txt", true, false)
                if clearmsg then
                    clearmsg:write("")
                    clearmsg:close()
                end
                cmds.sendmsg("PZ_READY")
                return 0
            else
                local clearmsg = getFileWriter("aptalk.txt", true, false)
                if clearmsg then
                    clearmsg:write("")
                    clearmsg:close()
                end
                return -1
            end
        else
            local clearmsg = getFileWriter("aptalk.txt", true, false)
            if clearmsg then
                clearmsg:write("")
                clearmsg:close()
            end
            return -1
        end
    end
end
 
local function tick(tick)
    if lasttick == 0 then
        recvmsg()
        lasttick = tick + 6
    end
    if tick >= lasttick then
        lasttick = tick + 6
        recvmsg()
    end
end
 
function ap.connect()
    if initconn() == -1 then
        return -1
    end
    ap.is_connected = 1
    Events.OnTick.Add(tick)
    return 0
end
 
function ap.disconnect()
    cmds.sendmsg("PZ_QUIT")
    ap.is_connected = 0
    Events.OnTick.Remove(tick)
end
 
return ap