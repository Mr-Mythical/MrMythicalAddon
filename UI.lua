local function CreateSetting(category, name, key, defaultValue, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, name, key, MRM_SavedVars, "boolean", name, defaultValue)
    setting:SetValueChangedCallback(function(_, value)
        MRM_SavedVars[key] = value
    end)
    
    local initializer = Settings.CreateCheckbox(category, setting, tooltip)
    initializer:SetSetting(setting)
    
    return {setting = setting, checkbox = initializer}
end

local function InitializeSettings()
    local defaults = {
        HIDE_UNWANTED_TEXT = true,
        HIDE_AFFIX_TEXT = false,
        HIDE_DURATION = false,
        SHOW_TIMING = true,
        PLAIN_SCORE_COLORS = false,
        COMPACT_LEVEL = false,
        SHORT_TITLE = false
    }
    
    MRM_SavedVars = MRM_SavedVars or {}
    for key, default in pairs(defaults) do
        if MRM_SavedVars[key] == nil then
            MRM_SavedVars[key] = default
        end
    end

    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        print("MrMythical: Settings API not found. Options unavailable via Interface menu.")
        return
    end

    local category = Settings.RegisterVerticalLayoutCategory("Mr. Mythical", "MrMythical")

    local headerData = {
        name = "Compact Mode Options",
        tooltip = "Settings that affect the appearance of keystone tooltips"
    }
    local headerInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", headerData)
    local layout = SettingsPanel:GetLayout(category)
    layout:AddInitializer(headerInitializer)

    CreateSetting(
        category,
        "Hide Common Text",
        "HIDE_UNWANTED_TEXT",
        true,
        "Hide common item text like 'Soulbound' and 'Unique' from keystone tooltips."
    )

    CreateSetting(
        category,
        "Hide Affix Text",
        "HIDE_AFFIX_TEXT",
        false,
        "Hide the lines listing the current dungeon affixes."
    )

    CreateSetting(
        category,
        "Hide Duration Text", 
        "HIDE_DURATION",
        false,
        "Hide the duration line from keystone tooltips."
    )

    CreateSetting(
        category,
        "Compact Level Display",
        "COMPACT_LEVEL", 
        false,
        "Change 'Mythic Level X' to '+X'"
    )

    CreateSetting(
        category,
        "Short Keystone Title",
        "SHORT_TITLE",
        false,
        "Remove 'Keystone:' from keystone titles"
    )

    local displayHeaderData = {
        name = "Display Options",
        tooltip = "Settings that affect score and timing display"
    }
    local displayHeaderInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", displayHeaderData)
    layout:AddInitializer(displayHeaderInitializer)

    CreateSetting(
        category,
        "Show Score Timing Bonus",
        "SHOW_TIMING",
        true,
        "Show the potential timing bonus (0-15)."
    )

    CreateSetting(
        category,
        "Remove Score Colors",
        "PLAIN_SCORE_COLORS",
        false,
        "Display score and score gains in white instead of gradient colors."
    )

    Settings.RegisterAddOnCategory(category)
end

MrMythicalUI = {
    InitializeSettings = InitializeSettings
}