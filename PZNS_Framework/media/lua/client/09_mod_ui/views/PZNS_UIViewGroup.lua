require("00_references/__init")
require("09_mod_ui/views/PZNS_UIView")

PZNS.UI.ViewGroup = PZNS_UIView:derive("PZNS_UIViewGroup")
local view = PZNS.UI.ViewGroup

local utils = require("02_mod_utils/PZNS_UtilsUI")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function view:initialise()
    PZNS_UIView.initialise(self)
    self:create()
end

function view:create()
    PZNS_UIView.create(self)

    self.toolsRow = PZNS.UI.ToolsRow:new(0, 0, self.width, 24, self.data)
    self.toolsRow:initialise()
    self.toolsRow:setVisible(false)

    self.tableList = ISScrollingListBox:new(0, self.toolsRow:getBottom(), self.width, self.height - self.toolsRow.height)
    self.tableList.backgroundColor.a = 0
    self.tableList:initialise()
    self.tableList:instantiate()
    self.tableList:setFont(UIFont.Small)
    self.tableList.doDrawItem = self.doDrawItemList
    self.tableList.prerender = self.prerenderTable
    self.tableList.addColumn = self.addColumn
    self.tableList.onMouseMove = self._onMouseMove
    self.tableList:addColumn("Name", 0)
    self.tableList:addColumn("Relations", self.width - 24,
        { texture = self.tex, size = 24 })
    self.tableList:setVisible(false)
    self.tableList.itemheight = math.max(24, self.tableList.fontHgt + (self.tableList.itemPadY or 0) * 2)
    self.tableList:setY(self.tableList.y + self.tableList.itemheight)
    self.tableList:setHeight(self.tableList.height - self.tableList.itemheight)
    self.tableList:setAnchorBottom(true)
    self.tableList:setAnchorRight(true)

    self.tableDetail = ISScrollingListBox:new(0, self.toolsRow:getBottom(), self.width,
        self.height - self.toolsRow.height)
    self.tableDetail.backgroundColor.a = 0
    self.tableDetail:initialise()
    self.tableDetail:setFont(UIFont.Small)
    self.tableDetail.doDrawItem = self.doDrawItemDetail
    self.tableDetail:addColumn("Inventory", 0)
    self.tableDetail:addColumn("Name", 24)
    self.tableDetail:addColumn("Location", 24 * 6)
    self.tableDetail:addColumn("Duration", 24 * 7)
    self.tableDetail:addColumn("Action", 24 * 8)
    self.tableDetail:addColumn("Job", 24 * 12)
    self.tableDetail:addColumn("Zone", 24 * 13)
    self.tableDetail:addColumn("Relation", 24 * 15)
    self.tableDetail:addColumn("Health", 24 * 16)
    self.tableDetail:addColumn("Mood", 24 * 17)
    self.tableDetail:setVisible(false)
    self.tableDetail:setY(self.tableDetail.y + self.tableDetail.itemheight)
    self.tableDetail:setAnchorBottom(true)

    self:addChild(self.toolsRow)
    self:addChild(self.tableList)
    self:addChild(self.tableDetail)
end

function view:doDrawItemList(y, item, alt)
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), item.height - 1, 0.3, 0.7, 0.35, 0.15);
    end
    self:drawRectBorder(0, (y), self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g,
        self.borderColor.b);
    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
    self:drawText(item.text, 15, (y) + itemPadY, 0.9, 0.9, 0.9, 0.9, self.font);
    if item.item.texture then
        self:drawTextureScaledAspect(item.item.texture, self.columns[2].size, (y) + itemPadY, 24, 24, 0.5, 1, 1, 1)
    end
    y = y + item.height;
    return y;
end

function view:doDrawItemDetail(y, item, alt)

end

function view:addColumn(name, size, image)
    local _name
    if not image then
        _name = name
    end

    table.insert(self.columns, { name = _name, size = size, image = image })
end

function view:_onMouseMove(dx, dy)
    print(self:getMouseX() .. "|" .. self:getMouseY())
end

function view:prerenderTable()
    ISScrollingListBox.prerender(self)
    self.itemheight = math.max(24, self.fontHgt + (self.itemPadY or 0) * 2)
    if #self.columns > 0 then
        for i = 1, #self.columns do
            local col = self.columns[i]
            local left = col.size
            local right = self.columns[i + 1] and self.columns[i + 1].size or self.width
            if col.image then
                -- (texture, x, y, w, h, a, r, g, b)
                local mid = (right + left) / 2 - col.image.size / 2
                local x = mid
                local y = 0 - self.itemheight - 1 - self:getYScroll()
                ---self.itemheight + col.image.size / 2 - self:getYScroll()
                self:drawTextureScaled(col.image.texture, x, y, 24, 24, 1, 1, 1, 1)
            end
        end
    end
end

function view:onActivateView()
    print("Activated " .. self.type)
end

function view:onDeactivateView()
    print("Deactivated " .. self.type)
end

-- function view:renderTable()
--     ISScrollingListBox.render(self)
--     if #self.columns > 0 then
--         for i = 1, #self.columns do
--             local col = self.columns[i]
--         end
--     end
-- end

function view:new(args)
    local o = PZNS_UIView:new(args)

    setmetatable(o, self)
    self.__index = self

    o.tex = getTexture("media/ui/SkullPoison.png")
    o.anchorRight = true
    o.anchorLeft = true
    o.anchorBottom = true

    return o
end
