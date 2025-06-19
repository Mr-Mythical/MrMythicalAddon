local MrMythical = MrMythical or {}

local GradientsData = MrMythical.GradientsData
local RewardsFunctions = MrMythical.RewardsFunctions
local CompletionTracker = MrMythical.CompletionTracker
local Constants = MrMythical.Constants
local Options = MrMythical.Options

local GRADIENTS = GradientsData.GRADIENTS
local currentPlayerRegion = "us"

--- Interpolates between color stops to get a color code for a normalized value.
-- @param normalizedValue number between 0 and 1
-- @param stops table of color stops (each with .rgbInteger)
-- @return string WoW color code
local function getColorFromStops(normalizedValue, stops)
    normalizedValue = math.max(0, math.min(1, normalizedValue))
    local numStops = #stops
    local scaledIndex = normalizedValue * (numStops - 1) + 1
    local lowerIndex = math.floor(scaledIndex)
    local upperIndex = math.min(lowerIndex + 1, numStops)
    local t = scaledIndex - lowerIndex

    local lr, lg, lb = unpack(stops[lowerIndex].rgbInteger)
    local ur, ug, ub = unpack(stops[upperIndex].rgbInteger)
    local r = lr + (ur - lr) * t
    local g = lg + (ug - lg) * t
    local b = lb + (ub - lb) * t

    return string.format("|cff%02x%02x%02x", r, g, b)
end

--- Returns a color code for a value in a domain, using a gradient.
-- @param value number
-- @param domainMin number
-- @param domainMax number
-- @param stops table of color stops
-- @return string WoW color code
local function getGradientColor(value, domainMin, domainMax, stops)
    if MRM_SavedVars.PLAIN_SCORE_COLORS then
        return Constants.COLORS.WHITE
    end
    local ratio = (value - domainMin) / (domainMax - domainMin)
    ratio = 1 - ratio
    return getColorFromStops(ratio, stops)
end

--- Gets the dungeon score for a given RaiderIO profile and map.
-- @param profile table RaiderIO profile
-- @param targetMapID number
-- @return number score
local function getDungeonScoreFromProfile(profile, targetMapID)
    if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.sortedDungeons then
        for _, entry in ipairs(profile.mythicKeystoneProfile.sortedDungeons) do
            if entry.dungeon and entry.dungeon.keystone_instance == targetMapID then
                local level = entry.level or 0
                local chests = entry.chests or 0
                local baseScore = RewardsFunctions.scoreFormula(level)
                local chestBonus = 0
                if chests == 2 then
                    chestBonus = 7.5
                elseif chests >= 3 then
                    chestBonus = 15
                end
                return baseScore + chestBonus
            end
        end
    end
    if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.currentScore then
        local numDungeons = #profile.mythicKeystoneProfile.sortedDungeons
        if numDungeons > 0 then
            return profile.mythicKeystoneProfile.currentScore / numDungeons
        end
    end
    return 0
end

--- Returns a table of group member scores for a given dungeon.
-- @param playerScore number
-- @param targetMapID number
-- @return table mapping player names to scores
function MrMythical.getGroupMythicDataParty(playerScore, targetMapID)
    local groupData = {}
    local playerName = UnitName("player")
    groupData[playerName] = playerScore
    local region = currentPlayerRegion
    local numParty = GetNumGroupMembers() or 1
    for i = 1, numParty - 1 do
        local unitID = "party" .. i
        if UnitExists(unitID) then
            local name, realm = UnitName(unitID)
            realm = realm and realm ~= "" and realm or GetRealmName()
            if RaiderIO and RaiderIO.GetProfile then
                local pProfile = RaiderIO.GetProfile(name, realm, region)
                local dungeonScore = 0
                if pProfile and pProfile.mythicKeystoneProfile then
                    dungeonScore = getDungeonScoreFromProfile(pProfile, targetMapID)
                end
                groupData[name] = dungeonScore
            else
                groupData[name] = 0
            end
        end
    end
    return groupData
end

--- Extracts the item string from a keystone link.
local function getItemString(link)
    return string.match(link, "keystone[%-?%d:]+")
end

--- Extracts the keystone level from a keystone link.
local function getKeyLevel(link)
    local keyField = select(4, strsplit(":", link))
    return tonumber(string.sub(keyField or "", 1, 2))
end

--- Extracts the map ID from a keystone link.
local function getMapID(link)
    local parts = { strsplit(":", link) }
    if #parts >= 3 then
        return tonumber(parts[3])
    end
    return nil
end

--- Returns the player's best score for a given keystone item string.
-- @param itemString string
-- @return number
function MrMythical.getCharacterMythicScore(itemString)
    local mapID = getMapID(itemString)
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

--- Determines if a tooltip line should be hidden based on user settings.
-- @param text string
-- @return boolean
local function isUnwantedText(text)
    if not text then return false end
    for _, duration in ipairs(Constants.DURATION_STRINGS) do
        if text:find(duration, 1, true) then
            return MRM_SavedVars.HIDE_DURATION
        end
    end
    for _, affix in ipairs(Constants.AFFIX_STRINGS) do
        if text:find(affix, 1, true) then
            return MRM_SavedVars.HIDE_AFFIX_TEXT
        end
    end
    for _, unwanted in ipairs(Constants.UNWANTED_STRINGS) do
        if text:find(unwanted, 1, true) then
            return MRM_SavedVars.HIDE_UNWANTED_TEXT
        end
    end
    return false
end

--- Rebuilds the tooltip, removing or modifying lines based on settings.
-- Handles level display, unwanted text, and title shortening.
-- @param tooltip GameTooltip
local function removeSpecificTooltipText(tooltip)
    local isShiftKeyDown = IsShiftKeyDown()
    local validLines = {}
    local firstLine = _G["GameTooltipTextLeft1"]
    local levelDisplay = MRM_SavedVars.LEVEL_DISPLAY or "OFF"
    local shiftMode = MRM_SavedVars.LEVEL_SHIFT_MODE or "NONE"

    if firstLine then
        local text = firstLine:GetText()
        if text then
            if MRM_SavedVars.SHORT_TITLE and text:find("^Keystone: ") then
                text = text:gsub("^Keystone: ", "")
            end
            -- Handle level display in title
            if levelDisplay == "TITLE" then
                local keyLevel, resilientLevel
                for i = 2, tooltip:NumLines() do
                    local line = _G["GameTooltipTextLeft"..i]:GetText() or ""
                    local level = line:match("Mythic Level (%d+)")
                    local resilient = line:match("Resilient Level (%d+)")
                    if level then keyLevel = level end
                    if resilient then resilientLevel = resilient end
                end
                if keyLevel and (shiftMode ~= "SHOW_BOTH" or isShiftKeyDown) then
                    text = text .. " +" .. keyLevel
                    if resilientLevel and (shiftMode == "NONE" or 
                        (shiftMode == "SHOW_RESILIENT" and isShiftKeyDown) or 
                        (shiftMode == "SHOW_BOTH" and isShiftKeyDown)) then
                        text = text .. " (R" .. resilientLevel .. ")"
                    end
                end
            end
            firstLine:SetText(text)
        end
        table.insert(validLines, {
            left = text,
            right = _G["GameTooltipTextRight1"] and _G["GameTooltipTextRight1"]:GetText(),
            color = {firstLine:GetTextColor()}
        })
    end

    -- Process all other lines, hiding or modifying as needed
    for i = 2, tooltip:NumLines() do
        local leftLine = _G["GameTooltipTextLeft"..i]
        local rightLine = _G["GameTooltipTextRight"..i]
        if leftLine then
            local lineText = leftLine:GetText() or ""
            local r, g, b = leftLine:GetTextColor()
            -- Handle level display modes
            if levelDisplay == "COMPACT" then
                local level = lineText:match("Mythic Level (%d+)")
                local resilient = nil
                if level then
                    for j = i + 1, tooltip:NumLines() do
                        local nextLine = _G["GameTooltipTextLeft"..j]:GetText() or ""
                        resilient = nextLine:match("Resilient Level (%d+)")
                        if resilient then break end
                    end
                    if shiftMode == "SHOW_BOTH" and not isShiftKeyDown then
                        lineText = nil
                    else
                        local levelText = "+" .. level
                        if resilient and (shiftMode == "NONE" or 
                            (shiftMode == "SHOW_RESILIENT" and isShiftKeyDown) or 
                            (shiftMode == "SHOW_BOTH" and isShiftKeyDown)) then
                            levelText = levelText .. " (R" .. resilient .. ")"
                        end
                        lineText = string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, levelText)
                    end
                elseif lineText:match("Resilient Level") then
                    lineText = nil
                end
            elseif levelDisplay == "TITLE" then
                if lineText:match("Mythic Level") or lineText:match("Resilient Level") then
                    lineText = nil
                end
            elseif levelDisplay == "OFF" then
                local isMythicLevel = lineText:match("Mythic Level")
                local isResilientLevel = lineText:match("Resilient Level")
                if isMythicLevel then
                    if shiftMode == "SHOW_BOTH" and not isShiftKeyDown then
                        lineText = nil
                    end
                elseif isResilientLevel then
                    if shiftMode == "SHOW_BOTH" and not isShiftKeyDown then
                        lineText = nil
                    elseif shiftMode == "SHOW_RESILIENT" and not isShiftKeyDown then
                        lineText = nil
                    end
                end
            end
            if lineText and not isUnwantedText(lineText) then
                table.insert(validLines, {
                    left = lineText,
                    right = rightLine and rightLine:GetText(),
                    color = {r, g, b}
                })
            end
        end
    end

    tooltip:ClearLines()
    for i, line in ipairs(validLines) do
        if line.color then
            tooltip:AddLine(line.left, line.color[1], line.color[2], line.color[3])
            if line.right then
                local rightLine = _G["GameTooltipTextRight" .. i]
                if rightLine then
                    rightLine:SetText(line.right)
                end
            end
        end
    end
    tooltip:Show()
end

--- Adds reward and score info to the keystone tooltip.
-- @param tooltip GameTooltip
-- @param itemString string
-- @param keyLevel number
-- @param mapID number
local function addTooltipRewardInfo(tooltip, itemString, keyLevel, mapID)
    local currentScore = MrMythical.getCharacterMythicScore(itemString)
    local groupData = MrMythical.getGroupMythicDataParty(currentScore, mapID)
    local totalGain, count = 0, 0
    local potentialScore = RewardsFunctions.scoreFormula(keyLevel)
    for _, score in pairs(groupData) do
        local playerGain = math.max(potentialScore - score, 0)
        totalGain = totalGain + playerGain
        count = count + 1
    end
    local avgGain = (count > 0) and (totalGain / count) or 0
    local groupColor = getGradientColor(avgGain, 0, 200, GRADIENTS)
    local baseColor = getGradientColor(potentialScore, 165, 500, GRADIENTS)
    local selfBaseGain = math.max(potentialScore - currentScore, 0)
    local gainColor = getGradientColor(selfBaseGain, 0, 200, GRADIENTS)
    local rewards = RewardsFunctions.getRewardsForKeyLevel(keyLevel)
    local crest = RewardsFunctions.getCrestReward(keyLevel)

    tooltip:AddLine(string.format("%sGear: %s (%s) / Vault: %s (%s)|r",
        Constants.COLORS.WHITE, rewards.dungeonTrack, rewards.dungeonItem,
        rewards.vaultTrack, rewards.vaultItem))
    tooltip:AddLine(string.format("%sCrest: %s (%s)|r", Constants.COLORS.WHITE, crest.crestType, tostring(crest.crestAmount)))

    local scoreLine = ""
    local gainStr = ""
    if MRM_SavedVars.SHOW_TIMING then
        local maxScore = potentialScore + 15
        scoreLine = string.format("%sScore: %s%d|r - %s%d|r", Constants.COLORS.WHITE, baseColor, potentialScore, baseColor, maxScore)
        local minGain = selfBaseGain
        local maxGain = math.max(maxScore - currentScore, 0)
        if maxGain > 0 then
            gainStr = string.format(" %s(+%d-%d)|r", gainColor, minGain, maxGain)
        end
    else
        scoreLine = string.format("%sScore: %s%d|r", Constants.COLORS.WHITE, baseColor, potentialScore)
        local minGain = selfBaseGain
        if minGain > 0 then
            gainStr = string.format(" %s(+%d)|r", gainColor, minGain)
        end
    end
    tooltip:AddLine(scoreLine .. gainStr)

    if IsInGroup() and GetNumGroupMembers() > 1 then
        tooltip:AddLine(string.format("%sGroup Avg Gain: %s+%.1f|r", Constants.COLORS.WHITE, groupColor, avgGain))
    end
end

--- Tooltip hook: adds reward info and cleans up lines for keystone items.
local function onTooltipSetItem(tooltip)
    local name, link = tooltip:GetItem()
    if not link then return end
    for itemLink in link:gmatch("|Hkeystone:.-|h.-|h|r") do
        local itemString = getItemString(itemLink)
        if not itemString then return end
        local keyLevel = getKeyLevel(itemString)
        local mapID = getMapID(itemString)
        addTooltipRewardInfo(tooltip, itemString, keyLevel, mapID)
        removeSpecificTooltipText(tooltip)
    end
end

--- Chat hyperlink hook: adds reward info to keystone links in chat.
local function setHyperlinkHook(self, hyperlink)
    local itemString = getItemString(hyperlink)
    if not itemString or itemString == "" then return end
    if strsplit(":", itemString) == "keystone" then
        local keyLevel = getKeyLevel(hyperlink)
        local mapID = getMapID(hyperlink)
        ItemRefTooltip:AddLine(" ")
        addTooltipRewardInfo(ItemRefTooltip, itemString, keyLevel, mapID)
        ItemRefTooltip:Show()
    end
end

hooksecurefunc("ChatFrame_OnHyperlinkShow", setHyperlinkHook)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onTooltipSetItem)

--- Prints completion statistics to the chat window.
local function showCompletionStats()
    print(Constants.COLORS.GOLD .. "=== Mythic+ Completion Statistics ===" .. "|r")
    local stats = CompletionTracker:getStats()
    local seasonTotal = stats.seasonal.completed + stats.seasonal.failed
    print("\n" .. Constants.COLORS.GREEN .. "Season Overview:|r")
    print(Constants.COLORS.WHITE .. string.format("Total Runs: %d", seasonTotal))
    print(Constants.COLORS.WHITE .. string.format("Completed: %d (%d%%)", stats.seasonal.completed, stats.seasonal.rate))
    print(Constants.COLORS.RED .. string.format("Failed: %d (%d%%)", stats.seasonal.failed, 100 - stats.seasonal.rate))
    local weeklyTotal = stats.weekly.completed + stats.weekly.failed
    print("\n" .. Constants.COLORS.GREEN .. "This Week:|r")
    print(Constants.COLORS.WHITE .. string.format("Total Runs: %d", weeklyTotal))
    print(Constants.COLORS.WHITE .. string.format("Completed: %d (%d%%)", stats.weekly.completed, stats.weekly.rate))
    print(Constants.COLORS.RED .. string.format("Failed: %d (%d%%)", stats.weekly.failed, 100 - stats.weekly.rate))
    if weeklyTotal > 0 then
        print("\n|cff00ff00Weekly Dungeon Breakdown:|r")
        for _, dungeon in pairs(stats.weekly.dungeons) do
            local total = dungeon.completed + dungeon.failed
            if total > 0 then
                print(string.format("|cffffffff%s|r", dungeon.name))
                print(string.format("  Completed: %d, Failed: %d (Success Rate: %d%%)", dungeon.completed, dungeon.failed, dungeon.rate))
            end
        end
    end
end

SLASH_MRMYTHICAL1 = "/mrm"
SlashCmdList["MRMYTHICAL"] = function(msg)
    local args = {}
    for word in string.gmatch(msg, "%S+") do
        table.insert(args, word)
    end
    local mode = args[1] and args[1]:lower() or "help"
    if mode == "rewards" then
        local level = args[2] and tonumber(args[2])
        if level then
            local rewards = RewardsFunctions.getRewardsForKeyLevel(level)
            local crest = RewardsFunctions.getCrestReward(level)
            local rewardLine = string.format("Key Level %d: %s (%s) / %s (%s) | %s (%s)",
                level, rewards.dungeonTrack, rewards.dungeonItem,
                rewards.vaultTrack, rewards.vaultItem,
                crest.crestType, crest.crestAmount)
            print(rewardLine)
        else
            print("Mythic Keystone Rewards by Key Level:")
            for keyLevel = 2, 12 do
                local rewards = RewardsFunctions.getRewardsForKeyLevel(keyLevel)
                local crest = RewardsFunctions.getCrestReward(keyLevel)
                local rewardLine = string.format("Key Level %d: %s (%s) / %s (%s) | %s (%s)",
                    keyLevel, rewards.dungeonTrack, rewards.dungeonItem,
                    rewards.vaultTrack, rewards.vaultItem,
                    crest.crestType, crest.crestAmount)
                print(rewardLine)
            end
        end
    elseif mode == "score" then
        local level = args[2] and tonumber(args[2])
        if level then
            local potentialScore = RewardsFunctions.scoreFormula(level)
            print(string.format("Potential Mythic+ Score for keystone level %d is %d", level, potentialScore))
            local gains = {}
            for _, mapInfo in ipairs(Constants.MYTHIC_MAPS) do
                local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapInfo.id)
                local currentScore = 0
                if intimeInfo and intimeInfo.dungeonScore then
                    currentScore = intimeInfo.dungeonScore
                elseif overtimeInfo and overtimeInfo.dungeonScore then
                    currentScore = overtimeInfo.dungeonScore
                end
                local gain = potentialScore - currentScore
                table.insert(gains, { name = mapInfo.name, gain = gain, current = currentScore })
            end
            table.sort(gains, function(a, b) return a.gain > b.gain end)
            for _, mapGain in ipairs(gains) do
                if mapGain.gain > 0 then
                    print(string.format("%s: +%d (current: %d)", mapGain.name, mapGain.gain, mapGain.current))
                else
                    print(string.format("%s: No gain (current: %d)", mapGain.name, mapGain.current))
                end
            end
        else
            print("Usage: /mrm score <keystone level>")
        end
    elseif mode == "stats" then
        showCompletionStats()
    elseif mode == "reset" then
        local scope = args[2] and args[2]:lower() or "all"
        if scope == "all" or scope == "weekly" or scope == "seasonal" then
            CompletionTracker:resetStats(scope)
        else
            print("Usage: /mrm reset [all|weekly|seasonal]")
        end
    else
        print(Constants.COLORS.GOLD .. "Usage:|r")
        print(Constants.COLORS.WHITE .. "  /mrm rewards - Show keystone rewards")
        print(Constants.COLORS.WHITE .. "  /mrm score <keystone level> - Show keystone score calculations")
        print(Constants.COLORS.WHITE .. "  /mrm stats - Show completion statistics")
        print(Constants.COLORS.WHITE .. "  /mrm reset [all|weekly|seasonal] - Reset completion statistics")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MrMythical" then
            Options.initializeSettings()
            CompletionTracker:initialize()
            if GetCurrentRegion then
                local regNum = GetCurrentRegion()
                currentPlayerRegion = Constants.REGION_MAP[regNum]
            end
        end
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        local info = C_ChallengeMode.GetChallengeCompletionInfo()
        if not info then return end
        CompletionTracker:trackRun(
            info.mapChallengeModeID,
            info.onTime,
            info.level
        )
    end
end)

_G.MrMythical = MrMythical
