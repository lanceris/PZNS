require("03_mod_core/init")

local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager");

local callbackFunction = function(_, npcSurvivor, playerGroupID)
    -- Cows: Remove the npcSurvivor from its original group if it was in a group
    if (npcSurvivor.groupID ~= nil) then
        PZNS_NPCGroupsManager.removeNPCFromGroupBySurvivorID(
            npcSurvivor.groupID, npcSurvivor.survivorID
        );
    end
    npcSurvivor.canSaveData = true; -- Cows: This will allow the NPC to be saved.
    PZNS_NPCSpeak(npcSurvivor, "Glad to be in your group!", "Positive")
    PZNS_NPCGroupsManager.addNPCToGroup(npcSurvivor, playerGroupID)
    PZNS_UtilsDataNPCs.PZNS_SaveNPCData(npcSurvivor.survivorID, npcSurvivor);
end

---comment
---@param context any
---@param worldobjects any
---@param playerSurvivor PZNS_NPCSurvivor
---@param square IsoGridSquare Clicked on cell
function PZNS.Context.InviteOptions(context, worldobjects, playerSurvivor, square)
    local invitableCount = 0;
    --
    local squareObjects = square:getMovingObjects();
    local objectsListSize = squareObjects:size() - 1;
    --
    local inviteSubMenu = context:getNew(context);
    --
    for i = 0, objectsListSize do
        local currentObj = squareObjects:get(i);
        local canInvite = false;
        --
        if (instanceof(currentObj, "IsoPlayer") == true) then
            -- Cows: Check and make sure it is NOT the current player and is alive
            if (currentObj ~= playerSurvivor.npcIsoPlayerObject and currentObj:isAlive() == true) then
                local npcSurvivor = PZNS_NPCsManager.getActiveNPCBySurvivorID(currentObj:getModData().survivorID);
                if not npcSurvivor then return end
                -- Cows: Check if the npc is not a raider, raiders cannot be invited
                if (npcSurvivor.isRaider ~= true) then
                    --  Cows: Survivor affection must be above a set value to be invited
                    if (npcSurvivor.affection > 30) then
                        -- Cows: Ungrouped NPC
                        -- if player not in group - where to invite to?
                        if playerSurvivor and playerSurvivor.groupID then
                            if (npcSurvivor.groupID == nil) then
                                invitableCount = invitableCount + 1;
                                canInvite = true;
                            elseif (npcSurvivor.groupID ~= playerSurvivor.groupID) then
                                -- Cows: Else different grouped NPCs
                                invitableCount = invitableCount + 1;
                                canInvite = true;
                            end
                        end
                    end
                end
                -- Cows: Check if current NPC is invitable.
                if (canInvite == true) then
                    if playerSurvivor and playerSurvivor.groupID then
                        inviteSubMenu:addOption(
                            npcSurvivor.survivorName,
                            nil,
                            callbackFunction,
                            npcSurvivor,
                            playerSurvivor.groupID
                        );
                    end
                end
            end
        end
    end
    -- Cows: Check if there are more than 0 invitable NPCs.
    if (invitableCount > 0) then
        local inviteSubMenu_Option = context:addOption(
            getText("ContextMenu_PZNS_PZNS_Invite"),
            worldobjects,
            nil
        );
        context:addSubMenu(inviteSubMenu_Option, inviteSubMenu);
    else
        inviteSubMenu = nil;
    end
end
