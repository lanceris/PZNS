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
    if key == Keyboard.KEY_Z then
        local player = getPlayer()
        local ut = require("04_data_management/PZNS_NPCsManager")
        local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")
        local PZNS_PlayerUtils = require("02_mod_utils/PZNS_PlayerUtils")
        local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager")

        local i = 1
        local name = string.format("some_random_%s", i)
        local isExist = PZNS.Core.NPC.registry[name]
        while isExist do
            i = i + 1
            name = string.format("some_random_%s", i)
            isExist = PZNS.Core.NPC.registry[name]
        end
        print(name .. " is free, creating...")
        local surv = ut.spawnRandomNPCSurvivorAtSquare(player:getSquare(), name, "Companion")
        local playerNPC = PZNS_PlayerUtils.getPlayerNPC(0)
        local groupID = "Player0Group"
        PZNS_NPCGroupsManager.addNPCToGroup(surv, groupID)
        PZNS_UtilsNPCs.PZNS_SetNPCFollowTargetID(surv, playerNPC.survivorID)
        surv.affection = 60
        i = i + 1
    end
end

Events.OnKeyPressed.Add(reload)
