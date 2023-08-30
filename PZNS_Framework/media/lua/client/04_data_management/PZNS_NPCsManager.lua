require("00_references/init")
require("03_mod_core/init")

local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local NPC = require("03_mod_core/PZNS_NPCSurvivor")

PZNS_ActiveInventoryNPC = {}; -- WIP - Cows: Need to rethink how Global variables are used...

local PZNS_NPCsManager = {};

local fmt = string.format

---for easier access locally
---@param survivorID survivorID?
---@return NPC?
local function get(survivorID)
    return PZNS.Core.NPC.registry[survivorID]
end

local function verifyNPC(npc, id)
    assert(npc, fmt("NPC not found! ID: %s", id))
end

---@param survivorID survivorID
---@return NPC?
function PZNS_NPCsManager.getNPC(survivorID)
    return get(survivorID)
end

---@return Group|nil
local function getGroup(groupID)
    return PZNS.Core.Group.registry[groupID]
end

---Try to find NPC from registry by its isoObject
---@param isoPlayer IsoPlayer
---@return NPC?
function PZNS_NPCsManager.findNPCByIsoObject(isoPlayer)
    for _, npc in pairs(PZNS.Core.NPC.registry) do
        if npc.npcIsoPlayerObject == isoPlayer then
            return npc
        end
    end
end

local function createIsoPlayer(square, isFemale, surname, forename, survivorID)
    local squareZ = 0;
    -- Cows: It turns out this check is needed, otherwise NPCs may spawn in the air and fall...
    if (square:isSolidFloor()) then
        squareZ = square:getZ();
    end
    --
    local survivorDescObject = PZNS_UtilsDataNPCs.PZNS_CreateNPCSurvivorDescObject(isFemale, surname, forename);
    local npcIsoPlayerObject = IsoPlayer.new(
        getWorld():getCell(),
        survivorDescObject,
        square:getX(),
        square:getY(),
        squareZ
    );
    --
    npcIsoPlayerObject:getModData().survivorID = survivorID;
    --
    npcIsoPlayerObject:setForname(forename); -- Cows: In case forename wasn't set...
    npcIsoPlayerObject:setSurname(surname);  -- Cows: Apparently the surname set at survivorDesc isn't automatically set to IsoPlayer...
    npcIsoPlayerObject:setNPC(true);
    npcIsoPlayerObject:setSceneCulled(false);
    return npcIsoPlayerObject, squareZ
end

--- Cows: The PZNS_NPCSurvivor uses the IsoPlayer from the base game as one of its properties.
--- Best to think of the other properties of PZNS_NPCSurvivor as extended properties for PZNS.
---@param survivorID survivorID -- Cows: Need a way to guarantee this is unique...
---@param isFemale boolean
---@param surname string
---@param forename string
---@param square IsoGridSquare
---@param isoPlayer IsoPlayer? if passed - skip IsoPlayer creation
---@return NPC
function PZNS_NPCsManager.createNPCSurvivor(
    survivorID,
    isFemale,
    surname,
    forename,
    square,
    isoPlayer
)
    -- Cows: Check if the survivorID is present before proceeding.
    if (survivorID == nil) then
        error("survivorID not set")
    end
    local npcSurvivor = nil;
    -- Cows: Now add the npcSurvivor to the PZNS_NPCsManager if the ID does not exist.
    local npc = get(survivorID)
    if (not npc) then
        local survivorName = forename .. " " .. surname; -- Cows: in case getName() functions break down or can't be used...
        --
        local squareZ = 0
        local addTextObject = true
        if not isoPlayer then
            isoPlayer, squareZ = createIsoPlayer(square, isFemale, surname, forename, survivorID)
        else
            addTextObject = false
            squareZ = isoPlayer:getSquare()
            if squareZ then
                squareZ = squareZ:getZ()
            else
                error("Could not get isoPlayer square")
            end
        end

        ---@type NPC
        npcSurvivor = NPC:new(
            survivorID,
            survivorName,
            isoPlayer
        );
        npcSurvivor.isFemale = isFemale;
        npcSurvivor.forename = forename;
        npcSurvivor.surname = surname;
        npcSurvivor.squareX = square:getX();
        npcSurvivor.squareY = square:getY();
        npcSurvivor.squareZ = squareZ;
        if addTextObject then
            npcSurvivor.textObject = TextDrawObject.new();
            npcSurvivor.textObject:setAllowAnyImage(true);
            npcSurvivor.textObject:setDefaultFont(UIFont.Small);
            npcSurvivor.textObject:setDefaultColors(255, 255, 255);
            npcSurvivor.textObject:ReadString(survivorName);
        end
    else
        -- WIP - Cows: Alert player the ID is already used and the NPC cannot be created.
        npcSurvivor = npc
        assert(isoPlayer, "IsoPlayer missing, can't create NPC")
        npcSurvivor.npcIsoPlayerObject = isoPlayer
    end
    return npcSurvivor;
end

---Set NPC group ID to groupID
---@param survivorID survivorID
---@param groupID groupID
function PZNS_NPCsManager.setGroupID(survivorID, groupID)
    local npc = get(survivorID)
    verifyNPC(npc, survivorID)
    local group = getGroup(groupID)
    assert(group, fmt("Group not found! ID: %s", groupID))
    if not npc or not group then return end
    NPC.setGroupID(npc, group.groupID)
end

---Set NPC group ID to nil
---@param survivorID survivorID
function PZNS_NPCsManager.unsetGroupID(survivorID)
    local npc = get(survivorID)
    verifyNPC(npc, survivorID)
    if not npc then return end
    NPC.unsetGroupID(npc)
end

--region relations
---@alias _getRelationToParam {npc?:NPC,id?:survivorID}
---if input is safe (survivors guaranteed to exist), set checks=false to avoid extra checks
---@alias _getRelArgs {first:_getRelationToParam, second:_getRelationToParam, checks:boolean}
---@alias _changeRelArgs {first:_getRelationToParam, second:_getRelationToParam, diff:integer, checks:boolean}

---Get true if `first` knows `second`
---@param args _getRelArgs
---@return boolean
function PZNS_NPCsManager.isNPCKnowsOther(args)
    local first = args.first
    local second = args.second
    local npcFirst = first.npc or get(first.id)
    local npcSecond = second.npc or get(second.id)
    if args.checks then
        if first.id then verifyNPC(npcFirst, first.id) end
        if second.id then verifyNPC(npcSecond, second.id) end
    end
    if not npcFirst or not npcSecond then error("Can't proceed") end

    return NPC.getRelationTo(npcFirst, npcSecond.survivorID) ~= nil
end

---Get true if `first` seen `second`
---@param args _getRelArgs
---@return boolean
function PZNS_NPCsManager.isNPCSeenOther(args)
    local first = args.first
    local second = args.second
    local npcFirst = first.npc or get(first.id)
    local npcSecond = second.npc or get(second.id)
    if args.checks then
        if first.id then verifyNPC(npcFirst, first.id) end
        if second.id then verifyNPC(npcSecond, second.id) end
    end
    if not npcFirst or not npcSecond then error("Can't proceed") end

    return NPC.getAnonRelationTo(npcFirst, npcSecond.survivorID) ~= nil
end

---Change opinion of `firstSurvivorID` to `secondSurvivorID` by `diff`
---@param args _changeRelArgs
---@return boolean? firstMet
function PZNS_NPCsManager.changeRelationBetween(args)
    local first = args.first
    local second = args.second
    local npcFirst = first.npc or get(first.id)
    local npcSecond = second.npc or get(second.id)
    if args.checks then
        if first.id then verifyNPC(npcFirst, first.id) end
        if second.id then verifyNPC(npcSecond, second.id) end
        assert(type(args.diff) == "number", fmt("Invalid diff: %s (%s)", args.diff, type(args.diff)))
    end
    if not npcFirst or not npcSecond then error("Can't proceed") end

    return NPC.changeRelation(npcFirst, npcSecond.survivorID, args.diff)
end

---Change anonymous opinion of `firstSurvivorID` to `secondSurvivorID` by `diff`
---Anonymous relation means `firstSurvivorID` haven't met `secondSurvivorID` yet (does not know name/group etc)
---@param args _changeRelArgs
---@return boolean? firstSeen
function PZNS_NPCsManager.changeAnonymousRelationBetween(args)
    local first = args.first
    local second = args.second
    local npcFirst = first.npc or get(first.id)
    local npcSecond = second.npc or get(second.id)
    if args.checks then
        if first.id then verifyNPC(npcFirst, first.id) end
        if second.id then verifyNPC(npcSecond, second.id) end
        assert(type(args.diff) == "number", fmt("Invalid diff: %s (%s)", args.diff, type(args.diff)))
    end
    if not npcFirst or not npcSecond then error("Can't proceed") end
    assert(not NPC.getRelationTo(npcFirst, npcSecond.survivorID),
        fmt("NPCs already met! ID1: %s; ID2: %s", npcFirst.survivorID, npcSecond.survivorID))

    return NPC.changeAnonRelation(npcFirst, npcSecond.survivorID, args.diff)
end

---Get opinion of `firstSurvivorID` to `secondSurvivorID`
---@param args _getRelArgs
---@return integer? relation
function PZNS_NPCsManager.getRelationTo(args)
    local first = args.first
    local second = args.second
    local npcFirst = first.npc or get(first.id)
    local npcSecond = second.npc or get(second.id)
    if args.checks then
        if first.id then verifyNPC(npcFirst, first.id) end
        if second.id then verifyNPC(npcSecond, second.id) end
    end
    if not npcFirst or not npcSecond then error("Can't proceed") end
    return NPC.getRelationTo(npcFirst, npcSecond.survivorID)
end

---Get anonymous opinion of `firstSurvivorID` to `secondSurvivorID`
---@param args _getRelArgs
---@return integer? relation
function PZNS_NPCsManager.getAnonRelationTo(args)
    local first = args.first
    local second = args.second
    local npcFirst = first.npc or get(first.id)
    local npcSecond = second.npc or get(second.id)
    if args.checks then
        if first.id then verifyNPC(npcFirst, first.id) end
        if second.id then verifyNPC(npcSecond, second.id) end
    end
    if not npcFirst or not npcSecond then error("Can't proceed") end
    return NPC.getAnonRelationTo(npcFirst, npcSecond.survivorID)
end

--endregion

---Cows: Get a npcSurvivor by specified survivorID
---@param survivorID any
---@return any
function PZNS_NPCsManager.getActiveNPCBySurvivorID(survivorID)
    local activeNPCs = PZNS.Core.NPC.registry
    if (activeNPCs[survivorID] ~= nil) then
        return activeNPCs[survivorID];
    end
    return nil;
end

---Cows: Delete a npcSurvivor by specified survivorID
---@param survivorID any
function PZNS_NPCsManager.deleteActiveNPCBySurvivorID(survivorID)
    local activeNPCs = PZNS.Core.NPC.registry
    local npcSurvivor = activeNPCs[survivorID];
    -- Cows: Check if npcSurvivor exists
    if (npcSurvivor ~= nil) and npcSurvivor.isPlayer == false then
        local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject;
        -- Cows Check if IsoPlayer object exists.
        if (npcIsoPlayer ~= nil) then
            -- Cows: Remove the IsoPlayer from the world then nil the table key-value data.
            npcIsoPlayer:removeFromSquare();
            npcIsoPlayer:removeFromWorld();
            npcIsoPlayer:removeSaveFile(); -- Cows: Remove the IsoPlayer SaveFile? I am curious about how it tracks the save file...
        end
        activeNPCs[survivorID] = nil;
    end
end

---comment
---@param survivorID any
function PZNS_NPCsManager.setActiveInventoryNPCBySurvivorID(survivorID)
    local activeNPCs = PZNS.Core.NPC.registry
    local npcSurvivor = activeNPCs[survivorID];
    PZNS_ActiveInventoryNPC = npcSurvivor;
end

--- WIP - Cows: Spawn a random raider NPC.
--- Cows: Go make your own random spawns, this is an example for debugging and testing.
---@param targetSquare IsoGridSquare
---@param raiderID survivorID?
---@return unknown
function PZNS_NPCsManager.spawnRandomRaiderSurvivorAtSquare(targetSquare, raiderID)
    local isFemale = ZombRand(100) > 50; -- Cows: 50/50 roll for female spawn
    local raiderForeName = SurvivorFactory.getRandomForename(isFemale);
    local raiderSurname = SurvivorFactory.getRandomSurname();
    local raiderName = raiderForeName .. " " .. raiderSurname;
    local gameTimeStampString = tostring(getTimestampMs());
    -- Cows: I recommend replacing the "PZNS_Raider_" prefix if another modder wants to create their own random spawns. As long as the ID is unique, there shouldn't be a problem
    local raiderSurvivorID = "PZNS_Raider_" .. raiderForeName .. "_" .. raiderSurname .. "_" .. gameTimeStampString;
    if (raiderID ~= nil) then
        raiderSurvivorID = raiderID;
    end
    --
    local raiderSurvivor = PZNS_NPCsManager.createNPCSurvivor(
        raiderSurvivorID,
        isFemale,
        raiderSurname,
        raiderForeName,
        targetSquare
    );
    raiderSurvivor.isRaider = true;                             -- Cows: MAKE SURE THIS FLAG IS SET TO 'true' - DIFFERENTIATE NORMAL NPCS FROM RAIDERS.
    raiderSurvivor.affection = 0;                               -- Cows: Raiders will never hold any love for players.
    raiderSurvivor.textObject:setDefaultColors(225, 0, 0, 0.8); -- Red text
    raiderSurvivor.textObject:ReadString(raiderName);
    raiderSurvivor.canSaveData = false;
    -- Cows: Setup the skills and outfit, plus equipment...
    if not PZNS_UtilsNPCs then
        print("Can't init PZNS_UtilsNPCs for some reason...")
        PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
    end
    PZNS_UtilsNPCs.PZNS_SetNPCPerksRandomly(raiderSurvivor);
    -- Cows: Bandanas - https://pzwiki.net/wiki/Bandana#Variants / Balaclava https://pzwiki.net/wiki/Balaclava
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(raiderSurvivor, "Base.Hat_BandanaMask"); -- Cows: Bandits and Raiders always wears a mask...
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(raiderSurvivor, "Base.Shirt_HawaiianRed");
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(raiderSurvivor, "Base.Trousers_Denim");
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(raiderSurvivor, "Base.Socks");
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(raiderSurvivor, "Base.Shoes_ArmyBoots");
    local spawnWithGun = ZombRand(0, 100) > 50;
    if (spawnWithGun) then
        PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(raiderSurvivor, "Base.Pistol");
        PZNS_UtilsNPCs.PZNS_SetLoadedGun(raiderSurvivor);
        PZNS_UtilsNPCs.PZNS_AddItemToInventoryNPCSurvivor(raiderSurvivor, "Base.9mmClip");
        PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(raiderSurvivor, "Base.Bullets9mm", 15);
        PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(raiderSurvivor, "Base.Bullets9mm", 15);
    else
        PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(raiderSurvivor, "Base.BaseballBat");
    end
    -- Cows: Set the job last, otherwise the NPC will function as if it didn't have a weapon.
    raiderSurvivor.jobName = "Wander In Cell";
    local activeNPCs = PZNS.Core.NPC.registry
    activeNPCs[raiderSurvivorID] = raiderSurvivor; -- Cows: This saves it to modData, which allows the npc to run while in-game, but does not create a save file.
    return raiderSurvivor;
end

--- WIP - Cows: Spawn a random NPC.
--- Cows: Go make your own random spawns, this is an example for debugging and testing.
---@param targetSquare IsoGridSquare
---@param survivorID string?
---@param initialJob string?
---@return NPC
function PZNS_NPCsManager.spawnRandomNPCSurvivorAtSquare(targetSquare, survivorID, initialJob)
    local isFemale = ZombRand(100) > 50; -- Cows: 50/50 roll for female spawn
    local npcForeName = SurvivorFactory.getRandomForename(isFemale);
    local npcSurname = SurvivorFactory.getRandomSurname();
    local gameTimeStampString = tostring(getTimestampMs());
    -- Cows: I recommend replacing the "PZNS_Survivor_" prefix if another modder wants to create their own random spawns. As long as the ID is unique, there shouldn't be a problem
    local npcSurvivorID = "PZNS_Survivor_" .. npcForeName .. "_" .. npcSurname .. "_" .. gameTimeStampString;
    if (survivorID ~= nil) then
        npcSurvivorID = survivorID;
    end
    --
    local npcSurvivor = PZNS_NPCsManager.createNPCSurvivor(
        npcSurvivorID,
        isFemale,
        npcSurname,
        npcForeName,
        targetSquare
    );
    npcSurvivor.affection = ZombRand(100); -- Cows: Random between 0 and 100 affection, not everyone will love the player.
    npcSurvivor.canSaveData = false;
    -- Cows: Setup the skills and outfit, plus equipment...
    PZNS_UtilsNPCs.PZNS_SetNPCPerksRandomly(npcSurvivor);
    --
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Tshirt_WhiteTINT");
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Trousers_Denim");
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Socks");
    PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Shoes");
    local spawnWithGun = ZombRand(0, 100) > 50;
    if (spawnWithGun) then
        PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, "Base.Pistol");
        PZNS_UtilsNPCs.PZNS_SetLoadedGun(npcSurvivor);
        PZNS_UtilsNPCs.PZNS_AddItemToInventoryNPCSurvivor(npcSurvivor, "Base.9mmClip");
        PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(npcSurvivor, "Base.Bullets9mm", 15);
        PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(npcSurvivor, "Base.Bullets9mm", 15);
    else
        PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, "Base.BaseballBat");
    end
    -- Cows: Set the job last, otherwise the NPC will function as if it didn't have a weapon.
    initialJob = initialJob == nil and "Wander In Cell" or initialJob
    npcSurvivor.jobName = initialJob
    local activeNPCs = PZNS.Core.NPC.registry
    activeNPCs[npcSurvivorID] = npcSurvivor; -- Cows: This saves it to modData, which allows the npc to run while in-game, but does not create a save file.
    return npcSurvivor;
end

return PZNS_NPCsManager;
