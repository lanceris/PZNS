require("00_references/init")
require("11_events_spawning/PZNS_EventManager")
local PZNS_CombatUtils = require("02_mod_utils/PZNS_CombatUtils");
local PZNS_PlayerUtils = require("02_mod_utils/PZNS_PlayerUtils")
local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")
local PZNS_SystemsManager = require("11_events_spawning/systems/PZNS_SystemsManager")

Events.EveryOneMinute.Add(PZNS.AI._updateEveryXGameMinutes)
Events.OnTick.Add(PZNS.AI._updateOnTick)
Events.OnRenderTick.Add(PZNS.AI._updateOnRenderTick)

-- Cows: Sandbox Options if needed
Events.OnInitGlobalModData.Add(PZNS_GetSandboxOptions);
--
Events.OnGameStart.Add(PZNS.Core.initModData)

-- Cows: Perhaps someone else can come up with the multiplayer group creation...
Events.OnGameStart.Add(PZNS_PlayerUtils.initPlayer)
Events.OnGameStart.Add(PZNS_UtilsDataNPCs.PZNS_InitLoadNPCsData);
Events.OnGameStart.Add(PZNS_UpdateISWorldMapRender);
Events.OnGameStart.Add(PZNS_ResetJillTesterSpeechTable);
Events.OnGameStart.Add(PZNS.UI.initUI)


-- Cows: Events that should load after all other game start events.
local function PZNS_Events()
    -- Events.OnKeyPressed.Add(PZNS_KeyBindAction);
    Events.OnWeaponSwing.Add(PZNS_WeaponSwing);
    Events.OnWeaponHitCharacter.Add(PZNS_CombatUtils.PZNS_CalculatePlayerDamage);
    --
    Events.OnFillWorldObjectContextMenu.Add(PZNS.Context.PZNS_OnFillWorldObjectContextMenu);
    --
    Events.OnRefreshInventoryWindowContainers.Add(PZNS_AddNPCInv);
    Events.OnFillInventoryObjectContextMenu.Add(PZNS_NPCInventoryContext);
    --
    if (IsNPCsNeedsActive ~= true) then
        Events.EveryHours.Add(PZNS_UtilsNPCs.PZNS_ClearAllNPCsAllNeedsLevel);
    end
    -- Cows: May need to change this to OnPlayerUpdate to address https://github.com/shadowhunter100/PZNS/issues/34...
    -- Cows: Maybe not, since the NPCs will be unloaded much more aggressively/sooner at 45 squares, will confirm after more testing.
    Events.EveryOneMinute.Add(PZNS_WorldUtils.PZNS_SpawnNPCIfSquareIsLoaded);
    -- Events.OnTick.Add(PZNS_UpdateAllJobsRoutines);
    -- Events.OnRenderTick.Add(PZNS_RenderNPCsText);
    -- Unregister updates for NPC and clean-up data
    Events.OnCharacterDeath.Add(PZNS_NPCsManager.PZNS_CleanUpNPCData)
    -- Track sounds for NPCs to react
    Events.OnWorldSound.Add(PZNS_SystemsManager.PZNS_SoundManager)
end

Events.OnGameStart.Add(PZNS_Events);
Events.OnSave.Add(PZNS_UtilsDataNPCs.PZNS_SaveAllNPCData);
