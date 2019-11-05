local AutoJoinButton = require "widgets/autojoinbutton"

local AUTO_JOIN_ICON_BUTTON_SIZE = 60
local SPACING = 10
local WIDTH = 240

local AutoJoinDefaultButton = Class(AutoJoinButton, function(self, onclick)
    local sizex = WIDTH - AUTO_JOIN_ICON_BUTTON_SIZE - SPACING
    local sizey = AUTO_JOIN_ICON_BUTTON_SIZE

    AutoJoinButton._ctor(self, STRINGS.UI.SERVERLISTINGSCREEN.JOIN, onclick, { sizex, sizey })

    local x = -(AUTO_JOIN_ICON_BUTTON_SIZE / 2) - SPACING
    local y = -RESOLUTION_Y * .5 + BACK_BUTTON_Y - 15
    self:SetPosition(x, y)

    self:SetScale(1.45)
    self:Disable()
end)

return AutoJoinDefaultButton
