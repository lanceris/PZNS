local PZNS_SystemsManager = {}

local pairs = pairs
local floor = math.floor
local soundTimeOut = 3 * 1000    -- 250 millisecond
local soundForgetTime = 5 * 1000 -- 5 second
local soundReact = 1 * 1000      -- 1 second
local soundPrecision = 5

local function getEffectiveVolume(x, y, z, radius, volume, npcSurvivor, survIsoPos)
    if survIsoPos.z ~= z then return 0 end
    local hearableRadius = radius * (npcSurvivor.hearingMultiplier or 1)
    local distance2 = IsoUtils.DistanceToSquared(survIsoPos.x, survIsoPos.y, x, y)
    if distance2 >= hearableRadius * hearableRadius then return 0 end
    local intensity = distance2 / (hearableRadius * hearableRadius)
    -- TODO: check performance impact
    local srcSq = getCell():getGridSquare(x, y, z)
    local destSq = getCell():getGridSquare(survIsoPos.x, survIsoPos.y, survIsoPos.z)
    local srcRoom = srcSq:getRoom()
    local destRoom = destSq:getRoom()
    if srcSq and destSq and srcRoom ~= destRoom then
        intensity = intensity * 1.2
        if not srcRoom or not destRoom then
            intensity = intensity * 1.4
        end
    end
    intensity = 1 - intensity
    if intensity <= 0 then
        return 0
    else
        if intensity > 1 then intensity = 1 end
        return volume * intensity, distance2
    end
end

local function roundToBracket(v, bracket)
    local sign = (v >= 0 and 1) or -1
    bracket = bracket or 1
    return floor(v / bracket + sign * 0.5) * bracket
end

local function encodeSound(x, y, z)
    -- encode imprecisely (+- 5 tiles)
    return string.format("sound_%s_%s_%s",
        roundToBracket(x, soundPrecision), roundToBracket(y, soundPrecision), z)
end

function PZNS_SystemsManager.PZNS_SoundManager(x, y, z, radius, volume, source)
    -- process all sounds, not only by npcs?
    -- local npcSource = PZNS.Core.NPC.IsoPlayerRegistry[source]
    -- if not npcSource then return end
    for survivorID, npcSurvivor in pairs(PZNS.Core.NPC.registry) do
        -- skip self-produced sounds
        if source ~= npcSurvivor.npcIsoPlayerObject then
            local dt = getTimeInMillis()
            local survIso = npcSurvivor.npcIsoPlayerObject
            local survIsoPos = { x = survIso:getX(), y = survIso:getY(), z = survIso:getZ() }
            local effectiveVol, distSqr = getEffectiveVolume(x, y, z, radius, volume, npcSurvivor, survIsoPos)
            if effectiveVol > 0 then
                --can hear sound
                local encoded = encodeSound(x, y, z)
                -- handled in AIAgent
                local lastHeard = npcSurvivor.brain.lastHeardSound
                if not lastHeard[encoded] then
                    lastHeard[encoded] = {
                        x = x,
                        y = y,
                        z = z,
                        volRaw = volume,
                        vol = effectiveVol,
                        radius = radius,
                        distSqr = distSqr,
                        time = dt,
                        count = 1,
                        source = source
                    }
                else
                    lastHeard[encoded].count = lastHeard[encoded].count + 1
                end
                -- if dt >= lastHeard[encoded].time + soundTimeOut then
                npcSurvivor.brain.__newSound = true
                -- end
            end
        end
    end
end

return PZNS_SystemsManager
