require("00_references/init")
require("09_mod_ui/views/PZNS_UIViewSettings")
require("09_mod_ui/views/PZNS_UIViewNPC")
require("09_mod_ui/views/PZNS_UIViewGroup")
require("09_mod_ui/views/PZNS_UIViewFaction")
require("09_mod_ui/views/PZNS_UIViewWork")
require("09_mod_ui/views/PZNS_UIViewZone")

local utilsData = require("02_mod_utils/PZNS_DataUtils")

PZNS.UI.const = PZNS.UI.const or { marginButton = 10 }

PZNS.UI.viewData = {
    _common = {
        buttonInactiveColor = { r = 0.137, g = 0.137, b = 0.137, a = 1 },
        buttonActiveColor = { r = 0.288, g = 0.288, b = 0.329, a = 1 },
    },
    settings = {
        name = "settings",
        title = "Settings",
        class = PZNS.UI.ViewSettings,
        btnTexure = getTexture("media/textures/UI/tab_settings.png")
    },
    npc = {
        name = "npc",
        title = "NPC Management",
        class = PZNS.UI.ViewNPC,
        btnTexure = getTexture("media/textures/UI/tab_npc.png")
    },
    group = {
        name = "group",
        title = "Group Management",
        class = PZNS.UI.ViewGroup,
        btnTexure = getTexture("media/textures/UI/tab_group.png")
    },
    faction = {
        name = "faction",
        title = "Faction Management",
        class = PZNS.UI.ViewFaction,
        btnTexure = getTexture("media/textures/UI/tab_faction.png")
    },
    work = {
        name = "work",
        title = "Jobs and Orders",
        class = PZNS.UI.ViewWork,
        btnTexure = getTexture("media/textures/UI/tab_work.png")
    },
    zone = {
        name = "zone",
        title = "Zones",
        class = PZNS.UI.ViewZone,
        btnTexure = getTexture("media/textures/UI/tab_zone.png")
    },
}

PZNS.UI.textures = {
    tools = {
        back = getTexture('media/textures/UI/btn_back.png'),
        search = getTexture('media/textures/UI/btn_search.png'),
        edit = getTexture('media/textures/UI/btn_edit.png'),
        faction = getTexture('media/textures/UI/btn_faction.png'),
        paste = getTexture('media/textures/UI/ctx_paste.png')
    }
}


PZNS.UI.settings = {}
local init_cfg = {
    main_window = {
        x = 100,
        y = 400,
        width = 500,
        height = 300
    },
    settings = {
        ui_scale = 1
    }
}
local config_name = "pzns_ui_config.lua"
PZNS.UI.settings.check = function(data)
    local resave = false
    for name, _ in pairs(init_cfg) do
        if data[name] == nil then
            data[name] = init_cfg[name]
            resave = true
        end
    end
    if resave == true then
        utilsData.save(config_name, data)
    end
end

PZNS.UI.settings.load = function()
    local status, config = pcall(utilsData.load, config_name)

    if not status or not config then
        config = init_cfg
        utilsData.save(config_name, config)
    end
    PZNS.UI.settings.check(config)
    return config
end

PZNS.UI.settings.save = function()
    local status = pcall(utilsData.save, config_name, PZNS.UI.config)
    if not status then
        -- config is corrupted, create new
        utilsData.save(config_name, init_cfg)
    end
end

PZNS.UI.settings.serialize = function()
    local window = PZNS.UI.mainWindow
    if not window then return end
    PZNS.UI.config.main_window = {
        x = window:getX(),
        y = window:getY(),
        w = window:getWidth(),
        h = window:getHeight(),
    }
end
