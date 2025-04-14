RewardsFunctions = {}
local RewardsData = RewardsData

function RewardsFunctions.GetRewardsForKeyLevel(keyLevel)
    local rewards = {}
    if not keyLevel or keyLevel < 2 then
        rewards.dungeonItem = "Unknown"
        rewards.dungeonTrack = "Unknown"
        rewards.vaultItem = "Unknown"
        rewards.vaultTrack = "Unknown"
        return rewards
    end

    local dungeonIndex = math.min(keyLevel - 1, #RewardsData.DUNGEON_GEAR)
    local dungeonReward = RewardsData.DUNGEON_GEAR[dungeonIndex] or {}
    rewards.dungeonItem = tostring(dungeonReward.itemLevel or "Unknown")
    rewards.dungeonTrack = dungeonReward.upgradeTrack or "Unknown"

    local vaultIndex = math.min(keyLevel - 1, #RewardsData.VAULT_GEAR)
    local vaultReward = RewardsData.VAULT_GEAR[vaultIndex] or {}
    rewards.vaultItem = tostring(vaultReward.itemLevel or "Unknown")
    rewards.vaultTrack = vaultReward.upgradeTrack or "Unknown"

    return rewards
end

function RewardsFunctions.GetCrestReward(keyLevel)
    local crest = {}
    if not keyLevel or keyLevel < 2 or keyLevel > #RewardsData.CRESTS + 1 then
        crest.crestType = "Unknown"
        crest.crestAmount = "Unknown"
        return crest
    end

    local crestReward = RewardsData.CRESTS[keyLevel - 1] or {}
    crest.crestType = crestReward.crestType or "Unknown"
    crest.crestAmount = crestReward.amount or "Unknown"
    return crest
end

function RewardsFunctions.ScoreFormula(keyLevel)
    if keyLevel < 2 then return 0 end
    local affixBreakpoints = { [4] = 15, [7] = 15, [10] = 15, [12] = 15 }
    local parScore = 155
    for current = 2, keyLevel - 1 do
        parScore = parScore + 15
        local nextLevel = current + 1
        if affixBreakpoints[nextLevel] then
            parScore = parScore + affixBreakpoints[nextLevel]
        end
    end
    return parScore
end

return RewardsFunctions