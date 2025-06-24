local MrMythical = MrMythical or {}
MrMythical.CommandHandlers = {}

local CommandHandlers = MrMythical.CommandHandlers
local RewardsFunctions = MrMythical.RewardsFunctions
local CompletionTracker = MrMythical.CompletionTracker
local ConfigData = MrMythical.ConfigData
local DungeonData = MrMythical.DungeonData

--- Displays mythic keystone rewards for a specific level or all levels
--- @param keyLevel number|nil Specific key level to show, or nil for all levels
function CommandHandlers.handleRewardsCommand(keyLevel)
    if keyLevel then
        local rewards = RewardsFunctions.getRewardsForKeyLevel(keyLevel)
        local crest = RewardsFunctions.getCrestReward(keyLevel)
        local rewardLine = string.format("Key Level %d: %s (%s) / %s (%s) | %s (%s)",
            keyLevel, rewards.dungeonTrack, rewards.dungeonItem,
            rewards.vaultTrack, rewards.vaultItem,
            crest.crestType, crest.crestAmount)
        print(rewardLine)
    else
        print("Mythic Keystone Rewards by Key Level:")
        for level = 2, 12 do
            local rewards = RewardsFunctions.getRewardsForKeyLevel(level)
            local crest = RewardsFunctions.getCrestReward(level)
            local rewardLine = string.format("Key Level %d: %s (%s) / %s (%s) | %s (%s)",
                level, rewards.dungeonTrack, rewards.dungeonItem,
                rewards.vaultTrack, rewards.vaultItem,
                crest.crestType, crest.crestAmount)
            print(rewardLine)
        end
    end
end

--- Displays mythic+ score calculations and potential gains for a key level
--- @param keyLevel number The keystone level to calculate scores for
function CommandHandlers.handleScoreCommand(keyLevel)
    if not keyLevel then
        print("Usage: /mrm score <keystone level>")
        return
    end
    
    local potentialScore = RewardsFunctions.scoreFormula(keyLevel)
    print(string.format("Potential Mythic+ Score for keystone level %d is %d", keyLevel, potentialScore))
    
    local dungeonGains = {}
    
    for _, mapInfo in ipairs(DungeonData.MYTHIC_MAPS) do
        local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapInfo.id)
        local currentScore = 0
        
        if intimeInfo and intimeInfo.dungeonScore then
            currentScore = intimeInfo.dungeonScore
        elseif overtimeInfo and overtimeInfo.dungeonScore then
            currentScore = overtimeInfo.dungeonScore
        end
        
        local scoreGain = potentialScore - currentScore
        table.insert(dungeonGains, { 
            name = mapInfo.name, 
            gain = scoreGain, 
            current = currentScore 
        })
    end
    
    -- Sort by potential gain (highest first)
    table.sort(dungeonGains, function(a, b) return a.gain > b.gain end)
    
    for _, mapGain in ipairs(dungeonGains) do
        if mapGain.gain > 0 then
            print(string.format("%s: +%d (current: %d)", mapGain.name, mapGain.gain, mapGain.current))
        else
            print(string.format("%s: No gain (current: %d)", mapGain.name, mapGain.current))
        end
    end
end

--- Displays completion statistics for the current season and week
function CommandHandlers.handleStatsCommand()
    print(ConfigData.COLORS.GOLD .. "=== Mythic+ Completion Statistics ===" .. "|r")
    
    local stats = CompletionTracker:getStats()
    local seasonTotal = stats.seasonal.completed + stats.seasonal.failed
    
    -- Season overview
    print("\n" .. ConfigData.COLORS.GREEN .. "Season Overview:|r")
    print(ConfigData.COLORS.WHITE .. string.format("Total Runs: %d", seasonTotal))
    print(ConfigData.COLORS.WHITE .. string.format("Completed: %d (%d%%)", 
        stats.seasonal.completed, stats.seasonal.rate))
    print(ConfigData.COLORS.RED .. string.format("Failed: %d (%d%%)", 
        stats.seasonal.failed, 100 - stats.seasonal.rate))
    
    -- Weekly overview
    local weeklyTotal = stats.weekly.completed + stats.weekly.failed
    print("\n" .. ConfigData.COLORS.GREEN .. "This Week:|r")
    print(ConfigData.COLORS.WHITE .. string.format("Total Runs: %d", weeklyTotal))
    print(ConfigData.COLORS.WHITE .. string.format("Completed: %d (%d%%)", 
        stats.weekly.completed, stats.weekly.rate))
    print(ConfigData.COLORS.RED .. string.format("Failed: %d (%d%%)", 
        stats.weekly.failed, 100 - stats.weekly.rate))
    
    -- Weekly dungeon breakdown
    if weeklyTotal > 0 then
        print("\n|cff00ff00Weekly Dungeon Breakdown:|r")
        for _, dungeon in pairs(stats.weekly.dungeons) do
            local dungeonTotal = dungeon.completed + dungeon.failed
            if dungeonTotal > 0 then
                print(string.format("|cffffffff%s|r", dungeon.name))
                print(string.format("  Completed: %d, Failed: %d (Success Rate: %d%%)", 
                    dungeon.completed, dungeon.failed, dungeon.rate))
            end
        end
    end
end

--- Handles the reset command for completion statistics
--- @param scope string The scope to reset: "all", "weekly", or "seasonal"
function CommandHandlers.handleResetCommand(scope)
    scope = scope and scope:lower() or "all"
    
    if scope == "all" or scope == "weekly" or scope == "seasonal" then
        CompletionTracker:resetStats(scope)
    else
        print("Usage: /mrm reset [all|weekly|seasonal]")
    end
end

--- Displays help information for all available commands
function CommandHandlers.handleHelpCommand()
    print(ConfigData.COLORS.GOLD .. "MrMythical Commands:|r")
    print(ConfigData.COLORS.WHITE .. "  /mrm rewards [level] - Show keystone rewards for specific level or all levels")
    print(ConfigData.COLORS.WHITE .. "  /mrm score <level> - Show score calculations and potential gains for a key level")
    print(ConfigData.COLORS.WHITE .. "  /mrm stats - Show completion statistics for season and week")
    print(ConfigData.COLORS.WHITE .. "  /mrm reset [scope] - Reset completion statistics (all/weekly/seasonal)")
    print(ConfigData.COLORS.WHITE .. "  /mrm help - Show this help message")
end

--- Main command parser and dispatcher
--- @param commandString string The full command string from the user
function CommandHandlers.processSlashCommand(commandString)
    local args = {}
    for word in string.gmatch(commandString, "%S+") do
        table.insert(args, word)
    end
    
    local command = args[1] and args[1]:lower() or "help"
    
    if command == "rewards" then
        local level = args[2] and tonumber(args[2])
        CommandHandlers.handleRewardsCommand(level)
    elseif command == "score" then
        local level = args[2] and tonumber(args[2])
        CommandHandlers.handleScoreCommand(level)
    elseif command == "stats" then
        CommandHandlers.handleStatsCommand()
    elseif command == "reset" then
        local scope = args[2]
        CommandHandlers.handleResetCommand(scope)
    else
        CommandHandlers.handleHelpCommand()
    end
end
