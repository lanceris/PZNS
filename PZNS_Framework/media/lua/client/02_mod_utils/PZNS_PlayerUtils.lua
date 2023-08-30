require("03_mod_core/init")

local PZNS_PlayerUtils = {};
local PZNS_NPCsManager --TODO: refactor, utils should not use managers
local PZNS_NPCGroupsManager
local NPC = require("03_mod_core/PZNS_NPCSurvivor")

---@return NPC
local function createLocalPlayerNPCSurvivor(playerIsoObject)
    local num = playerIsoObject:getPlayerNum()
    local survivorID = "Player" .. tostring(num)
    local isFemale = playerIsoObject:isFemale()
    local descriptor = playerIsoObject:getDescriptor()
    if not descriptor then
        error("Could not get isoPlayer descriptor")
    end
    local surname = descriptor:getSurname()
    local forename = descriptor:getForename()
    local square = playerIsoObject:getSquare()
    if not PZNS_NPCsManager then
        PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")
    end
    local npcSurvivor = PZNS_NPCsManager.createNPCSurvivor(survivorID, isFemale, surname, forename, square,
        playerIsoObject)
    npcSurvivor.isPlayer = true
    npcSurvivor.canSaveData = false
    NPC.setPlayerNum(npcSurvivor, num)
    if not npcSurvivor.npcIsoPlayerObject then
        error("Something went wrong, can't access player object")
    end
    npcSurvivor.npcIsoPlayerObject:getModData().survivorID = survivorID
    PZNS.Core.NPC.registry[survivorID] = npcSurvivor
    return npcSurvivor
end

--- Cows: Add LocalPlayer "0" to group.
---@param npcSurvivor NPC
local function createLocalPlayerGroup(npcSurvivor)
    local playerID = npcSurvivor.survivorID
    local playerGroupID = playerID .. "Group";
    local playerGroupName = npcSurvivor.survivorName .. " Group"
    if not PZNS_NPCGroupsManager then
        PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager")
    end
    ---@type Group|nil
    local playerGroup = PZNS_NPCGroupsManager.getGroupByID(playerGroupID);
    --
    if (playerGroup == nil) then
        PZNS_NPCGroupsManager.createGroup(playerGroupID, playerGroupName, playerID);
    end
end

function PZNS_PlayerUtils.initPlayer()
    local player = getPlayer()
    local npcSurvivor = createLocalPlayerNPCSurvivor(player)
    createLocalPlayerGroup(npcSurvivor)
end

---Return NPC instance of player
---@param playerNum? integer
---@return NPC|nil
function PZNS_PlayerUtils.getPlayerNPC(playerNum)
    playerNum = playerNum == nil and 0 or playerNum
    local survivorID = "Player" .. tostring(playerNum)
    if not PZNS_NPCsManager then
        PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")
    end
    return PZNS_NPCsManager.getNPC(survivorID)
end

---Get Group instance of player group
---@param playerNum? integer
---@return Group|nil
function PZNS_PlayerUtils.getPlayerGroup(playerNum)
    local playerSurvivor = PZNS_PlayerUtils.getPlayerNPC(playerNum)
    if not playerSurvivor then return end
    if not playerSurvivor.groupID then return end
    if not PZNS_NPCGroupsManager then
        PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager")
    end
    return PZNS_NPCGroupsManager.getGroupByID(playerSurvivor.groupID)
end

--- Cows: Placeholder, Apparently, all the MP player IDs in PZ Java are numbers only...
--- Cows: So this function is to ensure a set number of IDs are reserved.
--- Cows: Probably unnecessary if the mod uses it own ID tables...
---@param inputNumber number
---@param reservedNumber number
---@return boolean
function PZNS_PlayerUtils.PZNS_IsSurvivorIDReserved(inputNumber, reservedNumber)
    if (inputNumber <= reservedNumber) then
        return true;
    end
    return false;
end

--- Cows: Add a specified player to a specified group
---@param mpPlayerID number
---@param groupID any
function PZNS_PlayerUtils.PZNS_AddPlayerToGroup(mpPlayerID, groupID)
    if not PZNS_NPCGroupsManager then
        PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager")
    end
    ---@type nil|Group
    local group = PZNS_NPCGroupsManager.getGroupByID(groupID);
    local stringID = "player" .. tostring(mpPlayerID);
    --
    if (group ~= nil) then
        group:addMember(stringID)
    end
end

--- Cows: Remove the  specified player from the specified group
---@param mpPlayerID number
---@param groupID any
function PZNS_PlayerUtils.PZNS_RemovePlayerFromGroup(mpPlayerID, groupID)
    local group = PZNS_NPCGroupsManager.getGroupByID(groupID);
    local stringID = "player" .. tostring(mpPlayerID);
    --
    if (group ~= nil) then
        group[stringID] = nil;
    end
end

---comment
---@param mpPlayerID number
---@return IsoGridSquare
function PZNS_PlayerUtils.PZNS_GetPlayerCellGridSquare(mpPlayerID)
    local localPlayerID = 0;
    --
    if (mpPlayerID ~= nil) then
        localPlayerID = mpPlayerID;
    end
    local playerSurvivor = getSpecificPlayer(localPlayerID);
    --
    local gridSquare = getCell():getGridSquare(
        playerSurvivor:getX(),
        playerSurvivor:getY(),
        playerSurvivor:getZ()
    );
    return gridSquare;
end

--- Cows: Based on Superb Survivors GetMouseSquare(), the calculation seems to be off by almost 1...
---@param mpPlayerID integer
---@return IsoGridSquare
function PZNS_PlayerUtils.PZNS_GetPlayerMouseGridSquare(mpPlayerID)
    local sw = (128 / getCore():getZoom(0));
    local sh = (64 / getCore():getZoom(0));

    local playerSurvivor = getSpecificPlayer(mpPlayerID);
    local mapx = playerSurvivor:getX();
    local mapy = playerSurvivor:getY();
    local mousex = getMouseX() - (getCore():getScreenWidth() / 2);
    local mousey = getMouseY() - (getCore():getScreenHeight() / 2);

    local squareX = mapx + (mousex / (sw / 2) + mousey / (sh / 2)) / 2;
    local squareY = mapy + (mousey / (sh / 2) - (mousex / (sw / 2))) / 2;
    local squareZ = playerSurvivor:getZ();

    local square = getCell():getGridSquare(squareX, squareY, squareZ);
    return square;
end

---comment
function PZNS_PlayerUtils.PZNS_ClearPlayerAllNeeds()
    local playerSurvivor = getSpecificPlayer(0);

    playerSurvivor:getStats():setAnger(0.0);
    playerSurvivor:getStats():setBoredom(0.0);
    playerSurvivor:getStats():setDrunkenness(0.0);
    playerSurvivor:getStats():setEndurance(100.0);
    playerSurvivor:getStats():setFatigue(0.0);
    playerSurvivor:getStats():setFear(0.0);
    playerSurvivor:getStats():setHunger(0.0);
    playerSurvivor:getStats():setIdleboredom(0.0);
    playerSurvivor:getStats():setMorale(0.0);
    playerSurvivor:getStats():setPain(0.0);
    playerSurvivor:getStats():setPanic(0.0);
    playerSurvivor:getStats():setSanity(0.0);
    playerSurvivor:getStats():setSickness(0.0);
    playerSurvivor:getStats():setStress(0.0);
    playerSurvivor:getStats():setStressFromCigarettes(0.0);
    playerSurvivor:getStats():setThirst(0.0);
end

return PZNS_PlayerUtils;
