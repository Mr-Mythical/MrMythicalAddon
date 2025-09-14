--[[
ContentCreators.lua - UI Content Creation Module

Creates the various content panels for the unified interface.
This module handles dashboard, rewards, and times content.
--]]

local MrMythical = MrMythical or {}
MrMythical.ContentCreators = {}

local ContentCreators = MrMythical.ContentCreators

--- Creates the main dashboard content with welcome message and basic information
--- @param parentFrame Frame The parent frame to attach the dashboard content to
function ContentCreators.dashboard(parentFrame)
    local UIConstants = MrMythical.UIConstants
    local UIHelpers = MrMythical.UIHelpers
    
    if not UIHelpers then
        return
    end
    
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge", 
        "Mr. Mythical Dashboard", "TOP", 0, UIConstants and -UIConstants.LAYOUT.LARGE_PADDING or -20)
    
    local subtitle = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontHighlight",
        "Mythic+ Tools & Information", "TOP", 0, -5)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    local welcome = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormal",
        "Welcome to Mr. Mythical! Use the navigation panel to access different tools.", "TOP", 0, -30)
    welcome:SetPoint("TOP", subtitle, "BOTTOM", 0, -30)
    welcome:SetWidth(400)
    welcome:SetJustifyH("CENTER")
    
    local version = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontDisableSmall",
        "Mr. Mythical by Braunerr", "BOTTOM", 0, UIConstants and UIConstants.LAYOUT.LARGE_PADDING or 20)
    UIHelpers.setTextColor(version, "DISABLED")
end

--- Creates the rewards table interface showing Mythic+ rewards for different key levels
--- @param parentFrame Frame The parent frame to attach the rewards content to
function ContentCreators.rewards(parentFrame)
    local UIConstants = MrMythical.UIConstants
    local UIHelpers = MrMythical.UIHelpers
    
    if not UIHelpers then
        return
    end
    
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Mythic+ Rewards", "TOP", 0, UIConstants and -UIConstants.LAYOUT.LARGE_PADDING or -20)
    
    local rewardsTableFrame = CreateFrame("Frame", nil, parentFrame)
    rewardsTableFrame:SetPoint("TOPLEFT", UIConstants and UIConstants.LAYOUT.LARGE_PADDING or 20, -60)
    rewardsTableFrame:SetSize(530, 380)
    
    ContentCreators.createRewardsTable(rewardsTableFrame)
end

--- Creates the rewards table with headers and data rows
--- @param parentFrame Frame The parent frame to attach the rewards table to
function ContentCreators.createRewardsTable(parentFrame)
    local UIHelpers = MrMythical.UIHelpers
    if not UIHelpers then
        return
    end
    
    UIHelpers.createHeader(parentFrame, "Key Level", 0, 80)
    UIHelpers.createHeader(parentFrame, "End of Dungeon", 80, 150)
    UIHelpers.createHeader(parentFrame, "Great Vault", 230, 150)
    UIHelpers.createHeader(parentFrame, "Crest Rewards", 380, 150)
    
    local startY = -25
    for level = 2, 12 do
        ContentCreators.createRewardRow(parentFrame, level, startY, level - 2)
    end
end

function ContentCreators.createRewardRow(parentFrame, level, startY, index)
    local UIConstants = MrMythical.UIConstants
    local UIHelpers = MrMythical.UIHelpers
    local RewardsFunctions = MrMythical.RewardsFunctions
    
    if not UIHelpers or not RewardsFunctions then
        return
    end
    
    local yOffset = startY - (index * (UIConstants and UIConstants.LAYOUT.ROW_HEIGHT or 25))
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

--- Creates the dungeon timer thresholds interface
--- @param parentFrame Frame The parent frame to attach the times content to
function ContentCreators.times(parentFrame)
    local UIConstants = MrMythical.UIConstants
    local UIHelpers = MrMythical.UIHelpers
    
    if not UIHelpers then
        return
    end
    
    local title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
        "Mythic+ Timer Thresholds", "TOP", 0, UIConstants and -UIConstants.LAYOUT.LARGE_PADDING or -20)
    
    local timesTableFrame = CreateFrame("Frame", nil, parentFrame)
    timesTableFrame:SetPoint("TOPLEFT", UIConstants and UIConstants.LAYOUT.LARGE_PADDING or 20, -60)
    timesTableFrame:SetSize(620, 380)
    
    ContentCreators.createTimesTable(timesTableFrame)
    ContentCreators.createTimesInfoPanel(parentFrame)
end

function ContentCreators.createTimesTable(parentFrame)
    local UIHelpers = MrMythical.UIHelpers
    local DungeonData = MrMythical.DungeonData
    
    if not UIHelpers then
        return
    end
    
    UIHelpers.createHeader(parentFrame, "Dungeon", 0, 200)
    UIHelpers.createHeader(parentFrame, "1 Chest (0%)", 200, 140)
    UIHelpers.createHeader(parentFrame, "2 Chests (20%)", 340, 140)
    UIHelpers.createHeader(parentFrame, "3 Chests (40%)", 480, 140)
    
    if DungeonData and DungeonData.MYTHIC_MAPS then
        local startY = -25
        for i, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
            ContentCreators.createTimeRow(parentFrame, mapInfo, i, startY)
        end
    end
end

function ContentCreators.createTimeRow(parentFrame, mapInfo, index, startY)
    local UIConstants = MrMythical.UIConstants
    local UIHelpers = MrMythical.UIHelpers
    local DungeonData = MrMythical.DungeonData
    
    if not UIHelpers or not DungeonData then
        return
    end
    
    local yOffset = startY - ((index - 1) * (UIConstants and UIConstants.LAYOUT.LARGE_ROW_HEIGHT or 30))
    local isEven = index % 2 == 0
    local timers = ContentCreators.calculateTimers(mapInfo.parTime)
    
    UIHelpers.createRowBackground(parentFrame, yOffset, 620, isEven)
    
    UIHelpers.createRowText(parentFrame, mapInfo.name, 0, yOffset, 200)
    UIHelpers.createRowText(parentFrame, DungeonData.formatTime(timers.oneChest), 200, yOffset, 140)
    UIHelpers.createRowText(parentFrame, DungeonData.formatTime(timers.twoChest), 340, yOffset, 140)
    UIHelpers.createRowText(parentFrame, DungeonData.formatTime(timers.threeChest), 480, yOffset, 140)
end

--- Calculates the timer thresholds for chest completion based on par time
--- @param parTime number The par time for the dungeon in seconds
--- @return table Timer thresholds with oneChest, twoChest, and threeChest times
function ContentCreators.calculateTimers(parTime)
    if not parTime or parTime <= 0 then
        return {oneChest = 0, twoChest = 0, threeChest = 0}
    end
    
    return {
        oneChest = parTime,
        twoChest = math.floor(parTime * 0.8),
        threeChest = math.floor(parTime * 0.6)
    }
end

--- Calculates the chest level based on completion time and par time
--- @param completionTime number The actual completion time in seconds
--- @param parTime number The par time for the dungeon in seconds
--- @return number,number Chest level (0-3) and descriptive string
function ContentCreators.calculateChestLevel(completionTime, parTime)
    if not completionTime or not parTime or parTime <= 0 then
        return 0, "none"
    end
    
    local timers = ContentCreators.calculateTimers(parTime)
    
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

function ContentCreators.createTimesInfoPanel(parentFrame)
    local UIHelpers = MrMythical.UIHelpers
    
    if not UIHelpers then
        return
    end
    
    local infoText = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalSmall",
        "1 Chest: Complete within par time | 2 Chests: 20% faster | 3 Chests: 40% faster",
        "BOTTOM", 0, 25)
    infoText:SetWidth(620)
    infoText:SetJustifyH("CENTER")
    UIHelpers.setTextColor(infoText, "INFO_TEXT")
end

return ContentCreators
