---comment
---@param npcSurvivor any
---@param targetIsoObject IsoObject?
function PZNS_AimAtTarget(npcSurvivor, targetIsoObject)
    --
    if (npcSurvivor == nil) then
        return;
    end
    npcSurvivor.aimTarget = targetIsoObject;
end
