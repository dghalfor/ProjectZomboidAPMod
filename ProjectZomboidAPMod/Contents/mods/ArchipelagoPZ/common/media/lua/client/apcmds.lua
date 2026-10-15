local ap = require("apclient")
local cmds = {}
local lastmsg = ""

require "ApUi"

function cmds.sendmsg(msg)
    local file = getFileWriter("pztalk.sock", true, false)
    lastmsg = msg
    if file then
        file:write(msg)
        file:close()
    end
end

function cmds.resendmsg()
    local file = getFileWriter("pztalk.sock", true, false)
    if file then
        file:write(lastmsg)
        file:close()
    end
end

function cmds.sendkill(zombie)
    local killcnt = tostring(getPlayer():getZombieKills() + 1)
    local user = getPlayer():getUID()
    local strcount = tostring(killcnt)
    cmds.sendmsg("KILLCNT:".. strcount..":"..user)
end

function cmds.giveRandomFood(player, minAmount, maxAmount)
    local allItems = getScriptManager():getAllItems()
    local foodItems = {}
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item:getTypeString() == "Food" then
            table.insert(foodItems, item:getFullName())
        end
    end
    if #foodItems == 0 then
        print("No food items found!")
        return
    end
    local randomFood = foodItems[ZombRand(#foodItems) + 1]
    local amount = ZombRand(maxAmount - minAmount + 1) + minAmount
    player:getInventory():AddItems(randomFood, amount)
    print("Gave " .. amount .. "x " .. randomFood .. " to player")
    local ui = ApUI:getInstance()
    if ui then
        ui:addLog("Received " .. amount .. "x of food")
    end
end

function cmds.giveRandomCloth(player, minAmount, maxAmount)
    local allItems = getScriptManager():getAllItems()
    local ClothingItems = {}
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item:getTypeString() == "Clothing" then
            table.insert(ClothingItems, item:getFullName())
        end
    end
    if #ClothingItems == 0 then
        print("No Clothing items found!")
        return
    end
    local randomClothing = ClothingItems[ZombRand(#ClothingItems) + 1]
    local amount = ZombRand(maxAmount - minAmount + 1) + minAmount
    player:getInventory():AddItems(randomClothing, amount)
    print("Gave " .. amount .. "x " .. randomClothing .. " to player")
    local ui = ApUI:getInstance()
    if ui then
        ui:addLog("Received " .. amount .. "x of Clothing")
    end
end

function cmds.giveRandomMedic(player, minAmount, maxAmount)
    local allItems = getScriptManager():getAllItems()
    local MedicItems = {}
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item:getTypeString() == "Medical" then
            table.insert(MedicItems, item:getFullName())
        end
    end
    if #MedicItems == 0 then
        print("No Medic items found!")
        return
    end
    local randomMedic = MedicItems[ZombRand(#MedicItems) + 1]
    local amount = ZombRand(maxAmount - minAmount + 1) + minAmount
    player:getInventory():AddItems(randomMedic, amount)
    print("Gave " .. amount .. "x " .. randomMedic .. " to player")
    local ui = ApUI:getInstance()
    if ui then
        ui:addLog("Received " .. amount .. "x of Medical supplies")
    end
end

--[[ function cmds.recvall()
    local lit = Literature("", "", "", "")
    getPlayer():ReadLiterature(lit)
end ]]--

return cmds