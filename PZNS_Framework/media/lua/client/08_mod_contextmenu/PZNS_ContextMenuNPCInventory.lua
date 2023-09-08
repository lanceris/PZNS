local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils");
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager");

---Cows: Checks the distance between the playerSurvivor and the npc
local function PZNS_CheckDistToNPCInventory()
    if PZNS_ActiveInventoryNPC == nil then
        return;
    end
    local playerSurvivor = getSpecificPlayer(0);
    local npcIsoPlayer = PZNS_ActiveInventoryNPC.npcIsoPlayerObject;
    -- Cows: Check and reset the PZNS_ActiveInventoryNPC if the NPC is beyond 2 squares away.
    if (npcIsoPlayer) then
        local npcDistanceFromPlayer = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(playerSurvivor, npcIsoPlayer);
        --
        if (npcDistanceFromPlayer > 2) then
            PZNS_ActiveInventoryNPC = {};
            Events.OnPlayerMove.Remove(PZNS_CheckDistToNPCInventory);
        end
    end
end

---comment
---@param mpPlayerID integer
---@param npcSurvivor PZNS_NPCSurvivor
---@return ItemContainer | nil
local function openNPCInventory(mpPlayerID, npcSurvivor)
    if (npcSurvivor == nil) then
        return;
    end
    PZNS_NPCsManager.setActiveInventoryNPCBySurvivorID(npcSurvivor.survivorID);
    -- Cows: Force reload the container window.
    ISPlayerData[mpPlayerID + 1].lootInventory:refreshBackpacks();
    Events.OnPlayerMove.Add(PZNS_CheckDistToNPCInventory);
end

--- Cows: mpPlayerID is a placeholder, it always defaults to 0 in local.
---@param context any
---@param worldobjects any
---@param playerSurvivor PZNS_NPCSurvivor
function PZNS.Context.NPCInventoryOptions(context, worldobjects, playerSurvivor)
    local inventorySubMenu_1 = context:getNew(context);
    local inventorySubMenu_1_Option = context:addOption(
        getText("ContextMenu_PZNS_PZNS_Inventory"),
        worldobjects,
        nil
    );
    context:addSubMenu(inventorySubMenu_1_Option, inventorySubMenu_1);
    --
    local playerGroupID = playerSurvivor.groupID
    local groupMembers
    local activeNPCs = PZNS.Core.NPC.registry
    if playerGroupID then
        groupMembers = PZNS_NPCGroupsManager.getMembers(playerGroupID)
    end
    --
    if (groupMembers == nil) then
        return;
    end
    for i = 1, #groupMembers do
        local npcSurvivor = activeNPCs[groupMembers[i]]
        if (PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) == true) then
            local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject;
            local npcDistanceFromPlayer = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(
                playerSurvivor.npcIsoPlayerObject, npcIsoPlayer
            );
            if (npcDistanceFromPlayer <= 2) then
                -- Cows: conditionally set the callback function for the inventorySubMenu_1 option.
                local callbackFunction = function()
                    openNPCInventory(playerSurvivor.mpPlayerID, npcSurvivor);
                end
                inventorySubMenu_1:addOption(
                    npcSurvivor.survivorName,
                    nil,
                    callbackFunction
                );
            end
        end
    end -- Cows: End groupMembers For-loop.
end
