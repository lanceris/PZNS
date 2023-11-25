local PZNS_Utils = {}
local fmt = string.format

---@param group PZNS_NPCGroup?
---@param groupID groupID
---@return boolean exist
PZNS_Utils.groupCheck = function(group, groupID)
    if not group then
        print(fmt("Group not found! ID: %s", groupID))
        return false
    end
    return true
end

---@param npc PZNS_NPCSurvivor?
---@param survivorID survivorID
---@return boolean exist
PZNS_Utils.npcCheck = function(npc, survivorID)
    if not npc then
        print(fmt("NPC not found! ID: %s", survivorID))
        return false
    end
    return true
end

---Get NPC by its survivorID
---@param survivorID survivorID
---@return PZNS_NPCSurvivor?
PZNS_Utils.getNPC = function(survivorID)
    return PZNS.Core.NPC.registry[survivorID]
end

---Get Group by its groupID
---@param groupID groupID
---@return PZNS_NPCGroup?
PZNS_Utils.getGroup = function(groupID)
    return PZNS.Core.Group.registry[groupID]
end


---get zone by ID
---@param zoneID zoneID
PZNS_Utils.getZone = function(zoneID)
    return PZNS.Core.Zone.registry[zoneID]
end


---@param factionID factionID
---@return PZNS_NPCFaction?
PZNS_Utils.getFaction = function(factionID)
    return PZNS.Core.Faction.registry[factionID]
end

return PZNS_Utils
