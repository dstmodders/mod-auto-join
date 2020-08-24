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
-- @release 0.5.0-beta
----
local Button = require "widgets/autojoin/button"
local Icon = require "widgets/autojoin/icon"

local DEFAULT_PADDING = 10
local DEFAULT_SCALE = 1.3
local SIZE = 60

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

    -- fields
    self.is_active_fn = is_active_fn
    self.server = server

    self.icon = self:AddChild(Icon())
    self.icon:SetScale(1.3)
    self.icon:Active()

    -- general
    local pos = ((SIZE / 2) + padding) * scale

    self:SetHAnchor(ANCHOR_RIGHT)
    self:SetPosition(-pos, -pos)
    self:SetScale(scale)
    self:SetVAnchor(ANCHOR_TOP)

    if position == "br" then
        self:SetHAnchor(ANCHOR_RIGHT)
        self:SetVAnchor(ANCHOR_BOTTOM)
        self:SetPosition(-pos, pos)
    elseif position == "bl" then
        self:SetHAnchor(ANCHOR_LEFT)
        self:SetVAnchor(ANCHOR_BOTTOM)
        self:SetPosition(pos, pos)
    elseif position == "tl" then
        self:SetHAnchor(ANCHOR_LEFT)
        self:SetVAnchor(ANCHOR_TOP)
        self:SetPosition(pos, -pos)
    end

    if is_active_fn and is_active_fn() then
        self:Show()
    else
        self:Hide()
    end
end)

--- General
-- @section general

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

--- States
-- @section states

--- State when becomes visible.
function Indicator:Show()
    Button._base.Show(self)
end

--- State when the focus is gained.
function Indicator:OnGainFocus()
    Button._base.OnGainFocus(self)
    if self.is_active_fn and self.is_active_fn() then
        self.icon:ShowCircleCross()
    end
end

--- State when the focus is lost.
function Indicator:OnLoseFocus()
    Button._base.OnLoseFocus(self)
    if self.is_active_fn and self.is_active_fn() then
        self.icon:HideCircleCross()
    end
end

return Indicator
