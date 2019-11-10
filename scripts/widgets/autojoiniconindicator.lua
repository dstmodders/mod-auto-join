local AutoJoinButton = require "widgets/autojoinbutton"
local AutoJoinIcon = require "widgets/autojoinicon"

local DEFAULT_PADDING = 10
local DEFAULT_SCALE = 1.3
local SIZE = 60

local AutoJoinIconIndicator = Class(AutoJoinButton, function(self, server, onclick, isactivefn, position, padding, scale)
    AutoJoinButton._ctor(self, nil, onclick, { SIZE, SIZE })

    self.isactivefn = isactivefn
    self.server = server

    if not padding then
        padding = DEFAULT_PADDING
    end

    if not scale then
        scale = DEFAULT_SCALE
    end

    self.icon = self:AddChild(AutoJoinIcon())
    self.icon:SetScale(1.3)
    self.icon:Active()

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
