--[[ 
    Mythic Keystone Tooltip Addon
    Displays combined reward, crest, and Mythic+ score information in tooltips,
    and provides a slash command (/mrm) with subcommands "rewards" and "score".
]]--

---------------------------
-- Constants & Variables --
---------------------------
local line = false
local FONT = "|cffffffff"

local DUNGEON_REWARDS = {
    { itemLevel = 597, upgradeTrack = "Champion 1" },  -- Key Level 2
    { itemLevel = 597, upgradeTrack = "Champion 1" },  -- Key Level 3
    { itemLevel = 600, upgradeTrack = "Champion 2" },  -- Key Level 4
    { itemLevel = 603, upgradeTrack = "Champion 3" },  -- Key Level 5
    { itemLevel = 606, upgradeTrack = "Champion 4" },  -- Key Level 6
    { itemLevel = 610, upgradeTrack = "Hero 1" },      -- Key Level 7
    { itemLevel = 610, upgradeTrack = "Hero 1" },      -- Key Level 8
    { itemLevel = 613, upgradeTrack = "Hero 2" },      -- Key Level 9+
}

local VAULT_REWARDS = {
    { itemLevel = 606, upgradeTrack = "Champion 4" },  -- Key Level 2
    { itemLevel = 610, upgradeTrack = "Hero 1" },      -- Key Level 3
    { itemLevel = 610, upgradeTrack = "Hero 1" },      -- Key Level 4
    { itemLevel = 613, upgradeTrack = "Hero 2" },      -- Key Level 5
    { itemLevel = 613, upgradeTrack = "Hero 2" },      -- Key Level 6
    { itemLevel = 616, upgradeTrack = "Hero 3" },      -- Key Level 7
    { itemLevel = 619, upgradeTrack = "Hero 4" },      -- Key Level 8
    { itemLevel = 619, upgradeTrack = "Hero 4" },      -- Key Level 9
    { itemLevel = 623, upgradeTrack = "Myth 1" },      -- Key Level 10+
}

local CREST_REWARDS = {
    { crestType = "Carved", amount = 12 },  -- Key Level 2
    { crestType = "Carved", amount = 14 },  -- Key Level 3
    { crestType = "Runed",  amount = 12 },  -- Key Level 4
    { crestType = "Runed",  amount = 14 },  -- Key Level 5
    { crestType = "Runed",  amount = 16 },  -- Key Level 6
    { crestType = "Runed",  amount = 18 },  -- Key Level 7
    { crestType = "Gilded", amount = 12 },  -- Key Level 8
    { crestType = "Gilded", amount = 14 },  -- Key Level 9
    { crestType = "Gilded", amount = 16 },  -- Key Level 10
    { crestType = "Gilded", amount = 18 },  -- Key Level 11
    { crestType = "Gilded", amount = 20 },  -- Key Level 12
}

local MYTHIC_MAPS = {
    { id = 503, name = "Ara-Kara, City of Echoes" },
    { id = 502, name = "City of Threads" },
    { id = 507, name = "Grim Batol" },
    { id = 375, name = "Mists of Tirna Scithe" },
    { id = 353, name = "Siege of Boralus" },
    { id = 505, name = "The Dawnbreaker" },
    { id = 376, name = "The Necrotic Wake" },
    { id = 501, name = "The Stonevault" }
}

local gradientStops = {
    { score = 3725, rgbInteger = { 255, 128, 0 } },
    { score = 3660, rgbInteger = { 254, 126, 20 } },
    { score = 3635, rgbInteger = { 253, 124, 31 } },
    { score = 3610, rgbInteger = { 252, 122, 40 } },
    { score = 3585, rgbInteger = { 251, 121, 48 } },
    { score = 3560, rgbInteger = { 250, 119, 55 } },
    { score = 3540, rgbInteger = { 249, 117, 62 } },
    { score = 3515, rgbInteger = { 248, 115, 68 } },
    { score = 3490, rgbInteger = { 246, 113, 73 } },
    { score = 3465, rgbInteger = { 245, 111, 79 } },
    { score = 3440, rgbInteger = { 244, 109, 84 } },
    { score = 3420, rgbInteger = { 243, 108, 90 } },
    { score = 3395, rgbInteger = { 241, 106, 95 } },
    { score = 3370, rgbInteger = { 240, 104, 100 } },
    { score = 3345, rgbInteger = { 238, 102, 105 } },
    { score = 3320, rgbInteger = { 237, 100, 110 } },
    { score = 3300, rgbInteger = { 235, 98, 115 } },
    { score = 3275, rgbInteger = { 234, 96, 119 } },
    { score = 3250, rgbInteger = { 232, 95, 124 } },
    { score = 3225, rgbInteger = { 230, 93, 129 } },
    { score = 3200, rgbInteger = { 229, 91, 134 } },
    { score = 3180, rgbInteger = { 227, 89, 139 } },
    { score = 3155, rgbInteger = { 225, 87, 143 } },
    { score = 3130, rgbInteger = { 223, 85, 148 } },
    { score = 3105, rgbInteger = { 221, 83, 153 } },
    { score = 3080, rgbInteger = { 218, 82, 157 } },
    { score = 3060, rgbInteger = { 216, 80, 162 } },
    { score = 3035, rgbInteger = { 214, 78, 167 } },
    { score = 3010, rgbInteger = { 211, 76, 172 } },
    { score = 2985, rgbInteger = { 209, 74, 176 } },
    { score = 2960, rgbInteger = { 206, 73, 181 } },
    { score = 2940, rgbInteger = { 203, 71, 186 } },
    { score = 2915, rgbInteger = { 201, 69, 190 } },
    { score = 2890, rgbInteger = { 198, 67, 195 } },
    { score = 2865, rgbInteger = { 194, 66, 200 } },
    { score = 2840, rgbInteger = { 191, 64, 205 } },
    { score = 2820, rgbInteger = { 188, 62, 209 } },
    { score = 2795, rgbInteger = { 184, 61, 214 } },
    { score = 2770, rgbInteger = { 180, 59, 219 } },
    { score = 2745, rgbInteger = { 176, 58, 224 } },
    { score = 2720, rgbInteger = { 172, 56, 228 } },
    { score = 2700, rgbInteger = { 168, 54, 233 } },
    { score = 2675, rgbInteger = { 163, 53, 238 } },
    { score = 2640, rgbInteger = { 155, 62, 236 } },
    { score = 2615, rgbInteger = { 146, 70, 235 } },
    { score = 2590, rgbInteger = { 138, 77, 233 } },
    { score = 2565, rgbInteger = { 128, 83, 232 } },
    { score = 2545, rgbInteger = { 118, 88, 230 } },
    { score = 2520, rgbInteger = { 108, 93, 229 } },
    { score = 2495, rgbInteger = { 96, 98, 227 } },
    { score = 2470, rgbInteger = { 83, 102, 226 } },
    { score = 2445, rgbInteger = { 67, 105, 224 } },
    { score = 2425, rgbInteger = { 46, 109, 223 } },
    { score = 2400, rgbInteger = { 0, 112, 221 } },
    { score = 2325, rgbInteger = { 23, 115, 218 } },
    { score = 2300, rgbInteger = { 35, 117, 215 } },
    { score = 2275, rgbInteger = { 44, 120, 212 } },
    { score = 2255, rgbInteger = { 50, 123, 209 } },
    { score = 2230, rgbInteger = { 56, 126, 207 } },
    { score = 2205, rgbInteger = { 61, 128, 204 } },
    { score = 2180, rgbInteger = { 65, 131, 201 } },
    { score = 2155, rgbInteger = { 69, 134, 198 } },
    { score = 2135, rgbInteger = { 72, 137, 195 } },
    { score = 2110, rgbInteger = { 75, 139, 192 } },
    { score = 2085, rgbInteger = { 78, 142, 189 } },
    { score = 2060, rgbInteger = { 81, 145, 186 } },
    { score = 2035, rgbInteger = { 83, 148, 183 } },
    { score = 2015, rgbInteger = { 85, 151, 180 } },
    { score = 1990, rgbInteger = { 87, 153, 177 } },
    { score = 1965, rgbInteger = { 88, 156, 174 } },
    { score = 1940, rgbInteger = { 90, 159, 171 } },
    { score = 1915, rgbInteger = { 91, 162, 168 } },
    { score = 1895, rgbInteger = { 92, 165, 165 } },
    { score = 1870, rgbInteger = { 93, 168, 162 } },
    { score = 1845, rgbInteger = { 94, 170, 159 } },
    { score = 1820, rgbInteger = { 94, 173, 156 } },
    { score = 1795, rgbInteger = { 95, 176, 152 } },
    { score = 1775, rgbInteger = { 95, 179, 149 } },
    { score = 1750, rgbInteger = { 95, 182, 146 } },
    { score = 1725, rgbInteger = { 95, 185, 143 } },
    { score = 1700, rgbInteger = { 95, 188, 139 } },
    { score = 1675, rgbInteger = { 95, 190, 136 } },
    { score = 1655, rgbInteger = { 95, 193, 133 } },
    { score = 1630, rgbInteger = { 94, 196, 129 } },
    { score = 1605, rgbInteger = { 94, 199, 125 } },
    { score = 1580, rgbInteger = { 93, 202, 122 } },
    { score = 1555, rgbInteger = { 92, 205, 118 } },
    { score = 1535, rgbInteger = { 91, 208, 114 } },
    { score = 1510, rgbInteger = { 90, 211, 111 } },
    { score = 1485, rgbInteger = { 88, 214, 107 } },
    { score = 1460, rgbInteger = { 87, 217, 102 } },
    { score = 1435, rgbInteger = { 85, 220, 98 } },
    { score = 1415, rgbInteger = { 83, 222, 94 } },
    { score = 1390, rgbInteger = { 80, 225, 89 } },
    { score = 1365, rgbInteger = { 78, 228, 85 } },
    { score = 1340, rgbInteger = { 75, 231, 79 } },
    { score = 1315, rgbInteger = { 72, 234, 74 } },
    { score = 1295, rgbInteger = { 68, 237, 68 } },
    { score = 1270, rgbInteger = { 64, 240, 62 } },
    { score = 1245, rgbInteger = { 60, 243, 55 } },
    { score = 1220, rgbInteger = { 54, 246, 47 } },
    { score = 1195, rgbInteger = { 48, 249, 37 } },
    { score = 1175, rgbInteger = { 40, 252, 24 } },
    { score = 1150, rgbInteger = { 30, 255, 0 } },
    { score = 1125, rgbInteger = { 51, 255, 26 } },
    { score = 1100, rgbInteger = { 65, 255, 40 } },
    { score = 1075, rgbInteger = { 77, 255, 51 } },
    { score = 1050, rgbInteger = { 87, 255, 60 } },
    { score = 1025, rgbInteger = { 96, 255, 69 } },
    { score = 1000, rgbInteger = { 104, 255, 76 } },
    { score = 975,  rgbInteger = { 111, 255, 83 } },
    { score = 950,  rgbInteger = { 118, 255, 90 } },
    { score = 925,  rgbInteger = { 125, 255, 97 } },
    { score = 900,  rgbInteger = { 131, 255, 103 } },
    { score = 875,  rgbInteger = { 137, 255, 109 } },
    { score = 850,  rgbInteger = { 143, 255, 115 } },
    { score = 825,  rgbInteger = { 149, 255, 121 } },
    { score = 800,  rgbInteger = { 154, 255, 127 } },
    { score = 775,  rgbInteger = { 159, 255, 132 } },
    { score = 750,  rgbInteger = { 164, 255, 138 } },
    { score = 725,  rgbInteger = { 169, 255, 144 } },
    { score = 700,  rgbInteger = { 174, 255, 149 } },
    { score = 675,  rgbInteger = { 179, 255, 155 } },
    { score = 650,  rgbInteger = { 183, 255, 160 } },
    { score = 625,  rgbInteger = { 188, 255, 165 } },
    { score = 600,  rgbInteger = { 192, 255, 171 } },
    { score = 575,  rgbInteger = { 197, 255, 176 } },
    { score = 550,  rgbInteger = { 201, 255, 181 } },
    { score = 525,  rgbInteger = { 205, 255, 187 } },
    { score = 500,  rgbInteger = { 209, 255, 192 } },
    { score = 475,  rgbInteger = { 213, 255, 197 } },
    { score = 450,  rgbInteger = { 217, 255, 203 } },
    { score = 425,  rgbInteger = { 221, 255, 208 } },
    { score = 400,  rgbInteger = { 225, 255, 213 } },
    { score = 375,  rgbInteger = { 229, 255, 218 } },
    { score = 350,  rgbInteger = { 233, 255, 224 } },
    { score = 325,  rgbInteger = { 237, 255, 229 } },
    { score = 300,  rgbInteger = { 240, 255, 234 } },
    { score = 275,  rgbInteger = { 244, 255, 239 } },
    { score = 250,  rgbInteger = { 248, 255, 245 } },
    { score = 225,  rgbInteger = { 251, 255, 250 } },
    { score = 200,  rgbInteger = { 255, 255, 255 } }
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


---------------------
-- Slash Command   --
---------------------
SLASH_MYTHICALREWARDS1 = "/mrm"
SlashCmdList["MYTHICALREWARDS"] = function(msg)
    local args = {}
    for word in string.gmatch(msg, "%S+") do
        table.insert(args, word)
    end

    local mode = args[1] and args[1]:lower() or "rewards"

    if mode == "rewards" then
        local level = args[2] and tonumber(args[2])
        if level then
            local rewards = GetRewardsForKeyLevel(level)
            local crest = GetCrestReward(level)
            local rewardLine = string.format("Key Level %d: %s (%s) / %s (%s) | %s (%s)",
                                    level,
                                    rewards.dungeonTrack, rewards.dungeonItem,
                                    rewards.vaultTrack, rewards.vaultItem,
                                    crest.crestType, crest.crestAmount)
            print(rewardLine)
        else
            print("Mythic Keystone Rewards by Key Level:")
            for keyLevel = 2, 12 do
                local rewards = GetRewardsForKeyLevel(keyLevel)
                local crest = GetCrestReward(keyLevel)
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
            local potentialScore = ScoreFormula(level)
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
        print("Usage: /mrm <rewards|score> [<keystone level>]")
    end
end

---------------------
-- Initialization  --
---------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        -- Initialization go here
    end
end)

--------------------------
-- Helper Functions     --
--------------------------
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

function ScoreFormula(keyLevel)
    if keyLevel < 2 then return 0 end
    local affixBreakpoints = { [4] = 10, [7] = 15, [10] = 10, [12] = 15 }
    local parScore = 165
    for current = 2, keyLevel - 1 do
        parScore = parScore + 15
        local nextLevel = current + 1
        if affixBreakpoints[nextLevel] then
            parScore = parScore + affixBreakpoints[nextLevel]
        end
    end
    return parScore
end

-------------------------------
-- Reward Lookup Functions   --
-------------------------------
function GetRewardsForKeyLevel(keyLevel)
    local rewards = {}
    if not keyLevel or keyLevel < 2 then
        rewards.dungeonItem = "Unknown"
        rewards.dungeonTrack = "Unknown"
        rewards.vaultItem = "Unknown"
        rewards.vaultTrack = "Unknown"
        return rewards
    end

    local dungeonIndex = math.min(keyLevel - 1, #DUNGEON_REWARDS)
    local dungeonReward = DUNGEON_REWARDS[dungeonIndex] or {}
    rewards.dungeonItem = tostring(dungeonReward.itemLevel or "Unknown")
    rewards.dungeonTrack = dungeonReward.upgradeTrack or "Unknown"

    local vaultIndex = math.min(keyLevel - 1, #VAULT_REWARDS)
    local vaultReward = VAULT_REWARDS[vaultIndex] or {}
    rewards.vaultItem = tostring(vaultReward.itemLevel or "Unknown")
    rewards.vaultTrack = vaultReward.upgradeTrack or "Unknown"

    return rewards
end

function GetCrestReward(keyLevel)
    local crest = {}
    if not keyLevel or keyLevel < 2 or keyLevel > 12 then
        crest.crestType = "Unknown"
        crest.crestAmount = "Unknown"
        return crest
    end

    local crestReward = CREST_REWARDS[keyLevel - 1] or {}
    crest.crestType = crestReward.crestType or "Unknown"
    crest.crestAmount = crestReward.amount or "Unknown"
    return crest
end

--------------------------
-- Tooltip Handlers     --
--------------------------
local function OnTooltipSetItem(tooltip, ...)
    local name, link = GameTooltip:GetItem()
    if not link then return end

    for itemLink in link:gmatch("|%x+|Hkeystone:.-|h.-|h|r") do
        local itemString = GetItemString(itemLink)
        if not itemString then return end

        local keyLevel = GetKeyLevel(itemString)
        local currentScore = GetCharacterMythicScore(itemString)
        local rewards = GetRewardsForKeyLevel(keyLevel)
        local crest = GetCrestReward(keyLevel)
        local baseScore = ScoreFormula(keyLevel)
        local maxScore = baseScore + 15
        local minGain = math.max(baseScore - currentScore, 0)
        local maxGain = math.max(maxScore - currentScore, 0)
        
        local baseColor = GetGradientColor(baseScore, 165, 500, gradientStops)
        local gainColor = GetGradientColor(maxGain, 0, 200, gradientStops)

        if not line then
            tooltip:AddLine(string.format("%sGear: %s (%s) / %s (%s)|r",
                FONT, rewards.dungeonTrack, rewards.dungeonItem,
                rewards.vaultTrack, rewards.vaultItem))
            
            tooltip:AddLine(string.format("%sCrest: %s (%d)|r", 
                FONT, crest.crestType, crest.crestAmount))
            
            local gainStr = (maxGain > 0) and string.format(" %s(+%d-%d)|r", gainColor, minGain, maxGain) or ""
            tooltip:AddLine(string.format("%sScore: %s%d|r - %s%d|r%s", FONT,
                baseColor, baseScore,
                baseColor, maxScore,
                gainStr))
            
            line = true
        end
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
        local currentScore = GetCharacterMythicScore(itemString)
        local rewards = GetRewardsForKeyLevel(keyLevel)
        local crest = GetCrestReward(keyLevel)
        local baseScore = ScoreFormula(keyLevel)
        local maxScore = baseScore + 15
        local minGain = math.max(baseScore - currentScore, 0)
        local maxGain = math.max(maxScore - currentScore, 0)

        local baseColor = GetGradientColor(baseScore, 165, 500, gradientStops)
        local gainColor = GetGradientColor(maxGain, 0, 200, gradientStops)

        local rewardLine = string.format("%sGear: %s (%s) / %s (%s)|r",
                                FONT, rewards.dungeonTrack, rewards.dungeonItem,
                                rewards.vaultTrack, rewards.vaultItem)
        ItemRefTooltip:AddLine(rewardLine)
        ItemRefTooltip:AddLine(string.format("%sCrest: %s (%d)|r", FONT, crest.crestType, crest.crestAmount))
        
        local gainStr = (maxGain > 0) and string.format(" %s(+%d-%d)|r", gainColor, minGain, maxGain) or ""
        ItemRefTooltip:AddLine(string.format("%sScore: %s%d|r - %s%d|r%s", FONT,
            baseColor, baseScore,
            baseColor, maxScore,
            gainStr))
        ItemRefTooltip:Show()
    end
end


-----------------------------
-- Register Tooltip Hooks  --
-----------------------------
GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
hooksecurefunc("ChatFrame_OnHyperlinkShow", SetHyperlink_Hook)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
