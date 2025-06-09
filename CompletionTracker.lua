CompletionTracker = {}
local CompletionTracker = CompletionTracker
local Constants = MythicalConstants

local C_ChallengeMode = _G.C_ChallengeMode

local completionData = {
    seasonal = {
        completed = 0,
        failed = 0,
        dungeons = {}
    },
    weekly = {
        completed = 0,
        failed = 0,
        dungeons = {},
        resetTime = nil
    }
}

local function InitializeDungeonStats(container)
    for _, mapInfo in ipairs(Constants.MYTHIC_MAPS) do
        container[mapInfo.id] = {
            completed = 0,
            failed = 0,
            name = mapInfo.name
        }
    end
end

local function CalculateCompletionRate(completed, failed)
    local total = completed + failed
    if total == 0 then return 0 end
    return (completed / total) * 100
end

local function CheckWeeklyReset()
    local currentTime = time()
    local secondsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
    local nextReset = currentTime + secondsUntilReset
    
    if not completionData.weekly.resetTime or currentTime >= completionData.weekly.resetTime then
        completionData.weekly.completed = 0
        completionData.weekly.failed = 0
        InitializeDungeonStats(completionData.weekly.dungeons)
        
        completionData.weekly.resetTime = nextReset
    end
end

function CompletionTracker:TrackRun(mapID, success, level)
    if not completionData then return end
    if not mapID then return end
    if not completionData.seasonal.dungeons[mapID] or not completionData.weekly.dungeons[mapID] then return end

    CheckWeeklyReset()
    
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

function CompletionTracker:GetStats()
    CheckWeeklyReset()
    
    local stats = {
        seasonal = {
            rate = CalculateCompletionRate(completionData.seasonal.completed, completionData.seasonal.failed),
            completed = completionData.seasonal.completed,
            failed = completionData.seasonal.failed,
            dungeons = {}
        },
        weekly = {
            rate = CalculateCompletionRate(completionData.weekly.completed, completionData.weekly.failed),
            completed = completionData.weekly.completed,
            failed = completionData.weekly.failed,
            dungeons = {}
        }
    }
    
    for mapID, data in pairs(completionData.seasonal.dungeons) do
        stats.seasonal.dungeons[mapID] = {
            name = data.name,
            rate = CalculateCompletionRate(data.completed, data.failed),
            completed = data.completed,
            failed = data.failed
        }
    end
    
    for mapID, data in pairs(completionData.weekly.dungeons) do
        stats.weekly.dungeons[mapID] = {
            name = data.name,
            rate = CalculateCompletionRate(data.completed, data.failed),
            completed = data.completed,
            failed = data.failed
        }
    end
    
    return stats
end

function CompletionTracker:Initialize()
    if not MRM_CompletionData then
        MRM_CompletionData = {
            seasonal = {
                completed = 0,
                failed = 0,
                dungeons = {}
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

    if not completionData.seasonal.dungeons or next(completionData.seasonal.dungeons) == nil then
        InitializeDungeonStats(completionData.seasonal.dungeons)
    end
    if not completionData.weekly.dungeons or next(completionData.weekly.dungeons) == nil then
        InitializeDungeonStats(completionData.weekly.dungeons)
    end

    CheckWeeklyReset()
end

function CompletionTracker:ResetStats(scope)
    if not completionData then return end

    if scope == "all" or scope == "seasonal" then
        completionData.seasonal.completed = 0
        completionData.seasonal.failed = 0
        InitializeDungeonStats(completionData.seasonal.dungeons)
    end

    if scope == "all" or scope == "weekly" then
        completionData.weekly.completed = 0
        completionData.weekly.failed = 0
        InitializeDungeonStats(completionData.weekly.dungeons)
    end
end

return CompletionTracker