--[[
MainFrameManager.lua - Main UI Frame Management Module

Purpose: Handles creation and management of the main unified interface frame
Dependencies: UIConstants, UnifiedUI (for settings navigation), LibMrMythicalUI-1.0
Author: Braunerr
--]]

local MrMythical = MrMythical or {}
MrMythical.MainFrameManager = {}

local MainFrameManager = MrMythical.MainFrameManager

local function getUILib()
    return LibStub and LibStub("LibMrMythicalUI-1.0", true) or nil
end

local function layoutRegion(id)
    local L = MrMythical.Layout
    return L and L.regions and L.regions[id] or nil
end

--- Creates the main unified interface frame with backdrop and positioning
--- @return Frame|nil The created main frame, or nil if UIConstants not available
function MainFrameManager.createUnifiedFrame()
    local UIConstants = MrMythical.UIConstants
    if not UIConstants then
        return nil
    end

    local Lib = getUILib()
    local frame
    local L = MrMythical.Layout
    local frameSize = L and L.frame

    if Lib then
        local fw = (frameSize and frameSize.w) or UIConstants.FRAME.WIDTH
        local fh = (frameSize and frameSize.h) or UIConstants.FRAME.HEIGHT
        frame = Lib:CreatePanel(UIParent, {
            name = "MrMythicalUnifiedFrame",
            width = fw,
            height = fh,
            frameStrata = "DIALOG",
        })
        frame:SetFrameLevel(100)

        local close = Lib:CreateCloseButton(frame, function()
            frame:Hide()
        end)
        local closeR = layoutRegion("close")
        if closeR and Lib.ApplyRect then
            Lib:ApplyRect(close, closeR, closeR.anchor or "TOPRIGHT")
        else
            close:SetPoint("TOPRIGHT", -8, -8)
        end
        frame.CloseButton = close
    else
        frame = CreateFrame("Frame", "MrMythicalUnifiedFrame", UIParent, "BackdropTemplate")
        frame:SetSize(UIConstants.FRAME.WIDTH, UIConstants.FRAME.HEIGHT)
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(100)
        frame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
    end

    MainFrameManager.setupFrameBehavior(frame)
    frame:Hide()

    return frame
end

--- Configures frame behavior including movement, closing, and keyboard handling
--- @param frame Frame The frame to configure
function MainFrameManager.setupFrameBehavior(frame)
    local Lib = getUILib()
    if Lib and Lib.RegisterMovable then
        Lib:RegisterMovable(frame, {
            get = function()
                if not MRM_SavedVars or not MRM_SavedVars.UNIFIED_FRAME_POINT then
                    return nil
                end
                return {
                    point = MRM_SavedVars.UNIFIED_FRAME_POINT,
                    relativePoint = MRM_SavedVars.UNIFIED_FRAME_RELATIVE_POINT
                        or MRM_SavedVars.UNIFIED_FRAME_POINT,
                    x = MRM_SavedVars.UNIFIED_FRAME_X or 0,
                    y = MRM_SavedVars.UNIFIED_FRAME_Y or 0,
                }
            end,
            set = function(pos)
                if not MRM_SavedVars then
                    return
                end
                MRM_SavedVars.UNIFIED_FRAME_POINT = pos.point
                MRM_SavedVars.UNIFIED_FRAME_RELATIVE_POINT = pos.relativePoint or pos.point
                MRM_SavedVars.UNIFIED_FRAME_X = pos.x or 0
                MRM_SavedVars.UNIFIED_FRAME_Y = pos.y or 0
            end,
        })
        if not frame:GetPoint() then
            frame:SetPoint("CENTER")
        end
    else
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
    end

    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            frame:Hide()
            return
        end
        if self.SetPropagateKeyboardInput and not InCombatLockdown() then
            self:SetPropagateKeyboardInput(true)
        end
    end)
end

--- Creates the navigation panel on the left side of the main frame
--- @param parentFrame Frame The parent frame to attach the navigation panel to
--- @return Frame|nil The created navigation panel or nil if UIConstants is not available
function MainFrameManager.createNavigationPanel(parentFrame)
    local UIConstants = MrMythical.UIConstants
    if not UIConstants then
        return nil
    end

    local Lib = getUILib()
    local navPanel
    local navR = layoutRegion("nav")

    if Lib then
        local navX = (navR and navR.x) or UIConstants.LAYOUT.PADDING
        local navY = (navR and navR.y) or (-UIConstants.LAYOUT.PADDING - 24)
        local navW = (navR and navR.w) or UIConstants.FRAME.NAV_PANEL_WIDTH
        local navH = (navR and navR.h) or (UIConstants.FRAME.HEIGHT - (UIConstants.LAYOUT.PADDING * 2) - 24)
        navPanel = CreateFrame("Frame", nil, parentFrame)
        navPanel:SetPoint("TOPLEFT", navX, navY)
        navPanel:SetSize(navW, navH)
        local bg = Lib:CreateSVG(navPanel, Lib.Assets.NAV_PANEL_BG or "chrome/nav-panel-bg.svg", "BACKGROUND")
        if bg then
            bg:SetAllPoints()
            navPanel.Background = bg
        end
    else
        navPanel = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
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
    end

    return navPanel
end

--- Creates the main content frame where tab content is displayed
--- @param parentFrame Frame The parent frame to attach the content frame to
--- @return Frame|nil The created content frame or nil if UIConstants is not available
function MainFrameManager.createContentFrame(parentFrame)
    local UIConstants = MrMythical.UIConstants
    if not UIConstants then
        return nil
    end

    local Lib = getUILib()
    local contentR = layoutRegion("content")
    local contentX = (contentR and contentR.x) or (UIConstants.FRAME.NAV_PANEL_WIDTH + UIConstants.LAYOUT.PADDING * 2)
    local contentY = contentR and contentR.y
    local contentW = (contentR and contentR.w) or UIConstants.FRAME.CONTENT_WIDTH
    local contentH = contentR and contentR.h

    if not contentY then
        local topOffset = UIConstants.LAYOUT.PADDING
        if Lib then
            topOffset = UIConstants.LAYOUT.PADDING + 24
        end
        contentY = -topOffset
    end
    if not contentH then
        contentH = UIConstants.FRAME.HEIGHT + contentY - UIConstants.LAYOUT.PADDING
    end

    local contentFrame = CreateFrame("Frame", nil, parentFrame)
    contentFrame:SetPoint("TOPLEFT", contentX, contentY)
    contentFrame:SetSize(contentW, contentH)
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
