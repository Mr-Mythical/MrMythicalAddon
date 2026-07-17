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

--- Writes a formatted debug message when debug mode is enabled.
--- @param message string Format string.
--- @param ... any Arguments for string.format.
local function debugLog(message, ...)
    if MrMythicalDebug then
        local formattedMessage = string.format("[MrMythical Debug] " .. message, ...)
        print(formattedMessage)
    end
end

MrMythical.debugLog = debugLog

--- Builds the visible keystone tooltip title.
--- Applies level formatting and short-name preferences from saved settings.
--- @param mapID number|nil Dungeon map ID.
--- @param keyLevel number|nil Keystone level.
--- @param resilientLevel number|nil Resilient level (custom mode support).
--- @return string|nil newTitle Formatted title or nil when no dungeon name is available.
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

--- Extracts level values from raw tooltip data lines.
--- @param lines table[]|nil Tooltip data line entries.
--- @return number|nil keyLevel
--- @return number|nil resilientLevel
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

--- Mutates tooltip data lines to apply title/line visibility formatting.
--- This function runs in TooltipDataProcessor pre-call and only updates text fields.
--- @param data table Tooltip data object containing a lines array.
--- @param mapID number Dungeon map ID.
--- @param keyLevel number|nil Keystone level when already parsed from item link.
--- @param resilientLevel number|nil Optional resilient level.
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

--- Adds timer information lines to the tooltip based on timer display settings.
--- @param tooltip GameTooltip Tooltip instance.
--- @param mapID number Dungeon map ID.
local function addTimerToTooltip(tooltip, mapID)
    local timerMode = MRM_SavedVars.TIMER_DISPLAY_MODE or "NONE"
    if timerMode == "NONE" or not DungeonData then
        return
    end

    local parTime = DungeonData.getParTime(mapID)
    if not parTime then
        return
    end

    local timesText
    if timerMode == "DUNGEON" then
        timesText = DungeonData.formatTime(parTime)
    elseif timerMode == "UPGRADE" or (timerMode == "SHIFT" and IsShiftKeyDown()) then
        local timer1 = DungeonData.formatTime(parTime)
        local timer2 = DungeonData.formatTime(math.floor(parTime * 0.8))
        local timer3 = DungeonData.formatTime(math.floor(parTime * 0.6))
        timesText = string.format("%s/%s/%s", timer1, timer2, timer3)
    else
        return
    end

    local labelStyle = MRM_SavedVars.TIMER_LABEL_STYLE or "FULL"
    local lineText
    if labelStyle == "TIMES_ONLY" then
        lineText = string.format("%s%s|r", ConfigData.COLORS.WHITE, timesText)
    elseif labelStyle == "SHORT" then
        lineText = string.format("%sTimer: %s|r", ConfigData.COLORS.WHITE, timesText)
    else
        lineText = string.format("%sDungeon Timer: %s|r", ConfigData.COLORS.WHITE, timesText)
    end

    tooltip:AddLine(lineText)
end

--- Returns whether a Hide/Show/Shift display setting should render.
--- @param displayMode string Display mode value.
--- @param isShiftPressed boolean Whether Shift is currently held.
--- @return boolean
local function shouldShowDisplayMode(displayMode, isShiftPressed)
    return displayMode == "SHOW" or (displayMode == "SHIFT" and isShiftPressed)
end

--- Formats a reward segment with optional numeric value.
--- @param label string Display label.
--- @param trackOrType string Track name or crest type.
--- @param numberValue string|number|nil Optional numeric value.
--- @param hideNumbers boolean Whether to omit numbers.
--- @return string
local function formatRewardSegment(label, trackOrType, numberValue, hideNumbers)
    if hideNumbers or numberValue == nil then
        return string.format("%s: %s", label, trackOrType)
    end
    return string.format("%s: %s (%s)", label, trackOrType, tostring(numberValue))
end

--- Adds reward and crest information for a given keystone level.
--- Respects master REWARDS_DISPLAY plus per-type gear/vault/crest settings.
--- @param tooltip GameTooltip Tooltip instance.
--- @param keyLevel number Keystone level.
--- @param isShiftPressed boolean Whether Shift is currently held.
local function addRewardsToTooltip(tooltip, keyLevel, isShiftPressed)
    local rewardsDisplay = MRM_SavedVars.REWARDS_DISPLAY or "SHOW"
    if not shouldShowDisplayMode(rewardsDisplay, isShiftPressed) then
        return
    end

    local showGear = shouldShowDisplayMode(MRM_SavedVars.GEAR_REWARD_DISPLAY or "SHOW", isShiftPressed)
    local showVault = shouldShowDisplayMode(MRM_SavedVars.VAULT_REWARD_DISPLAY or "SHOW", isShiftPressed)
    local showCrest = shouldShowDisplayMode(MRM_SavedVars.CREST_REWARD_DISPLAY or "SHOW", isShiftPressed)

    if not (showGear or showVault or showCrest) then
        return
    end

    local rewards = RewardsFunctions.getRewardsForKeyLevel(keyLevel)
    local crest = RewardsFunctions.getCrestReward(keyLevel)
    local hideNumbers = MRM_SavedVars.HIDE_REWARD_NUMBERS
    local lineStyle = MRM_SavedVars.REWARD_LINE_STYLE or "TWO_LINES"
    local compact = lineStyle == "COMPACT"

    local gearLabel = compact and "G" or "Gear"
    local vaultLabel = compact and "V" or "Vault"
    local crestLabel = compact and "C" or "Crest"

    local gearText = showGear and formatRewardSegment(gearLabel, rewards.dungeonTrack, rewards.dungeonItem, hideNumbers) or nil
    local vaultText = showVault and formatRewardSegment(vaultLabel, rewards.vaultTrack, rewards.vaultItem, hideNumbers) or nil
    local crestText = showCrest and formatRewardSegment(crestLabel, crest.crestType, crest.crestAmount, hideNumbers) or nil

    if lineStyle == "TWO_LINES" then
        local gearVaultParts = {}
        if gearText then
            table.insert(gearVaultParts, gearText)
        end
        if vaultText then
            table.insert(gearVaultParts, vaultText)
        end

        if #gearVaultParts > 0 then
            tooltip:AddLine(string.format("%s%s|r", ConfigData.COLORS.WHITE, table.concat(gearVaultParts, " / ")))
        end
        if crestText then
            tooltip:AddLine(string.format("%s%s|r", ConfigData.COLORS.WHITE, crestText))
        end
    else
        -- SINGLE_LINE and COMPACT both join all visible parts on one line
        local parts = {}
        if gearText then
            table.insert(parts, gearText)
        end
        if vaultText then
            table.insert(parts, vaultText)
        end
        if crestText then
            table.insert(parts, crestText)
        end
        if #parts > 0 then
            tooltip:AddLine(string.format("%s%s|r", ConfigData.COLORS.WHITE, table.concat(parts, " / ")))
        end
    end
end

--- Adds the current character personal-best line for this keystone.
--- @param tooltip GameTooltip Tooltip instance.
--- @param itemString string Keystone item string used for lookups.
--- @param currentScore number Current character mythic score.
--- @param isShiftPressed boolean Whether Shift is currently held.
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

--- Adds group-wide score gain details for party members.
--- Shows summary by default and detailed per-player rows when Shift is held.
--- @param tooltip GameTooltip Tooltip instance.
--- @param groupScoreData table<string, number> Player name to score map.
--- @param potentialScore number Score for completing this key.
--- @param averageGroupGain number Average potential gain across the group.
--- @param groupColor string Color code used for average gain.
--- @param isShiftPressed boolean Whether Shift is currently held.
local function addGroupDetailsToTooltip(tooltip, groupScoreData, potentialScore, averageGroupGain, groupColor, isShiftPressed)
    if not (IsInGroup() and GetNumGroupMembers() > 1 and not IsInRaid()) then
        return
    end

    local groupScoreDisplay = MRM_SavedVars.GROUP_SCORE_DISPLAY or "SHIFT_DETAILS"
    if groupScoreDisplay == "HIDE" then
        return
    end

    if groupScoreDisplay == "SHIFT_DETAILS" and isShiftPressed then
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
        local shiftHint = ""
        if groupScoreDisplay == "SHIFT_DETAILS" then
            shiftHint = string.format(" %s(Hold Shift for details)|r", ConfigData.COLORS.GRAY)
        end

        tooltip:AddLine(string.format(
            "%sGroup Avg Gain: %s+%.1f|r%s",
            ConfigData.COLORS.WHITE,
            groupColor,
            averageGroupGain,
            shiftHint
        ))
    end
end

--- Composes all reward/scoring lines appended to keystone tooltips.
--- @param tooltip GameTooltip Tooltip instance.
--- @param itemString string Keystone item string.
--- @param keyLevel number Keystone level.
--- @param mapID number Dungeon map ID.
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

    local scoreDisplay = MRM_SavedVars.SCORE_DISPLAY or "SHOW"
    local shouldShowScore = scoreDisplay == "SHOW"
        or (scoreDisplay == "SHIFT" and isShiftPressed)

    if shouldShowScore then
        local scoreLine = ""
        local gainString = ""
        local showScoreGain = MRM_SavedVars.SHOW_SCORE_GAIN ~= false

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
            if showScoreGain and maxGain > 0 then
                gainString = string.format(" %s(+%d-%d)|r", gainColor, minGain, maxGain)
            end
        else
            scoreLine = string.format(
                "%sScore: %s%d|r",
                ConfigData.COLORS.WHITE,
                baseColor,
                potentialScore
            )

            if showScoreGain and playerGain > 0 then
                gainString = string.format(" %s(+%d)|r", gainColor, playerGain)
            end
        end

        tooltip:AddLine(scoreLine .. gainString)
    end

    addGroupDetailsToTooltip(
        tooltip,
        groupScoreData,
        potentialScore,
        averageGroupGain,
        groupColor,
        isShiftPressed
    )
end

--- Cache of parsed keystones by tooltip frame.
--- Used to share data between tooltip pre/post callbacks.
local tooltipKeystoneCache = {}

--- Tooltip pre-call handler.
--- Parses keystone links and updates base tooltip data lines.
--- @param tooltip GameTooltip Tooltip instance.
--- @param data table Tooltip data object from TooltipDataProcessor.
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

--- Tooltip post-call handler.
--- Appends reward/score lines after the base tooltip content exists.
--- @param tooltip GameTooltip Tooltip instance.
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

--- Chat hyperlink handler for keystone links in ItemRefTooltip.
--- @param link string Hyperlink string passed by SetItemRef.
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

--- Main event dispatcher for addon lifecycle and challenge mode tracking
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