local AutoJoinButton = require "widgets/autojoinbutton"
local Image = require "widgets/image"

local BUTTON_SIZE = 60
local ICON_SIZE = 28

local AutoJoinIconButton = Class(AutoJoinButton, function(self, onclick, isactivefn)
    AutoJoinButton._ctor(self, nil, onclick, { BUTTON_SIZE, BUTTON_SIZE })

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
    self.icon:Show()

    self.circle = self:AddChild(Image("images/auto_join_icons.xml", "circle.tex"))
    self.circle:ScaleToSize(ICON_SIZE, ICON_SIZE)
    self.circle:SetPosition(.5, 0)
    self.circle:Hide()

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

    self.ongainfocus = function()
        if isactivefn() then
            self.circle:Hide()
            self.circlecross:Show()
        end
    end

    self.onlosefocus = function()
        if isactivefn() then
            self.circle:Show()
            self.circlecross:Hide()
        end
    end

    if isactivefn() then
        self:Enable()
    else
        self:Disable()
    end
end)

return AutoJoinIconButton
