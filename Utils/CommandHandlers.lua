--[[
CommandHandlers.lua - Slash Command Processing

Purpose: Handles all slash command functionality for Mr. Mythical addon
Dependencies: RewardsFunctions, CompletionTracker, ConfigData, DungeonData
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.CommandHandlers = {}

local CommandHandlers = MrMythical.CommandHandlers
local RewardsFunctions = MrMythical.RewardsFunctions
local CompletionTracker = MrMythical.CompletionTracker
local ConfigData = MrMythical.ConfigData
local DungeonData = MrMythical.DungeonData

--- Displays mythic keystone rewards UI
function CommandHandlers.handleRewardsCommand()
    if MrMythical.UnifiedUI then
        MrMythical.UnifiedUI:Show("rewards")
    else
        print("Rewards UI not available")
    end
end

--- Displays mythic+ score calculations UI
function CommandHandlers.handleScoreCommand()
    if MrMythical.UnifiedUI then
        MrMythical.UnifiedUI:Show("scores")
    else
        print("Scores UI not available")
    end
end

--- Displays completion statistics for the current season and week
function CommandHandlers.handleStatsCommand()
    if MrMythical.UnifiedUI then
        MrMythical.UnifiedUI:Show("stats")
    else
        print("Stats UI not available")
    end
end

--- Displays the main dashboard UI
function CommandHandlers.handleDashboardCommand()
    if MrMythical.UnifiedUI then
        MrMythical.UnifiedUI:Show("dashboard")
    else
        print("Dashboard UI not available")
    end
end

--- Displays help information for all available commands
function CommandHandlers.handleHelpCommand()
    print(ConfigData.COLORS.GOLD .. "MrMythical Commands:|r")
    print(ConfigData.COLORS.WHITE .. "  /mrm - Open main dashboard")
    print(ConfigData.COLORS.WHITE .. "  /mrm rewards - Open keystone rewards UI")
    print(ConfigData.COLORS.WHITE .. "  /mrm score - Open score calculations UI")
    print(ConfigData.COLORS.WHITE .. "  /mrm stats - Open completion statistics dashboard")
    print(ConfigData.COLORS.WHITE .. "  /mrm times - Open dungeon timers with chest thresholds")
    print(ConfigData.COLORS.WHITE .. "  /mrm help - Show this help message")
end

--- Displays dungeon timers for all dungeons or opens the Times UI
function CommandHandlers.handleTimesCommand()
    if MrMythical.UnifiedUI then
        MrMythical.UnifiedUI:Show("times")
    else
        print("Times UI not available")
    end
end

--- Main command parser and dispatcher
--- @param commandString string The full command string from the user
function CommandHandlers.processSlashCommand(commandString)
    local args = {}
    for word in string.gmatch(commandString, "%S+") do
        table.insert(args, word)
    end
    
    local command = args[1] and args[1]:lower() or "dashboard"

    if command == "rewards" then
        CommandHandlers.handleRewardsCommand()
    elseif command == "score" then
        CommandHandlers.handleScoreCommand()
    elseif command == "stats" then
        CommandHandlers.handleStatsCommand()
    elseif command == "times" then
        CommandHandlers.handleTimesCommand()
    elseif command == "help" then
        CommandHandlers.handleHelpCommand()
    else
        CommandHandlers.handleDashboardCommand()
    end
end
