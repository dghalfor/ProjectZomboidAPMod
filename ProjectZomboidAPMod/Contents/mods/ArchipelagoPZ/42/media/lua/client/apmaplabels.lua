-- apmaplabels.lua
-- Writes each PhunZones zone's name onto the world map as a map note (once per save).
-- BEST EFFORT: the B42 world-map symbols API could not be verified. Watch console.txt for [APMAP] lines.
local M = {}

M.LABELS = {
    { "KY-79 South", 7393, 14973 }, -- KY79South
    { "Irvington South", 2134, 14677 }, -- IrvingtonSouth
    { "Irvington North", 2081, 13785 }, -- IrvingtonNorth
    { "Irvington Speedway", 1012, 12616 }, -- IrvingtonSpeedway
    { "Wadsworth Lake", 4089, 12769 }, -- WadsworthLake
    { "Wadsworth Lake", 2450, 12616 }, -- WadsworthLake
    { "Echo Creek", 3779, 11321 }, -- EchoCreek
    { "Echo Creek", 3556, 10404 }, -- EchoCreek
    { "Guns Unlimited", 1959, 11003 }, -- GunsUnlimited
    { "Ekron", 525, 10522 }, -- Ekron
    { "KY-60", 2785, 8463 }, -- KY60
    { "KY-60", 546, 7982 }, -- KY60
    { "Brandenburg South", 2064, 6490 }, -- BrandenburgSouth
    { "Brandenburg North", 2064, 5785 }, -- BrandenburgNorth
    { "Sanatorium", 4126, 6164 }, -- Sanatorium
    { "West Maple Country Club", 5724, 6213 }, -- WestMapleCountryClub
    { "Riverside West", 5623, 5375 }, -- RiversideWest
    { "Riverside East", 6932, 5353 }, -- RiversideEast
    { "KY-163", 7033, 6812 }, -- KY163
    { "Deerhead Lake", 5497, 8463 }, -- DeerheadLake
    { "Fallas Lake", 7443, 9062 }, -- FallasLake
    { "KY-60 East", 5953, 11852 }, -- KY60East
    { "KY-60 East", 4519, 10404 }, -- KY60East
    { "KY-60 East", 8687, 10658 }, -- KY60East
    { "Rosewood Prison", 7534, 11775 }, -- RosewoodPrison
    { "Rosewood", 8391, 11766 }, -- Rosewood
    { "Rosewood", 7534, 11409 }, -- Rosewood
    { "Rosewood", 8374, 12960 }, -- Rosewood
    { "Rosewood", 9231, 11766 }, -- Rosewood
    { "Rosewood", 7534, 12132 }, -- Rosewood
    { "March Ridge", 11316, 12424 }, -- MarchRidge
    { "Muldraugh South", 10781, 10540 }, -- MuldraughSouth
    { "Muldraugh North", 10703, 9188 }, -- MuldraughNorth
    { "Muldraugh North", 9285, 9968 }, -- MuldraughNorth
    { "Muldraugh North", 12199, 10540 }, -- MuldraughNorth
    { "West Point outskirts", 9401, 7278 }, -- WestPointoutskirts
    { "West Point outskirts", 9811, 8282 }, -- WestPointoutskirts
    { "West Point", 11814, 7544 }, -- WestPoint
    { "West Point", 14041, 7607 }, -- WestPoint
    { "Dixie Highway", 12958, 5636 }, -- DixieHighway
    { "Dixie Highway", 14838, 6528 }, -- DixieHighway
    { "Crossroads Mall", 14634, 5476 }, -- CrossroadsMall
    { "Louisville Outskirts", 14476, 4000 }, -- LouisvilleOutskirts
    { "Louisville Outskirts", 14525, 2723 }, -- LouisvilleOutskirts
    { "Louisville Outskirts", 16373, 2723 }, -- LouisvilleOutskirts
    { "Louisville Outskirts", 15502, 2223 }, -- LouisvilleOutskirts
    { "Louiville - Chapelmount Downs", 12321, 2993 }, -- LouivilleChapelmountDowns
    { "Louiville State University", 12321, 2253 }, -- LouivilleStateUniversity
    { "Louisville - Evergreen Hill", 13695, 2875 }, -- LouisvilleEvergreenHill
    { "Iroquois Park", 13042, 2830 }, -- IroquoisPark
    { "Louisville - Fairgrounds", 13695, 2064 }, -- LouisvilleFairgrounds
    { "Louisville - Grand Ohio Mall", 13757, 1490 }, -- LouisvilleGrandOhioMall
    { "Louisville General Hospital", 13042, 2019 }, -- LouisvilleGeneralHospital
    { "Louisville - Oil Refineries", 12148, 1562 }, -- LouisvilleOilRefineries
    { "Louisville - River Road", 12800, 1185 }, -- LouisvilleRiverRoad
    { "Louisville - Kentucky State Prison", 12487, 1648 }, -- LouisvilleKentuckyStatePrison
    { "Louisville - Downtown", 12973, 1576 }, -- LouisvilleDowntown
}

M.SCALE = 3 -- text size multiplier

local VERSION = 3 -- bump to re-add labels after changing M.LABELS

local function wd()
    return ModData.getOrCreate("PZArchipelago")
end

local function getSymbols()
    local map = ISWorldMap_instance
    if not map or not map.mapAPI then return nil, "no ISWorldMap_instance.mapAPI" end
    if not map.mapAPI.getSymbolsAPI then return nil, "mapAPI has no getSymbolsAPI" end
    return map.mapAPI:getSymbolsAPI()
end

function M.addLabels()
    local data = wd()
    if data.mapLabelsVersion == VERSION then return end

    local ok, symbols, why = pcall(getSymbols)
    if not ok or not symbols then
        print("[APMAP] symbols API unavailable: " .. tostring(ok and why or symbols))
        return
    end
    if not symbols.addUntranslatedText then
        print("[APMAP] symbols API has no addUntranslatedText")
        return
    end

    local before = symbols.getSymbolCount and symbols:getSymbolCount() or 0
    local font = UIFont.Handwritten or UIFont.Medium
    local added = 0
    for _, l in ipairs(M.LABELS) do
        local okAdd, sym = pcall(symbols.addUntranslatedText, symbols, l[1], font, l[2], l[3])
        if okAdd then
            added = added + 1
            if sym then
                if sym.setRGBA then pcall(sym.setRGBA, sym, 0, 0, 0, 1) end
                if sym.setAnchor then pcall(sym.setAnchor, sym, 0.5, 0.5) end
                if sym.setScale then pcall(sym.setScale, sym, M.SCALE) end
            end
        else
            print("[APMAP] failed to add '" .. l[1] .. "': " .. tostring(sym))
        end
    end

    local after = symbols.getSymbolCount and symbols:getSymbolCount() or (before + added)
    print("[APMAP] added " .. added .. " labels (symbols " .. before .. " -> " .. after .. ")")
    if after > before then
        data.mapLabelsVersion = VERSION
    end
end

-- The map object only exists once the map has been opened, so add the labels after it first shows.
local function wrap(name)
    if not ISWorldMap or not ISWorldMap[name] then return end
    local orig = ISWorldMap[name]
    ISWorldMap[name] = function(...)
        local r = orig(...)
        pcall(M.addLabels)
        return r
    end
    print("[APMAP] hooked ISWorldMap." .. name)
end

Events.OnGameStart.Add(function()
    wrap("ShowWorldMap")
    wrap("ToggleWorldMap")
end)

return M