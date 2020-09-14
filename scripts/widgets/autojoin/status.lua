----
-- Auto-Join icon.
--
-- Widget for an icon used in `AutoJoinButton`.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod widgets.Status
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.7.0
----
require "autojoin/constants"

local Image = require "widgets/image"
local Utils = require "autojoin/utils"
local Widget = require "widgets/widget"

local _IMAGE_ATLAS = "images/auto_join_statuses.xml"

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam[opt] number scale
-- @tparam[opt] number scale_focus
-- @usage local status = Status()
local Status = Class(Widget, function(self, scale, scale_focus)
    Widget._ctor(self, "Status")

    -- fields
    self.hover_text_offset = 20
    self.message = nil
    self.scale = scale or 1
    self.scale_focus = scale_focus or 1.4
    self.screen_position = nil
    self.value = nil

    -- circle
    self.icon = self:AddChild(Image(_IMAGE_ATLAS, "unknown.tex"))
    self.icon:SetScale(self.scale)
    self.icon:SetScale(.35)

    -- self
    self:Update()
end)

--- General
-- @section general

--- Gets message.
-- @treturn message
function Status:GetMessage()
    return self.message
end

--- Sets message.
-- @tparam number message
function Status:SetMessage(message)
    self.message = message
    self:Update()
end

--- Gets screen position.
-- @treturn number
function Status:GetScreenPosition()
    return self.screen_position
end

--- Sets screen position.
-- @tparam string screen_position
function Status:SetScreenPosition(screen_position)
    self.screen_position = screen_position
    self:Update()
end

--- Gets value.
-- @treturn number
function Status:GetValue()
    return self.value
end

--- Sets value.
-- @tparam number value
function Status:SetValue(value)
    self.value = value
    self:Update()
end

--- Gets hover text region size.
-- @treturn number Width
-- @treturn number Height
function Status:GetHoverTextRegionSize()
    if self.hovertext then
        return self.hovertext:GetRegionSize()
    end
end

--- Sets hover text offset.
-- @tparam Vector3 offset
function Status:SetHoverTextOffset(offset)
    self.hover_text_offset = offset
end

--- Sets scale for the focused state.
-- @tparam number scale_focus Focus scale
-- @tparam[opt] number scale Default scale
function Status:SetScaleFocus(scale_focus, scale)
    self.scale_focus = scale_focus
    if scale then
        self.scale = scale
        self:SetScale(scale)
    end
end

--- States
-- @section states

--- State when the focus is gained.
function Status:OnGainFocus()
    Widget.OnGainFocus(self)
    self:SetScale(self.scale_focus)
end

--- State when the focus is lost.
function Status:OnLoseFocus()
    Widget.OnLoseFocus(self)
    self:SetScale(self.scale)
end

--- Update
-- @section update

--- Updates.
function Status:Update()
    if self.value == nil then
        self.icon:Hide()
    else
        -- icon
        self.icon:Show()
        if self.value == MOD_AUTO_JOIN.STATUS.ALREADY_CONNECTED then
            self.icon:SetTexture(_IMAGE_ATLAS, "already_connected.tex")
        elseif self.value == MOD_AUTO_JOIN.STATUS.FULL then
            self.icon:SetTexture(_IMAGE_ATLAS, "full.tex")
        elseif self.value == MOD_AUTO_JOIN.STATUS.INVALID_PASSWORD then
            self.icon:SetTexture(_IMAGE_ATLAS, "invalid_password.tex")
        elseif self.value == MOD_AUTO_JOIN.STATUS.NOT_RESPONDING then
            self.icon:SetTexture(_IMAGE_ATLAS, "not_responding.tex")
        elseif self.value == MOD_AUTO_JOIN.STATUS.UNKNOWN then
            self.icon:SetTexture(_IMAGE_ATLAS, "unknown.tex")
        end

        -- hover text
        local message = Utils.Chain.Get(STRINGS, "UI", "NETWORKDISCONNECT", "TITLE", self.message)
        message = type(message) == "string" and message or "Error"
        self:ClearHoverText()
        self:SetHoverText(message, { offset_x = 0, offset_y = 40 + self.hover_text_offset })

        local w = self:GetHoverTextRegionSize()
        if self.screen_position ~= nil then
            self:ClearHoverText()
        end

        if self.screen_position == MOD_AUTO_JOIN.ANCHOR.TOP_RIGHT
            or self.screen_position == MOD_AUTO_JOIN.ANCHOR.BOTTOM_RIGHT
        then
            self:SetHoverText(message, {
                offset_x = -((w * 1.5) + self.hover_text_offset),
                offset_y = 0,
            })
        elseif self.screen_position == MOD_AUTO_JOIN.ANCHOR.TOP_LEFT
            or self.screen_position == MOD_AUTO_JOIN.ANCHOR.BOTTOM_LEFT
        then
            self:SetHoverText(message, {
                offset_x = (w * 1.5) + self.hover_text_offset,
                offset_y = 0,
            })
        end
    end
end

return Status
