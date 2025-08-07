--[[
Mr. Mythical - Keystone Tooltips Options Panel

This addon implements the global registry pattern for coordinating settings panels
across multiple Mr. Mythical addons. As a sibling addon, it:

1. Creates the shared "Mr. Mythical" parent category (or uses existing one)
2. Creates a "Keystone Tooltips" subcategory under the parent
3. Stores references in _G.MrMythicalSettingsRegistry for other addons to use
4. Provides utility functions for integration status checking and debugging

Other Mr. Mythical addons should create their own subcategories under the shared parent.
See SETTINGS_INTEGRATION_GUIDE.md for detailed integration guide.

Author: Braunerr
--]]

local MrMythical = MrMythical or {}
local ConfigData = MrMythical.ConfigData

local Options = {}

local function createSetting(category, name, key, defaultValue, tooltip)
    local setting = Settings.RegisterAddOnSetting(category, name, key, MRM_SavedVars, "boolean", name, defaultValue)
    setting:SetValueChangedCallback(function(_, value)
        MRM_SavedVars[key] = value
    end)

    local initializer = Settings.CreateCheckbox(category, setting, tooltip)
    initializer:SetSetting(setting)

    return { setting = setting, checkbox = initializer }
end

local function createDropdownSetting(category, name, key, defaultValue, tooltip, options)
    local setting = Settings.RegisterAddOnSetting(category, name, key, MRM_SavedVars, "string", name, defaultValue)
    setting:SetValueChangedCallback(function(_, value)
        MRM_SavedVars[key] = value
    end)

    local function getOptions()
        local dropdownOptions = {}
        for _, option in ipairs(options) do
            table.insert(dropdownOptions, {
                text = option.text,
                label = option.text,
                value = option.value,
            })
        end
        return dropdownOptions
    end

    local initializer = Settings.CreateDropdown(category, setting, getOptions, tooltip)

    return { setting = setting, dropdown = initializer }
end

function Options.initializeSettings()
    local defaults = {
        HIDE_UNWANTED_TEXT = true,
        HIDE_AFFIX_TEXT = false,
        HIDE_DURATION = false,
        SHOW_TIMING = true,
        SHOW_PAR_TIME = false,
        PLAIN_SCORE_COLORS = false,
        LEVEL_DISPLAY = "OFF",
        LEVEL_SHIFT_MODE = "NORMAL",
        SHORT_TITLE = false
    }

    MRM_SavedVars = MRM_SavedVars or {}
    for key, default in pairs(defaults) do
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

-- Create all the settings in the specified category
function Options.createSettingsInCategory(category)

    local headerData = {
        name = "Compact Mode Options",
        tooltip = "Settings that affect the appearance of keystone tooltips"
    }
    local headerInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", headerData)
    local layout = SettingsPanel:GetLayout(category)
    layout:AddInitializer(headerInitializer)

    createSetting(
        category,
        "Hide Common Text",
        "HIDE_UNWANTED_TEXT",
        true,
        "Hide common item text like 'Soulbound' and 'Unique' from keystone tooltips."
    )

    createSetting(
        category,
        "Hide Affix Text",
        "HIDE_AFFIX_TEXT",
        false,
        "Hide the lines listing the current dungeon affixes."
    )

    createSetting(
        category,
        "Hide Duration Text",
        "HIDE_DURATION",
        false,
        "Hide the duration line from keystone tooltips."
    )

    local levelDisplayOptions = {
        { text = "Default", value = "OFF" },
        { text = "Compact (+X)", value = "COMPACT" },
        { text = "In Title", value = "TITLE" }
    }

    createDropdownSetting(
        category,
        "Level Display Style",
        "LEVEL_DISPLAY",
        "OFF",
        "Choose how the mythic keystone level is displayed:\n\n" ..
        ConfigData.COLORS.WHITE .. "Default:|r Show level in its own line (e.g. 'Mythic Level 15')\n\n" ..
        ConfigData.COLORS.WHITE .. "Compact:|r Show level as +X (e.g. '+15')\n\n" ..
        ConfigData.COLORS.WHITE .. "In Title:|r Add level to keystone title (e.g. 'Operation: Floodgate +15')",
        levelDisplayOptions
    )

    local levelShiftOptions = {
        { text = "None", value = "NONE" },
        { text = "Show Resilient", value = "SHOW_RESILIENT" },
        { text = "Show Both", value = "SHOW_BOTH" }
    }

    createDropdownSetting(
        category,
        "Shift Modifier Behavior for Levels",
        "LEVEL_SHIFT_MODE",
        "NONE",
        "Choose how holding Shift affects level display (Mythic & Resilient):\n\n" ..
        ConfigData.COLORS.WHITE .. "None:|r Show both levels always\n\n" ..
        ConfigData.COLORS.WHITE .. "Show Resilient:|r Show only Mythic level, hold Shift for Resilient\n\n" ..
        ConfigData.COLORS.WHITE .. "Show Both:|r Hide levels, hold Shift shows both",
        levelShiftOptions
    )

    createSetting(
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

    createSetting(
        category,
        "Show Score Timing Bonus",
        "SHOW_TIMING",
        true,
        "Show the potential timing bonus (0-15)."
    )

    createSetting(
        category,
        "Show Dungeon Timer",
        "SHOW_PAR_TIME",
        false,
        "Display the dungeon timer in the keystone tooltip."
    )

    createSetting(
        category,
        "Remove Score Colors",
        "PLAIN_SCORE_COLORS",
        false,
        "Display score and score gains in white instead of gradient colors."
    )
end

-- Integration utility functions for other addons
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

-- Function to open the addon settings panel
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