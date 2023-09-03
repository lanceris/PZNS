require("00_references/init")
local fmt = string.format
local unpack = unpack

local updOnTick = {}
local updOneMinute = {}
local updRenderTick = {}
local map = {
    OnTick = updOnTick,
    EveryOneMinute = updOneMinute,
    OnRenderTick = updRenderTick
}

-- based on FPS ~16.7 ms/tick on 60 FPS, ~8.6 ms/t on 120 FPS etc
function PZNS.AI._updateOnTick()
    -- some static updates (not tied to game speed, except paused)
    -- NOTE: heavy functions will affect light ones (i.e game will freeze while processing heavy stuff)
    -- as there's no multithreading
    local ms = getTimeInMillis()
    for i = 1, #updOnTick do
        local val = updOnTick[i]
        if not val.cur then val.cur = ms end
        if ms >= val.cur + val.rate then
            val.cur = ms
            val.func(unpack(val.args))
        end
    end
end

function PZNS.AI._updateOnRenderTick()
    for i = 1, #updRenderTick do
        local val = updRenderTick[i]
        val.func(unpack(val.args))
    end
end

-- x1 - ~2500 ms; x2 - ~500 ms; x3 - ~120 ms; x4 - ~60ms
-- if `val.rate` is set - trigger every `val.rate` minutes
function PZNS.AI._updateEveryXGameMinutes()
    for i = 1, #updOneMinute do
        local toRun = false
        local val = updOneMinute[i]
        if val.rate then
            if not val.start then
                val.start = 0
            end
            val.start = val.start + 1
            if val.start >= val.rate then
                val.start = 0
                toRun = true
            end
        else
            toRun = true
        end
        if toRun then
            val.func(unpack(val.args))
        end
    end
end

local function verify(event, name, rate)
    assert(Events[event], fmt("Event '%s' not found!", event))
    assert(map[event], fmt("Event '%s' not supported!", event))
    assert(name, "No name provided!")
    if rate then
        assert(tonumber(rate), "Rate must be numeric!")
        if event == "EveryOneMinute" then
            assert(tonumber(rate) >= 1, "Scheduled time must be >= 1 minute")
        elseif event == "OnTick" then
            assert(tonumber(rate) >= 5, "Tick rate must be >= 5")
        end
    end
end

---Schedule
---@param event string
---@param name string
---@param func function
---@param rate? integer
---@param args? table<string, any>
function PZNS.AI.AddToSchedule(event, name, func, rate, args)
    verify(event, name, rate)
    assert(func, "No function to call!")
    if event == "OnTick" and not rate then
        error("Update rate required for OnTick!")
        return
    end
    if event == "OnRenderTick" and rate then
        print("Rate not supported for OnRenderTick!")
    end
    local schedule = map[event]
    for i = 1, #schedule do
        if name == schedule[i].name then
            print(fmt("%s already scheduled in event '%s'!", name, event))
            return
        end
    end
    schedule[#schedule + 1] = {
        name = name,
        func = func,
        rate = tonumber(rate),
        args = args,
    }
    print(fmt("Added '%s' to '%s' schedule", name, event))
end

function PZNS.AI.UpdateScheduleRate(event, name, rate)
    verify(event, name, rate)
    if event == "OnTick" and not rate then
        error("No update rate specified!")
        return
    end
    local schedule = map[event]
    local existing
    for i = 1, #schedule do
        if name == schedule[i].name then
            existing = schedule[i]
            break
        end
    end
    if not existing then
        print(fmt("'%s' not found for event '%s'!", name, event))
        return
    end
    if rate then
        print(fmt("Changed rate from %s to %s", existing.rate, rate))
        existing.rate = tonumber(rate)
    end
    print(fmt("Updated '%s' in '%s' schedule", name, event))
end

---comment
---@param event string Name of the event
---@param name string Name of entry to remove
function PZNS.AI.RemoveFromSchedule(event, name)
    verify(event, name)
    local schedule = map[event]
    for i = 1, #schedule do
        if name == schedule[i].name then
            table.remove(schedule, i)
            print(fmt("Removed '%s' from '%s' schedule", name, event))
            return
        end
    end
    print(fmt("'%s' not found for event '%s'!", name, event))
end

function PZNS.AI.GetScheduledFor(event, asStr)
    local schedule = map[event]
    if not schedule then return {} end
    local result = {}
    for i = 1, #schedule do
        local val = schedule[i].name
        if schedule[i].rate then
            val = val .. "|" .. schedule[i].rate
        end
        result[#result + 1] = val
    end
    if asStr then
        if result[1] then
            local msg = { "\n------", fmt("Scheduled for %s:", event) }
            for i = 1, #result do msg[#msg + 1] = result[i] end
            msg[#msg + 1] = "Total: " .. #result
            msg[#msg + 1] = "------"
            return table.concat(msg, "\n")
        else
            return
        end
    end
    return result
end

function PZNS.AI.ClearSchedule(event)
    assert(Events[event], fmt("Event '%s' not found!", event))
    assert(map[event], fmt("Event '%s' not supported!", event))
    local schedule = map[event]
    local total = #schedule
    table.wipe(map[event])
    print(fmt("Removed %s functions for '%s' event", total, event))
end

function PZNS.AI.ClearAllEvents()
    for event, schedule in pairs(map) do
        local total = #schedule
        table.wipe(schedule)
        print(fmt("Removed %s functions for '%s' event", total, event))
    end
end
