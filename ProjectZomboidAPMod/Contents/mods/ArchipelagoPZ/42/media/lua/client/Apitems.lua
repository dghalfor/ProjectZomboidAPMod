-- apitems.lua
-- Spawns the Archipelago "check" tokens into the world and turns picking one up into a location check.
--
--   spawn : polled, so it works whether or not the chunk was loaded when the world linked to a slot
--   pickup: wraps ISInventoryTransferAction:transferItem (singleplayer; see the note on transferItem below)
--   send  : "CHECK:<key>" through the existing pztalk.txt bridge (cmds.sendmsg)
--
-- Keys here MUST match ITEM_CHECKS in Locations.py (key column).
local cmds = require "apcmds"

local M = {}

M.TYPE = "PZAP.APCheck"
M.DEBUG = true

-- key, display name, and the square the token is dropped on.
-- PLACEHOLDER COORDINATES: replace with real squares (the tile must exist and be reachable).
M.SPAWNS = {
    { key = "muldraugh_north_1", name = "Muldraugh North Cache", x = 10700, y = 9200, z = 0 },
    { key = "muldraugh_south_1", name = "Muldraugh South - Stale Pizza", x = 10605, y = 10114, z = 0 },
}

local SPAWN_POLL_TICKS = 300 -- only unspawned entries are checked, so this is cheap
local SEND_POLL_TICKS = 60   -- one CHECK message per poll (pztalk.txt is overwritten, not appended)

-- Per-save state lives in the world ModData: wd.itemChecks[key] = { spawned = bool, found = bool }
local function states()
    local wd = cmds.worldData()
    wd.itemChecks = wd.itemChecks or {}
    return wd.itemChecks
end

local function log(text)
    local ui = ApUI and ApUI:getInstance()
    if ui then ui:addLog(text) end
end

local function dbg(text)
    if M.DEBUG then print("[APITEM] " .. text) end
end

-- Spawning retries forever, so report each reason once instead of every poll.
local warned = {}
local function warnOnce(id, text)
    if warned[id] then return end
    warned[id] = true
    dbg(text)
end

---------------------------------------------------------------------------
-- Spawning
---------------------------------------------------------------------------

local function spawnOne(def)
    local cell = getCell()
    if not cell then return false end
    local sq = cell:getGridSquare(def.x, def.y, def.z)
    if not sq then -- chunk not loaded yet (or the coordinates are off the map), try again later
        warnOnce(def.key .. ":sq", def.key .. ": no square at " .. def.x .. "," .. def.y .. "," .. def.z
            .. " yet (chunk not loaded, or bad coordinates). Retrying every poll.")
        return false
    end

    local r = sq:AddWorldInventoryItem(M.TYPE, 0.5, 0.5, 0)
    if not r then
        dbg("AddWorldInventoryItem returned nil for " .. def.key .. " (is ap_items.txt loaded?)")
        return false
    end
    -- Depending on version this returns the InventoryItem or the IsoWorldInventoryItem.
    local item = r
    if instanceof(r, "IsoWorldInventoryItem") then item = r:getItem() end
    if not item then return false end

    local md = item:getModData()
    md.apCheck = def.key
    item:setName(def.name)
    dbg("spawned " .. def.key .. " at " .. def.x .. "," .. def.y .. "," .. def.z)
    return true
end

function M.spawnPending()
    local wd = cmds.worldData()
    if not wd.slot then -- world isn't linked to a slot yet
        warnOnce("nolink", "not spawning: this world is not linked to an Archipelago slot yet (connect the client once)")
        return
    end
    local st = states()
    for _, def in ipairs(M.SPAWNS) do
        local s = st[def.key]
        if s and (s.spawned or s.found) then
            warnOnce(def.key .. ":done", def.key .. ": already spawned/found in this save, not spawning again")
        else
            if spawnOne(def) then
                st[def.key] = st[def.key] or {}
                st[def.key].spawned = true
            end
        end
    end
end

---------------------------------------------------------------------------
-- Pickup
---------------------------------------------------------------------------

local toRemove = {} -- { item = InventoryItem, container = ItemContainer }

local function checkFound(item, container)
    local key = item:getModData().apCheck
    if not key then return end
    local st = states()
    st[key] = st[key] or {}
    -- Consume the token either way (a re-picked-up token must not linger).
    table.insert(toRemove, { item = item, container = container })
    if st[key].found then return end -- already counted
    st[key].found = true
    st[key].spawned = true

    local p = getPlayer()
    if p then p:addLineChatElement("Archipelago check found!") end
    log("Found check: " .. key)
    dbg("found " .. key)
end

-- B42 ISInventoryTransferAction:perform() drains a queue of (possibly merged) items and calls
-- self:transferItem(item) once per item, so hooking transferItem sees every transfer, including
-- floor -> inventory pickups and bulk moves of light items. Singleplayer only: in multiplayer the
-- client never calls transferItem (the server transaction completes the move), so this would miss.
local function onTransferred(action, item)
    local character = action.character
    if not character or not instanceof(character, "IsoPlayer") or not character:isLocalPlayer() then return end
    local moved = action.item or item -- transferItem reassigns self.item to the item that was moved
    if not moved or moved:getFullType() ~= M.TYPE then return end
    local dest = action.destContainer
    if not dest or not dest:isInCharacterInventory(character) then return end
    if not dest:contains(moved) then return end -- blocked or favourited: nothing actually moved
    dbg("token transferred into player inventory")
    checkFound(moved, dest)
end

function M.installHooks()
    if M.hooked then return end -- OnGameStart fires again when another save is loaded
    local class = ISInventoryTransferAction
    if not class or not class.transferItem then
        print("[APITEM] ISInventoryTransferAction.transferItem not found, pickups will not be detected")
        return
    end
    local orig = class.transferItem
    class.transferItem = function(self, item, ...)
        local result = orig(self, item, ...)
        local ok, err = pcall(onTransferred, self, item)
        if not ok then print("[APITEM] transfer hook error: " .. tostring(err)) end
        return result
    end
    M.hooked = true
    dbg("wrapped ISInventoryTransferAction.transferItem")
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------

local sentThisSession = {}
local wasConnected = false

-- Locations are idempotent in Archipelago, so every found check is re-sent once per connection.
-- That covers checks found while disconnected and any message overwritten in pztalk.txt.
function M.sendPending()
    local connected = require("apclient").is_connected == 1
    if not connected then
        wasConnected = false
        return
    end
    if not wasConnected then
        wasConnected = true
        sentThisSession = {}
    end
    for key, s in pairs(states()) do
        if s.found and not sentThisSession[key] then
            cmds.sendmsg("CHECK:" .. key)
            sentThisSession[key] = true
            dbg("sent CHECK:" .. key)
            return -- one per poll
        end
    end
end

---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------

local tick = 0
local function onTick()
    tick = tick + 1

    -- Remove consumed tokens on the tick after they were counted.
    if #toRemove > 0 then
        for _, entry in ipairs(toRemove) do
            local c = entry.item:getContainer() or entry.container
            if c then c:Remove(entry.item) end
        end
        toRemove = {}
    end

    if tick % SPAWN_POLL_TICKS == 0 then M.spawnPending() end
    if tick % SEND_POLL_TICKS == 0 then M.sendPending() end
end

Events.OnGameStart.Add(function()
    M.installHooks() -- at game start so the vanilla timed-action class is certainly loaded
    Events.OnTick.Add(onTick)
    M.spawnPending()
end)

return M