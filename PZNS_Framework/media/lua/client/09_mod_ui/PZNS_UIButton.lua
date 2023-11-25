require("09_mod_ui/init")

local utils = require("02_mod_utils/PZNS_UtilsUI")

function PZNS.UI.initWindow()
    PZNS.UI.config = PZNS.UI.settings.load()

    PZNS.UI.mainWindow = PZNS_Window:new(PZNS.UI.config.main_window)
    PZNS.UI.mainWindow:initialise()
    PZNS.UI.mainWindow:setVisible(false)
    PZNS.UI.windowCaretaker = utils.Caretaker:new(PZNS.UI.mainWindow)
end

function PZNS.UI.toggleUI(_)
    local button = PZNS.UI.mainButton
    local ui = PZNS.UI.mainWindow
    if not button or not ui then return end

    if ui:getIsVisible() then
        button:setImage(button._meta.onTexture)
        ui:setVisible(false)
        ui:removeFromUIManager()
        PZNS.UI.settings.serialize()
        PZNS.UI.settings.save()
    else
        button:setImage(button._meta.offTexture)
        ui:setVisible(true)
        ui:addToUIManager()
    end
end

function PZNS.UI.initUI(_)
    PZNS_CreateNPCPanelInfo()
    PZNS_CreatePVPButton()
    local pvpBtn = PVPButton -- TODO: refactor PVPButton
    if PZNS.UI.mainButton then error("PZNS.UI.mainButton already exist") end
    if not pvpBtn then error("PVPButton not found") end

    local btn = ISButton:new(pvpBtn:getRight() + PZNS.UI.const.marginButton, pvpBtn.y, pvpBtn.width,
        pvpBtn.height, "")
    PZNS.UI.mainButton = btn
    btn._meta = {}
    btn._meta.onTexture = getTexture("media/textures/UI_ON.png")
    btn._meta.offTexture = getTexture("media/textures/UI_OFF.png")
    btn._meta.tooltip = getText("UI_PZNS_Button_Tooltip")
    btn:setOnClick(PZNS.UI.toggleUI)
    btn:initialise()
    btn:setImage(btn._meta.onTexture)
    btn:setTooltip(btn._meta.tooltip)
    btn:setVisible(true)
    btn:setEnable(true)
    btn:addToUIManager()

    if not PZNS.UI.mainWindow then
        PZNS.UI.initWindow()
    end
end

local cur
local function reload(key)
    if key == Keyboard.KEY_X then
        if PZNS.UI.mainWindow then
            if PZNS.UI.mainWindow:getIsVisible() then
                PZNS.UI.mainWindow:close()
            end
            PZNS.UI.mainWindow = nil
        end
        if PZNS.UI.mainButton then
            PZNS.UI.mainButton:setVisible(false)
            PZNS.UI.mainButton:removeFromUIManager()
            PZNS.UI.mainButton = nil
        end
        PZNS.UI.initUI()
    end
    local player = getPlayer()
    local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")
    local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
    local PZNS_PlayerUtils = require("02_mod_utils/PZNS_PlayerUtils")
    local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager")
    local PZNS_CombatUtils = require("02_mod_utils/PZNS_CombatUtils")

    -- if key == Keyboard.KEY_E then
    --     local raider = PZNS_NPCsManager.spawnRandomRaiderSurvivorAtSquare(clickedOnSquare)
    --     cur = raider
    -- end
    if key == Keyboard.KEY_Z then
        local clickedOnSquare = PZNS_PlayerUtils.PZNS_GetPlayerMouseGridSquare(0)
        local playerNPC = PZNS_PlayerUtils.getPlayerNPC(0)
        -- local rolledPart, chanceToHit = calcHitPart(true, 5, 0)

        -- if not cur or not PZNS_NPCsManager.findNPCByIsoObject(cur.npcIsoPlayerObject) or cur and not cur.npcIsoPlayerObject:isAlive() then
        --     local clickedOnSquare = PZNS_PlayerUtils.PZNS_GetPlayerMouseGridSquare(0)
        --     local raider = PZNS_NPCsManager.spawnRandomRaiderSurvivorAtSquare(clickedOnSquare)
        --     cur = raider
        -- end
        -- local weapon = playerNPC.npcIsoPlayerObject:getPrimaryHandItem() --[[@as HandWeapon]]
        -- if not weapon then weapon = InventoryItemFactory.CreateItem("Base.BareHands") end
        -- PZNS_CombatUtils.PZNS_CalculatePlayerDamage(playerNPC.npcIsoPlayerObject, cur.npcIsoPlayerObject,
        --     weapon, 1)
        local npc = PZNS_NPCsManager.spawnRandomRaiderSurvivorAtSquare(clickedOnSquare)
        -- PZNS_UtilsNPCs.PZNS_SetNPCFollowTargetID(npc, playerNPC.survivorID);
        -- PZNS_NPCGroupsManager.addNPCToGroup(npc, playerNPC.groupID)
        PZNS_UtilsNPCs.PZNS_SetNPCJob(npc, "Guard")
    end
end

Events.OnKeyPressed.Add(reload)
