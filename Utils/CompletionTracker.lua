--[[
CompletionTracker.lua - Mythic+ Run History & Analytics

Tracks Mythic+ dungeon completion statistics with analytics capabilities.
Stores individual run records and generates statistics dynamically.

Data Structure: MRM_RunHistory (global storage with character filtering)
Dependencies: WoW APIs, MrMythical.DungeonData
--]]

local MrMythical = MrMythical or {}
MrMythical.CompletionTracker = MrMythical.CompletionTracker or {}

local CompletionTracker = {}

local MAX_RUN_HISTORY = 5000

local function debugLog(message, ...)
    if MrMythicalDebug then
        print(string.format("[MrMythical CompletionTracker] " .. message, ...))
    end
end

local function initializeSavedVariables()
    MRM_RunHistory = {
        version = 1,
        runs = {}
    }
end

local RunResultCalculator = {}

function RunResultCalculator.getCategory(run)
    if run.completed then
        return run.onTime and "completed_intime" or "completed_overtime"
    else
        return "abandoned"
    end
end

local StatsAggregator = {}

function StatsAggregator.initializeDungeonStats(mapID, dungeonName)
    return {
        name = dungeonName,
        runs = 0,
        abandoned = 0,
        completedIntime = 0,
        completedOvertime = 0,
        bestTime = nil
    }
end

function StatsAggregator.updateDungeonStats(dungeonStats, run, runResult)
    dungeonStats.runs = dungeonStats.runs + 1

    if runResult == "completed_intime" then
        dungeonStats.completedIntime = dungeonStats.completedIntime + 1
        if run.time and (not dungeonStats.bestTime or run.time < dungeonStats.bestTime) then
            dungeonStats.bestTime = run.time
        end
    elseif runResult == "completed_overtime" then
        dungeonStats.completedOvertime = dungeonStats.completedOvertime + 1
        if run.time and (not dungeonStats.bestTime or run.time < dungeonStats.bestTime) then
            dungeonStats.bestTime = run.time
        end
    elseif runResult == "abandoned" then
        dungeonStats.abandoned = dungeonStats.abandoned + 1
    end
end

CompletionTracker.calculateRunResult = RunResultCalculator.getCategory

local function manageMemory(historyTable, maxRuns)
    if #historyTable.runs > maxRuns then
        local excess = #historyTable.runs - maxRuns
        for i = 1, excess do
            table.remove(historyTable.runs, 1)
        end
        debugLog("Removed %d old runs to manage memory", excess)
    end
end

local DataCollectors = {}

function DataCollectors.getPlayerData()
    return {
        name = UnitName("player"),
        class = select(2, UnitClass("player")),
        spec = GetSpecialization() and select(2, GetSpecializationInfo(GetSpecialization())) or "Unknown",
        itemLevel = math.floor(GetAverageItemLevel())
    }
end

function DataCollectors.getDungeonData(mapID)
    return {
        mapID = mapID,
        name = MrMythical.DungeonData.getDungeonName(mapID),
        timeLimit = MrMythical.DungeonData.getParTime(mapID) or 0
    }
end

function DataCollectors.getDeathData()
    local numDeaths, timeLost = C_ChallengeMode.GetDeathCount()
    
    if numDeaths and numDeaths > 0 then
        return {
            deaths = numDeaths,
            timeLost = timeLost or 0
        }
    else
        return {
            deaths = 0,
            timeLost = 0
        }
    end
end

local RunRecordManager = {}

function RunRecordManager.createInitial(mapID, level)
    return {
        startTime = time(),
        level = level,
        completed = false,
        deaths = nil,
        time = nil,
        seasonID = C_MythicPlus.GetCurrentSeason(),
        player = DataCollectors.getPlayerData(),
        dungeon = DataCollectors.getDungeonData(mapID)
    }
end

function RunRecordManager.updateWithCompletion(runRecord, challengeInfo)
    runRecord.completed = true
    
    local deathData = DataCollectors.getDeathData()
    runRecord.deaths = deathData.deaths
    runRecord.timeLost = deathData.timeLost

    if runRecord.dungeon.timeLimit == 0 and challengeInfo.timeLimit then
        runRecord.dungeon.timeLimit = challengeInfo.timeLimit
    end

    if challengeInfo.time and challengeInfo.time > 0 then
        runRecord.time = math.floor(challengeInfo.time / 1000)
    end
    
    runRecord.onTime = challengeInfo.onTime or false
    runRecord.keystoneUpgradeLevels = challengeInfo.keystoneUpgradeLevels or 0
    runRecord.oldOverallDungeonScore = challengeInfo.oldOverallDungeonScore
    runRecord.newOverallDungeonScore = challengeInfo.newOverallDungeonScore

    debugLog("Updated run: %s (+%d) - OnTime: %s, Upgrade: +%d", 
        runRecord.dungeon.name, runRecord.level, 
        tostring(runRecord.onTime), runRecord.keystoneUpgradeLevels)
    
    return runRecord
end

function RunRecordManager.findExistingRun(mapID, level)
    local latestRun = nil
    local latestStartTime = 0

    for i, run in ipairs(MRM_RunHistory.runs) do
        if run.dungeon.mapID == mapID and
           run.level == level and
           not run.completed and
           not run.time then
            -- Find the most recent run with this mapID/level combination
            if run.startTime and run.startTime > latestStartTime then
                latestRun = run
                latestStartTime = run.startTime
            end
        end
    end
    return latestRun
end

function CompletionTracker:trackRunStart(mapID, level)
    if not mapID then return end

    debugLog("Starting run: MapID=%d, Level=%d", mapID, level or 0)

    local runRecord = RunRecordManager.createInitial(mapID, level)
    table.insert(MRM_RunHistory.runs, runRecord)
end

function CompletionTracker:trackRun(challengeInfo)
    if type(challengeInfo) ~= "table" then
        debugLog("Invalid challenge info: expected table, got %s", type(challengeInfo))
        return
    end
    
    if not challengeInfo.mapChallengeModeID then
        debugLog("Invalid challenge info: missing mapChallengeModeID")
        return
    end

    local existingRun = RunRecordManager.findExistingRun(challengeInfo.mapChallengeModeID, challengeInfo.level)
    
    if existingRun then
        RunRecordManager.updateWithCompletion(existingRun, challengeInfo)
    else
        debugLog("No existing run found, creating new record")
        local runRecord = RunRecordManager.createInitial(challengeInfo.mapChallengeModeID, challengeInfo.level)
        RunRecordManager.updateWithCompletion(runRecord, challengeInfo)
        table.insert(MRM_RunHistory.runs, runRecord)
    end

    manageMemory(MRM_RunHistory, MAX_RUN_HISTORY)
end

function CompletionTracker:getStats()
    local runs = MRM_RunHistory.runs or {}
    local currentCharacterName = UnitName("player")
    local currentSeason = C_MythicPlus.GetCurrentSeason()
    
    local stats = {
        totalRuns = 0,
        completedIntime = 0,
        completedOvertime = 0,
        abandoned = 0,
        completed = 0,
        rate = 0,
        abandonmentRate = 0,
        bestLevel = 0,
        dungeons = {},
        runHistory = {}
    }
    
    if not currentSeason then
        return stats
    end

    debugLog("getStats - Total runs: %d, Character: %s", #runs, tostring(currentCharacterName))

    for _, run in ipairs(runs) do
        if run.player and run.player.name == currentCharacterName then
            local runSeason = run.seasonID or C_MythicPlus.GetCurrentSeason()
            if runSeason == currentSeason then
                table.insert(stats.runHistory, run)
                
                local runResult = RunResultCalculator.getCategory(run)
                
                if runResult == "completed_intime" then
                    stats.completedIntime = stats.completedIntime + 1
                    stats.bestLevel = math.max(stats.bestLevel, run.level)
                elseif runResult == "completed_overtime" then
                    stats.completedOvertime = stats.completedOvertime + 1
                    stats.bestLevel = math.max(stats.bestLevel, run.level)
                elseif runResult == "abandoned" then
                    stats.abandoned = stats.abandoned + 1
                end

                local mapID = run.dungeon.mapID
                if not stats.dungeons[mapID] then
                    stats.dungeons[mapID] = StatsAggregator.initializeDungeonStats(mapID, run.dungeon.name)
                end
                
                StatsAggregator.updateDungeonStats(stats.dungeons[mapID], run, runResult)
            end
        end
    end

    stats.totalRuns = #stats.runHistory
    stats.completed = stats.completedIntime + stats.completedOvertime
    
    if stats.totalRuns > 0 then
        stats.rate = (stats.completed / stats.totalRuns) * 100
        stats.abandonmentRate = (stats.abandoned / stats.totalRuns) * 100
    end

    debugLog("Filtered runs: %d for %s", stats.totalRuns, tostring(currentCharacterName))

    return stats
end

function CompletionTracker:getRunHistory(filters)
    local stats = self:getStats()
    local characterFilteredRuns = stats.runHistory
    
    if not filters then
        return characterFilteredRuns
    end

    local filteredRuns = {}
    for _, run in ipairs(characterFilteredRuns) do
        local matches = true

        if filters.dungeon and run.dungeon.mapID ~= filters.dungeon then
            matches = false
        end

        if filters.completed ~= nil and run.completed ~= filters.completed then
            matches = false
        end

        if filters.abandoned ~= nil then
            local isAbandoned = not run.completed
            if isAbandoned ~= filters.abandoned then
                matches = false
            end
        end

        if filters.minLevel and run.level < filters.minLevel then
            matches = false
        end

        if filters.maxLevel and run.level > filters.maxLevel then
            matches = false
        end

        if matches then
            table.insert(filteredRuns, run)
        end
    end

    return filteredRuns
end

initializeSavedVariables()

MrMythical = MrMythical or {}
MrMythical.CompletionTracker = CompletionTracker
_G.MrMythical = MrMythical

debugLog("CompletionTracker module loaded")