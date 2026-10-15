local ap = {}
local cmds = require("apcmds")
local zones = require("apzones")
local lasttick = 0
ap.is_connected = 0

local function recvmsg()
    local file = getFileReader("aptalk.sock", false)
    if file then
        local msg = file:readLine()
        file:close()
        if msg and msg:len() > 0 and msg ~= "" then
            local clearmsg = getFileWriter("aptalk.sock", false, false)
            if clearmsg then
                clearmsg:write("")
                clearmsg:close()
            end
            if msg == "AP_QUIT" then
                getPlayer():addLineChatElement("AP Client Disconnected. Press HOME to reconnect")
                ap.disconnect()
                return
            elseif msg == "RESEND" then
                cmds.resendmsg()
                print("ReSending...")
            elseif string.match(msg, "^AP_RAND_FOOD_") then
                local num = tonumber(string.match(msg, "%d+$"))
                cmds.giveRandomFood(getPlayer(), 1, num)
            elseif string.match(msg, "^AP_RAND_CLOTH_") then
                local num = tonumber(string.match(msg, "%d+$"))
                cmds.giveRandomCloth(getPlayer(), 1, num)
            elseif string.match(msg, "^AP_RAND_MEDIC_") then
                local num = tonumber(string.match(msg, "%d+$"))
                cmds.giveRandomMedic(getPlayer(), 1, num)
            elseif msg:sub(1, 11) == "unlockZone " then
                local name = msg:sub(12):match("^%s*(.-)%s*$")
                local ok, info = zones.unlock(name)
                local p = getPlayer()
                if p then
                    p:addLineChatElement(ok and ("Zone unlocked: " .. info) or info)
                end
            else
                print("Msg from ap: " .. msg)
            end
        end
    end
end

local function initconn()
    local file = getFileReader("aptalk.sock", true)
    if file then
        local msg = file:readLine()
        file:close()
        if msg and msg:len() > 0 and msg ~= "" then
            if msg == "AP_READY" then
                local clearmsg = getFileWriter("aptalk.sock", true, false)
                if clearmsg then
                    clearmsg:write("")
                    clearmsg:close()
                end
                cmds.sendmsg("PZ_READY")
                return 0
            else
                local clearmsg = getFileWriter("aptalk.sock", true, false)
                if clearmsg then
                    clearmsg:write("")
                    clearmsg:close()
                end
                return -1
            end
        else
            local clearmsg = getFileWriter("aptalk.sock", true, false)
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
    Events.OnZombieDead.Add(cmds.sendkill)
    Events.OnTick.Add(tick)
    return 0
end

function ap.disconnect()
    cmds.sendmsg("PZ_QUIT")
    ap.is_connected = 0
    Events.OnZombieDead.Remove(cmds.sendkill)
    Events.OnTick.Remove(tick)
end

return ap