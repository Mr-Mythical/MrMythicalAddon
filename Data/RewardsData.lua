--[[
RewardsData.lua - Mythic+ Reward Tables

Purpose: Contains gear, vault, and crest reward data for all keystone levels
Dependencies: None
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

MrMythical.RewardsData = {
    DUNGEON_GEAR = {
        { itemLevel = 250, upgradeTrack = "Champion 2" },  -- Key Level 2
        { itemLevel = 250, upgradeTrack = "Champion 2" },  -- Key Level 3
        { itemLevel = 253, upgradeTrack = "Champion 3" },  -- Key Level 4
        { itemLevel = 256, upgradeTrack = "Champion 4" },  -- Key Level 5
        { itemLevel = 259, upgradeTrack = "Hero 1" },      -- Key Level 6
        { itemLevel = 259, upgradeTrack = "Hero 1" },      -- Key Level 7
        { itemLevel = 263, upgradeTrack = "Hero 2" },      -- Key Level 8
        { itemLevel = 263, upgradeTrack = "Hero 2" },      -- Key Level 9
        { itemLevel = 266, upgradeTrack = "Hero 3" }       -- Key Level 10+
    },

    VAULT_GEAR = {
        { itemLevel = 259, upgradeTrack = "Hero 1" },      -- Key Level 2
        { itemLevel = 259, upgradeTrack = "Hero 1" },      -- Key Level 3
        { itemLevel = 263, upgradeTrack = "Hero 2" },      -- Key Level 4
        { itemLevel = 263, upgradeTrack = "Hero 2" },      -- Key Level 5
        { itemLevel = 266, upgradeTrack = "Hero 3" },      -- Key Level 6
        { itemLevel = 269, upgradeTrack = "Hero 3" },      -- Key Level 7
        { itemLevel = 269, upgradeTrack = "Hero 3" },      -- Key Level 8
        { itemLevel = 269, upgradeTrack = "Hero 3" },      -- Key Level 9
        { itemLevel = 272, upgradeTrack = "Hero 3" }       -- Key Level 10+
    },

    CRESTS = {
        { crestType = "Hero", amount = 10 },   -- Key Level 2
        { crestType = "Hero", amount = 12 },   -- Key Level 3
        { crestType = "Hero", amount = 14 },   -- Key Level 4
        { crestType = "Hero", amount = 16 },   -- Key Level 5
        { crestType = "Hero", amount = 18 },   -- Key Level 6
        { crestType = "Myth", amount = 10 },  -- Key Level 7
        { crestType = "Myth", amount = 12 },  -- Key Level 8
        { crestType = "Myth", amount = 14 },  -- Key Level 9
        { crestType = "Myth", amount = 16 },  -- Key Level 10
        { crestType = "Myth", amount = 18 },  -- Key Level 11
        { crestType = "Myth", amount = 20 },  -- Key Level 12+
    }
}

_G.MrMythical = MrMythical
