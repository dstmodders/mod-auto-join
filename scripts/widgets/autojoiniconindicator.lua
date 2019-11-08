local AutoJoinButton = require "widgets/autojoinbutton"
local AutoJoinIcon = require "widgets/autojoinicon"

local PADDING = 10
local SCALE = 1.3
local SIZE = 60

local AutoJoinIconIndicator = Class(AutoJoinButton, function(self, server, onclick, isactivefn)
    AutoJoinButton._ctor(self, nil, onclick, { SIZE, SIZE })

    self.isactivefn = isactivefn
    self.server = server

    self.icon = self:AddChild(AutoJoinIcon())
    self.icon:SetScale(SCALE)
    self.icon:Active()

    self:SetHAnchor(ANCHOR_RIGHT)
    self:SetScale(SCALE)
    self:SetVAnchor(ANCHOR_TOP)

    local pos = -((SIZE / 2) + PADDING) * SCALE
    self:SetPosition(pos, pos)

    if isactivefn and isactivefn() then
        self:Show()
    else
        self:Hide()
    end
end)

--
-- General
--

function AutoJoinIconIndicator:GetSeconds()
    return self.icon:GetSeconds()
end

function AutoJoinIconIndicator:SetSeconds(seconds)
    self.icon:SetSeconds(seconds)
end

--
-- States
--

function AutoJoinIconIndicator:Show()
    AutoJoinButton._base.Show(self)
end

function AutoJoinIconIndicator:OnGainFocus()
    AutoJoinButton._base.OnGainFocus(self)
    if self.isactivefn and self.isactivefn() then
        self.icon:ShowCircleCross()
    end
end

function AutoJoinIconIndicator:OnLoseFocus()
    AutoJoinButton._base.OnLoseFocus(self)
    if self.isactivefn and self.isactivefn() then
        self.icon:HideCircleCross()
    end
end

return AutoJoinIconIndicator
