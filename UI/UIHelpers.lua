--[[
UIHelpers.lua - UI Helper Functions

Common UI utility functions for creating and styling interface elements.
--]]

local MrMythical = MrMythical or {}
MrMythical.UIHelpers = {}

local UIHelpers = MrMythical.UIHelpers

function UIHelpers.createFontString(parent, layer, font, text, point, x, y)
    local fontString = parent:CreateFontString(nil, layer or "OVERLAY", font or "GameFontNormal")
    if point then
        fontString:SetPoint(point, x or 0, y or 0)
    end
    if text then
        fontString:SetText(text)
    end
    return fontString
end

function UIHelpers.createHeader(parent, text, x, width)
    local header = UIHelpers.createFontString(parent, "OVERLAY", "GameFontHighlight", text, "TOPLEFT", x, 0)
    header:SetWidth(width)
    header:SetJustifyH("CENTER")
    return header
end

function UIHelpers.createRowBackground(parent, yOffset, width, isEven)
    local UIConstants = MrMythical.UIConstants
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 0, yOffset)
    bg:SetSize(width, UIConstants and UIConstants.LAYOUT.ROW_HEIGHT or 25)
    
    local color
    if UIConstants then
        color = isEven and UIConstants.COLORS.EVEN_ROW or UIConstants.COLORS.ODD_ROW
    else
        color = isEven and {r = 0.1, g = 0.1, b = 0.1, a = 0.3} or {r = 0.15, g = 0.15, b = 0.15, a = 0.3}
    end
    bg:SetColorTexture(color.r, color.g, color.b, color.a)
    return bg
end

function UIHelpers.createRowText(parent, text, x, yOffset, width, color)
    local fontString = UIHelpers.createFontString(parent, "OVERLAY", "GameFontNormal", text, "TOPLEFT", x, yOffset)
    fontString:SetWidth(width)
    fontString:SetJustifyH("CENTER")
    
    if color then
        fontString:SetTextColor(color.r, color.g, color.b)
    end
    return fontString
end

function UIHelpers.setTextColor(fontString, colorName)
    local UIConstants = MrMythical.UIConstants
    local color = UIConstants and UIConstants.COLORS[colorName]
    if color then
        fontString:SetTextColor(color.r, color.g, color.b, color.a)
    else
        -- Fallback colors if UIConstants not available
        local fallbackColors = {
            SUCCESS_HIGH = {r = 0, g = 1, b = 0},
            SUCCESS_MEDIUM = {r = 1, g = 1, b = 0},
            SUCCESS_LOW = {r = 1, g = 0, b = 0},
            DISABLED = {r = 0.5, g = 0.5, b = 0.5},
            INFO_TEXT = {r = 0.8, g = 0.8, b = 0.8}
        }
        local fallbackColor = fallbackColors[colorName]
        if fallbackColor then
            fontString:SetTextColor(fallbackColor.r, fallbackColor.g, fallbackColor.b)
        end
    end
end

function UIHelpers.getSuccessRateColor(rate)
    if rate >= 80 then
        return "SUCCESS_HIGH"
    elseif rate >= 60 then
        return "SUCCESS_MEDIUM"
    else
        return "SUCCESS_LOW"
    end
end

return UIHelpers
