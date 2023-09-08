require("00_references/init")

---@class PZNS_NPCSurvivor
---@field survivorID survivorID               Unique identifier for this NPC
---@field mpPlayerID integer?                 playerNum if `isPlayer=true`
---@field groupID groupID?                    Unique identifier of the group this NPC belongs to, if any
---@field factionID factionID?                Unique identifier of the faction this NPC belongs to, if any
---@field survivorName string                 NPC name
---@field survivorNickname string?            NPC nickname
---@field affection integer                   WIP - Cows: Added this value as a check for invite-able NPCs... between 0 and 100? 0 Means 100% hostility and will attack. (deprecated)
---@field isPlayer boolean                    Indicates whether this survivor is human player or NPC (for job/textObject update purposes)
---@field isForcedMoving boolean              Cows: Added this flag to force NPCs to move and disengage from combat/other actions.
---@field isHoldingInPlace boolean            Cows: Prevent current NPC from moving if true
---@field isMeleeOnly boolean                 WIP - Cows: Will eventually be used in more complex combat AI.
---@field isRaider boolean                    WIP - Cows: Used to test raiding NPCs
---@field isSavedInWorld boolean              Cows: Added so that NPC can be checked and saved when it is off-screen.
---@field courage integer                     WIP - Cows: Considered for evaluating when NPCs should "flee" from hostility
---@field jobName string                      Current job of this NPC; Cows: Defaults to a job managed by PZNS
---@field jobSquare IsoGridSquare?            Cows: The square at which the NPC do its job (pickup item, chop tree, etc.)
---@field isJobRefreshed boolean              Cows: This is a flag to check for NPCs to "refresh" their job status.
---@field currentAction string                Cows: This is a value to check for NPCs to queue or not queue up more actions.
---@field isStuckTicks integer                Cows: Used check if NPC is "stuck" or doing nothing even though it has a job.
---@field moveTicks integer                   Cows: Used to track how long the NPC is moving about. Added to determine how often to update pathing.
---@field jobTicks integer                    Cows: Used to track how often NPCs updates their job routine. This was added because actionTicks is intended for actions only.
---@field followTargetID survivorID           Cows: Used to follow a specified object managed by PZNS IDs
---@field speechTable table?                  Cows: Used when adding speech table(s), if nil, NPCs should use PresetsSpeeches instead.
---@field lastEquippedMeleeWeapon HandWeapon? WIP - Cows: Added so that NPCs can resume using this melee weapon after completing an action.
---@field lastEquippedRangeWeapon HandWeapon? WIP - Cows: Added so that NPCs can resume using this range weapon after completing an action.
---@field idleTicks integer                   Cows: Used to track how long an NPC is idle for before they take some general AI stuff.
---@field actionTicks integer                 Cows: This is a value used to determine the frequency of an action being called, most notably with multi-stage actions (such as reloading).
---@field attackTicks integer                 Cows: I thought it was stupid at first, but after observing an NPC queue up 20+ attacks in a a single frame...
---@field speechTicks integer                 Cows: Tracks the ticks between speech text... ticks are inconsistent, but there are currently no other short duration timers.
---@field aimTarget IsoGameCharacter?         Cows: Used to identify the object the NPC is to aim at... but Java API has a "NPCSetAiming()" call which is confusing...
---@field canAttack boolean                   Cows: Added to prevent NPCs from taking attacking actions; Java API has a "NPCSetAttack()" call which is confusing; as it appears to force the NPC to attack.
---@field canSaveData boolean                 WIP - Cows: Added this flag to determine if NPC can be saved via data management.
---@field textObject TextDrawObject?          Cows: This should handle all the text displayed by the NPC. Not used if `isPlayer=true`
---Relations
---@field relationsMap table<survivorID, integer?>  To represent relations of this NPC to other NPCs
---@field initialRelation integer                   From this NPC to all others (e.g misanthrope will have negative bias by default)
---@field _minRelation integer                      Minimum possible relation
---@field _maxRelation integer                      Maximum possible relation
---@field anonymousMap table<survivorID, integer?>  To represent seen-but-unknown NPCs and relation offset to them (applied when first met i.e moved to relationsMap)
---IsoPlayer Spawning Related fields
---@field isAlive boolean               WIP - Technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
---@field isSpawned boolean             WIP - Technically part of IsoPlayer... but "isExistInTheWorld()" seems very inconsistent...
---@field forename string               Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
---@field surname string                Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
---@field isFemale boolean              Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
---@field squareX integer?              Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
---@field squareY integer?              Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
---@field squareZ integer?              Cows: Placeholder; technically part of IsoPlayer; used when PZNS needs to use it before IsoPlayer is loaded.
---@field npcIsoPlayerObject IsoPlayer  Cows: objects cannot be saved to moddata...
---AI
---@field AIDefaultUpdateRate integer Initial update rate for NPC AI in milliseconds
---@field AIUpdateRate integer        Update rate for NPC AI in milliseconds
---@field AIScheduleName string       Name of scheduled AI update task for this NPC
local PZNS_NPCSurvivor = {}

--- Cows: Construct the PZNS_NPCSurvivor.
---@param survivorID survivorID         -- Cows: Unique Identifier for the current NPC
---@param survivorName any              -- Cows: Current NPC's name
---@param npcIsoPlayerObject IsoPlayer  -- Cows: The actual IsoPlayer object the current NPC is spawned in as. NPCUtils will mostly interact with this object.
---@return table
function PZNS_NPCSurvivor:new(
    survivorID,
    survivorName,
    npcIsoPlayerObject
)
    local npcSurvivor = {
        ----- IDs -----
        survivorID = survivorID,
        mpPlayerID = nil,
        groupID = nil,
        factionID = nil,
        ----- Main data -----
        survivorName = survivorName,
        survivorNickname = nil,
        isPlayer = false,
        isForcedMoving = false,
        isHoldingInPlace = false,
        isMeleeOnly = false,
        isRaider = false,
        isSavedInWorld = false,
        courage = 50,
        jobName = "Guard",
        jobSquare = nil,
        isJobRefreshed = false,
        currentAction = "",
        followTargetID = "",
        speechTable = nil,
        lastEquippedMeleeWeapon = nil,
        lastEquippedRangeWeapon = nil,
        idleTicks = 0,
        isStuckTicks = 0,
        moveTicks = 0,
        jobTicks = 0,
        actionTicks = 0,
        attackTicks = 0,
        speechTicks = 0,
        aimTarget = "",
        canAttack = true,
        canSaveData = true,
        textObject = nil,
        ----- Relations -----
        relationsMap = {},
        initialRelation = 0,
        _minRelation = 0,
        _maxRelation = 50,
        anonymousMap = {},
        affection = 50,
        ------ IsoPlayer Spawning Related below ------
        isAlive = true,
        isSpawned = true,
        forename = "",
        surname = "",
        isFemale = false,
        squareX = nil,
        squareY = nil,
        squareZ = nil,
        npcIsoPlayerObject = npcIsoPlayerObject,
        --- AI ---
        AIDefaultUpdateRate = 50,
        AIUpdateRate = 50,
        AIScheduleName = nil
    };

    setmetatable(npcSurvivor, self);
    self.__index = self;

    return npcSurvivor;
end

---Assigns groupID to NPC
---@param groupID groupID?
function PZNS_NPCSurvivor:setGroupID(groupID)
    self.groupID = groupID
end

---Assigns factionID to NPC
---@param factionID factionID?
function PZNS_NPCSurvivor:setFactionID(factionID)
    self.factionID = factionID
end

---comments
---@param mpPlayerID integer
function PZNS_NPCSurvivor:setPlayerNum(mpPlayerID)
    local requestedIsoPlayer = getSpecificPlayer(mpPlayerID)
    if requestedIsoPlayer then
        print("Can't find specific player, num: " .. tostring(mpPlayerID))
        return
    end
    local msg = string.format("IsoPlayer for mpPlayerID: %s does not match npcIsoPlayerObject. survivorID: %s",
        mpPlayerID, self.survivorID)
    if requestedIsoPlayer == self.npcIsoPlayerObject then
        print(msg)
        return
    end
    self.mpPlayerID = mpPlayerID
end

--region relations

---Change relation with `otherSurvivorID` by `diff`
---@param otherSurvivorID survivorID survivor to change relation to
---@param diff integer change amount
---@return boolean isNewRelation whether this relation is new (first meet)
function PZNS_NPCSurvivor:changeRelation(otherSurvivorID, diff)
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
function PZNS_NPCSurvivor:changeAnonRelation(otherSurvivorID, diff)
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
function PZNS_NPCSurvivor:getRelationTo(otherSurvivorID)
    return self.relationsMap[otherSurvivorID]
end

---Get anonymous relation to `otherSurvivorID`
---@param otherSurvivorID survivorID
---@return integer?
function PZNS_NPCSurvivor:getAnonRelationTo(otherSurvivorID)
    return self.anonymousMap[otherSurvivorID]
end

function PZNS_NPCSurvivor:removeRelationTo(otherSurvivorID)
    self.relationsMap[otherSurvivorID] = nil
end

function PZNS_NPCSurvivor:removeAnonRelationTo(otherSurvivorID)
    self.anonymousMap[otherSurvivorID] = nil
end

--endregion

return PZNS_NPCSurvivor
