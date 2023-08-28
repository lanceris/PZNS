require("00_references/init")
require("09_mod_ui/views/PZNS_UIView")

PZNS.UI.ViewWork = PZNS_UIView:derive("PZNS_UIViewWork")
local view = PZNS.UI.ViewWork

function view:initialise()
    PZNS_UIView.initialise(self)
    self:create()
end

function view:create()
    PZNS_UIView.create(self)

    self.label = ISLabel:new(0, 0, 30, self.data.name, 1, 1, 1, 1, UIFont.Medium, true)
    self.label:initialise()

    self.container:addChild(self.label)
end

function view:onActivateView()
    print("Activated " .. self.type)
end

function view:onDeactivateView()
    print("Deactivated " .. self.type)
end

function view:new(args)
    local o = PZNS_UIView:new(args)

    setmetatable(o, self)
    self.__index = self

    return o
end
