----
-- Base button.
--
-- Base widget to create a button by extending `ImageButton` from the engine.
--
-- Designed to be extended by other button widgets like `AutoJoinButton` and `JoinButton`.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-auto-join](https://github.com/dstmodders/dst-mod-auto-join)
--
-- @classmod widgets.Button
-- @see widgets.AutoJoinButton
-- @see widgets.JoinButton
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.8.0
----
local ImageButton = require "widgets/imagebutton"
local Status = require "widgets/autojoin/status"

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam[opt] AutoJoin autojoin AutoJoin instance
-- @tparam[opt] string text Text
-- @tparam[opt] function on_click_fn Function triggered on click
-- @tparam[opt] table size Size (table with width and height)
-- @usage local button = Button(autojoin, "Join")
local Button = Class(ImageButton, function(self, autojoin, text, on_click_fn, size)
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

    -- general
    self.autojoin = autojoin

    -- status
    self.status = self:AddChild(Status())
    self.status:SetPosition(25, 25)

    if autojoin then
        self:SetStatus(autojoin.status, autojoin.status_message)
    end

    -- self
    self:SetDisabledFont(CHATFONT)
    self:SetFont(CHATFONT)
    self:SetOnClick(on_click_fn)
    self:SetText(text)

    if size then
        self:ForceImageSize(unpack(size))
        self:SetTextSize(math.ceil(size[2] * .45))
    end
end)

--- General
-- @section general

--- Gets status value.
-- @treturn number
function Button:GetStatus()
    return self.status:GetValue()
end

--- Sets status value.
-- @tparam number status
-- @tparam[opt] string message
function Button:SetStatus(status, message)
    self.status:SetValue(status)
    if message then
        self.status:SetMessage(message)
    end
end

return Button
