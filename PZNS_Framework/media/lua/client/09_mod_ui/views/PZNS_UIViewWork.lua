require("00_references/__init")
require("09_mod_ui/views/PZNS_UIView")

PZNS.UI.ViewWork = PZNS_UIView:derive("PZNS_UIViewWork")
local view = PZNS.UI.ViewWork

function view:initialise()
    PZNS_UIView.initialise(self)
    self:create()
end

function view:create()
    PZNS_UIView.create(self)

    self.toolsRow = PZNS.UI.ToolsRow:new(0, 0, self.width, 24, self.data)
    self.toolsRow:initialise()
    self.toolsRow:setVisible(false)

    self.label = ISLabel:new(0, self.toolsRow:getBottom(), 30, self.data.name, 1, 1, 1, 1, UIFont.Medium, true)
    self.label:initialise()
    self.label:setVisible(false)

    self:addChild(self.toolsRow)
    self:addChild(self.label)
end

function view:onActivateView()
    self.label:setVisible(true)
    print("Activated " .. self.type)
end

function view:onDeactivateView()
    self.label:setVisible(false)
    print("Deactivated " .. self.type)
end

function view:new(args)
    local o = PZNS_UIView:new(args)

    setmetatable(o, self)
    self.__index = self

    return o
end
