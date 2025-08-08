--[[
RewardsData.lua - Mythic+ Reward Tables

Purpose: Contains gear, vault, and crest reward data for all keystone levels
Dependencies: None
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

MrMythical.RewardsData = {
    DUNGEON_GEAR = {
        { itemLevel = 684, upgradeTrack = "Champion 2" },  -- Key Level 2
        { itemLevel = 684, upgradeTrack = "Champion 2" },  -- Key Level 3
        { itemLevel = 688, upgradeTrack = "Champion 3" },  -- Key Level 4
        { itemLevel = 691, upgradeTrack = "Champion 4" },  -- Key Level 5
        { itemLevel = 694, upgradeTrack = "Hero 1" },      -- Key Level 6
        { itemLevel = 694, upgradeTrack = "Hero 1" },      -- Key Level 7
        { itemLevel = 697, upgradeTrack = "Hero 2" },      -- Key Level 8
        { itemLevel = 697, upgradeTrack = "Hero 2" },      -- Key Level 9
        { itemLevel = 701, upgradeTrack = "Hero 3" }       -- Key Level 10+
    },

    VAULT_GEAR = {
        { itemLevel = 694, upgradeTrack = "Hero 1" },      -- Key Level 2
        { itemLevel = 694, upgradeTrack = "Hero 1" },      -- Key Level 3
        { itemLevel = 697, upgradeTrack = "Hero 2" },      -- Key Level 4
        { itemLevel = 697, upgradeTrack = "Hero 2" },      -- Key Level 5
        { itemLevel = 701, upgradeTrack = "Hero 3" },      -- Key Level 6
        { itemLevel = 704, upgradeTrack = "Hero 4" },      -- Key Level 7
        { itemLevel = 704, upgradeTrack = "Hero 4" },      -- Key Level 8
        { itemLevel = 704, upgradeTrack = "Hero 4" },      -- Key Level 9
        { itemLevel = 707, upgradeTrack = "Myth 1" }       -- Key Level 10+
    },

    CRESTS = {
        { crestType = "Runed", amount = 10 },   -- Key Level 2
        { crestType = "Runed", amount = 12 },   -- Key Level 3
        { crestType = "Runed", amount = 14 },   -- Key Level 4
        { crestType = "Runed", amount = 16 },   -- Key Level 5
        { crestType = "Runed", amount = 18 },   -- Key Level 6
        { crestType = "Gilded", amount = 10 },  -- Key Level 7
        { crestType = "Gilded", amount = 12 },  -- Key Level 8
        { crestType = "Gilded", amount = 14 },  -- Key Level 9
        { crestType = "Gilded", amount = 16 },  -- Key Level 10
        { crestType = "Gilded", amount = 18 },  -- Key Level 11
        { crestType = "Gilded", amount = 20 },  -- Key Level 12+
    }
}

_G.MrMythical = MrMythical
