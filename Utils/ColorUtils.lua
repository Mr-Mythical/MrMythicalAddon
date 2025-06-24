local MrMythical = MrMythical or {}
MrMythical.ColorUtils = {}

local ColorUtils = MrMythical.ColorUtils
local ConfigData = MrMythical.ConfigData

--- Interpolates between color stops to create a smooth gradient color
--- @param normalizedValue number A value between 0 and 1 representing position in gradient
--- @param colorStops table Array of color stops, each with .rgbInteger property
--- @return string WoW color code in format |cffRRGGBB
function ColorUtils.interpolateColorFromStops(normalizedValue, colorStops)
    -- Clamp value to valid range
    normalizedValue = math.max(0, math.min(1, normalizedValue))
    
    local numStops = #colorStops
    local scaledIndex = normalizedValue * (numStops - 1) + 1
    local lowerIndex = math.floor(scaledIndex)
    local upperIndex = math.min(lowerIndex + 1, numStops)
    local interpolationFactor = scaledIndex - lowerIndex

    -- Get RGB values for interpolation
    local lowerRed, lowerGreen, lowerBlue = unpack(colorStops[lowerIndex].rgbInteger)
    local upperRed, upperGreen, upperBlue = unpack(colorStops[upperIndex].rgbInteger)
    
    -- Linear interpolation between colors
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
    -- Invert the ratio so higher values get "better" colors
    normalizedValue = 1 - normalizedValue
    
    return ColorUtils.interpolateColorFromStops(normalizedValue, colorStops)
end

--- Formats a WoW color code with the specified RGB values
--- @param red number Red component (0-255)
--- @param green number Green component (0-255)
--- @param blue number Blue component (0-255)
--- @return string WoW color code
function ColorUtils.formatColorCode(red, green, blue)
    return string.format("|cff%02x%02x%02x", red, green, blue)
end

--- Applies a color to text using WoW color codes
--- @param text string The text to colorize
--- @param colorCode string The color code (without |r suffix)
--- @return string Colored text with reset suffix
function ColorUtils.colorizeText(text, colorCode)
    return colorCode .. text .. "|r"
end
