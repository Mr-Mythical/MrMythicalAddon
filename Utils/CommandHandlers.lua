--[[
CommandHandlers.lua - Slash Command Processing

Purpose: Handles all slash command functionality for Mr. Mythical addon
Dependencies: RewardsFunctions, CompletionTracker, ConfigData, DungeonData
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.CommandHandlers = {}

local CommandHandlers = MrMythical.CommandHandlers
local ConfigData = MrMythical.ConfigData

-- Maps command names to their UnifiedUI content types
local UI_COMMANDS = {
    rewards = "rewards",
    score = "scores",
    stats = "stats",
    dashboard = "dashboard",
    times = "times",
}

local function showUIContent(contentType)
    if MrMythical.UnifiedUI then
        MrMythical.UnifiedUI:Show(contentType)
    else
        print(contentType:sub(1,1):upper() .. contentType:sub(2) .. " UI not available")
    end
end

function CommandHandlers.handleHelpCommand()
    print(ConfigData.COLORS.GOLD .. "MrMythical Commands:|r")
    print(ConfigData.COLORS.WHITE .. "  /mrm - Open main dashboard")
    print(ConfigData.COLORS.WHITE .. "  /mrm rewards - Open keystone rewards UI")
    print(ConfigData.COLORS.WHITE .. "  /mrm score - Open score calculations UI")
    print(ConfigData.COLORS.WHITE .. "  /mrm stats - Open completion statistics dashboard")
    print(ConfigData.COLORS.WHITE .. "  /mrm times - Open dungeon timers with chest thresholds")
    print(ConfigData.COLORS.WHITE .. "  /mrm settings - Open addon settings panel")
    print(ConfigData.COLORS.WHITE .. "  /mrm help - Show this help message")
end

function CommandHandlers.handleSettingsCommand()
    if MrMythical.Options then
        MrMythical.Options.openSettings()
    else
        print("Settings not available")
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

    if command == "settings" or command == "config" or command == "options" then
        CommandHandlers.handleSettingsCommand()
    elseif command == "help" then
        CommandHandlers.handleHelpCommand()
    else
        local contentType = UI_COMMANDS[command] or "dashboard"
        showUIContent(contentType)
    end
end
