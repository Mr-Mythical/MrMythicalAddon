--[[
UI.lua - Mythic+ Interface

Unified tabbed interface that consolidates all Mr. Mythical functionality.

Dependencies: RewardsFunctions, DungeonData, CompletionTracker, WoW APIs
--]]

local MrMythical = MrMythical or {}
MrMythical.UnifiedUI = {}

local UnifiedUI = MrMythical.UnifiedUI
local RewardsFunctions = MrMythical.RewardsFunctions
local DungeonData = MrMythical.DungeonData
local CompletionTracker = MrMythical.CompletionTracker

local UI_CONSTANTS = {
    FRAME = {
        WIDTH = 850,
        HEIGHT = 500,
        NAV_PANEL_WIDTH = 140,
        CONTENT_WIDTH = 680,
    },
    LAYOUT = {
        ROW_HEIGHT = 25,
        LARGE_ROW_HEIGHT = 30,
        BUTTON_HEIGHT = 30,
        PADDING = 10,
        LARGE_PADDING = 20,
    },
    COLORS = {
        EVEN_ROW = {r = 0.1, g = 0.1, b = 0.1, a = 0.3},
        ODD_ROW = {r = 0.15, g = 0.15, b = 0.15, a = 0.3},
        SUCCESS_HIGH = {r = 0, g = 1, b = 0},
        SUCCESS_MEDIUM = {r = 1, g = 1, b = 0},
        SUCCESS_LOW = {r = 1, g = 0, b = 0},
        DISABLED = {r = 0.5, g = 0.5, b = 0.5},
        INFO_TEXT = {r = 0.8, g = 0.8, b = 0.8},
        NAV_BACKGROUND = {r = 0.1, g = 0.1, b = 0.1, a = 0.8}
    },
    CONTENT_TYPES = {
        DASHBOARD = "dashboard",
        REWARDS = "rewards",
        SCORES = "scores",
        STATS = "stats",
        TIMES = "times",
        SETTINGS = "settings"
    }
}

local UIHelpers = {}

function UIHelpers.createFontString(parent, layer, font, text, point, x, y)
    local fontString = parent:CreateFontString(nil, layer or "OVERLAY", font or "GameFontNormal")
    if point then
        fontString:SetPoint(point, x or 0, y or 0)
    end
    if text then
        fontString:SetText(text)
    end
    return fontString
end

function UIHelpers.createHeader(parent, text, x, width)
    local header = UIHelpers.createFontString(parent, "OVERLAY", "GameFontHighlight", text, "TOPLEFT", x, 0)
    header:SetWidth(width)
    header:SetJustifyH("CENTER")
    return header
end

function UIHelpers.createRowBackground(parent, yOffset, width, isEven)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, yOffset)
    bg:SetSize(width, UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
    
    local color = isEven and UI_CONSTANTS.COLORS.EVEN_ROW or UI_CONSTANTS.COLORS.ODD_ROW
    bg:SetColorTexture(color.r, color.g, color.b, color.a)
    return bg
end

function UIHelpers.createRowText(parent, text, x, yOffset, width, color)
    local fontString = UIHelpers.createFontString(parent, "OVERLAY", "GameFontNormal", text, "TOPLEFT", x, yOffset)
    fontString:SetWidth(width)
    fontString:SetJustifyH("CENTER")
    
    if color then
        fontString:SetTextColor(color.r, color.g, color.b)
    end
    return fontString
end

function UIHelpers.setTextColor(fontString, colorName)
    local color = UI_CONSTANTS.COLORS[colorName]
    if color then
        fontString:SetTextColor(color.r, color.g, color.b, color.a)
    end
end

local UIContentCreators = {}
local NavigationManager = {}

function UIContentCreators.dashboard(parentFrame)
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge", 
        "Mr. Mythical Dashboard", "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    
    local subtitle = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontHighlight",
        "Mythic+ Tools & Information", "TOP", 0, -5)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    local welcome = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "Welcome to Mr. Mythical! Use the navigation panel to access different tools.", "TOP", 0, -30)
    welcome:SetPoint("TOP", subtitle, "BOTTOM", 0, -30)
    welcome:SetWidth(400)
    welcome:SetJustifyH("CENTER")
    
    local version = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontDisableSmall",
        "Mr. Mythical by Braunerr", "BOTTOM", 0, UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    UIHelpers.setTextColor(version, "DISABLED")
end

function UIContentCreators.rewards(parentFrame)
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Mythic+ Rewards", "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    
    local rewardsTableFrame = CreateFrame("Frame", nil, parentFrame)
    rewardsTableFrame:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -60)
    rewardsTableFrame:SetSize(530, 380)
    
    UIContentCreators.createRewardsTable(rewardsTableFrame)
end

function UIContentCreators.createRewardsTable(parentFrame)
    UIHelpers.createHeader(parentFrame, "Key Level", 0, 80)
    UIHelpers.createHeader(parentFrame, "End of Dungeon", 80, 150)
    UIHelpers.createHeader(parentFrame, "Great Vault", 230, 150)
    UIHelpers.createHeader(parentFrame, "Crest Rewards", 380, 150)
    
    local startY = -25
    for level = 2, 12 do
        UIContentCreators.createRewardRow(parentFrame, level, startY, level - 2)
    end
end

function UIContentCreators.createRewardRow(parentFrame, level, startY, index)
    local yOffset = startY - (index * UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
    local isEven = level % 2 == 0
    
    UIHelpers.createRowBackground(parentFrame, yOffset, 530, isEven)
    
    local rewards = RewardsFunctions.getRewardsForKeyLevel(level)
    local crests = RewardsFunctions.getCrestReward(level)
    
    UIHelpers.createRowText(parentFrame, tostring(level), 0, yOffset, 80)
    UIHelpers.createRowText(parentFrame, 
        string.format("%s\n%s", rewards.dungeonItem, rewards.dungeonTrack), 
        80, yOffset, 150)
    UIHelpers.createRowText(parentFrame, 
        string.format("%s\n%s", rewards.vaultItem, rewards.vaultTrack), 
        230, yOffset, 150)
    UIHelpers.createRowText(parentFrame, 
        string.format("%s\n%d", crests.crestType, crests.crestAmount), 
        380, yOffset, 150)
end

function UIContentCreators.scores(parentFrame)
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Mythic+ Score Calculator", "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    
    local descText = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalSmall",
        "Hover over key levels in the left table to see potential score gains for your dungeons on the right",
        "TOP", 0, -10)
    descText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    descText:SetWidth(650)
    descText:SetJustifyH("CENTER")
    UIHelpers.setTextColor(descText, "INFO_TEXT")
    
    local timerSlider = UIContentCreators.createTimerSlider(parentFrame)
    local currentKeyLevel = UIContentCreators.createKeyLevelDropdown(parentFrame)
    local scoreRows, gainRows = UIContentCreators.createScoreTables(parentFrame)
    
    UIContentCreators.setupScoreCalculator(timerSlider, currentKeyLevel, scoreRows, gainRows)
end

function UIContentCreators.createTimerSlider(parentFrame)
    local timerLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "Timer Bonus:", "TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -80)
    
    local timerSlider = CreateFrame("Slider", "MrMythicalUnifiedTimerSlider", parentFrame, "OptionsSliderTemplate")
    timerSlider:SetPoint("TOPLEFT", 120, -75)
    timerSlider:SetSize(200, 20)
    timerSlider:SetMinMaxValues(0, 40)
    timerSlider:SetValue(0)
    timerSlider:SetValueStep(1)
    timerSlider.tooltipText = "Timer Percentage"
    
    _G[timerSlider:GetName() .. "Low"]:SetText("0%")
    _G[timerSlider:GetName() .. "High"]:SetText("40%")
    _G[timerSlider:GetName() .. "Text"]:SetText("0%")
    
    return timerSlider
end

function UIContentCreators.createKeyLevelDropdown(parentFrame)
    local currentKeyLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "Using Key Level:", "TOPLEFT", 350, -110)
    
    local currentKeyLevel = CreateFrame("Frame", "MrMythicalUnifiedCurrentKeyLevel", parentFrame, "UIDropDownMenuTemplate")
    currentKeyLevel:SetPoint("TOPLEFT", 450, -105)
    UIDropDownMenu_SetWidth(currentKeyLevel, 60)
    UIDropDownMenu_SetText(currentKeyLevel, "2")
    
    return currentKeyLevel
end

function UIContentCreators.createScoreTables(parentFrame)
    local scoreScrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
    scoreScrollFrame:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -110)
    scoreScrollFrame:SetSize(320, 320)
    
    local scoreContentFrame = CreateFrame("Frame", nil, scoreScrollFrame)
    scoreContentFrame:SetSize(320, 800)
    scoreScrollFrame:SetScrollChild(scoreContentFrame)
    
    UIHelpers.createHeader(scoreContentFrame, "Key Level", 0, 70)
    UIHelpers.createHeader(scoreContentFrame, "Base Score", 70, 80)
    UIHelpers.createHeader(scoreContentFrame, "Timer Bonus", 150, 80)
    UIHelpers.createHeader(scoreContentFrame, "Final Score", 230, 90)
    
    local gainsLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Your Dungeons", "TOPLEFT", 350, -80)
    
    local gainsTableFrame = CreateFrame("Frame", nil, parentFrame)
    gainsTableFrame:SetPoint("TOPLEFT", 350, -140)
    gainsTableFrame:SetSize(310, 290)
    
    UIHelpers.createHeader(gainsTableFrame, "Dungeon", 0, 110)
    UIHelpers.createHeader(gainsTableFrame, "Level", 110, 40)
    UIHelpers.createHeader(gainsTableFrame, "Score", 150, 50)
    UIHelpers.createHeader(gainsTableFrame, "Time", 200, 60)
    UIHelpers.createHeader(gainsTableFrame, "Gain", 260, 50)
    
    return UIContentCreators.createScoreRows(scoreContentFrame), UIContentCreators.createGainRows(gainsTableFrame)
end

function UIContentCreators.createScoreRows(scoreContentFrame)
    local scoreRows = {}
    local startY = -25
    
    for level = 2, 30 do
        local yOffset = startY - ((level - 2) * UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
        local isEven = level % 2 == 0
        
        UIHelpers.createRowBackground(scoreContentFrame, yOffset, 320, isEven)
        
        if RewardsFunctions and RewardsFunctions.scoreFormula then
            local baseScore = RewardsFunctions.scoreFormula(level)
            
            scoreRows[level] = {
                level = UIHelpers.createRowText(scoreContentFrame, tostring(level), 0, yOffset, 70),
                base = UIHelpers.createRowText(scoreContentFrame, tostring(baseScore), 70, yOffset, 80),
                bonus = UIHelpers.createRowText(scoreContentFrame, "+0", 150, yOffset, 80),
                final = UIHelpers.createRowText(scoreContentFrame, tostring(baseScore), 230, yOffset, 90)
            }
            
            local rowFrame = CreateFrame("Button", nil, scoreContentFrame)
            rowFrame:SetPoint("TOPLEFT", 0, yOffset)
            rowFrame:SetSize(320, UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
            rowFrame:EnableMouse(true)
            rowFrame.level = level
            scoreRows[level].frame = rowFrame
        end
    end
    
    return scoreRows
end

function UIContentCreators.createGainRows(gainsTableFrame)
    local gainRows = {}
    
    if not DungeonData or not DungeonData.MYTHIC_MAPS then
        return gainRows
    end
    
    if MrMythical.DungeonData and MrMythical.DungeonData.getAllDungeonData then
        local dungeonData = MrMythical.DungeonData.getAllDungeonData()
        local startY = -25
        
        for i, data in ipairs(dungeonData) do
            local yOffset = startY - ((i - 1) * UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
            local isEven = i % 2 == 0
            
            UIHelpers.createRowBackground(gainsTableFrame, yOffset, 310, isEven)
            
            local levelText = "--"
            if data.currentLevel > 0 then
                levelText = tostring(data.currentLevel)
            end
            
            local runTimeText = DungeonData and DungeonData.formatTime and DungeonData.formatTime(data.runTime) or "Unknown"
        
        gainRows[i] = {
            name = UIHelpers.createRowText(gainsTableFrame, data.mapInfo.name, 0, yOffset, 110),
            current = UIHelpers.createRowText(gainsTableFrame, levelText, 110, yOffset, 40),
            timer = UIHelpers.createRowText(gainsTableFrame, 
                data.currentScore > 0 and tostring(data.currentScore) or "--", 150, yOffset, 50),
            time = UIHelpers.createRowText(gainsTableFrame, runTimeText, 200, yOffset, 60),
            gain = UIHelpers.createRowText(gainsTableFrame, "--", 260, yOffset, 50)
        }
        
        if data.hasRun then
            if data.isInTime then
                UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_HIGH")
            else
                UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_LOW")
            end
        else
            UIHelpers.setTextColor(gainRows[i].current, "DISABLED")
        end
    end
    
    end
    
    return gainRows
end

function UIContentCreators.setupScoreCalculator(timerSlider, currentKeyLevel, scoreRows, gainRows)
    local function updateScores(timerPercentage)
        UIContentCreators.updateScoreTable(scoreRows, timerPercentage)
        UIContentCreators.updateDungeonGains(gainRows, currentKeyLevel, timerPercentage)
    end
    
    local function currentKeyLevelOnClick(self)
        UIDropDownMenu_SetText(currentKeyLevel, self.value)
        updateScores(timerSlider:GetValue())
    end
    
    local function currentKeyLevelInitialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for i = 2, 30 do
            info.text = i
            info.value = i
            info.func = currentKeyLevelOnClick
            UIDropDownMenu_AddButton(info)
        end
    end
    
    UIDropDownMenu_Initialize(currentKeyLevel, currentKeyLevelInitialize)
    
    timerSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName() .. "Text"]:SetText(string.format("%d%%", value))
        updateScores(value)
    end)
    
    for level, row in pairs(scoreRows) do
        if row.frame then
            row.frame:SetScript("OnEnter", function(self)
                UIDropDownMenu_SetText(currentKeyLevel, self.level)
                updateScores(timerSlider:GetValue())
            end)
        end
    end
    
    updateScores(0)
end

function UIContentCreators.updateScoreTable(scoreRows, timerPercentage)
    if not RewardsFunctions or not RewardsFunctions.scoreFormula then
        return
    end
    
    for level = 2, 30 do
        local row = scoreRows[level]
        if row then
            local baseScore = RewardsFunctions.scoreFormula(level)
            local scoreBonus = math.floor(15 * (timerPercentage / 40))
            local finalScore = baseScore + scoreBonus

            row.bonus:SetText(string.format("+%d", scoreBonus))
            row.final:SetText(string.format("%d", finalScore))
            UIHelpers.setTextColor(row.bonus, "SUCCESS_HIGH")
        end
    end
end

function UIContentCreators.updateDungeonGains(gainRows, currentKeyLevel, timerPercentage)
    local selectedLevel = tonumber(UIDropDownMenu_GetText(currentKeyLevel))
    if not selectedLevel or not RewardsFunctions or not RewardsFunctions.scoreFormula then
        return
    end
    
    local finalScore = RewardsFunctions.scoreFormula(selectedLevel)
    finalScore = finalScore + math.floor(15 * (timerPercentage / 40))
    
    if MrMythical.DungeonData and MrMythical.DungeonData.getAllDungeonData then
        local dungeonData = MrMythical.DungeonData.getAllDungeonData()
        
        for i, data in ipairs(dungeonData) do
            if gainRows[i] then
                local levelText = "--"
                if data.currentLevel > 0 then
                    levelText = tostring(data.currentLevel)
                end
            gainRows[i].current:SetText(levelText)
            
            if data.hasRun then
                if data.isInTime then
                    UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_HIGH")
                else
                    UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_LOW")
                end
            else
                UIHelpers.setTextColor(gainRows[i].current, "DISABLED")
            end
            
            local potentialGain = finalScore - data.currentScore
            
            if potentialGain > 0 then
                gainRows[i].gain:SetText(string.format("+%d", potentialGain))
                UIHelpers.setTextColor(gainRows[i].gain, "SUCCESS_HIGH")
            else
                gainRows[i].gain:SetText("--")
                UIHelpers.setTextColor(gainRows[i].gain, "DISABLED")
            end
        end
    end
    end
end

function UIContentCreators.stats(parentFrame)
    local row1 = CreateFrame("Frame", nil, parentFrame)
    row1:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    row1:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH - (UI_CONSTANTS.LAYOUT.LARGE_PADDING * 2), 220)
    
    local row2 = CreateFrame("Frame", nil, parentFrame)
    row2:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -250)
    row2:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH - (UI_CONSTANTS.LAYOUT.LARGE_PADDING * 2), 220)
    
    local statsOverview = UIContentCreators.createStatsOverview(row1)
    local recentActivity = UIContentCreators.createRecentActivity(row1)
    local dungeonBreakdown = UIContentCreators.createDungeonBreakdown(row2)
    
    UIContentCreators.updateStats(statsOverview, recentActivity, dungeonBreakdown)
    
    parentFrame:SetScript("OnShow", function()
        if statsOverview and recentActivity and dungeonBreakdown then
            C_Timer.After(0.1, function()
                if parentFrame:IsVisible() then
                    UIContentCreators.updateStats(statsOverview, recentActivity, dungeonBreakdown)
                end
            end)
        end
    end)
end

function UIContentCreators.createStatsOverview(parentFrame)
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

function UIContentCreators.createRecentActivity(parentFrame)
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

function UIContentCreators.createDungeonBreakdown(parentFrame)
    local dungeonLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Dungeon Breakdown", "TOPLEFT", 0, 0)
    UIHelpers.setTextColor(dungeonLabel, "SUCCESS_HIGH")
    
    local dungeonTableFrame = UIContentCreators.createDungeonTable(parentFrame)
    
    local dungeonRows = {}
    
    C_Timer.After(0.1, function()
        UIContentCreators.updateDungeonBreakdown(dungeonTableFrame, dungeonRows, "seasonal")
    end)
    
    return {
        rows = dungeonRows,
        tableFrame = dungeonTableFrame
    }
end

function UIContentCreators.createDungeonTable(parentFrame)
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

function UIContentCreators.updateDungeonBreakdown(dungeonTableFrame, dungeonRows, stats)
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
        local yOffset = startY - ((i - 1) * UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
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
        
        local colorName = UIContentCreators.getSuccessRateColor(data.successRate)
        UIHelpers.setTextColor(dungeonRows[i].rate, colorName)
        
        local intimeColorName = UIContentCreators.getSuccessRateColor(data.intimeRate)
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

function UIContentCreators.getSuccessRateColor(rate)
    if rate >= 80 then
        return "SUCCESS_HIGH"
    elseif rate >= 60 then
        return "SUCCESS_MEDIUM"
    else
        return "SUCCESS_LOW"
    end
end

function UIContentCreators.updateStats(statsOverview, recentActivity, dungeonBreakdown)
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
                
                activityText = activityText .. string.format("\n%s %s%s|r (%s)", statusPrefix, color, dungeonName, timeStr)
            elseif runResult == "abandoned" then
                activityText = activityText .. string.format("\n|cFFFF0000%d|r |cFFFF0000%s|r", run.level, dungeonName)
            end
        end
    else
        activityText = "No runs recorded yet."
    end

    recentActivity:SetText(activityText)
    
    if dungeonBreakdown and dungeonBreakdown.tableFrame and dungeonBreakdown.rows then
        UIContentCreators.updateDungeonBreakdown(dungeonBreakdown.tableFrame, dungeonBreakdown.rows, stats)
    end
end

function UIContentCreators.times(parentFrame)
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Mythic+ Timer Thresholds", "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    
    local timesTableFrame = CreateFrame("Frame", nil, parentFrame)
    timesTableFrame:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -60)
    timesTableFrame:SetSize(620, 380)
    
    UIContentCreators.createTimesTable(timesTableFrame)
    UIContentCreators.createTimesInfoPanel(parentFrame)
end

function UIContentCreators.createTimesTable(parentFrame)
    UIHelpers.createHeader(parentFrame, "Dungeon", 0, 200)
    UIHelpers.createHeader(parentFrame, "1 Chest (0%)", 200, 140)
    UIHelpers.createHeader(parentFrame, "2 Chests (20%)", 340, 140)
    UIHelpers.createHeader(parentFrame, "3 Chests (40%)", 480, 140)
    
    if DungeonData and DungeonData.MYTHIC_MAPS then
        local startY = -25
        for i, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
            UIContentCreators.createTimeRow(parentFrame, mapInfo, i, startY)
        end
    end
end

function UIContentCreators.createTimeRow(parentFrame, mapInfo, index, startY)
    local yOffset = startY - ((index - 1) * UI_CONSTANTS.LAYOUT.LARGE_ROW_HEIGHT)
    local isEven = index % 2 == 0
    local timers = UIContentCreators.calculateTimers(mapInfo.parTime)
    
    UIHelpers.createRowBackground(parentFrame, yOffset, 620, isEven)
    
    UIHelpers.createRowText(parentFrame, mapInfo.name, 0, yOffset, 200)
    UIHelpers.createRowText(parentFrame, DungeonData.formatTime(timers.oneChest), 200, yOffset, 140)
    UIHelpers.createRowText(parentFrame, DungeonData.formatTime(timers.twoChest), 340, yOffset, 140)
    UIHelpers.createRowText(parentFrame, DungeonData.formatTime(timers.threeChest), 480, yOffset, 140)
end

function UIContentCreators.calculateTimers(parTime)
    if not parTime or parTime <= 0 then
        return {oneChest = 0, twoChest = 0, threeChest = 0}
    end
    
    return {
        oneChest = parTime,
        twoChest = math.floor(parTime * 0.8),
        threeChest = math.floor(parTime * 0.6)
    }
end

function UIContentCreators.calculateChestLevel(completionTime, parTime)
    if not completionTime or not parTime or parTime <= 0 then
        return 0, "none"
    end
    
    local timers = UIContentCreators.calculateTimers(parTime)
    
    if completionTime <= timers.threeChest then
        return 3, "+3"
    elseif completionTime <= timers.twoChest then
        return 2, "+2"
    elseif completionTime <= timers.oneChest then
        return 1, "+1"
    else
        return 0, "none"
    end
end

function UIContentCreators.createTimesInfoPanel(parentFrame)
    local infoText = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalSmall",
        "1 Chest: Complete within par time | 2 Chests: 20% faster | 3 Chests: 40% faster",
        "BOTTOM", 0, 25)
    infoText:SetWidth(620)
    infoText:SetJustifyH("CENTER")
    UIHelpers.setTextColor(infoText, "INFO_TEXT")
end

local MainFrameManager = {}

function MainFrameManager.createUnifiedFrame()
    local frame = CreateFrame("Frame", "MrMythicalUnifiedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(UI_CONSTANTS.FRAME.WIDTH, UI_CONSTANTS.FRAME.HEIGHT)
    if MRM_SavedVars and MRM_SavedVars.UNIFIED_FRAME_POINT then
        frame:SetPoint(
            MRM_SavedVars.UNIFIED_FRAME_POINT or "CENTER",
            UIParent,
            MRM_SavedVars.UNIFIED_FRAME_RELATIVE_POINT or (MRM_SavedVars.UNIFIED_FRAME_POINT or "CENTER"),
            MRM_SavedVars.UNIFIED_FRAME_X or 0,
            MRM_SavedVars.UNIFIED_FRAME_Y or 0
        )
    else
        frame:SetPoint("CENTER")
    end
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    
    MainFrameManager.setupFrameBehavior(frame)
    frame:Hide()
    
    return frame
end

function MainFrameManager.setupFrameBehavior(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not MRM_SavedVars then return end
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint(1)
        if point then
            MRM_SavedVars.UNIFIED_FRAME_POINT = point
            MRM_SavedVars.UNIFIED_FRAME_RELATIVE_POINT = relativePoint or point
            MRM_SavedVars.UNIFIED_FRAME_X = xOfs or 0
            MRM_SavedVars.UNIFIED_FRAME_Y = yOfs or 0
        end
    end)
    
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            frame:Hide()
            self:SetPropagateKeyboardInput(false)
            return
        end
        self:SetPropagateKeyboardInput(true)
    end)
end

function MainFrameManager.createNavigationPanel(parentFrame)
    local navPanel = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    navPanel:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.PADDING, -UI_CONSTANTS.LAYOUT.PADDING)
    navPanel:SetSize(UI_CONSTANTS.FRAME.NAV_PANEL_WIDTH, UI_CONSTANTS.FRAME.HEIGHT - (UI_CONSTANTS.LAYOUT.PADDING * 2))
    navPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
    local color = UI_CONSTANTS.COLORS.NAV_BACKGROUND
    navPanel:SetBackdropColor(color.r, color.g, color.b, color.a)
    
    return navPanel
end

function MainFrameManager.createContentFrame(parentFrame)
    local contentFrame = CreateFrame("Frame", nil, parentFrame)
    contentFrame:SetPoint("TOPLEFT", UI_CONSTANTS.FRAME.NAV_PANEL_WIDTH + UI_CONSTANTS.LAYOUT.PADDING * 2, -UI_CONSTANTS.LAYOUT.PADDING)
    contentFrame:SetSize(UI_CONSTANTS.FRAME.CONTENT_WIDTH, UI_CONSTANTS.FRAME.HEIGHT - (UI_CONSTANTS.LAYOUT.PADDING * 2))
    return contentFrame
end

NavigationManager.BUTTON_DATA = {
    {id = UI_CONSTANTS.CONTENT_TYPES.DASHBOARD, text = "Dashboard", y = -UI_CONSTANTS.LAYOUT.LARGE_PADDING},
    {id = UI_CONSTANTS.CONTENT_TYPES.REWARDS, text = "Rewards", y = -60},
    {id = UI_CONSTANTS.CONTENT_TYPES.SCORES, text = "Scores", y = -100},
    {id = UI_CONSTANTS.CONTENT_TYPES.STATS, text = "Statistics", y = -140},
    {id = UI_CONSTANTS.CONTENT_TYPES.TIMES, text = "Times", y = -180},
    {id = UI_CONSTANTS.CONTENT_TYPES.SETTINGS, text = "Settings", y = -220}
}

function NavigationManager.createButtons(navPanel, contentFrame)
    local navButtons = {}
    
    for _, buttonInfo in ipairs(NavigationManager.BUTTON_DATA) do
        local button = NavigationManager.createNavigationButton(navPanel, buttonInfo, contentFrame, navButtons)
        navButtons[buttonInfo.id] = button
        
        if buttonInfo.id == UI_CONSTANTS.CONTENT_TYPES.DASHBOARD then
            button:SetNormalFontObject("GameFontHighlight")
        end
    end
    
    return navButtons
end

function NavigationManager.createNavigationButton(navPanel, buttonInfo, contentFrame, navButtons)
    local button = CreateFrame("Button", nil, navPanel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.PADDING, buttonInfo.y)
    button:SetSize(120, UI_CONSTANTS.LAYOUT.BUTTON_HEIGHT)
    button:SetText(buttonInfo.text)
    
    button:SetScript("OnClick", function()
        NavigationManager.handleButtonClick(buttonInfo, button, navButtons, contentFrame)
    end)
    
    return button
end

function NavigationManager.handleButtonClick(buttonInfo, button, navButtons, contentFrame)
    if buttonInfo.id == UI_CONSTANTS.CONTENT_TYPES.SETTINGS then
        MainFrameManager.openSettings()
        return
    end
    
    NavigationManager.updateButtonStates(button, navButtons)
    NavigationManager.showContent(buttonInfo.id, contentFrame)
end

function MainFrameManager.openSettings()
    UnifiedUI:Hide()
    
    local registry = _G.MrMythicalSettingsRegistry
    if registry and registry.parentCategory and registry.parentCategory.GetID then
        Settings.OpenToCategory(registry.parentCategory:GetID())
    elseif MrMythical.Options and MrMythical.Options.openSettings then
        MrMythical.Options.openSettings()
    else
        SettingsPanel:Open()
        if MrMythicalDebug then
            print("Mr. Mythical: Settings category not found. Please access via Game Menu > Options > AddOns.")
        end
    end
end

function NavigationManager.updateButtonStates(activeButton, navButtons)
    for _, button in pairs(navButtons) do
        button:SetNormalFontObject("GameFontNormal")
    end
    activeButton:SetNormalFontObject("GameFontHighlight")
end

function NavigationManager.clearContent(contentFrame)
    for _, child in ipairs({contentFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({contentFrame:GetRegions()}) do
        if region.Hide then
            region:Hide()
        end
    end
end

function NavigationManager.showContent(contentType, contentFrame)
    NavigationManager.clearContent(contentFrame)
    
    if UIContentCreators[contentType] then
        UIContentCreators[contentType](contentFrame)
    else
        UIHelpers.createFontString(contentFrame, "OVERLAY", "GameFontNormal",
        "Content not available: " .. contentType, "CENTER", 0, 0)
    end
end

local unifiedFrame = MainFrameManager.createUnifiedFrame()
local navPanel = MainFrameManager.createNavigationPanel(unifiedFrame)
local contentFrame = MainFrameManager.createContentFrame(unifiedFrame)
local navButtons = NavigationManager.createButtons(navPanel, contentFrame)

local closeButton = CreateFrame("Button", nil, unifiedFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

function UnifiedUI:Show(contentType)
    if MRM_SavedVars and MRM_SavedVars.UNIFIED_FRAME_POINT then
        unifiedFrame:ClearAllPoints()
        unifiedFrame:SetPoint(
            MRM_SavedVars.UNIFIED_FRAME_POINT or "CENTER",
            UIParent,
            MRM_SavedVars.UNIFIED_FRAME_RELATIVE_POINT or (MRM_SavedVars.UNIFIED_FRAME_POINT or "CENTER"),
            MRM_SavedVars.UNIFIED_FRAME_X or 0,
            MRM_SavedVars.UNIFIED_FRAME_Y or 0
        )
    end
    unifiedFrame:Show()
    
    local targetContent = contentType or UI_CONSTANTS.CONTENT_TYPES.DASHBOARD
    if contentType and contentType ~= UI_CONSTANTS.CONTENT_TYPES.DASHBOARD then
        NavigationManager.showContent(contentType, contentFrame)
        if navButtons[contentType] then
            NavigationManager.updateButtonStates(navButtons[contentType], navButtons)
        end
    else
        NavigationManager.showContent(UI_CONSTANTS.CONTENT_TYPES.DASHBOARD, contentFrame)
    end
end

function UnifiedUI:Hide()
    unifiedFrame:Hide()
end

function UnifiedUI:Toggle(contentType)
    if unifiedFrame:IsShown() then
        self:Hide()
    else
        self:Show(contentType)
    end
end

NavigationManager.showContent(UI_CONSTANTS.CONTENT_TYPES.DASHBOARD, contentFrame)
