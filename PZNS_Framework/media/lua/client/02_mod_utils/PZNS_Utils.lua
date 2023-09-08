require("00_references/init")
local u = {}
local fmt = string.format

---@param group Group?
---@param groupID groupID
---@return boolean exist
u.groupCheck = function(group, groupID)
    if not group then
        print(fmt("Group not found! ID: %s", groupID))
        return false
    end
    return true
end

---@param npc NPC?
---@param survivorID survivorID
---@return boolean exist
u.npcCheck = function(npc, survivorID)
    if not npc then
        print(fmt("NPC not found! ID: %s", survivorID))
        return false
    end
    return true
end

---Get NPC by its survivorID
---@param survivorID survivorID
---@return NPC?
u.getNPC = function(survivorID)
    return PZNS.Core.NPC.registry[survivorID]
end

---Get Group by its groupID
---@param groupID groupID
---@return Group?
u.getGroup = function(groupID)
    return PZNS.Core.Group.registry[groupID]
end


---@param factionID factionID
---@return NPCFaction?
u.getFaction = function(factionID)
    return PZNS.Core.Faction.registry[factionID]
end

return u
