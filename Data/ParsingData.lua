--[[
ParsingData.lua - Text Parsing Constants

Purpose: Contains strings and patterns used for tooltip text parsing and filtering
Dependencies: None
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

MrMythical.ParsingData = {
    AFFIX_STRINGS = {
        "Fortified",
        "Tyrannical",
        "Xal'atath",
        "Dungeon Modifiers:",
        "Explosive",
        "Bolstering",
        "Grievous",
        "Eternus",
        "Teeming",
    },

    DURATION_STRINGS = {
        "Duration"
    },

    UNWANTED_STRINGS = {
        "Font of Power",
        "Soulbound",
        "Unique"
    }
}

_G.MrMythical = MrMythical
