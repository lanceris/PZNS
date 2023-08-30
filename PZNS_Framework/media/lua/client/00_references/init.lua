PZNS = PZNS or {}
PZNS.Core = PZNS.Core or {}
PZNS.Context = PZNS.Context or {}
PZNS.Context.Debug = PZNS.Context.Debug or {}
PZNS.UI = PZNS.UI or {}

PZNS.Core.NPC = {}
PZNS.Core.Group = {}
PZNS.Core.Faction = {}
PZNS.Core.Zone = {}

---@type table<survivorID, NPC>
PZNS.Core.NPC.registry = {}
---@type table<groupID, Group>
PZNS.Core.Group.registry = {}
---@type table<factionID, Faction>
PZNS.Core.Faction.registry = {}
---@type table<zoneID, Zone>
PZNS.Core.Zone.registry = {}


---Unique identifier for survivor
---@alias survivorID string
---Unique identifier for group
---@alias groupID string
---Unique identifier for faction
---@alias factionID string
---Unique identifier for zone
---@alias zoneID string
---Number with decimal
---@alias float number

---@class IsoObject
---@field getModData fun(): table --<string|number, number|string|boolean|table|nil>
---@field getSquare fun(): IsoGridSquare
---@class IsoMovingObject:IsoObject

---@class IsoGameCharacter:IsoMovingObject
---@field getX fun(): integer X position
---@field getY fun(): integer Y position
---@field getZ fun(): integer Z position
---@field Say fun(self,string:string): nil
---@field getPerkLevel fun(self, perk:Perk): integer
---@field getBodyDamage fun(self): BodyDamage
---@field getBodyPartClothingDefense fun(self, index:integer, isBiteDefence:boolean, isBulletDefence:boolean): float
---@field addHole fun(self, bloodBodyPartType:BloodBodyPartType): boolean
---@field getStats fun(self): Stats
---@field StopAllActionQueue fun(self)
---@field faceThisObject fun(self, o:IsoObject)
---@field getIsNPC fun(self): boolean
---@field getWeaponLevel fun(self): integer

---@class IsoPlayer:IsoGameCharacter
---@field isAlive fun(): boolean
---@field save fun(self,filename:string)
---@class IsoZombie:IsoGameCharacter

---@class ArrayList
---@field size fun(self): integer
---@field get fun(self, index:integer): any
---@field contains fun(self, any): boolean

---zombie\iso\IsoGridSquare.java
---@class IsoGridSquare
---@field getX fun(): integer X position
---@field getY fun(): integer Y position
---@field getZ fun(): integer Z position

---@class ItemContainer
---@class InventoryItem
---@field getType fun(self): string
---@class HandWeapon:InventoryItem
---@field getAimingPerkHitChanceModifier fun(self): float
---@field getHitChance fun(self): integer
---@field getCategories fun(self): ArrayList
---@field isAimedFirearm fun(self): boolean
---@field getMaxDamage fun(self): float
---@field getPushBackMod fun(self): float
---@field isRangeFalloff fun(self): boolean
---@field getMaxRange fun(self, isoPlayer:IsoPlayer): float

---@class Perk
---@class BodyPart
---@field generateDeepWound fun(self)
---@field setCut fun(self, addBleeding:boolean, addInfection25?:boolean)
---@field setScratched fun(self, addBleeding:boolean, addInfection7?:boolean)
---@field setHaveBullet fun(self, haveBullet:boolean, doctorLevel:integer)

---@class TextDrawObject


---@alias BodyPartType BodyPartType
---|'"Hand_L"'
---|'"Hand_R"'
---|'"ForeArm_L"'
---|'"ForeArm_R"'
---|'"UpperArm_L"'
---|'"UpperArm_R"'
---|'"Torso_Upper"'
---|'"Torso_Lower"'
---|'"Head"'
---|'"Neck"'
---|'"Groin"'
---|'"UpperLeg_L"'
---|'"UpperLeg_R"'
---|'"LowerLeg_L"'
---|'"LowerLeg_R"'
---|'"Foot_L"'
---|'"Foot_R"'
---|'"MAX"'

---@class BodyDamage
---@field getBodyPart fun(self, bodyPartType:BodyPartType):BodyPart
---@field AddDamage fun(self, bodyPartType:BodyPartType, damage:float)
---@field getInitialThumpPain fun(self): float
---@field getInitialScratchPain fun(self): float
---@field getInitialBitePain fun(self): float

---@class BloodBodyPartType
---@field FromIndex fun(self, index:integer): BloodBodyPartType
---@class Stats
---@field setPain fun(self, amount:float)
---@field getPain fun(self): float

--FIXME
---@class Faction
