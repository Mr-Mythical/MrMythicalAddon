--[[
ParsingData.lua - Locale-safe Tooltip Filter Strings

Purpose: Builds match lists from Blizzard globals and Challenge Mode APIs
so hide-filters work on every client language. English strings are fallbacks only.
Dependencies: C_ChallengeMode, C_MythicPlus (optional)
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

local ParsingData = {
    AFFIX_STRINGS = {},
    DURATION_STRINGS = {},
    UNWANTED_STRINGS = {},
    KNOWN_AFFIX_IDS = {
        9, 10, 148, 158, 159, 160, 147, 152, 153, 162,
    },
}

local function addUnique(list, index, value)
    if type(value) ~= "string" or value == "" then
        return
    end
    if index[value] then
        return
    end
    index[value] = true
    table.insert(list, value)
end

local function addGlobal(list, index, globalName, englishFallback)
    local value = rawget(_G, globalName)
    if type(value) == "string" and value ~= "" then
        local plain = value:gsub("%%%d*%$?[sd]", ""):gsub("%%s", ""):gsub("%%d", "")
        plain = plain:gsub("%s+$", ""):gsub("^%s+", "")
        if plain ~= "" then
            addUnique(list, index, plain)
        else
            addUnique(list, index, value)
        end
    elseif englishFallback then
        addUnique(list, index, englishFallback)
    end
end

local function addAffixName(list, index, affixID)
    if not affixID or affixID == 0 then
        return
    end
    if not (C_ChallengeMode and C_ChallengeMode.GetAffixInfo) then
        return
    end
    local name = C_ChallengeMode.GetAffixInfo(affixID)
    if type(name) == "string" and name ~= "" then
        addUnique(list, index, name)
        local lead = name:match("^([^:]+)")
        if lead and lead ~= name then
            lead = lead:gsub("%s+$", "")
            if lead ~= "" then
                addUnique(list, index, lead)
            end
        end
    end
end

function ParsingData.refresh()
    local affixList, affixIndex = {}, {}
    local durationList, durationIndex = {}, {}
    local unwantedList, unwantedIndex = {}, {}

    addGlobal(unwantedList, unwantedIndex, "ITEM_SOULBOUND", "Soulbound")
    addGlobal(unwantedList, unwantedIndex, "ITEM_UNIQUE", "Unique")
    addGlobal(unwantedList, unwantedIndex, "ITEM_UNIQUE_EQUIPPABLE", nil)
    addGlobal(unwantedList, unwantedIndex, "ITEM_UNIQUE_MULTIPLE", nil)
    addGlobal(unwantedList, unwantedIndex, "CHALLENGE_MODE_KEYSTONE_NAME", nil)
    addUnique(unwantedList, unwantedIndex, "Font of Power")

    addGlobal(durationList, durationIndex, "SPELL_DURATION", nil)
    addGlobal(durationList, durationIndex, "AUCTION_DURATION", nil)
    addGlobal(durationList, durationIndex, "POWER_TYPE_DURATION", nil)
    if #durationList == 0 then
        addUnique(durationList, durationIndex, "Duration")
    end

    addGlobal(affixList, affixIndex, "CHALLENGE_MODE_DEPLETED_KEYSTONE", nil)
    addUnique(affixList, affixIndex, "Dungeon Modifiers:")
    addUnique(affixList, affixIndex, "Lindormi's")

    for _, affixID in ipairs(ParsingData.KNOWN_AFFIX_IDS) do
        addAffixName(affixList, affixIndex, affixID)
    end

    if C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
        local ok, current = pcall(C_MythicPlus.GetCurrentAffixes)
        if ok and type(current) == "table" then
            for _, entry in ipairs(current) do
                local id = type(entry) == "table" and (entry.id or entry.affixID) or entry
                addAffixName(affixList, affixIndex, id)
            end
        end
    end

    ParsingData.AFFIX_STRINGS = affixList
    ParsingData.DURATION_STRINGS = durationList
    ParsingData.UNWANTED_STRINGS = unwantedList
end

function ParsingData.addAffixIDs(affixIDs)
    if type(affixIDs) ~= "table" then
        return
    end
    local index = {}
    for _, name in ipairs(ParsingData.AFFIX_STRINGS) do
        index[name] = true
    end
    for _, id in ipairs(affixIDs) do
        addAffixName(ParsingData.AFFIX_STRINGS, index, id)
    end
end

ParsingData.refresh()

MrMythical.ParsingData = ParsingData
_G.MrMythical = MrMythical
