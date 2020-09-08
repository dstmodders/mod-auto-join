----
-- Indicator.
--
-- Widget that extends `Button` and creates a corner indicator which is shown during auto-joining.
-- Acts as a button clicking on which should stop auto-joining and must be visible on most of the
-- non-in-game screens.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod widgets.Indicator
-- @see AutoJoin
-- @see widgets.Button
-- @see widgets.Icon
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.6.0-alpha
----
local Button = require "widgets/autojoin/button"
local Icon = require "widgets/autojoin/icon"

local DEFAULT_PADDING = 10
local DEFAULT_SCALE = 1.3
local SIZE = 60

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam[opt] table server Server data
-- @tparam[opt] function on_click Function triggered on click
-- @tparam[opt] boolean is_active_fn Function to check active state
-- @tparam[opt] string position Position string from configurations
-- @tparam[opt] number padding Padding
-- @tparam[opt] number scale Scale
-- @usage local indicator = Indicator()
local Indicator = Class(Button, function(
    self,
    autojoin,
    server,
    on_click,
    is_active_fn,
    position,
    padding,
    scale
)
    padding = padding ~= nil and padding or DEFAULT_PADDING
    scale = scale ~= nil and scale or DEFAULT_SCALE

    Button._ctor(self, nil, on_click, { SIZE, SIZE })

    -- general
    self.autojoin = autojoin
    self.is_active_fn = is_active_fn
    self.padding = padding
    self.screen_position = position
    self.screen_scale = scale
    self.server = server

    -- icon
    self.icon = self:AddChild(Icon())
    self.icon:SetScale(1.3)

    -- devtoolssubmenu
    local devtoolssubmenu = self.autojoin.devtoolssubmenu
    if devtoolssubmenu then
        self.padding = devtoolssubmenu.indicator_padding
        self.screen_position = devtoolssubmenu.indicator_position
        self.screen_scale = devtoolssubmenu.indicator_scale
    end

    -- self
    self:Update()
end)

--- General
-- @section general

--- Gets padding.
-- @treturn number
function Indicator:GetPadding()
    return self.padding
end

--- Sets padding.
-- @tparam number padding
function Indicator:SetPadding(padding)
    self.padding = padding
    self:Update()
end

--- Gets icon seconds.
-- @treturn number
function Indicator:GetSeconds()
    return self.icon:GetSeconds()
end

--- Sets icon seconds.
-- @tparam number seconds
function Indicator:SetSeconds(seconds)
    self.icon:SetSeconds(seconds)
end

--- Sets state.
-- @tparam number state
function Indicator:SetState(state)
    if self.icon and not self.focus then
        self.icon:SetState(state)
    end
end

--- Gets screen position.
-- @treturn number
function Indicator:GetScreenPosition()
    return self.screen_position
end

--- Sets screen position.
-- @tparam string screen_position
function Indicator:SetScreenPosition(screen_position)
    self.screen_position = screen_position
    self:Update()
end

--- Gets screen scale.
-- @treturn number
function Indicator:GetScreenScale()
    return self.screen_scale
end

--- Sets screen scale.
-- @tparam number screen_scale
function Indicator:SetScreenScale(screen_scale)
    self.screen_scale = screen_scale
    self:Update()
end

--- States
-- @section states

--- State when becomes visible.
function Indicator:Show()
    Button._base.Show(self)
end

--- State when the focus is gained.
function Indicator:OnGainFocus()
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
function Indicator:OnLoseFocus()
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
function Indicator:Update()
    local pos = ((SIZE / 2) + self.padding) * self.screen_scale

    self:SetHAnchor(ANCHOR_RIGHT)
    self:SetPosition(-pos, -pos)
    self:SetScale(self.screen_scale)
    self:SetVAnchor(ANCHOR_TOP)

    if self.screen_position == "br" then
        self:SetHAnchor(ANCHOR_RIGHT)
        self:SetVAnchor(ANCHOR_BOTTOM)
        self:SetPosition(-pos, pos)
    elseif self.screen_position == "bl" then
        self:SetHAnchor(ANCHOR_LEFT)
        self:SetVAnchor(ANCHOR_BOTTOM)
        self:SetPosition(pos, pos)
    elseif self.screen_position == "tl" then
        self:SetHAnchor(ANCHOR_LEFT)
        self:SetVAnchor(ANCHOR_TOP)
        self:SetPosition(pos, -pos)
    end

    self:SetSeconds(self.autojoin.seconds)
    self:SetState(self.autojoin.state)

    if (type(self.is_active_fn) == "function" and self.is_active_fn())
        or self.autojoin.devtoolssubmenu.indicator_visibility
    then
        self:Show()
    else
        self:Hide()
    end
end

return Indicator
