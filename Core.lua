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

local function debugLog(message, ...)
    if MrMythicalDebug then
        local formattedMessage = string.format("[MrMythical Debug] " .. message, ...)
        print(formattedMessage)
    end
end

MrMythical.debugLog = debugLog

local function buildTooltipTitle(mapID, keyLevel, resilientLevel)
    local fullName = mapID and DungeonData.getDungeonName(mapID) or nil
    if not fullName then
        return nil
    end

    local isShiftPressed = IsShiftKeyDown()
    local levelDisplayMode = MRM_SavedVars.LEVEL_DISPLAY or "OFF"
    local newTitle = "Keystone: " .. fullName

    if levelDisplayMode == "TITLE" then
        newTitle = TooltipUtils.processLevelInTitle(newTitle, keyLevel, resilientLevel, isShiftPressed)
    elseif MRM_SavedVars.SHORT_TITLE and string.find(newTitle, "^Keystone: ") then
        newTitle = string.gsub(newTitle, "^Keystone: ", "")
    end

    local dungeonNameMode = MRM_SavedVars.SHORT_DUNGEON_NAMES or "OFF"
    if dungeonNameMode ~= "OFF" then
        local shortName = DungeonData.getShortDungeonName(mapID)
        if shortName then
            local startPos, endPos = string.find(newTitle, fullName, 1, true)
            if startPos then
                local replacement = dungeonNameMode == "SHORT_FULL"
                    and (shortName .. " - " .. fullName)
                    or shortName

                newTitle = string.sub(newTitle, 1, startPos - 1)
                    .. replacement
                    .. string.sub(newTitle, endPos + 1)
            end
        end
    end

    return newTitle
end

local function extractLevelsFromTooltipDataLines(lines)
    local keyLevel, resilientLevel

    if not lines then
        return nil, nil
    end

    for _, line in ipairs(lines) do
        local text = line and line.leftText
        if text then
            if not keyLevel then
                local matchedKeyLevel = string.match(text, "Mythic Level (%d+)")
                if matchedKeyLevel then
                    keyLevel = tonumber(matchedKeyLevel)
                end
            end

            if not resilientLevel then
                local matchedResilientLevel = string.match(text, "Resilient Level (%d+)")
                if matchedResilientLevel then
                    resilientLevel = tonumber(matchedResilientLevel)
                end
            end
        end

        if keyLevel and resilientLevel then
            break
        end
    end

    return keyLevel, resilientLevel
end

local function processKeystoneTooltipData(data, mapID, keyLevel, resilientLevel)
    if not data or not data.lines then
        return
    end

    local isShiftPressed = IsShiftKeyDown()
    local levelDisplayMode = MRM_SavedVars.LEVEL_DISPLAY or "OFF"

    if levelDisplayMode == "TITLE" and not keyLevel then
        keyLevel, resilientLevel = extractLevelsFromTooltipDataLines(data.lines)
    end

    local newTitle = buildTooltipTitle(mapID, keyLevel, resilientLevel)

    for index, line in ipairs(data.lines) do
        local leftText = line and line.leftText

        if leftText and leftText ~= "" then
            if index == 1 and newTitle then
                line.leftText = newTitle
            elseif index >= 2 then
                if levelDisplayMode == "COMPACT" then
                    local leftColor = line.leftColor or {}
                    local processed = TooltipUtils.processCompactLevelDisplay(
                        leftText,
                        isShiftPressed,
                        {
                            leftColor.r or 1,
                            leftColor.g or 1,
                            leftColor.b or 1,
                        }
                    )

                    if processed == nil then
                        line.leftText = ""
                        line.rightText = nil
                    elseif processed ~= leftText then
                        line.leftText = processed
                        line.rightText = nil
                    end
                else
                    local shouldHide =
                        TooltipUtils.shouldHideLevelLine(leftText, levelDisplayMode, isShiftPressed)
                        or TooltipUtils.shouldHideTooltipText(leftText)

                    if shouldHide then
                        line.leftText = ""
                        line.rightText = nil
                    end
                end
            end
        end
    end
end

local function addTimerToTooltip(tooltip, mapID)
    local timerMode = MRM_SavedVars.TIMER_DISPLAY_MODE or "NONE"
    if not DungeonData then
        return
    end

    local parTime = DungeonData.getParTime(mapID)
    if not parTime then
        return
    end

    if timerMode == "DUNGEON" then
        local formattedTime = DungeonData.formatTime(parTime)
        tooltip:AddLine(string.format("%sDungeon Timer: %s|r", ConfigData.COLORS.WHITE, formattedTime))
    elseif timerMode == "UPGRADE" or (timerMode == "SHIFT" and IsShiftKeyDown()) then
        local timer1 = DungeonData.formatTime(parTime)
        local timer2 = DungeonData.formatTime(math.floor(parTime * 0.8))
        local timer3 = DungeonData.formatTime(math.floor(parTime * 0.6))
        tooltip:AddLine(string.format("%sDungeon Timer: %s/%s/%s|r", ConfigData.COLORS.WHITE, timer1, timer2, timer3))
    end
end

local function addPersonalBestToTooltip(tooltip, itemString, currentScore, isShiftPressed)
    local playerBestDisplay = MRM_SavedVars.PLAYER_BEST_DISPLAY or "WITH_SCORE"
    local shouldShow = playerBestDisplay == "WITH_SCORE"
        or playerBestDisplay == "WITHOUT_SCORE"
        or (playerBestDisplay == "SHIFT_WITH_SCORE" and isShiftPressed)

    if not shouldShow then
        return
    end

    local bestRun = MrMythical.DungeonData.getCharacterBestRun(itemString)
    if bestRun then
        local timeColor = bestRun.wasInTime and ConfigData.COLORS.GREEN or ConfigData.COLORS.YELLOW
        local formattedTime = DungeonData and DungeonData.formatTime and DungeonData.formatTime(bestRun.bestTime) or "Unknown"
        local pluses = string.rep("+", bestRun.upgrade or 0)
        local levelText = "Level " .. pluses .. bestRun.bestLevel

        if playerBestDisplay == "WITH_SCORE" or playerBestDisplay == "SHIFT_WITH_SCORE" then
            local personalBestColor = ColorUtils.calculateGradientColor(currentScore, 165, 500, GRADIENTS)
            tooltip:AddLine(string.format(
                "%sPersonal Best: %s (%s%s|r) - Score: %s%d|r",
                ConfigData.COLORS.WHITE,
                levelText,
                timeColor,
                formattedTime,
                personalBestColor,
                currentScore
            ))
        else
            tooltip:AddLine(string.format(
                "%sPersonal Best: %s (%s%s|r)|r",
                ConfigData.COLORS.WHITE,
                levelText,
                timeColor,
                formattedTime
            ))
        end
    else
        tooltip:AddLine(string.format(
            "%sPersonal Best: %sNo data|r",
            ConfigData.COLORS.WHITE,
            ConfigData.COLORS.GRAY
        ))
    end
end

local function addRewardsToTooltip(tooltip, keyLevel, isShiftPressed)
    local rewardsDisplay = MRM_SavedVars.REWARDS_DISPLAY or "SHOW"
    local shouldShow = rewardsDisplay == "SHOW" or (rewardsDisplay == "SHIFT" and isShiftPressed)

    if not shouldShow then
        return
    end

    local rewards = RewardsFunctions.getRewardsForKeyLevel(keyLevel)
    local crest = RewardsFunctions.getCrestReward(keyLevel)
    tooltip:AddLine(string.format(
        "%sGear: %s (%s) / Vault: %s (%s)|r",
        ConfigData.COLORS.WHITE,
        rewards.dungeonTrack,
        rewards.dungeonItem,
        rewards.vaultTrack,
        rewards.vaultItem
    ))
    tooltip:AddLine(string.format(
        "%sCrest: %s (%s)|r",
        ConfigData.COLORS.WHITE,
        crest.crestType,
        tostring(crest.crestAmount)
    ))
end

local function addGroupDetailsToTooltip(tooltip, groupScoreData, potentialScore, averageGroupGain, groupColor, isShiftPressed)
    if not (IsInGroup() and GetNumGroupMembers() > 1 and not IsInRaid()) then
        return
    end

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
                gainColor = individualGainColor,
            })
        end

        table.sort(sortedPlayers, function(a, b)
            return a.gain > b.gain
        end)

        for _, player in ipairs(sortedPlayers) do
            if player.gain > 0 then
                tooltip:AddLine(string.format(
                    "  %s: %s+%d|r",
                    player.name,
                    player.gainColor,
                    player.gain
                ))
            else
                tooltip:AddLine(string.format(
                    "  %s: %sNo gain|r",
                    player.name,
                    ConfigData.COLORS.GRAY
                ))
            end
        end
    else
        tooltip:AddLine(string.format(
            "%sGroup Avg Gain: %s+%.1f|r %s(Hold Shift for details)|r",
            ConfigData.COLORS.WHITE,
            groupColor,
            averageGroupGain,
            ConfigData.COLORS.GRAY
        ))
    end
end

local function enhanceTooltipWithRewardInfo(tooltip, itemString, keyLevel, mapID)
    debugLog("Enhancing tooltip with reward info: level=%d, mapID=%d", keyLevel, mapID)

    local currentScore = MrMythical.DungeonData.getCharacterMythicScore(itemString)
    local groupScoreData = MrMythical.DungeonData.getGroupMythicDataParty(currentScore, mapID)

    local totalPotentialGain, playerCount = 0, 0
    local potentialScore = RewardsFunctions.scoreFormula(keyLevel)

    for _, playerScore in pairs(groupScoreData) do
        local playerGainForGroup = math.max(potentialScore - playerScore, 0)
        totalPotentialGain = totalPotentialGain + playerGainForGroup
        playerCount = playerCount + 1
    end

    local averageGroupGain = (playerCount > 0) and (totalPotentialGain / playerCount) or 0
    local groupColor = ColorUtils.calculateGradientColor(averageGroupGain, 0, 200, GRADIENTS)
    local baseColor = ColorUtils.calculateGradientColor(potentialScore, 165, 500, GRADIENTS)
    local playerGain = math.max(potentialScore - currentScore, 0)
    local gainColor = ColorUtils.calculateGradientColor(playerGain, 0, 200, GRADIENTS)
    local isShiftPressed = IsShiftKeyDown()

    addTimerToTooltip(tooltip, mapID)
    addPersonalBestToTooltip(tooltip, itemString, currentScore, isShiftPressed)
    addRewardsToTooltip(tooltip, keyLevel, isShiftPressed)

    local scoreLine = ""
    local gainString = ""

    if MRM_SavedVars.SHOW_TIMING then
        local maxScore = potentialScore + 15
        scoreLine = string.format(
            "%sScore: %s%d|r - %s%d|r",
            ConfigData.COLORS.WHITE,
            baseColor,
            potentialScore,
            baseColor,
            maxScore
        )

        local minGain = playerGain
        local maxGain = math.max(maxScore - currentScore, 0)
        if maxGain > 0 then
            gainString = string.format(" %s(+%d-%d)|r", gainColor, minGain, maxGain)
        end
    else
        scoreLine = string.format(
            "%sScore: %s%d|r",
            ConfigData.COLORS.WHITE,
            baseColor,
            potentialScore
        )

        if playerGain > 0 then
            gainString = string.format(" %s(+%d)|r", gainColor, playerGain)
        end
    end

    tooltip:AddLine(scoreLine .. gainString)

    addGroupDetailsToTooltip(
        tooltip,
        groupScoreData,
        potentialScore,
        averageGroupGain,
        groupColor,
        isShiftPressed
    )
end

local tooltipKeystoneCache = {}

local function handleKeystoneTooltip(tooltip, data)
    if not data then
        return
    end

    local link
    if tooltip and tooltip.GetItem then
        pcall(function()
            local _
            _, link = tooltip:GetItem()
        end)
    end

    local pendingKeys = {}
    local parsedOk = false

    if type(link) == "string" then
        for keystoneLink in string.gmatch(link, "|Hkeystone:.-|h.-|h|r") do
            local parsed = KeystoneUtils.parseKeystoneData(keystoneLink)
            if parsed then
                table.insert(pendingKeys, parsed)
                parsedOk = true
            end
        end
    end

    if parsedOk then
        tooltipKeystoneCache[tooltip] = pendingKeys
    elseif tooltipKeystoneCache[tooltip] then
        pendingKeys = tooltipKeystoneCache[tooltip]
    end

    for _, keystoneData in ipairs(pendingKeys) do
        processKeystoneTooltipData( data, keystoneData.mapID, keystoneData.level, nil )
    end
end

local function appendKeystoneRewardInfo(tooltip)
    if not tooltip or not tooltip.GetItem then
        return
    end

    local pendingKeys = tooltipKeystoneCache[tooltip]
    if not pendingKeys then
        return
    end

    for _, keystoneData in ipairs(pendingKeys) do
        enhanceTooltipWithRewardInfo(tooltip, keystoneData.itemString, keystoneData.level, keystoneData.mapID)
    end
end

local function handleKeystoneChatHyperlink(link)
    local keystoneData = KeystoneUtils.parseKeystoneData(link)
    if not keystoneData then
        return
    end

    ItemRefTooltip:AddLine(" ")
    enhanceTooltipWithRewardInfo(
        ItemRefTooltip,
        keystoneData.itemString,
        keystoneData.level,
        keystoneData.mapID
    )
    ItemRefTooltip:Show()
end

hooksecurefunc("SetItemRef", handleKeystoneChatHyperlink)

TooltipDataProcessor.AddTooltipPreCall(Enum.TooltipDataType.Item, handleKeystoneTooltip)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, appendKeystoneRewardInfo)

GameTooltip:HookScript("OnHide", function(self)
    tooltipKeystoneCache[self] = nil
end)

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

        if mapID and level and MrMythical.CompletionTracker then
            MrMythical.CompletionTracker:trackRunStart(mapID, level)
        end
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        local completionInfo = C_ChallengeMode.GetChallengeCompletionInfo()

        if completionInfo and MrMythical.CompletionTracker then
            MrMythical.CompletionTracker:trackRun(completionInfo)
        end
    end
end)

_G.MrMythical = MrMythical