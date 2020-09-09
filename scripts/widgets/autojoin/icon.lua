----
-- Auto-Join icon.
--
-- Widget for an icon used in `AutoJoinButton`.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod widgets.Icon
-- @see widgets.AutoJoinButton
-- @see widgets.Indicator
-- @see widgets.RejoinButton
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.6.0-alpha
----
require "autojoin/constants"

local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @usage local icon = Icon()
local Icon = Class(Widget, function(self)
    Widget._ctor(self)

    -- fields
    self.seconds = 0
    self.state = MOD_AUTO_JOIN.STATE.DEFAULT

    -- circle
    self.circle = self:AddChild(UIAnim())
    self.circle:GetAnimState():SetBank("auto_join_states")
    self.circle:GetAnimState():SetBuild("auto_join_states")
    self.circle:GetAnimState():PlayAnimation("clock_idle")
    self.circle:SetScale(.3)

    -- icon
    self.icon = self:AddChild(UIAnim())
    self.icon:GetAnimState():SetBank("auto_join_states")
    self.icon:GetAnimState():SetBuild("auto_join_states")
    self.icon:GetAnimState():PlayAnimation("circle_idle")
    self.icon:SetScale(.3)

    -- text
    self.text = self:AddChild(Text(HEADERFONT, 18))
    self.text:SetColour({ 0, 0, 0, 1 })
    self.text:SetPosition(.5, -.5)
    self.text:SetVAlign(ANCHOR_MIDDLE)

    -- self
    self:Update()
end)

--- General
-- @section general

--- Gets seconds.
-- @treturn number
function Icon:GetSeconds()
    return self.seconds
end

--- Sets seconds.
-- @tparam number seconds
function Icon:SetSeconds(seconds)
    if type(seconds) == "number" and seconds >= 0 then
        self.seconds = seconds
        self.text:SetSize(seconds > 9 and 14 or 18)
        self.text:SetString(seconds)
    elseif type(seconds) == "nil" then
        self.text:SetString(nil)
    end
end

--- Gets state.
-- @treturn number
function Icon:GetState()
    return self.state
end

--- Sets state.
-- @tparam number state
function Icon:SetState(state)
    self.state = state
    self:Update()
end

--- Update
-- @section update

local function UpdateCircleAnim(self, name)
    self.circle:Show()
    if not self.circle:GetAnimState():IsCurrentAnimation(name) then
        self.circle:GetAnimState():PlayAnimation(name, true)
    end
end

local function UpdateIconAnim(self, name)
    self.icon:Show()
    if not self.icon:GetAnimState():IsCurrentAnimation(name) then
        self.icon:GetAnimState():PlayAnimation(name, true)
    end
end

--- Updates.
function Icon:Update()
    if self.state == MOD_AUTO_JOIN.STATE.DEFAULT then
        UpdateCircleAnim(self, "circle_idle")
        UpdateIconAnim(self, "clock_idle")
        self.text:Hide()
    elseif self.state == MOD_AUTO_JOIN.STATE.DEFAULT_FOCUS then
        UpdateCircleAnim(self, "circle_idle")
        UpdateIconAnim(self, "clock")
        self.text:Hide()
    elseif self.state == MOD_AUTO_JOIN.STATE.COUNTDOWN then
        UpdateCircleAnim(self, "circle_loading")
        UpdateIconAnim(self, "countdown")
        self.text:Show()
    elseif self.state == MOD_AUTO_JOIN.STATE.COUNTDOWN_FOCUS then
        UpdateCircleAnim(self, "circle_cross_idle")
        self.icon:Hide()
        self.text:Show()
    elseif self.state == MOD_AUTO_JOIN.STATE.CONNECT then
        UpdateCircleAnim(self, "circle_loading")
        UpdateIconAnim(self, "connect")
        self.text:Hide()
    elseif self.state == MOD_AUTO_JOIN.STATE.CONNECT_FOCUS then
        UpdateCircleAnim(self, "circle_cross_idle")
        UpdateIconAnim(self, "connect")
        self.text:Hide()
    end
end

return Icon
