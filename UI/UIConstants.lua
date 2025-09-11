--[[
UIConstants.lua - UI Constants and Configuration

Centralized constants for UI layout, colors, and sizing.
--]]

local MrMythical = MrMythical or {}
MrMythical.UIConstants = {}

local UIConstants = MrMythical.UIConstants

UIConstants.FRAME = {
    WIDTH = 850,
    HEIGHT = 500,
    NAV_PANEL_WIDTH = 140,
    CONTENT_WIDTH = 680,
}

UIConstants.LAYOUT = {
    ROW_HEIGHT = 25,
    LARGE_ROW_HEIGHT = 30,
    BUTTON_HEIGHT = 30,
    PADDING = 10,
    LARGE_PADDING = 20,
}

UIConstants.COLORS = {
    EVEN_ROW = {r = 0.1, g = 0.1, b = 0.1, a = 0.3},
    ODD_ROW = {r = 0.15, g = 0.15, b = 0.15, a = 0.3},
    SUCCESS_HIGH = {r = 0, g = 1, b = 0},
    SUCCESS_MEDIUM = {r = 1, g = 1, b = 0},
    SUCCESS_LOW = {r = 1, g = 0, b = 0},
    DISABLED = {r = 0.5, g = 0.5, b = 0.5},
    INFO_TEXT = {r = 0.8, g = 0.8, b = 0.8},
    NAV_BACKGROUND = {r = 0.1, g = 0.1, b = 0.1, a = 0.8}
}

UIConstants.CONTENT_TYPES = {
    DASHBOARD = "dashboard",
    REWARDS = "rewards",
    SCORES = "scores",
    STATS = "stats",
    TIMES = "times",
    SETTINGS = "settings"
}

return UIConstants
