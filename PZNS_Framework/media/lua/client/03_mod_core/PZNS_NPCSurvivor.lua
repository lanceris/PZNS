require("00_references/init")

---@class NPC
---@field survivorID survivorID
---@field survivorName string
---@field mpPlayerID integer playerNum
---@field survivorNickname string?
---@field groupID groupID?
---@field factionID factionID?
---@field affection integer
---@field isPlayer boolean
---@field isForcedMoving boolean
---@field isHoldingInPlace boolean
---@field isMeleeOnly boolean
---@field isRaider boolean
---@field isSavedInWorld boolean
---@field courage integer
---@field jobName string
---@field jobSquare IsoGridSquare?
---@field isJobRefreshed boolean
---@field currentAction string
---@field isStuckTicks integer
---@field followTargetID survivorID
---@field speechTable table?
---@field lastEquippedMeleeWeapon string
---@field lastEquippedRangeWeapon string
---@field idleTicks integer
---@field actionTicks integer
---@field attackTicks integer
---@field speechTicks integer
---@field aimTarget IsoGameCharacter? can IsoObject (not npc/zombie) be targeted?
---@field canAttack boolean
---@field canSaveData boolean
---@field textObject TextDrawObject
---Relations
---@field relationsMap table<survivorID, integer?> to represent relations of this NPC to other NPCs
---@field initialRelation integer
---@field _minRelation integer
---@field _maxRelation integer
---@field anonymousMap table<survivorID, integer?> to represent seen-but-unknown NPCs and relation offset to them (applied when first met i.e moved to relationsMap)
---IsoPlayer Spawning Related fields
---@field isAlive boolean
---@field isSpawned boolean
---@field forename string
---@field surname string
---@field isFemale boolean
---@field squareX integer?
---@field squareY integer?
---@field squareZ integer?
---@field npcIsoPlayerObject IsoPlayer
local NPC = {}

--- Cows: Construct the PZNS_NPCSurvivor.
---@param survivorID survivorID         -- Cows: Unique Identifier for the current NPC
---@param survivorName any              -- Cows: Current NPC's name
---@param npcIsoPlayerObject IsoPlayer  -- Cows: The actual IsoPlayer object the current NPC is spawned in as. NPCUtils will mostly interact with this object.
---@return table
function NPC:new(
    survivorID,
    survivorName,
    npcIsoPlayerObject
)
    local npcSurvivor = {
        survivorID = survivorID,
        survivorName = survivorName,
        mpPlayerID = nil,
        survivorNickname = nil,
        groupID = nil,
        factionID = nil,
        isPlayer = false, -- Indicates whether this survivor is human player or NPC (for job/textObject update purposes)
        ----- Relations -----
        relationsMap = {},
        initialRelation = 0,                    -- From this NPC to all others (e.g misanthrope will have negative bias by default)
        _minRelation = 0,                       -- Should not be manipulated directly
        _maxRelation = 50,                      -- Should not be manipulated directly
        anonymousMap = {},
        affection = 50,                         -- WIP - Cows: Added this value as a check for invite-able NPCs... between 0 and 100? 0 Means 100% hostility and will attack.
        isForcedMoving = false,                 -- Cows: Added this flag to force NPCs to move and disengage from combat/other actions.
        isHoldingInPlace = false,               -- Cows: Prevent current NPC from moving if true
        isMeleeOnly = false,                    -- WIP - Cows: Will eventually be used in more complex combat AI.
        isRaider = false,                       -- WIP - Cows: Used to test raiding NPCs
        isSavedInWorld = false,                 -- Cows: Added so that NPC can be checked and saved when it is off-screen.
        courage = 50,                           -- WIP - Cows: Considered for evaluating when NPCs should "flee" from hostility
        jobName = "Guard",                      -- Cows: Defaults to a job managed by PZNS
        jobSquare = nil,                        -- Cows: The square at which the NPC do its job (pickup item, chop tree, etc.)
        isJobRefreshed = false,                 -- Cows: This is a flag to check for NPCs to "refresh" their job status.
        currentAction = "",                     -- Cows: This is a value to check for NPCs to queue or not queue up more actions.
        followTargetID = "",                    -- Cows: Used to follow a specified object managed by PZNS IDs
        speechTable = nil,                      -- Cows: Used when adding speech table(s), if nil, NPCs should use PresetsSpeeches instead.
        lastEquippedMeleeWeapon = "",           -- WIP - Cows: Added so that NPCs can resume using this melee weapon after completing an action.
        lastEquippedRangeWeapon = "",           -- WIP - Cows: Added so that NPCs can resume using this range weapon after completing an action.
        idleTicks = 0,                          -- Cows: Used to track how long an NPC is idle for before they take some general AI stuff.
        isStuckTicks = 0,                       -- Cows: Used check if NPC is "stuck" or doing nothing even though it has a job.
        moveTicks = 0,                          -- Cows: Used to track how long the NPC is moving about. Added to determine how often to update pathing.
        jobTicks = 0,                           -- Cows: Used to track how often NPCs updates their job routine. This was added because actionTicks is intended for actions only.
        actionTicks = 0,                        -- Cows: This is a value used to determine the frequency of an action being called, most notably with multi-stage actions (such as reloading).
        attackTicks = 0,                        -- Cows: I thought it was stupid at first, but after observing an NPC queue up 20+ attacks in a a single frame...
        speechTicks = 0,                        -- Cows: Tracks the ticks between speech text... ticks are inconsistent, but there are currently no other short duration timers.
        aimTarget = "",                         -- Cows: Used to identify the object the NPC is to aim at... but Java API has a "NPCSetAiming()" call which is confusing...
        canAttack = true,                       -- Cows: Added to prevent NPCs from taking attacking actions; Java API has a "NPCSetAttack()" call which is confusing; as it appears to force the NPC to attack.
        canSaveData = true,                     -- WIP - Cows: Added this flag to determine if NPC can be saved via data management.
        textObject = nil,                       -- Cows: This should handle all the text displayed by the NPC.
        ------ IsoPlayer Spawning Related below ------
        isAlive = true,                         -- WIP - Technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
        isSpawned = true,                       -- WIP - Technically part of IsoPlayer... but "isExistInTheWorld()" seems very inconsistent...
        forename = "",                          -- Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
        surname = "",                           -- Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
        isFemale = false,                       -- Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
        squareX = nil,                          -- Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
        squareY = nil,                          -- Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
        squareZ = nil,                          -- Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
        npcIsoPlayerObject = npcIsoPlayerObject -- Cows: objects cannot be saved to moddata...
    };

    setmetatable(npcSurvivor, self);
    self.__index = self;

    return npcSurvivor;
end

---Assigns groupID to NPC
---@param groupID groupID
function NPC:setGroupID(groupID)
    self.groupID = groupID
end

---Unassign groupID from NPC
function NPC:unsetGroupID()
    self.groupID = nil
end

---comments
---@param mpPlayerID integer
function NPC:setPlayerNum(mpPlayerID)
    local requestedIsoPlayer = getSpecificPlayer(mpPlayerID)
    assert(requestedIsoPlayer, "Can't find specific player, num: " .. tostring(mpPlayerID))
    local msg = string.format("IsoPlayer for mpPlayerID: %s does not match npcIsoPlayerObject. survivorID: %s",
        mpPlayerID, self.survivorID)
    assert(requestedIsoPlayer == self.npcIsoPlayerObject, msg)
    self.mpPlayerID = mpPlayerID
end

--region relations

---Change relation with `otherSurvivorID` by `diff`
---@param otherSurvivorID survivorID survivor to change relation to
---@param diff integer change amount
---@return boolean isNewRelation whether this relation is new (first meet)
function NPC:changeRelation(otherSurvivorID, diff)
    --TODO: periodic(?) cleanings for nil NPC (dead etc)
    local relation = self.relationsMap[otherSurvivorID]
    local isNewRelation = false
    local newRelation
    if not relation then
        local anonOffset = self.anonymousMap[otherSurvivorID] or 0
        relation = self.initialRelation + anonOffset
        isNewRelation = true
        self.anonymousMap[otherSurvivorID] = nil
    end
    newRelation = relation + diff
    newRelation = math.min(self._maxRelation, math.max(self._minRelation, newRelation))
    self.relationsMap[otherSurvivorID] = newRelation
    return isNewRelation
end

---Change anonymous relation with `otherSurvivorID` by `diff`
---@param otherSurvivorID any
---@param diff integer
---@return boolean isNewRelation whether this anon relation is new (first seen)
function NPC:changeAnonRelation(otherSurvivorID, diff)
    local relation = self.anonymousMap[otherSurvivorID]
    local newRelation
    local isNewRelation = false
    if not relation then
        relation = self.initialRelation
        isNewRelation = true
    end
    newRelation = relation + diff
    newRelation = math.min(self._maxRelation, math.max(self._minRelation, newRelation))
    self.anonymousMap[otherSurvivorID] = newRelation
    return isNewRelation
end

---Get relation to `otherSurvivorID`
---@param otherSurvivorID survivorID
---@return integer?
function NPC:getRelationTo(otherSurvivorID)
    return self.relationsMap[otherSurvivorID]
end

---Get anonymous relation to `otherSurvivorID`
---@param otherSurvivorID survivorID
---@return integer?
function NPC:getAnonRelationTo(otherSurvivorID)
    return self.anonymousMap[otherSurvivorID]
end

--endregion

return NPC
