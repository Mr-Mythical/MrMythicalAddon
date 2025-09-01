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
        local name, parTime
        
        if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
            local n, _, timeLimit = C_ChallengeMode.GetMapUIInfo(id)
            name = type(n) == "string" and n or nil
            parTime = (type(timeLimit) == "number" and timeLimit > 0) and math.floor(timeLimit) or nil
            
            if parTime then 
                withTimers = withTimers + 1 
            else 
                table.insert(missingTimers, string.format("%s(%d)", name or "?", id)) 
            end
        end
        
        table.insert(maps, { 
            id = id, 
            name = name or ("Map " .. tostring(id)), 
            parTime = parTime 
        })
    end

    MrMythical.DungeonData.MYTHIC_MAPS = maps
    return true
end

--- Helper function to find map info by ID
--- @param mapID number The dungeon map ID
--- @return table|nil The map info table or nil if not found
local function findMapByID(mapID)
    for _, mapInfo in ipairs(MrMythical.DungeonData.MYTHIC_MAPS) do
        if mapInfo.id == mapID then
            return mapInfo
        end
    end
    return nil
end

--- Gets the par time for a specific dungeon map ID
--- @param mapID number The dungeon map ID
--- @return number|nil The par time in seconds, or nil if not found
function MrMythical.DungeonData.getParTime(mapID)
    local mapInfo = findMapByID(mapID)
    return mapInfo and mapInfo.parTime or nil
end

--- Gets the name for a specific dungeon map ID
--- @param mapID number The dungeon map ID
--- @return string The dungeon name or a fallback string
function MrMythical.DungeonData.getDungeonName(mapID)
    local mapInfo = findMapByID(mapID)
    if mapInfo then
        return mapInfo.name
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
    
    if not (currentSeasonID and currentSeasonID > 0) then
        return result
    end
    
    -- Initialize cache on first run
    local cache = MrMythical.DungeonData._seasonCache
    if not cache.seasonID or cache.seasonID <= 0 then
        cache.seasonID = currentSeasonID
        cache.mapPoolSignature = currentPoolSig
        return result
    end
    
    -- Check for changes
    result.seasonChanged = currentSeasonID ~= cache.seasonID
    result.poolChanged = currentPoolSig ~= cache.mapPoolSignature
    
    -- Update cache
    if result.seasonChanged then
        cache.seasonID = currentSeasonID
        cache.mapPoolSignature = currentPoolSig
    elseif result.poolChanged and currentPoolSig and currentPoolSig ~= "" then
        cache.mapPoolSignature = currentPoolSig
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

--- Debug logging function for development
--- @param message string The debug message to log
--- @param ... any Additional values to include in the debug output
local function debugLog(message, ...)
    if MrMythicalDebug then
        local formattedMessage = string.format("[MrMythical Debug] " .. message, ...)
        print(formattedMessage)
    end
end

--- Retrieves the dungeon score for a specific map from a RaiderIO profile
--- @param profile table RaiderIO profile data containing mythic keystone information
--- @param targetMapID number The specific dungeon map ID to find score for
--- @return number The dungeon score, or 0 if no data found
local function getDungeonScoreFromProfile(profile, targetMapID)
    if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.sortedDungeons then
        for _, dungeonEntry in ipairs(profile.mythicKeystoneProfile.sortedDungeons) do
            if dungeonEntry.dungeon and dungeonEntry.dungeon.keystone_instance == targetMapID then
                local completedLevel = dungeonEntry.level or 0
                local chestsEarned = dungeonEntry.chests or 0
                local baseScore = MrMythical.RewardsFunctions.scoreFormula(completedLevel)
                
                local chestBonus = 0
                if chestsEarned == 2 then
                    chestBonus = 7.5
                elseif chestsEarned >= 3 then
                    chestBonus = 15
                end
                
                return baseScore + chestBonus
            end
        end
    end
    
    -- Fallback to average score if specific dungeon not found
    if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.currentScore then
        local numDungeons = #profile.mythicKeystoneProfile.sortedDungeons
        if numDungeons > 0 then
            return profile.mythicKeystoneProfile.currentScore / numDungeons
        end
    end
    
    return 0
end

--- Retrieves mythic+ scores for all group members for a specific dungeon
--- @param playerScore number The current player's score for this dungeon
--- @param targetMapID number The dungeon map ID to get scores for
--- @return table A mapping of player names to their dungeon scores
function MrMythical.DungeonData.getGroupMythicDataParty(playerScore, targetMapID)
    debugLog("Getting group mythic data for map ID: %d", targetMapID)
    
    local groupScoreData = {}
    local playerName = UnitName("player")
    groupScoreData[playerName] = playerScore
    
    local regionNumber = GetCurrentRegion and GetCurrentRegion() or 1
    local region = MrMythical.ConfigData.REGION_MAP[regionNumber] or "us"
    local numGroupMembers = GetNumGroupMembers() or 1
    
    for i = 1, numGroupMembers - 1 do
        local unitID = "party" .. i
        if UnitExists(unitID) then
            local name, realm = UnitName(unitID)
            realm = realm and realm ~= "" and realm or GetRealmName()
            
            if RaiderIO and RaiderIO.GetProfile then
                local playerProfile = RaiderIO.GetProfile(name, realm, region)
                local dungeonScore = 0
                
                if playerProfile and playerProfile.mythicKeystoneProfile then
                    dungeonScore = getDungeonScoreFromProfile(playerProfile, targetMapID)
                end
                
                groupScoreData[name] = dungeonScore
            else
                groupScoreData[name] = 0
            end
        end
    end
    
    return groupScoreData
end

--- Retrieves the player's best mythic+ score for a given keystone
--- @param itemString string The keystone item string to get score for
--- @return number The player's best score for this keystone, or 0 if no data
function MrMythical.DungeonData.getCharacterMythicScore(itemString)
    local mapID = MrMythical.KeystoneUtils.extractMapID(itemString)
    if not mapID then
        return 0
    end
    
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    
    -- Return the highest score between in-time and overtime runs
    local bestScore = 0
    
    if intimeInfo and intimeInfo.dungeonScore then
        bestScore = intimeInfo.dungeonScore
    end
    
    if overtimeInfo and overtimeInfo.dungeonScore and overtimeInfo.dungeonScore > bestScore then
        bestScore = overtimeInfo.dungeonScore
    end
    
    return bestScore
end

--- Retrieves the player's best mythic+ level and time for a given keystone
--- @param itemString string The keystone item string to get data for
--- @return table Table with bestLevel, bestTime, and wasInTime, or nil if no data
function MrMythical.DungeonData.getCharacterBestRun(itemString)
    local mapID = MrMythical.KeystoneUtils.extractMapID(itemString)
    if not mapID then
        return nil
    end
    
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    
    -- Compare scores to find the best scoring run
    local bestInfo = nil
    local bestScore = 0
    
    if intimeInfo and intimeInfo.dungeonScore then
        bestInfo = intimeInfo
        bestScore = intimeInfo.dungeonScore
    end
    
    if overtimeInfo and overtimeInfo.dungeonScore and overtimeInfo.dungeonScore > bestScore then
        bestInfo = overtimeInfo
        bestScore = overtimeInfo.dungeonScore
    end
    
    if bestInfo then
        return {
            bestLevel = bestInfo.level,
            bestTime = bestInfo.durationSec,
            wasInTime = (bestInfo == intimeInfo)
        }
    end
end
    
--- Retrieves aggregated dungeon data for all mythic+ dungeons
--- @return table Array of dungeon data with best scores, levels, and timing info
function MrMythical.DungeonData.getAllDungeonData()
    local dungeonData = {}
    
    for i, mapInfo in ipairs(MrMythical.DungeonData.MYTHIC_MAPS) do
        local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapInfo.id)
        local hasRun = false
        
        -- Check both timed and overtime runs to find the highest score
        local bestScore = 0
        local bestLevel = 0
        local bestIsInTime = false
        local bestRunTime = 0
        
        if intimeInfo and intimeInfo.dungeonScore then
            if intimeInfo.dungeonScore > bestScore then
                bestScore = intimeInfo.dungeonScore
                bestLevel = intimeInfo.level
                bestIsInTime = true
                bestRunTime = intimeInfo.durationSec or 0
            end
            hasRun = true
        end
        
        if overtimeInfo and overtimeInfo.dungeonScore then
            if overtimeInfo.dungeonScore > bestScore then
                bestScore = overtimeInfo.dungeonScore
                bestLevel = overtimeInfo.level
                bestIsInTime = false
                bestRunTime = overtimeInfo.durationSec or 0
            end
            hasRun = true
        end
        
        table.insert(dungeonData, {
            index = i,
            mapInfo = mapInfo,
            currentLevel = bestLevel,
            currentScore = bestScore,
            isInTime = bestIsInTime,
            hasRun = hasRun,
            runTime = bestRunTime
        })
    end
    
    -- Sort by current score (highest first), then by name
    table.sort(dungeonData, function(a, b)
        if a.currentScore == b.currentScore then
            return a.mapInfo.name < b.mapInfo.name
        end
        return a.currentScore > b.currentScore
    end)
    
    return dungeonData
end

_G.MrMythical = MrMythical
