----
-- Auto-Join icon.
--
-- Widget for an icon used in `AutoJoinButton`.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod widgets.autojoin.Icon
-- @see widgets.autojoin.AutoJoinButton
-- @see widgets.autojoin.Indicator
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-beta
----
local Image = require "widgets/image"
local Text = require "widgets/text"
local Widget = require "widgets/widget"

local SIZE = 28

local Icon = Class(Widget, function(self)
    Widget._ctor(self)

    -- fields
    self.seconds = 0

    self.text = self:AddChild(Text(HEADERFONT, 18))
    self.text:SetColour({ 0, 0, 0, 1 })
    self.text:SetPosition(.5, -.5)
    self.text:SetVAlign(ANCHOR_MIDDLE)

    self.icon = self:AddChild(Image("images/auto_join_icons.xml", "clock.tex"))
    self.icon:ScaleToSize(SIZE, SIZE)
    self.icon:SetPosition(.5, 0)

    self.circle = self:AddChild(Image("images/auto_join_icons.xml", "circle.tex"))
    self.circle:ScaleToSize(SIZE, SIZE)
    self.circle:SetPosition(.5, 0)

    self.circle_cross = self:AddChild(Image("images/auto_join_icons.xml", "circle_cross.tex"))
    self.circle_cross:ScaleToSize(SIZE, SIZE)
    self.circle_cross:SetPosition(.5, 0)
    self.circle_cross:Hide()
end)

--
-- General
--

--- Gets seconds.
-- @treturn number
function Icon:GetSeconds()
    return self.seconds
end

--- Sets seconds.
-- @tparam number seconds
function Icon:SetSeconds(seconds)
    self.seconds = seconds
    self.text:SetSize(seconds > 9 and 14 or 18)
    self.text:SetString(seconds)
end

--
-- States
--

--- Changes to an active state.
function Icon:Active()
    self.circle:Show()
    self.circle_cross:Hide()
    self.icon:Hide()
    self:SetSeconds(self.seconds)
end

--- Changes to an inactive state.
function Icon:Inactive()
    self.circle:Hide()
    self.circle_cross:Hide()
    self.icon:Show()
    self.text:SetString(nil)
end

--- Changes a circle to the state with cross.
function Icon:ShowCircleCross()
    self.circle:Hide()
    self.circle_cross:Show()
end

--- Changes a circle to the state without cross.
function Icon:HideCircleCross()
    self.circle:Show()
    self.circle_cross:Hide()
end

return Icon
