--[[
ScoreCalculator.lua - Mythic+ Score Calculator Content

Handles the score calculator interface and functionality.
--]]

local MrMythical = MrMythical or {}
MrMythical.ScoreCalculator = {}

local ScoreCalculator = MrMythical.ScoreCalculator
local UIConstants = MrMythical.UIConstants
local UIHelpers = MrMythical.UIHelpers
local RewardsFunctions = MrMythical.RewardsFunctions
local DungeonData = MrMythical.DungeonData

-- Constants for key level range
local MIN_KEY_LEVEL = 2 -- Todo: Make these configurable in ui
local MAX_KEY_LEVEL = 30

function ScoreCalculator.create(parentFrame)
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Mythic+ Score Calculator", "TOP", 0, -UIConstants.LAYOUT.LARGE_PADDING)
    
    local descText = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalSmall",
        "Hover over key levels in the left table to see potential score gains for your dungeons on the right",
        "TOP", 0, -10)
    descText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    descText:SetWidth(650)
    descText:SetJustifyH("CENTER")
    UIHelpers.setTextColor(descText, "INFO_TEXT")
    
    local timerSlider = ScoreCalculator.createTimerSlider(parentFrame)
    local currentKeyLevel = ScoreCalculator.createKeyLevelDropdown(parentFrame)
    local scoreRows, gainRows = ScoreCalculator.createScoreTables(parentFrame)
    
    ScoreCalculator.setupScoreCalculator(timerSlider, currentKeyLevel, scoreRows, gainRows)
end

function ScoreCalculator.createTimerSlider(parentFrame)
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

function ScoreCalculator.createKeyLevelDropdown(parentFrame)
    local currentKeyLevel = CreateFrame("Frame", "MrMythicalUnifiedCurrentKeyLevel", parentFrame, "UIDropDownMenuTemplate")
    currentKeyLevel:SetPoint("TOPLEFT", 450, -105)
    UIDropDownMenu_SetWidth(currentKeyLevel, 60)
    UIDropDownMenu_SetText(currentKeyLevel, tostring(MIN_KEY_LEVEL))
    
    return currentKeyLevel
end

function ScoreCalculator.createScoreTables(parentFrame)
    local scoreScrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
    scoreScrollFrame:SetPoint("TOPLEFT", UIConstants.LAYOUT.LARGE_PADDING, -110)
    scoreScrollFrame:SetSize(320, 320)
    
    local scoreContentFrame = CreateFrame("Frame", nil, scoreScrollFrame)
    scoreContentFrame:SetSize(320, 800)
    scoreScrollFrame:SetScrollChild(scoreContentFrame)
    
    UIHelpers.createHeader(scoreContentFrame, "Key Level", 0, 70)
    UIHelpers.createHeader(scoreContentFrame, "Base Score", 70, 80)
    UIHelpers.createHeader(scoreContentFrame, "Timer Bonus", 150, 80)
    UIHelpers.createHeader(scoreContentFrame, "Final Score", 230, 90)
    
    local gainsTableFrame = CreateFrame("Frame", nil, parentFrame)
    gainsTableFrame:SetPoint("TOPLEFT", 350, -140)
    gainsTableFrame:SetSize(310, 290)
    
    UIHelpers.createHeader(gainsTableFrame, "Dungeon", 0, 110)
    UIHelpers.createHeader(gainsTableFrame, "Level", 110, 40)
    UIHelpers.createHeader(gainsTableFrame, "Score", 150, 50)
    UIHelpers.createHeader(gainsTableFrame, "Time", 200, 60)
    UIHelpers.createHeader(gainsTableFrame, "Gain", 260, 50)
    
    return ScoreCalculator.createScoreRows(scoreContentFrame), ScoreCalculator.createGainRows(gainsTableFrame)
end

function ScoreCalculator.createScoreRows(scoreContentFrame)
    local scoreRows = {}
    local startY = -25
    
    for level = MIN_KEY_LEVEL, MAX_KEY_LEVEL do
        local yOffset = startY - ((level - MIN_KEY_LEVEL) * UIConstants.LAYOUT.ROW_HEIGHT)
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
            rowFrame:SetSize(320, UIConstants.LAYOUT.ROW_HEIGHT)
            rowFrame:EnableMouse(true)
            rowFrame.level = level
            scoreRows[level].frame = rowFrame
        end
    end
    
    return scoreRows
end

function ScoreCalculator.createGainRows(gainsTableFrame)
    local gainRows = {}
    
    if not DungeonData or not DungeonData.MYTHIC_MAPS then
        return gainRows
    end
    
    if MrMythical.DungeonData and MrMythical.DungeonData.getAllDungeonData then
        local dungeonData = MrMythical.DungeonData.getAllDungeonData()
        local startY = -25
        
        for i, data in ipairs(dungeonData) do
            local yOffset = startY - ((i - 1) * UIConstants.LAYOUT.ROW_HEIGHT)
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

function ScoreCalculator.setupScoreCalculator(timerSlider, currentKeyLevel, scoreRows, gainRows)
    local function updateScores(timerPercentage)
        ScoreCalculator.updateScoreTable(scoreRows, timerPercentage)
        ScoreCalculator.updateDungeonGains(gainRows, currentKeyLevel, timerPercentage)
    end
    
    local function currentKeyLevelOnClick(self)
        UIDropDownMenu_SetText(currentKeyLevel, self.value)
        updateScores(timerSlider:GetValue())
    end
    
    local function currentKeyLevelInitialize()
        local info = UIDropDownMenu_CreateInfo()
        for i = MIN_KEY_LEVEL, MAX_KEY_LEVEL do
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

function ScoreCalculator.updateScoreTable(scoreRows, timerPercentage)
    if not RewardsFunctions or not RewardsFunctions.scoreFormula then
        return
    end
    
    for level = MIN_KEY_LEVEL, MAX_KEY_LEVEL do
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

function ScoreCalculator.updateDungeonGains(gainRows, currentKeyLevel, timerPercentage)
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

-- Add score calculator to ContentCreators
if MrMythical.ContentCreators then
    MrMythical.ContentCreators.scores = ScoreCalculator.create
end

return ScoreCalculator
