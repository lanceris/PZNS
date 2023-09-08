require("00_references/init")

local PZNS_PlayerUtils = require("02_mod_utils/PZNS_PlayerUtils")
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")

function PZNS.Context.PZNS_CreateContextMenuDebug(context, worldobjects, playerSurvivor, square)
    PZNS.Context.Debug.BuildOptions(context, worldobjects)
    PZNS.Context.Debug.WorldOptions(context, worldobjects, playerSurvivor, square)
    PZNS.Context.Debug.WipeOptions(context, worldobjects)
end

function PZNS.Context.PZNS_CreateContextMenu(context, worldobjects, playerSurvivor, square)
    PZNS.Context.ZonesOptions(context, worldobjects, playerSurvivor)
    PZNS.Context.JobsOptions(context, worldobjects, playerSurvivor)
    PZNS.Context.OrdersOptions(context, worldobjects, playerSurvivor, square)
    PZNS.Context.NPCInventoryOptions(context, worldobjects, playerSurvivor)
    PZNS.Context.NPCInfoOptions(context, worldobjects, playerSurvivor)
    PZNS.Context.SquareObjectsOptions(context, worldobjects, playerSurvivor, square)
    PZNS.Context.InviteOptions(context, worldobjects, playerSurvivor, square)
end

function PZNS.Context.PZNS_OnFillWorldObjectContextMenu(mpPlayerID, context, worldobjects)
    local opt = context:addOption(getText("Sandbox_PZNS_Framework"), worldobjects, nil)
    local PZNSMenu = ISContextMenu:getNew(context)
    context:addSubMenu(opt, PZNSMenu)

    local playerIsoObject = getSpecificPlayer(mpPlayerID)
    local playerSurvivor = PZNS_NPCsManager.findNPCByIsoObject(playerIsoObject)
    if not playerSurvivor then print("playerSurvivor not found!") end
    local clickedOnSquare = PZNS_PlayerUtils.PZNS_GetPlayerMouseGridSquare(mpPlayerID)

    if SandboxVars.PZNS_Framework.IsDebugModeActive == true then
        PZNS.Context.PZNS_CreateContextMenuDebug(PZNSMenu, worldobjects, playerSurvivor, clickedOnSquare)
    end
    PZNS.Context.PZNS_CreateContextMenu(PZNSMenu, worldobjects, playerSurvivor, clickedOnSquare)
end
