--[[
MainFrameManager.lua - Main UI Frame Management Module

Purpose: Handles creation and management of the main unified interface frame
Dependencies: UIConstants, UIHelpers
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.MainFrameManager = {}

local MainFrameManager = MrMythical.MainFrameManager

--- Creates the main unified interface frame with backdrop and positioning
--- @return Frame The created main frame, or nil if UIConstants not available
function MainFrameManager.createUnifiedFrame()
    local UIConstants = MrMythical.UIConstants
    if not UIConstants then
        return nil
    end
    
    local frame = CreateFrame("Frame", "MrMythicalUnifiedFrame", UIParent, "BackdropTemplate")
    frame:SetSize(UIConstants.FRAME.WIDTH, UIConstants.FRAME.HEIGHT)
    if MRM_SavedVars and MRM_SavedVars.UNIFIED_FRAME_POINT then
        frame:SetPoint(
            MRM_SavedVars.UNIFIED_FRAME_POINT or "CENTER",
            UIParent,
            MRM_SavedVars.UNIFIED_FRAME_RELATIVE_POINT or (MRM_SavedVars.UNIFIED_FRAME_POINT or "CENTER"),
            MRM_SavedVars.UNIFIED_FRAME_X or 0,
            MRM_SavedVars.UNIFIED_FRAME_Y or 0
        )
    else
        frame:SetPoint("CENTER")
    end
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    
    MainFrameManager.setupFrameBehavior(frame)
    frame:Hide()
    
    return frame
end

--- Configures frame behavior including movement, closing, and keyboard handling
--- @param frame Frame The frame to configure
function MainFrameManager.setupFrameBehavior(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not MRM_SavedVars then return end
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint(1)
        if point then
            MRM_SavedVars.UNIFIED_FRAME_POINT = point
            MRM_SavedVars.UNIFIED_FRAME_RELATIVE_POINT = relativePoint or point
            MRM_SavedVars.UNIFIED_FRAME_X = xOfs or 0
            MRM_SavedVars.UNIFIED_FRAME_Y = yOfs or 0
        end
    end)
    
    frame:EnableKeyboard(true)
    if frame.SetPropagateKeyboardInput and not InCombatLockdown() then
        frame:SetPropagateKeyboardInput(true)
    end
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            frame:Hide()
            return
        end
    end)
end

--- Creates the navigation panel on the left side of the main frame
--- @param parentFrame Frame The parent frame to attach the navigation panel to
--- @return Frame The created navigation panel
function MainFrameManager.createNavigationPanel(parentFrame)
    local UIConstants = MrMythical.UIConstants
    if not UIConstants then
        return nil
    end
    
    local navPanel = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    navPanel:SetPoint("TOPLEFT", UIConstants.LAYOUT.PADDING, -UIConstants.LAYOUT.PADDING)
    navPanel:SetSize(UIConstants.FRAME.NAV_PANEL_WIDTH, UIConstants.FRAME.HEIGHT - (UIConstants.LAYOUT.PADDING * 2))
    navPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
    local color = UIConstants.COLORS.NAV_BACKGROUND
    navPanel:SetBackdropColor(color.r, color.g, color.b, color.a)
    
    return navPanel
end

--- Creates the main content frame where tab content is displayed
--- @param parentFrame Frame The parent frame to attach the content frame to
--- @return Frame The created content frame
function MainFrameManager.createContentFrame(parentFrame)
    local UIConstants = MrMythical.UIConstants
    if not UIConstants then
        return nil
    end
    
    local contentFrame = CreateFrame("Frame", nil, parentFrame)
    contentFrame:SetPoint("TOPLEFT", UIConstants.FRAME.NAV_PANEL_WIDTH + UIConstants.LAYOUT.PADDING * 2, -UIConstants.LAYOUT.PADDING)
    contentFrame:SetSize(UIConstants.FRAME.CONTENT_WIDTH, UIConstants.FRAME.HEIGHT - (UIConstants.LAYOUT.PADDING * 2))
    return contentFrame
end

function MainFrameManager.openSettings()
    local UnifiedUI = MrMythical.UnifiedUI
    if UnifiedUI then
        UnifiedUI:Hide()
    end
    
    local registry = _G.MrMythicalSettingsRegistry
    if registry and registry.parentCategory and registry.parentCategory.GetID then
        Settings.OpenToCategory(registry.parentCategory:GetID())
    elseif MrMythical.Options and MrMythical.Options.openSettings then
        MrMythical.Options.openSettings()
    else
        SettingsPanel:Open()
        if MrMythicalDebug then
            print("Mr. Mythical: Settings category not found. Please access via Game Menu > Options > AddOns.")
        end
    end
end

return MainFrameManager
