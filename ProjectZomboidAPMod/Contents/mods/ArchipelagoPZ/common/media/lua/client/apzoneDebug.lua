-- apcheck.lua  (temporary: delete after use)
-- Put next to your other mod Lua files (media/lua/client). Prints a status report to
-- console.txt, once when the game starts and again about 10 seconds later, because
-- PhunZones may load after this does. Search the log for [APCHECK].
-- It only reads state. It does not unlock anything.

local function report(label)
    print("[APCHECK] ---- " .. label .. " ----")

    print("[APCHECK] PhunZones is " .. (PhunZones and "present" or "NIL"))
    if PhunZones then
        print("[APCHECK] PhunZones.saveChanges is " .. type(PhunZones.saveChanges))
        print("[APCHECK] PhunZones.events is " .. type(PhunZones.events))
        local ev = PhunZones.events and PhunZones.events.OnPhunZoneReady
        print("[APCHECK] OnPhunZoneReady name: " .. tostring(ev) .. ", Events entry: " .. tostring(ev and Events[ev]))
    end

    local ok, zones = pcall(require, "apzones")
    print("[APCHECK] require apzones: " .. tostring(ok))
    if ok and type(zones) == "table" then
        local found = false
        for _, k in ipairs(zones.ZONES or {}) do
            if k:lower() == "dixiehighway" then found = k end
        end
        print("[APCHECK] DixieHighway in ZONES: " .. tostring(found))
    end

    local az = ModData.getOrCreate("APZones")
    local open = {}
    for k, v in pairs(az) do
        if v then table.insert(open, tostring(k)) end
    end
    table.sort(open)
    print("[APCHECK] zones marked unlocked in this save: " .. (#open > 0 and table.concat(open, ", ") or "(none)"))

    local wd = ModData.getOrCreate("PZArchipelago")
    print("[APCHECK] world slot=" .. tostring(wd.slot) .. " seed=" .. tostring(wd.seed)
        .. " serverIndex=" .. tostring(wd.serverIndex) .. " kills=" .. tostring(wd.kills))

    local ap = require("apclient")
    print("[APCHECK] apclient.is_connected=" .. tostring(ap.is_connected))
end

local ticks = 0
local function onTick()
    ticks = ticks + 1
    if ticks == 600 then
        Events.OnTick.Remove(onTick)
        report("10 seconds after start")
    end
end

Events.OnGameStart.Add(function()
    report("game start")
    Events.OnTick.Add(onTick)
end)