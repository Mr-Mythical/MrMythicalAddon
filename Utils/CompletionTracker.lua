--[[
CompletionTracker.lua - Mythic+ Run Completion Tracking

Purpose: Tracks and analyzes Mythic+ dungeon completion statistics
Dependencies: WoW APIs (C_ChallengeMode, C_MythicPlus, C_DateAndTime)
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

local CompletionTracker = {}

local completionData = {
    seasonal = {
        completed = 0,
        failed = 0,
        dungeons = {},
        seasonID = nil,
        mapPoolSig = nil
    },
    weekly = {
        completed = 0,
        failed = 0,
        dungeons = {},
        resetTime = nil
    }
}

--- Fetches the current Mythic+ map pool using the game API
--- @return table Array of map info tables with id and name fields
local function fetchCurrentMythicPool()
    local pool = {}
    
    -- Check if Challenge Mode APIs are available
    if not C_ChallengeMode or not C_ChallengeMode.GetMapTable then
        return pool -- Return empty pool if APIs not available
    end
    
    local mapIDs = C_ChallengeMode.GetMapTable()
    if mapIDs and type(mapIDs) == "table" and #mapIDs > 0 then
        for _, id in ipairs(mapIDs) do
            local name = C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(id)
            table.insert(pool, { 
                id = id, 
                name = name or ("Map " .. tostring(id)) 
            })
        end
    end
    
    return pool
end

--- Builds a stable signature string for the current dungeon pool (order-independent)
--- @return string A signature string representing the current map pool
local function getMapPoolSignature()
    local ids = {}
    local pool = fetchCurrentMythicPool()
    for _, mapInfo in ipairs(pool) do
        table.insert(ids, tostring(mapInfo.id))
    end
    table.sort(ids)
    return table.concat(ids, ":")
end

--- Helper function to get dungeon name from API or fallback
--- @param mapID number The dungeon map ID
--- @return string The dungeon name or a fallback string
local function getDungeonName(mapID)
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        if name then
            return name
        end
    end
    return "Dungeon " .. tostring(mapID)
end

--- Helper function to ensure dungeon entry exists in container
--- @param container table The stats container to ensure entry exists in
--- @param mapID number The dungeon map ID to ensure entry for
local function ensureDungeonEntry(container, mapID)
    if not container[mapID] then
        container[mapID] = { 
            completed = 0, 
            failed = 0, 
            name = getDungeonName(mapID) 
        }
    else
        -- Update name in case it changed, but preserve stats
        container[mapID].name = getDungeonName(mapID)
        container[mapID].completed = container[mapID].completed or 0
        container[mapID].failed = container[mapID].failed or 0
    end
end

--- Ensures dungeon stats table matches the current pool; keeps known entries, drops removed, adds new
--- @param container table The stats container to synchronize
local function syncDungeonStats(container)
    if not container then return end

    for _, mapInfo in ipairs(fetchCurrentMythicPool()) do
        ensureDungeonEntry(container, mapInfo.id)
    end
end

--- Checks and ensures dungeon pool is populated during initialization
local function checkDungeonPoolOnLoad()
    -- Always sync the current dungeon pool to ensure UI has data
    syncDungeonStats(completionData.seasonal.dungeons)
    syncDungeonStats(completionData.weekly.dungeons)
    
    -- Set basic season tracking if not already set (for UI purposes)
    local currentSeasonID = (C_MythicPlus and C_MythicPlus.GetCurrentSeason and C_MythicPlus.GetCurrentSeason())
    if currentSeasonID and currentSeasonID > 0 then
        if not completionData.seasonal.seasonID or completionData.seasonal.seasonID <= 0 then
            completionData.seasonal.seasonID = currentSeasonID
        end
        if not completionData.seasonal.mapPoolSig then
            completionData.seasonal.mapPoolSig = getMapPoolSignature()
        end
    end
    
    -- If we still don't have any dungeons, APIs might not be ready yet
    local hasSeasonalDungeons = next(completionData.seasonal.dungeons) ~= nil
    local hasWeeklyDungeons = next(completionData.weekly.dungeons) ~= nil
    
    if not hasSeasonalDungeons or not hasWeeklyDungeons then
        -- Schedule a retry after a short delay
        C_Timer.After(1.0, function()
            syncDungeonStats(completionData.seasonal.dungeons)
            syncDungeonStats(completionData.weekly.dungeons)
        end)
    end
end

--- Forces a refresh of the dungeon pool data (useful when APIs become available)
--- @return boolean True if dungeons were successfully loaded, false otherwise
function CompletionTracker:refreshDungeonPool()
    local poolBefore = {}
    for mapID in pairs(completionData.seasonal.dungeons) do
        poolBefore[mapID] = true
    end
    
    syncDungeonStats(completionData.seasonal.dungeons)
    syncDungeonStats(completionData.weekly.dungeons)
    
    local poolAfter = {}
    for mapID in pairs(completionData.seasonal.dungeons) do
        poolAfter[mapID] = true
    end
    
    -- Check if we actually got some new dungeons
    local newDungeonsFound = false
    for mapID in pairs(poolAfter) do
        if not poolBefore[mapID] then
            newDungeonsFound = true
            break
        end
    end
    
    return next(completionData.seasonal.dungeons) ~= nil
end

--- Initializes dungeon stats for a container if it's empty
--- @param container table The stats container to initialize
local function initializeDungeonStats(container)
    -- Only initialize if container is completely empty - don't wipe existing data
    if not container or next(container) then
        return -- Container already has data or is nil, don't wipe it
    end
    
    local pool = fetchCurrentMythicPool()
    for _, mapInfo in ipairs(pool) do
        container[mapInfo.id] = { 
            completed = 0, 
            failed = 0, 
            name = mapInfo.name 
        }
    end
end

--- Calculates completion rate percentage from completed and failed counts
--- @param completed number Number of successful completions
--- @param failed number Number of failed attempts
--- @return number Completion rate as a percentage (0-100)
local function calculateCompletionRate(completed, failed)
    local total = completed + failed
    if total == 0 then return 0 end
    return (completed / total) * 100
end

--- Checks for weekly reset and handles season/pool changes
local function checkWeeklyReset()
    local currentTime = time()
    local secondsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
    local nextReset = currentTime + secondsUntilReset

    if not completionData.weekly.resetTime or currentTime >= completionData.weekly.resetTime then
        -- Reset weekly stats
        completionData.weekly.completed = 0
        completionData.weekly.failed = 0
        initializeDungeonStats(completionData.weekly.dungeons)
        completionData.weekly.resetTime = nextReset
        
        -- Check for season/pool changes on weekly reset
        local currentSeasonID = (C_MythicPlus and C_MythicPlus.GetCurrentSeason and C_MythicPlus.GetCurrentSeason())
        if currentSeasonID and currentSeasonID > 0 then
            local currentSig = getMapPoolSignature()
            
            -- First-time initialization
            if not completionData.seasonal.seasonID or completionData.seasonal.seasonID <= 0 then
                completionData.seasonal.seasonID = currentSeasonID
            end
            if not completionData.seasonal.mapPoolSig then
                completionData.seasonal.mapPoolSig = currentSig
            end

            local seasonChanged = currentSeasonID ~= completionData.seasonal.seasonID
            local poolChanged = currentSig ~= completionData.seasonal.mapPoolSig

            if seasonChanged then
                -- Reset seasonal stats for new season
                completionData.seasonal.completed = 0
                completionData.seasonal.failed = 0
                
                -- Reset individual dungeon stats but keep the structure
                for mapID, dungeonData in pairs(completionData.seasonal.dungeons) do 
                    dungeonData.completed = 0
                    dungeonData.failed = 0
                end

                -- Update markers
                completionData.seasonal.seasonID = currentSeasonID
                completionData.seasonal.mapPoolSig = currentSig
            elseif poolChanged and currentSig and currentSig ~= "" then
                -- Pool changed but not season - just sync the available dungeons
                completionData.seasonal.mapPoolSig = currentSig
            end
            
            -- Sync dungeon pools for both seasonal and weekly after any changes
            syncDungeonStats(completionData.seasonal.dungeons)
            syncDungeonStats(completionData.weekly.dungeons)
        end
    end
end

--- Helper function to update completion stats
--- @param container table The stats container to update
--- @param mapID number The dungeon map ID
--- @param success boolean Whether the run was successful
local function updateStats(container, mapID, success)
    if success then
        container.completed = container.completed + 1
        container.dungeons[mapID].completed = container.dungeons[mapID].completed + 1
    else
        container.failed = container.failed + 1
        container.dungeons[mapID].failed = container.dungeons[mapID].failed + 1
    end
end

--- Tracks a completed Mythic+ run and updates statistics
--- @param mapID number The dungeon map ID that was completed
--- @param success boolean Whether the run was completed successfully (in time)
--- @param level number The keystone level completed (currently unused but available for future features)
function CompletionTracker:trackRun(mapID, success, level)
    if not completionData or not mapID then 
        return 
    end
    
    -- Don't do season checks during tracking - just track the run
    -- Season checks will happen when viewing stats
    checkWeeklyReset()
    
    -- Ensure the mapID exists in our tracking tables
    ensureDungeonEntry(completionData.seasonal.dungeons, mapID)
    ensureDungeonEntry(completionData.weekly.dungeons, mapID)

    -- Update both seasonal and weekly stats
    updateStats(completionData.seasonal, mapID, success)
    updateStats(completionData.weekly, mapID, success)
end

--- Helper function to build stats for a container
--- @param container table The raw completion data container
--- @return table Formatted stats with rates and dungeon breakdowns
local function buildStatsContainer(container)
    local stats = {
        rate = calculateCompletionRate(container.completed, container.failed),
        completed = container.completed,
        failed = container.failed,
        dungeons = {}
    }

    for mapID, data in pairs(container.dungeons) do
        stats.dungeons[mapID] = {
            name = data.name,
            rate = calculateCompletionRate(data.completed, data.failed),
            completed = data.completed,
            failed = data.failed
        }
    end

    return stats
end

--- Gets current completion statistics for both seasonal and weekly periods
--- @return table Table containing seasonal and weekly stats with completion rates
function CompletionTracker:getStats()
    -- Ensure weekly reset is current (this will also handle season changes)
    checkWeeklyReset()
    
    -- If dungeons are still empty, try to populate them again
    -- This handles cases where APIs weren't available during initial load
    local seasonalCount = 0
    for _ in pairs(completionData.seasonal.dungeons) do seasonalCount = seasonalCount + 1 end
    local weeklyCount = 0
    for _ in pairs(completionData.weekly.dungeons) do weeklyCount = weeklyCount + 1 end
    
    if seasonalCount == 0 or weeklyCount == 0 then
        syncDungeonStats(completionData.seasonal.dungeons)
        syncDungeonStats(completionData.weekly.dungeons)
        
        -- If still empty after sync, try explicit refresh
        if next(completionData.seasonal.dungeons) == nil then
            self:refreshDungeonPool()
        end
    end

    return {
        seasonal = buildStatsContainer(completionData.seasonal),
        weekly = buildStatsContainer(completionData.weekly)
    }
end

--- Initializes the completion tracker with saved variables and default data
function CompletionTracker:initialize()
    -- Initialize saved variables if they don't exist
    if not MRM_CompletionData then
        MRM_CompletionData = completionData
    end

    completionData = MRM_CompletionData

    -- Ensure all required tables exist
    completionData.seasonal = completionData.seasonal or {}
    completionData.weekly = completionData.weekly or {}
    completionData.seasonal.dungeons = completionData.seasonal.dungeons or {}
    completionData.weekly.dungeons = completionData.weekly.dungeons or {}
    
    -- Only call initializeDungeonStats if tables are truly empty
    initializeDungeonStats(completionData.seasonal.dungeons)
    initializeDungeonStats(completionData.weekly.dungeons)

    -- Check and populate dungeon pool for immediate UI availability
    checkDungeonPoolOnLoad()

    checkWeeklyReset()
end

MrMythical.CompletionTracker = CompletionTracker
_G.MrMythical = MrMythical