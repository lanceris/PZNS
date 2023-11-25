local PZNS_NPCZonesManager = {};

local PZNS_Utils = require("02_mod_utils/PZNS_Utils")
local PZNS_NPCZone = require("03_mod_core/PZNS_NPCZone")

---comment
---@param groupID groupID
---@param zoneType string
---@return Zone zone
function PZNS_NPCZonesManager.createZone(
    groupID,
    zoneType,
    zoneID,
    name
)
    local zone
    zoneID = zoneID or groupID .. "_" .. zoneType
    local existingZone = PZNS_Utils.getZone(zoneID)
    if not existingZone then
        zone = PZNS_NPCZone:new(zoneID, name, groupID, zoneType);
        PZNS.Core.Zone.registry[zone.zoneID] = zone
    else
        zone = existingZone
    end
    return zone;
end

--- Cows: Get a zone by the input groupID.
---@param groupID groupID
function PZNS_NPCZonesManager.getZonesByGroupID(groupID)
    local activeZones = PZNS.Core.Zone.registry
    local groupZones = {};
    --
    if (activeZones ~= nil) then
        --
        for groupZoneID, groupZoneVal in pairs(activeZones) do
            if (groupZoneVal.groupID == groupID) then
                groupZones[groupZoneID] = groupZoneVal;
            end
        end
        return groupZones;
    end
    return nil;
end

--- Cows: Remove a group zone by the input groupID and zoneType.
---@param zoneType any
---@param groupID any
function PZNS_NPCZonesManager.removeZoneByGroupIDZoneType(groupID, zoneType)
    local activeZones = PZNS.Core.Zone.registry
    --
    if (activeZones == nil) then
        return;
    end
    --
    local groupZoneID = groupID .. "_" .. zoneType;
    local groupZone = activeZones[groupZoneID];
    --
    if (groupZone ~= nil) then
        activeZones[groupZoneID] = nil;
    end
end

return PZNS_NPCZonesManager;
