local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_PresetsSpeeches = require("03_mod_core/PZNS_PresetsSpeeches");
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager");


---@param npcSurvivor NPC
---@param parentContextMenu any
---@param jobName string
---@param followTargetID survivorID
local callbackFunction = function(npcSurvivor, parentContextMenu, jobName, followTargetID)
    npcSurvivor.jobSquare = nil;
    npcSurvivor.isHoldingInPlace = false;
    if (jobName == "Companion") then
        PZNS_JobCompanion(npcSurvivor, followTargetID);
    end
    --
    if (npcSurvivor.speechTable ~= nil) then
        if (npcSurvivor.speechTable.PZNS_OrderConfirmed ~= nil) then
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, npcSurvivor.speechTable.PZNS_OrderConfirmed, "Friendly"
            );
        else
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivor, PZNS_PresetsSpeeches.PZNS_OrderConfirmed, "Friendly"
            );
        end
    else
        PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
            npcSurvivor, PZNS_PresetsSpeeches.PZNS_OrderConfirmed, "Friendly"
        );
    end
    PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, jobName);
    parentContextMenu:setVisible(false);
end

---comment
---@param parentContextMenu any
---@param jobName string
---@param playerSurvivor NPC
---@param groupMembers table<survivorID?>
---@return any
local function PZNS_CreateJobNPCsMenu(parentContextMenu, jobName, playerSurvivor, groupMembers)
    local activeNPCs = PZNS.Core.NPC.registry
    local followTargetID = playerSurvivor.survivorID
    --
    for i = 1, #groupMembers do
        local npcSurvivor = activeNPCs[groupMembers[i]];
        -- Cows: conditionally set the callback function for the context menu option.
        --
        if (PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) == true) then
            local isNPCSquareLoaded = PZNS_UtilsNPCs.PZNS_GetIsNPCSquareLoaded(npcSurvivor);
            if (isNPCSquareLoaded == true) then
                parentContextMenu:addOption(
                    npcSurvivor.survivorName,
                    npcSurvivor,
                    callbackFunction,
                    parentContextMenu,
                    jobName,
                    followTargetID
                );
            end
        end
    end -- Cows: End groupMembers for-loop

    return parentContextMenu;
end

---comment
---@param context any
---@param worldobjects any
function PZNS.Context.JobsOptions(context, worldobjects, playerSurvivor)
    local jobsSubMenu_1 = context:getNew(context);
    local jobsSubMenu_1_Option = context:addOption(
        getText("ContextMenu_PZNS_PZNS_Jobs"),
        worldobjects,
        nil
    );
    context:addSubMenu(jobsSubMenu_1_Option, jobsSubMenu_1);
    --
    local playerGroupID = playerSurvivor.groupID
    local groupMembers
    if playerGroupID then
        groupMembers = PZNS_NPCGroupsManager.getMembers(playerGroupID)
    end
    if not groupMembers then return end
    --
    for _, jobText in pairs(PZNS_JobsText) do
        local jobSubMenu_2 = jobsSubMenu_1:getNew(context);
        local jobSubMenu_2_Option = jobsSubMenu_1:addOption(
            jobText[2],
            worldobjects,
            nil
        );
        local npcSubMenu_3 = jobSubMenu_2:getNew(context);
        PZNS_CreateJobNPCsMenu(npcSubMenu_3, jobText[1], playerSurvivor, groupMembers);
        --
        jobsSubMenu_1:addSubMenu(jobSubMenu_2_Option, jobSubMenu_2);
        jobSubMenu_2:addSubMenu(jobSubMenu_2_Option, npcSubMenu_3);
    end
end
