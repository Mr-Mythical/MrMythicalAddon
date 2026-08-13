--[[
RewardsData.lua - Mythic+ Reward Tables

Purpose: Contains gear, vault, and crest reward data for all keystone levels
Dependencies: None
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

-- Midnight Season 2 (Mistcrest) reward ladder.
MrMythical.RewardsData = {
    DUNGEON_GEAR = {
        { itemLevel = 295, upgradeTrack = "Champion 2" },  -- Key Level 2
        { itemLevel = 295, upgradeTrack = "Champion 2" },  -- Key Level 3
        { itemLevel = 298, upgradeTrack = "Champion 3" },  -- Key Level 4
        { itemLevel = 302, upgradeTrack = "Champion 4" },  -- Key Level 5
        { itemLevel = 305, upgradeTrack = "Hero 1" },      -- Key Level 6
        { itemLevel = 305, upgradeTrack = "Hero 1" },      -- Key Level 7
        { itemLevel = 308, upgradeTrack = "Hero 2" },      -- Key Level 8
        { itemLevel = 308, upgradeTrack = "Hero 2" },      -- Key Level 9
        { itemLevel = 311, upgradeTrack = "Hero 3" }       -- Key Level 10+
    },

    VAULT_GEAR = {
        { itemLevel = 305, upgradeTrack = "Hero 1" },      -- Key Level 2
        { itemLevel = 305, upgradeTrack = "Hero 1" },      -- Key Level 3
        { itemLevel = 308, upgradeTrack = "Hero 2" },      -- Key Level 4
        { itemLevel = 308, upgradeTrack = "Hero 2" },      -- Key Level 5
        { itemLevel = 311, upgradeTrack = "Hero 3" },      -- Key Level 6
        { itemLevel = 315, upgradeTrack = "Hero 4" },      -- Key Level 7
        { itemLevel = 315, upgradeTrack = "Hero 4" },      -- Key Level 8
        { itemLevel = 315, upgradeTrack = "Hero 4" },      -- Key Level 9
        { itemLevel = 318, upgradeTrack = "Myth 1" }       -- Key Level 10+
    },

    CRESTS = {
        { crestType = "Champion", amount = 12 },   -- Key Level 2
        { crestType = "Champion", amount = 14 },   -- Key Level 3
        { crestType = "Hero", amount = 10 },       -- Key Level 4
        { crestType = "Hero", amount = 10 },       -- Key Level 5
        { crestType = "Hero", amount = 12 },       -- Key Level 6
        { crestType = "Hero", amount = 14 },       -- Key Level 7
        { crestType = "Hero", amount = 18 },       -- Key Level 8
        { crestType = "Myth", amount = 10 },       -- Key Level 9
        { crestType = "Myth", amount = 12 },       -- Key Level 10
        { crestType = "Myth", amount = 14 },       -- Key Level 11
        { crestType = "Myth", amount = 16 },       -- Key Level 12+
    }
}

_G.MrMythical = MrMythical
