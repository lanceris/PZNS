local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager");
local PZNS_DebuggerUtils = require("02_mod_utils/PZNS_DebuggerUtils");
local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager");
require("00_references/init")
require "11_events_spawning/PZNS_Events";

-- Cows: Use this file to test whatever events or function to call in the game. This file will be overridden between releases and updates.

local function every5Test(args)
    print(args.npc.name)
    print("imma run every 5 min!")
end
local function every1Test()
    print("imma run every 1 min!")
end

local function _key(key)
    local args = {
        event = "OnTick",
        func = every5Test,
        rate = 1000,
        name = "5 minute test",
        args = {
            npc = { name = "ab" } }
    }
    -- if key == Keyboard.KEY_E then
    --     PZNS.AI.AddToSchedule(args.event, args.name, args.func, args.rate, args.args)
    --     -- PZNS.AI.AddToSchedule(args.event, "1 minute test", every1Test, args.args, 1)
    -- end
    if key == Keyboard.KEY_C then
        -- PZNS.AI.UpdateScheduleRate(args.event, "1 minute test", 3)
        print(PZNS.AI.GetScheduledFor("OnTick", true))
    end
    -- if key == Keyboard.KEY_X then
    -- end
    -- if key == Keyboard.KEY_Z then
    --     PZNS.AI.ClearAllEvents()
    -- end
end
Events.OnKeyPressed.Add(_key)

local fmod = math.fmod
local last = getTimeInMillis()
local function tickPerf(ticks)
    if fmod(ticks, 100) == 0 then
        local cur = getTimeInMillis()
        print(round((cur - last) / 100, 2))
        last = cur
    end
end

-- Events.OnTick.Add(tickPerf)
