--[[
ScoresUI.lua - Mythic+ Score Display Interface

Purpose: Creates and manages the scores window showing score calculations with timer bonus
Dependencies: RewardsFunctions
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
local RewardsFunctions = MrMythical.RewardsFunctions

-- Create main frame
local ScoresFrame = CreateFrame("Frame", "MrMythicalScoresFrame", UIParent, "BackdropTemplate")
ScoresFrame:SetSize(400, 500)
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

-- Create scrolling table
local scrollFrame = CreateFrame("ScrollFrame", nil, ScoresFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -110)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 40)

local contentFrame = CreateFrame("Frame", nil, scrollFrame)
contentFrame:SetSize(350, 800)
scrollFrame:SetScrollChild(contentFrame)

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
createHeader("Base Score", contentFrame, 80, 100)
createHeader("Timer Bonus", contentFrame, 180, 100)
createHeader("Final Score", contentFrame, 280, 70)

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
local startY = -25
local rowHeight = 25

for level = 2, 20 do
    local yOffset = startY - ((level - 2) * rowHeight)
    
    -- Alternate row colors
    local bg = createRowBackground(contentFrame, yOffset)
    if level % 2 == 0 then
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    else
        bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
    end
    
    -- Get base score
    local baseScore = RewardsFunctions.scoreFormula(level)
    
    -- Create row content
    local row = {
        level = createRowText(level, contentFrame, 0, yOffset, 80),
        base = createRowText(baseScore, contentFrame, 80, yOffset, 100),
        bonus = createRowText("0", contentFrame, 180, yOffset, 100),
        final = createRowText(baseScore, contentFrame, 280, yOffset, 70)
    }
    scoreRows[level] = row
end

-- Update function for timer bonus changes
local function UpdateScores(timerPercentage)
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
