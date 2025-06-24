local MrMythical = MrMythical or {}
local RewardsData = MrMythical.RewardsData

local RewardsFunctions = {}

function RewardsFunctions.getRewardsForKeyLevel(keyLevel)
    if not keyLevel or keyLevel < 2 then
        return {
            dungeonItem = "Unknown",
            dungeonTrack = "Unknown",
            vaultItem = "Unknown",
            vaultTrack = "Unknown"
        }
    end

    local dungeonIndex = math.min(keyLevel - 1, #RewardsData.DUNGEON_GEAR)
    local dungeonReward = RewardsData.DUNGEON_GEAR[dungeonIndex] or {}
    local vaultIndex = math.min(keyLevel - 1, #RewardsData.VAULT_GEAR)
    local vaultReward = RewardsData.VAULT_GEAR[vaultIndex] or {}

    return {
        dungeonItem = tostring(dungeonReward.itemLevel or "Unknown"),
        dungeonTrack = dungeonReward.upgradeTrack or "Unknown",
        vaultItem = tostring(vaultReward.itemLevel or "Unknown"),
        vaultTrack = vaultReward.upgradeTrack or "Unknown"
    }
end

function RewardsFunctions.getCrestReward(keyLevel)
    if not keyLevel or keyLevel < 2 then
        return { crestType = "Unknown", crestAmount = "Unknown" }
    end

    local crestIndex = math.min(keyLevel - 1, #RewardsData.CRESTS)
    local crestReward = RewardsData.CRESTS[crestIndex] or {}
    return {
        crestType = crestReward.crestType or "Unknown",
        crestAmount = crestReward.amount or "Unknown"
    }
end

function RewardsFunctions.scoreFormula(keyLevel)
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

MrMythical.RewardsFunctions = RewardsFunctions
_G.MrMythical = MrMythical