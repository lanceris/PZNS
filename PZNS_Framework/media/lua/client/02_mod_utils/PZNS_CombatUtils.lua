local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs");
local PZNS_PresetsSpeeches = require("03_mod_core/PZNS_PresetsSpeeches");
local PZNS_NPCsManager = require("04_data_management/PZNS_NPCsManager") --TODO: refactor, utils should not use managers
local weightedRng = require("02_mod_utils/PZNS_WeightedRandom")

local PZNS_CombatUtils = {};

local hostileRelationBorder = 0 --TODO: make configurable

---comment
---@param targetObject IsoGameCharacter?
---@return boolean isValid true if `targetObject` is instance of IsoGameCharacter
function PZNS_CombatUtils.PZNS_IsTargetInvalidForDamage(targetObject)
    -- Cows: If targetObject is not an IsoPlayer or IsoZombie, it is invalid for damage.
    -- if not (instanceof(targetObject, "IsoPlayer") == true or instanceof(targetObject, "IsoZombie") == true) then
    --     return true;
    -- end
    if not instanceof(targetObject, "IsoGameCharacter") then
        return true
    end

    return false;
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

-- v weapon skill level; > bodyPart
local lvlToBodyPart = {
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

local lvlToBodyPartMelee = lvlToBodyPart
---Calculate part to hit, based on
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
    tbl = isFirearm and lvlToBodyPart[aimingLevel + 1] or lvlToBodyPartMelee[meleeWeaponLevel + 1]
    if not tbl then error("mapping for found") end
    roll = weightedRng:new(tbl)
    ---@type float, integer
    local rolled = roll()
    local rolledPart = partOrder[rolled]
    local chance = tbl[rolled]
    if doubleParts[rolledPart] then
        -- 50/50 between left/right part
        rolledPart = ZombRand(2) == 0 and rolledPart .. "_L" or rolledPart .. "_R"
    end
    return BodyPartType.FromString(rolledPart), chance
end

local function handleRelations(npcSurvivorVictim, npcSurvivorWielder, missedByPerc)
    -- TODO: use missedByPerc in calc?
    -- check if NPC is persistent (otherwise either set to persistent or ignore handling relations?)
    local args = {
        first = { npc = npcSurvivorVictim },
        second = { npc = npcSurvivorWielder },
        checks = false
    }
    local relationVictimToWielder = PZNS_NPCsManager.getRelationTo(args)
    local isVictimKnowsWielder = relationVictimToWielder ~= nil
    if not relationVictimToWielder then
        -- check if victim seen wielder
        relationVictimToWielder = PZNS_NPCsManager.getAnonRelationTo(args)
        if not relationVictimToWielder then
            -- never seen
            args.diff = -25 --TODO: determine based on damage type/amount etc
            PZNS_NPCsManager.changeAnonymousRelationBetween(args)
            relationVictimToWielder = args.diff
        end
    end
    local diff
    -- should wielder change opinion of victim?
    -- local relationWielderToVictim = PZNS_NPCsManager.getRelationTo(npcSurvivorWielder, npcSurvivorVictim)
    -- Cows: After reaching <= 0 affection
    local sameGroup = npcSurvivorVictim.groupID == npcSurvivorWielder.groupID
    local wasHostile = relationVictimToWielder <= hostileRelationBorder
    --change relations - -10 for group members and -25 for others
    if sameGroup then
        diff = -10
    else
        diff = -25
    end
    args.diff = diff
    if isVictimKnowsWielder then
        PZNS_NPCsManager.changeRelationBetween(args)
        relationVictimToWielder = PZNS_NPCsManager.getRelationTo(args)
    else
        PZNS_NPCsManager.changeAnonymousRelationBetween(args)
        relationVictimToWielder = PZNS_NPCsManager.getAnonRelationTo(args)
    end
    local isHostile = relationVictimToWielder <= hostileRelationBorder

    if not wasHostile and isHostile then
        -- relations dropped below `hostileRelationBorder` during this encounter
        PZNS_UtilsNPCs.PZNS_UseNPCSpeechTable(
            npcSurvivorVictim, PZNS_PresetsSpeeches.PZNS_NeutralRevenge, "Hostile"
        )
        if sameGroup then
            --TODO: trigger exit group for victim as he's now hostile
        end
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
end

-- NOTE: server-side damage calculations done in zombie.characters.BodyDamage.java DamageFromWeapon()
local function handleDamage()

end

---clamp `n` between `_min` (0) and `max` (100)
---@param n number
---@param _min number?
---@param _max number?
---@return number result
local function clamp(n, _min, _max)
    if not n then error("Missing value in clamp()") end
    _min = _min or 0
    _max = _max or 100
    return math.min(math.max(n, _min), _max)
end

---roll chance from `_min` (1) to `_max` (100) for `oneIn`
---@param oneIn integer chance to check ((`onein`/(`_max`+1-`_min`) * 100%)
---@param _min integer? minimum value, inclusive
---@param _max integer? maximum value, inclusive
---@param retRoll boolean? if true - return `rolled` in 2nd arg
---@return boolean passed whether roll was successful
---@return integer? rolled rolled value, returned if `retRoll=true`
local function randomChance(oneIn, _min, _max, retRoll)
    _min = _min or 1
    _max = _max or 100
    _max = _max + 1 -- ZombRand 2nd arg is exclusive
    oneIn = clamp(oneIn, _min, _max)
    local rolled = ZombRand(_min, _max)
    local passed = rolled < oneIn
    if retRoll then
        return passed, rolled
    else
        return passed
    end
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

---Calculate penetration of body part
---@param weapon HandWeapon
---@param victim IsoPlayer
---@param bodyPart BodyPart
---@return boolean passed
---@return float missedByPerc
local function calcPenetration(weapon, victim, bodyPart, offence)
    local part = bodyPart:getType()
    local defence = victim:getBodyPartClothingDefense(part:index(), false, weapon:isAimedFirearm())
    defence = clamp(defence - offence)
    local deflect, rolled = randomChance(defence, 0, 99, true)
    -- print(string.format("Defence: %s | Offence: %s | Rolled: %s | Part: %s", defence, offence, rolled, t))
    local missedByPerc = rolled / defence * 100 - 100
    return not deflect, missedByPerc
end


local function calcBonusDamage(isAimedFirearm, meleeWeaponLevel, rangedWeaponLevel, strengthLevel)
    -- Cows: Add bonusDamage to weapon damage...
    -- Cows: Apply bonus damage based on strength... I haven't figure out how to get the weapon-related skill from the weapon...
    -- we can get it from from IsoPlayer apparently
    -- zombie.inventory.types.WeaponType.java
    local bonusDamage = 0;
    local strMult = (1 + strengthLevel / 10)
    if not isAimedFirearm then
        bonusDamage = bonusDamage + meleeWeaponLevel * strMult
    else
        -- Cows: Update bonus damage to be based on aim level...
        bonusDamage = bonusDamage + rangedWeaponLevel
    end
    return bonusDamage
end

local function calcBonusDamageApplyMult(missedByPerc)
    local bonusDamageApplyMult = 0
    if missedByPerc <= 0 then -- not penetrated
        if missedByPerc > -10 then
            --almost penetrated
            bonusDamageApplyMult = 0.75
        elseif missedByPerc > -25 then
            --heavy bruises + scratch probably?
            bonusDamageApplyMult = 0.5
        elseif missedByPerc > -50 then
            --light bruises
            bonusDamageApplyMult = 0.25
        else
            -- no damage
            bonusDamageApplyMult = 0
        end
    else
        if missedByPerc < 50 then
            bonusDamageApplyMult = 1
        elseif missedByPerc < 100 then
            bonusDamageApplyMult = 1.25
        elseif missedByPerc < 150 then
            bonusDamageApplyMult = 1.5
        elseif missedByPerc < 200 then
            bonusDamageApplyMult = 1.75
        else
            bonusDamageApplyMult = 2
        end
    end
    return bonusDamageApplyMult
end

---@param a {victim:IsoPlayer, weapon: HandWeapon, partIndex:integer, bodypart:BodyPart, bodydamage: BodyDamage, missedByPerc:float}
local function handleStats(a)
    --TODO: use missedByPerc in calc
    -- https://projectzomboid.com/modding/zombie/characters/IsoGameCharacter.html#getBodyPartClothingDefense(java.lang.Integer,boolean,boolean)
    local stats = a.victim:getStats()
    local newPain = 0
    local painMod = BodyPartType.getPainModifyer(a.partIndex)
    local addHole = false
    if (a.weapon:getCategories():contains("Blunt") or a.weapon:getCategories():contains("SmallBlunt")) then
        -- Cows: Didn't seem right that blunt weapons would create holes on clothes 100% of the time...
        if randomChance(25) then
            if randomChance(20) then addHole = true end -- 5% total
            a.bodypart:setCut(true)
        else
            a.bodypart:setScratched(true, true)
        end
        newPain = a.bodydamage:getInitialThumpPain() * painMod
    elseif not a.weapon:isAimedFirearm() then
        addHole = true
        if randomChance(20) then     -- 20% ZombRand(0, 6) is 0-5 so will never get 6
            a.bodypart:generateDeepWound();
        elseif randomChance(35) then -- 35%
            a.bodypart:setCut(true);
        else
            a.bodypart:setScratched(true, true); -- 45%
        end
        newPain = a.bodydamage:getInitialScratchPain() * painMod
    else
        addHole = true
        a.bodypart:setHaveBullet(true, 0);
        newPain = a.bodydamage:getInitialBitePain() * painMod
    end
    if addHole then a.victim:addHole(BloodBodyPartType.FromIndex(a.partIndex)) end
    newPain = clamp(stats:getPain() + newPain, 0, 100)
    stats:setPain(newPain)
end

-- adaptation from IsoGameCharacter Hit()
-- victim(this) is being hit by wielder with weapon
---@param victim any
---@param wielder IsoPlayer
---@param weapon any
---@param initialDamage any
---@return integer
local function Hit(victim, wielder, weapon, initialDamage)
    local var6 = false
    local var4 = false
    local var5 = calcModDelta(wielder, victim, weapon)
    -- if wielder is pushing someone and not stomping on the ground
    if wielder:isDoShove() and not wielder:isAimAtFloor() then
        var4 = true
        var5 = var5 * 1.5
    end
    -- triggerEvent("OnWeaponHitCharacter", wielder, victim, weapon, initialDamage)
    if false then -- if triggerHook("WeaponHitCharacter", wielder, victim, weapon, initialDamage)
        return 0
    elseif victim:avoidDamage() then
        victim:setAvoidDamage(false)
        return 0
    else
        if victim:getNoDamage() then
            var4 = true
            victim:setNoDamage(true)
        end

        if instanceof(victim, "IsoSurvivor") and not victim:getEnemyList():contains(wielder) then
            error("This should not get triggered?")
            victim:getEnemyList():add(wielder)
        end

        victim:setStaggerTimeMod(weapon:getPushBackMod() * weapon:getKnockbackMod(wielder) * wielder:getShovingMod())

        wielder:addWorldSoundUnlessInvisible(5, 1, false)
        -- region vectors fun
        local hitDir = victim:getHitDir()
        hitDir:setX(victim:getX())
        hitDir:setY(victim:getY())
        victim:setHitDir(hitDir)
        local vector = victim:getHitDir()
        vector:setX(vector:getX() - wielder:getX())
        vector = victim:getHitDir()
        vector:setY(vector:getY() - wielder:getY())
        victim:getHitDir():normalize()
        vector = victim:getHitDir()
        vector:setX(vector:getX() * weapon:getPushBackMod())
        vector = victim:getHitDir()
        vector:setY(vector:getY() * weapon:getPushBackMod())
        -- victim:getHitDir():rotate(weapon:getHitAngleMod()) -- can't get HitAngleMod
        --endregion
        victim:setAttackedBy(wielder)

        local var12 = initialDamage
        if not var6 then
            var12 = victim:processHitDamage(weapon, wielder, initialDamage, var4, var5)
        end

        local var8 = 0
        -- if two handed weapon held in one hand only
        if weapon:isTwoHandWeapon() and
            wielder:getPrimaryHandItem() ~= weapon or
            wielder:getSecondaryHandItem() ~= weapon then
            var8 = weapon:getWeight() / 1.5 / 10
        end

        local var9 = (weapon:getWeight() * 0.28 *
            weapon:getFatigueMod(wielder) *
            victim:getFatigueMod() *
            weapon:getEnduranceMod() * 0.3 + var8) * 0.04
        if wielder:isAimAtFloor() and wielder:isDoShove() then
            var9 = var9 * 2
        end
        local var10
        if weapon:isAimedFirearm() then
            var10 = var12 * 0.7
        else
            var10 = var12 * 0.15
        end

        local vH = victim:getHealth()
        if vH < var12 then var10 = vH end

        local var11 = var10 / weapon:getMaxDamage()
        var11 = math.min(var11, 1)

        if victim:isCloseKilled() then var11 = 0.2 end
        if weapon:isUseEndurance() then
            var11 = var12 <= 0 and 1 or var11
            local stats = wielder:getStats()
            stats:setEndurance(stats:getEndurance() - var9 * var11)
        end
        if not var4 then
            if weapon:isAimedFirearm() then
                victim:setHealth(victim:getHealth() - var12 * 0.7)
            else
                victim:setHealth(victim:getHealth() - var12 * 0.15)
            end
        end
        if victim:isDead() then
            if not victim:isOnKillDone() and victim:shouldDoInventory() then
                victim:Kill(wielder)
            end
            wielder:setZombieKills(wielder:getZombieKills() + 1);
            --TODO: register kill and increase counter of killed NPCs
        else
            if weapon:isSplatBloodOnNoDeath() then
                victim:splatBlood(2, 0.2)
            end
            if weapon:isKnockBackOnNoDeath() then -- and wielder:getXP() then
                --TODO: add Strength XP
            end
        end
        victim:hitConsequences(weapon, wielder, var4, var12, var6)
        if weapon:isAimedFirearm() then
            var12 = var12 * 0.7
        else
            var12 = var12 * 0.15
        end
        return var12
    end
end

local bodyPartDamageMult = {
    [BodyPartType.Head:index()] = 4,
    [BodyPartType.Neck:index()] = 5,
    [BodyPartType.Torso_Upper:index()] = 2,
    [BodyPartType.Torso_Lower:index()] = 3,
    [BodyPartType.Groin:index()] = 2,
    [BodyPartType.UpperLeg_L:index()] = 2,
    [BodyPartType.UpperLeg_R:index()] = 2
}

function Zombie_Armor_Check(victim, wielder, bodypart, weapon)
    -- this function is called in GunFighter_02Function.lua but there's no def for it
    -- triggered when armored NPC was eaten by zombies, reanimated and attacked other NPC
    return 2
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
    if not npcSurvivorVictim.isPlayer then
        npcSurvivorVictim.attackTicks = 0; -- Cows: Force reset the NPC attack ticks when they're hit, this prevents them from piling on damage.
    end

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
    local isMiss, rolled = randomChance(chance, 0, 99, true)
    local missedByPerc = rolled / chance * 100 - 100

    -- not sure if it's fair and fun to play this way, need testing
    if not isMiss then
        local critChance = wielder:calculateCritChance(victim)
        if randomChance(critChance) then
            wielder:setCriticalHit(true)
        end

        local modDelta = calcModDelta(wielder, victim, weapon)
        modDelta = clamp(modDelta, 0, 1)
        local _init_dmg = ZombRandFloat(weapon:getMinDamage(), weapon:getMaxDamage())
        local offence = victim:processHitDamage(weapon, wielder, _init_dmg, false, modDelta)

        isDefencePenetrated, missedByPerc = calcPenetration(weapon, victim, bodypart, offence)

        -- region calc bodypart damage
        bodypartDamage = offence
        local bonusDamage = calcBonusDamage(isAimedFirearm, meleeWeaponLevel, rangedWeaponLevel, strengthLevel)
        local bonusDamageApplyMult = calcBonusDamageApplyMult(missedByPerc)
        if wielder:isCriticalHit() and not npcSurvivorVictim.isPlayer then
            bonusDamageApplyMult = bonusDamageApplyMult * 5 --TODO figure out good multiplier
        end
        bonusDamage = bonusDamage * bonusDamageApplyMult
        local partMult = bodyPartDamageMult[partIndex] or 1
        bodypartDamage = bodypartDamage * partMult
        bodypartDamage = bodypartDamage + bonusDamage
        --endregion

        -- those 2 giving pretty similar results
        -- local dmg = Hit(victim, wielder, weapon, _init_dmg)
        -- local res = { bodypartDamage, dmg * partMult + bonusDamage }

        --apply damage to body part
        bodydamage:AddDamage(partIndex, bodypartDamage)
        if bodypart:getHealth() <= 0 then
            -- if part health <= 0 and part is vital - kill
            local lethalParts = { Head = true, Neck = true, Torso_Upper = true, Torso_Lower = true, Groin = true }
            if lethalParts[BodyPartType.ToString(bodyPartType)] then
                bodydamage:ReduceGeneralHealth(110)
            end
        end

        if bodydamage:getOverallBodyHealth() <= 0 then
            bodydamage:Update() -- this will update internal state of victim
            -- remove any data associated with victim as it's dead

            return
        end
    end

    --handle scratches/holes/stats changes

    if (not isAimedFirearm) and (weapon:getPushBackMod() > 0.3) then
        victim:StopAllActionQueue();
        victim:faceThisObject(wielder);
    end
    local _args = {
        victim = victim,
        weapon = weapon,
        partIndex = partIndex,
        bodypart = bodypart,
        bodydamage = bodydamage,
        missedByPerc = missedByPerc,
    }
    handleStats(_args)

    handleRelations(npcSurvivorVictim, npcSurvivorWielder, missedByPerc)
end

--TODO: for npc vision cone
-- also check IsoGameCharacter.isBehind()
local function getDotSide(char, mouseX, mouseY)
    ---@type Vector2
    local lookVector = char:getLookVector(Vector2.new())
    local lookVX, lookVY = lookVector:getX(), lookVector:getY()

    local charX, charY, charZ, charNum = char:getX(), char:getY(), char:getZ(), char:getPlayerNum()

    ---@type Vector2
    local charVector = Vector2.new(charX, charY)
    local charVX, charVY = charVector:getX(), charVector:getY()

    local objX = screenToIsoX(charNum, mouseX, mouseY, charZ)
    local objY = screenToIsoY(charNum, mouseX, mouseY, charZ)

    ---@type Vector2
    local objVector = Vector2.new(objX - charVX, objY - charVY)
    objVector:normalize()

    local dot = Vector2.dot(objVector:getX(), objVector:getY(), lookVX, lookVY)

    local results = ""

    if dot > 0.0 then
        results = results .. "FRONT"
    else --if (dot < 0.0 and dot < -0.5) then
        results = results .. "BEHIND"
    end

    results = results .. "|"

    local lcVX, lcVY = charVX + lookVX, charVY + lookVY
    local dotSide = (objX - charVX) * (lcVY - charVY) - (objY - charVY) * (lcVX - charVX)

    if dotSide > 0.0 then
        results = results .. "LEFT"
    else
        results = results .. "RIGHT"
    end

    return results, "" .. dot .. "|" .. dotSide
end

return PZNS_CombatUtils;
