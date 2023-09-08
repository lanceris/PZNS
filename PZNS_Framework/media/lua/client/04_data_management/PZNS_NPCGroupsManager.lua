require("03_mod_core/init")

local PZNS_NPCGroupsManager = {};
local NPC = require("03_mod_core/PZNS_NPCSurvivor")
local Group = require("03_mod_core/PZNS_NPCGroup")
local u = require("02_mod_utils/PZNS_Utils")
local fmt = string.format

--- Cows: Create a new group based on the input groupID.
---@param groupID groupID Unique identifier for group
---@param name? string Group name
---@param leaderID? survivorID survivorID of group leader
---@param members? table<survivorID> group members
---@return Group? newGroup created `Group` or `nil` (if errors)
function PZNS_NPCGroupsManager.createGroup(groupID, name, leaderID, members)
    name = name or groupID
    members = members or {}
    local existing = u.getGroup(groupID)
    if existing then
        print(fmt("Group already exist! ID: %s", groupID))
        return existing
    end
    if leaderID then
        local leader = u.getNPC(leaderID)
        if not u.npcCheck(leader, leaderID) then return end ---@cast leader NPC
        if leader.groupID then
            print(fmt("NPC is already a member of another group! ID: %s; leaderID: %s", groupID, leaderID))
            return
        end
        members[#members + 1] = leaderID
    end
    if members then
        -- check that all members exist
        -- check that none of them are in other group
        local isLeaderIn = false
        for i = 1, #members do
            local member = members[i] ---@type string
            local npc = u.getNPC(member)
            if not u.npcCheck(npc, member) then return end ---@cast npc NPC
            if npc.groupID then
                print(fmt("NPC is already a member of another group! ID: %s; npcID: %s", groupID, member))
            end
            if leaderID and member == leaderID then isLeaderIn = true end
        end
        -- check that leaderID in members, if not - add
        if leaderID and not isLeaderIn then
            members[#members + 1] = leaderID
        end
    end
    local newGroup = Group:new(groupID, name, leaderID, members)
    -- update members groupID
    for i = 1, #newGroup.members do
        local npc = u.getNPC(newGroup.members[i])
        if npc then
            NPC.setGroupID(npc, newGroup.groupID)
        else
            print(fmt("Can't update groupID (NPC not found)! ID: %s; npcID: %s", groupID, newGroup.members[i]))
        end
    end

    PZNS.Core.Group.registry[groupID] = newGroup
    return newGroup
end

---Delete group by group ID, unset groupID for all members
---@param groupID groupID
function PZNS_NPCGroupsManager.deleteGroup(groupID)
    local group = u.getGroup(groupID)
    if not u.groupCheck(group, groupID) then return end ---@cast group Group
    local members = Group.getMembers(group)
    for i = 1, #members do
        local npc = u.getNPC(members[i])
        if npc then
            NPC.setGroupID(npc, nil)
        end
    end
    if group.factionID then
        print("Not yet implemented")
        -- local faction = getFaction(group.factionID)
        -- assert(faction, fmt("Faction not found! ID: %s; groupID: %s", group.factionID, groupID))
        -- group.factionID = nil
        -- faction:removeGroup(groupID)
    end
    PZNS.Core.Group.registry[groupID] = nil
end

--- Cows: Get a group by the input groupID.
---@param groupID groupID
---@return Group?
function PZNS_NPCGroupsManager.getGroupByID(groupID)
    return u.getGroup(groupID)
end

--- Get a group by the input name
---@param name string
---@return Group?
function PZNS_NPCGroupsManager.getGroupByName(name)
    for _, group in pairs(PZNS.Core.Group.registry) do
        if group.name == name then
            return group
        end
    end
end

--- Cows: Add a npcSurvivor to the specified group
---@param npcSurvivor NPC
---@param groupID groupID
function PZNS_NPCGroupsManager.addNPCToGroup(npcSurvivor, groupID)
    local survivorID = npcSurvivor.survivorID;

    local group = u.getGroup(groupID)
    if not u.groupCheck(group, groupID) then return end
    if npcSurvivor.groupID and npcSurvivor.groupID ~= groupID then
        print(fmt("NPC is already a member of another group! NPC groupID: %s; ID: %s; npcID: %s", npcSurvivor.groupID,
            groupID, survivorID))
        return
    end
    if npcSurvivor.groupID == groupID then
        if not Group.isMember(group, npcSurvivor.survivorID) then
            print("Group is set for NPC, but he's not a member!")
            Group.addMember(group, npcSurvivor.survivorID)
        else
            print(fmt("NPC is already a member of this group! ID: %s", survivorID))
        end
        return
    end
    Group.addMember(group, survivorID)
    NPC.setGroupID(npcSurvivor, groupID)
end

--- Cows: Add a npcSurvivor to the specified group
---@param survivorID survivorID
---@param groupID groupID
---@deprecated
function PZNS_NPCGroupsManager.addNPCToGroupById(survivorID, groupID)
    --[[As this function only used when creating player group and
    player is not an NPC yet - this check not needed ]]
    -- local npc = u.getNPC(survivorID)
    -- if not npc then return end
    local group = u.getGroup(groupID)
    if not u.groupCheck(group, groupID) then return end
    Group.addMember(group, survivorID)
    -- NPC.setGroupID(npc, groupID)
end

--- Cows: Remove a npcSurvivor from the specified group
---@param groupID groupID
---@param survivorID survivorID
function PZNS_NPCGroupsManager.removeNPCFromGroup(groupID, survivorID)
    local group = u.getGroup(groupID)
    if not u.groupCheck(group, groupID) then return end
    local npc = u.getNPC(survivorID)
    if not u.npcCheck(npc, survivorID) then return end ---@cast npc NPC
    if npc.groupID ~= groupID then
        print(fmt("NPC is not in this group! ID: %s; groupID: %s", survivorID, groupID))
        return
    end
    --
    Group.removeMember(group, survivorID)
    NPC.setGroupID(npc, nil)
end

---Get group members
---@param groupID groupID
---@return table<survivorID?> members list of group members
function PZNS_NPCGroupsManager.getMembers(groupID)
    local group = u.getGroup(groupID)
    if not u.groupCheck(group, groupID) then return {} end
    return Group.getMembers(group)
end

--- Cows: Get the group members count by the input groupID.
---@param groupID groupID
function PZNS_NPCGroupsManager.getGroupMembersCount(groupID)
    local group = u.getGroup(groupID)
    if not u.groupCheck(group, groupID) then return end
    return Group.getMemberCount(group)
end

---Set new `Group` leader
---@param groupID groupID
---@param leaderID survivorID
function PZNS_NPCGroupsManager.setLeader(groupID, leaderID)
    local group = u.getGroup(groupID)
    if not u.groupCheck(group, groupID) then return end ---@cast group Group
    local npc = u.getNPC(leaderID)
    if not u.npcCheck(npc, leaderID) then return end ---@cast npc NPC
    if npc.groupID ~= groupID then
        fmt("NPC is not a member of this group! ID: %s; leaderID: %s", groupID, leaderID)
        return
    end
    if group.leaderID == leaderID then
        print(fmt("NPC is already the leader of this group! ID: %s; leaderID: %s", groupID, leaderID))
        return
    end
    Group.setLeader(group, leaderID)
end

---Set new name for the `Group`
---@param groupID groupID
---@param newName string
function PZNS_NPCGroupsManager.setGroupName(groupID, newName)
    local group = u.getGroup(groupID)
    if not u.groupCheck(group, groupID) then return end
    Group.setName(group, newName)
end

--backward compat
PZNS_NPCGroupsManager.removeNPCFromGroupBySurvivorID = PZNS_NPCGroupsManager.removeNPCFromGroup


return PZNS_NPCGroupsManager;
