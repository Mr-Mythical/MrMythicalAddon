--[[
UI.lua - Mythic+ Interface Main Controller

Purpose: Unified tabbed interface that consolidates all Mr. Mythical functionality as the main controller
Dependencies: UI modules, RewardsFunctions, DungeonData, CompletionTracker, WoW APIs
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.UnifiedUI = {}

local UnifiedUI = MrMythical.UnifiedUI

local function initializeUnifiedUI()
    local UIConstants = MrMythical.UIConstants
    local MainFrameManager = MrMythical.MainFrameManager
    local NavigationManager = MrMythical.NavigationManager
    
    if not MainFrameManager or not NavigationManager or not UIConstants then
        if MrMythicalDebug then
            print("Mr. Mythical: UI modules not loaded properly")
        end
        return false
    end
    
    local unifiedFrame = MainFrameManager.createUnifiedFrame()
    local navPanel = MainFrameManager.createNavigationPanel(unifiedFrame)
    local contentFrame = MainFrameManager.createContentFrame(unifiedFrame)
    local navButtons = NavigationManager.createButtons(navPanel, contentFrame)
    
    local closeButton = CreateFrame("Button", nil, unifiedFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    
    -- Store references for the public API
    UnifiedUI._unifiedFrame = unifiedFrame
    UnifiedUI._contentFrame = contentFrame
    UnifiedUI._navButtons = navButtons
    UnifiedUI._UIConstants = UIConstants
    UnifiedUI._NavigationManager = NavigationManager
    
    -- Initialize with dashboard content
    NavigationManager.showContent("dashboard", contentFrame)
    
    return true
end

--- Shows the unified UI interface
--- @param contentType string Optional content type to show (dashboard, rewards, scores, stats, times, settings)
function UnifiedUI:Show(contentType)
    if not self._unifiedFrame then
        local success = initializeUnifiedUI()
        if not success then
            print("Mr. Mythical: Failed to initialize UI. Please try again or reload the addon.")
            return
        end
    end

    self._unifiedFrame:Show()
    
    local NavigationManager = self._NavigationManager

    if contentType and contentType ~= "dashboard" then
        NavigationManager.showContent(contentType, self._contentFrame)
        if self._navButtons[contentType] then
            NavigationManager.updateButtonStates(self._navButtons[contentType], self._navButtons)
        end
    else
        NavigationManager.showContent("dashboard", self._contentFrame)
    end
end

function UnifiedUI:Hide()
    if self._unifiedFrame then
        self._unifiedFrame:Hide()
    end
end

--- Toggles the visibility of the unified UI interface
--- @param contentType string Optional content type to show when opening
function UnifiedUI:Toggle(contentType)
    if self._unifiedFrame and self._unifiedFrame:IsShown() then
        self:Hide()
    else
        self:Show(contentType)
    end
end
