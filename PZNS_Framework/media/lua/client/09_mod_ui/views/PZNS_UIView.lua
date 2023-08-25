require("00_references/__init")

PZNS_UIView = ISPanelJoypad:derive("PZNS_UIView")

function PZNS_UIView:create()
    ISPanelJoypad.createChildren(self)
end

function PZNS_UIView:back()
    PZNS.UI.windowCaretaker:undo()
end

function PZNS_UIView:onActivateView()
    error("Must override in children. View: " .. self.type)
end

function PZNS_UIView:onDeactivateView()
    error("Must override in children. View: " .. self.type)
end

function PZNS_UIView:new(args)
    local o = ISPanelJoypad:new(args.x, args.y, args.w, args.h)

    -- for k, v in pairs(args) do
    --     o[k] = v
    -- end
    o.state = {}
    o.type = args.type
    o.data = args.data
    if not o.data.onBackButtonDown then
        o.data.onBackButtonDown = PZNS_UIView.back
    end
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end
