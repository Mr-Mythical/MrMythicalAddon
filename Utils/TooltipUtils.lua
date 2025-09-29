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

--- Determines if tooltip text should be hidden based on user preferences
--- @param text string The text to check
--- @return boolean True if the text should be hidden
function TooltipUtils.shouldHideTooltipText(text)
    if not text then 
        return false 
    end
    
    for _, duration in ipairs(ParsingData.DURATION_STRINGS) do
        if text:find(duration, 1, true) then
            return MRM_SavedVars.HIDE_DURATION
        end
    end
    
    for _, affix in ipairs(ParsingData.AFFIX_STRINGS) do
        if text:find(affix, 1, true) then
            return MRM_SavedVars.HIDE_AFFIX_TEXT
        end
    end
    
    for _, unwanted in ipairs(ParsingData.UNWANTED_STRINGS) do
        if text:find(unwanted, 1, true) then
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
--- @return string The modified title text
function TooltipUtils.processLevelInTitle(titleText, keyLevel, resilientLevel, isShiftPressed)
    local shiftMode = MRM_SavedVars.LEVEL_SHIFT_MODE or "NONE"
    
    if MRM_SavedVars.SHORT_TITLE and titleText:find("^Keystone: ") then
        titleText = titleText:gsub("^Keystone: ", "")
    end
    
    if keyLevel and (shiftMode ~= "SHOW_BOTH" or isShiftPressed) then
        titleText = titleText .. " +" .. keyLevel
        
        if resilientLevel and (shiftMode == "NONE" or 
            (shiftMode == "SHOW_RESILIENT" and isShiftPressed) or 
            (shiftMode == "SHOW_BOTH" and isShiftPressed)) then
            titleText = titleText .. " (R" .. resilientLevel .. ")"
        end
    end
    
    return titleText
end

--- Processes level display in compact mode
--- @param lineText string The line text containing level info
--- @param isShiftPressed boolean Whether shift key is pressed
--- @param lineColor table RGB color values for the line
--- @return string|nil The processed line text, or nil if should be hidden
function TooltipUtils.processCompactLevelDisplay(lineText, isShiftPressed, lineColor)
    local shiftMode = MRM_SavedVars.LEVEL_SHIFT_MODE or "NONE"
    local level = lineText:match("Mythic Level (%d+)")
    
    if level then
        if shiftMode == "SHOW_BOTH" and not isShiftPressed then
            return nil
        end
        
        local levelText = "+" .. level
        -- Note: Resilient level would need to be passed separately or found from context
        return string.format("|cff%02x%02x%02x%s|r", 
            lineColor[1] * 255, lineColor[2] * 255, lineColor[3] * 255, levelText)
    elseif lineText:match("Resilient Level") then
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
    local isMythicLevel = lineText:match("Mythic Level")
    local isResilientLevel = lineText:match("Resilient Level")
    
    if levelDisplayMode == "TITLE" then
        return isMythicLevel or isResilientLevel
    elseif levelDisplayMode == "OFF" then
        if isMythicLevel or isResilientLevel then
            return shiftMode == "SHOW_BOTH" and not isShiftPressed
        end
    end
    
    return false
end

--- Rebuilds a tooltip with processed lines according to user settings
--- @param tooltip table The GameTooltip object
--- @param validLines table Array of processed line data
function TooltipUtils.rebuildTooltipWithProcessedLines(tooltip, validLines)
    tooltip:ClearLines()
    
    for i, line in ipairs(validLines) do
        if line.color then
            tooltip:AddLine(line.left, line.color[1], line.color[2], line.color[3])
            
            if line.right then
                local rightLine = _G["GameTooltipTextRight" .. i]
                if rightLine then
                    rightLine:SetText(line.right)
                end
            end
        end
    end
    
    tooltip:Show()
end

--- Extracts level information from tooltip lines
--- @param tooltip table The GameTooltip object
--- @param startLine number Line number to start searching from
--- @return number|nil, number|nil keyLevel, resilientLevel
function TooltipUtils.extractLevelInfoFromTooltip(tooltip, startLine)
    local keyLevel, resilientLevel
    
    for i = startLine or 2, tooltip:NumLines() do
        local line = _G["GameTooltipTextLeft"..i]:GetText() or ""
        
        if not keyLevel then
            keyLevel = line:match("Mythic Level (%d+)")
            if keyLevel then
                keyLevel = tonumber(keyLevel)
            end
        end
        
        if not resilientLevel then
            resilientLevel = line:match("Resilient Level (%d+)")
            if resilientLevel then
                resilientLevel = tonumber(resilientLevel)
            end
        end
        
        if keyLevel and resilientLevel then
            break
        end
    end
    
    return keyLevel, resilientLevel
end
