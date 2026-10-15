local M = {}
local defs = require("apzonedefs").DEFS

-- Gated PhunZones keys, taken from PhunZones.json. Spelling must match exactly,
-- including the existing typos in LouivilleChapelmountDowns / LouivilleStateUniversity.
-- Left out on purpose: "Inaccessible" and the disabled "Coalfieldroad".
M.ZONES = {
    "KY79South", "IrvingtonSouth", "IrvingtonNorth", "IrvingtonSpeedway", "WadsworthLake",
    "EchoCreek", "GunsUnlimited", "Ekron", "KY60", "BrandenburgSouth", "BrandenburgNorth",
    "Sanatorium", "WestMapleCountryClub", "RiversideWest", "RiversideEast", "KY163",
    "DeerheadLake", "FallasLake", "KY60East", "RosewoodPrison", "Rosewood", "MarchRidge",
    "MuldraughSouth", "MuldraughNorth", "WestPointoutskirts", "WestPoint", "DixieHighway",
    "CrossroadsMall", "LouisvilleOutskirts", "LouivilleChapelmountDowns", "LouivilleStateUniversity",
    "LouisvilleEvergreenHill", "IroquoisPark", "LouisvilleFairgrounds", "LouisvilleGrandOhioMall",
    "LouisvilleGeneralHospital", "LouisvilleOilRefineries", "LouisvilleRiverRoad",
    "LouisvilleKentuckyStatePrison", "LouisvilleDowntown",
}

-- Always open. Set this to the Archipelago start region(s).
M.START = { "MuldraughNorth", "MuldraughSouth" }

-- Zone border colour on the PhunZones map (PhunZones.json "mapBorder").
M.COLOR_LOCKED = "#E53935"   -- red
M.COLOR_UNLOCKED = "#43A047" -- green

local canonical, startSet = {}, {}
for _, k in ipairs(M.ZONES) do canonical[k:lower()] = k end
for _, k in ipairs(M.START) do startSet[k] = true end

-- Unlocked zones for this save: key -> true. PhunZones.json is only a cache of this.
local function state() return ModData.getOrCreate("APZones") end

local function isOpen(key) return startSet[key] or state()[key] end

-- PhunZones.saveChanges merges into its in-memory layer (global ModData "PhunZones") and then
-- rewrites PhunZones.json from that layer. If it runs before PhunZones has loaded the file, the layer
-- is empty and the file is overwritten with only these changes (titles, points and inherits are lost).
-- So only save once that layer holds data.
local function save(changes)
    if not (PhunZones and PhunZones.saveChanges) then return false end
    local layer = ModData.get("PhunZones")
    if type(layer) ~= "table" then return false end
    local hasData = false
    for _ in pairs(layer) do hasData = true break end -- Kahlua has no global next()
    if not hasData then return false end
    PhunZones.saveChanges(changes)
    return true
end

-- Full reconcile: writes the zone definitions plus noplayers/border for every gated zone in a single rebuild.
function M.sync()
    local changes = {}
    for key, def in pairs(defs) do
        changes[key] = { title = def.title, inherits = "_default", points = def.points }
        if def.disabled then changes[key].disabled = true end
    end
    for _, key in ipairs(M.ZONES) do
        local open = isOpen(key) and true or false
        changes[key].noplayers = not open
        changes[key].mapBorder = open and M.COLOR_UNLOCKED or M.COLOR_LOCKED
    end
    for key, def in pairs(defs) do
        if def.noplayers ~= nil then changes[key].noplayers = def.noplayers end
    end
    return save(changes)
end

-- Unlock one zone by name (case-insensitive). Idempotent.
-- Returns ok, canonicalKey (on success) or an error message (on failure).
function M.unlock(name)
    local key = canonical[tostring(name or ""):lower()]
    if not key then return false, "unknown zone: " .. tostring(name) end
    local s = state()
    if s[key] then return true, key end
    s[key] = true
    save({ [key] = { noplayers = false, mapBorder = M.COLOR_UNLOCKED } })
    return true, key
end

-- This mod loads before PhunZones, so PhunZones (and its ready event) don't exist yet when this
-- file runs. Look for them once the game has started instead, and reconcile right away.
Events.OnGameStart.Add(function()
    local ev = PhunZones and PhunZones.events and PhunZones.events.OnPhunZoneReady
    if ev and Events[ev] then Events[ev].Add(M.sync) end
    M.sync()
end)

return M