local AutoJoinButton = require "widgets/autojoinbutton"
local AutoJoinIcon = require "widgets/autojoinicon"

local SCREENX = 2560
local SCREENY = 1440
local SIZE = 60

local function GetScreenSize()
    if TheSim then
        return TheSim:GetScreenSize()
    end
    return RESOLUTION_X, RESOLUTION_Y
end

local AutoJoinIconButton = Class(AutoJoinButton, function(self, onclick, isactivefn)
    AutoJoinButton._ctor(self, nil, onclick, { SIZE, SIZE })

    self.isactivefn = isactivefn

    local screenx, screeny = GetScreenSize()

    self.icon = self:AddChild(AutoJoinIcon())

    self:SetPosition(120, -RESOLUTION_Y * .5 + BACK_BUTTON_Y - 15)
    self:SetScale(1.4)
    self:SetHoverText("Auto-Join", {
        bg = nil,
        colour = UICOLOURS.WHITE,
        font = NEWFONT_OUTLINE,
        offset_x = 0 * screenx / SCREENX,
        offset_y = 70 * screeny / SCREENY,
    })

    if isactivefn() then
        self:Active()
        self:Enable()
    else
        self:Inactive()
        self:Disable()
    end
end)

--
-- General
--

function AutoJoinIconButton:GetSeconds()
    return self.icon:GetSeconds()
end

function AutoJoinIconButton:SetSeconds(seconds)
    self.icon:SetSeconds(seconds)
end

--
-- States
--

function AutoJoinIconButton:Active()
    self.icon:Active()
    self:SetHoverText("Disable")
    self:Enable()
end

function AutoJoinIconButton:Inactive()
    self.icon:Inactive()
    self:SetHoverText("Auto-Join")
    self:Enable()
end

function AutoJoinIconButton:OnGainFocus()
    AutoJoinButton._base.OnGainFocus(self)
    if self.isactivefn and self.isactivefn() then
        self.icon:ShowCircleCross()
    end
end

function AutoJoinIconButton:OnLoseFocus()
    AutoJoinButton._base.OnLoseFocus(self)
    if self.isactivefn and self.isactivefn() then
        self.icon:HideCircleCross()
    end
end

return AutoJoinIconButton
