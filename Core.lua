--[[
Core.lua - Mr. Mythical Main Addon Core Logic

Purpose: Main functionality for Mythic+ keystone tooltips and scoring
Dependencies: All Data and Utils modules
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

local GradientsData = MrMythical.GradientsData
local ConfigData = MrMythical.ConfigData
local DungeonData = MrMythical.DungeonData

local ColorUtils = MrMythical.ColorUtils
local KeystoneUtils = MrMythical.KeystoneUtils
local TooltipUtils = MrMythical.TooltipUtils
local CommandHandlers = MrMythical.CommandHandlers
local CompletionTracker = MrMythical.CompletionTracker
local RewardsFunctions = MrMythical.RewardsFunctions

local Options = MrMythical.Options

local GRADIENTS = GradientsData.GRADIENTS
local currentPlayerRegion = "us"

--- Retrieves the dungeon score for a specific map from a RaiderIO profile
--- @param profile table RaiderIO profile data containing mythic keystone information
--- @param targetMapID number The specific dungeon map ID to find score for
--- @return number The dungeon score, or 0 if no data found
local function getDungeonScoreFromProfile(profile, targetMapID)
    if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.sortedDungeons then
        for _, dungeonEntry in ipairs(profile.mythicKeystoneProfile.sortedDungeons) do
            if dungeonEntry.dungeon and dungeonEntry.dungeon.keystone_instance == targetMapID then
                local completedLevel = dungeonEntry.level or 0
                local chestsEarned = dungeonEntry.chests or 0
                local baseScore = RewardsFunctions.scoreFormula(completedLevel)
                
                local chestBonus = 0
                if chestsEarned == 2 then
                    chestBonus = 7.5
                elseif chestsEarned >= 3 then
                    chestBonus = 15
                end
                
                return baseScore + chestBonus
            end
        end
    end
    
    -- Fallback to average score if specific dungeon not found
    if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.currentScore then
        local numDungeons = #profile.mythicKeystoneProfile.sortedDungeons
        if numDungeons > 0 then
            return profile.mythicKeystoneProfile.currentScore / numDungeons
        end
    end
    
    return 0
end

--- Retrieves mythic+ scores for all group members for a specific dungeon
--- @param playerScore number The current player's score for this dungeon
--- @param targetMapID number The dungeon map ID to get scores for
--- @return table A mapping of player names to their dungeon scores
function MrMythical.getGroupMythicDataParty(playerScore, targetMapID)
    local groupScoreData = {}
    local playerName = UnitName("player")
    groupScoreData[playerName] = playerScore
    
    local region = currentPlayerRegion
    local numGroupMembers = GetNumGroupMembers() or 1
    
    for i = 1, numGroupMembers - 1 do
        local unitID = "party" .. i
        if UnitExists(unitID) then
            local name, realm = UnitName(unitID)
            realm = realm and realm ~= "" and realm or GetRealmName()
            
            if RaiderIO and RaiderIO.GetProfile then
                local playerProfile = RaiderIO.GetProfile(name, realm, region)
                local dungeonScore = 0
                
                if playerProfile and playerProfile.mythicKeystoneProfile then
                    dungeonScore = getDungeonScoreFromProfile(playerProfile, targetMapID)
                end
                
                groupScoreData[name] = dungeonScore
            else
                groupScoreData[name] = 0
            end
        end
    end
    
    return groupScoreData
end

--- Retrieves the player's best mythic+ score for a given keystone
--- @param itemString string The keystone item string to get score for
--- @return number The player's best score for this keystone, or 0 if no data
function MrMythical.getCharacterMythicScore(itemString)
    local mapID = KeystoneUtils.extractMapID(itemString)
    if not mapID then
        return 0
    end
    
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    
    if intimeInfo and intimeInfo.dungeonScore then
        return intimeInfo.dungeonScore
    elseif overtimeInfo and overtimeInfo.dungeonScore then
        return overtimeInfo.dungeonScore
    else
        return 0
    end
end

--- Processes and rebuilds keystone tooltip according to user preferences
--- Handles level display modes, text filtering, and title modifications
--- @param tooltip table The GameTooltip object to process
local function processKeystoneTooltip(tooltip)
    local isShiftPressed = IsShiftKeyDown()
    local processedLines = {}
    local firstLine = _G["GameTooltipTextLeft1"]
    local levelDisplayMode = MRM_SavedVars.LEVEL_DISPLAY or "OFF"
    
    -- Process title line with level information if needed
    if firstLine then
        local titleText = firstLine:GetText()
        if titleText then
            if levelDisplayMode == "TITLE" then
                local keyLevel, resilientLevel = TooltipUtils.extractLevelInfoFromTooltip(tooltip)
                titleText = TooltipUtils.processLevelInTitle(titleText, keyLevel, resilientLevel, isShiftPressed)
            elseif MRM_SavedVars.SHORT_TITLE and titleText:find("^Keystone: ") then
                titleText = titleText:gsub("^Keystone: ", "")
            end
            firstLine:SetText(titleText)
        end
        
        table.insert(processedLines, {
            left = titleText,
            right = _G["GameTooltipTextRight1"] and _G["GameTooltipTextRight1"]:GetText(),
            color = {firstLine:GetTextColor()}
        })
    end

    -- Process remaining tooltip lines
    for i = 2, tooltip:NumLines() do
        local leftLine = _G["GameTooltipTextLeft"..i]
        local rightLine = _G["GameTooltipTextRight"..i]
        
        if leftLine then
            local lineText = leftLine:GetText() or ""
            local red, green, blue = leftLine:GetTextColor()
            local lineColor = {red, green, blue}
            
            -- Handle different level display modes
            if levelDisplayMode == "COMPACT" then
                lineText = TooltipUtils.processCompactLevelDisplay(lineText, isShiftPressed, lineColor)
            elseif TooltipUtils.shouldHideLevelLine(lineText, levelDisplayMode, isShiftPressed) then
                lineText = nil
            end
            
            -- Filter unwanted text based on user settings
            if lineText and not TooltipUtils.shouldHideTooltipText(lineText) then
                table.insert(processedLines, {
                    left = lineText,
                    right = rightLine and rightLine:GetText(),
                    color = lineColor
                })
            end
        end
    end

    TooltipUtils.rebuildTooltipWithProcessedLines(tooltip, processedLines)
end

--- Adds comprehensive reward and score information to keystone tooltips
--- @param tooltip table The GameTooltip object to enhance
--- @param itemString string The keystone item string
--- @param keyLevel number The keystone level
--- @param mapID number The dungeon map ID
local function enhanceTooltipWithRewardInfo(tooltip, itemString, keyLevel, mapID)
    local currentScore = MrMythical.getCharacterMythicScore(itemString)
    local groupScoreData = MrMythical.getGroupMythicDataParty(currentScore, mapID)
    
    -- Calculate group average potential gain
    local totalPotentialGain, playerCount = 0, 0
    local potentialScore = RewardsFunctions.scoreFormula(keyLevel)
    
    for _, playerScore in pairs(groupScoreData) do
        local playerGain = math.max(potentialScore - playerScore, 0)
        totalPotentialGain = totalPotentialGain + playerGain
        playerCount = playerCount + 1
    end
    
    local averageGroupGain = (playerCount > 0) and (totalPotentialGain / playerCount) or 0
    
    -- Generate color-coded displays
    local groupColor = ColorUtils.calculateGradientColor(averageGroupGain, 0, 200, GRADIENTS)
    local baseColor = ColorUtils.calculateGradientColor(potentialScore, 165, 500, GRADIENTS)
    local playerGain = math.max(potentialScore - currentScore, 0)
    local gainColor = ColorUtils.calculateGradientColor(playerGain, 0, 200, GRADIENTS)
    
    -- Get reward information
    local rewards = RewardsFunctions.getRewardsForKeyLevel(keyLevel)
    local crest = RewardsFunctions.getCrestReward(keyLevel)

    -- Add dungeon timer if enabled (at the top)
    if MRM_SavedVars.SHOW_PAR_TIME then
        local parTime = DungeonData.getParTime(mapID)
        if parTime then
            local formattedTime = DungeonData.formatTime(parTime)
            tooltip:AddLine(string.format("%sDungeon Timer: %s|r", 
                ConfigData.COLORS.WHITE, formattedTime))
        end
    end

    -- Add gear and crest information
    tooltip:AddLine(string.format("%sGear: %s (%s) / Vault: %s (%s)|r",
        ConfigData.COLORS.WHITE, rewards.dungeonTrack, rewards.dungeonItem,
        rewards.vaultTrack, rewards.vaultItem))
    tooltip:AddLine(string.format("%sCrest: %s (%s)|r", 
        ConfigData.COLORS.WHITE, crest.crestType, tostring(crest.crestAmount)))

    -- Add score information with timing consideration
    local scoreLine, gainString = "", ""
    
    if MRM_SavedVars.SHOW_TIMING then
        local maxScore = potentialScore + 15  -- +15 bonus for perfect timing
        scoreLine = string.format("%sScore: %s%d|r - %s%d|r", 
            ConfigData.COLORS.WHITE, baseColor, potentialScore, baseColor, maxScore)
            
        local minGain = playerGain
        local maxGain = math.max(maxScore - currentScore, 0)
        if maxGain > 0 then
            gainString = string.format(" %s(+%d-%d)|r", gainColor, minGain, maxGain)
        end
    else
        scoreLine = string.format("%sScore: %s%d|r", 
            ConfigData.COLORS.WHITE, baseColor, potentialScore)
            
        if playerGain > 0 then
            gainString = string.format(" %s(+%d)|r", gainColor, playerGain)
        end
    end
    
    tooltip:AddLine(scoreLine .. gainString)

    -- Add group information if in a group (but not raid)
    if IsInGroup() and GetNumGroupMembers() > 1 and not IsInRaid() then
        local isShiftPressed = IsShiftKeyDown()
        
        if isShiftPressed then
            -- Show detailed individual player scores when shift is held
            tooltip:AddLine(string.format("%sGroup Details:|r", ConfigData.COLORS.WHITE))
            
            -- Sort players by gain (highest first) for better readability
            local sortedPlayers = {}
            for playerName, playerScore in pairs(groupScoreData) do
                local individualGain = math.max(potentialScore - playerScore, 0)
                local individualGainColor = ColorUtils.calculateGradientColor(individualGain, 0, 200, GRADIENTS)
                table.insert(sortedPlayers, {
                    name = playerName,
                    score = playerScore,
                    gain = individualGain,
                    gainColor = individualGainColor
                })
            end
            
            table.sort(sortedPlayers, function(a, b) return a.gain > b.gain end)
            
            for _, player in ipairs(sortedPlayers) do
                if player.gain > 0 then
                    tooltip:AddLine(string.format("  %s: %s+%d|r", 
                        player.name, player.gainColor, player.gain))
                else
                    tooltip:AddLine(string.format("  %s: %sNo gain|r", 
                        player.name, ConfigData.COLORS.GRAY))
                end
            end
        else
            -- Show group average gain when shift is not held
            tooltip:AddLine(string.format("%sGroup Avg Gain: %s+%.1f|r %s(Hold Shift for details)|r", 
                ConfigData.COLORS.WHITE, groupColor, averageGroupGain, ConfigData.COLORS.GRAY))
        end
    end
end

--- Tooltip hook handler for keystone items
--- Enhances tooltips with reward information and processes display settings
--- @param tooltip table The GameTooltip object being processed
local function handleKeystoneTooltip(tooltip)
    -- Only proceed if the tooltip supports GetItem (excludes ShoppingTooltips)
    if not tooltip.GetItem then 
        return 
    end
    
    local name, link = tooltip:GetItem()
    if not link then 
        return 
    end
    
    -- Process all keystone links found in the tooltip
    for keystoneLink in link:gmatch("|Hkeystone:.-|h.-|h|r") do
        local keystoneData = KeystoneUtils.parseKeystoneData(keystoneLink)
        if keystoneData then
            enhanceTooltipWithRewardInfo(tooltip, keystoneData.itemString, keystoneData.level, keystoneData.mapID)
            processKeystoneTooltip(tooltip)
        end
    end
end

--- Chat hyperlink hook handler for keystone links
--- Adds reward information to keystone links clicked in chat
--- @param self table The chat frame object
--- @param hyperlink string The clicked hyperlink
local function handleKeystoneChatHyperlink(self, hyperlink)
    local keystoneData = KeystoneUtils.parseKeystoneData(hyperlink)
    if not keystoneData then 
        return 
    end
    
    ItemRefTooltip:AddLine(" ")
    enhanceTooltipWithRewardInfo(ItemRefTooltip, keystoneData.itemString, keystoneData.level, keystoneData.mapID)
    ItemRefTooltip:Show()
end

-- Register tooltip and chat hooks
hooksecurefunc("ChatFrame_OnHyperlinkShow", handleKeystoneChatHyperlink)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, handleKeystoneTooltip)

-- Register slash command handler
SLASH_MRMYTHICAL1 = "/mrm"
SlashCmdList["MRMYTHICAL"] = CommandHandlers.processSlashCommand

--- Event handler for addon initialization and mythic+ completion tracking
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MrMythical" then
            -- Initialize addon settings and completion tracker
            Options.initializeSettings()
            CompletionTracker:initialize()
            
            -- Determine player's region for RaiderIO integration
            if GetCurrentRegion then
                local regionNumber = GetCurrentRegion()
                currentPlayerRegion = ConfigData.REGION_MAP[regionNumber]
            end
        end
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        -- Track mythic+ completion when challenge mode finishes
        local challengeInfo = C_ChallengeMode.GetChallengeCompletionInfo()
        if challengeInfo then
            CompletionTracker:trackRun(
                challengeInfo.mapChallengeModeID,
                challengeInfo.onTime,
                challengeInfo.level
            )
        end
    end
end)

-- Export the main addon object to global scope
_G.MrMythical = MrMythical
