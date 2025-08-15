--[[
CompletionTracker.lua - Mythic+ Run Completion Tracking

Purpose: Tracks and analyzes Mythic+ dungeon completion statistics
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

-- Fetch the current Mythic+ map pool using the game API
local function fetchCurrentMythicPool()
    local pool = {}
    
    local mapIDs = C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable()
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

-- Build a stable signature string for the current dungeon pool (order-independent)
local function getMapPoolSignature()
    local ids = {}
    local pool = fetchCurrentMythicPool()
    for _, mapInfo in ipairs(pool) do
        table.insert(ids, tostring(mapInfo.id))
    end
    table.sort(ids)
    return table.concat(ids, ":")
end

-- Helper function to get dungeon name from API or fallback
local function getDungeonName(mapID)
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        if name then
            return name
        end
    end
    return "Dungeon " .. tostring(mapID)
end

-- Helper function to ensure dungeon entry exists in container
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

-- Ensure dungeon stats table matches the current pool; keep known entries, drop removed, add new
local function syncDungeonStats(container)
    if not container then return end

    for _, mapInfo in ipairs(fetchCurrentMythicPool()) do
        ensureDungeonEntry(container, mapInfo.id)
    end
end

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

local function calculateCompletionRate(completed, failed)
    local total = completed + failed
    if total == 0 then return 0 end
    return (completed / total) * 100
end

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

-- Helper function to update completion stats
local function updateStats(container, mapID, success)
    if success then
        container.completed = container.completed + 1
        container.dungeons[mapID].completed = container.dungeons[mapID].completed + 1
    else
        container.failed = container.failed + 1
        container.dungeons[mapID].failed = container.dungeons[mapID].failed + 1
    end
end

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

-- Helper function to build stats for a container
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

function CompletionTracker:getStats()
    -- Ensure weekly reset is current (this will also handle season changes)
    checkWeeklyReset()

    return {
        seasonal = buildStatsContainer(completionData.seasonal),
        weekly = buildStatsContainer(completionData.weekly)
    }
end

-- Constants for default data structure
local DEFAULT_COMPLETION_DATA = {
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

-- Helper function to deep copy a table
local function deepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = deepCopy(value)
    end
    return copy
end

function CompletionTracker:initialize()
    -- Initialize saved variables if they don't exist
    if not MRM_CompletionData then
        MRM_CompletionData = deepCopy(DEFAULT_COMPLETION_DATA)
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

    -- Sync dungeon pools immediately for UI purposes
    syncDungeonStats(completionData.seasonal.dungeons)
    syncDungeonStats(completionData.weekly.dungeons)

    checkWeeklyReset()
end

MrMythical.CompletionTracker = CompletionTracker
_G.MrMythical = MrMythical