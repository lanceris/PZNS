require("09_mod_ui/__init")
PZNS_Window = ISCollapsableWindowJoypad:derive('PZNS_Window')
-- local PZNS_Window = PZNS.UI.PZNS_Window

local utils = require("02_mod_utils/PZNS_UtilsUI")

-- region create
function PZNS_Window:initialise()
    ISCollapsableWindowJoypad.initialise(self)
end

function PZNS_Window:createChildren()
    ISCollapsableWindowJoypad.createChildren(self)

    self.tbh = self:titleBarHeight()
    self.rh = self:resizeWidgetHeight()
    self.headerH = 24

    --region header
    self.header = ISPanelJoypad:new(0, self.tbh, self.width, self.headerH)
    self.header:initialise()
    self.header:setAnchorRight(true)
    self.header:setVisible(true)
    self:addChild(self.header)

    local buttons = { "settings", "npc", "group", "faction", "work", "zone" }
    local viewArgs = {
        x = 0,
        y = self.tbh + self.headerH,
        w = self.width,
        h = self.height - self.tbh - self.headerH - self.rh,
        btnX = 0
    }

    for i = 1, #buttons do
        local viewName = buttons[i]
        self:addView(viewName, viewArgs)
    end

    self.activeView = self.views[buttons[1]]
    self:activateView(buttons[1])
end

-- endregion


-- region update

-- endregion

-- region render

-- endregion

-- region logic
function PZNS_Window.setVisibleSubView(view, visible, joypadData)
    ISPanelJoypad.setVisible(view, visible, joypadData)
    if view.toolsRow then
        view.toolsRow:setVisible(visible)
    end
    if view.tableList then
        view.tableList:setVisible(visible)
    end
    if view.tableDetail and false then
        view.tableDetail:setVisible(visible)
    end
end

function PZNS_Window:addView(name, viewArgs)
    local viewData = PZNS.UI.viewData[name]
    if not viewData or utils.empty(viewData) then error("No data found for view: " .. name) end
    if not viewData.class then error("class not found for view: " .. name) end
    viewArgs.viewName = name
    viewArgs.type = name
    viewArgs.data = viewData.data or { name = name }
    local view = viewData.class:new(viewArgs)
    view.setVisible = self.setVisibleSubView

    local button = ISButton:new(viewArgs.btnX, 0, 24, 24, "", self, self.onViewButtonMouseDown)
    button.internal = name
    button.viewName = name
    button.windowTitle = viewData.title
    button.backgroundColor = self.buttonInactiveColor
    button.image = viewData.btnTexure
    button:initialise()
    button:setVisible(true)
    self.header:addChild(button)
    viewArgs.btnX = viewArgs.btnX + 24

    view:initialise()
    view:setVisible(false)
    local viewObj = {}
    viewObj.headerButton = button
    viewObj.name = name
    viewObj.view = view
    self.views[viewObj.name] = viewObj
    self:addChild(view)
end

function PZNS_Window:onViewButtonMouseDown(button, x, y)
    if self.activeView.name == button.internal then
        -- same view, do nothing
        return
    end
    PZNS.UI.windowCaretaker:backup()
    local status, res = pcall(self.activateView, self, button.internal)
    if not status then
        error("Could not activateView: " .. tostring(button.internal) .. "; err:" .. tostring(res))
    end
    if not res then
        error("Unknown view requested: " .. tostring(button.internal))
    end
end

function PZNS_Window:activateView(viewName)
    if not self.views[viewName] then return false end
    local oldView = self.activeView
    oldView.view:setVisible(false)
    oldView.headerButton.backgroundColor = self.buttonInactiveColor
    if oldView.view.onDeactivateView then
        oldView.view:onDeactivateView()
    end

    local newView = self.views[viewName]
    newView.headerButton.backgroundColor = self.buttonActiveColor
    if newView.view.onActivateView then
        newView.view:onActivateView()
    end

    newView.view:setVisible(true)
    self.activeView = self.views[viewName]

    self:setTitle(newView.headerButton.windowTitle)
    self.state = { name = self.activeView.name }
    return true
end

-- endregion


function PZNS_Window:saveState()
    if self.state == nil then
        self.state = {}
    end
    return self:createMemento()
end

function PZNS_Window:restoreState(memento)
    self.state = memento:getState()
    self:activateView(self.state.name)
end

function PZNS_Window:createMemento()
    local o = utils.Memento:new()
    o._state = copyTable(self.state)
    return o
end

function PZNS_Window:new(args)
    local o = {}
    local x = args.x
    local y = args.y
    local width = args.width
    local height = args.height

    o = ISCollapsableWindowJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    for k, v in pairs(args) do
        o[k] = v
    end
    o.views = {}
    o.activeView = nil
    o.buttonInactiveColor = PZNS.UI.viewData._common.buttonInactiveColor
    o.buttonActiveColor = PZNS.UI.viewData._common.buttonActiveColor
    o.minimumWidth = 500
    o.minimumHeight = 300

    o.state = {}
    return o
end
