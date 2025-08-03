--[[
RewardsUI.lua - Mythic+ Rewards User Interface

Purpose: Creates and manages the rewards window showing dungeon, vault, and crest rewards
Dependencies: RewardsData, RewardsFunctions
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
local RewardsFunctions = MrMythical.RewardsFunctions

-- Create main frame
local RewardsFrame = CreateFrame("Frame", "MrMythicalRewardsFrame", UIParent, "BackdropTemplate")
RewardsFrame:SetSize(600, 400)
RewardsFrame:SetPoint("CENTER")
RewardsFrame:SetFrameStrata("DIALOG")
RewardsFrame:SetFrameLevel(100)
RewardsFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
RewardsFrame:SetBackdropColor(0, 0, 0, 0.8)
RewardsFrame:SetMovable(true)
RewardsFrame:EnableMouse(true)
RewardsFrame:RegisterForDrag("LeftButton")
RewardsFrame:SetScript("OnDragStart", RewardsFrame.StartMoving)
RewardsFrame:SetScript("OnDragStop", RewardsFrame.StopMovingOrSizing)
RewardsFrame:Hide()

-- Create title
local title = RewardsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 15, -15)
title:SetText("Mythic+ Rewards")

-- Create scrolling table
local scrollFrame = CreateFrame("ScrollFrame", nil, RewardsFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 40)

local contentFrame = CreateFrame("Frame", nil, scrollFrame)
contentFrame:SetSize(550, 800)  -- Height will adjust based on content
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

-- Populate table
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
    
    -- Get rewards data
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

-- Close button
local closeButton = CreateFrame("Button", nil, RewardsFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Toggle function
function MrMythical:ToggleRewardsUI()
    if RewardsFrame:IsShown() then
        RewardsFrame:Hide()
    else
        RewardsFrame:Show()
    end
end
