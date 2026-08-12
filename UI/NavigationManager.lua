--[[
NavigationManager.lua - Navigation and Content Switching Module

Purpose: Handles navigation buttons and content switching in the unified interface
Dependencies: UIConstants, UIHelpers, LibMrMythicalUI-1.0
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.NavigationManager = {}

local NavigationManager = MrMythical.NavigationManager

NavigationManager.BUTTON_DATA = {
    {id = "dashboard", text = "Dashboard", y = -20},
    {id = "rewards", text = "Rewards", y = -60},
    {id = "scores", text = "Scores", y = -100},
    {id = "stats", text = "Statistics", y = -140},
    {id = "times", text = "Times", y = -180},
    {id = "settings", text = "Settings", y = -220}
}

local function getUILib()
    return LibStub and LibStub("LibMrMythicalUI-1.0", true) or nil
end

local function getNavButtonData()
    local tabs = MrMythical.Layout and MrMythical.Layout.navTabs
    if tabs and #tabs > 0 then
        return tabs
    end
    return NavigationManager.BUTTON_DATA
end

--- Creates all navigation buttons for the interface
--- @param navPanel Frame The navigation panel to attach buttons to
--- @param contentFrame Frame The content frame for displaying tab content
--- @return table Table of created navigation buttons indexed by content type
function NavigationManager.createButtons(navPanel, contentFrame)
    local navButtons = {}

    for _, buttonInfo in ipairs(getNavButtonData()) do
        local button = NavigationManager.createNavigationButton(navPanel, buttonInfo, contentFrame, navButtons)
        navButtons[buttonInfo.id] = button
    end

    if navButtons.dashboard then
        NavigationManager.updateButtonStates(navButtons.dashboard, navButtons)
    end

    return navButtons
end

function NavigationManager.createNavigationButton(navPanel, buttonInfo, contentFrame, navButtons)
    local UIConstants = MrMythical.UIConstants
    local Lib = getUILib()
    local button

    if Lib then
        button = Lib:CreateNavTab(navPanel, {
            text = buttonInfo.text,
            id = buttonInfo.id,
            width = 120,
            height = UIConstants and UIConstants.LAYOUT.BUTTON_HEIGHT or 30,
            selected = buttonInfo.id == "dashboard",
        })
        button:SetPoint("TOPLEFT", UIConstants and UIConstants.LAYOUT.PADDING or 10, buttonInfo.y)
    else
        button = CreateFrame("Button", nil, navPanel, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", UIConstants and UIConstants.LAYOUT.PADDING or 10, buttonInfo.y)
        button:SetSize(120, UIConstants and UIConstants.LAYOUT.BUTTON_HEIGHT or 30)
        button:SetText(buttonInfo.text)
    end

    button:SetScript("OnClick", function()
        NavigationManager.handleButtonClick(buttonInfo, button, navButtons, contentFrame)
    end)

    return button
end

--- Handles navigation button clicks and content switching
--- @param buttonInfo table Button information with id and text
--- @param button Button The clicked button
--- @param navButtons table All navigation buttons
--- @param contentFrame Frame The content frame to update
function NavigationManager.handleButtonClick(buttonInfo, button, navButtons, contentFrame)
    if buttonInfo.id == "settings" then
        local MainFrameManager = MrMythical.MainFrameManager
        if MainFrameManager then
            MainFrameManager.openSettings()
        end
        return
    end

    NavigationManager.updateButtonStates(button, navButtons)
    NavigationManager.showContent(buttonInfo.id, contentFrame)
end

function NavigationManager.updateButtonStates(activeButton, navButtons)
    for _, button in pairs(navButtons) do
        if button.SetSelected then
            button:SetSelected(button == activeButton)
        else
            button:SetNormalFontObject(button == activeButton and "GameFontHighlight" or "GameFontNormal")
        end
    end
end

function NavigationManager.clearContent(contentFrame)
    for _, child in ipairs({contentFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({contentFrame:GetRegions()}) do
        if region.Hide then
            region:Hide()
        end
    end
end

--- Displays the specified content type in the content frame
--- @param contentType string The content type to display
--- @param contentFrame Frame The frame to display content in
function NavigationManager.showContent(contentType, contentFrame)
    NavigationManager.clearContent(contentFrame)

    local ContentCreators = MrMythical.ContentCreators
    if ContentCreators and ContentCreators[contentType] then
        ContentCreators[contentType](contentFrame)
    else
        local UIHelpers = MrMythical.UIHelpers
        if UIHelpers then
            UIHelpers.createFontString(contentFrame, "OVERLAY", "GameFontNormal",
                "Content not available: " .. contentType, "CENTER", 0, 0)
        else
            local fontString = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fontString:SetPoint("CENTER", 0, 0)
            fontString:SetText("Content not available: " .. contentType)
        end
    end
end

return NavigationManager
