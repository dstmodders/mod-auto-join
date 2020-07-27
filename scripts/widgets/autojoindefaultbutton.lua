----
-- Default "Join" button.
--
-- Widget that extends `AutoJoinButton` and creates our own version of the "Join" button very
-- similar to one on the server listing screen.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod AutoJoinDefaultButton
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-alpha
----
local AutoJoinButton = require "widgets/autojoinbutton"

local AUTO_JOIN_ICON_BUTTON_SIZE = 60
local SPACING = 10
local WIDTH = 240

local AutoJoinDefaultButton = Class(AutoJoinButton, function(self, on_click)
    local sx = WIDTH - AUTO_JOIN_ICON_BUTTON_SIZE - SPACING
    local sy = AUTO_JOIN_ICON_BUTTON_SIZE
    AutoJoinButton._ctor(self, STRINGS.UI.SERVERLISTINGSCREEN.JOIN, on_click, { sx, sy })

    -- general
    self:SetScale(1.45)
    self:Disable()

    -- position
    local x = -(AUTO_JOIN_ICON_BUTTON_SIZE / 2) - SPACING
    local y = -RESOLUTION_Y * .5 + BACK_BUTTON_Y - 15
    self:SetPosition(x, y)
end)

return AutoJoinDefaultButton
