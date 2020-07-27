----
-- Our "Auto-Join" button.
--
-- Widget that extends `AutoJoinButton` and creates our "Auto-Join" button with an icon.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod AutoJoinIconButton
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-alpha
----
local AutoJoinButton = require "widgets/autojoinbutton"
local AutoJoinIcon = require "widgets/autojoinicon"

local SCREEN_X = 2560
local SCREEN_Y = 1440
local SIZE = 60

--
-- Helpers
--

local function GetScreenSize()
    if TheSim then
        return TheSim:GetScreenSize()
    end
    return RESOLUTION_X, RESOLUTION_Y
end

--
-- Class
--

local AutoJoinIconButton = Class(AutoJoinButton, function(self, on_click, is_active_fn)
    AutoJoinButton._ctor(self, nil, on_click, { SIZE, SIZE })

    -- fields
    self.icon = self:AddChild(AutoJoinIcon())
    self.is_active_fn = is_active_fn

    -- general
    local sx, sy = GetScreenSize()
    self:SetPosition(120, -RESOLUTION_Y * .5 + BACK_BUTTON_Y - 15)
    self:SetScale(1.4)
    self:SetHoverText("Auto-Join", {
        bg = nil,
        colour = UICOLOURS.WHITE,
        font = NEWFONT_OUTLINE,
        offset_x = 0 * sx / SCREEN_X,
        offset_y = 70 * sy / SCREEN_Y,
    })

    -- states
    if is_active_fn() then
        self:Active()
        self:Enable()
    else
        self:Inactive()
        self:Disable()
    end
end)

--
-- General
--

--- Gets icon seconds.
-- @treturn number
function AutoJoinIconButton:GetSeconds()
    return self.icon:GetSeconds()
end

--- Sets icon seconds.
-- @tparam number seconds
function AutoJoinIconButton:SetSeconds(seconds)
    self.icon:SetSeconds(seconds)
end

--
-- States
--

--- Changes to an active state.
function AutoJoinIconButton:Active()
    self.icon:Active()
    self:SetHoverText("Disable")
    self:Enable()
end

--- Changes to an inactive state.
function AutoJoinIconButton:Inactive()
    self.icon:Inactive()
    self:SetHoverText("Auto-Join")
    self:Enable()
end

--- State when the focus is gained.
function AutoJoinIconButton:OnGainFocus()
    AutoJoinButton._base.OnGainFocus(self)
    if self.is_active_fn and self.is_active_fn() then
        self.icon:ShowCircleCross()
    end
end

--- State when the focus is lost.
function AutoJoinIconButton:OnLoseFocus()
    AutoJoinButton._base.OnLoseFocus(self)
    if self.is_active_fn and self.is_active_fn() then
        self.icon:HideCircleCross()
    end
end

return AutoJoinIconButton
