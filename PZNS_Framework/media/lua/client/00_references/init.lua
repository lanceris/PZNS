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

---@class IsoGameCharacter
---@field Say fun(self:IsoGameCharacter,string:string): nil
---@class IsoPlayer:IsoGameCharacter
---@field isAlive fun(): boolean
---@field save fun(self:IsoPlayer,filename:string)

---zombie\iso\IsoGridSquare.java
---@class IsoGridSquare
---@field getX fun(): integer X position
---@field getY fun(): integer Y position
---@field getZ fun(): integer Z position

---@class ItemContainer

--FIXME
---@class Faction
