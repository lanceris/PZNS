require("00_references/init")

function PZNS.Context.PZNS_CreateContextMenuDebug(mpPlayerID, context, worldobjects)
    if (SandboxVars.PZNS_Framework.IsDebugModeActive ~= true) then
        return
    end
    PZNS.Context.Debug.BuildOptions(mpPlayerID, context, worldobjects)
    PZNS.Context.Debug.WorldOptions(mpPlayerID, context, worldobjects)
    PZNS.Context.Debug.WipeOptions(mpPlayerID, context, worldobjects)
end

function PZNS.Context.PZNS_CreateContextMenu(mpPlayerID, context, worldobjects)
    PZNS.Context.ZonesOptions(mpPlayerID, context, worldobjects)
    PZNS.Context.JobsOptions(mpPlayerID, context, worldobjects)
    PZNS.Context.OrdersOptions(mpPlayerID, context, worldobjects)
    PZNS.Context.NPCInventoryOptions(mpPlayerID, context, worldobjects)
    PZNS.Context.NPCInfoOptions(mpPlayerID, context, worldobjects)
    PZNS.Context.SquareObjectsOptions(mpPlayerID, context, worldobjects)
    PZNS.Context.InviteOptions(mpPlayerID, context, worldobjects)
end

function PZNS.Context.PZNS_OnFillWorldObjectContextMenu(mpPlayerID, context, worldobjects)
    local opt = context:addOption(getText("Sandbox_PZNS_Framework"), worldobjects, nil)
    local PZNSMenu = ISContextMenu:getNew(context)
    context:addSubMenu(opt, PZNSMenu)

    PZNS.Context.PZNS_CreateContextMenuDebug(mpPlayerID, PZNSMenu, worldobjects)
    PZNS.Context.PZNS_CreateContextMenu(mpPlayerID, PZNSMenu, worldobjects)
end
