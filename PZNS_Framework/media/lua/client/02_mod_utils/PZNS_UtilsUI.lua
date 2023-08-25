local utils = {}

local len = string.len
local sub = string.sub

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
    o.timestamp = os.time()
    return o
end

function utils.Memento:getState()
    return self._state
end

function utils.Memento:getName()
    local state = tostring(self._state.name)
    return tostring(self.timestamp) .. " / " .. string.sub(state, 1, 10)
end

function utils.Memento:getDate()
    return self.timestamp
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
    table.insert(self._mementos, self._originator:saveState())
end

function utils.Caretaker:undo()
    if utils.empty(self._mementos) then
        return
    end

    local memento = table.remove(self._mementos, #self._mementos)
    print("Caretaker: restoring state to: " .. memento:getName())
    local ok, err = pcall(self._originator.restoreState, self._originator, memento)
    if not ok then
        print("Caretaker: Undoing state due to: " .. err)
        self:undo()
    end
end

function utils.Caretaker:showHistory()
    print("Caretaker: list of mementos:")
    for i = 1, #self._mementos do
        print(i .. " | " .. self._mementos[i]:getName())
    end
    print("====")
end

return utils
