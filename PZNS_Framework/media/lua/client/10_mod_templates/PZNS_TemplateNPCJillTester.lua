local PZNS_DebuggerUtils = require("02_mod_utils/PZNS_DebuggerUtils");
local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_PlayerUtils = require("02_mod_utils/PZNS_PlayerUtils")
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager");
local PZNS_SpeechTableJill = require("10_mod_templates/PZNS_SpeechTableJill");

local npcSurvivorID = "PZNS_JillTester";

--- Cows: mpPlayerID is merely a placeholder... PZ has issues as of B41 with NPCs/non-players in a MP environment.
--- Cows: Example of spawning in an NPC. This Npc is "Jill Tester"
---@param addToPlayerGroup? boolean if true - try to add NPC to player group (if exist) by default true
function PZNS_SpawnJillTester(mpPlayerID, square, addToPlayerGroup)
    addToPlayerGroup = addToPlayerGroup == nil and true or addToPlayerGroup
    local npcSurvivor = PZNS_NPCsManager.getNPC(npcSurvivorID)
    --
    local playerNPC = PZNS_PlayerUtils.getPlayerNPC(mpPlayerID)
    local playerGroup
    if playerNPC then
        local playerSurvivor = playerNPC.npcIsoPlayerObject
        square = square or playerSurvivor:getSquare()
        playerGroup = PZNS_NPCGroupsManager.getGroupByID(playerNPC.groupID)
    end
    if not square then return end
    -- Cows: Check if the NPC is active before continuing.
    if (npcSurvivor == nil) then
        npcSurvivor = PZNS_NPCsManager.createNPCSurvivor(
            npcSurvivorID, -- Unique Identifier for the npcSurvivor so that it can be managed.
            true,          -- isFemale
            "Tester",      -- Surname
            "Jill",        -- Forename
            square         -- Square to spawn at
        );
        --
        if (npcSurvivor ~= nil) then
            PZNS_UtilsNPCs.PZNS_SetNPCSpeechTable(npcSurvivor, PZNS_SpeechTableJill);
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Strength", 5);
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Fitness", 5);
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Aiming", 5);
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorPerkLevel(npcSurvivor, "Reloading", 5);
            PZNS_UtilsNPCs.PZNS_AddNPCSurvivorTraits(npcSurvivor, "Lucky");
            -- Cows: Setup npcSurvivor outfit... Example mod patcher check
            -- "jill" is a costume mod created/uploaded by "Satispie" at https://steamcommunity.com/sharedfiles/filedetails/?id=2903870282
            if (PZNS_DebuggerUtils.PZNS_IsModActive("jill") == true) then
                PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.jill");
            else
                -- Cows: Else use vanilla assets
                PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Vest_DefaultTEXTURE");
                PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Skirt_Mini");
                PZNS_UtilsNPCs.PZNS_AddEquipClothingNPCSurvivor(npcSurvivor, "Base.Shoes_ArmyBoots");
                PZNS_UtilsNPCs.PZNS_AddItemToInventoryNPCSurvivor(npcSurvivor, "Base.BaseballBat");
            end
            PZNS_UtilsNPCs.PZNS_AddEquipWeaponNPCSurvivor(npcSurvivor, "Base.Pistol");
            PZNS_UtilsNPCs.PZNS_SetLoadedGun(npcSurvivor);
            PZNS_UtilsNPCs.PZNS_AddItemToInventoryNPCSurvivor(npcSurvivor, "Base.9mmClip");
            PZNS_UtilsNPCs.PZNS_AddItemsToInventoryNPCSurvivor(npcSurvivor, "Base.Bullets9mm", 15);
            -- Cows: Set the job...
            PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, "Companion");
            if playerNPC then
                PZNS_UtilsNPCs.PZNS_SetNPCFollowTargetID(npcSurvivor, playerNPC.survivorID);
            end
            -- Cows: Begin styling customizations...
            PZNS_UtilsNPCs.PZNS_SetNPCHairModel(npcSurvivor, "Bob");
            PZNS_UtilsNPCs.PZNS_SetNPCHairColor(npcSurvivor, 0.720, 0.451, 0.230);
            PZNS_UtilsNPCs.PZNS_SetNPCSkinTextureIndex(npcSurvivor, 1);
            PZNS_UtilsNPCs.PZNS_SetNPCSkinColor(npcSurvivor, 0.970, 0.934, 0.873);
            -- Cows: Group Assignment
            if addToPlayerGroup and playerGroup then
                PZNS_NPCGroupsManager.addNPCToGroup(npcSurvivor, playerGroup.groupID);
            end

            PZNS_UtilsDataNPCs.PZNS_SaveNPCData(npcSurvivorID, npcSurvivor);
        end
    end
end

-- Cows: NPC Cleanup function...
function PZNS_DeleteJillTester()
    local npcSurvivor = PZNS_NPCsManager.getActiveNPCBySurvivorID(npcSurvivorID);
    if not npcSurvivor then return end
    PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor);
    if npcSurvivor.groupID then
        PZNS_NPCGroupsManager.removeNPCFromGroupBySurvivorID(npcSurvivor.groupID, npcSurvivorID); -- Cows: REMOVE THE NPC FROM THEIR GROUP BEFORE DELETING THEM! OTHERWISE IT'S A NIL REFERENCE
    end
    PZNS_NPCsManager.deleteActiveNPCBySurvivorID(npcSurvivorID);
end

--- Cows: Automatically Re-set the custom npc speech table, this is to ensure the custom npc always uses the latest speech table if an update occurs.
function PZNS_ResetJillTesterSpeechTable()
    local npcSurvivor = PZNS_NPCsManager.getActiveNPCBySurvivorID(npcSurvivorID);
    if (npcSurvivor ~= nil) then
        PZNS_UtilsNPCs.PZNS_SetNPCSpeechTable(npcSurvivor, PZNS_SpeechTableJill);
    end
end
