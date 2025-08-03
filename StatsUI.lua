--[[
StatsUI.lua - Mythic+ Statistics Display Interface

Purpose: Creates and manages the statistics window showing completion rates and dungeon breakdown
Dependencies: CompletionTracker, DungeonData
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
local CompletionTracker = MrMythical.CompletionTracker
local DungeonData = MrMythical.DungeonData

-- Create main frame
local StatsFrame = CreateFrame("Frame", "MrMythicalStatsFrame", UIParent, "BackdropTemplate")
StatsFrame:SetSize(700, 600)
StatsFrame:SetPoint("CENTER")
StatsFrame:SetFrameStrata("DIALOG")
StatsFrame:SetFrameLevel(100)
StatsFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
StatsFrame:SetBackdropColor(0, 0, 0, 0.8)
StatsFrame:SetMovable(true)
StatsFrame:EnableMouse(true)
StatsFrame:RegisterForDrag("LeftButton")
StatsFrame:SetScript("OnDragStart", StatsFrame.StartMoving)
StatsFrame:SetScript("OnDragStop", StatsFrame.StopMovingOrSizing)
StatsFrame:Hide()

-- Create title
local title = StatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 15, -15)
title:SetText("Mythic+ Completion Statistics")

-- Create season overview section
local seasonLabel = StatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
seasonLabel:SetPoint("TOPLEFT", 15, -50)
seasonLabel:SetText("Season Overview")
seasonLabel:SetTextColor(0, 1, 0)

local seasonStats = StatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
seasonStats:SetPoint("TOPLEFT", 15, -75)
seasonStats:SetWidth(320)
seasonStats:SetJustifyH("LEFT")

-- Create weekly overview section
local weeklyLabel = StatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
weeklyLabel:SetPoint("TOPLEFT", 350, -50)
weeklyLabel:SetText("This Week")
weeklyLabel:SetTextColor(0, 1, 0)

local weeklyStats = StatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
weeklyStats:SetPoint("TOPLEFT", 350, -75)
weeklyStats:SetWidth(320)
weeklyStats:SetJustifyH("LEFT")

-- Create dungeon breakdown section
local dungeonLabel = StatsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
dungeonLabel:SetPoint("TOPLEFT", 15, -150)
dungeonLabel:SetText("Dungeon Breakdown")
dungeonLabel:SetTextColor(0, 1, 0)

-- Create tab buttons for switching between seasonal and weekly
local tabFrame = CreateFrame("Frame", nil, StatsFrame)
tabFrame:SetPoint("TOPLEFT", 15, -175)
tabFrame:SetSize(650, 30)

local seasonalTab = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
seasonalTab:SetPoint("TOPLEFT", 0, 0)
seasonalTab:SetSize(100, 25)
seasonalTab:SetText("Seasonal")

local weeklyTab = CreateFrame("Button", nil, tabFrame, "UIPanelButtonTemplate")
weeklyTab:SetPoint("TOPLEFT", 105, 0)
weeklyTab:SetSize(100, 25)
weeklyTab:SetText("Weekly")

-- Create scrolling table for dungeon stats
local dungeonScrollFrame = CreateFrame("ScrollFrame", nil, StatsFrame, "UIPanelScrollFrameTemplate")
dungeonScrollFrame:SetPoint("TOPLEFT", 15, -205)
dungeonScrollFrame:SetSize(650, 270)

local dungeonContentFrame = CreateFrame("Frame", nil, dungeonScrollFrame)
dungeonContentFrame:SetSize(650, 800)
dungeonScrollFrame:SetScrollChild(dungeonContentFrame)

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
    bg:SetSize(width or 650, 25)
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

-- Create dungeon table headers
createHeader("Dungeon", dungeonContentFrame, 0, 200)
createHeader("Completed", dungeonContentFrame, 200, 100)
createHeader("Failed", dungeonContentFrame, 300, 100)
createHeader("Total", dungeonContentFrame, 400, 100)
createHeader("Success Rate", dungeonContentFrame, 500, 150)

-- Create and store text elements for updating
local dungeonRows = {}
local startY = -25
local rowHeight = 25
local currentStatsView = "weekly"  -- Track which view is active

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

-- Function to update dungeon breakdown based on current view
function UpdateDungeonBreakdown()
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
        local bg = createRowBackground(dungeonContentFrame, yOffset, 650)
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
            rate = createRowText(string.format("%d%%", data.rate), dungeonContentFrame, 500, yOffset, 150)
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
                name = createRowText(string.format("No %s dungeon data available", currentStatsView), dungeonContentFrame, 0, startY, 650)
            }
        else
            dungeonRows[1].name:SetText(string.format("No %s dungeon data available", currentStatsView))
            dungeonRows[1].name:Show()
        end
        dungeonRows[1].name:SetTextColor(0.7, 0.7, 0.7)
    end
end

-- Update function for stats display
function UpdateStats()
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

-- Create info panel
local infoPanel = CreateFrame("Frame", nil, StatsFrame)
infoPanel:SetPoint("BOTTOMLEFT", 15, 15)
infoPanel:SetSize(650, 30)

local infoText = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
infoText:SetPoint("TOPLEFT", 0, 0)
infoText:SetWidth(650)
infoText:SetJustifyH("LEFT")
infoText:SetText("Statistics are tracked automatically when you complete Mythic+ dungeons. Use tabs to switch between seasonal and weekly data.")
infoText:SetTextColor(0.8, 0.8, 0.8)

-- Close button
local closeButton = CreateFrame("Button", nil, StatsFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Toggle function
function MrMythical:ToggleStatsUI()
    if StatsFrame:IsShown() then
        StatsFrame:Hide()
    else
        StatsFrame:Show()
        UpdateStats()
    end
end
