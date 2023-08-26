require("09_mod_ui/__init")

local utils = require("02_mod_utils/PZNS_UtilsUI")

function PZNS.UI.initWindow()
    local args = { x = 100, y = 400, width = 500, height = 300 }

    PZNS.UI.mainWindow = PZNS_Window:new(args)
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
    else
        button:setImage(button._meta.offTexture)
        ui:setVisible(true)
        ui:addToUIManager()
    end
end

function PZNS.UI.initUI(_)
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
        PZNS.UI.windowCaretaker:showHistory()
    end
end

Events.OnKeyPressed.Add(reload)
