--source - https://gist.github.com/RyanPattison/7dd900f4042e8a6f9f23

---@class weightedRng
local weightedRng = {}

function weightedRng:new(weights)
    local total = 0
    for _, v in ipairs(weights) do
        assert(v >= 0, "all weights must be non-negative")
        total = total + v
    end

    assert(total > 0, "total weight must be positive")
    local normalize = #weights / total
    local norm = {}
    local small_stack = {}
    local big_stack = {}
    for i, w in ipairs(weights) do
        norm[i] = w * normalize
        if norm[i] < 1 then
            table.insert(small_stack, i)
        else
            table.insert(big_stack, i)
        end
    end

    local prob = {}
    local alias = {}
    while small_stack[1] and big_stack[1] do -- both non-empty
        local small = table.remove(small_stack)
        local large = table.remove(big_stack)
        prob[small] = norm[small]
        alias[small] = large
        norm[large] = norm[large] + norm[small] - 1
        if norm[large] < 1 then
            table.insert(small_stack, large)
        else
            table.insert(big_stack, large)
        end
    end

    for _, v in ipairs(big_stack) do prob[v] = 1 end
    for _, v in ipairs(small_stack) do prob[v] = 1 end

    self.__index = self
    return setmetatable({ alias = alias, prob = prob, n = #weights }, self)
end

function weightedRng:__call()
    local index = ZombRand(1, self.n + 1)
    return ZombRandFloat(0, 1) < self.prob[index] and index or self.alias[index]
end

return weightedRng

--[[ -- usage:
alias_table = require"alias_table"
sample = alias_table:new{10, 20, 15, 2, 2.3, 130} -- assign weights for 1, 2, 3, 4, 5, 6 etc.
print(sample())
print(sample())
print(sample())
print(sample())
print(sample())
--]]
