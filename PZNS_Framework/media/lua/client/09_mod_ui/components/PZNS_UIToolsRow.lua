require("09_mod_ui/init")
local fzy = require("02_mod_utils/fzy_lua")
local utils = require("02_mod_utils/PZNS_UtilsUI")
PZNS.UI.ToolsRow = ISPanelJoypad:derive('PZNS_UIToolsRow')
local class = PZNS.UI.ToolsRow

local contains = string.contains
local trim = string.trim
local insert = table.insert
local concat = table.concat

-- region create

function class:initialise()
    ISPanelJoypad.initialise(self)
    self:create()
end

function class:create()
    self.backButton = ISButton:new(0, 0, 24, 24, "", self, self.onBackButtonDown)
    self.backButton:initialise()
    self.backButton:setImage(self.textures.back)
    self.backButton:setVisible(true)
    self.backButton.onRightMouseDown = self.backButtonOnRightMouseDown

    self.searchBar = ISTextEntryBox:new('', self.backButton:getRight(), 0, 24 * 5, 24)
    self.searchBar.font = UIFont.Small -- TODO: move to options
    self.searchBar:setTooltip(self.searchBarTooltip)
    self.searchBar:setAnchorRight(true)
    self.searchBar.onCommandEntered = self.onCommandEntered
    self.searchBar:initialise()
    self.searchBar:instantiate()
    self.searchBar:setText('')
    self.searchBar:setClearButton(true)
    self.searchBarLastText = self.searchBar:getInternalText()
    self.searchBarText = self.searchBarLastText
    self.searchBar.onTextChange = self.onTextChange
    self.searchBar.onOtherKey = class.onOtherKey
    self.searchBar.onRightMouseDown = self.onRightMouseDown


    self.selector = ISComboBox:new(0, 0, 200, 24, self)
    if self.args.selector then
        self:selectorSetOnChange(self.selector, self.args.selector)
    end
    self.selector.editable = true
    self.selector.font = UIFont.Small
    self.selector:initialise()
    self.selector:instantiate()
    self.selector.prerender = self.prerenderSelector
    self.selector:setVisible(false)

    self.editButton = ISButton:new(0, 0, 24, 24, "", self, self.onButtonMouseDown)
    self.editButton.internal = "edit"
    self.editButton:initialise()
    self.editButton:setImage(self.textures.edit)
    self.editButton:setVisible(false)

    self.createFactionButton = ISButton:new(0, 0, 24, 24, "", self.onButtonMouseDown)
    self.createFactionButton.internal = "createFaction"
    self.createFactionButton:initialise()
    self.createFactionButton:setImage(self.textures.faction)
    self.createFactionButton:setVisible(false)

    self:addChild(self.backButton)
    self:addChild(self.searchBar)
    self:addChild(self.selector)
    self:addChild(self.editButton)
    self:addChild(self.createFactionButton)

    self.selector.popup.doDrawItem = self.doDrawItemSelectorPopup
end

-- endregion

-- region update

function class:updateSearchBarLastText()
    self.searchBarLastText = self.searchBar:getText()
end

-- endregion

-- region render

-- function class:onResize()
--     self.searchBar:setWidth(self.width - self.searchBtn.width)
-- end


function class:prerenderSelector()
    ISComboBox.prerender(self)
    local selected = self.options[self.selected]
    if not selected then return end

    if self:isEditable() and self.editor and self.editor:isReallyVisible() then
    else
        local data = self:getOptionData(self.selected)
        if not data or not data.count or type(data.count) ~= "number" then return end
        local texX = getTextManager():MeasureStringX(self.font, self:getOptionText(self.selected))
        local y = (self.height - getTextManager():getFontHeight(self.font)) / 2
        self:clampStencilRectToParent(0, 0, self.width - self.image:getWidthOrig() - 6, self.height)
        local countStr = ' (' .. data.count .. ')'
        self:drawText(countStr, texX + 10, y, self.textColor.r, self.textColor.g,
            self.textColor.b, self.textColor.a, self.font)
        self:clearStencilRect()
    end
end

function class:doDrawItemSelectorPopup(y, item, alt)
    y = ISComboBoxPopup.doDrawItem(self, y, item, alt)
    local data = self.parentCombo:getOptionData(item.index)
    if not data or not data.count or type(data.count) ~= "number" then return y end
    if self.parentCombo:hasFilterText() then
        if not item.text:lower():contains(self.parentCombo:getFilterText():lower()) then
            return y
        end
    end
    local texX = getTextManager():MeasureStringX(self.font, self.parentCombo:getOptionText(item.index))
    local countStr = ' (' .. data.count .. ')'
    self:drawText(countStr, texX + 10, y - item.height + 5,
        self.parentCombo.textColor.r, self.parentCombo.textColor.g,
        self.parentCombo.textColor.b, self.parentCombo.textColor.a, self.font)

    return y
end

function class:prerender()
    if self.background then
        self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r,
            self.backgroundColor.g, self.backgroundColor.b);
    end
    self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b)
end

-- endregion

-- region logic

-- function class:setOnBackButtonDown(onBackButtonDown)
--     self.backButton:setOnClick(onBackButtonDown)
-- end

function class:selectorSetOnChange(selector, args)
    if args.onChange then
        selector.onChange = args.onChange
        if args.onChangeArg1 then
            selector.onChangeArgs = { args.onChangeArg1, args.onChangeArg2 }
        end
    end
end

function class:onButtonMouseDown(button, x, y)

end

function class:backButtonOnRightMouseDown(x, y)
    local context = ISContextMenu.get(0, getMouseX() + 10, getMouseY())
    local history = PZNS.UI.windowCaretaker:getHistory()
    if not history then return end

    for i = #history, 1, -1 do
        context:addOption(history[i], self, PZNS_UIView.backTo, i)
    end
end

---Parses the query string with optional list of delimiters
---@param txt string search query, e.g `'t1,@t2,%t3'` or `'t1'`
---@param delim? table<number,string> table (list) of delimiters, by default `{',', '|'}`
---@return table<number,string>|nil tokens table (list) of tokens e.g `{'t1', '@t2', '%t3'}` or `{'t1'}`, `nil` if no tokens found (only `delim`)
---@return boolean isMultiSearch `true` if multiple tokens
---@return string|nil queryType type of search query ('AND' or 'OR'), `nil` if `isMultiSearch==false`
function class:parseTokens(txt, delim)
    delim = delim or { ',', '|' }
    local regex = '[^' .. concat(delim) .. ']+'
    local queryType

    txt = trim(txt)
    if not contains(txt, ',') and not contains(txt, '|') then
        return { txt }, false, nil
    end
    if contains(txt, ',') then
        queryType = 'AND'
    elseif contains(txt, '|') then
        queryType = 'OR'
    end

    local tokens = {}
    for token in txt:gmatch(regex) do
        insert(tokens, trim(token))
    end
    if #tokens == 1 then
        return tokens, false, nil
    elseif not tokens then -- just sep (e.g txt=',')
        return nil, false, nil
    end
    return tokens, true, queryType
end

---Checks if `txt` starts with any of the `validSpecialChars`
---@param txt string token
---@param validSpecialChars? table<number,string>  list of special characters to check, by default `{'!', '@', '#', '$', '%', '^', '&'}`
---@return boolean isSpecial
function class:isSpecialCommand(txt, validSpecialChars)
    validSpecialChars = validSpecialChars or { '!', '@', '#', '$', '%', '^', '&' }

    for i = 1, #validSpecialChars do
        if utils.startswith(txt, validSpecialChars[i]) then return true end
    end
    return false
end

-- function class:searchBtnOnClick()
--     if self.searchBtn.modal:isVisible() then
--         self.searchBtn.modal:setVisible(false)
--         self.searchBtn.modal:removeFromUIManager()
--     else
--         self.searchBtn.modal:setVisible(true)
--         self.searchBtn.modal:addToUIManager()
--     end
-- end

function class:setTooltip(text)
    if not self.origTooltip then
        self.origTooltip = self.searchBarTooltip
    end
    self.searchBarTooltip = text
    self.searchBar:setTooltip(self.searchBarTooltip)
end

-- region event handlers

function class:onTextChange()
    local s = self.parent
    s:updateSearchBarLastText()

    if s.onTextChangeSB ~= nil then
        s.onTextChangeSB(s.parent)
    end
end

function class:onCommandEntered()
    local s = self.parent

    if s.onCommandEnteredSB ~= nil then
        s.onCommandEnteredSB(s.parent)
    end
end

function class:onOtherKey(key)
    if key == Keyboard.KEY_ESCAPE then
        self:unfocus()
    end
end

-- function class:onPressDown()
--     local sBar = self
--     local sBarText = sBar:getInternalText()
--     sBarText.logIndex = sBarText.logIndex - 1
--     if sBarText.logIndex < 0 then
--         sBarText.logIndex = 0
--     end
--     if sBarText.log and sBarText.log[sBarText.logIndex] then
--         sBar:setText(sBarText.log[sBarText.logIndex])
--     else
--         sBar:setText('')
--     end
-- end

-- function class:onPressUp()
--     local sBar = self
--     local sBarText = sBar:getInternalText()
--     sBarText.logIndex = sBarText.logIndex + 1
--     if sBarText.logIndex > #sBarText.log then
--         sBarText.logIndex = #sBarText.log
--     end
--     if sBarText.log and sBarText.log[sBarText.logIndex] then
--         sBar:setText(sBarText.log[sBarText.logIndex])
--     end
-- end

function class:onRightMouseDown()
    local s = self.parent

    local context

    local function chcpaste(_, clip)
        self:setText(clip)
        s.parent:updateObjects()
    end

    local clip = Clipboard.getClipboard()
    if clip and trim(clip) ~= '' then
        clip = string.sub(clip, 1, 100)
        context = ISContextMenu.get(0, getMouseX() + 10, getMouseY())
        local name = context:addOption(getText('IGUI_chc_Paste') .. ' (' .. clip .. ')', self, chcpaste, clip)
        name.iconTexture = self.icons.paste
    end
    if s.onRightMouseDownSB then
        s.onRightMouseDownSB(s.parent, context)
    end
end

-- endregion

-- endregion

function class:new(x, y, w, h, args)
    local o = {};
    o = ISPanelJoypad:new(x, y, w, h)

    setmetatable(o, self)
    self.__index = self

    o.background = false
    -- o.searchBtnOnClickText = searchBtnOnClickText
    o.args = args or {}
    o.onTextChangeSB = o.args.onTextChange
    o.onCommandEnteredSB = o.args.onCommandEntered
    -- o.onRightMouseDownSB = onRightMouseDown
    o.searchBarTooltip = o.args.searchBarTooltip or string.sub(getText('IGUI_CraftUI_Name_Filter'), 1, -2)
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.onBackButtonDown = args.onBackButtonDown

    o.textures = PZNS.UI.textures.tools

    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true

    return o
end
