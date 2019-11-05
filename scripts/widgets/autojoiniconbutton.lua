local AutoJoinButton = require "widgets/autojoinbutton"
local Image = require "widgets/image"

local BUTTON_SIZE = 60
local ICON_SIZE = 28

local AutoJoinIconButton = Class(AutoJoinButton, function(self, onclick, isactivefn)
    AutoJoinButton._ctor(self, nil, onclick, { BUTTON_SIZE, BUTTON_SIZE })

    self.isactivefn = isactivefn
    self.seconds = 0

    self:SetDisabledFont(HEADERFONT)
    self:SetFont(HEADERFONT)
    self:SetPosition(120, -RESOLUTION_Y * .5 + BACK_BUTTON_Y - 15)
    self:SetScale(1.4)
    self:SetText(nil)
    self:SetTextSize(18)

    self.text:SetPosition(.5, -.5)

    self.icon = self:AddChild(Image("images/auto_join_icons.xml", "clock.tex"))
    self.icon:ScaleToSize(ICON_SIZE, ICON_SIZE)
    self.icon:SetPosition(.5, 0)

    self.circle = self:AddChild(Image("images/auto_join_icons.xml", "circle.tex"))
    self.circle:ScaleToSize(ICON_SIZE, ICON_SIZE)
    self.circle:SetPosition(.5, 0)

    self.circlecross = self:AddChild(Image("images/auto_join_icons.xml", "circle_cross.tex"))
    self.circlecross:ScaleToSize(ICON_SIZE, ICON_SIZE)
    self.circlecross:SetPosition(.5, 0)
    self.circlecross:Hide()

    self:SetHoverText("Auto-Join", {
        font = NEWFONT_OUTLINE,
        offset_x = 0,
        offset_y = 70,
        colour = UICOLOURS.WHITE,
        bg = nil
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
    return self.seconds
end

function AutoJoinIconButton:SetSeconds(seconds)
    self.seconds = seconds
    self:SetText(seconds)
    self:SetTextSize(seconds > 9 and 14 or 18)
end

--
-- States
--

local function SetHoverTextString(btn, string)
    btn.hovertext:SetString(string)
    local w, h = btn.hovertext:GetRegionSize()
    btn.hovertext_bg:SetSize(w * 1.5, h * 2.0)
end

function AutoJoinIconButton:Active()
    self.circle:Show()
    self.circlecross:Hide()
    self.icon:Hide()
    self:SetSeconds(self.seconds)
    self:Enable()
    SetHoverTextString(self, "Disable Auto-Join")
end

function AutoJoinIconButton:Inactive()
    self.circle:Hide()
    self.circlecross:Hide()
    self.icon:Show()
    self:SetText(nil)
    self:Enable()
    SetHoverTextString(self, "Auto-Join")
end

function AutoJoinIconButton:OnGainFocus()
    AutoJoinButton._base.OnGainFocus(self)
    if self.isactivefn and self.isactivefn() then
        self.circle:Hide()
        self.circlecross:Show()
    end
end

function AutoJoinIconButton:OnLoseFocus()
    AutoJoinButton._base.OnLoseFocus(self)
    if self.isactivefn and self.isactivefn() then
        self.circle:Show()
        self.circlecross:Hide()
    end
end

return AutoJoinIconButton
