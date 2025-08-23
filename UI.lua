--[[
UI.lua - Comprehensive Mythic+ Interface

This module provides a unified tabbed interface that consolidates all Mr. Mythical
functionality into a single frame with navigation panels.

Dependencies:
- RewardsFunctions: For reward calculations and score formulas
- DungeonData: For dungeon information and par times
- CompletionTracker: For player statistics tracking
- WoW APIs: C_MythicPlus for player dungeon data

Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.UnifiedUI = {}

-- Local references for performance
local UnifiedUI = MrMythical.UnifiedUI
local RewardsFunctions = MrMythical.RewardsFunctions
local DungeonData = MrMythical.DungeonData
local CompletionTracker = MrMythical.CompletionTracker

-- Constants
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

-- Common UI helper functions
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

-- Content creation functions
local UIContentCreators = {}

-- Forward declare NavigationManager so UIContentCreators can be accessed
local NavigationManager = {}

--- Creates the dashboard content
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

--- Creates the rewards content with comprehensive reward information
function UIContentCreators.rewards(parentFrame)
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Mythic+ Rewards", "TOP", 0, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    
    local rewardsTableFrame = CreateFrame("Frame", nil, parentFrame)
    rewardsTableFrame:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -60)
    rewardsTableFrame:SetSize(530, 380)
    
    UIContentCreators.createRewardsTable(rewardsTableFrame)
end

function UIContentCreators.createRewardsTable(parentFrame)
    -- Create table headers
    UIHelpers.createHeader(parentFrame, "Key Level", 0, 80)
    UIHelpers.createHeader(parentFrame, "End of Dungeon", 80, 150)
    UIHelpers.createHeader(parentFrame, "Great Vault", 230, 150)
    UIHelpers.createHeader(parentFrame, "Crest Rewards", 380, 150)
    
    -- Populate table with reward data
    local startY = -25
    for level = 2, 12 do
        UIContentCreators.createRewardRow(parentFrame, level, startY, level - 2)
    end
end

function UIContentCreators.createRewardRow(parentFrame, level, startY, index)
    local yOffset = startY - (index * UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
    local isEven = level % 2 == 0
    
    -- Create alternating row background
    UIHelpers.createRowBackground(parentFrame, yOffset, 530, isEven)
    
    -- Get rewards data
    if not RewardsFunctions then
        return
    end
    
    local rewards = RewardsFunctions.getRewardsForKeyLevel(level)
    local crests = RewardsFunctions.getCrestReward(level)
    
    if not rewards or not crests then
        return
    end
    
    -- Create row content
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

--- Creates the scores content with interactive score calculator
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
    
    -- Set slider labels
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
    -- Create score calculation table
    local scoreScrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
    scoreScrollFrame:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -110)
    scoreScrollFrame:SetSize(320, 320)
    
    local scoreContentFrame = CreateFrame("Frame", nil, scoreScrollFrame)
    scoreContentFrame:SetSize(320, 800)
    scoreScrollFrame:SetScrollChild(scoreContentFrame)
    
    -- Score table headers
    UIHelpers.createHeader(scoreContentFrame, "Key Level", 0, 70)
    UIHelpers.createHeader(scoreContentFrame, "Base Score", 70, 80)
    UIHelpers.createHeader(scoreContentFrame, "Timer Bonus", 150, 80)
    UIHelpers.createHeader(scoreContentFrame, "Final Score", 230, 90)
    
    -- Create dungeon gains section
    local gainsLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Your Dungeons", "TOPLEFT", 350, -80)
    
    local gainsTableFrame = CreateFrame("Frame", nil, parentFrame)
    gainsTableFrame:SetPoint("TOPLEFT", 350, -140)
    gainsTableFrame:SetSize(310, 290)
    
    -- Gains table headers
    UIHelpers.createHeader(gainsTableFrame, "Dungeon", 0, 140)
    UIHelpers.createHeader(gainsTableFrame, "Level", 140, 50)
    UIHelpers.createHeader(gainsTableFrame, "Score", 190, 60)
    UIHelpers.createHeader(gainsTableFrame, "Gain", 250, 60)
    
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
            
            -- Make the row interactive for hovering
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
    
    -- Create initial dungeon data
    local dungeonData = UIContentCreators.getDungeonData()
    local startY = -25
    
    for i, data in ipairs(dungeonData) do
        local yOffset = startY - ((i - 1) * UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
        local isEven = i % 2 == 0
        
        UIHelpers.createRowBackground(gainsTableFrame, yOffset, 310, isEven)
        
        -- Format the level display without symbols
        local levelText = "--"
        if data.currentLevel > 0 then
            levelText = tostring(data.currentLevel)
        end
        
        gainRows[i] = {
            name = UIHelpers.createRowText(gainsTableFrame, data.mapInfo.name, 0, yOffset, 140),
            current = UIHelpers.createRowText(gainsTableFrame, levelText, 140, yOffset, 50),
            timer = UIHelpers.createRowText(gainsTableFrame, 
                data.currentScore > 0 and tostring(data.currentScore) or "--", 190, yOffset, 60),
            gain = UIHelpers.createRowText(gainsTableFrame, "--", 250, yOffset, 60)
        }
        
        -- Color code the level text based on timing status
        if data.hasRun then
            if data.isInTime then
                UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_HIGH")  -- Green for timed
            else
                UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_LOW")  -- Red for overtime
            end
        else
            UIHelpers.setTextColor(gainRows[i].current, "DISABLED")  -- Gray for no run
        end
    end
    
    return gainRows
end

function UIContentCreators.getDungeonData()
    local dungeonData = {}
    
    for i, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
        local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapInfo.id)
        local currentLevel = 0
        local currentScore = 0
        local isInTime = false
        local hasRun = false
        
        -- Check both timed and overtime runs to find the highest score
        local bestScore = 0
        local bestLevel = 0
        local bestIsInTime = false
        
        if intimeInfo and intimeInfo.dungeonScore then
            if intimeInfo.dungeonScore > bestScore then
                bestScore = intimeInfo.dungeonScore
                bestLevel = intimeInfo.level
                bestIsInTime = true
            end
            hasRun = true
        end
        
        if overtimeInfo and overtimeInfo.dungeonScore then
            if overtimeInfo.dungeonScore > bestScore then
                bestScore = overtimeInfo.dungeonScore
                bestLevel = overtimeInfo.level
                bestIsInTime = false
            end
            hasRun = true
        end
        
        currentLevel = bestLevel
        currentScore = bestScore
        isInTime = bestIsInTime
        
        table.insert(dungeonData, {
            index = i,
            mapInfo = mapInfo,
            currentLevel = currentLevel,
            currentScore = currentScore,
            isInTime = isInTime,
            hasRun = hasRun
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

function UIContentCreators.setupScoreCalculator(timerSlider, currentKeyLevel, scoreRows, gainRows)
    local function updateScores(timerPercentage)
        UIContentCreators.updateScoreTable(scoreRows, timerPercentage)
        UIContentCreators.updateDungeonGains(gainRows, currentKeyLevel, timerPercentage)
    end
    
    -- Setup dropdown
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
    
    -- Setup slider callback
    timerSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName() .. "Text"]:SetText(string.format("%d%%", value))
        updateScores(value)
    end)
    
    -- Setup row hover functionality
    for level, row in pairs(scoreRows) do
        if row.frame then
            row.frame:SetScript("OnEnter", function(self)
                UIDropDownMenu_SetText(currentKeyLevel, self.level)
                updateScores(timerSlider:GetValue())
            end)
        end
    end
    
    -- Initial update
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
    
    local dungeonData = UIContentCreators.getDungeonData()
    
    for i, data in ipairs(dungeonData) do
        if gainRows[i] then
            -- Update the level display without symbols
            local levelText = "--"
            if data.currentLevel > 0 then
                levelText = tostring(data.currentLevel)
            end
            gainRows[i].current:SetText(levelText)
            
            -- Color code the level text based on timing status
            if data.hasRun then
                if data.isInTime then
                    UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_HIGH")  -- Green for timed
                else
                    UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_LOW")  -- Red for overtime
                end
            else
                UIHelpers.setTextColor(gainRows[i].current, "DISABLED")  -- Gray for no run
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

--- Creates the stats content with completion tracking and analysis
function UIContentCreators.stats(parentFrame)
    -- Create overview panels
    local seasonStats, weeklyStats = UIContentCreators.createStatsOverview(parentFrame)
    
    -- Create dungeon breakdown section
    local dungeonBreakdown = UIContentCreators.createDungeonBreakdown(parentFrame)
    
    -- Initial data update
    UIContentCreators.updateStats(seasonStats, weeklyStats, dungeonBreakdown)
    
    -- Update when frame becomes visible or data changes
    parentFrame:SetScript("OnShow", function()
        if seasonStats and weeklyStats and dungeonBreakdown then
            C_Timer.After(0.1, function()
                if parentFrame:IsVisible() then
                    UIContentCreators.updateStats(seasonStats, weeklyStats, dungeonBreakdown)
                end
            end)
        end
    end)
end

function UIContentCreators.createStatsOverview(parentFrame)
    -- Season overview section
    local seasonLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Season Overview", "TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    UIHelpers.setTextColor(seasonLabel, "SUCCESS_HIGH")
    
    local seasonStats = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "", "TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -60)
    seasonStats:SetWidth(320)
    seasonStats:SetJustifyH("LEFT")
    
    -- Weekly overview section
    local weeklyLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "This Week", "TOPLEFT", 350, -UI_CONSTANTS.LAYOUT.LARGE_PADDING)
    UIHelpers.setTextColor(weeklyLabel, "SUCCESS_HIGH")
    
    local weeklyStats = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "", "TOPLEFT", 350, -60)
    weeklyStats:SetWidth(320)
    weeklyStats:SetJustifyH("LEFT")
    
    return seasonStats, weeklyStats
end

function UIContentCreators.createDungeonBreakdown(parentFrame)
    local dungeonLabel = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Dungeon Breakdown", "TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -140)
    UIHelpers.setTextColor(dungeonLabel, "SUCCESS_HIGH")
    
    local seasonalTab, weeklyTab = UIContentCreators.createStatsTabs(parentFrame)
    local dungeonTableFrame = UIContentCreators.createDungeonTable(parentFrame)
    
    local dungeonRows = {}
    local currentStatsView = {value = "weekly"}  -- Use table for reference passing
    
    -- Setup tab functionality
    seasonalTab:SetScript("OnClick", function()
        currentStatsView.value = "seasonal"
        UIContentCreators.updateDungeonBreakdown(dungeonTableFrame, dungeonRows, currentStatsView.value)
        seasonalTab:Disable()
        weeklyTab:Enable()
    end)
    
    weeklyTab:SetScript("OnClick", function()
        currentStatsView.value = "weekly"
        UIContentCreators.updateDungeonBreakdown(dungeonTableFrame, dungeonRows, currentStatsView.value)
        weeklyTab:Disable()
        seasonalTab:Enable()
    end)
    
    -- Set initial state
    weeklyTab:Disable()
    seasonalTab:Enable()
    
    -- Perform initial update to populate the dungeon breakdown table
    C_Timer.After(0.1, function()
        UIContentCreators.updateDungeonBreakdown(dungeonTableFrame, dungeonRows, currentStatsView.value)
    end)
    
    return {
        rows = dungeonRows,
        tableFrame = dungeonTableFrame,
        currentStatsView = currentStatsView,
        seasonalTab = seasonalTab,
        weeklyTab = weeklyTab
    }
end

function UIContentCreators.createStatsTabs(parentFrame)
    local tabFrame = CreateFrame("Frame", nil, parentFrame)
    tabFrame:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -165)
    tabFrame:SetSize(620, 30)
    
    local seasonalTab = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    seasonalTab:SetPoint("TOPLEFT", 0, 0)
    seasonalTab:SetSize(100, UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
    seasonalTab:SetText("Seasonal")
    
    local weeklyTab = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    weeklyTab:SetPoint("TOPLEFT", 105, 0)
    weeklyTab:SetSize(100, UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
    weeklyTab:SetText("Weekly")
    
    return seasonalTab, weeklyTab
end

function UIContentCreators.createDungeonTable(parentFrame)
    local dungeonTableFrame = CreateFrame("Frame", nil, parentFrame)
    dungeonTableFrame:SetPoint("TOPLEFT", UI_CONSTANTS.LAYOUT.LARGE_PADDING, -195)
    dungeonTableFrame:SetSize(620, 220)
    
    -- Create table headers
    UIHelpers.createHeader(dungeonTableFrame, "Dungeon", 0, 200)
    UIHelpers.createHeader(dungeonTableFrame, "Completed", 200, 100)
    UIHelpers.createHeader(dungeonTableFrame, "Failed", 300, 100)
    UIHelpers.createHeader(dungeonTableFrame, "Total", 400, 100)
    UIHelpers.createHeader(dungeonTableFrame, "Success Rate", 500, 120)
    
    return dungeonTableFrame
end

function UIContentCreators.updateDungeonBreakdown(dungeonTableFrame, dungeonRows, currentStatsView)
    if not CompletionTracker or not dungeonTableFrame or not dungeonRows then
        return
    end
    
    local success, stats = pcall(function() return CompletionTracker:getStats() end)
    if not success or not stats then
        return
    end
    
    local statsSource = currentStatsView == "seasonal" and stats.seasonal or stats.weekly
    if not statsSource or not statsSource.dungeons then
        return
    end
    
    local dungeonData = {}
    
    for mapID, data in pairs(statsSource.dungeons) do
        local dungeonTotal = data.completed + data.failed
        -- Show dungeons even if they have no runs (to indicate they exist)
        table.insert(dungeonData, {
            name = data.name or ("Dungeon " .. tostring(mapID)),
            completed = data.completed,
            failed = data.failed,
            total = dungeonTotal,
            rate = dungeonTotal > 0 and math.floor(data.rate) or 0
        })
    end
    
    -- Sort by total runs (highest first), then by name for consistency
    table.sort(dungeonData, function(a, b) 
        if a.total == b.total then
            return a.name < b.name
        end
        return a.total > b.total 
    end)
    
    -- Clear existing rows
    for i = 1, #dungeonRows do
        if dungeonRows[i] then
            for _, element in pairs(dungeonRows[i]) do
                if element and element.Hide then
                    element:Hide()
                end
            end
        end
    end
    for k in pairs(dungeonRows) do dungeonRows[k] = nil end
    
    -- Create new rows
    local startY = -25
    for i, data in ipairs(dungeonData) do
        local yOffset = startY - ((i - 1) * UI_CONSTANTS.LAYOUT.ROW_HEIGHT)
        local isEven = i % 2 == 0
        
        UIHelpers.createRowBackground(dungeonTableFrame, yOffset, 620, isEven)
        
        dungeonRows[i] = {
            name = UIHelpers.createRowText(dungeonTableFrame, data.name, 0, yOffset, 200),
            completed = UIHelpers.createRowText(dungeonTableFrame, tostring(data.completed), 200, yOffset, 100),
            failed = UIHelpers.createRowText(dungeonTableFrame, tostring(data.failed), 300, yOffset, 100),
            total = UIHelpers.createRowText(dungeonTableFrame, tostring(data.total), 400, yOffset, 100),
            rate = UIHelpers.createRowText(dungeonTableFrame, string.format("%d%%", data.rate), 500, yOffset, 120)
        }
        
        -- Color code the success rate
        local colorName = UIContentCreators.getSuccessRateColor(data.rate)
        UIHelpers.setTextColor(dungeonRows[i].rate, colorName)
    end
    
    -- Show no data message if needed
    if #dungeonData == 0 then
        UIContentCreators.showNoDungeonDataMessage(dungeonTableFrame, dungeonRows, currentStatsView, startY)
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

function UIContentCreators.showNoDungeonDataMessage(dungeonTableFrame, dungeonRows, currentStatsView, startY)
    dungeonRows[1] = {
        name = UIHelpers.createRowText(dungeonTableFrame, 
            string.format("No %s dungeon data available", currentStatsView), 0, startY, 620)
    }
    dungeonRows[1].name:SetTextColor(0.7, 0.7, 0.7)
end

function UIContentCreators.updateStats(seasonStats, weeklyStats, dungeonBreakdown)
    if not CompletionTracker then
        seasonStats:SetText("CompletionTracker not available\n\nPlease run some Mythic+ dungeons to see statistics here.")
        weeklyStats:SetText("Statistics will appear here once you complete some dungeons this week.")
        return
    end
    
    local success, stats = pcall(function() return CompletionTracker:getStats() end)
    if not success or not stats then
        seasonStats:SetText("Error loading statistics: " .. tostring(stats) .. "\n\nTry again in a moment.")
        weeklyStats:SetText("Statistics temporarily unavailable.")
        return
    end
    
    -- Update season overview
    local seasonTotal = (stats.seasonal.completed or 0) + (stats.seasonal.failed or 0)
    local seasonRate = stats.seasonal.rate or 0
    local seasonText = string.format("Total Runs: %d\nCompleted: %d (%d%%)\nFailed: %d (%d%%)",
        seasonTotal,
        stats.seasonal.completed or 0, math.floor(seasonRate),
        stats.seasonal.failed or 0, math.floor(100 - seasonRate)
    )
    seasonStats:SetText(seasonText)
    
    -- Update weekly overview
    local weeklyTotal = (stats.weekly.completed or 0) + (stats.weekly.failed or 0)
    local weeklyRate = stats.weekly.rate or 0
    local weeklyText = string.format("Total Runs: %d\nCompleted: %d (%d%%)\nFailed: %d (%d%%)",
        weeklyTotal,
        stats.weekly.completed or 0, math.floor(weeklyRate),
        stats.weekly.failed or 0, math.floor(100 - weeklyRate)
    )
    weeklyStats:SetText(weeklyText)
    
    -- Update dungeon breakdown
    if dungeonBreakdown and dungeonBreakdown.tableFrame and dungeonBreakdown.rows and dungeonBreakdown.currentStatsView then
        UIContentCreators.updateDungeonBreakdown(dungeonBreakdown.tableFrame, dungeonBreakdown.rows, dungeonBreakdown.currentStatsView.value)
    end
end

--- Creates the times content with dungeon timer information
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
    -- Create table headers
    UIHelpers.createHeader(parentFrame, "Dungeon", 0, 200)
    UIHelpers.createHeader(parentFrame, "1 Chest (0%)", 200, 140)
    UIHelpers.createHeader(parentFrame, "2 Chests (20%)", 340, 140)
    UIHelpers.createHeader(parentFrame, "3 Chests (40%)", 480, 140)
    
    -- Populate with dungeon data
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
    
    -- Create row content
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
        oneChest = parTime,  -- Must complete within par time for 1 chest
        twoChest = math.floor(parTime * 0.8),  -- 20% faster for 2 chests
        threeChest = math.floor(parTime * 0.6)  -- 40% faster for 3 chests
    }
end

function UIContentCreators.createTimesInfoPanel(parentFrame)
    local infoText = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalSmall",
        "1 Chest: Complete within par time | 2 Chests: 20% faster | 3 Chests: 40% faster",
        "BOTTOM", 0, 25)
    infoText:SetWidth(620)
    infoText:SetJustifyH("CENTER")
    UIHelpers.setTextColor(infoText, "INFO_TEXT")
end

-- Main UI Frame and Navigation System
local MainFrameManager = {}

function MainFrameManager.createUnifiedFrame()
    local frame = CreateFrame("Frame", "MrMythicalUnifiedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(UI_CONSTANTS.FRAME.WIDTH, UI_CONSTANTS.FRAME.HEIGHT)
    -- Attempt to restore saved position
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

-- Navigation System
-- NavigationManager already declared earlier

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
        NavigationManager.openSettings()
        return
    end
    
    NavigationManager.updateButtonStates(button, navButtons)
    NavigationManager.showContent(buttonInfo.id, contentFrame)
end

function NavigationManager.openSettings()
    UnifiedUI:Hide()
    
    local registry = _G.MrMythicalSettingsRegistry
    if registry and registry.parentCategory and registry.parentCategory.GetID then
        Settings.OpenToCategory(registry.parentCategory:GetID())
    elseif MrMythical.Options and MrMythical.Options.openSettings then
        MrMythical.Options.openSettings()
    else
        SettingsPanel:Open()
        print("Mr. Mythical: Settings category not found. Please access via Game Menu > Options > AddOns.")
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
        NavigationManager.showFallbackContent(contentFrame, contentType)
    end
end

function NavigationManager.showFallbackContent(contentFrame, contentType)
    UIHelpers.createFontString(contentFrame, "OVERLAY", "GameFontNormal",
        "Content not available: " .. contentType, "CENTER", 0, 0)
end

-- Initialize the main UI
local unifiedFrame = MainFrameManager.createUnifiedFrame()
local navPanel = MainFrameManager.createNavigationPanel(unifiedFrame)
local contentFrame = MainFrameManager.createContentFrame(unifiedFrame)
local navButtons = NavigationManager.createButtons(navPanel, contentFrame)

-- Add close button
local closeButton = CreateFrame("Button", nil, unifiedFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Public API functions
function UnifiedUI:Show(contentType)
    -- Re-anchor before showing to avoid drift after resolution/UI scale changes
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

-- Initialize with dashboard content
NavigationManager.showContent(UI_CONSTANTS.CONTENT_TYPES.DASHBOARD, contentFrame)
