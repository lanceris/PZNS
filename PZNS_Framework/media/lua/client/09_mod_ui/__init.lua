require("00_references/__init")
require("09_mod_ui/views/PZNS_UIViewSettings")
require("09_mod_ui/views/PZNS_UIViewNPC")
require("09_mod_ui/views/PZNS_UIViewGroup")
require("09_mod_ui/views/PZNS_UIViewFaction")
require("09_mod_ui/views/PZNS_UIViewWork")
require("09_mod_ui/views/PZNS_UIViewZone")

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
