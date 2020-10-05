----
-- Our "Rejoin" button.
--
-- Widget that extends `Button` and creates our "Rejoin: button with an icon (`Icon`).
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod widgets.RejoinButton
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

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam[opt] AutoJoin autojoin AutoJoin instance
-- @tparam[opt] function on_click_fn Function triggered on click
-- @usage local rejoinbutton = RejoinButton()
local RejoinButton = Class(Button, function(self, autojoin, rejoin_cb, cancel_cb)
    Button._ctor(self, autojoin, nil, nil, { 70, 70 })

    -- general
    self.cancel_cb = cancel_cb
    self.rejoin_cb = rejoin_cb

    -- status
    self.status:SetPosition(25, 25)

    -- icon
    self.icon = self:AddChild(Icon())
    self.icon:SetScale(1.4)

    -- self
    self:SetFont(NEWFONT_OUTLINE)
    self:SetTextColour(UICOLOURS.GOLD_CLICKABLE)
    self:SetTextFocusColour(UICOLOURS.GOLD_FOCUS)
    self:SetTextSize(25)
    self:Update()

    -- autojoin
    if autojoin then
        autojoin.rejoin_btn = self
        self:SetSeconds(autojoin:GetSeconds())
        self:SetState(autojoin:GetState())
    end
end)

--- General
-- @section general

--- Gets icon seconds.
-- @treturn number
function RejoinButton:GetSeconds()
    return self.icon:GetSeconds()
end

--- Sets icon seconds.
-- @tparam number seconds
function RejoinButton:SetSeconds(seconds)
    self.icon:SetSeconds(seconds)
end

--- States
-- @section states

--- Sets state.
-- @tparam number state
-- @tparam boolean ignore_focus
function RejoinButton:SetState(state, ignore_focus)
    if self.icon and (not self.focus or ignore_focus) then
        self.icon:SetState(state)
        self:Update()
    end
end

--- State when the focus is gained.
function RejoinButton:OnGainFocus()
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
function RejoinButton:OnLoseFocus()
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
function RejoinButton:Update()
    -- state
    local state = self.icon:GetState()
    if state == MOD_AUTO_JOIN.STATE.DEFAULT or state == MOD_AUTO_JOIN.STATE.DEFAULT_FOCUS then
        self:SetText("Rejoin", true)
        self:SetOnClick(self.rejoin_cb)
    else
        self:SetText("Cancel", true)
        self:SetOnClick(self.cancel_cb)
    end

    -- text
    self.text:SetPosition(1, -38)
    self.text_shadow:SetPosition(-1, -40)
end

return RejoinButton
