----
-- Our "Auto-Join" button.
--
-- Widget that extends `Button` and creates our "Auto-Join" button with an icon (`Icon`).
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-auto-join](https://github.com/dstmodders/dst-mod-auto-join)
--
-- @classmod widgets.AutoJoinButton
-- @see widgets.Button
-- @see widgets.Icon
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.8.0
----
require "autojoin/constants"

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

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam[opt] AutoJoin autojoin AutoJoin instance
-- @tparam[opt] function on_click_fn Function triggered on click
-- @tparam[opt] boolean is_active_fn Function to check active state
-- @usage local autojoinbutton = AutoJoinButton()
local AutoJoinButton = Class(Button, function(self, autojoin, on_click_fn, is_active_fn)
    Button._ctor(self, autojoin, nil, on_click_fn, { SIZE, SIZE })

    -- fields
    self.icon = self:AddChild(Icon())
    self.is_active_fn = is_active_fn

    -- status
    self.status:SetHoverTextOffset(40)
    self.status:SetScaleFocus(1.1, .8)
    self.status:SetPosition(-20, -20)
    self.status:SetScreenPosition(MOD_AUTO_JOIN.ANCHOR.BOTTOM_RIGHT)

    -- self
    local sx, sy = GetScreenSize()
    self:SetPosition(120, -RESOLUTION_Y * .5 + BACK_BUTTON_Y - 15)
    self:SetScale(1.4)
    self:Update()
    self:SetHoverText("Auto-Join", {
        bg = nil,
        colour = UICOLOURS.WHITE,
        font = NEWFONT_OUTLINE,
        offset_x = 0 * sx / SCREEN_X,
        offset_y = 70 * sy / SCREEN_Y,
    })
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

--- Sets state.
-- @tparam number state
-- @tparam boolean ignore_focus
function AutoJoinButton:SetState(state, ignore_focus)
    if self.icon and (not self.focus or ignore_focus) then
        self.icon:SetState(state)
    end
end

--- State when the focus is gained.
function AutoJoinButton:OnGainFocus()
    Button._base.OnGainFocus(self)
    if self:IsEnabled() and self.icon then
        local state = self.icon:GetState()
        if state == MOD_AUTO_JOIN.STATE.DEFAULT then
            self.icon:SetState(MOD_AUTO_JOIN.STATE.DEFAULT_FOCUS)
        elseif state == MOD_AUTO_JOIN.STATE.COUNTDOWN then
            self.icon:SetState(MOD_AUTO_JOIN.STATE.COUNTDOWN_FOCUS)
        elseif state == MOD_AUTO_JOIN.STATE.CONNECT then
            self.icon:SetState(MOD_AUTO_JOIN.STATE.CONNECT_FOCUS)
        end
    end
end

--- State when the focus is lost.
function AutoJoinButton:OnLoseFocus()
    Button._base.OnLoseFocus(self)
    if self:IsEnabled() and self.icon then
        local state = self.icon:GetState()
        if state == MOD_AUTO_JOIN.STATE.DEFAULT_FOCUS then
            self.icon:SetState(MOD_AUTO_JOIN.STATE.DEFAULT)
        elseif state == MOD_AUTO_JOIN.STATE.COUNTDOWN_FOCUS then
            self.icon:SetState(MOD_AUTO_JOIN.STATE.COUNTDOWN)
        elseif state == MOD_AUTO_JOIN.STATE.CONNECT_FOCUS then
            self.icon:SetState(MOD_AUTO_JOIN.STATE.CONNECT)
        end
    end
end

--- Update
-- @section update

--- Updates.
function AutoJoinButton:Update()
    self:SetState(self.autojoin.state)
    self:SetSeconds(self.autojoin.seconds)

    if self.is_active_fn and self.is_active_fn() then
        self:Enable()
    else
        self:Disable()
    end
end

return AutoJoinButton
