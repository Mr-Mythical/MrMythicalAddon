--[[
DungeonData.lua - Mythic+ Dungeon Map Data

Purpose: Contains mapping data for all current season Mythic+ dungeons
Dependencies: None
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

MrMythical.DungeonData = {
    MYTHIC_MAPS = {
        { id = 506, name = "Cinderbrew Meadery", parTime = 1980 },
        { id = 504, name = "Darkflame Cleft", parTime = 1860 },
        { id = 370, name = "Mechagon Workshop", parTime = 1920 },
        { id = 525, name = "Operation: Floodgate", parTime = 1980 },
        { id = 499, name = "Priory of the Sacred Flame", parTime = 1950 },
        { id = 247, name = "The MOTHERLODE!!", parTime = 1980 },
        { id = 500, name = "The Rookery", parTime = 1740 },
        { id = 382, name = "Theater of Pain", parTime = 2040 }
    }
}

--- Gets the par time for a specific dungeon map ID
--- @param mapID number The dungeon map ID
--- @return number|nil The par time in seconds, or nil if not found
function MrMythical.DungeonData.getParTime(mapID)
    for _, mapInfo in ipairs(MrMythical.DungeonData.MYTHIC_MAPS) do
        if mapInfo.id == mapID then
            return mapInfo.parTime
        end
    end
    return nil
end

--- Formats time in seconds to MM:SS format
--- @param timeInSeconds number The time in seconds
--- @return string The formatted time string
function MrMythical.DungeonData.formatTime(timeInSeconds)
    if not timeInSeconds then
        return "Unknown"
    end
    
    local minutes = math.floor(timeInSeconds / 60)
    local seconds = timeInSeconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

_G.MrMythical = MrMythical
