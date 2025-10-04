--[[
Core.lua - Mr. Mythical Main Addon Core Logic

Purpose: Main functionality for Mythic+ keystone tooltips and scoring
Dependencies: All Data and Utils modules
Author: Braunerr
--]]

local MrMythical = MrMythical or {}

MrMythicalDebug = false

local GradientsData = MrMythical.GradientsData
local ConfigData = MrMythical.ConfigData
local DungeonData = MrMythical.DungeonData

local ColorUtils = MrMythical.ColorUtils
local KeystoneUtils = MrMythical.KeystoneUtils
local TooltipUtils = MrMythical.TooltipUtils
local CommandHandlers = MrMythical.CommandHandlers
local RewardsFunctions = MrMythical.RewardsFunctions

local Options = MrMythical.Options

local GRADIENTS = GradientsData.GRADIENTS

--- Debug logging function for development
--- @param message string The debug message to log
--- @param ... any Additional values to include in the debug output
local function debugLog(message, ...)
    if MrMythicalDebug then
        local formattedMessage = string.format("[MrMythical Debug] " .. message, ...)
        print(formattedMessage)
    end
end

--- Handles level display modes, text filtering, and title modifications
--- @param tooltip table The GameTooltip object to process
local function processKeystoneTooltip(tooltip)
    local isShiftPressed = IsShiftKeyDown()
    local processedLines = {}
    local firstLine = _G["GameTooltipTextLeft1"]
    local levelDisplayMode = MRM_SavedVars.LEVEL_DISPLAY or "OFF"
    
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

    for i = 2, tooltip:NumLines() do
        local leftLine = _G["GameTooltipTextLeft"..i]
        local rightLine = _G["GameTooltipTextRight"..i]
        
        if leftLine then
            local lineText = leftLine:GetText() or ""
            local red, green, blue = leftLine:GetTextColor()
            local lineColor = {red, green, blue}
            local shouldProcess = true
            
            if levelDisplayMode == "COMPACT" then
                lineText = TooltipUtils.processCompactLevelDisplay(lineText, isShiftPressed, lineColor)
            elseif TooltipUtils.shouldHideLevelLine(lineText, levelDisplayMode, isShiftPressed) then
                shouldProcess = false
            end
            
            if shouldProcess and lineText and not TooltipUtils.shouldHideTooltipText(lineText) then
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
    debugLog("Enhancing tooltip with reward info: level=%d, mapID=%d", keyLevel, mapID)
    
    local currentScore = MrMythical.DungeonData.getCharacterMythicScore(itemString)
    local groupScoreData = MrMythical.DungeonData.getGroupMythicDataParty(currentScore, mapID)
    
    local totalPotentialGain, playerCount = 0, 0
    local potentialScore = RewardsFunctions.scoreFormula(keyLevel)
    
    for _, playerScore in pairs(groupScoreData) do
        local playerGain = math.max(potentialScore - playerScore, 0)
        totalPotentialGain = totalPotentialGain + playerGain
        playerCount = playerCount + 1
    end
    
    local averageGroupGain = (playerCount > 0) and (totalPotentialGain / playerCount) or 0
    
    local groupColor = ColorUtils.calculateGradientColor(averageGroupGain, 0, 200, GRADIENTS)
    local baseColor = ColorUtils.calculateGradientColor(potentialScore, 165, 500, GRADIENTS)
    local playerGain = math.max(potentialScore - currentScore, 0)
    local gainColor = ColorUtils.calculateGradientColor(playerGain, 0, 200, GRADIENTS)
    
    local rewards = RewardsFunctions.getRewardsForKeyLevel(keyLevel)
    local crest = RewardsFunctions.getCrestReward(keyLevel)


    local timerMode = MRM_SavedVars.TIMER_DISPLAY_MODE or "NONE"
    if DungeonData then
        local parTime = DungeonData.getParTime(mapID)
        if parTime then
            if timerMode == "DUNGEON" then
                local formattedTime = DungeonData.formatTime(parTime)
                tooltip:AddLine(string.format("%sDungeon Timer: %s|r", ConfigData.COLORS.WHITE, formattedTime))
            elseif timerMode == "UPGRADE" then
                local timer1 = DungeonData.formatTime(parTime)
                local timer2 = DungeonData.formatTime(math.floor(parTime * 0.8))
                local timer3 = DungeonData.formatTime(math.floor(parTime * 0.6))
                tooltip:AddLine(string.format("%sDungeon Timer: %s/%s/%s|r", ConfigData.COLORS.WHITE, timer1, timer2, timer3))
            elseif timerMode == "SHIFT" then
                if IsShiftKeyDown() then
                    local timer1 = DungeonData.formatTime(parTime)
                    local timer2 = DungeonData.formatTime(math.floor(parTime * 0.8))
                    local timer3 = DungeonData.formatTime(math.floor(parTime * 0.6))
                    tooltip:AddLine(string.format("%sDungeon Timer: %s/%s/%s|r", ConfigData.COLORS.WHITE, timer1, timer2, timer3))
                end
            end
        end
    end

    if MRM_SavedVars.SHOW_PLAYER_BEST then
        local bestRun = MrMythical.DungeonData.getCharacterBestRun(itemString)
        if bestRun then
            local timeColor = bestRun.wasInTime and ConfigData.COLORS.GREEN or ConfigData.COLORS.YELLOW
            local formattedTime = DungeonData and DungeonData.formatTime and DungeonData.formatTime(bestRun.bestTime) or "Unknown"
            local timeStatus = bestRun.wasInTime and "In Time" or "Overtime"
            
            local personalBestColor = ColorUtils.calculateGradientColor(currentScore, 165, 500, GRADIENTS)
            
            local pluses = string.rep("+", bestRun.upgrade or 0)
            local levelText = "Level " .. pluses .. bestRun.bestLevel
            
            tooltip:AddLine(string.format("%sPersonal Best: %s (%s%s|r - %s) - Score: %s%d|r", 
                ConfigData.COLORS.WHITE, levelText, timeColor, formattedTime, timeStatus,
                personalBestColor, currentScore))
        else
            tooltip:AddLine(string.format("%sPersonal Best: %sNo data|r", 
                ConfigData.COLORS.WHITE, ConfigData.COLORS.GRAY))
        end
    end

    tooltip:AddLine(string.format("%sGear: %s (%s) / Vault: %s (%s)|r",
        ConfigData.COLORS.WHITE, rewards.dungeonTrack, rewards.dungeonItem,
        rewards.vaultTrack, rewards.vaultItem))
    tooltip:AddLine(string.format("%sCrest: %s (%s)|r", 
        ConfigData.COLORS.WHITE, crest.crestType, tostring(crest.crestAmount)))

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

    if IsInGroup() and GetNumGroupMembers() > 1 and not IsInRaid() then
        local isShiftPressed = IsShiftKeyDown()
        
        if isShiftPressed then
            tooltip:AddLine(string.format("%sGroup Details:|r", ConfigData.COLORS.WHITE))
            
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
            tooltip:AddLine(string.format("%sGroup Avg Gain: %s+%.1f|r %s(Hold Shift for details)|r", 
                ConfigData.COLORS.WHITE, groupColor, averageGroupGain, ConfigData.COLORS.GRAY))
        end
    end
end

--- Tooltip hook handler for keystone items
--- Enhances tooltips with reward information and processes display settings
--- @param tooltip table The GameTooltip object being processed
local function handleKeystoneTooltip(tooltip)
    if not tooltip.GetItem then 
        return 
    end
    
    local name, link = tooltip:GetItem()
    if not link then 
        return
    end
    
    for keystoneLink in link:gmatch("|Hkeystone:.-|h.-|h|r") do
        local keystoneData = KeystoneUtils.parseKeystoneData(keystoneLink)
        if keystoneData then
            debugLog("Enhancing tooltip for keystone: level %d, map ID %d", keystoneData.level, keystoneData.mapID)
            enhanceTooltipWithRewardInfo(tooltip, keystoneData.itemString, keystoneData.level, keystoneData.mapID)
            processKeystoneTooltip(tooltip)
        else
            debugLog("Failed to parse keystone data from link: %s", keystoneLink)
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

hooksecurefunc("ChatFrame_OnHyperlinkShow", handleKeystoneChatHyperlink)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, handleKeystoneTooltip)

SLASH_MRMYTHICAL1 = "/mrm"
SlashCmdList["MRMYTHICAL"] = CommandHandlers.processSlashCommand

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")

local addonInitialized = false

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MrMythical" then
            debugLog("MrMythical addon loaded, initializing...")
            
            Options.initializeSettings()
            
            addonInitialized = true
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if addonInitialized then
            if DungeonData and DungeonData.refreshFromAPI then
                DungeonData.refreshFromAPI()
            end
            
            eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    elseif event == "CHALLENGE_MODE_MAPS_UPDATE" then
        if addonInitialized and DungeonData and DungeonData.refreshFromAPI then
            C_Timer.After(0.5, function()
                DungeonData.refreshFromAPI()
            end)
        end
    elseif event == "CHALLENGE_MODE_START" then
        local mapID = C_ChallengeMode.GetActiveChallengeMapID()
        local level = C_ChallengeMode.GetActiveKeystoneInfo()

        if mapID and level then
            if MrMythical.CompletionTracker then
                MrMythical.CompletionTracker:trackRunStart(mapID, level)
            end
        end
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        local mapChallengeModeID, level, time, onTime, keystoneUpgradeLevels, practiceRun, oldOverallDungeonScore, newOverallDungeonScore, IsMapRecord, IsAffixRecord, PrimaryAffix, isEligibleForScore, members = C_ChallengeMode.GetCompletionInfo()
        
        if mapChallengeModeID then
            local challengeInfo = {
                mapChallengeModeID = mapChallengeModeID,
                level = level,
                time = time,
                onTime = onTime,
                keystoneUpgradeLevels = keystoneUpgradeLevels,
                practiceRun = practiceRun,
                oldOverallDungeonScore = oldOverallDungeonScore,
                newOverallDungeonScore = newOverallDungeonScore,
                IsMapRecord = IsMapRecord,
                IsAffixRecord = IsAffixRecord,
                PrimaryAffix = PrimaryAffix,
                isEligibleForScore = isEligibleForScore,
                members = members
            }
            
            if MrMythical.CompletionTracker then
                MrMythical.CompletionTracker:trackRun(challengeInfo)
            end
        end
    end
end)

-- Export the main addon object to global scope
_G.MrMythical = MrMythical
