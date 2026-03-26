--[[
TooltipUtils.lua - Tooltip Processing and Enhancement Utilities

Purpose: Processes and enhances tooltip display with filtering and formatting
Dependencies: ParsingData
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.TooltipUtils = MrMythical.TooltipUtils or {}

local TooltipUtils = MrMythical.TooltipUtils
local ParsingData = MrMythical.ParsingData

local function safeGetText(fontString)
    if not fontString then
        return nil
    end

    local ok, text = pcall(function()
        return fontString:GetText()
    end)

    if ok then
        return text
    end

    return nil
end

local function safeGetTextColor(fontString)
    if not fontString then
        return 1, 1, 1
    end

    local ok, r, g, b = pcall(function()
        return fontString:GetTextColor()
    end)

    if ok then
        return r, g, b
    end

    return 1, 1, 1
end

TooltipUtils.safeGetText = safeGetText
TooltipUtils.safeGetTextColor = safeGetTextColor

--- Determines if tooltip text should be hidden based on user preferences
--- @param text string The text to check
--- @return boolean True if the text should be hidden
function TooltipUtils.shouldHideTooltipText(text)
    if not text or not ParsingData then
        return false
    end

    for _, duration in ipairs(ParsingData.DURATION_STRINGS or {}) do
        if string.find(text, duration, 1, true) then
            return MRM_SavedVars.HIDE_DURATION
        end
    end

    for _, affix in ipairs(ParsingData.AFFIX_STRINGS or {}) do
        if string.find(text, affix, 1, true) then
            return MRM_SavedVars.HIDE_AFFIX_TEXT
        end
    end

    for _, unwanted in ipairs(ParsingData.UNWANTED_STRINGS or {}) do
        if string.find(text, unwanted, 1, true) then
            return MRM_SavedVars.HIDE_UNWANTED_TEXT
        end
    end

    return false
end

--- Processes level display in tooltip title based on user settings
--- @param titleText string The original title text
--- @param keyLevel number The keystone level
--- @param resilientLevel number|nil The resilient level if available
--- @param isShiftPressed boolean Whether shift key is pressed
--- @return string titleText The modified title text
function TooltipUtils.processLevelInTitle(titleText, keyLevel, resilientLevel, isShiftPressed)
    local shiftMode = MRM_SavedVars.LEVEL_SHIFT_MODE or "NONE"

    if MRM_SavedVars.SHORT_TITLE and string.find(titleText, "^Keystone: ") then
        titleText = string.gsub(titleText, "^Keystone: ", "")
    end

    if keyLevel and (shiftMode ~= "SHOW_BOTH" or isShiftPressed) then
        titleText = titleText .. " +" .. keyLevel

        if resilientLevel and (
            shiftMode == "NONE" or
            (shiftMode == "SHOW_RESILIENT" and isShiftPressed) or
            (shiftMode == "SHOW_BOTH" and isShiftPressed)
        ) then
            titleText = titleText .. " (R" .. resilientLevel .. ")"
        end
    end

    return titleText
end

--- Processes level display in compact mode
--- @param lineText string The line text containing level info
--- @param isShiftPressed boolean Whether shift key is pressed
--- @param lineColor table RGB color values for the line
--- @return string|nil lineText The processed line text, or nil if should be hidden
function TooltipUtils.processCompactLevelDisplay(lineText, isShiftPressed, lineColor)
    local shiftMode = MRM_SavedVars.LEVEL_SHIFT_MODE or "NONE"
    local level = string.match(lineText, "Mythic Level (%d+)")

    if level then
        if shiftMode == "SHOW_BOTH" and not isShiftPressed then
            return nil
        end

        local levelText = "+" .. level
        return string.format(
            "|cff%02x%02x%02x%s|r",
            math.floor((lineColor[1] or 1) * 255),
            math.floor((lineColor[2] or 1) * 255),
            math.floor((lineColor[3] or 1) * 255),
            levelText
        )
    elseif string.match(lineText, "Resilient Level") then
        return nil
    end

    return lineText
end

--- Checks if a level line should be hidden based on display settings
--- @param lineText string The line text to check
--- @param levelDisplayMode string The level display mode setting
--- @param isShiftPressed boolean Whether shift key is pressed
--- @return boolean True if the line should be hidden
function TooltipUtils.shouldHideLevelLine(lineText, levelDisplayMode, isShiftPressed)
    local shiftMode = MRM_SavedVars.LEVEL_SHIFT_MODE or "NONE"
    local isMythicLevel = string.match(lineText, "Mythic Level")
    local isResilientLevel = string.match(lineText, "Resilient Level")

    if levelDisplayMode == "TITLE" then
        return isMythicLevel or isResilientLevel
    elseif levelDisplayMode == "OFF" then
        if isMythicLevel or isResilientLevel then
            return shiftMode == "SHOW_BOTH" and not isShiftPressed
        end
    end

    return false
end

--- Extracts level information from tooltip lines
--- @param tooltip table The GameTooltip object
--- @param startLine number|nil Line number to start searching from
--- @return number|nil keyLevel
--- @return number|nil resilientLevel
function TooltipUtils.extractLevelInfoFromTooltip(tooltip, startLine)
    local keyLevel, resilientLevel

    for i = startLine or 2, tooltip:NumLines() do
        local fontString = _G["GameTooltipTextLeft" .. i]
        if not fontString then
            break
        end

        local text = safeGetText(fontString)
        if text then
            if not keyLevel then
                local matchedKeyLevel = string.match(text, "Mythic Level (%d+)")
                if matchedKeyLevel then
                    keyLevel = tonumber(matchedKeyLevel)
                end
            end

            if not resilientLevel then
                local matchedResilientLevel = string.match(text, "Resilient Level (%d+)")
                if matchedResilientLevel then
                    resilientLevel = tonumber(matchedResilientLevel)
                end
            end
        end

        if keyLevel and resilientLevel then
            break
        end
    end

    return keyLevel, resilientLevel
end

--- Reads current tooltip lines into a plain Lua table
--- @param tooltip table The GameTooltip object
--- @return table lines
function TooltipUtils.captureTooltipLines(tooltip)
    local lines = {}

    for i = 1, tooltip:NumLines() do
        local leftFontString = _G["GameTooltipTextLeft" .. i]
        local rightFontString = _G["GameTooltipTextRight" .. i]

        if leftFontString then
            local leftText = safeGetText(leftFontString)
            local rightText = safeGetText(rightFontString)
            local r, g, b = safeGetTextColor(leftFontString)

            table.insert(lines, {
                index = i,
                left = leftText,
                right = rightText,
                color = { r, g, b },
            })
        end
    end

    return lines
end

--- Rebuilds a tooltip with processed lines according to user settings
--- @param tooltip table The GameTooltip object
--- @param validLines table Array of processed line data
function TooltipUtils.rebuildTooltipWithProcessedLines(tooltip, validLines)
    if not validLines or #validLines == 0 then
        return
    end

    tooltip:ClearLines()

    for _, line in ipairs(validLines) do
        if line and line.left and line.left ~= "" then
            local r, g, b = 1, 1, 1
            if line.color then
                r = line.color[1] or 1
                g = line.color[2] or 1
                b = line.color[3] or 1
            end

            if line.right and line.right ~= "" then
                tooltip:AddDoubleLine(line.left, line.right, r, g, b, r, g, b)
            else
                tooltip:AddLine(line.left, r, g, b)
            end
        end
    end

    tooltip:Show()
end
