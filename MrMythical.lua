local GRADIENTS = GradientsData.GRADIENTS
local RewardsFunctions = RewardsFunctions

local line = false
local FONT = "|cffffffff"
local currentPlayerRegion = "us" -- Default to us

local AFFIX_STRINGS = {
    "  Fortified",
    "  Tyrannical",
    "  Xal'atath's Bargain: Ascendant",
    "  Xal'atath's Bargain: Devour", 
    "  Xal'atath's Bargain: Voidbound",
    "  Xal'atath's Bargain: Pulsar",
    "  Xal'atath's Guile"
}

local UNWANTED_STRINGS = {
    '"Place within the Font of Power inside the dungeon on Mythic difficulty."',
    "Soulbound",
    "Unique", 
    "Dungeon Modifiers:",
    unpack(AFFIX_STRINGS)
}

local regionMap = {
    [1] = "us",
    [2] = "kr",
    [3] = "eu",
    [4] = "tw",
    [5] = "cn",
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
    for _, unwanted in ipairs(UNWANTED_STRINGS) do
        if text == unwanted then
            return true
        end
    end
    return false
end

local function RemoveSpecificTooltipText(tooltip)
    if not MRM_SavedVars.COMPACT_MODE_ENABLED then return end
    for i = tooltip:NumLines(), 1, -1 do
        local leftLine = _G["GameTooltipTextLeft"..i]
        if leftLine then
            local lineText = leftLine:GetText()
            if IsUnwantedText(lineText) then
                local isAffix = false
                for _, affix in ipairs(AFFIX_STRINGS) do
                    if lineText == affix then
                        isAffix = true
                        break
                    end
                end
                
                if isAffix and not MRM_SavedVars.CHILD_OPTION then
                    -- Skip removal for affixes when CHILD_OPTION is false
                else
                    leftLine:SetText("")
                    local rightLine = _G["GameTooltipTextRight"..i]
                    if rightLine then
                        rightLine:SetText("")
                    end
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
    for name, score in pairs(groupData) do
        local playerGain = math.max(RewardsFunctions.ScoreFormula(keyLevel) - score, 0)
        totalGain = totalGain + playerGain
        count = count + 1
    end

    local avgGain = (count > 0) and (totalGain / count) or 0
    local potentialScore = RewardsFunctions.ScoreFormula(keyLevel)
    local groupColor = GetGradientColor(avgGain, 0, 200, GRADIENTS)
    local baseColor = GetGradientColor(potentialScore, 165, 500, GRADIENTS)
    local gainColor = GetGradientColor(math.max(potentialScore - currentScore,0), 0, 200, GRADIENTS)

    local rewards = RewardsFunctions.GetRewardsForKeyLevel(keyLevel)
    local crest = RewardsFunctions.GetCrestReward(keyLevel)

    tooltip:AddLine(string.format("%sGear: %s (%s) / %s (%s)|r",
        FONT, rewards.dungeonTrack, rewards.dungeonItem,
        rewards.vaultTrack, rewards.vaultItem))
    tooltip:AddLine(string.format("%sCrest: %s (%d)|r", FONT, crest.crestType, crest.crestAmount))
    
    local gainStr = (math.max(potentialScore - currentScore,0) > 0) and 
        string.format(" %s(+%d-%d)|r", gainColor, math.max(potentialScore - currentScore,0), math.max(potentialScore + 15 - currentScore,0)) or ""
    
    tooltip:AddLine(string.format("%sScore: %s%d|r - %s%d|r%s", FONT,
        baseColor, potentialScore,
        baseColor, potentialScore + 15,
        gainStr))
        
    if IsInGroup() and GetNumGroupMembers() > 1 then
        tooltip:AddLine(string.format("%sGroup Avg Gain: %s+%.1f|r", FONT, groupColor, avgGain))
    end
end

local function OnTooltipSetItem(tooltip, ...)
    local name, link = GameTooltip:GetItem()
    if not link then return end

    for itemLink in link:gmatch("|%x+|Hkeystone:.-|h.-|h|r") do
        local itemString = GetItemString(itemLink)
        if not itemString then return end

        local keyLevel = GetKeyLevel(itemString)
        local mapID = GetMapID(itemString) 

        AddTooltipRewardInfo(tooltip, itemString, keyLevel, mapID)
        RemoveSpecificTooltipText(tooltip)
    end
end

local function OnTooltipCleared(tooltip, ...)
    line = false
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

GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
hooksecurefunc("ChatFrame_OnHyperlinkShow", SetHyperlink_Hook)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)

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
    else
        print("|cffffcc00Usage:|r")
        print("  /mrm rewards - Show keystone rewards")
        print("  /mrm score <keystone level> - Show keystone score calculations")
    end
end

local category
local function InitializeSettings()
    MRM_SavedVars = MRM_SavedVars or {}
    MRM_SavedVars.COMPACT_MODE_ENABLED = MRM_SavedVars.COMPACT_MODE_ENABLED ~= false
    MRM_SavedVars.CHILD_OPTION = MRM_SavedVars.CHILD_OPTION == true

    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        print("MrMythical: Settings API not found. Options unavailable via Interface menu.")
        return
    end

    category = Settings.RegisterVerticalLayoutCategory("Mr. Mythical", "MrMythical")

    local compactSetting = Settings.RegisterAddOnSetting(category, "Compact Mode", "COMPACT_MODE_ENABLED", MRM_SavedVars, "boolean", "Compact Keystone Tooltips", true)
    compactSetting:SetValueChangedCallback(function(setting, value)
        MRM_SavedVars.COMPACT_MODE_ENABLED = value
    end)
    local compactInitializer = Settings.CreateCheckbox(category, compactSetting, "Enable to remove extra lines like 'Soulbound' and 'Unique' from keystone tooltips.")
    compactInitializer:SetSetting(compactSetting) 


    local childSetting = Settings.RegisterAddOnSetting(category, "Hide Affix Text", "CHILD_OPTION", MRM_SavedVars, "boolean", "Hide Current Affixes", false) 
    childSetting:SetValueChangedCallback(function(setting, value)
        MRM_SavedVars.CHILD_OPTION = value
    end)
    local childInitializer = Settings.CreateCheckbox(category, childSetting, "When Compact Mode is enabled, also hide the lines listing the current dungeon affixes.")
    childInitializer:SetSetting(childSetting) 

    childInitializer:SetParentInitializer(compactInitializer, function()
        return compactSetting:GetValue() == true
    end)

    Settings.RegisterAddOnCategory(category)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "MrMythical" then
        InitializeSettings()
        if GetCurrentRegion then
            local regNum = GetCurrentRegion()
            currentPlayerRegion = regionMap[regNum]
        end
    end
end)
