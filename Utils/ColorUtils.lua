--[[
ColorUtils.lua - Color Calculation and Gradient Utilities

Purpose: Provides color interpolation and gradient calculation functions
Dependencies: ConfigData for color constants
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.ColorUtils = {}

local ColorUtils = MrMythical.ColorUtils
local ConfigData = MrMythical.ConfigData

--- Interpolates between color stops to create a smooth gradient color
--- @param normalizedValue number A value between 0 and 1 representing position in gradient
--- @param colorStops table Array of color stops, each with .rgbInteger property
--- @return string WoW color code in format |cffRRGGBB
function ColorUtils.interpolateColorFromStops(normalizedValue, colorStops)
    normalizedValue = math.max(0, math.min(1, normalizedValue))
    
    local numStops = #colorStops
    local scaledIndex = normalizedValue * (numStops - 1) + 1
    local lowerIndex = math.floor(scaledIndex)
    local upperIndex = math.min(lowerIndex + 1, numStops)
    local interpolationFactor = scaledIndex - lowerIndex

    local lowerRed, lowerGreen, lowerBlue = unpack(colorStops[lowerIndex].rgbInteger)
    local upperRed, upperGreen, upperBlue = unpack(colorStops[upperIndex].rgbInteger)
    
    local finalRed = lowerRed + (upperRed - lowerRed) * interpolationFactor
    local finalGreen = lowerGreen + (upperGreen - lowerGreen) * interpolationFactor
    local finalBlue = lowerBlue + (upperBlue - lowerBlue) * interpolationFactor

    return string.format("|cff%02x%02x%02x", finalRed, finalGreen, finalBlue)
end

--- Calculates a gradient color for a value within a specified domain
--- @param value number The value to colorize
--- @param domainMin number Minimum value of the domain
--- @param domainMax number Maximum value of the domain
--- @param colorStops table Array of color stops for the gradient
--- @return string WoW color code, or white if plain colors are enabled
function ColorUtils.calculateGradientColor(value, domainMin, domainMax, colorStops)
    if MRM_SavedVars.PLAIN_SCORE_COLORS then
        return ConfigData.COLORS.WHITE
    end
    
    local normalizedValue = (value - domainMin) / (domainMax - domainMin)
    normalizedValue = 1 - normalizedValue  -- Invert so higher values get "better" colors
    
    return ColorUtils.interpolateColorFromStops(normalizedValue, colorStops)
end

--- Gets class color for a given class name
--- @param className string The class name to get color for
--- @return string WoW color code
function ColorUtils.getClassColor(className)
    
    local classColors = {
        ["Death Knight"] = "|cffc41e3a",
        ["Demon Hunter"] = "|cffa330c9",
        ["Druid"] = "|cffff7c0a",
        ["Evoker"] = "|cff33937f",
        ["Hunter"] = "|cffaad372",
        ["Mage"] = "|cff3fc7eb",
        ["Monk"] = "|cff00ff98",
        ["Paladin"] = "|cfff48cba",
        ["Priest"] = "|cffffffff",
        ["Rogue"] = "|cffffff00",
        ["Shaman"] = "|cff0070dd",
        ["Warlock"] = "|cff8788ee",
        ["Warrior"] = "|cffc69b6d",
    }
    return classColors[className]
end
