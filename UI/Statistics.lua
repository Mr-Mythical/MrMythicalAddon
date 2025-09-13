--[[
Statistics.lua - Statistics Content

Handles the statistics interface and data presentation.
--]]

local MrMythical = MrMythical or {}
MrMythical.Statistics = {}

local Statistics = MrMythical.Statistics
local UIConstants = MrMythical.UIConstants
local UIHelpers = MrMythical.UIHelpers
local CompletionTracker = MrMythical.CompletionTracker

function Statistics.create(parentFrame)
    local row1 = CreateFrame("Frame", nil, parentFrame)
    row1:SetPoint("TOPLEFT", UIConstants.LAYOUT.LARGE_PADDING, -UIConstants.LAYOUT.LARGE_PADDING)
    row1:SetSize(UIConstants.FRAME.CONTENT_WIDTH - (UIConstants.LAYOUT.LARGE_PADDING * 2), 220)
    
    local row2 = CreateFrame("Frame", nil, parentFrame)
    row2:SetPoint("TOPLEFT", UIConstants.LAYOUT.LARGE_PADDING, -250)
    row2:SetSize(UIConstants.FRAME.CONTENT_WIDTH - (UIConstants.LAYOUT.LARGE_PADDING * 2), 220)
    
    local statsOverview = Statistics.createStatsOverview(row1)
    local recentActivity = Statistics.createRecentActivity(row1)
    local dungeonBreakdown = Statistics.createDungeonBreakdown(row2)
    
    Statistics.updateStats(statsOverview, recentActivity, dungeonBreakdown)
    
    parentFrame:SetScript("OnShow", function()
        if statsOverview and recentActivity and dungeonBreakdown then
            C_Timer.After(0.1, function()
                if parentFrame:IsVisible() then
                    Statistics.updateStats(statsOverview, recentActivity, dungeonBreakdown)
                end
            end)
        end
    end)
end

function Statistics.createStatsOverview(parentFrame)
    local statsLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Statistics Overview", "TOPLEFT", 0, 0)
    UIHelpers.setTextColor(statsLabel, "SUCCESS_HIGH")

    local statsOverview = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "", "TOPLEFT", 0, -30)
    statsOverview:SetWidth(320)
    statsOverview:SetHeight(180)
    statsOverview:SetJustifyH("LEFT")
    statsOverview:SetJustifyV("TOP")

    return statsOverview
end

function Statistics.createRecentActivity(parentFrame)
    local activityLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Recent Activity", "TOPLEFT", 340, 0)
    UIHelpers.setTextColor(activityLabel, "SUCCESS_HIGH")
    
    local recentActivity = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "", "TOPLEFT", 340, -30)
    recentActivity:SetWidth(320)
    recentActivity:SetHeight(180)
    recentActivity:SetJustifyH("LEFT")
    recentActivity:SetJustifyV("TOP")

    return recentActivity
end

function Statistics.createDungeonBreakdown(parentFrame)
    local dungeonLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Dungeon Breakdown", "TOPLEFT", 0, 0)
    UIHelpers.setTextColor(dungeonLabel, "SUCCESS_HIGH")
    
    local dungeonTableFrame = Statistics.createDungeonTable(parentFrame)
    
    local dungeonRows = {}
    
    C_Timer.After(0.1, function()
        Statistics.updateDungeonBreakdown(dungeonTableFrame, dungeonRows, "seasonal")
    end)
    
    return {
        rows = dungeonRows,
        tableFrame = dungeonTableFrame
    }
end

function Statistics.createDungeonTable(parentFrame)
    local dungeonTableFrame = CreateFrame("Frame", nil, parentFrame)
    dungeonTableFrame:SetPoint("TOPLEFT", 0, -25)
    dungeonTableFrame:SetSize(670, 190)
    
    UIHelpers.createHeader(dungeonTableFrame, "Dungeon", 0, 140)
    UIHelpers.createHeader(dungeonTableFrame, "In Time", 140, 70)
    UIHelpers.createHeader(dungeonTableFrame, "Overtime", 210, 70)
    UIHelpers.createHeader(dungeonTableFrame, "Abandoned", 280, 70)
    UIHelpers.createHeader(dungeonTableFrame, "Total", 350, 60)
    UIHelpers.createHeader(dungeonTableFrame, "Completion %", 410, 70)
    UIHelpers.createHeader(dungeonTableFrame, "In Time %", 480, 70)
    
    return dungeonTableFrame
end

function Statistics.updateDungeonBreakdown(dungeonTableFrame, dungeonRows, stats)
    if not stats or not dungeonTableFrame or not dungeonRows then
        return
    end
    
    local statsSource = stats.dungeons
    if not statsSource then
        return
    end
    
    local dungeonData = {}
    
    for mapID, data in pairs(statsSource) do
        local dungeonTotal = (data.completedIntime or 0) + (data.completedOvertime or 0) + (data.abandoned or 0)
        local completedTotal = (data.completedIntime or 0) + (data.completedOvertime or 0)
        local intimeRate = completedTotal > 0 and math.floor((data.completedIntime or 0) / completedTotal * 100) or 0
        
        table.insert(dungeonData, {
            name = data.name or ("Dungeon " .. tostring(mapID)),
            completedIntime = data.completedIntime or 0,
            completedOvertime = data.completedOvertime or 0, 
            abandoned = data.abandoned or 0,
            total = dungeonTotal,
            successRate = dungeonTotal > 0 and math.floor((completedTotal / dungeonTotal) * 100) or 0,
            intimeRate = intimeRate
        })
    end
    
    table.sort(dungeonData, function(a, b) 
        if a.total == b.total then
            return a.name < b.name
        end
        return a.total > b.total 
    end)
    
    -- Clear existing rows
    for i = 0, #dungeonRows do
        if dungeonRows[i] then
            for _, element in pairs(dungeonRows[i]) do
                if element and element.Hide then
                    element:Hide()
                end
            end
        end
    end
    for k in pairs(dungeonRows) do dungeonRows[k] = nil end

    local startY = -25
    for i, data in ipairs(dungeonData) do
        local yOffset = startY - ((i - 1) * UIConstants.LAYOUT.ROW_HEIGHT)
        local isEven = i % 2 == 0
        
        UIHelpers.createRowBackground(dungeonTableFrame, yOffset, 670, isEven)
        
        dungeonRows[i] = {
            name = UIHelpers.createRowText(dungeonTableFrame, data.name, 0, yOffset, 140),
            inTime = UIHelpers.createRowText(dungeonTableFrame, tostring(data.completedIntime), 140, yOffset, 70),
            overtime = UIHelpers.createRowText(dungeonTableFrame, tostring(data.completedOvertime), 210, yOffset, 70),
            abandoned = UIHelpers.createRowText(dungeonTableFrame, tostring(data.abandoned), 280, yOffset, 70),
            total = UIHelpers.createRowText(dungeonTableFrame, tostring(data.total), 350, yOffset, 60),
            rate = UIHelpers.createRowText(dungeonTableFrame, string.format("%d%%", data.successRate), 410, yOffset, 70),
            intimeRate = UIHelpers.createRowText(dungeonTableFrame, string.format("%d%%", data.intimeRate), 480, yOffset, 70)
        }
        
        local colorName = UIHelpers.getSuccessRateColor(data.successRate)
        UIHelpers.setTextColor(dungeonRows[i].rate, colorName)
        
        local intimeColorName = UIHelpers.getSuccessRateColor(data.intimeRate)
        UIHelpers.setTextColor(dungeonRows[i].intimeRate, intimeColorName)
        
        if data.completedIntime > 0 then
            UIHelpers.setTextColor(dungeonRows[i].inTime, "SUCCESS_HIGH")
        end
        if data.completedOvertime > 0 then
            UIHelpers.setTextColor(dungeonRows[i].overtime, "SUCCESS_MEDIUM")
        end
        if data.abandoned > 0 then
            UIHelpers.setTextColor(dungeonRows[i].abandoned, "SUCCESS_LOW")
        end
    end

    if #dungeonData == 0 then
        dungeonRows[1] = {
            name = UIHelpers.createRowText(dungeonTableFrame, "No dungeon data available", 0, startY, 670)
        }
        dungeonRows[1].name:SetTextColor(0.7, 0.7, 0.7)
    end
end

function Statistics.updateStats(statsOverview, recentActivity, dungeonBreakdown)
    if not CompletionTracker then
        statsOverview:SetText("CompletionTracker not available\n\nPlease run some Mythic+ dungeons to see statistics here.")
        recentActivity:SetText("No data available")
        return
    end

    local success, stats = pcall(function() return CompletionTracker:getStats() end)
    if not success or not stats then
        statsOverview:SetText("Error loading statistics: " .. tostring(stats) .. "\n\nTry again in a moment.")
        recentActivity:SetText("Error loading data")
        return
    end

    local success2, charStats = pcall(function() return CompletionTracker:getStats() end)
    local charStats = success2 and charStats or {}

    local charName = UnitName("player") or "Unknown"
    local charClass = select(2, UnitClass("player")) or "Unknown"
    local currentSeason = C_MythicPlus.GetCurrentSeason() or "Unknown"

    local seasonTotal = (stats.completedIntime or 0) + (stats.completedOvertime or 0) + (stats.abandoned or 0)
    local seasonRate = stats.rate or 0
    local bestLevel = charStats.bestLevel or 0

    local statsText = string.format("%s (%s)\n\n", charName, charClass)

    local completionRate = seasonTotal > 0 and math.floor((stats.completed or 0) / seasonTotal * 100) or 0
    local intimeRate = (stats.completed or 0) > 0 and math.floor((stats.completedIntime or 0) / (stats.completed or 0) * 100) or 0
    local abandonmentRate = seasonTotal > 0 and math.floor((stats.abandoned or 0) / seasonTotal * 100) or 0
    local allRunsIntimeRate = seasonTotal > 0 and math.floor((stats.completedIntime or 0) / seasonTotal * 100) or 0

    local uniqueDungeons = 0
    if stats.dungeons then
        for _ in pairs(stats.dungeons) do
            uniqueDungeons = uniqueDungeons + 1
        end
    end

    statsText = statsText .. string.format("Total Runs: %d\nCompleted: %d (%d%%)\n  • In Time: %d (%d%%)\n  • Overtime: %d (%d%%)\nAbandoned: %d (%d%%)\nBest Level: +%d\nIn-Time Rate (All Runs): %d%%",
        seasonTotal,
        stats.completed or 0, completionRate,
        stats.completedIntime or 0, intimeRate,
        stats.completedOvertime or 0, 100 - intimeRate,
        stats.abandoned or 0, abandonmentRate,
        bestLevel,
        allRunsIntimeRate
    )

    statsOverview:SetText(statsText)

    local allRuns = CompletionTracker:getRunHistory()
    local activityText = ""
    
    if #allRuns > 0 then
        local recentRuns = {}
        for i = 1, math.min(8, #allRuns) do
            table.insert(recentRuns, allRuns[i])
        end

        for _, run in ipairs(recentRuns) do
            local runResult = CompletionTracker.calculateRunResult(run)
            local dungeonName = run.dungeon.name
            
            if runResult == "completed_intime" or runResult == "completed_overtime" then
                local chestLevel = run.keystoneUpgradeLevels or 0
                local timeStr = run.time and MrMythical.DungeonData.formatTime(run.time) or "Unknown"
                
                local scoreIncrease = 0
                if run.newOverallDungeonScore and run.oldOverallDungeonScore then
                    scoreIncrease = run.newOverallDungeonScore - run.oldOverallDungeonScore
                end
                
                local color = ""
                local statusPrefix = ""
                
                if runResult == "completed_intime" then
                    color = "|cFF00FF00"
                    if chestLevel >= 3 then
                        statusPrefix = color .. "+++" .. run.level .. "|r"
                    elseif chestLevel >= 2 then
                        statusPrefix = color .. "++" .. run.level .. "|r"
                    elseif chestLevel >= 1 then
                        statusPrefix = color .. "+" .. run.level .. "|r"
                    else
                        statusPrefix = color .. run.level .. "|r"
                    end
                else
                    color = "|cFF888888"
                    statusPrefix = color .. run.level .. "|r"
                end
                
                local scoreStr = ""
                if scoreIncrease > 0 then
                    scoreStr = string.format(" +%d", scoreIncrease)
                end
                
                activityText = activityText .. string.format("\n%s %s%s|r (%s%s)", statusPrefix, color, dungeonName, timeStr, scoreStr)
            elseif runResult == "abandoned" then
                activityText = activityText .. string.format("\n|cFFFF0000%d|r |cFFFF0000%s|r", run.level, dungeonName)
            end
        end
    else
        activityText = "No runs recorded yet."
    end

    recentActivity:SetText(activityText)
    
    if dungeonBreakdown and dungeonBreakdown.tableFrame and dungeonBreakdown.rows then
        Statistics.updateDungeonBreakdown(dungeonBreakdown.tableFrame, dungeonBreakdown.rows, stats)
    end
end

-- Add statistics to ContentCreators
if MrMythical.ContentCreators then
    MrMythical.ContentCreators.stats = Statistics.create
end

return Statistics
