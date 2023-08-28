require("00_references/init")

local function initNPCModData()
    PZNS.Core.NPC.registry = ModData.getOrCreate("PZNS_ActiveNPCs")
end

local function initGroupModData()
    PZNS.Core.Group.registry = ModData.getOrCreate("PZNS_ActiveGroups")
end

local function initFactionModData()
    PZNS.Core.Faction.registry = ModData.getOrCreate("PZNS_ActiveFactions")
end

local function initZoneModData()
    PZNS.Core.Zone.registry = ModData.getOrCreate("PZNS_ActiveZones")
end

function PZNS.Core.initModData()
    initNPCModData()
    initGroupModData()
    initFactionModData()
    initZoneModData()
end

---@alias _type string
---| '"all"' # all tables
---| '"npc"' # PZNS_ActiveNPCs
---| '"group"' # PZNS_ActiveGroups
---| '"faction"' # PZNS_ActiveFactions
---| '"zone"' # PZNS_ActiveZones

---@param _type _type
function PZNS.Core.clearModData(_type)
    local typeToModDataTable = {
        npc = "PZNS_ActiveNPCs",
        group = "PZNS_ActiveGroups",
        faction = "PZNS_ActiveFactions",
        zone = "PZNS_ActiveZones"
    }
    if _type == "all" then
        for _, value in pairs(typeToModDataTable) do
            ModData.remove(value)
        end
    elseif not typeToModDataTable[_type] then
        error("Invalid type: " .. _type)
        return
    else
        ModData.remove(typeToModDataTable[_type])
    end
    print(string.format("Cleared %s moddata", _type))
end
