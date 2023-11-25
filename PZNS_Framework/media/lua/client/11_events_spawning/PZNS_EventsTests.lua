local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager");
local PZNS_DebuggerUtils = require("02_mod_utils/PZNS_DebuggerUtils");
local PZNS_UtilsDataNPCs = require("02_mod_utils/PZNS_UtilsDataNPCs");
local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager");
require("00_references/init")
require "11_events_spawning/PZNS_Events";
local PZNS_PlayerUtils = require "02_mod_utils/PZNS_PlayerUtils"
local sb_htn = require("sb_htn/interop")

-- Cows: Use this file to test whatever events or function to call in the game. This file will be overridden between releases and updates.

local function every5Test(args)
    print(args.npc.name)
    print("imma run every 5 min!")
end
local function every1Test()
    print("imma run every 1 min!")
end


---comment
---@param obj Stack | ArrayList
---@return table
local function toLuaTable(obj)
    local result = {}
    for i = 0, obj:size() - 1 do
        result[i + 1] = obj:get(i)
    end
    return result
end
local pairs = pairs
local floor = math.floor
local soundTimeOut = 3 * 1000    -- 250 millisecond
local soundForgetTime = 5 * 1000 -- 5 second
local soundReact = 1 * 1000      -- 1 second
local soundPrecision = 5

local function empty(tab)
    for _, _ in pairs(tab) do return false; end
    return true
end

---comment
---@param npcSurvivor PZNS_NPCSurvivor
---@param soundData table
local function respondToSound(npcSurvivor, soundData)
    npcSurvivor.npcIsoPlayerObject:faceLocation(soundData.x, soundData.y)
end

---@param npcSurvivor PZNS_NPCSurvivor
local function processSound(npcSurvivor, curTime)
    local sounds = npcSurvivor.brain.lastHeardSound
    if npcSurvivor.brain.__newSound == false and empty(sounds) then return end
    -- print("Registered new sound for: ", npcSurvivor.survivorName)
    npcSurvivor.brain.__newSound = false
    for soundID, soundData in pairs(sounds) do
        if curTime >= soundData.time + soundReact then
            -- react to sound
            print(string.format("Reacting to sound: %s | after %s ms",
                soundData.radius, curTime - soundData.time))

            respondToSound(npcSurvivor, soundData)
            sounds[soundID] = nil
        end
        if curTime >= soundData.time + soundTimeOut then
            -- forget about sound
            soundData.count = soundData.count - 1
            if soundData.count <= 0 then
                print(string.format("Forgot about sound: %s | after %s ms",
                    soundID, curTime - soundData.time))
                sounds[soundID] = nil
            end
        end
        if curTime >= soundData.time + soundForgetTime then
            -- if couldn't react for some reason
            print(string.format("Forgot about sound: %s | after %s ms",
                soundID, curTime - soundData.time))
            sounds[soundID] = nil
        end
    end
end

---comment
---@param npcSurvivor PZNS_NPCSurvivor
local function processLastAttacked(npcSurvivor, dt)
    local player = npcSurvivor.npcIsoPlayerObject
    local hitReaction = player:hasHitReaction()
    local attackedBy = player:getAttackedBy()
    if hitReaction and attackedBy then
        if npcSurvivor.lastAttackedBy ~= attackedBy then
            -- local s = tostring(attackedBy)
            -- print("New attacker:", string.sub(s, string.find(s, "@"), #s))
            npcSurvivor.lastAttackedBy = attackedBy
        end
    end
end

local function playerUpdate(player)
    if not player then return end
    local npcSurvivor = PZNS.Core.NPC.IsoPlayerRegistry[player]
    if not npcSurvivor then return end
    local dt = getTimeInMillis()
    processLastAttacked(npcSurvivor)
    processSound(npcSurvivor, dt)
end

local a = true
local function _key(key)
    if key == Keyboard.KEY_F then
        local uu = PZNS.Core.NPC.registry["Player0"].brain
        local o = PZNS.Core.NPC.IsoPlayerRegistry
        df:df()
    end
    if key == Keyboard.KEY_C then
        print(PZNS.AI.GetScheduledFor("OnTick", true))
    end
    if key == Keyboard.KEY_V then
        local player = getPlayer()
        -- local sound = WorldSoundManager:getBiggestSoundZomb(player:getX(), player:getY(), player:getZ(), false,
        --     player)
        -- df:df()
        -- ---@type NPC
        -- local testNPC = npcs["PZNS_ChrisTester"]
        -- local isoNPC = testNPC.npcIsoPlayerObject
        -- local survMap = transformIntoKahluaTable(IsoGameCharacter.getSurvivorMap())
        -- -- print(testNPC.stats:getIdleboredom())
        -- -- print(12 % 5)
        -- local lastSpotted = toLuaTable(testNPC.lastSpotted)
        -- local spottedList = toLuaTable(testNPC.spottedList)
        -- print(#spottedList)
        -- PZNS_ManageJobs.updatePZNSJobsTable("Custom", customJob)
        a = not a
        if a then
            Events.OnPlayerUpdate.Remove(playerUpdate)
            print("INACTIVE")
        else
            print("ACTIVE")
            Events.OnPlayerUpdate.Add(playerUpdate)
        end
    end
end


local function zomhit(zombie, attacker, bodypart, weapon)
    -- df:df()
end

-- Events.OnPlayerUpdate.Remove(zomhit)
-- Events.OnPlayerUpdate.Add(zomhit)
Events.OnKeyPressed.Remove(_key)
Events.OnKeyPressed.Add(_key)
