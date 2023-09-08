local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_PresetsSpeeches = require("03_mod_core/PZNS_PresetsSpeeches");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")           --TODO: refactor, utils should not use managers
local PZNS_NPCGroupsManager = require("04_data_management/PZNS_NPCGroupsManager") --TODO: refactor, utils should not use managers
local PZNS_WorldUtils = require("02_mod_utils/PZNS_WorldUtils");
local weightedRng = require("02_mod_utils/PZNS_WeightedRandom")
local utils = require("02_mod_utils/PZNS_DataUtils")

local PZNS_CombatUtils = {};

--TODO: make all configurable
local spottingRange = 10
local hostileRelationBorder = 0
local bodyPartDamageMult = {
    [BodyPartType.Head:index()] = 5,
    [BodyPartType.Neck:index()] = 4,
    [BodyPartType.Torso_Upper:index()] = 3,
    [BodyPartType.Torso_Lower:index()] = 3,
    [BodyPartType.Groin:index()] = 2,
    [BodyPartType.UpperLeg_L:index()] = 2,
    [BodyPartType.UpperLeg_R:index()] = 2
}

-- v weapon skill level; > bodyPart
-- {"Hand", "ForeArm", "UpperArm", "Torso_Upper", "Torso_Lower", "Head", "Neck", "Groin", "UpperLeg", "LowerLeg", "Foot"}
local lvlToBodyPartDistribution = {
    { 0.01, 0.04, 0.08, 0.25, 0.3,  0.05, 0.01, 0.15, 0.08, 0.02, 0.01 }, -- 0
    { 0.04, 0.08, 0.16, 0.4,  0.45, 0.1,  0.02, 0.2,  0.12, 0.08, 0.06 }, -- 1
    { 0.1,  0.14, 0.2,  0.55, 0.6,  0.15, 0.05, 0.25, 0.16, 0.14, 0.1 },  -- 2
    { 0.16, 0.2,  0.26, 0.7,  0.75, 0.2,  0.1,  0.35, 0.24, 0.16, 0.12 }, -- 3
    { 0.2,  0.3,  0.36, 0.85, 0.9,  0.25, 0.12, 0.45, 0.32, 0.24, 0.16 }, -- 4
    { 0.24, 0.42, 0.46, 0.96, 1,    0.3,  0.15, 0.6,  0.38, 0.32, 0.24 }, -- 5
    { 0.3,  0.56, 0.6,  1,    1,    0.4,  0.2,  0.85, 0.44, 0.38, 0.3 },  -- 6
    { 0.45, 0.7,  0.72, 1,    1,    0.5,  0.25, 0.9,  0.56, 0.48, 0.44 }, -- 7
    { 0.56, 0.76, 0.86, 1,    1,    0.65, 0.35, 1,    0.76, 0.56, 0.5 },  -- 8
    { 0.64, 0.86, 1,    1,    1,    0.8,  0.45, 1,    0.86, 0.76, 0.64 }, -- 9
    { 0.8,  0.98, 1,    1,    1,    0.9,  0.65, 1,    1,    0.9,  0.8 },  -- 10
}
local lvlToBodyPartMeleeDistribution = lvlToBodyPartDistribution

---Calculate vision cone angle(?) of a `char`
--From zombie.iso.LightingJNI.java calculateVisionCone()
---@param char IsoPlayer
local function calculateVisionCone(char)
    if not char then return end
    local val
    local stats = char:getStats()
    local dayLight = getClimateManager():getDayLightStrength()
    local vehicle = char:getVehicle()
    local traits = char:getTraits()
    if not vehicle then
        val = -0.2
        val = val - stats:getFatigue() - 0.6
        if val > -0.2 then val = -0.2 end
        if stats:getFatigue() >= 1 then val = val - 0.2 end
        if char:getMoodles():getMoodleLevel(MoodleType.ToIndex(MoodleType.Panic)) == 4 then
            val = val - 0.2
        end
        if char:isInARoom() then
            val = val - 0.2 * (1 - dayLight)
        else
            val = val - 0.7 * (1 - dayLight)
        end
        if val < -0.9 then val = -0.9 end

        if traits:contains("EagleEyed") then
            val = val + 0.2 * dayLight
        end
        if traits:contains("NightVision") then
            val = val + 0.2 * (1 - dayLight)
        end
        if val > 0 then val = 0 end
    else
        val = 0.8 - 3 * (1 - dayLight)
        if vehicle:getHeadlightsOn() and vehicle:getHeadlightCanEmmitLight() then
            if val < -0.8 then val = -0.8 end
        else
            if val < -0.95 then val = -0.95 end
        end

        if traits:contains("NightVision") then
            val = val + 0.2 * (1 - dayLight)
        end
        if val > 1 then val = 1 end
    end
    return val
end

---Check if `observed` is in vision cone of `observant`
---From zombie.characters.IsoZombie.java canBeDeletedUnnoticed()
---@param observant IsoPlayer
---@param observed IsoGameCharacter
---@param maxDistance? float If passed - also use distance between `observant` and `observed` in calculation
---@return boolean canSee true if `obeservant` can see `observed`
---@return float? distance distance between 2 objects, returned is `maxDistance` provided
function PZNS_CombatUtils.canSee(observant, observed, maxDistance)
    --TODO: check for obstacles
    if not observant or not observed then return false end
    local dot = observant:getDotWithForwardDirection(observed:getX(), observed:getY())
    local cone = calculateVisionCone(observant) + 0.4 -- TODO: configurable
    if maxDistance then
        local distanceFromTarget = PZNS_WorldUtils.PZNS_GetDistanceBetweenTwoObjects(observant, observed);
        return (dot > -cone) and distanceFromTarget <= maxDistance, distanceFromTarget
    end
    return dot > -cone
end

---@param targetObject any
---@return boolean isValid true if `targetObject` is not instance of IsoGameCharacter
function PZNS_CombatUtils.PZNS_IsTargetInvalidForDamage(targetObject)
    -- Cows: If targetObject is not an IsoPlayer or IsoZombie, it is invalid for damage.
    -- if not (instanceof(targetObject, "IsoPlayer") == true or instanceof(targetObject, "IsoZombie") == true) then
    --     return true;
    -- end
    return not instanceof(targetObject, "IsoGameCharacter")
end

--- Cows: Toggle (active) to attack NPCs or (inactive) prevent friendly fire.
--- Cows: Call the IsoPlayerCoopPVP API to toggle local isoplayer pvp targeting.
function PZNS_CombatUtils.PZNS_TogglePvP()
    if (IsPVPActive == true) then
        IsPVPActive = false;
        PVPButton:setImage(PVPTextureOff)
    else
        IsPVPActive = true;
        PVPButton:setImage(PVPTextureOn)
    end
    IsoPlayer.setCoopPVP(IsPVPActive);
end

--- Cows: Added this function for calculating hit chance with range weapons
---@param selectedWeapon HandWeapon
---@param aimingLevel number
---@param missModifier number
function PZNS_CombatUtils.PZNS_CalculateHitChance(selectedWeapon, aimingLevel, missModifier)
    local weaponAimingModifier = selectedWeapon:getAimingPerkHitChanceModifier();
    local weaponHitChance = selectedWeapon:getHitChance();
    local skillHitChance = weaponAimingModifier * aimingLevel;
    local actualHitChance = weaponHitChance + skillHitChance - missModifier;

    return actualHitChance;
end

---Calculate part to hit, based on skill level
---@param isFirearm boolean
---@param aimingLevel integer
---@param meleeWeaponLevel integer correct skill (axe/blunt etc)
---@return BodyPartType partType BodyPartType which will receive damage
---@return number chance rolled value (might be used as chance)
local function calcHitPart(isFirearm, aimingLevel, meleeWeaponLevel)
    local doubleParts = {
        Hand = true,
        ForeArm = true,
        UpperArm = true,
        UpperLeg = true,
        LowerLeg = true,
        Foot = true
    }
    local partOrder = {
        "Hand", "ForeArm", "UpperArm", "Torso_Upper", "Torso_Lower", "Head", "Neck", "Groin", "UpperLeg", "LowerLeg",
        "Foot"
    }
    ---@type weightedRng
    local roll
    local tbl
    tbl = isFirearm and
        lvlToBodyPartDistribution[aimingLevel + 1] or
        lvlToBodyPartMeleeDistribution[meleeWeaponLevel + 1]
    if not tbl then error("mapping for found") end
    roll = weightedRng:new(tbl)
    ---@type integer
    local rolled = roll()
    local rolledPart = partOrder[rolled]
    local chance = tbl[rolled]
    if doubleParts[rolledPart] then
        -- 50/50 between left/right part
        rolledPart = ZombRand(2) == 0 and rolledPart .. "_L" or rolledPart .. "_R"
    end
    return BodyPartType.FromString(rolledPart), chance
end

---Change relations between NPCs after hostile encounter
---@param npcSurvivorVictim NPC
---@param npcSurvivorWielder NPC
---@param severity float damage severity (light bruise or missing ribs)
local function handleRelations(npcSurvivorVictim, npcSurvivorWielder, severity, canSee)
    -- Transient NPCs might become persistent in the future (e.g inviting to group)
    -- so I think it's better to handle relations regardless of NPC status
    -- and handle actual NPC state (periodic clean-ups of nil survivorIDs) separately
    --
    -- should wielder change opinion of victim?
    -- local relationWielderToVictim = PZNS_NPCsManager.getRelationTo(npcSurvivorWielder, npcSurvivorVictim)
    -- Cows: After reaching <= 0 affection
    if not canSee then
        -- TODO
        local text = "Ouch! What was that?!"
        if not npcSurvivorVictim.isPlayer then
            PZNS_NPCSpeak(npcSurvivorVictim, text, "Negative")
        else
            npcSurvivorVictim.npcIsoPlayerObject:Say(text)
        end
        return
    end

    local sameGroup = npcSurvivorVictim.groupID == npcSurvivorWielder.groupID
    local diff = 0
    if sameGroup then
        diff = -10
    else
        diff = -25
    end
    -- severity from 0 (no damage) to 2 (super large damage)
    -- even if no damage was done, this still affects relation to attacker
    diff = utils.clamp(severity, 0.25, 2)
    diff = diff * severity

    local args = {
        first = { npc = npcSurvivorVictim },
        second = { npc = npcSurvivorWielder },
        checks = false
    }
    local relationVictimToWielder = PZNS_NPCsManager.getRelationTo(args) or
        PZNS_NPCsManager.getAnonRelationTo(args) or
        npcSurvivorVictim.initialRelation

    local isVictimKnowsWielder = relationVictimToWielder ~= nil
    local wasHostile = relationVictimToWielder <= hostileRelationBorder
    args.diff = diff
    if isVictimKnowsWielder then
        PZNS_NPCsManager.changeRelationBetween(args)
        relationVictimToWielder = PZNS_NPCsManager.getRelationTo(args)
    else
        PZNS_NPCsManager.changeAnonymousRelationBetween(args)
        relationVictimToWielder = PZNS_NPCsManager.getAnonRelationTo(args)
    end
    local isHostile = relationVictimToWielder <= hostileRelationBorder

    -- apply multiplier based on damage severity


    if isHostile and sameGroup then
        --trigger exit group for victim as he's now hostile
        local victimID = npcSurvivorVictim.survivorID
        local groupID = npcSurvivorVictim.groupID
        PZNS_NPCGroupsManager.removeNPCFromGroup(groupID, victimID)
        PZNS_NPCsManager.unsetGroupID(victimID)
        --optionally also set to raider
    end

    -- region speak
    if not wasHostile and isHostile then
        -- relations dropped below `hostileRelationBorder` during this encounter
        PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
            npcSurvivorVictim, PZNS_PresetsSpeeches.PZNS_NeutralRevenge, "Hostile"
        )
    end

    if isHostile then
        PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
            npcSurvivorVictim, PZNS_PresetsSpeeches.PZNS_HostileHit, "Hostile"
        );
    else
        if sameGroup then
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivorVictim, PZNS_PresetsSpeeches.PZNS_FriendlyFire, "Friendly"
            )
        else
            -- Cows: Else complain about getting hit
            PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
                npcSurvivorVictim, PZNS_PresetsSpeeches.PZNS_NeutralHit, "Negative"
            )
        end
    end
    --endregion
end

---couldn't figure out purpose of this variable,
---but it's used when calculating hit in vanilla
---@param wielder IsoPlayer
---@param victim IsoGameCharacter
---@param weapon HandWeapon
---@return integer
local function calcModDelta(wielder, victim, weapon)
    local var55 = { x = wielder:getX(), y = wielder:getY() }
    local var36 = { x = victim:getX(), y = victim:getY() }

    var36.x = var36.x - var55.x
    var36.y = var36.y - var55.y
    local var37 = math.sqrt(var36.x * var36.x + var36.y * var36.y)
    local modDelta = 1
    local maxRange = weapon:getMaxRange(wielder)
    if var37 > maxRange then
        return 0
    end
    if not weapon:isRangeFalloff() then
        modDelta = var37 / maxRange
    end
    modDelta = modDelta * 2
    if modDelta < 0.3 then modDelta = 1 end
    if false then -- if crit with knife to zombie (unrelated to npc vs npc)
        modDelta = modDelta * 1000
        zombie:setCloseKilled(true)
    end
    return modDelta
end

---Calculate penetration of body part, based on `bodyPart` defence, weapon `offence` and random
---@param isAimedFirearm boolean
---@param victim IsoPlayer
---@param bodyPart BodyPart
---@param offence float `weapon` "stopping power/hit force"
---@return boolean passed `true` if `bodyPart` was penetrated
---@return float severity difference between rolled value and `bodyPart` defence - `offence`
local function calcPenetration(isAimedFirearm, victim, bodyPart, offence)
    local part = bodyPart:getType()
    local defence = victim:getBodyPartClothingDefense(part:index(), false, isAimedFirearm)
    defence = utils.clamp(defence - offence)
    if defence == 0 then defence = 1 end
    local deflect, rolled = utils.randomChance(defence, 0, 99, true)
    local severity = rolled / defence * 100 - 100
    return not deflect, severity
end

local function calcBonusDamage(isAimedFirearm, meleeWeaponLevel, rangedWeaponLevel, strengthLevel, distance)
    -- Cows: Add bonusDamage to weapon damage...
    -- Cows: Apply bonus damage based on strength... I haven't figure out how to get the weapon-related skill from the weapon...
    -- we can get it from from IsoPlayer apparently
    -- zombie.inventory.types.WeaponType.java
    local bonusDamage = 0;
    local strMult = strengthLevel --(1 + strengthLevel / 10)
    if not isAimedFirearm then
        bonusDamage = bonusDamage + meleeWeaponLevel * strMult
    else
        -- Cows: Update bonus damage to be based on aim level...
        distance = utils.clamp(distance, 1)
        bonusDamage = bonusDamage + rangedWeaponLevel + 10 / distance
    end
    return bonusDamage
end

local function calcBonusDamageApplyMult(severity)
    local bonusDamageApplyMult = 0
    if severity <= 0 then -- not penetrated
        if severity > -10 then
            --almost penetrated
            bonusDamageApplyMult = 0.75
        elseif severity > -25 then
            --heavy bruises
            bonusDamageApplyMult = 0.5
        elseif severity > -50 then
            --light bruises
            bonusDamageApplyMult = 0.25
        else
            -- no damage
            bonusDamageApplyMult = 0
        end
    else
        if severity < 50 then
            bonusDamageApplyMult = 1
        elseif severity < 100 then
            bonusDamageApplyMult = 1.25
        elseif severity < 150 then
            bonusDamageApplyMult = 1.5
        elseif severity < 200 then
            bonusDamageApplyMult = 1.75
        else
            bonusDamageApplyMult = 2
        end
    end
    return bonusDamageApplyMult
end

---Manage post-damage physical changes (holes, scratches, bleeding, pain)
---@param victim IsoPlayer NPC to receive changes
---@param weapon HandWeapon Weapon that inflicted damage
---@param bodypart BodyPart body part that received damage
---@param bodydamage BodyDamage to get initial pain levels for thump/scratch/bite
---@param severity float damage severity (light bruise or missing ribs)
local function handleStats(victim, wielder, weapon, bodypart, bodydamage, severity)
    -- https://projectzomboid.com/modding/zombie/characters/IsoGameCharacter.html#getBodyPartClothingDefense(java.lang.Integer,boolean,boolean)
    local stats = victim:getStats()
    local newPain = 0
    local bodyPartType = bodypart:getType()
    local index = bodyPartType:index()
    local painMod = BodyPartType.getPainModifyer(index)

    local bledingTimeMult = calcBonusDamageApplyMult(severity)

    local addHole = false
    local cutChance = 25
    local deepWoundChance = 20
    local scratchChance = 40
    local bulletWoundChance = 50
    if (weapon:getCategories():contains("Blunt") or weapon:getCategories():contains("SmallBlunt")) then
        -- Cows: Didn't seem right that blunt weapons would create holes on clothes 100% of the time...
        cutChance = 5
        scratchChance = 10
        if utils.randomChance(cutChance) then
            if utils.randomChance(deepWoundChance) then addHole = true end
            bodypart:setCut(true)
        elseif utils.randomChance(scratchChance) then
            bodypart:setScratched(true, true)
        else
            addHole = false
        end
        newPain = bodydamage:getInitialThumpPain() * painMod
    elseif not weapon:isAimedFirearm() then         -- sharp weapons
        addHole = true
        if utils.randomChance(deepWoundChance) then -- 20% ZombRand(0, 6) is 0-5 so will never get 6
            bodypart:generateDeepWound();
        elseif utils.randomChance(cutChance) then   -- 25%
            bodypart:setCut(true);
        elseif utils.randomChance(scratchChance) then
            bodypart:setScratched(true, true);
        else
            addHole = false
        end
        newPain = bodydamage:getInitialScratchPain() * painMod
    else
        addHole = true
        if utils.randomChance(bulletWoundChance) then
            bodypart:setHaveBullet(true, 0);
        else
            bodypart:generateDeepWound()
        end
        newPain = bodydamage:getInitialBitePain() * painMod
    end
    if addHole then
        victim:addHole(BloodBodyPartType.FromIndex(index))
        bodypart:setBleedingTime(bodypart:getBleedingTime() * bledingTimeMult)
    else
        -- no hole - no bleeding
        bodypart:setBleeding(false)
    end
    newPain = utils.clamp(stats:getPain() + newPain, 0, 100)
    stats:setPain(newPain)
    local staggerTime = weapon:getPushBackMod() * weapon:getKnockbackMod(wielder) * wielder:getShovingMod()
    victim:setStaggerTimeMod(staggerTime)
end

--- This should work for any two characters, not only player vs NPC?
--- WIP - Cows: Function is based on "SuperSurvivorPVPHandle()" in "SuperSurvivorUpdate.lua"
--- NOTE: not working with explode damage (bombs etc)
---@param wielder IsoPlayer player or NPC
---@param victim IsoPlayer NPC
---@param weapon HandWeapon
---@param damage float Initial damage came from SwipeStatePlayer, use as a reference only
function PZNS_CombatUtils.PZNS_CalculatePlayerDamage(wielder, victim, weapon, damage)
    if not PZNS_NPCsManager then
        PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager")
    end
    -- Cows: Check the the wielder or victim are IsoPlayer. We don't care about zombies in this function.
    if not instanceof(wielder, "IsoPlayer") or not instanceof(victim, "IsoPlayer") then return end
    -- Cows: Check if the victim is an NPC and calculate how much damage the npc will take from the weapon.
    ---@type survivorID
    local wielderSurvivorID = wielder:getModData().survivorID
    ---@type survivorID
    local victimSurvivorID = victim:getModData().survivorID
    local npcSurvivorWielder = PZNS_NPCsManager.getNPC(wielderSurvivorID)
    local npcSurvivorVictim = PZNS_NPCsManager.getNPC(victimSurvivorID)
    if not npcSurvivorWielder or not npcSurvivorVictim then
        error("wielder/victim NPCs not found!")
        return
    end
    if not weapon then error("Weapon not set!") end
    -- how can victim/wielder be not an NPC?
    -- if not victim:getIsNPC() then return end
    local canSee, distance = PZNS_CombatUtils.canSee(victim, wielder, spottingRange)
    if not npcSurvivorVictim.isPlayer then
        npcSurvivorVictim.attackTicks = 0; -- Cows: Force reset the NPC attack ticks when they're hit, this prevents them from piling on damage.
    end
    if wielder:isProne() then return end

    local isAimedFirearm = weapon:isAimedFirearm()
    local meleeWeaponLevel = wielder:getWeaponLevel()
    if weapon:getType() == "BareHands" then
        -- Cows: Perhaps we need to account for "martial artists" and stomping attacks ...
        meleeWeaponLevel = 1
    end
    local strengthLevel = wielder:getPerkLevel(Perks.FromString("Strength"))
    local rangedWeaponLevel = wielder:getPerkLevel(Perks.FromString("Aiming"))
    -- region determine body part to hit (and chance?)
    local bodyPartType, chance = calcHitPart(isAimedFirearm, rangedWeaponLevel, meleeWeaponLevel)
    local partIndex = bodyPartType:index()
    local bodydamage = victim:getBodyDamage()
    local bodypart = bodydamage:getBodyPart(bodyPartType)
    -- endregion
    local bodypartDamage = 0
    local isDefencePenetrated = false
    -- local isMiss, rolled = utils.randomChance(chance, 0, 99, true)
    -- local severity = rolled / chance * 100 - 100
    local severity

    -- not sure if it's fair and fun to play this way (applying additional chance to miss)
    -- if not isMiss then
    local critChance = wielder:calculateCritChance(victim)
    if utils.randomChance(critChance) then
        wielder:setCriticalHit(true)
    end

    -- Calculate weapon "stopping power/hit force"
    local modDelta = calcModDelta(wielder, victim, weapon)
    modDelta = utils.clamp(modDelta, 0, 1)
    local _init_dmg = ZombRandFloat(weapon:getMinDamage(), weapon:getMaxDamage())
    local offence = victim:processHitDamage(weapon, wielder, _init_dmg, false, modDelta)
    if wielder:isAimAtFloor() and wielder:isDoShove() then
        offence = offence * 2
    end
    isDefencePenetrated, severity = calcPenetration(isAimedFirearm, victim, bodypart, offence)

    -- region calc bodypart damage
    bodypartDamage = offence + damage
    local bonusDamage = calcBonusDamage(isAimedFirearm, meleeWeaponLevel, rangedWeaponLevel, strengthLevel, distance)
    local bonusDamageApplyMult = calcBonusDamageApplyMult(severity)
    if wielder:isCriticalHit() and not npcSurvivorVictim.isPlayer then
        bonusDamageApplyMult = bonusDamageApplyMult * 5 --TODO figure out good multiplier
    end
    bonusDamage = bonusDamage * bonusDamageApplyMult
    local partMult = bodyPartDamageMult[partIndex] or 1
    bodypartDamage = bodypartDamage * partMult
    bodypartDamage = bodypartDamage + bonusDamage
    --endregion

    --apply damage to body part
    bodydamage:AddDamage(partIndex, bodypartDamage)
    if bodypart:getHealth() <= 0 then
        -- if part health <= 0 and part is vital - kill
        local lethalParts = { Head = true, Neck = true, Torso_Upper = true, Torso_Lower = true, Groin = true }
        if lethalParts[BodyPartType.ToString(bodyPartType)] then
            bodydamage:ReduceGeneralHealth(110)
            -- this will update internal state of victim
            bodydamage:Update()
        end
    end

    if victim:isDead() or bodydamage:getOverallBodyHealth() <= 0 then
        --TODO: remove any data associated with victim as it's dead
        return
    end
    --handle scratches/holes/stats changes
    handleStats(victim, wielder, weapon, bodypart, bodydamage, severity)
    -- end


    if (not isAimedFirearm) and (weapon:getPushBackMod() > 0.3) then
        victim:StopAllActionQueue();
        victim:faceThisObject(wielder);
    end

    handleRelations(npcSurvivorVictim, npcSurvivorWielder, severity, canSee)
end

-- this function is called in `GunFighter_02Function.lua` but there's no def for it
-- triggered when armored NPC was eaten by zombies, reanimated and attacked other NPC
function Zombie_Armor_Check(victim, wielder, bodypart, weapon)
    return 2
end

return PZNS_CombatUtils;
