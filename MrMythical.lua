local GRADIENTS = GradientsData.GRADIENTS
local RewardsFunctions = RewardsFunctions
local CompletionTracker = CompletionTracker

local Colors = {
    WHITE = "|cffffffff",
    GOLD = "|cffffcc00",
    GREEN = "|cff00ff00",
    GRAY = "|cff808080",
    BLUE = "|cff0088ff",
    RED = "|cffff0000",
}

local currentPlayerRegion = "us" -- Default to us

local AFFIX_STRINGS = {
    "Fortified",
    "Tyrannical",
    "Xal'atath",
    "Dungeon Modifiers:"
}

local DURATION_STRINGS = {
    "Duration"
}

local UNWANTED_STRINGS = {
    "Font of Power",
    "Soulbound",
    "Unique"

}

local regionMap = {
    [1] = "us",
    [2] = "kr",
    [3] = "eu",
    [4] = "tw",
    [5] = "cn"
}

local MYTHIC_MAPS = {
    { id = 506, name = "Cinderbrew Meadery" },
    { id = 504, name = "Darkflame Cleft" },
    { id = 370, name = "Mechagon Workshop" },
    { id = 525, name = "Operation: Floodgate" },
    { id = 499, name = "Priory of the Sacred Flame" },
    { id = 247, name = "The MOTHERLODE!!" },
    { id = 500, name = "The Rookery" },
    { id = 382, name = "Theater of Pain" }
}

local function GetColorFromStops(normalizedValue, stops)
    if normalizedValue < 0 then normalizedValue = 0 end
    if normalizedValue > 1 then normalizedValue = 1 end

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

local function GetGradientColor(value, domainMin, domainMax, stops)
    if MRM_SavedVars.PLAIN_SCORE_COLORS then
        return Colors.WHITE
    end
    
    local ratio = (value - domainMin) / (domainMax - domainMin)
    ratio = 1 - ratio
    if ratio < 0 then ratio = 0 end
    if ratio > 1 then ratio = 1 end
    return GetColorFromStops(ratio, stops)
end

local function GetDungeonScoreFromProfile(profile, targetMapID)
    if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.sortedDungeons then
        for _, entry in ipairs(profile.mythicKeystoneProfile.sortedDungeons) do
            if entry.dungeon and entry.dungeon.keystone_instance == targetMapID then
                local level = entry.level or 0
                local chests = entry.chests or 0
                local baseScore = RewardsFunctions.ScoreFormula(level)
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
            local averageScore = profile.mythicKeystoneProfile.currentScore / numDungeons
            return averageScore
        end
    end

    return 0
end

function GetGroupMythicData_Party(playerScore, targetMapID)
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
                    dungeonScore = GetDungeonScoreFromProfile(pProfile, targetMapID)
                    groupData[name] = dungeonScore
                else
                    groupData[name] = 0
                end
            else
                groupData[name] = 0
            end
        end
    end
    return groupData
end

local function GetItemString(link)
    return string.match(link, "keystone[%-?%d:]+")
end

local function GetKeyLevel(link)
    local keyField = select(4, strsplit(":", link))
    return tonumber(string.sub(keyField or "", 1, 2))
end

local function GetMapID(link)
    local parts = { strsplit(":", link) }
    if #parts >= 3 then
        local mapID = tonumber(parts[3])
        return mapID
    end
    return nil
end

function GetCharacterMythicScore(itemString)
    local mapID = GetMapID(itemString)
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

local function IsUnwantedText(text)
    if not text then return false end
    
    for _, duration in ipairs(DURATION_STRINGS) do
        if text:find(duration, 1, true) then
            return MRM_SavedVars.HIDE_DURATION
        end
    end
    
    for _, affix in ipairs(AFFIX_STRINGS) do
        if text:find(affix, 1, true) then
            return MRM_SavedVars.HIDE_AFFIX_TEXT
        end
    end
    
    for _, unwanted in ipairs(UNWANTED_STRINGS) do
        if text:find(unwanted, 1, true) then
            return MRM_SavedVars.HIDE_UNWANTED_TEXT
        end
    end
    
    return false
end

local function RemoveSpecificTooltipText(tooltip)
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
    
    for i = 2, tooltip:NumLines() do
        local leftLine = _G["GameTooltipTextLeft"..i]
        local rightLine = _G["GameTooltipTextRight"..i]
        
        if leftLine then
            local lineText = leftLine:GetText() or ""
            local r, g, b = leftLine:GetTextColor()
            
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
            
            if lineText and not IsUnwantedText(lineText) then
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

local function AddTooltipRewardInfo(tooltip, itemString, keyLevel, mapID)
    local currentScore = GetCharacterMythicScore(itemString)
    local groupData = GetGroupMythicData_Party(currentScore, mapID)

    local totalGain, count = 0, 0
    local potentialScore = RewardsFunctions.ScoreFormula(keyLevel)

    for name, score in pairs(groupData) do
        local playerGain = math.max(potentialScore - score, 0)
        totalGain = totalGain + playerGain
        count = count + 1
    end

    local avgGain = (count > 0) and (totalGain / count) or 0

    local groupColor = GetGradientColor(avgGain, 0, 200, GRADIENTS)
    local baseColor = GetGradientColor(potentialScore, 165, 500, GRADIENTS)
    local selfBaseGain = math.max(potentialScore - currentScore, 0)
    local gainColor = GetGradientColor(selfBaseGain, 0, 200, GRADIENTS)

    local rewards = RewardsFunctions.GetRewardsForKeyLevel(keyLevel)
    local crest = RewardsFunctions.GetCrestReward(keyLevel)

    tooltip:AddLine(string.format("%sGear: %s (%s) / Vault: %s (%s)|r",
        Colors.WHITE, rewards.dungeonTrack, rewards.dungeonItem,
        rewards.vaultTrack, rewards.vaultItem))
    tooltip:AddLine(string.format("%sCrest: %s (%s)|r", Colors.WHITE, crest.crestType, tostring(crest.crestAmount))) 

    local scoreLine = ""
    local gainStr = ""

    if MRM_SavedVars.SHOW_TIMING then
        local maxScore = potentialScore + 15
        scoreLine = string.format("%sScore: %s%d|r - %s%d|r", Colors.WHITE, baseColor, potentialScore, baseColor, maxScore) 

        local minGain = selfBaseGain
        local maxGain = math.max(maxScore - currentScore, 0)
        if maxGain > 0 then
            gainStr = string.format(" %s(+%d-%d)|r", gainColor, minGain, maxGain)
        end
    else
        scoreLine = string.format("%sScore: %s%d|r", Colors.WHITE, baseColor, potentialScore) 

        local minGain = selfBaseGain
        if minGain > 0 then
            gainStr = string.format(" %s(+%d)|r", gainColor, minGain)
        end
    end

    tooltip:AddLine(scoreLine .. gainStr)

    if IsInGroup() and GetNumGroupMembers() > 1 then
        tooltip:AddLine(string.format("%sGroup Avg Gain: %s+%.1f|r", Colors.WHITE, groupColor, avgGain))
    end
end

local function OnTooltipSetItem(tooltip, ...)
    local name, link = GameTooltip:GetItem()
    if not link then return end

    for itemLink in link:gmatch("|Hkeystone:.-|h.-|h|r") do
        local itemString = GetItemString(itemLink)
        if not itemString then return end

        local keyLevel = GetKeyLevel(itemString)
        local mapID = GetMapID(itemString) 

        AddTooltipRewardInfo(tooltip, itemString, keyLevel, mapID)
        RemoveSpecificTooltipText(tooltip)
    end
end

local function SetHyperlink_Hook(self, hyperlink, text, button)
    local itemString = GetItemString(hyperlink)
    if not itemString or itemString == "" then return end

    if strsplit(":", itemString) == "keystone" then
        local keyLevel = GetKeyLevel(hyperlink)
        local mapID = GetMapID(hyperlink) 
        AddTooltipRewardInfo(ItemRefTooltip, itemString, keyLevel, mapID)
        ItemRefTooltip:Show()
        RemoveSpecificTooltipText(ItemRefTooltip)
    end
end

hooksecurefunc("ChatFrame_OnHyperlinkShow", SetHyperlink_Hook)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)

local function ShowCompletionStats()
    local stats = CompletionTracker:GetStats()
    
    -- Header
    print(Colors.GOLD .. "=== Mythic+ Completion Statistics ===" .. "|r")
    
    local seasonTotal = stats.seasonal.completed + stats.seasonal.failed
    print("\n" .. Colors.GREEN .. "Season Overview:|r")
    print(Colors.WHITE .. string.format("Total Runs: %d", seasonTotal))
    print(Colors.WHITE .. string.format("Completed: %d (%d%%)", 
        stats.seasonal.completed,
        stats.seasonal.rate))
    print(Colors.RED .. string.format("Failed: %d (%d%%)", 
        stats.seasonal.failed,
        100 - stats.seasonal.rate))
    
    local weeklyTotal = stats.weekly.completed + stats.weekly.failed
    print("\n" .. Colors.GREEN .. "This Week:|r")
    print(Colors.WHITE .. string.format("Total Runs: %d", weeklyTotal))
    print(Colors.WHITE .. string.format("Completed: %d (%d%%)", 
        stats.weekly.completed,
        stats.weekly.rate))
    print(Colors.RED .. string.format("Failed: %d (%d%%)", 
        stats.weekly.failed,
        100 - stats.weekly.rate))
    
    if weeklyTotal > 0 then
        print("\n|cff00ff00Weekly Dungeon Breakdown:|r")
        for _, dungeon in pairs(stats.weekly.dungeons) do
            local total = dungeon.completed + dungeon.failed
            if total > 0 then
                print(string.format("|cffffffff%s|r", dungeon.name))
                print(string.format("  Completed: %d, Failed: %d (Success Rate: %d%%)", 
                    dungeon.completed,
                    dungeon.failed,
                    dungeon.rate))
            end
        end
    end
end

SLASH_MYTHICALREWARDS1 = "/mrm"
SlashCmdList["MYTHICALREWARDS"] = function(msg)
    local args = {}
    for word in string.gmatch(msg, "%S+") do
        table.insert(args, word)
    end
    
    local mode = args[1] and args[1]:lower() or "help"

    if mode == "rewards" then
        local level = args[2] and tonumber(args[2])
        if level then
            local rewards = RewardsFunctions.GetRewardsForKeyLevel(level)
            local crest = RewardsFunctions.GetCrestReward(level)
            local rewardLine = string.format("Key Level %d: %s (%s) / %s (%s) | %s (%s)",
                                    level,
                                    rewards.dungeonTrack, rewards.dungeonItem,
                                    rewards.vaultTrack, rewards.vaultItem,
                                    crest.crestType, crest.crestAmount)
            print(rewardLine)
        else
            print("Mythic Keystone Rewards by Key Level:")
            for keyLevel = 2, 12 do
                local rewards = RewardsFunctions.GetRewardsForKeyLevel(keyLevel)
                local crest = RewardsFunctions.GetCrestReward(keyLevel)
                local rewardLine = string.format("Key Level %d: %s (%s) / %s (%s) | %s (%s)",
                                        keyLevel,
                                        rewards.dungeonTrack, rewards.dungeonItem,
                                        rewards.vaultTrack, rewards.vaultItem,
                                        crest.crestType, crest.crestAmount)
                print(rewardLine)
            end
        end
    elseif mode == "score" then
        local level = args[2] and tonumber(args[2])
        if level then
            local potentialScore = RewardsFunctions.ScoreFormula(level)
            print(string.format("Potential Mythic+ Score for keystone level %d is %d", level, potentialScore))
            local gains = {}
            for _, mapInfo in ipairs(MYTHIC_MAPS) do
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

            table.sort(gains, function(a, b)
                return a.gain > b.gain
            end)

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
        ShowCompletionStats()
    elseif mode == "reset" then
        local scope = args[2] and args[2]:lower() or "all"
        if scope == "all" or scope == "weekly" or scope == "seasonal" then
            CompletionTracker:ResetStats(scope)
        else
            print("Usage: /mrm reset [all|weekly|seasonal]")
        end
    else
        print(Colors.GOLD .. "Usage:|r")
        print(Colors.WHITE .. "  /mrm rewards - Show keystone rewards")
        print(Colors.WHITE .. "  /mrm score <keystone level> - Show keystone score calculations")
        print(Colors.WHITE .. "  /mrm stats - Show completion statistics")
        print(Colors.WHITE .. "  /mrm reset [all|weekly|seasonal] - Reset completion statistics")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MrMythical" then
            MrMythicalUI.InitializeSettings()
            CompletionTracker:SetMythicMaps(MYTHIC_MAPS)
            CompletionTracker:Initialize()
            if GetCurrentRegion then
                local regNum = GetCurrentRegion()
                currentPlayerRegion = regionMap[regNum]
            end
        end
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        local info = C_ChallengeMode.GetChallengeCompletionInfo()
        if not info then return end
        
        CompletionTracker:TrackRun(
            info.mapChallengeModeID,
            info.onTime,
            info.level
        )
    end
end)
