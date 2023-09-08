local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_PresetsSpeeches = require("03_mod_core/PZNS_PresetsSpeeches");
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager");

PZNS_NPCOrdersText = {
    HoldPosition = getText("ContextMenu_PZNS_Hold_Position"),
    FollowMe = getText("ContextMenu_PZNS_Follow_Me"),
    -- AimAtMe = "Aim At Me",-- Cows: Meant for debugging
    Attack = getText("ContextMenu_PZNS_Attack_Aimed_Target"),
    AttackStop = getText("ContextMenu_PZNS_Stop_Attacking")
};
---
PZNS_NPCOrderActions = {
    HoldPosition = PZNS_HoldPosition,
    FollowMe = PZNS_Follow,
    -- AimAtMe = PZNS_AimAtPlayer, -- Cows: Meant for debugging
    Attack = PZNS_AttackTarget,
    AttackStop = PZNS_StopAttacking
};

local callbackFunction = function(npcSurvivor, orderKey, followTargetID, square)
    if not npcSurvivor then
        return
    end
    npcSurvivor.jobSquare = nil;
    -- Cows: Clear the existing queued actions for the npcSurvivor when an Order is issued.
    PZNS_UtilsNPCs.PZNS_ClearQueuedNPCActions(npcSurvivor);
    local npcIso = npcSurvivor.npcIsoPlayerObject
    npcIso:Say(npcSurvivor.forename .. ", " .. PZNS_NPCOrdersText[orderKey]);
    --
    if (orderKey == "FollowMe" or orderKey == "AimAtMe") then
        if (npcSurvivor.speechTable == nil) then
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, PZNS_PresetsSpeeches.PZNS_OrderSpeechFollow, "Friendly"
            );
        elseif (npcSurvivor.speechTable.PZNS_OrderSpeechFollow) then
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, npcSurvivor.speechTable.PZNS_OrderSpeechFollow, "Friendly"
            );
        else
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, PZNS_PresetsSpeeches.PZNS_OrderSpeechFollow, "Friendly"
            );
        end
        PZNS_NPCOrderActions[orderKey](npcSurvivor, followTargetID);
    elseif (orderKey == "HoldPosition") then
        if (npcSurvivor.speechTable == nil) then
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, PZNS_PresetsSpeeches.PZNS_OrderSpeechHoldPosition, "Friendly"
            );
        elseif (npcSurvivor.speechTable.PZNS_OrderSpeechHoldPosition) then
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, npcSurvivor.speechTable.PZNS_OrderSpeechHoldPosition, "Friendly"
            );
        else
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, PZNS_PresetsSpeeches.PZNS_OrderSpeechHoldPosition, "Friendly"
            );
        end
        PZNS_NPCOrderActions[orderKey](npcSurvivor, square);
    else
        if (npcSurvivor.speechTable == nil) then
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, PZNS_PresetsSpeeches.PZNS_OrderConfirmed, "Friendly"
            );
        elseif (npcSurvivor.speechTable.PZNS_OrderConfirmed) then
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, npcSurvivor.speechTable.PZNS_OrderConfirmed, "Friendly"
            );
        else
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, PZNS_PresetsSpeeches.PZNS_OrderConfirmed, "Friendly"
            );
        end
        PZNS_NPCOrderActions[orderKey](npcSurvivor);
    end
end

---comment
---@param parentContextMenu any
---@param orderKey any
---@param playerSurvivor PZNS_NPCSurvivor
---@param playerGroupMembers table<survivorID?>
---@param square IsoGridSquare
---@return any
local function PZNS_CreateGroupNPCsSubMenu(parentContextMenu, orderKey, playerSurvivor, playerGroupMembers, square)
    local activeNPCs = PZNS.Core.NPC.registry
    -- Cows: Stop if the square isn't in a loaded visible square or there are no active npcs.
    if (square == nil or activeNPCs == nil) then
        return;
    end
    --
    for i = 1, #playerGroupMembers do
        local npcSurvivor = activeNPCs[playerGroupMembers[i]];
        -- Cows: Conditionally set the callback function for the context menu option.
        --
        if (PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) == true) then
            local isNPCSquareLoaded = PZNS_UtilsNPCs.PZNS_GetIsNPCSquareLoaded(npcSurvivor);
            if (isNPCSquareLoaded == true) then
                parentContextMenu:addOption(
                    npcSurvivor.survivorName,
                    npcSurvivor,
                    callbackFunction,
                    orderKey,
                    playerSurvivor.survivorID,
                    square
                );
            end
        end
    end -- Cows: End groupMembers for-loop

    return parentContextMenu;
end

---comment
---@param context any
---@param worldobjects any
---@param playerSurvivor PZNS_NPCSurvivor
function PZNS.Context.OrdersOptions(context, worldobjects, playerSurvivor, square)
    local orderSubMenu = context:getNew(context);
    local orderSubMenu_Option = context:addOption(
        getText("ContextMenu_PZNS_PZNS_Orders"),
        worldobjects,
        nil
    );
    context:addSubMenu(orderSubMenu_Option, orderSubMenu);
    --
    local playerGroupID = playerSurvivor.groupID
    local groupMembers
    if playerGroupID then
        groupMembers = PZNS_NPCGroupsManager.getMembers(playerGroupID)
    end
    if not groupMembers then return end
    --
    for orderKey, orderText in pairs(PZNS_NPCOrdersText) do
        local orderAction = orderSubMenu:getNew(context);
        local orderAction_Option = orderSubMenu:addOption(
            orderText,
            worldobjects,
            nil
        );
        local npcsSubMenu = orderAction:getNew(context);
        PZNS_CreateGroupNPCsSubMenu(npcsSubMenu, orderKey, playerSurvivor, groupMembers, square);
        --
        orderSubMenu:addSubMenu(orderAction_Option, orderAction);
        orderAction:addSubMenu(orderAction_Option, npcsSubMenu);
    end
end
