local utils = {}

local len = string.len
local sub = string.sub
local insert = table.insert
---Checks if txt start with start
---@param txt string text to check
---@param start string string to check in text
---@return boolean #result
utils.startswith = function(txt, start)
    return sub(txt, 1, len(start)) == start
end

utils.empty = function(tab)
    for _, _ in pairs(tab) do return false; end
    return true
end

utils.Memento = {}
function utils.Memento:new(state)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o._state = state
    o.date = os.date("%Y-%m-%d %H:%M:%S")
    return o
end

function utils.Memento:getState()
    return self._state
end

function utils.Memento:getName()
    local state = tostring(self._state.name)
    return tostring(self.date) .. " / " .. string.sub(state, 1, 10)
end

function utils.Memento:getDate()
    return self.date
end

utils.Caretaker = {}
function utils.Caretaker:new(cls, historyLimit)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.historyLimit = historyLimit or 10
    o._mementos = {}
    o._originator = cls
    return o
end

function utils.Caretaker:backup()
    print("Caretaker: Backup originator state...")
    if #self._mementos >= self.historyLimit then
        print("Caretaker: Limit Exceeded, removing oldest state")
        table.remove(self._mementos, 1)
    end
    insert(self._mementos, self._originator:saveState())
end

function utils.Caretaker:undo(index)
    if utils.empty(self._mementos) then
        return
    end
    local slice = false
    if index then
        slice = true
        if index <= 0 then
            index = 1
        elseif index > #self._mementos then
            index = #self._mementos
        end
    else
        index = #self._mementos
    end

    local memento = table.remove(self._mementos, index)
    print("Caretaker: restoring state to: " .. memento:getName())
    if slice then
        local from = index
        if from <= 0 then from = 1 end
        print("Caretaker: removing history from " .. from .. " to " .. #self._mementos)
        for i = from, #self._mementos do
            table.remove(self._mementos, i)
        end
    end
    local ok, err = pcall(self._originator.restoreState, self._originator, memento)
    if not ok then
        print("Caretaker: Undoing state due to: " .. err)
        self:undo()
    end
end

function utils.Caretaker:historySize()
    return #self._mementos
end

function utils.Caretaker:getHistory(toString)
    if #self._mementos <= 0 then return end
    local history = {}
    for i = 1, #self._mementos do
        insert(history, i .. " | " .. self._mementos[i]:getName())
    end
    if toString then
        history = table.concat(history, " <LINE> ")
    end
    return history
end

function utils.Caretaker:showHistory()
    local history = {}
    insert(history, "Caretaker: list of mementos:")
    for i = 1, #self._mementos do
        insert(history, i .. " | " .. self._mementos[i]:getName())
    end
    for i = 1, #history do
        print(history[i])
    end
    print("====")
end

return utils
