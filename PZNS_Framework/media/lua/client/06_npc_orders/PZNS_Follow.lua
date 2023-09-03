local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");

---comment
---@param npcSurvivor any
---@param targetID any
function PZNS_Follow(npcSurvivor, targetID)
    --
    if (npcSurvivor == nil) then
        return;
    end
    --
    npcSurvivor.isHoldingInPlace = false;
    PZNS_UtilsNPCs.PZNS_SetNPCJob(npcSurvivor, "Companion")
    npcSurvivor.followTargetID = targetID;
    npcSurvivor.jobSquare = nil;
end
