--[[
Options.lua - Mr. Mythical Keystone Tooltips Options Panel

Purpose: Manages settings panel and global registry for Mr. Mythical addons
Dependencies: ConfigData
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
local ConfigData = MrMythical.ConfigData

local Options = {}

-- Configuration data
local DEFAULTS = {
    HIDE_UNWANTED_TEXT = true,
    HIDE_AFFIX_TEXT = false,
    HIDE_DURATION = false,
    SHOW_TIMING = true,
    TIMER_DISPLAY_MODE = "NONE",
    PLAIN_SCORE_COLORS = false,
    LEVEL_DISPLAY = "OFF",
    LEVEL_SHIFT_MODE = "NONE",
    SHORT_TITLE = false,
    SHORT_DUNGEON_NAMES = "OFF",
    PLAYER_BEST_DISPLAY = "WITH_SCORE",
    REWARDS_DISPLAY = "SHOW",
    HIDE_REWARD_NUMBERS = false,
    GEAR_REWARD_DISPLAY = "SHOW",
    VAULT_REWARD_DISPLAY = "SHOW",
    CREST_REWARD_DISPLAY = "SHOW",
    REWARD_LINE_STYLE = "TWO_LINES",
    TIMER_LABEL_STYLE = "FULL",
    REVEAL_MODIFIER = "SHIFT",
    SCORE_DISPLAY = "SHOW",
    SHOW_SCORE_GAIN = true,
    GROUP_SCORE_DISPLAY = "SHIFT_DETAILS",
    UNIFIED_FRAME_POINT = "CENTER",
    UNIFIED_FRAME_RELATIVE_POINT = "CENTER",
    UNIFIED_FRAME_X = 0,
    UNIFIED_FRAME_Y = 0
}

local DROPDOWN_OPTIONS = {
    LEVEL_DISPLAY = {
        { text = "Default",      value = "OFF" },
        { text = "Compact (+X)", value = "COMPACT" },
        { text = "In Title",     value = "TITLE" }
    },
    LEVEL_SHIFT_MODE = {
        { text = "None",           value = "NONE" },
        { text = "Show Resilient", value = "SHOW_RESILIENT" },
        { text = "Show Both",      value = "SHOW_BOTH" }
    },
    TIMER_DISPLAY_MODE = {
        { text = "None",                 value = "NONE" },
        { text = "Dungeon Timer",        value = "DUNGEON" },
        { text = "Upgrade Timers",       value = "UPGRADE" },
        { text = "Hold Modifier to Show", value = "SHIFT" }
    },
    PLAYER_BEST_DISPLAY = {
        { text = "None",                  value = "NONE" },
        { text = "Without Score",         value = "WITHOUT_SCORE" },
        { text = "With Score",            value = "WITH_SCORE" },
        { text = "Hold Modifier to Show", value = "SHIFT_WITH_SCORE" }
    },
    SHORT_DUNGEON_NAMES = {
        { text = "Full Name",       value = "OFF" },
        { text = "Short Only",      value = "SHORT" },
        { text = "Short - Full",    value = "SHORT_FULL" }
    },
    REWARDS_DISPLAY = {
        { text = "Hide",                  value = "HIDE" },
        { text = "Always Show",           value = "SHOW" },
        { text = "Hold Modifier to Show", value = "SHIFT" }
    },
    GEAR_REWARD_DISPLAY = {
        { text = "Hide",                  value = "HIDE" },
        { text = "Always Show",           value = "SHOW" },
        { text = "Hold Modifier to Show", value = "SHIFT" }
    },
    VAULT_REWARD_DISPLAY = {
        { text = "Hide",                  value = "HIDE" },
        { text = "Always Show",           value = "SHOW" },
        { text = "Hold Modifier to Show", value = "SHIFT" }
    },
    CREST_REWARD_DISPLAY = {
        { text = "Hide",                  value = "HIDE" },
        { text = "Always Show",           value = "SHOW" },
        { text = "Hold Modifier to Show", value = "SHIFT" }
    },
    REWARD_LINE_STYLE = {
        { text = "Two Lines",   value = "TWO_LINES" },
        { text = "Single Line", value = "SINGLE_LINE" },
        { text = "Compact",     value = "COMPACT" }
    },
    TIMER_LABEL_STYLE = {
        { text = "Full (Dungeon Timer)", value = "FULL" },
        { text = "Short (Timer)",        value = "SHORT" },
        { text = "Times Only",           value = "TIMES_ONLY" }
    },
    REVEAL_MODIFIER = {
        { text = "Shift",   value = "SHIFT" },
        { text = "Alt",     value = "ALT" },
        { text = "Control", value = "CTRL" }
    },
    SCORE_DISPLAY = {
        { text = "Hide",                  value = "HIDE" },
        { text = "Always Show",           value = "SHOW" },
        { text = "Hold Modifier to Show", value = "SHIFT" }
    },
    GROUP_SCORE_DISPLAY = {
        { text = "Hide",                    value = "HIDE" },
        { text = "Average Only",            value = "AVERAGE" },
        { text = "Modifier for Details",    value = "SHIFT_DETAILS" }
    }
}

local WHITE = ConfigData and ConfigData.COLORS and ConfigData.COLORS.WHITE or ""

local TOOLTIPS = {
    LEVEL_DISPLAY = "Choose how the mythic keystone level is displayed:\n\n" ..
        WHITE .. "Default:|r Show level in its own line (e.g. 'Mythic Level 15')\n\n" ..
        WHITE .. "Compact:|r Show level as +X (e.g. '+15')\n\n" ..
        WHITE .. "In Title:|r Add level to keystone title (e.g. 'Windrunner Spire +15')",

    LEVEL_SHIFT_MODE = "Choose how holding the reveal modifier affects level display (Mythic & Resilient):\n\n" ..
        WHITE .. "None:|r Show both levels always\n\n" ..
        WHITE .. "Show Resilient:|r Show only Mythic level, hold the reveal modifier for Resilient\n\n" ..
        WHITE .. "Show Both:|r Hide levels, hold the reveal modifier to show both",

    TIMER_DISPLAY_MODE = "Choose which timer(s) to display in the keystone tooltip:\n\n" ..
        WHITE .. "None:|r No timer\n" ..
        WHITE .. "Dungeon Timer:|r Show only the dungeon timer\n" ..
        WHITE .. "Upgrade Timers:|r Show +2/+3 upgrade timers and the dungeon timer on one line\n" ..
        WHITE .. "Hold Modifier to Show:|r Hold the reveal modifier to show upgrade timers",

    PLAYER_BEST_DISPLAY = "Choose how to display your personal best run for this dungeon:\n\n" ..
        WHITE .. "None:|r Don't show personal best information\n" ..
        WHITE .. "Without Score:|r Show level, time, and upgrades only\n" ..
        WHITE .. "With Score:|r Show level, time, upgrades, and score\n" ..
        WHITE .. "Hold Modifier to Show:|r Hold the reveal modifier to show personal best with score",

    REWARDS_DISPLAY = "Master control for all reward lines. When hidden or gated by the reveal modifier, individual gear/vault/crest settings are ignored.\n\n" ..
        WHITE .. "Hide:|r Don't show any reward information\n" ..
        WHITE .. "Always Show:|r Allow individual reward settings to apply\n" ..
        WHITE .. "Hold Modifier to Show:|r Hold the reveal modifier to show rewards (then apply individual settings)",

    GEAR_REWARD_DISPLAY = "Choose how to display dungeon gear rewards:\n\n" ..
        WHITE .. "Hide:|r Don't show gear reward information\n" ..
        WHITE .. "Always Show:|r Always display gear rewards\n" ..
        WHITE .. "Hold Modifier to Show:|r Hold the reveal modifier to show gear rewards",

    VAULT_REWARD_DISPLAY = "Choose how to display Great Vault rewards:\n\n" ..
        WHITE .. "Hide:|r Don't show vault reward information\n" ..
        WHITE .. "Always Show:|r Always display vault rewards\n" ..
        WHITE .. "Hold Modifier to Show:|r Hold the reveal modifier to show vault rewards",

    CREST_REWARD_DISPLAY = "Choose how to display crest rewards:\n\n" ..
        WHITE .. "Hide:|r Don't show crest reward information\n" ..
        WHITE .. "Always Show:|r Always display crest rewards\n" ..
        WHITE .. "Hold Modifier to Show:|r Hold the reveal modifier to show crest rewards",

    REWARD_LINE_STYLE = "Choose how reward information is laid out:\n\n" ..
        WHITE .. "Two Lines:|r Gear and vault on one line, crest on a second line\n" ..
        WHITE .. "Single Line:|r All visible rewards on one line\n" ..
        WHITE .. "Compact:|r Abbreviated labels (G/V/C) on one line",

    TIMER_LABEL_STYLE = "Choose how timer labels are written:\n\n" ..
        WHITE .. "Full:|r 'Dungeon Timer: 30:00'\n" ..
        WHITE .. "Short:|r 'Timer: 30:00'\n" ..
        WHITE .. "Times Only:|r '30:00' with no label",

    REVEAL_MODIFIER = "Choose which key reveals gated tooltip details (levels, rewards, score, group breakdown, etc.).\n\n" ..
        WHITE .. "Shift:|r Hold Shift to reveal\n" ..
        WHITE .. "Alt:|r Hold Alt to reveal\n" ..
        WHITE .. "Control:|r Hold Control to reveal",

    SCORE_DISPLAY = "Choose how to display the potential score line:\n\n" ..
        WHITE .. "Hide:|r Don't show score information\n" ..
        WHITE .. "Always Show:|r Always display the score line\n" ..
        WHITE .. "Hold Modifier to Show:|r Hold the reveal modifier to show score information",

    GROUP_SCORE_DISPLAY = "Choose how to display group score information in parties:\n\n" ..
        WHITE .. "Hide:|r Don't show group score information\n" ..
        WHITE .. "Average Only:|r Show average party gain only\n" ..
        WHITE .. "Modifier for Details:|r Show average by default, hold the reveal modifier for per-player breakdown",

    HIDE_REWARD_NUMBERS = "Hide the numeric values (item level and crest amount) from reward displays, showing only the reward type names."
}

--- Creates a setting with appropriate UI element
--- @param category table The settings category to add to
--- @param name string Display name for the setting
--- @param key string Saved variable key name
--- @param settingType string "boolean" or "string"
--- @param tooltip string Tooltip text for the setting
--- @param options? table For dropdown settings only
--- @return table Table containing setting and initializer
local function createSetting(category, name, key, settingType, tooltip, options)
    local defaultValue = DEFAULTS[key]
    local setting = Settings.RegisterAddOnSetting(category, name, key, MRM_SavedVars, settingType, name, defaultValue)
    setting:SetValueChangedCallback(function(_, value)
        MRM_SavedVars[key] = value
    end)

    local initializer
    if settingType == "boolean" then
        initializer = Settings.CreateCheckbox(category, setting, tooltip)
    else -- dropdown
        local function getOptions()
            -- Fallback: build menu entries compatible with Blizzard_Menu on older clients.
            local dropdownOptions = {}
            local menuRadio = (_G.MenuButtonType and _G.MenuButtonType.Radio)
                or (_G.Enum and Enum.MenuItemType and Enum.MenuItemType.Radio)
                or 1                    -- numeric fallback commonly used for Radio
            for _, option in ipairs(options) do
                table.insert(dropdownOptions, {
                    text = option.text,
                    label = option.text,
                    value = option.value,
                    controlType = menuRadio,
                    -- Mark selected state and provide a handler to update the setting.
                    checked = function() return setting:GetValue() == option.value end,
                    func = function() setting:SetValue(option.value) end,
                })
            end
            return dropdownOptions
        end
        initializer = Settings.CreateDropdown(category, setting, getOptions, tooltip)
    end

    initializer:SetSetting(setting)
    return { setting = setting, initializer = initializer }
end

--- Initializes saved variables with default values and sets up settings UI
function Options.initializeSettings()
    MRM_SavedVars = MRM_SavedVars or {}
    -- Set defaults for any missing values
    for key, default in pairs(DEFAULTS) do
        if MRM_SavedVars[key] == nil then
            MRM_SavedVars[key] = default
        end
    end
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        return
    end

    local success = pcall(Options.createSettingsStructure)
    if not success then
        C_Timer.After(0.1, function()
            pcall(Options.createSettingsStructure)
        end)
    end
end

--- Creates the settings category structure and integrates with global registry
function Options.createSettingsStructure()
    -- Initialize the global registry if it doesn't exist
    if not _G.MrMythicalSettingsRegistry then
        _G.MrMythicalSettingsRegistry = {}
    end

    local registry = _G.MrMythicalSettingsRegistry
    local parentCategory = nil

    -- Check if another addon already created the parent category
    if registry.parentCategory then
        parentCategory = registry.parentCategory
    else
        -- We need to create the parent category
        local success, result = pcall(function()
            return Settings.RegisterVerticalLayoutCategory("Mr. Mythical")
        end)

        if success and result then
            parentCategory = result
            registry.parentCategory = parentCategory
            registry.createdBy = "MrMythical"

            Settings.RegisterAddOnCategory(parentCategory)
        else
            -- Fallback to standalone category
            local fallbackSuccess, fallbackResult = pcall(function()
                return Settings.RegisterVerticalLayoutCategory("Mr. Mythical: Keystone Tooltips")
            end)
            if fallbackSuccess and fallbackResult then
                parentCategory = fallbackResult
                Settings.RegisterAddOnCategory(parentCategory)
                local category = parentCategory
                Options.createSettingsInCategory(category)
                return
            else
                return
            end
        end
    end

    -- Create our subcategory under the parent (using WoW-native subcategory method)
    local category

    -- Try the native subcategory registration method first
    local subcategorySuccess, subcategoryResult = pcall(function()
        return Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Keystone Tooltips")
    end)

    if subcategorySuccess and subcategoryResult then
        category = subcategoryResult

        registry.subCategories = registry.subCategories or {}
        registry.subCategories["KeystoneTooltips"] = category
    else
        -- Fallback to the manual SetParentCategory method
        local altSuccess, altResult = pcall(function()
            local subCat = Settings.RegisterVerticalLayoutCategory("Keystone Tooltips")
            subCat:SetParentCategory(parentCategory)
            return subCat
        end)

        if altSuccess and altResult then
            category = altResult
            registry.subCategories = registry.subCategories or {}
            registry.subCategories["KeystoneTooltips"] = category
        else
            category = parentCategory
        end
    end

    Options.createSettingsInCategory(category)
end

--- Creates all the settings in the specified category
--- @param category table The settings category to add settings to
function Options.createSettingsInCategory(category)
    local layout = SettingsPanel:GetLayout(category)

    -- Helper function to add section header
    local function addHeader(name, tooltip)
        local headerData = { name = name, tooltip = tooltip }
        local headerInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", headerData)
        layout:AddInitializer(headerInitializer)
    end

    local settingsConfig = {
        {
            header = { name = "Modifier Options", tooltip = "Choose which key reveals gated tooltip details" },
            settings = {
                {
                    name = "Reveal Modifier",
                    key = "REVEAL_MODIFIER",
                    type = "string",
                    tooltip = TOOLTIPS.REVEAL_MODIFIER,
                    options = DROPDOWN_OPTIONS.REVEAL_MODIFIER
                }
            }
        },
        {
            header = { name = "Compact Mode Options", tooltip = "Settings that affect the appearance of keystone tooltips" },
            settings = {
                {
                    name = "Hide Common Text",
                    key = "HIDE_UNWANTED_TEXT",
                    type = "boolean",
                    tooltip = "Hide common item text like 'Soulbound' and 'Unique' from keystone tooltips."
                },
                {
                    name = "Hide Affix Text",
                    key = "HIDE_AFFIX_TEXT",
                    type = "boolean",
                    tooltip = "Hide the lines listing the current dungeon affixes."
                },
                {
                    name = "Hide Duration Text",
                    key = "HIDE_DURATION",
                    type = "boolean",
                    tooltip = "Hide the duration line from keystone tooltips."
                },
                {
                    name = "Level Display Style",
                    key = "LEVEL_DISPLAY",
                    type = "string",
                    tooltip = TOOLTIPS.LEVEL_DISPLAY,
                    options = DROPDOWN_OPTIONS.LEVEL_DISPLAY
                },
                {
                    name = "Reveal Modifier Behavior for Levels",
                    key = "LEVEL_SHIFT_MODE",
                    type = "string",
                    tooltip = TOOLTIPS.LEVEL_SHIFT_MODE,
                    options = DROPDOWN_OPTIONS.LEVEL_SHIFT_MODE
                },
                {
                    name = "Short Keystone Title",
                    key = "SHORT_TITLE",
                    type = "boolean",
                    tooltip = "Remove 'Keystone:' from keystone titles"
                },
                {
                    name = "Short Dungeon Names",
                    key = "SHORT_DUNGEON_NAMES",
                    type = "string",
                    tooltip = "How to display dungeon names in keystone titles",
                    options = DROPDOWN_OPTIONS.SHORT_DUNGEON_NAMES
                }
            }
        },
        {
            header = { name = "Display Options", tooltip = "Settings that affect score and timing display" },
            settings = {
                {
                    name = "Show Score Timing Bonus",
                    key = "SHOW_TIMING",
                    type = "boolean",
                    tooltip = "Show the potential timing bonus (0-15)."
                },
                {
                    name = "Score Display",
                    key = "SCORE_DISPLAY",
                    type = "string",
                    tooltip = TOOLTIPS.SCORE_DISPLAY,
                    options = DROPDOWN_OPTIONS.SCORE_DISPLAY
                },
                {
                    name = "Show Score Gain",
                    key = "SHOW_SCORE_GAIN",
                    type = "boolean",
                    tooltip = "Show your personal score gain alongside the score line."
                },
                {
                    name = "Group Score Display",
                    key = "GROUP_SCORE_DISPLAY",
                    type = "string",
                    tooltip = TOOLTIPS.GROUP_SCORE_DISPLAY,
                    options = DROPDOWN_OPTIONS.GROUP_SCORE_DISPLAY
                },
                {
                    name = "Timer Display",
                    key = "TIMER_DISPLAY_MODE",
                    type = "string",
                    tooltip = TOOLTIPS.TIMER_DISPLAY_MODE,
                    options = DROPDOWN_OPTIONS.TIMER_DISPLAY_MODE
                },
                {
                    name = "Timer Label Style",
                    key = "TIMER_LABEL_STYLE",
                    type = "string",
                    tooltip = TOOLTIPS.TIMER_LABEL_STYLE,
                    options = DROPDOWN_OPTIONS.TIMER_LABEL_STYLE
                },
                {
                    name = "Player Best Display",
                    key = "PLAYER_BEST_DISPLAY",
                    type = "string",
                    tooltip = TOOLTIPS.PLAYER_BEST_DISPLAY,
                    options = DROPDOWN_OPTIONS.PLAYER_BEST_DISPLAY
                },
                {
                    name = "Remove Score Colors",
                    key = "PLAIN_SCORE_COLORS",
                    type = "boolean",
                    tooltip = "Display score and score gains in white instead of gradient colors."
                }
            }
        },
        {
            header = { name = "Rewards Options", tooltip = "Settings that control gear, vault, and crest reward lines" },
            settings = {
                {
                    name = "Rewards Display",
                    key = "REWARDS_DISPLAY",
                    type = "string",
                    tooltip = TOOLTIPS.REWARDS_DISPLAY,
                    options = DROPDOWN_OPTIONS.REWARDS_DISPLAY
                },
                {
                    name = "Gear Reward Display",
                    key = "GEAR_REWARD_DISPLAY",
                    type = "string",
                    tooltip = TOOLTIPS.GEAR_REWARD_DISPLAY,
                    options = DROPDOWN_OPTIONS.GEAR_REWARD_DISPLAY
                },
                {
                    name = "Vault Reward Display",
                    key = "VAULT_REWARD_DISPLAY",
                    type = "string",
                    tooltip = TOOLTIPS.VAULT_REWARD_DISPLAY,
                    options = DROPDOWN_OPTIONS.VAULT_REWARD_DISPLAY
                },
                {
                    name = "Crest Reward Display",
                    key = "CREST_REWARD_DISPLAY",
                    type = "string",
                    tooltip = TOOLTIPS.CREST_REWARD_DISPLAY,
                    options = DROPDOWN_OPTIONS.CREST_REWARD_DISPLAY
                },
                {
                    name = "Reward Line Style",
                    key = "REWARD_LINE_STYLE",
                    type = "string",
                    tooltip = TOOLTIPS.REWARD_LINE_STYLE,
                    options = DROPDOWN_OPTIONS.REWARD_LINE_STYLE
                },
                {
                    name = "Hide Reward Numbers",
                    key = "HIDE_REWARD_NUMBERS",
                    type = "boolean",
                    tooltip = TOOLTIPS.HIDE_REWARD_NUMBERS
                }
            }
        }
    }

    -- Create all settings
    for _, section in ipairs(settingsConfig) do
        if section.header then
            addHeader(section.header.name, section.header.tooltip)
        end

        for _, setting in ipairs(section.settings) do
            createSetting(category, setting.name, setting.key, setting.type, setting.tooltip, setting.options)
        end
    end
end

--- Integration utility functions for other addons
--- @return table Information about the integration status and parent category
function Options.getIntegrationInfo()
    local registry = _G.MrMythicalSettingsRegistry
    if not registry then
        return {
            integrated = false,
            parentExists = false,
            createdBy = nil,
            parentName = nil
        }
    end

    return {
        integrated = registry.parentCategory ~= nil,
        parentExists = registry.parentCategory ~= nil,
        createdBy = registry.createdBy,
        parentName = registry.parentCategory and "Mr. Mythical" or nil
    }
end

function Options.openSettings()
    local registry = _G.MrMythicalSettingsRegistry
    if registry and registry.parentCategory then
        Settings.OpenToCategory(registry.parentCategory:GetID())
    else
        SettingsPanel:Open()
    end
end

MrMythical.Options = Options
_G.MrMythical = MrMythical
