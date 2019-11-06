local Image = require "widgets/image"
local Text = require "widgets/text"
local Widget = require "widgets/widget"

local SIZE = 28

local AutoJoinIcon = Class(Widget, function(self)
    Widget._ctor(self)

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

    self.circlecross = self:AddChild(Image("images/auto_join_icons.xml", "circle_cross.tex"))
    self.circlecross:ScaleToSize(SIZE, SIZE)
    self.circlecross:SetPosition(.5, 0)
    self.circlecross:Hide()
end)

--
-- General
--

function AutoJoinIcon:GetSeconds()
    return self.seconds
end

function AutoJoinIcon:SetSeconds(seconds)
    self.seconds = seconds
    self.text:SetSize(seconds > 9 and 14 or 18)
    self.text:SetString(seconds)
end

--
-- States
--

function AutoJoinIcon:Active()
    self.circle:Show()
    self.circlecross:Hide()
    self.icon:Hide()
    self:SetSeconds(self.seconds)
end

function AutoJoinIcon:Inactive()
    self.circle:Hide()
    self.circlecross:Hide()
    self.icon:Show()
    self.text:SetString(nil)
end

function AutoJoinIcon:ShowCircleCross()
    self.circle:Hide()
    self.circlecross:Show()
end

function AutoJoinIcon:HideCircleCross()
    self.circle:Show()
    self.circlecross:Hide()
end

return AutoJoinIcon
