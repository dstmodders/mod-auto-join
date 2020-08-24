----
-- Our "Auto-Join" button.
--
-- Widget that extends `Button` and creates our "Auto-Join" button with an icon (`Icon`).
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod widgets.AutoJoinButton
-- @see widgets.Button
-- @see widgets.Icon
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-beta
----
local Button = require "widgets/autojoin/button"
local Icon = require "widgets/autojoin/icon"

local SCREEN_X = 2560
local SCREEN_Y = 1440
local SIZE = 60

--- Helpers
-- @section helpers

local function GetScreenSize()
    if TheSim then
        return TheSim:GetScreenSize()
    end
    return RESOLUTION_X, RESOLUTION_Y
end

--- Class
-- @section class

--- Constructor.
-- @function _ctor
-- @tparam[opt] function on_click Function triggered on click
-- @tparam[opt] boolean is_active_fn Function to check active state
-- @usage local autojoinbutton = AutoJoinButton()
local AutoJoinButton = Class(Button, function(self, on_click, is_active_fn)
    Button._ctor(self, nil, on_click, { SIZE, SIZE })

    -- fields
    self.icon = self:AddChild(Icon())
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

--- General
-- @section general

--- Gets icon seconds.
-- @treturn number
function AutoJoinButton:GetSeconds()
    return self.icon:GetSeconds()
end

--- Sets icon seconds.
-- @tparam number seconds
function AutoJoinButton:SetSeconds(seconds)
    self.icon:SetSeconds(seconds)
end

--- States
-- @section states

--- Changes to an active state.
function AutoJoinButton:Active()
    self.icon:Active()
    self:SetHoverText("Disable")
    self:Enable()
end

--- Changes to an inactive state.
function AutoJoinButton:Inactive()
    self.icon:Inactive()
    self:SetHoverText("Auto-Join")
    self:Enable()
end

--- State when the focus is gained.
function AutoJoinButton:OnGainFocus()
    Button._base.OnGainFocus(self)
    if self.is_active_fn and self.is_active_fn() then
        self.icon:ShowCircleCross()
    end
end

--- State when the focus is lost.
function AutoJoinButton:OnLoseFocus()
    Button._base.OnLoseFocus(self)
    if self.is_active_fn and self.is_active_fn() then
        self.icon:HideCircleCross()
    end
end

return AutoJoinButton
