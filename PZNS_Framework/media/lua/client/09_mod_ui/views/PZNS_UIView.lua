require("00_references/init")

PZNS_UIView = ISPanelJoypad:derive("PZNS_UIView")

function PZNS_UIView:create()
    ISPanelJoypad.createChildren(self)
    self.toolsRow = PZNS.UI.ToolsRow:new(0, 0, self.width, 24, self.data)
    self.toolsRow:initialise()

    self.container = ISPanelJoypad:new(0, self.toolsRow:getBottom(), self.toolsRow.width,
        self.height - self.toolsRow.height)
    self.container.background = false
    self.container.anchorBottom = true
    self.container.anchorRight = true
    self.container:initialise()

    self:addChild(self.toolsRow)
    self:addChild(self.container)
end

function PZNS_UIView:back()
    PZNS.UI.windowCaretaker:undo()
end

function PZNS_UIView:backTo(index)
    PZNS.UI.windowCaretaker:undo(index)
end

function PZNS_UIView:onActivateView()
    self.toolsRow:setVisible(true)
    self.container:setVisible(true)
end

function PZNS_UIView:onDeactivateView()
    self.toolsRow:setVisible(false)
    self.container:setVisible(false)
end

function PZNS_UIView:addSliderRow(x, y, w, h, sliderArgs, labelArgs, inputArgs)
    local function onOtherKey(input, key)
        if key == Keyboard.KEY_ESCAPE then
            input:setText(input.parent.currentValue)
            input:unfocus()
        end
    end

    local function inputSetText(input, text)
        ISTextEntryBox.setText(input, tostring(text))
    end

    local _x = x
    local _w = w
    local label
    local input
    local slider
    if labelArgs then
        local clr = labelArgs.clr or { r = 1, g = 1, b = 1, a = 1 }
        label = ISLabel:new(0, 0, h, labelArgs.name, clr.r, clr.g, clr.b, clr.a, labelArgs.font,
            labelArgs.bLeft == nil and true or labelArgs.bLeft)
        label.originalName = labelArgs.name
        label:initialise()
        x = x + label:getWidth()
        w = w - label:getWidth()
    end
    if inputArgs then
        local inputW = getTextManager():MeasureStringX(inputArgs.font, "9999")
        input = ISTextEntryBox:new("", x, 0, inputW, h)
        input.anchorRight = true
        input.font = inputArgs.font
        input.setText = inputSetText
        input:initialise()
        input:instantiate()
        input:setOnlyNumbers(true)
        input:setEditable(inputArgs.editable == nil and true or inputArgs.editable)
        input:setText("")
        input.onOtherKey = onOtherKey
        input.onTextChange = inputArgs.onTextChange
        x = x + input:getWidth()
        w = w - input:getWidth()
    end
    slider = ISSliderPanel:new(x, 0, w, h, sliderArgs.target, sliderArgs.callback)
    if sliderArgs.values then
        local v = sliderArgs.values
        slider.currentValue = v.current or 0
        slider.minValue = v.min or 0
        slider.maxValue = v.max or 100
        slider.stepValue = v.step or 1
        slider.shiftValue = v.shift or 10

        if labelArgs.doLabel then
        end
        if input then
            input:setText(slider.currentValue)
        end
    end
    slider.name = sliderArgs.name
    slider:initialise()

    local obj = ISPanel:new(_x, y, _w, h)
    obj.backgroundColor.a = 0
    obj.borderColor.a = 0
    obj:initialise()
    obj.slider = slider
    if label then
        obj.label = label
        obj:addChild(label)
    end
    if input then
        obj.input = input
        obj:addChild(input)
    end
    obj:addChild(slider)
    return obj
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
    o.anchorBottom = true
    o.anchorRight = true
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

--region update

function PZNS_UIView:updateCategories(data, counts)
    local selector = self.toolsRow.selector

    selector:clear()
    selector:addOptionWithData(self.defaultCategory, { count = self.categoryData[self.defaultCategory].count })
    table.sort(data)
    for i = 1, #data do
        selector:addOptionWithData(data[i], { count = counts[data[i]] })
    end

    selector:select(self.selectedCategory)
end

--endregion
