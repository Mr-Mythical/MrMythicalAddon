--[[
CompletionTracker.lua - Mythic+ Run Completion Tracking

Purpose: Tracks and analyzes Mythic+ dungeon completion statistics
Dependencies: DungeonData
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
local DungeonData = MrMythical.DungeonData

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

-- Fetch the current Mythic+ map pool using the game API; fallback to static data if needed
local function fetchCurrentMythicPool()
    local pool = {}
    local mapIDs = C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable() or nil
    if type(mapIDs) == "table" and #mapIDs > 0 then
    local names = {}
        for _, id in ipairs(mapIDs) do
            local name = C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(id) or nil
            table.insert(pool, { id = id, name = name or ("Map "..tostring(id)) })
            table.insert(names, string.format("%s(%d)", name or "?", id))
        end
        return pool
    end

    -- Fallback to DungeonData if API not available yet
    if DungeonData and type(DungeonData.MYTHIC_MAPS) == "table" then
    local count = 0
        for _, m in ipairs(DungeonData.MYTHIC_MAPS) do
            table.insert(pool, { id = m.id, name = m.name })
            count = count + 1
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

-- Ensure dungeon stats table matches the current pool; keep known entries, drop removed, add new
local function syncDungeonStats(container)
    if not container then return end

    local poolSet = {}
    for _, mapInfo in ipairs(fetchCurrentMythicPool()) do
        poolSet[mapInfo.id] = mapInfo
        if not container[mapInfo.id] then
            container[mapInfo.id] = { completed = 0, failed = 0, name = mapInfo.name }
        else
            -- Ensure name stays updated, but preserve existing stats
            container[mapInfo.id].name = mapInfo.name
            container[mapInfo.id].completed = container[mapInfo.id].completed or 0
            container[mapInfo.id].failed = container[mapInfo.id].failed or 0
        end
    end
end

local function initializeDungeonStats(container)
    -- Only initialize if container is completely empty - don't wipe existing data
    if not container or next(container) ~= nil then
        return -- Container already has data, don't wipe it
    end
    
    local pool = fetchCurrentMythicPool()
    for _, mapInfo in ipairs(pool) do
        container[mapInfo.id] = { completed = 0, failed = 0, name = mapInfo.name }
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
        completionData.weekly.completed = 0
        completionData.weekly.failed = 0
        initializeDungeonStats(completionData.weekly.dungeons)
        completionData.weekly.resetTime = nextReset
    end
end

function CompletionTracker:trackRun(mapID, success, level)
    if not completionData then return end
    if not mapID then return end
    
    -- Don't do season checks during tracking - just track the run
    -- Season checks will happen when viewing stats
    
    checkWeeklyReset()
    
    -- Ensure the mapID exists in our tracking tables, if not, add it
    if not completionData.seasonal.dungeons[mapID] then
        -- Try to get the name from the API
        local name = C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(mapID) or ("Dungeon " .. tostring(mapID))
        completionData.seasonal.dungeons[mapID] = { completed = 0, failed = 0, name = name }
    end
    
    if not completionData.weekly.dungeons[mapID] then
        -- Try to get the name from the API
        local name = C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(mapID) or ("Dungeon " .. tostring(mapID))
        completionData.weekly.dungeons[mapID] = { completed = 0, failed = 0, name = name }
    end

    if success then
        completionData.seasonal.completed = completionData.seasonal.completed + 1
        completionData.seasonal.dungeons[mapID].completed = completionData.seasonal.dungeons[mapID].completed + 1
        completionData.weekly.completed = completionData.weekly.completed + 1
        completionData.weekly.dungeons[mapID].completed = completionData.weekly.dungeons[mapID].completed + 1
    else
        completionData.seasonal.failed = completionData.seasonal.failed + 1
        completionData.seasonal.dungeons[mapID].failed = completionData.seasonal.dungeons[mapID].failed + 1
        completionData.weekly.failed = completionData.weekly.failed + 1
        completionData.weekly.dungeons[mapID].failed = completionData.weekly.dungeons[mapID].failed + 1
    end
end

function CompletionTracker:getStats()
    -- Perform season/pool check when stats are actually requested (APIs should be ready by now)
    if self._checkSeasonalChange then 
        self:_checkSeasonalChange() 
    end
    
    -- Ensure weekly reset is current
    checkWeeklyReset()

    local stats = {
        seasonal = {
            rate = calculateCompletionRate(completionData.seasonal.completed, completionData.seasonal.failed),
            completed = completionData.seasonal.completed,
            failed = completionData.seasonal.failed,
            dungeons = {}
        },
        weekly = {
            rate = calculateCompletionRate(completionData.weekly.completed, completionData.weekly.failed),
            completed = completionData.weekly.completed,
            failed = completionData.weekly.failed,
            dungeons = {}
        }
    }

    for mapID, data in pairs(completionData.seasonal.dungeons) do
        stats.seasonal.dungeons[mapID] = {
            name = data.name,
            rate = calculateCompletionRate(data.completed, data.failed),
            completed = data.completed,
            failed = data.failed
        }
    end

    for mapID, data in pairs(completionData.weekly.dungeons) do
        stats.weekly.dungeons[mapID] = {
            name = data.name,
            rate = calculateCompletionRate(data.completed, data.failed),
            completed = data.completed,
            failed = data.failed
        }
    end

    return stats
end

function CompletionTracker:initialize()
    if not MRM_CompletionData then
        MRM_CompletionData = {
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
    end

    completionData = MRM_CompletionData

    -- Only initialize if the dungeons tables are completely empty
    if not completionData.seasonal.dungeons then
        completionData.seasonal.dungeons = {}
    end
    if not completionData.weekly.dungeons then
        completionData.weekly.dungeons = {}
    end
    
    -- Only call initializeDungeonStats if tables are truly empty
    initializeDungeonStats(completionData.seasonal.dungeons)
    initializeDungeonStats(completionData.weekly.dungeons)

    -- Separate function to just sync dungeon pools without season checking
    function self:_syncDungeonPools()
        -- Populate DungeonData for UI consumers (names and par times) FIRST
        if MrMythical and MrMythical.DungeonData and MrMythical.DungeonData.refreshFromAPI then
            MrMythical.DungeonData.refreshFromAPI()
        end
        
        -- Just sync the current dungeon pool for UI purposes, no season validation
        syncDungeonStats(completionData.seasonal.dungeons)
        syncDungeonStats(completionData.weekly.dungeons)
    end

    -- Attach helper for seasonal/pool change detection
    function self:_checkSeasonalChange()
        local currentSeasonID = (C_MythicPlus and C_MythicPlus.GetCurrentSeason and C_MythicPlus.GetCurrentSeason()) or nil
        
        -- Don't do season checks if the API isn't ready yet (returns -1 or nil during loading)
        if not currentSeasonID or currentSeasonID <= 0 then
            return
        end
        
        -- Populate DungeonData for UI consumers (names and par times)
        if MrMythical and MrMythical.DungeonData and MrMythical.DungeonData.refreshFromAPI then
            MrMythical.DungeonData.refreshFromAPI()
        end
        local currentSig = getMapPoolSignature()

        -- First-time seed
        if completionData.seasonal.seasonID == nil or completionData.seasonal.seasonID <= 0 then
            completionData.seasonal.seasonID = currentSeasonID
        end
        if completionData.seasonal.mapPoolSig == nil then
            completionData.seasonal.mapPoolSig = currentSig
        end

        local seasonChanged = currentSeasonID and completionData.seasonal.seasonID and currentSeasonID ~= completionData.seasonal.seasonID
        local poolChanged = currentSig ~= completionData.seasonal.mapPoolSig

        if seasonChanged then
            -- Only reset if the season actually changed (not just on every load)
            completionData.seasonal.completed = 0
            completionData.seasonal.failed = 0
            -- Clear the dungeons table but don't call initializeDungeonStats (let it populate naturally)
            for k in pairs(completionData.seasonal.dungeons) do 
                completionData.seasonal.dungeons[k].completed = 0
                completionData.seasonal.dungeons[k].failed = 0
            end

            -- Update markers
            completionData.seasonal.seasonID = currentSeasonID
            completionData.seasonal.mapPoolSig = currentSig
        elseif poolChanged and currentSig and currentSig ~= "" then
            -- Pool changed but not season - just sync the available dungeons
            -- Only do this if we have a valid current signature
            syncDungeonStats(completionData.seasonal.dungeons)
            completionData.seasonal.mapPoolSig = currentSig
        else
            -- No changes - just make sure current pool dungeons are available for tracking
            syncDungeonStats(completionData.seasonal.dungeons)
        end

        -- Weekly should also keep pool in sync (without resetting counts unless weekly timer says so)
        syncDungeonStats(completionData.weekly.dungeons)
    end

    -- Sync dungeon pools immediately for UI purposes (but don't do season validation)
    self:_syncDungeonPools()
    
    -- Also try to refresh dungeon data after a short delay to ensure APIs are ready
    C_Timer.After(2, function()
        if MrMythical and MrMythical.DungeonData and MrMythical.DungeonData.refreshFromAPI then
            MrMythical.DungeonData.refreshFromAPI()
        end
    end)

    checkWeeklyReset()
end

MrMythical.CompletionTracker = CompletionTracker
_G.MrMythical = MrMythical