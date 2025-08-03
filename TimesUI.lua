--[[
TimesUI.lua - Mythic+ Times Display Interface

Purpose: Creates and manages the times window showing timer thresholds for different chest rewards
Dependencies: DungeonData
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
local DungeonData = MrMythical.DungeonData

-- Create main frame
local TimesFrame = CreateFrame("Frame", "MrMythicalTimesFrame", UIParent, "BackdropTemplate")
TimesFrame:SetSize(700, 500)
TimesFrame:SetPoint("CENTER")
TimesFrame:SetFrameStrata("DIALOG")
TimesFrame:SetFrameLevel(100)
TimesFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TimesFrame:SetBackdropColor(0, 0, 0, 0.8)
TimesFrame:SetMovable(true)
TimesFrame:EnableMouse(true)
TimesFrame:RegisterForDrag("LeftButton")
TimesFrame:SetScript("OnDragStart", TimesFrame.StartMoving)
TimesFrame:SetScript("OnDragStop", TimesFrame.StopMovingOrSizing)
TimesFrame:Hide()

-- Create title
local title = TimesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 15, -15)
title:SetText("Mythic+ Timer Thresholds")

-- Create scrolling table
local timesScrollFrame = CreateFrame("ScrollFrame", nil, TimesFrame, "UIPanelScrollFrameTemplate")
timesScrollFrame:SetPoint("TOPLEFT", 15, -50)
-- Create scrolling table
local timesScrollFrame = CreateFrame("ScrollFrame", nil, TimesFrame, "UIPanelScrollFrameTemplate")
timesScrollFrame:SetPoint("TOPLEFT", 15, -50)
timesScrollFrame:SetSize(650, 400)

local timesContentFrame = CreateFrame("Frame", nil, timesScrollFrame)
timesContentFrame:SetSize(650, 800)
timesScrollFrame:SetScrollChild(timesContentFrame)

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
    bg:SetSize(width or 650, 30)
    return bg
end

-- Create row content
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
createHeader("1 Chest (0%)", timesContentFrame, 200, 150)
createHeader("2 Chests (20%)", timesContentFrame, 350, 150)
createHeader("3 Chests (40%)", timesContentFrame, 500, 150)

-- Create and store text elements for updating
local timeRows = {}
local startY = -25
local rowHeight = 30

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

-- Update function for displaying times
local function UpdateTimes()
    -- Update or create time rows
    for i, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
        local yOffset = startY - ((i - 1) * rowHeight)
        local timers = calculateTimers(mapInfo.parTime)
        
        if not timeRows[i] then
            -- Create row background
            local bg = createRowBackground(timesContentFrame, yOffset, 650)
            if i % 2 == 0 then
                bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
            else
                bg:SetColorTexture(0.15, 0.15, 0.15, 0.3)
            end
            
            -- Create row content
            timeRows[i] = {
                name = createRowText(mapInfo.name, timesContentFrame, 0, yOffset, 200),
                oneChest = createRowText("", timesContentFrame, 200, yOffset, 150),
                twoChest = createRowText("", timesContentFrame, 350, yOffset, 150),
                threeChest = createRowText("", timesContentFrame, 500, yOffset, 150)
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

-- Create info panel
local infoPanel = CreateFrame("Frame", nil, TimesFrame)
infoPanel:SetPoint("BOTTOMLEFT", 15, 15)
infoPanel:SetSize(650, 30)

local infoText = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
infoText:SetPoint("TOPLEFT", 0, 0)
infoText:SetWidth(650)
infoText:SetJustifyH("LEFT")
infoText:SetText("1 Chest: Complete within par time | 2 Chests: 20% faster | 3 Chests: 40% faster")
infoText:SetTextColor(0.8, 0.8, 0.8)

-- Close button
local closeButton = CreateFrame("Button", nil, TimesFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Toggle function
function MrMythical:ToggleTimesUI()
    if TimesFrame:IsShown() then
        TimesFrame:Hide()
    else
        TimesFrame:Show()
        UpdateTimes()
    end
end

-- Initialize with default values
UpdateTimes()
