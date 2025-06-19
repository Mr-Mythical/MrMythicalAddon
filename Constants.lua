local MrMythical = MrMythical or {}

MrMythical.Constants = {
    COLORS = {
        WHITE = "|cffffffff",
        GOLD = "|cffffcc00",
        GREEN = "|cff00ff00",
        GRAY = "|cff808080",
        BLUE = "|cff0088ff",
        RED = "|cffff0000",
    },

    AFFIX_STRINGS = {
        "Fortified",
        "Tyrannical",
        "Xal'atath",
        "Dungeon Modifiers:"
    },

    DURATION_STRINGS = {
        "Duration"
    },

    UNWANTED_STRINGS = {
        "Font of Power",
        "Soulbound",
        "Unique"
    },

    REGION_MAP = {
        [1] = "us",
        [2] = "kr",
        [3] = "eu",
        [4] = "tw",
        [5] = "cn"
    },

    MYTHIC_MAPS = {
        { id = 506, name = "Cinderbrew Meadery" },
        { id = 504, name = "Darkflame Cleft" },
        { id = 370, name = "Mechagon Workshop" },
        { id = 525, name = "Operation: Floodgate" },
        { id = 499, name = "Priory of the Sacred Flame" },
        { id = 247, name = "The MOTHERLODE!!" },
        { id = 500, name = "The Rookery" },
        { id = 382, name = "Theater of Pain" }
    }
}

_G.MrMythical = MrMythical