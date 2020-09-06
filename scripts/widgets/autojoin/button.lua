----
-- Base button.
--
-- Base widget to create a button by extending `ImageButton` from the engine.
--
-- Designed to be extended by other button widgets like `AutoJoinButton` and `JoinButton`.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod widgets.Button
-- @see widgets.AutoJoinButton
-- @see widgets.JoinButton
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.6.0-alpha
----
local ImageButton = require "widgets/imagebutton"

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam[opt] string text Text
-- @tparam[opt] function on_click Function triggered on click
-- @tparam[opt] table size Size (table with width and height)
-- @usage local button = Button("Join")
local Button = Class(ImageButton, function(self, text, on_click, size)
    local prefix = "button_carny_long"
    if size and #size == 2 then
        local ratio = size[1] / size[2]
        if ratio > 4 then
            prefix = "button_carny_xlong"
        elseif ratio < 1.1 then
            prefix = "button_carny_square"
        end
    end

    ImageButton._ctor(
        self,
        "images/global_redux.xml",
        prefix .. "_normal.tex",
        prefix .. "_hover.tex",
        prefix .. "_disabled.tex",
        prefix .. "_down.tex"
    )

    self:SetDisabledFont(CHATFONT)
    self:SetFont(CHATFONT)
    self:SetOnClick(on_click)
    self:SetText(text)

    if size then
        self:ForceImageSize(unpack(size))
        self:SetTextSize(math.ceil(size[2] * .45))
    end
end)

return Button
