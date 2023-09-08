local PZNS_DebuggerUtils = require("02_mod_utils/PZNS_DebuggerUtils");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_PlayerUtils = require("02_mod_utils/PZNS_PlayerUtils");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager");
--
local function addFiveCannedTunasToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    for i = 1, 5 do
        playerSurvivor:getInventory():AddItem("Base.TunaTin");
    end
end

local function addTenPlanksToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    for i = 1, 10 do
        playerSurvivor:getInventory():AddItem("Base.Plank");
    end
end

local function addFiveNailsBoxesToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    for i = 1, 3 do
        playerSurvivor:getInventory():AddItem("Base.NailsBox");
    end
end

local function addFivePropanTanksToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    for i = 1, 5 do
        playerSurvivor:getInventory():AddItem("Base.PropaneTank");
    end
end

local function addMetalSheetsToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    for i = 1, 5 do
        playerSurvivor:getInventory():AddItem("Base.SheetMetal");
    end
end

local function addBigPoleFenceGate()
    local playerSurvivor = getSpecificPlayer(0);
    playerSurvivor:getInventory():AddItem("Base.WeldingRods");
    for i = 1, 5 do
        playerSurvivor:getInventory():AddItem("MetalPipe");
    end
    for i = 1, 4 do
        playerSurvivor:getInventory():AddItem("Base.ScrapMetal");
    end
    for i = 1, 2 do
        playerSurvivor:getInventory():AddItem("Base.Hinge");
    end
end
--
local function addBigWiredWallMaterialsToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    playerSurvivor:getInventory():AddItem("Base.Wire");
    for i = 1, 4 do
        playerSurvivor:getInventory():AddItem("Base.ScrapMetal");
    end
    for i = 1, 3 do
        playerSurvivor:getInventory():AddItem("MetalPipe");
    end
end

local function addToolsToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    playerSurvivor:getInventory():AddItem("Base.TinOpener");
    playerSurvivor:getInventory():AddItem("Base.Screwdriver");
    playerSurvivor:getInventory():AddItem("Base.Wrench");
    playerSurvivor:getInventory():AddItem("Base.PipeWrench");
    playerSurvivor:getInventory():AddItem("Base.Hammer");
    playerSurvivor:getInventory():AddItem("Base.WeldingMask");
    playerSurvivor:getInventory():AddItem("Base.BlowTorch");
end

local function addBooksToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    playerSurvivor:getInventory():AddItem("Base.ElectronicsMag4");
    playerSurvivor:getInventory():AddItem("Base.FishingMag1");
    playerSurvivor:getInventory():AddItem("Base.FishingMag2");
    playerSurvivor:getInventory():AddItem("Base.MechanicMag1");
    playerSurvivor:getInventory():AddItem("Base.MechanicMag2");
    playerSurvivor:getInventory():AddItem("Base.MechanicMag3");
end

local function addMedicalToLocalPlayer()
    local playerSurvivor = getSpecificPlayer(0);
    playerSurvivor:getInventory():AddItem("Base.SutureNeedleHolder");
    for i = 1, 3 do
        playerSurvivor:getInventory():AddItem("Base.Antibiotics");
        playerSurvivor:getInventory():AddItem("Base.BathTowel");
        playerSurvivor:getInventory():AddItem("Base.Disinfectant");
        playerSurvivor:getInventory():AddItem("Base.Pills");
        playerSurvivor:getInventory():AddItem("Base.PillsBeta");
        playerSurvivor:getInventory():AddItem("Base.PillsAntiDep");
        playerSurvivor:getInventory():AddItem("Base.PillsSleepingTablets");
        playerSurvivor:getInventory():AddItem("Base.Splint");
    end
    for i = 1, 5 do
        playerSurvivor:getInventory():AddItem("Base.AlcoholBandage");
        playerSurvivor:getInventory():AddItem("Base.SutureNeedle");
    end
end

---comment
---@param targetSquare any
local function spawnZombieAtSquare(targetSquare)
    local squareX = targetSquare:getX();
    local squareY = targetSquare:getY();
    local squareZ = targetSquare:getZ();
    local hordeSize = 1;
    local outfitString = nil;
    local isFemaleChance = 50;
    local spawnedZombie = addZombiesInOutfit(squareX, squareY, squareZ, hordeSize, outfitString, isFemaleChance);

    return spawnedZombie;
end

--
local PZNS_DebugBuildText = {
    SpawnMedical = getText("ContextMenu_PZNS_Spawn_Medical"),
    SpawnBooks = getText("ContextMenu_PZNS_Spawn_Books"),
    SpawnCannedTuna = getText("ContextMenu_PZNS_Spawn_5_Canned_Tuna"),
    SpawnNails = getText("ContextMenu_PZNS_Spawn_5_Nails_Boxes"),
    SpawnPlanks = getText("ContextMenu_PZNS_Spawn_10_Planks"),
    SpawnPropaneTank = getText("ContextMenu_PZNS_Spawn_5_Propane_Tanks"),
    SpawnMetalSheets = getText("ContextMenu_PZNS_Spawn_5_Metal_Sheets"),
    SpawnBigFenceGate = getText("ContextMenu_PZNS_Spawn_1_Big_Fence_Gate"),
    SpawnBigWiredWall = getText("ContextMenu_PZNS_Spawn_1_Wired_Wall"),
    SpawnTools = getText("ContextMenu_PZNS_Spawn_Tools"),
};
---
local PZNS_DebugBuild = {
    SpawnMedical = addMedicalToLocalPlayer,
    SpawnBooks = addBooksToLocalPlayer,
    SpawnCannedTuna = addFiveCannedTunasToLocalPlayer,
    SpawnNails = addFiveNailsBoxesToLocalPlayer,
    SpawnPlanks = addTenPlanksToLocalPlayer,
    SpawnPropaneTank = addFivePropanTanksToLocalPlayer,
    SpawnMetalSheets = addMetalSheetsToLocalPlayer,
    SpawnBigFenceGate = addBigPoleFenceGate,
    SpawnBigWiredWall = addBigWiredWallMaterialsToLocalPlayer,
    SpawnTools = addToolsToLocalPlayer,
};

---@param context any
---@param worldobjects any
function PZNS.Context.Debug.BuildOptions(context, worldobjects)
    --
    local submenu_1 = context:getNew(context);
    local submenu_1_Option = context:addOption(
        getText("ContextMenu_PZNS_PZNS_Debug_Build"),
        worldobjects,
        nil
    );
    context:addSubMenu(submenu_1_Option, submenu_1);
    --
    for debugKey, debugText in pairs(PZNS_DebugBuildText) do
        local callbackFunction = function()
            PZNS_DebugBuild[debugKey]();
        end
        --
        submenu_1:addOption(
            debugText,
            nil,
            callbackFunction
        );
    end
end

-- Cows: Respawn Christ Tester
---@param playerSurvivor NPC
---@param square? IsoGridSquare square to spawn NPC at; if nil - spawn at `playerSurvivor` position
local function respawnChristTester(playerSurvivor, square)
    PZNS_DeleteChrisTester();
    PZNS_SpawnChrisTester(playerSurvivor, square);
end

-- Cows: Respawn Jill Tester
---@param playerSurvivor NPC
---@param square? IsoGridSquare square to spawn NPC at; if `nil` - spawn at `playerSurvivor` position
local function respawnJillTester(playerSurvivor, square)
    PZNS_DeleteJillTester()
    PZNS_SpawnJillTester(playerSurvivor, square);
end

local function removeNPCsAndData()
    local cnt = 0
    for survID, _ in pairs(PZNS.Core.NPC.registry) do
        PZNS_NPCsManager.deleteActiveNPCBySurvivorID(survID)
        cnt = cnt + 1
    end
    print(string.format("Removed %s NPCs from world", cnt))
end

--
local PZNS_DebugWorldText = {
    ClearPlayerNeeds = getText("ContextMenu_PZNS_Clear_Player_Needs"),
    ClearAllNPCsNeeds = getText("ContextMenu_PZNS_Clear_All_NPCs_Needs"),
    SpawnChris = getText("ContextMenu_PZNS_ReSpawn_Chris_Tester"),
    SpawnJill = getText("ContextMenu_PZNS_ReSpawn_Jill_Tester"),
    SpawnZombie = getText("ContextMenu_PZNS_Spawn_Zombie"),
    SpawnRaider = getText("ContextMenu_PZNS_Spawn_Raider"),
    SpawnNPCSurvivor = getText("ContextMenu_PZNS_Spawn_Survivor"),
    RemoveDeadBodies = getText("ContextMenu_PZNS_Remove_Dead_Bodies"),

};
---

---@param context any
---@param worldobjects any
---@param square IsoGridSquare
function PZNS.Context.Debug.WorldOptions(context, worldobjects, playerSurvivor, square)
    local submenu_1 = context:getNew(context);
    local submenu_1_Option = context:addOption(
        getText("ContextMenu_PZNS_PZNS_Debug_World"),
        worldobjects,
        nil
    );
    context:addSubMenu(submenu_1_Option, submenu_1);
    --
    ---@type table<string, {fun:function, params:table<any?>}>
    local PZNS_DebugWorld = {
        ClearPlayerNeeds = { fun = PZNS_PlayerUtils.PZNS_ClearPlayerAllNeeds, params = {} },
        ClearAllNPCsNeeds = { fun = PZNS_UtilsNPCs.PZNS_ClearAllNPCsAllNeedsLevel, params = {} },
        SpawnChris = { fun = respawnChristTester, params = { playerSurvivor, square } },
        SpawnJill = { fun = respawnJillTester, params = { playerSurvivor, square } },
        SpawnZombie = { fun = spawnZombieAtSquare, params = { square } },
        SpawnRaider = { fun = PZNS_NPCsManager.spawnRandomRaiderSurvivorAtSquare, params = { square } },
        SpawnNPCSurvivor = { fun = PZNS_NPCsManager.spawnRandomNPCSurvivorAtSquare, params = { square } },
        RemoveDeadBodies = { fun = PZNS_DebuggerUtils.PZNS_RemoveDeadBodies, params = {} },
    };
    --
    -- make sure we have playerGroup created
    local groups = PZNS.Core.Group.registry
    local playerGroup = "Player0Group"
    if not groups[playerGroup] then
        print(string.format("%s not found, will create new.", playerGroup))
        PZNS_LocalPlayerGroupCreation()
    end
    for debugKey, debugText in pairs(PZNS_DebugWorldText) do
        -- Cows: conditionally set the callback function for the context menu option.
        --
        local key = PZNS_DebugWorld[debugKey]
        if not key then return end
        submenu_1:addOption(
            debugText,
            key.params[1] or nil,
            key.fun,
            unpack(key.params, 2)
        );
    end
end

--
local PZNS_DebugWipeText = {
    WipeNPCs = getText("ContextMenu_PZNS_Wipe_NPC_Data"),
    WipeGroups = getText("ContextMenu_PZNS_Wipe_Groups_Data"),
    WipeFactions = getText("ContextMenu_PZNS_Wipe_Factions_Data"),
    WipeZones = getText("ContextMenu_PZNS_Wipe_Zones_Data"),
    WipeAll = getText("ContextMenu_PZNS_Wipe_All_Data"),
    WipeNPCAndData = getText("ContextMenu_PZNS_Wipe_NPC_And_Data")
};
---
local PZNS_DebugWipe = {
    WipeNPCs = "npc",
    WipeGroups = "group",
    WipeFactions = "faction",
    WipeZones = "zone",
    WipeAll = "all",
};

--- Cows: mpPlayerID is a placeholder, it doesn't do anything.
---@param mpPlayerID number
---@param context any
---@param worldobjects any
function PZNS.Context.Debug.WipeOptions(context, worldobjects)
    local submenu_1 = context:getNew(context);
    local submenu_1_Option = context:addOption(
        getText("ContextMenu_PZNS_PZNS_Debug_WipeData"),
        worldobjects,
        nil
    );
    context:addSubMenu(submenu_1_Option, submenu_1);
    --
    local funcs = { WipeNPCAndData = removeNPCsAndData }
    for debugKey, debugText in pairs(PZNS_DebugWipeText) do
        local callbackFunction = function()
            if funcs[debugKey] then
                funcs[debugKey]()
            else
                PZNS.Core.clearModData(PZNS_DebugWipe[debugKey]);
            end
        end
        --
        submenu_1:addOption(
            debugText,
            nil,
            callbackFunction
        );
    end
end
