--[[
DungeonData.lua - Mythic+ Dungeon Map Data

Purpose: Contains mapping data for all current season Mythic+ dungeons
Dependencies: None
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

MrMythical.DungeonData = {
    MYTHIC_MAPS = {}
}

--- Refresh the MYTHIC_MAPS list from the live API (id, name, parTime if available)
function MrMythical.DungeonData.refreshFromAPI()
    local maps = {}
    local mapIDs = C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable() or nil
    if type(mapIDs) ~= "table" or #mapIDs == 0 then
        -- Nothing to do; keep current table (possibly empty)
        return
    end

    local missingTimers = {}
    local withTimers = 0

    for _, id in ipairs(mapIDs) do
        local name = nil
        if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
            local n, _, timeLimit = C_ChallengeMode.GetMapUIInfo(id)
            if type(n) == "string" then name = n end
            local parTime = (type(timeLimit) == "number" and timeLimit > 0) and math.floor(timeLimit) or nil
            if parTime then withTimers = withTimers + 1 else table.insert(missingTimers, string.format("%s(%d)", name or "?", id)) end
            table.insert(maps, { id = id, name = name or ("Map "..tostring(id)), parTime = parTime })
        else
            table.insert(maps, { id = id, name = name or ("Map "..tostring(id)), parTime = nil })
        end
    end

    MrMythical.DungeonData.MYTHIC_MAPS = maps

    -- Debug output removed
end

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
