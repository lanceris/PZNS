---@class NPCZone
---@field zoneID zoneID             Unique zone identifier
---@field name string?              Zone name
---@field groupID groupID           Associated group ID
---@field zoneType string           Type of zone
---@field zoneBoundaryX1 integer    First corner X
---@field zoneBoundaryX2 integer    Second corner X
---@field zoneBoundaryY1 integer    First corner Y
---@field zoneBoundaryY2 integer    Second corner Y
---@field zoneBoundaryZ integer     Zone Z level
local PZNS_NPCZone = {}

---Creates new zone
---@param zoneID zoneID   Unique zone identifier
---@param name string?    Zone name
---@param groupID groupID Associated `groupID`
---@param zoneType string Type of zone
---@return table
function PZNS_NPCZone:new(
    zoneID,
    name,
    groupID,
    zoneType
)
    local npcZone = {
        zoneID = zoneID,
        name = name,
        groupID = groupID,
        zoneType = zoneType,
        zoneBoundaryX1 = 0,
        zoneBoundaryX2 = 0,
        zoneBoundaryY1 = 0,
        zoneBoundaryY2 = 0,
        zoneBoundaryZ = 0,
    }
    setmetatable(npcZone, self)
    self.__index = self

    return npcZone
end

return PZNS_NPCZone
