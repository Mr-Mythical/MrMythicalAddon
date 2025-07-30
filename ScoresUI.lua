--[[
ScoresUI.lua - Mythic+ Score Display Interface

Purpose: Creates and manages the scores window showing score calculations with timer bonus
Dependencies: RewardsFunctions, DungeonData
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
local RewardsFunctions = MrMythical.RewardsFunctions
local DungeonData = MrMythical.DungeonData

-- Create main frame
local ScoresFrame = CreateFrame("Frame", "MrMythicalScoresFrame", UIParent, "BackdropTemplate")
ScoresFrame:SetSize(800, 500)
ScoresFrame:SetPoint("CENTER")
ScoresFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ScoresFrame:SetBackdropColor(0, 0, 0, 0.8)
ScoresFrame:SetMovable(true)
ScoresFrame:EnableMouse(true)
ScoresFrame:RegisterForDrag("LeftButton")
ScoresFrame:SetScript("OnDragStart", ScoresFrame.StartMoving)
ScoresFrame:SetScript("OnDragStop", ScoresFrame.StopMovingOrSizing)
ScoresFrame:Hide()

-- Create title
local title = ScoresFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 15, -15)
title:SetText("Mythic+ Score Calculator")

-- Create timer bonus slider
local timerLabel = ScoresFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timerLabel:SetPoint("TOPLEFT", 15, -50)
timerLabel:SetText("Timer Bonus %:")

local timerSlider = CreateFrame("Slider", "MrMythicalTimerSlider", ScoresFrame, "OptionsSliderTemplate")
timerSlider:SetPoint("TOPLEFT", 15, -70)
timerSlider:SetWidth(370)
timerSlider:SetMinMaxValues(0, 40)
timerSlider:SetValue(0)
timerSlider:SetValueStep(1)
timerSlider.tooltipText = "Timer Percentage"
_G[timerSlider:GetName() .. "Low"]:SetText("0%")
_G[timerSlider:GetName() .. "High"]:SetText("40%")
_G[timerSlider:GetName() .. "Text"]:SetText("0%")

-- Table headers
local function createHeader(text, parent, x, width)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", x, 0)
    header:SetWidth(width)
    header:SetJustifyH("CENTER")
    header:SetText(text)
    return header
end

-- Create row background
local function createRowBackground(parent, yOffset, width)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, yOffset)
    bg:SetSize(width or 350, 25)
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

-- Create scrolling tables
local scoreScrollFrame = CreateFrame("ScrollFrame", nil, ScoresFrame, "UIPanelScrollFrameTemplate")
scoreScrollFrame:SetPoint("TOPLEFT", 15, -110)
scoreScrollFrame:SetSize(350, 350)

local scoreContentFrame = CreateFrame("Frame", nil, scoreScrollFrame)
scoreContentFrame:SetSize(350, 800)
scoreScrollFrame:SetScrollChild(scoreContentFrame)

-- Create score table headers
createHeader("Key Level", scoreContentFrame, 0, 80)
createHeader("Base Score", scoreContentFrame, 80, 100)
createHeader("Timer Bonus", scoreContentFrame, 180, 100)
createHeader("Final Score", scoreContentFrame, 280, 70)

-- Create dungeon gains section
local gainsLabel = ScoresFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
gainsLabel:SetPoint("TOPLEFT", 380, -50)
gainsLabel:SetText("Your Dungeons")

-- Add current keystone level dropdown
local currentKeyLabel = ScoresFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
currentKeyLabel:SetPoint("TOPLEFT", 380, -80)
currentKeyLabel:SetText("Using Key Level:")

local currentKeyLevel = CreateFrame("Frame", "MrMythicalCurrentKeyLevel", ScoresFrame, "UIDropDownMenuTemplate")
currentKeyLevel:SetPoint("TOPLEFT", 480, -75)
UIDropDownMenu_SetWidth(currentKeyLevel, 60)
UIDropDownMenu_SetText(currentKeyLevel, "2")

local function CurrentKeyLevel_OnClick(self)
    UIDropDownMenu_SetText(currentKeyLevel, self.value)
    UpdateScores(timerSlider:GetValue())
end

local function CurrentKeyLevel_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for i = 2, 20 do
        info.text = i
        info.value = i
        info.func = CurrentKeyLevel_OnClick
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(currentKeyLevel, CurrentKeyLevel_Initialize)

local gainsScrollFrame = CreateFrame("ScrollFrame", nil, ScoresFrame, "UIPanelScrollFrameTemplate")
gainsScrollFrame:SetPoint("TOPLEFT", 380, -110)
gainsScrollFrame:SetSize(400, 350)

local gainsContentFrame = CreateFrame("Frame", nil, gainsScrollFrame)
gainsContentFrame:SetSize(400, 800)
gainsScrollFrame:SetScrollChild(gainsContentFrame)

-- Create gains table headers
createHeader("Dungeon", gainsContentFrame, 0, 150)
createHeader("Current Level", gainsContentFrame, 150, 70)
createHeader("Timer", gainsContentFrame, 220, 80)
createHeader("Score", gainsContentFrame, 300, 50)
createHeader("Gain", gainsContentFrame, 350, 50)

-- Create row background
local function createRowBackground(parent, yOffset)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, yOffset)
    bg:SetSize(350, 25)
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

-- Create and store text elements for updating
local scoreRows = {}
local gainRows = {}
local startY = -25
local rowHeight = 25

-- Update function for timer bonus changes (defined early so it can be used in OnEnter scripts)
local function UpdateScores(timerPercentage)
    -- Update score table
    for level = 2, 20 do
        local row = scoreRows[level]
        if row then
            local baseScore = RewardsFunctions.scoreFormula(level)
            -- Convert timer percentage to score bonus (0-40% timer = 0-15 score bonus)
            local scoreBonus = math.floor(15 * (timerPercentage / 40))
            local finalScore = baseScore + scoreBonus
            
            row.bonus:SetText(string.format("+%d", scoreBonus))
            row.final:SetText(string.format("%d", finalScore))
            
            -- Color the bonus (always green since it's always positive)
            row.bonus:SetTextColor(0, 1, 0)
        end
    end
    
    -- Update dungeon gains
    local dungeonGains = {}
    local selectedLevel = tonumber(UIDropDownMenu_GetText(currentKeyLevel))
    local finalScore = RewardsFunctions.scoreFormula(selectedLevel)
    finalScore = finalScore + math.floor(15 * (timerPercentage / 40))
    
    for _, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
        local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapInfo.id)
        local currentLevel = 0
        local currentScore = 0
        local timerInfo = ""
        
        if intimeInfo then
            currentLevel = intimeInfo.level
            currentScore = intimeInfo.dungeonScore
            timerInfo = "In Time"
        elseif overtimeInfo then
            currentLevel = overtimeInfo.level
            currentScore = overtimeInfo.dungeonScore
            timerInfo = "Overtime"
        end
        
        local scoreGain = finalScore - currentScore
        table.insert(dungeonGains, { 
            name = mapInfo.name,
            level = currentLevel,
            timer = timerInfo, 
            gain = scoreGain, 
            current = currentScore 
        })
    end
    
    -- Sort by potential gain (highest first)
    table.sort(dungeonGains, function(a, b) return a.gain > b.gain end)
    
    -- Update or create gain rows
    for i, gain in ipairs(dungeonGains) do
        local yOffset = startY - ((i - 1) * rowHeight)
        
        if not gainRows[i] then
            -- Create row background
            local bg = createRowBackground(gainsContentFrame, yOffset, 400)
            if i % 2 == 0 then
                bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
            else
                bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
            end
            
            -- Create row content
            gainRows[i] = {
                name = createRowText(gain.name, gainsContentFrame, 0, yOffset, 150),
                level = createRowText("", gainsContentFrame, 150, yOffset, 70),
                timer = createRowText("", gainsContentFrame, 220, yOffset, 80),
                score = createRowText("", gainsContentFrame, 300, yOffset, 50),
                gain = createRowText("", gainsContentFrame, 350, yOffset, 50)
            }
        end
        
        -- Update row content
        local row = gainRows[i]
        row.name:SetText(gain.name)
        row.level:SetText(gain.level > 0 and gain.level or "-")
        row.timer:SetText(gain.timer)
        row.score:SetText(gain.current)
        
        if gain.gain > 0 then
            row.gain:SetText(string.format("+%d", gain.gain))
            row.gain:SetTextColor(0, 1, 0)
        else
            row.gain:SetText("-")
            row.gain:SetTextColor(0.7, 0.7, 0.7)
        end
        
        -- Color timer text
        if gain.timer == "In Time" then
            row.timer:SetTextColor(0, 1, 0)
        elseif gain.timer == "Overtime" then
            row.timer:SetTextColor(1, 0, 0)
        else
            row.timer:SetTextColor(1, 1, 1)
        end
    end
end

for level = 2, 20 do
    local yOffset = startY - ((level - 2) * rowHeight)
    
    -- Alternate row colors
    local bg = createRowBackground(scoreContentFrame, yOffset)
    if level % 2 == 0 then
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    else
        bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
    end
    
    -- Get base score
    local baseScore = RewardsFunctions.scoreFormula(level)
    
    -- Create row content
    local row = {
        level = createRowText(level, scoreContentFrame, 0, yOffset, 80),
        base = createRowText(baseScore, scoreContentFrame, 80, yOffset, 100),
        bonus = createRowText("0", scoreContentFrame, 180, yOffset, 100),
        final = createRowText(baseScore, scoreContentFrame, 280, yOffset, 70)
    }
    
    -- Make the row interactive - hovering sets the key level for dungeon calculations
    local rowFrame = CreateFrame("Button", nil, scoreContentFrame)
    rowFrame:SetPoint("TOPLEFT", 0, yOffset)
    rowFrame:SetSize(350, 25)
    rowFrame:EnableMouse(true)
    rowFrame:SetScript("OnEnter", function(self)
        UIDropDownMenu_SetText(currentKeyLevel, level)
        UpdateScores(timerSlider:GetValue())
    end)
    
    scoreRows[level] = row
end

-- Slider value changed
timerSlider:SetScript("OnValueChanged", function(self, value)
    _G[self:GetName() .. "Text"]:SetText(string.format("%d%%", value))
    UpdateScores(value)
end)

-- Close button
local closeButton = CreateFrame("Button", nil, ScoresFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Toggle function
function MrMythical:ToggleScoresUI()
    if ScoresFrame:IsShown() then
        ScoresFrame:Hide()
    else
        ScoresFrame:Show()
        UpdateScores(timerSlider:GetValue())
    end
end
