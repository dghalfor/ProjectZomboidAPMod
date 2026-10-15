local M = {}

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

local canonical, startSet = {}, {}
for _, k in ipairs(M.ZONES) do canonical[k:lower()] = k end
for _, k in ipairs(M.START) do startSet[k] = true end

-- Unlocked zones for this save: key -> true. PhunZones.json is only a cache of this.
local function state() return ModData.getOrCreate("APZones") end

local function isOpen(key) return startSet[key] or state()[key] end

-- Full reconcile: writes noplayers for every gated zone in a single rebuild.
function M.sync()
    if not (PhunZones and PhunZones.saveChanges) then return false end
    local changes = {}
    for _, key in ipairs(M.ZONES) do
        changes[key] = { noplayers = not isOpen(key) }
    end
    PhunZones.saveChanges(changes)
    return true
end

-- Unlock one zone by name (case-insensitive). Idempotent.
-- Returns ok, canonicalKey (on success) or an error message (on failure).
function M.unlock(name)
    local key = canonical[tostring(name or ""):lower()]
    if not key then return false, "unknown zone: " .. tostring(name) end
    local s = state()
    if s[key] then return true, key end
    s[key] = true
    if PhunZones and PhunZones.saveChanges then
        PhunZones.saveChanges({ [key] = { noplayers = false } })
    end
    return true, key
end

-- Reconcile once PhunZones has finished loading.
local ev = PhunZones and PhunZones.events and PhunZones.events.OnPhunZoneReady
if ev and Events[ev] then Events[ev].Add(M.sync) end

return M