require("00_references/__init")
require("09_mod_ui/views/PZNS_UIView")

PZNS.UI.ViewSettings = PZNS_UIView:derive("PZNS_UIViewSettings")
local view = PZNS.UI.ViewSettings

function view:initialise()
    PZNS_UIView.initialise(self)
    self:create()
end

function view:create()
    PZNS_UIView.create(self)

    --region toolsRow "tabs"
    self.uiSettingsButton = ISButton:new(self.toolsRow.backButton:getRight(), 0, 24 * 3, 24, "UI", self,
        self.onActivateSubView)
    self.uiSettingsButton.internal = "ui"
    self.uiSettingsButton:initialise()
    self.toolsRow:addChild(self.uiSettingsButton)

    self.otherSettingsButton = ISButton:new(self.uiSettingsButton:getRight(), 0, 24 * 3, 24, "Other", self,
        self.onActivateSubView)
    self.otherSettingsButton.internal = "other"
    self.otherSettingsButton:initialise()
    self.toolsRow:addChild(self.otherSettingsButton)

    self.label = ISLabel:new(0, 0, 30, self.data.name, 1, 1, 1, 1, UIFont.Medium, true)
    self.label:initialise()

    -- (x, y, w, h, labelArgs, sliderArgs)
    local sliderArgs = {
        name = "UIScale",
        target = self,
        callback = self.onSliderChange,
        values = { current = 1, min = 0.25, max = 3, step = 0.25, shift = 0.5 }
    }
    local labelArgs = {
        name = "UI Scale",
        font = UIFont.Small
    }
    local inputArgs = {
        font = UIFont.Small,
        editable = false,
        onTextChange = self.onInputChange
    }
    self.UIScaleSlider = self:addSliderRow(0, self.label:getBottom(), 300, 24, sliderArgs, labelArgs, inputArgs)

    sliderArgs = {
        name = "someSlider",
        target = self,
        callback = self.onSliderChange,
        values = { current = 5, step = 5, shift = 20 }
    }
    labelArgs = {
        name = "someSlider",
        font = UIFont.Small
    }
    inputArgs = {
        font = UIFont.Small,
        editable = true,
        onTextChange = self.onInputChange
    }
    self.slider2 = self:addSliderRow(0, self.UIScaleSlider:getBottom() + 2, 300, 24, sliderArgs, labelArgs, inputArgs)

    self.container:addChild(self.label)
    self.container:addChild(self.UIScaleSlider)
    self.container:addChild(self.slider2)
end

function view.onInputChange(input)
    local text = input:getInternalText()
    if not tonumber(text) then return end
    local slider = input.parent.slider
    local step = slider.stepValue
    local min = slider.minValue
    local max = slider.maxValue
    local sliderVal = math.min(max, math.max(min, round(text * (1 / step)) / (1 / step)))
    slider:setCurrentValue(sliderVal, true)
end

function view:onSliderChange(newVal, slider)
    if slider.name then
        local label = slider.parent.label
        local input = slider.parent.input
        if label then
        end
        if input then
            input:setText(newVal)
        end
        if slider.name == "UIScale" then
        end
        if slider.name == "someSlider" then

        end
    end
end

function view:onActivateView()
    print("Activated " .. self.type)
    if self.toolsRow.searchBar:isVisible() then
        self.toolsRow.searchBar:setVisible(false)
    end
end

function view:onDeactivateView()
    print("Deactivated " .. self.type)
end

function view:onActivateSubView(button)
    print(button.internal)
end

function view:new(args)
    local o = PZNS_UIView:new(args)

    setmetatable(o, self)
    self.__index = self

    return o
end
