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
local DEBUG_MODE = false

-- Updated reward tables using objects
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
        -- Additional initialization can go here if needed.
    end
end)

--------------------------
-- Helper Functions     --
--------------------------
local function DebugPrint(msg)
    if DEBUG_MODE then
        print("|cffffd700[DEBUG]|r " .. msg)
    end
end

local function GetItemString(link)
    return string.match(link, "keystone[%-?%d:]+")
end

local function GetKeyLevel(link)
    local keyField = select(4, strsplit(":", link))
    DebugPrint("Raw key level field: " .. tostring(keyField))
    return tonumber(string.sub(keyField or "", 1, 2))
end

local function GetMapID(link)
    local parts = { strsplit(":", link) }
    if #parts >= 3 then
        local mapID = tonumber(parts[3])
        DebugPrint("Extracted mapID (field 3): " .. tostring(mapID))
        return mapID
    end
    return nil
end

function GetCharacterMythicScore(itemString)
    local mapID = GetMapID(itemString)
    if not mapID then
        DebugPrint("No mapID found in item string.")
        return 0
    end
    DebugPrint("Querying C_MythicPlus.GetSeasonBestForMap with mapID: " .. tostring(mapID))
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    if intimeInfo and intimeInfo.dungeonScore then
        DebugPrint("Found intimeInfo.dungeonScore: " .. tostring(intimeInfo.dungeonScore))
        return intimeInfo.dungeonScore
    elseif overtimeInfo and overtimeInfo.dungeonScore then
        DebugPrint("Found overtimeInfo.dungeonScore: " .. tostring(overtimeInfo.dungeonScore))
        return overtimeInfo.dungeonScore
    else
        DebugPrint("No valid season best score found for mapID: " .. tostring(mapID))
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

    -- Dungeon rewards
    local dungeonIndex = math.min(keyLevel - 1, #DUNGEON_REWARDS)
    local dungeonReward = DUNGEON_REWARDS[dungeonIndex] or {}
    rewards.dungeonItem = tostring(dungeonReward.itemLevel or "Unknown")
    rewards.dungeonTrack = dungeonReward.upgradeTrack or "Unknown"

    -- Vault rewards
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
        local potentialScore = ScoreFormula(keyLevel)
        local scoreGain = potentialScore - currentScore

        DebugPrint("Key Level: " .. tostring(keyLevel))
        DebugPrint("Potential Score: " .. tostring(potentialScore))
        DebugPrint("Current Score: " .. tostring(currentScore))
        DebugPrint("Score Gain: " .. tostring(scoreGain))

        if not line then
            local rewardLine = string.format("%sGear: %s (%s) / %s (%s)|r",
                                    FONT, rewards.dungeonTrack, rewards.dungeonItem,
                                    rewards.vaultTrack, rewards.vaultItem)
            tooltip:AddLine(rewardLine)
            tooltip:AddLine(string.format("%sCrest: %s (%d)|r", FONT, crest.crestType, crest.crestAmount))
            
            local gainStr = ""
            if scoreGain >= 0 then
                gainStr = string.format(" ( +%d )", scoreGain)
            end
            tooltip:AddLine(string.format("%sMythic+ Score: %d%s|r", FONT, potentialScore, gainStr))
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
        local potentialScore = ScoreFormula(keyLevel)
        local scoreGain = potentialScore - currentScore

        DebugPrint("(Hyperlink) Key Level: " .. tostring(keyLevel))
        DebugPrint("(Hyperlink) Potential Score: " .. tostring(potentialScore))
        DebugPrint("(Hyperlink) Current Score: " .. tostring(currentScore))
        DebugPrint("(Hyperlink) Score Gain: " .. tostring(scoreGain))

        local rewardLine = string.format("%sGear: %s (%s) / %s (%s)|r",
                                FONT, rewards.dungeonTrack, rewards.dungeonItem,
                                rewards.vaultTrack, rewards.vaultItem)
        ItemRefTooltip:AddLine(rewardLine, 1, 1, 1, true)
        ItemRefTooltip:AddLine(string.format("%sCrest: %s (%d)|r", FONT, crest.crestType, crest.crestAmount), 1, 1, 1, true)
        
        local gainStr = ""
        if scoreGain >= 0 then
            gainStr = string.format(" ( +%d )", scoreGain)
        end
        ItemRefTooltip:AddLine(string.format("%sMythic+ Score: %d%s|r", FONT, potentialScore, gainStr), 1, 1, 1, true)
        ItemRefTooltip:Show()
    end
end

-----------------------------
-- Register Tooltip Hooks  --
-----------------------------
GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
hooksecurefunc("ChatFrame_OnHyperlinkShow", SetHyperlink_Hook)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
