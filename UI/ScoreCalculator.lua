--[[
ScoreCalculator.lua - Mythic+ Score Calculator Content

Purpose: Handles the score calculator interface and functionality
Dependencies: UIConstants, UIHelpers, RewardsFunctions, DungeonData, LibMrMythicalUI
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.ScoreCalculator = {}

local ScoreCalculator = MrMythical.ScoreCalculator
local UIConstants = MrMythical.UIConstants
local UIHelpers = MrMythical.UIHelpers
local RewardsFunctions = MrMythical.RewardsFunctions
local DungeonData = MrMythical.DungeonData

local MIN_KEY_LEVEL = 2
local MAX_KEY_LEVEL = 30

local function getUILib()
    return LibStub and LibStub("LibMrMythicalUI-1.0", true) or nil
end

local function region(id)
    local L = MrMythical.Layout
    return L and L.regions and L.regions[id] or nil
end

function ScoreCalculator.create(parentFrame)
    local Lib = getUILib()
    local titleR = region("scores:title")
    local descR = region("scores:desc")
    local title, descText

    if Lib then
        local titleText = (titleR and titleR.text) or "Mythic+ Score Calculator"
        title = Lib:CreateHeader(parentFrame, {
            text = titleText,
            width = (titleR and titleR.w) or 400,
        })
        if titleR and Lib.ApplyRect then
            Lib:ApplyRect(title, titleR)
        else
            title:SetPoint("TOPLEFT", 140, -12)
        end

        local descTextStr = (descR and descR.text)
            or "Hover over key levels in the left table to see potential score gains for your dungeons on the right"
        descText = Lib:CreateLabel(parentFrame, {
            text = descTextStr,
            width = (descR and descR.w) or 640,
            color = "INFO_TEXT",
            justifyH = "CENTER",
            height = (descR and descR.h) or 28,
        })
        if descR and Lib.ApplyRect then
            Lib:ApplyRect(descText, descR)
        else
            descText:SetPoint("TOPLEFT", 20, -40)
        end
    else
        title = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalLarge",
            (titleR and titleR.text) or "Mythic+ Score Calculator", "TOP", 0, -UIConstants.LAYOUT.LARGE_PADDING)
        descText = UIHelpers.createFontString(parentFrame, "OVERLAY", "GameFontNormalSmall",
            (descR and descR.text)
                or "Hover over key levels in the left table to see potential score gains for your dungeons on the right",
            "TOP", 0, -10)
        descText:SetPoint("TOP", title, "BOTTOM", 0, -10)
        descText:SetWidth(650)
        descText:SetJustifyH("CENTER")
        UIHelpers.setTextColor(descText, "INFO_TEXT")
    end

    local timerSlider = ScoreCalculator.createTimerSlider(parentFrame, Lib)
    local currentKeyLevel = ScoreCalculator.createKeyLevelDropdown(parentFrame, Lib)
    local scoreRows, gainRows = ScoreCalculator.createScoreTables(parentFrame, Lib)

    ScoreCalculator.setupScoreCalculator(timerSlider, currentKeyLevel, scoreRows, gainRows, Lib)
end

function ScoreCalculator.createTimerSlider(parentFrame, Lib)
    local sliderR = region("scores:slider")
    if Lib then
        local slider = Lib:CreateSlider(parentFrame, {
            name = "MrMythicalUnifiedTimerSlider",
            width = (sliderR and sliderR.w) or 220,
            min = 0,
            max = 40,
            step = 1,
            value = 0,
            label = (sliderR and sliderR.text) or "Timer %",
            lowText = (sliderR and sliderR.lowText) or "0%",
            highText = (sliderR and sliderR.highText) or "40%",
            format = function(v) return string.format("%d%%", v) end,
        })
        if sliderR and Lib.ApplyRect then
            Lib:ApplyRect(slider, sliderR)
        else
            slider:SetPoint("TOPLEFT", 20, -88)
        end
        return slider
    end

    -- Legacy fallback (should not run when lib is embedded)
    local timerSlider = CreateFrame("Slider", "MrMythicalUnifiedTimerSlider", parentFrame)
    timerSlider:SetPoint("TOPLEFT", 120, -75)
    timerSlider:SetSize(200, 20)
    timerSlider:SetMinMaxValues(0, 40)
    timerSlider:SetValue(0)
    timerSlider:SetValueStep(1)
    return timerSlider
end

function ScoreCalculator.createKeyLevelDropdown(parentFrame, Lib)
    local dropR = region("scores:dropdown")
    local labelR = region("scores:dropdownLabel")
    if Lib then
        local items = {}
        for i = MIN_KEY_LEVEL, MAX_KEY_LEVEL do
            items[#items + 1] = { text = tostring(i), value = i }
        end
        local w = (dropR and dropR.w) or 90
        local dropdown = Lib:CreateDropdown(parentFrame, {
            name = "MrMythicalUnifiedCurrentKeyLevel",
            width = w,
            items = items,
            value = MIN_KEY_LEVEL,
        })
        if dropR and Lib.ApplyRect then
            Lib:ApplyRect(dropdown, dropR)
        else
            dropdown:SetPoint("TOPLEFT", 270, -100)
        end
        local label = Lib:CreateLabel(parentFrame, {
            text = (labelR and labelR.text) or "Key level",
            width = (labelR and labelR.w) or w,
            color = "INFO_TEXT",
        })
        if labelR and Lib.ApplyRect then
            Lib:ApplyRect(label, labelR)
        else
            label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
        end
        return dropdown
    end

    local currentKeyLevel = CreateFrame("Frame", "MrMythicalUnifiedCurrentKeyLevel", parentFrame)
    currentKeyLevel:SetPoint("TOPLEFT", 450, -105)
    currentKeyLevel:SetSize(80, 30)
    currentKeyLevel._value = MIN_KEY_LEVEL
    function currentKeyLevel:GetValue() return self._value end
    function currentKeyLevel:SetValue(v) self._value = v end
    return currentKeyLevel
end

function ScoreCalculator.createScoreTables(parentFrame, Lib)
    local scoreScrollFrame
    local scoreContentFrame
    local scrollR = region("scores:scoreScroll")
    local gainsR = region("scores:gainsTable")

    local scrollX = (scrollR and scrollR.x) or UIConstants.LAYOUT.LARGE_PADDING
    local scrollY = (scrollR and scrollR.y) or -140
    local scrollW = (scrollR and scrollR.w) or 320
    local scrollH = (scrollR and scrollR.h) or 300

    if Lib then
        scoreScrollFrame = Lib:CreateScrollFrame(parentFrame, {
            width = scrollW,
            height = scrollH,
        })
        scoreScrollFrame:SetPoint("TOPLEFT", scrollX, scrollY)
        scoreContentFrame = CreateFrame("Frame", nil, scoreScrollFrame)
        scoreContentFrame:SetSize(math.max(1, scrollW - 20), 800)
        scoreScrollFrame:SetScrollChild(scoreContentFrame)
    else
        scoreScrollFrame = CreateFrame("ScrollFrame", nil, parentFrame)
        scoreScrollFrame:SetPoint("TOPLEFT", scrollX, scrollY)
        scoreScrollFrame:SetSize(scrollW, scrollH)
        scoreContentFrame = CreateFrame("Frame", nil, scoreScrollFrame)
        scoreContentFrame:SetSize(scrollW, 800)
        scoreScrollFrame:SetScrollChild(scoreContentFrame)
    end

    local scoreHeaders = scrollR and scrollR.headers
    if scoreHeaders then
        for _, h in ipairs(scoreHeaders) do
            UIHelpers.createHeader(scoreContentFrame, h.text, h.x or 0, h.w or 70)
        end
    else
        UIHelpers.createHeader(scoreContentFrame, "Key Level", 0, 70)
        UIHelpers.createHeader(scoreContentFrame, "Base Score", 70, 80)
        UIHelpers.createHeader(scoreContentFrame, "Timer Bonus", 150, 80)
        UIHelpers.createHeader(scoreContentFrame, "Final Score", 230, 90)
    end

    local gainsX = (gainsR and gainsR.x) or 360
    local gainsY = (gainsR and gainsR.y) or -140
    local gainsW = (gainsR and gainsR.w) or 300
    local gainsH = (gainsR and gainsR.h) or 300

    local gainsTableFrame = CreateFrame("Frame", nil, parentFrame)
    gainsTableFrame:SetPoint("TOPLEFT", gainsX, gainsY)
    gainsTableFrame:SetSize(gainsW, gainsH)

    local gainsHeaders = gainsR and gainsR.headers
    if gainsHeaders then
        for _, h in ipairs(gainsHeaders) do
            UIHelpers.createHeader(gainsTableFrame, h.text, h.x or 0, h.w or 50)
        end
    else
        UIHelpers.createHeader(gainsTableFrame, "Dungeon", 0, 110)
        UIHelpers.createHeader(gainsTableFrame, "Level", 110, 40)
        UIHelpers.createHeader(gainsTableFrame, "Score", 150, 50)
        UIHelpers.createHeader(gainsTableFrame, "Time", 200, 60)
        UIHelpers.createHeader(gainsTableFrame, "Gain", 260, 50)
    end

    return ScoreCalculator.createScoreRows(scoreContentFrame), ScoreCalculator.createGainRows(gainsTableFrame)
end

function ScoreCalculator.createScoreRows(scoreContentFrame)
    local scoreRows = {}
    local startY = -25

    for level = MIN_KEY_LEVEL, MAX_KEY_LEVEL do
        local yOffset = startY - ((level - MIN_KEY_LEVEL) * UIConstants.LAYOUT.ROW_HEIGHT)
        local isEven = level % 2 == 0

        UIHelpers.createRowBackground(scoreContentFrame, yOffset, 300, isEven)

        if RewardsFunctions and RewardsFunctions.scoreFormula then
            local baseScore = RewardsFunctions.scoreFormula(level)

            scoreRows[level] = {
                level = UIHelpers.createRowText(scoreContentFrame, tostring(level), 0, yOffset, 70),
                base = UIHelpers.createRowText(scoreContentFrame, tostring(baseScore), 70, yOffset, 80),
                bonus = UIHelpers.createRowText(scoreContentFrame, "+0", 150, yOffset, 80),
                final = UIHelpers.createRowText(scoreContentFrame, tostring(baseScore), 230, yOffset, 90)
            }

            local rowFrame = CreateFrame("Button", nil, scoreContentFrame)
            rowFrame:SetPoint("TOPLEFT", 0, yOffset)
            rowFrame:SetSize(300, UIConstants.LAYOUT.ROW_HEIGHT)
            rowFrame:EnableMouse(true)
            rowFrame.level = level
            scoreRows[level].frame = rowFrame
        end
    end

    return scoreRows
end

function ScoreCalculator.createGainRows(gainsTableFrame)
    local gainRows = {}

    if not DungeonData or not DungeonData.MYTHIC_MAPS then
        return gainRows
    end

    if MrMythical.DungeonData and MrMythical.DungeonData.getAllDungeonData then
        local dungeonData = MrMythical.DungeonData.getAllDungeonData()
        local startY = -25

        for i, data in ipairs(dungeonData) do
            local yOffset = startY - ((i - 1) * UIConstants.LAYOUT.ROW_HEIGHT)
            local isEven = i % 2 == 0

            UIHelpers.createRowBackground(gainsTableFrame, yOffset, 310, isEven)

            local levelText = "--"
            if data.currentLevel > 0 then
                levelText = tostring(data.currentLevel)
            end

            local runTimeText = DungeonData and DungeonData.formatTime and DungeonData.formatTime(data.runTime) or "Unknown"

            gainRows[i] = {
                name = UIHelpers.createRowText(gainsTableFrame, data.mapInfo.name, 0, yOffset, 110),
                current = UIHelpers.createRowText(gainsTableFrame, levelText, 110, yOffset, 40),
                timer = UIHelpers.createRowText(gainsTableFrame,
                    data.currentScore > 0 and tostring(data.currentScore) or "--", 150, yOffset, 50),
                time = UIHelpers.createRowText(gainsTableFrame, runTimeText, 200, yOffset, 60),
                gain = UIHelpers.createRowText(gainsTableFrame, "--", 260, yOffset, 50)
            }

            if data.hasRun then
                if data.isInTime then
                    UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_HIGH")
                else
                    UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_LOW")
                end
            else
                UIHelpers.setTextColor(gainRows[i].current, "DISABLED")
            end
        end
    end

    return gainRows
end

function ScoreCalculator.setupScoreCalculator(timerSlider, currentKeyLevel, scoreRows, gainRows, Lib)
    local function getKeyLevel()
        if currentKeyLevel.GetValue then
            return tonumber(currentKeyLevel:GetValue())
        end
        return MIN_KEY_LEVEL
    end

    local function getTimerValue()
        if timerSlider.GetValue then
            return timerSlider:GetValue()
        end
        return 0
    end

    local function updateScores(timerPercentage)
        ScoreCalculator.updateScoreTable(scoreRows, timerPercentage)
        ScoreCalculator.updateDungeonGains(gainRows, getKeyLevel(), timerPercentage)
    end

    if timerSlider.ValueText then
        timerSlider._onChanged = function(_, value)
            updateScores(value)
        end
    elseif timerSlider.SetScript then
        timerSlider:SetScript("OnValueChanged", function(_, value)
            updateScores(value)
        end)
    end

    if currentKeyLevel.Menu then
        currentKeyLevel._onChanged = function()
            updateScores(getTimerValue())
        end
    end

    for _, row in pairs(scoreRows) do
        if row.frame then
            row.frame:SetScript("OnEnter", function(self)
                if currentKeyLevel.SetValue then
                    currentKeyLevel:SetValue(self.level)
                end
                updateScores(getTimerValue())
            end)
        end
    end

    updateScores(0)
end

function ScoreCalculator.updateScoreTable(scoreRows, timerPercentage)
    if not RewardsFunctions or not RewardsFunctions.scoreFormula then
        return
    end

    for level = MIN_KEY_LEVEL, MAX_KEY_LEVEL do
        local row = scoreRows[level]
        if row then
            local baseScore = RewardsFunctions.scoreFormula(level)
            local scoreBonus = math.floor(15 * (timerPercentage / 40))
            local finalScore = baseScore + scoreBonus

            row.bonus:SetText(string.format("+%d", scoreBonus))
            row.final:SetText(string.format("%d", finalScore))
            UIHelpers.setTextColor(row.bonus, "SUCCESS_HIGH")
        end
    end
end

function ScoreCalculator.updateDungeonGains(gainRows, selectedLevel, timerPercentage)
    selectedLevel = tonumber(selectedLevel)
    if not selectedLevel or not RewardsFunctions or not RewardsFunctions.scoreFormula then
        return
    end

    local finalScore = RewardsFunctions.scoreFormula(selectedLevel)
    finalScore = finalScore + math.floor(15 * (timerPercentage / 40))

    if MrMythical.DungeonData and MrMythical.DungeonData.getAllDungeonData then
        local dungeonData = MrMythical.DungeonData.getAllDungeonData()

        for i, data in ipairs(dungeonData) do
            if gainRows[i] then
                local levelText = "--"
                if data.currentLevel > 0 then
                    levelText = tostring(data.currentLevel)
                end
                gainRows[i].current:SetText(levelText)

                if data.hasRun then
                    if data.isInTime then
                        UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_HIGH")
                    else
                        UIHelpers.setTextColor(gainRows[i].current, "SUCCESS_LOW")
                    end
                else
                    UIHelpers.setTextColor(gainRows[i].current, "DISABLED")
                end

                local potentialGain = finalScore - data.currentScore

                if potentialGain > 0 then
                    gainRows[i].gain:SetText(string.format("+%d", potentialGain))
                    UIHelpers.setTextColor(gainRows[i].gain, "SUCCESS_HIGH")
                else
                    gainRows[i].gain:SetText("--")
                    UIHelpers.setTextColor(gainRows[i].gain, "DISABLED")
                end
            end
        end
    end
end

if MrMythical.ContentCreators then
    MrMythical.ContentCreators.scores = ScoreCalculator.create
end

return ScoreCalculator
