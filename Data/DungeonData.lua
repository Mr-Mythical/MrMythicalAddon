--[[
DungeonData.lua - Mythic+ Dungeon Map Data

Purpose: Contains mapping data for all current season Mythic+ dungeons
Dependencies: None
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

MrMythical.DungeonData = {
    MYTHIC_MAPS = {},
    
    -- Cache for season/pool tracking
    _seasonCache = {
        seasonID = nil,
        mapPoolSignature = nil
    }
}

--- Refresh the MYTHIC_MAPS list from the live API (id, name, parTime if available)
function MrMythical.DungeonData.refreshFromAPI()
    local maps = {}
    local mapIDs = C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable() or nil
    if type(mapIDs) ~= "table" or #mapIDs == 0 then
        -- Nothing to do; keep current table (possibly empty)
        return false
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
    return true
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

--- Gets the name for a specific dungeon map ID
--- @param mapID number The dungeon map ID
--- @return string The dungeon name or a fallback string
function MrMythical.DungeonData.getDungeonName(mapID)
    for _, mapInfo in ipairs(MrMythical.DungeonData.MYTHIC_MAPS) do
        if mapInfo.id == mapID then
            return mapInfo.name
        end
    end
    
    -- Fallback to API if not in cache
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        if name then
            return name
        end
    end
    
    return "Dungeon " .. tostring(mapID)
end

--- Gets all current Mythic+ map IDs
--- @return table Array of map IDs
function MrMythical.DungeonData.getCurrentMapIDs()
    local mapIDs = {}
    for _, mapInfo in ipairs(MrMythical.DungeonData.MYTHIC_MAPS) do
        table.insert(mapIDs, mapInfo.id)
    end
    return mapIDs
end

--- Builds a stable signature string for the current dungeon pool (order-independent)
--- @return string A signature string representing the current map pool
function MrMythical.DungeonData.getMapPoolSignature()
    local ids = {}
    for _, mapInfo in ipairs(MrMythical.DungeonData.MYTHIC_MAPS) do
        table.insert(ids, tostring(mapInfo.id))
    end
    table.sort(ids)
    return table.concat(ids, ":")
end

--- Checks if season/pool has changed and updates cache
--- @return table Result with seasonChanged and poolChanged flags
function MrMythical.DungeonData.checkSeasonAndPoolChanges()
    local result = {
        seasonChanged = false,
        poolChanged = false,
        currentSeasonID = nil,
        currentPoolSignature = nil
    }
    
    local currentSeasonID = (C_MythicPlus and C_MythicPlus.GetCurrentSeason and C_MythicPlus.GetCurrentSeason())
    local currentPoolSig = MrMythical.DungeonData.getMapPoolSignature()
    
    result.currentSeasonID = currentSeasonID
    result.currentPoolSignature = currentPoolSig
    
    if currentSeasonID and currentSeasonID > 0 then
        -- First-time initialization
        if not MrMythical.DungeonData._seasonCache.seasonID or MrMythical.DungeonData._seasonCache.seasonID <= 0 then
            MrMythical.DungeonData._seasonCache.seasonID = currentSeasonID
        end
        if not MrMythical.DungeonData._seasonCache.mapPoolSignature then
            MrMythical.DungeonData._seasonCache.mapPoolSignature = currentPoolSig
        end

        result.seasonChanged = currentSeasonID ~= MrMythical.DungeonData._seasonCache.seasonID
        result.poolChanged = currentPoolSig ~= MrMythical.DungeonData._seasonCache.mapPoolSignature

        -- Update cache
        if result.seasonChanged then
            MrMythical.DungeonData._seasonCache.seasonID = currentSeasonID
            MrMythical.DungeonData._seasonCache.mapPoolSignature = currentPoolSig
        elseif result.poolChanged and currentPoolSig and currentPoolSig ~= "" then
            MrMythical.DungeonData._seasonCache.mapPoolSignature = currentPoolSig
        end
    end
    
    return result
end

--- Formats time in seconds to MM:SS format
--- @param timeInSeconds number The time in seconds
--- @return string The formatted time string
function MrMythical.DungeonData.formatTime(timeInSeconds)
    if timeInSeconds == nil then
        return "Unknown"
    end
    
    if timeInSeconds <= 0 then
        return "0:00"
    end
    
    local minutes = math.floor(timeInSeconds / 60)
    local seconds = timeInSeconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

_G.MrMythical = MrMythical
