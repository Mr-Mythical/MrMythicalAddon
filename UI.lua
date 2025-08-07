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

local UnifiedUI = MrMythical.UnifiedUI
local RewardsFunctions = MrMythical.RewardsFunctions
local DungeonData = MrMythical.DungeonData
local CompletionTracker = MrMythical.CompletionTracker

-- Content creation functions that implement full addon functionality
local UIContentCreators = {}

--- Creates the dashboard content
function UIContentCreators.dashboard(parentFrame)
    local title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Mr. Mythical Dashboard")
    
    local subtitle = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    subtitle:SetText("Mythic+ Tools & Information")
    
    local welcome = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    welcome:SetPoint("TOP", subtitle, "BOTTOM", 0, -30)
    welcome:SetText("Welcome to Mr. Mythical! Use the navigation panel to access different tools.")
    welcome:SetWidth(400)
    welcome:SetJustifyH("CENTER")
    
    local version = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    version:SetPoint("BOTTOM", 0, 20)
    version:SetText("Mr. Mythical by Braunerr")
    version:SetTextColor(0.5, 0.5, 0.5)
end

--- Creates the rewards content with comprehensive reward information
function UIContentCreators.rewards(parentFrame)
    local title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Mythic+ Rewards")
    
    -- Create table container without scrolling for smaller lists
    local rewardsTableFrame = CreateFrame("Frame", nil, parentFrame)
    rewardsTableFrame:SetPoint("TOPLEFT", 20, -60)
    rewardsTableFrame:SetSize(530, 380)
    
    local contentFrame = rewardsTableFrame
    
    -- Table headers
    local function createHeader(text, parent, x, width)
        local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        header:SetPoint("TOPLEFT", x, 0)
        header:SetWidth(width)
        header:SetJustifyH("CENTER")
        header:SetText(text)
        return header
    end
    
    createHeader("Key Level", contentFrame, 0, 80)
    createHeader("End of Dungeon", contentFrame, 80, 150)
    createHeader("Great Vault", contentFrame, 230, 150)
    createHeader("Crest Rewards", contentFrame, 380, 150)
    
    -- Create row background
    local function createRowBackground(parent, yOffset)
        local bg = parent:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 0, yOffset)
        bg:SetSize(530, 25)
        return bg
    end
    
    -- Create row content
    local function createRowText(text, parent, x, yOffset, width)
        local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fontString:SetPoint("TOPLEFT", x, yOffset)
        fontString:SetWidth(width)
        fontString:SetJustifyH("CENTER")
        fontString:SetText(text)
        return fontString
    end
    
    -- Populate table with full data
    local rowHeight = 25
    local startY = -25
    
    for level = 2, 12 do
        local yOffset = startY - ((level - 2) * rowHeight)
        
        -- Alternate row colors
        local bg = createRowBackground(contentFrame, yOffset)
        if level % 2 == 0 then
            bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
        else
            bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
        end
        
        -- Get rewards data using existing functions
        local rewards = RewardsFunctions.getRewardsForKeyLevel(level)
        local crests = RewardsFunctions.getCrestReward(level)
        
        -- Create row content
        createRowText(level, contentFrame, 0, yOffset, 80)
        createRowText(string.format("%s\n%s", rewards.dungeonItem, rewards.dungeonTrack), 
            contentFrame, 80, yOffset, 150)
        createRowText(string.format("%s\n%s", rewards.vaultItem, rewards.vaultTrack), 
            contentFrame, 230, yOffset, 150)
        createRowText(string.format("%s\n%d", crests.crestType, crests.crestAmount), 
            contentFrame, 380, yOffset, 150)
    end
end

--- Creates the scores content with interactive score calculator
function UIContentCreators.scores(parentFrame)
    local title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Mythic+ Score Calculator")
    
    -- Add descriptive text explaining functionality
    local descText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    descText:SetWidth(650)
    descText:SetJustifyH("CENTER")
    descText:SetText("Hover over key levels in the left table to see potential score gains for your dungeons on the right")
    descText:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create timer bonus slider for score calculations
    local timerLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerLabel:SetPoint("TOPLEFT", 20, -80)
    timerLabel:SetText("Timer Bonus:")
    
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
    
    -- Helper functions
    local function createHeader(text, parent, x, width)
        local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        header:SetPoint("TOPLEFT", x, 0)
        header:SetWidth(width)
        header:SetJustifyH("CENTER")
        header:SetText(text)
        return header
    end
    
        local function createRowBackground(parent, yOffset, width)
        local bg = parent:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 0, yOffset)
        bg:SetSize(width or 320, 25)
        return bg
    end    local function createRowText(text, parent, x, yOffset, width)
        local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fontString:SetPoint("TOPLEFT", x, yOffset)
        fontString:SetWidth(width)
        fontString:SetJustifyH("CENTER")
        fontString:SetText(text)
        return fontString
    end
    
    -- Create score calculation table
    local scoreScrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
    scoreScrollFrame:SetPoint("TOPLEFT", 20, -110)
    scoreScrollFrame:SetSize(320, 320)
    
    local scoreContentFrame = CreateFrame("Frame", nil, scoreScrollFrame)
    scoreContentFrame:SetSize(320, 800)
    scoreScrollFrame:SetScrollChild(scoreContentFrame)
    
    -- Score table headers
    createHeader("Key Level", scoreContentFrame, 0, 70)
    createHeader("Base Score", scoreContentFrame, 70, 80)
    createHeader("Timer Bonus", scoreContentFrame, 150, 80)
    createHeader("Final Score", scoreContentFrame, 230, 90)
    
    -- Create dungeon gains section
    local gainsLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    gainsLabel:SetPoint("TOPLEFT", 350, -80)
    gainsLabel:SetText("Your Dungeons")
    
    -- Add current keystone level dropdown
    local currentKeyLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentKeyLabel:SetPoint("TOPLEFT", 350, -110)
    currentKeyLabel:SetText("Using Key Level:")
    
    local currentKeyLevel = CreateFrame("Frame", "MrMythicalUnifiedCurrentKeyLevel", parentFrame, "UIDropDownMenuTemplate")
    currentKeyLevel:SetPoint("TOPLEFT", 450, -105)
    UIDropDownMenu_SetWidth(currentKeyLevel, 60)
    UIDropDownMenu_SetText(currentKeyLevel, "2")
    
    local function CurrentKeyLevel_OnClick(self)
        UIDropDownMenu_SetText(currentKeyLevel, self.value)
        UpdateScores(timerSlider:GetValue())
    end
    
    local function CurrentKeyLevel_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for i = 2, 30 do
            info.text = i
            info.value = i
            info.func = CurrentKeyLevel_OnClick
            UIDropDownMenu_AddButton(info)
        end
    end
    
    UIDropDownMenu_Initialize(currentKeyLevel, CurrentKeyLevel_Initialize)
    
    local gainsTableFrame = CreateFrame("Frame", nil, parentFrame)
    gainsTableFrame:SetPoint("TOPLEFT", 350, -140)
    gainsTableFrame:SetSize(310, 290)
    
    local gainsContentFrame = gainsTableFrame
    
    -- Gains table headers
    createHeader("Dungeon", gainsContentFrame, 0, 140)
    createHeader("Current", gainsContentFrame, 140, 50)
    createHeader("Score", gainsContentFrame, 190, 60)
    createHeader("Gain", gainsContentFrame, 250, 60)
    
    -- Create storage for dynamic content
    local scoreRows = {}
    local gainRows = {}
    local startY = -25
    local rowHeight = 25
    
    -- Update function for score calculations
    local function UpdateScores(timerPercentage)
        -- Update score table
        for level = 2, 30 do
            local row = scoreRows[level]
            if row then
                local baseScore = RewardsFunctions.scoreFormula(level)
                local scoreBonus = math.floor(15 * (timerPercentage / 40))
                local finalScore = baseScore + scoreBonus
                
                row.bonus:SetText(string.format("+%d", scoreBonus))
                row.final:SetText(string.format("%d", finalScore))
                row.bonus:SetTextColor(0, 1, 0)
            end
        end
        
        -- Update dungeon gains
        local selectedLevel = tonumber(UIDropDownMenu_GetText(currentKeyLevel))
        local finalScore = RewardsFunctions.scoreFormula(selectedLevel)
        finalScore = finalScore + math.floor(15 * (timerPercentage / 40))
        
        if DungeonData and DungeonData.MYTHIC_MAPS then
            -- Create dungeon data with scores for sorting
            local dungeonData = {}
            for i, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
                local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapInfo.id)
                local currentLevel = 0
                local currentScore = 0
                
                if intimeInfo then
                    currentLevel = intimeInfo.level
                    currentScore = intimeInfo.dungeonScore or 0  -- Use actual API score
                elseif overtimeInfo then
                    currentLevel = overtimeInfo.level
                    currentScore = overtimeInfo.dungeonScore or 0  -- Use actual API score
                end
                
                local potentialGain = finalScore - currentScore
                
                table.insert(dungeonData, {
                    index = i,
                    mapInfo = mapInfo,
                    currentLevel = currentLevel,
                    currentScore = currentScore,
                    potentialGain = potentialGain
                })
            end
            
            -- Sort by current score (highest first), then by potential gain
            table.sort(dungeonData, function(a, b)
                if a.currentScore == b.currentScore then
                    return a.potentialGain > b.potentialGain
                end
                return a.currentScore > b.currentScore
            end)
            
            -- Clear existing rows and recreate them in sorted order
            for i = 1, #gainRows do
                if gainRows[i] then
                    for _, element in pairs(gainRows[i]) do
                        element:Hide()
                    end
                end
            end
            gainRows = {}
            
            -- Recreate rows in sorted order
            for i, data in ipairs(dungeonData) do
                local yOffset = startY - ((i - 1) * rowHeight)
                
                local bg = createRowBackground(gainsContentFrame, yOffset, 310)
                if i % 2 == 0 then
                    bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
                else
                    bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
                end
                
                gainRows[i] = {
                    name = createRowText(data.mapInfo.name, gainsContentFrame, 0, yOffset, 140),
                    current = createRowText(data.currentLevel > 0 and tostring(data.currentLevel) or "--", gainsContentFrame, 140, yOffset, 50),
                    timer = createRowText(data.currentScore > 0 and tostring(data.currentScore) or "--", gainsContentFrame, 190, yOffset, 60),
                    gain = createRowText("--", gainsContentFrame, 250, yOffset, 60)
                }
                
                if data.potentialGain > 0 then
                    gainRows[i].gain:SetText(string.format("+%d", data.potentialGain))
                    gainRows[i].gain:SetTextColor(0, 1, 0)
                else
                    gainRows[i].gain:SetText("--")
                    gainRows[i].gain:SetTextColor(0.5, 0.5, 0.5)
                end
            end
        end
    end
    
    -- Create score rows
    for level = 2, 30 do
        local yOffset = startY - ((level - 2) * rowHeight)
        
        local bg = createRowBackground(scoreContentFrame, yOffset, 320)
        if level % 2 == 0 then
            bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
        else
            bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
        end
        
        scoreRows[level] = {
            level = createRowText(level, scoreContentFrame, 0, yOffset, 70),
            base = createRowText(RewardsFunctions.scoreFormula(level), scoreContentFrame, 70, yOffset, 80),
            bonus = createRowText("+0", scoreContentFrame, 150, yOffset, 80),
            final = createRowText(RewardsFunctions.scoreFormula(level), scoreContentFrame, 230, yOffset, 90)
        }
        
        -- Make the row interactive - hovering sets the key level for dungeon calculations
        local rowFrame = CreateFrame("Button", nil, scoreContentFrame)
        rowFrame:SetPoint("TOPLEFT", 0, yOffset)
        rowFrame:SetSize(320, 25)
        rowFrame:EnableMouse(true)
        rowFrame:SetScript("OnEnter", function(self)
            UIDropDownMenu_SetText(currentKeyLevel, level)
            UpdateScores(timerSlider:GetValue())
        end)
    end
    
    -- Create dungeon gain rows - initially sorted by dungeon name
    if DungeonData and DungeonData.MYTHIC_MAPS then
        -- Create initial data for sorting
        local dungeonData = {}
        for i, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
            local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapInfo.id)
            local currentLevel = 0
            local currentScore = 0
            
            if intimeInfo then
                currentLevel = intimeInfo.level
                currentScore = intimeInfo.dungeonScore or 0  -- Use actual API score
            elseif overtimeInfo then
                currentLevel = overtimeInfo.level
                currentScore = overtimeInfo.dungeonScore or 0  -- Use actual API score
            end
            
            table.insert(dungeonData, {
                index = i,
                mapInfo = mapInfo,
                currentLevel = currentLevel,
                currentScore = currentScore
            })
        end
        
        -- Sort by current score (highest first)
        table.sort(dungeonData, function(a, b)
            if a.currentScore == b.currentScore then
                return a.mapInfo.name < b.mapInfo.name  -- Secondary sort by name
            end
            return a.currentScore > b.currentScore
        end)
        
        for i, data in ipairs(dungeonData) do
            local yOffset = startY - ((i - 1) * rowHeight)
            
            local bg = createRowBackground(gainsContentFrame, yOffset, 310)
            if i % 2 == 0 then
                bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
            else
                bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
            end
            
            gainRows[i] = {
                name = createRowText(data.mapInfo.name, gainsContentFrame, 0, yOffset, 140),
                current = createRowText(data.currentLevel > 0 and tostring(data.currentLevel) or "--", gainsContentFrame, 140, yOffset, 50),
                timer = createRowText(data.currentScore > 0 and tostring(data.currentScore) or "--", gainsContentFrame, 190, yOffset, 60),
                gain = createRowText("--", gainsContentFrame, 250, yOffset, 60)
            }
        end
    end
    
    -- Setup slider callback
    timerSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName() .. "Text"]:SetText(string.format("%d%%", value))
        UpdateScores(value)
    end)
    
    -- Initial update
    UpdateScores(0)
end

--- Creates the stats content with completion tracking and analysis
function UIContentCreators.stats(parentFrame)
    local title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Mythic+ Completion Statistics")
    
    -- Create season overview section
    local seasonLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    seasonLabel:SetPoint("TOPLEFT", 20, -50)
    seasonLabel:SetText("Season Overview")
    seasonLabel:SetTextColor(0, 1, 0)
    
    local seasonStats = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    seasonStats:SetPoint("TOPLEFT", 20, -75)
    seasonStats:SetWidth(320)
    seasonStats:SetJustifyH("LEFT")
    
    -- Create weekly overview section
    local weeklyLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    weeklyLabel:SetPoint("TOPLEFT", 350, -50)
    weeklyLabel:SetText("This Week")
    weeklyLabel:SetTextColor(0, 1, 0)
    
    local weeklyStats = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    weeklyStats:SetPoint("TOPLEFT", 350, -75)
    weeklyStats:SetWidth(320)
    weeklyStats:SetJustifyH("LEFT")
    
    -- Create dungeon breakdown section
    local dungeonLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dungeonLabel:SetPoint("TOPLEFT", 20, -150)
    dungeonLabel:SetText("Dungeon Breakdown")
    dungeonLabel:SetTextColor(0, 1, 0)
    
    -- Create tab buttons for switching between seasonal and weekly
    local tabFrame = CreateFrame("Frame", nil, parentFrame)
    tabFrame:SetPoint("TOPLEFT", 20, -175)
    tabFrame:SetSize(620, 30)
    
    local seasonalTab = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    seasonalTab:SetPoint("TOPLEFT", 0, 0)
    seasonalTab:SetSize(100, 25)
    seasonalTab:SetText("Seasonal")
    
    local weeklyTab = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
    weeklyTab:SetPoint("TOPLEFT", 105, 0)
    weeklyTab:SetSize(100, 25)
    weeklyTab:SetText("Weekly")
    
    -- Create table container for dungeon stats
    local dungeonTableFrame = CreateFrame("Frame", nil, parentFrame)
    dungeonTableFrame:SetPoint("TOPLEFT", 20, -205)
    dungeonTableFrame:SetSize(620, 220)
    
    local dungeonContentFrame = dungeonTableFrame
    
    -- Helper functions
    local function createHeader(text, parent, x, width)
        local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        header:SetPoint("TOPLEFT", x, 0)
        header:SetWidth(width)
        header:SetJustifyH("CENTER")
        header:SetText(text)
        return header
    end
    
    local function createRowBackground(parent, yOffset, width)
        local bg = parent:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 0, yOffset)
        bg:SetSize(width or 620, 25)
        return bg
    end
    
    local function createRowText(text, parent, x, yOffset, width)
        local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fontString:SetPoint("TOPLEFT", x, yOffset)
        fontString:SetWidth(width)
        fontString:SetJustifyH("CENTER")
        fontString:SetText(text)
        return fontString
    end
    
    -- Create dungeon table headers
    createHeader("Dungeon", dungeonContentFrame, 0, 200)
    createHeader("Completed", dungeonContentFrame, 200, 100)
    createHeader("Failed", dungeonContentFrame, 300, 100)
    createHeader("Total", dungeonContentFrame, 400, 100)
    createHeader("Success Rate", dungeonContentFrame, 500, 120)
    
    -- Create and store text elements for updating
    local dungeonRows = {}
    local startY = -25
    local rowHeight = 25
    local currentStatsView = "weekly"  -- Track which view is active
    
    -- Function to update dungeon breakdown based on current view
    local function UpdateDungeonBreakdown()
        if not CompletionTracker then
            return
        end
        
        local stats = CompletionTracker:getStats()
        local dungeonData = {}
        local statsSource = currentStatsView == "seasonal" and stats.seasonal or stats.weekly
        
        for mapID, data in pairs(statsSource.dungeons) do
            local dungeonTotal = data.completed + data.failed
            if dungeonTotal > 0 then
                table.insert(dungeonData, {
                    name = data.name,
                    completed = data.completed,
                    failed = data.failed,
                    total = dungeonTotal,
                    rate = math.floor(data.rate)
                })
            end
        end
        
        -- Sort by total runs (highest first)
        table.sort(dungeonData, function(a, b) return a.total > b.total end)
        
        -- Clear existing rows
        for i = 1, #dungeonRows do
            if dungeonRows[i] then
                for _, element in pairs(dungeonRows[i]) do
                    element:Hide()
                end
            end
        end
        dungeonRows = {}
        
        -- Create or update dungeon rows
        for i, data in ipairs(dungeonData) do
            local yOffset = startY - ((i - 1) * rowHeight)
            
            -- Create row background
            local bg = createRowBackground(dungeonContentFrame, yOffset, 620)
            if i % 2 == 0 then
                bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
            else
                bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
            end
            
            -- Create row content
            dungeonRows[i] = {
                name = createRowText(data.name, dungeonContentFrame, 0, yOffset, 200),
                completed = createRowText(tostring(data.completed), dungeonContentFrame, 200, yOffset, 100),
                failed = createRowText(tostring(data.failed), dungeonContentFrame, 300, yOffset, 100),
                total = createRowText(tostring(data.total), dungeonContentFrame, 400, yOffset, 100),
                rate = createRowText(string.format("%d%%", data.rate), dungeonContentFrame, 500, yOffset, 120)
            }
            
            -- Color code the success rate
            local row = dungeonRows[i]
            if data.rate >= 80 then
                row.rate:SetTextColor(0, 1, 0)  -- Green for high success
            elseif data.rate >= 60 then
                row.rate:SetTextColor(1, 1, 0)  -- Yellow for medium success
            else
                row.rate:SetTextColor(1, 0, 0)  -- Red for low success
            end
        end
        
        -- If no data, show message
        if #dungeonData == 0 then
            if not dungeonRows[1] then
                dungeonRows[1] = {
                    name = createRowText(string.format("No %s dungeon data available", currentStatsView), dungeonContentFrame, 0, startY, 620)
                }
            else
                dungeonRows[1].name:SetText(string.format("No %s dungeon data available", currentStatsView))
                dungeonRows[1].name:Show()
            end
            dungeonRows[1].name:SetTextColor(0.7, 0.7, 0.7)
        end
    end
    
    -- Update function for stats display
    local function UpdateStats()
        if not CompletionTracker then
            seasonStats:SetText("CompletionTracker not available")
            weeklyStats:SetText("CompletionTracker not available")
            return
        end
        
        local stats = CompletionTracker:getStats()
        
        -- Update season overview
        local seasonTotal = stats.seasonal.completed + stats.seasonal.failed
        local seasonText = string.format("Total Runs: %d\nCompleted: %d (%d%%)\nFailed: %d (%d%%)",
            seasonTotal,
            stats.seasonal.completed, math.floor(stats.seasonal.rate),
            stats.seasonal.failed, math.floor(100 - stats.seasonal.rate)
        )
        seasonStats:SetText(seasonText)
        
        -- Update weekly overview
        local weeklyTotal = stats.weekly.completed + stats.weekly.failed
        local weeklyText = string.format("Total Runs: %d\nCompleted: %d (%d%%)\nFailed: %d (%d%%)",
            weeklyTotal,
            stats.weekly.completed, math.floor(stats.weekly.rate),
            stats.weekly.failed, math.floor(100 - stats.weekly.rate)
        )
        weeklyStats:SetText(weeklyText)
        
        -- Update dungeon breakdown based on current view
        UpdateDungeonBreakdown()
    end
    
    -- Tab functionality
    seasonalTab:SetScript("OnClick", function()
        currentStatsView = "seasonal"
        UpdateDungeonBreakdown()
        seasonalTab:Disable()
        weeklyTab:Enable()
    end)
    
    weeklyTab:SetScript("OnClick", function()
        currentStatsView = "weekly"
        UpdateDungeonBreakdown()
        weeklyTab:Disable()
        seasonalTab:Enable()
    end)
    
    -- Set initial tab state
    weeklyTab:Disable()
    seasonalTab:Enable()
    
    -- Create info panel
    local infoText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("BOTTOM", 0, 25)
    infoText:SetWidth(620)
    infoText:SetJustifyH("CENTER")
    infoText:SetText("Statistics are tracked automatically when you complete Mythic+ dungeons. Use tabs to switch between seasonal and weekly data.")
    infoText:SetTextColor(0.8, 0.8, 0.8)
    
    -- Initialize with stats
    UpdateStats()
end

--- Creates the times content with dungeon timer information
function UIContentCreators.times(parentFrame)
    local title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Mythic+ Timer Thresholds")
    
    -- Create table container without scrolling for smaller lists
    local timesTableFrame = CreateFrame("Frame", nil, parentFrame)
    timesTableFrame:SetPoint("TOPLEFT", 20, -60)
    timesTableFrame:SetSize(620, 380)
    
    local timesContentFrame = timesTableFrame
    
    -- Helper functions
    local function createHeader(text, parent, x, width)
        local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        header:SetPoint("TOPLEFT", x, 0)
        header:SetWidth(width)
        header:SetJustifyH("CENTER")
        header:SetText(text)
        return header
    end
    
    local function createRowBackground(parent, yOffset, width)
        local bg = parent:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 0, yOffset)
        bg:SetSize(width or 620, 30)
        return bg
    end
    
    local function createRowText(text, parent, x, yOffset, width, fontColor)
        local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fontString:SetPoint("TOPLEFT", x, yOffset)
        fontString:SetWidth(width)
        fontString:SetJustifyH("CENTER")
        fontString:SetText(text)
        if fontColor then
            fontString:SetTextColor(fontColor.r, fontColor.g, fontColor.b)
        end
        return fontString
    end
    
    -- Create times table headers
    createHeader("Dungeon", timesContentFrame, 0, 200)
    createHeader("1 Chest (0%)", timesContentFrame, 200, 140)
    createHeader("2 Chests (20%)", timesContentFrame, 340, 140)
    createHeader("3 Chests (40%)", timesContentFrame, 480, 140)
    
    -- Calculate timer thresholds
    local function calculateTimers(parTime)
        return {
            oneChest = parTime,  -- 0% - must complete within par time for 1 chest
            twoChest = math.floor(parTime * 0.8),  -- 20% faster for 2 chests
            threeChest = math.floor(parTime * 0.6)  -- 40% faster for 3 chests
        }
    end
    
    -- Format time in seconds to MM:SS format
    local function formatTime(timeInSeconds)
        if not timeInSeconds or timeInSeconds <= 0 then
            return "0:00"
        end
        
        local minutes = math.floor(timeInSeconds / 60)
        local seconds = timeInSeconds % 60
        return string.format("%d:%02d", minutes, seconds)
    end
    
    -- Create and populate time rows
    local timeRows = {}
    local startY = -25
    local rowHeight = 30
    
    local function UpdateTimes()
        if not DungeonData or not DungeonData.MYTHIC_MAPS then
            return
        end
        
        -- Update or create time rows
        for i, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
            local yOffset = startY - ((i - 1) * rowHeight)
            local timers = calculateTimers(mapInfo.parTime)
            
            if not timeRows[i] then
                -- Create row background
                local bg = createRowBackground(timesContentFrame, yOffset, 620)
                if i % 2 == 0 then
                    bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
                else
                    bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
                end
                
                -- Create row content
                timeRows[i] = {
                    name = createRowText(mapInfo.name, timesContentFrame, 0, yOffset, 200),
                    oneChest = createRowText("", timesContentFrame, 200, yOffset, 140),
                    twoChest = createRowText("", timesContentFrame, 340, yOffset, 140),
                    threeChest = createRowText("", timesContentFrame, 480, yOffset, 140)
                }
            end
            
            -- Update row content
            local row = timeRows[i]
            row.name:SetText(mapInfo.name)
            row.oneChest:SetText(formatTime(timers.oneChest))
            row.twoChest:SetText(formatTime(timers.twoChest))
            row.threeChest:SetText(formatTime(timers.threeChest))
        end
    end
    
    -- Create info panel at bottom
    local infoText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("BOTTOM", 0, 25)
    infoText:SetWidth(620)
    infoText:SetJustifyH("CENTER")
    infoText:SetText("1 Chest: Complete within par time | 2 Chests: 20% faster | 3 Chests: 40% faster")
    infoText:SetTextColor(0.8, 0.8, 0.8)
    
    -- Initialize with default values
    UpdateTimes()
end

-- Main unified frame
local UnifiedFrame = CreateFrame("Frame", "MrMythicalUnifiedFrame", UIParent, "BackdropTemplate")
UnifiedFrame:SetSize(850, 500)
UnifiedFrame:SetPoint("CENTER")
UnifiedFrame:SetFrameStrata("DIALOG")
UnifiedFrame:SetFrameLevel(100)
UnifiedFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
UnifiedFrame:SetBackdropColor(0, 0, 0, 0.8)
UnifiedFrame:SetMovable(true)
UnifiedFrame:EnableMouse(true)
UnifiedFrame:RegisterForDrag("LeftButton")
UnifiedFrame:SetScript("OnDragStart", UnifiedFrame.StartMoving)
UnifiedFrame:SetScript("OnDragStop", UnifiedFrame.StopMovingOrSizing)

UnifiedFrame:EnableKeyboard(true)
UnifiedFrame:SetPropagateKeyboardInput(true)
UnifiedFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        UnifiedFrame:Hide()
        self:SetPropagateKeyboardInput(false)
        return
    end
    -- Propagate all other keys to the game
    self:SetPropagateKeyboardInput(true)
end)

UnifiedFrame:Hide()

local navPanel = CreateFrame("Frame", nil, UnifiedFrame, "BackdropTemplate")
navPanel:SetPoint("TOPLEFT", 10, -10)
navPanel:SetSize(140, 480)
navPanel:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
navPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

-- Navigation buttons
local navButtons = {}
local buttonData = {
    {id = "dashboard", text = "Dashboard", y = -20},
    {id = "rewards", text = "Rewards", y = -60},
    {id = "scores", text = "Scores", y = -100},
    {id = "stats", text = "Statistics", y = -140},
    {id = "times", text = "Times", y = -180},
    {id = "settings", text = "Settings", y = -220}
}

local contentFrame = CreateFrame("Frame", nil, UnifiedFrame)
contentFrame:SetPoint("TOPLEFT", 160, -10)
contentFrame:SetSize(680, 480)

local currentContent = "dashboard"
local activeButton = nil

-- Function to clear content frame
local function clearContent()
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

-- Function to show specific content
local function showContent(contentType)
    clearContent()
    currentContent = contentType
    
    -- Update button states - reset all buttons first
    for _, button in pairs(navButtons) do
        button:SetNormalFontObject("GameFontNormal")
    end
    
    -- Highlight the active button
    if navButtons[contentType] then
        navButtons[contentType]:SetNormalFontObject("GameFontHighlight")
        activeButton = navButtons[contentType]
    end
    
    if UIContentCreators[contentType] then
        UIContentCreators[contentType](contentFrame)
    else
        -- Fallback content
        local fallbackText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fallbackText:SetPoint("CENTER", 0, 0)
        fallbackText:SetText("Content not available: " .. contentType)
    end
end

-- Create navigation buttons
for _, buttonInfo in ipairs(buttonData) do
    local button = CreateFrame("Button", nil, navPanel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", 10, buttonInfo.y)
    button:SetSize(120, 30)
    button:SetText(buttonInfo.text)
    
    button:SetScript("OnClick", function()
        if buttonInfo.id == "settings" then
            UnifiedUI:Hide()
            
            local registry = _G.MrMythicalSettingsRegistry
            if registry and registry.parentCategory and registry.parentCategory.GetID then
                Settings.OpenToCategory(registry.parentCategory:GetID())
            elseif MrMythical.Options and MrMythical.Options.openSettings then
                -- Fallback to the Options module
                MrMythical.Options.openSettings()
            else
                -- Last resort: open general settings
                SettingsPanel:Open()
                print("Mr. Mythical: Settings category not found. Please access via Game Menu > Options > AddOns.")
            end
            return
        end
        
        -- Reset all buttons to normal state
        for _, otherButton in pairs(navButtons) do
            if otherButton ~= button then
                otherButton:SetNormalFontObject("GameFontNormal")
            end
        end
        
        activeButton = button
        button:SetNormalFontObject("GameFontHighlight")
        showContent(buttonInfo.id)
    end)
    
    navButtons[buttonInfo.id] = button
    
    -- Set dashboard as default active
    if buttonInfo.id == "dashboard" then
        activeButton = button
        button:SetNormalFontObject("GameFontHighlight")
    end
end

local closeButton = CreateFrame("Button", nil, UnifiedFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Public functions
function UnifiedUI:Show(contentType)
    UnifiedFrame:Show()
    if contentType then
        showContent(contentType)
    else
        showContent("dashboard")
    end
end

function UnifiedUI:Hide()
    UnifiedFrame:Hide()
end

function UnifiedUI:Toggle(contentType)
    if UnifiedFrame:IsShown() then
        self:Hide()
    else
        self:Show(contentType)
    end
end

function UnifiedUI:IsShown()
    return UnifiedFrame:IsShown()
end

-- Global toggle function for slash command
function MrMythical:ToggleUnifiedUI(contentType)
    UnifiedUI:Toggle(contentType or "dashboard")
end

showContent("dashboard")
