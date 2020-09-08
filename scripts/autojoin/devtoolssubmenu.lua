----
-- Dev Tools mod submenu.
--
-- Includes submenu for the "Dev Tools" mod.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod DevToolsSubmenu
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.6.0-alpha
----
require "class"

local _API

--- Helpers
-- @section helpers

local function Add(self)
    _API:AddSubmenu({
        label = "Auto Join",
        name = "AutoJoinSubmenu",
        options = {
            {
                type = MOD_DEV_TOOLS.OPTION.CHECKBOX,
                options = {
                    label = "Toggle Fake Auto-Joining",
                    on_get_fn = function()
                        return self.is_fake_auto_joining
                    end,
                    on_set_fn = function(_, _, value)
                        self.is_fake_auto_joining = value
                    end,
                },
            },
            {
                type = MOD_DEV_TOOLS.OPTION.CHECKBOX,
                options = {
                    label = "Toggle Indicator Visibility",
                    on_get_fn = function()
                        return self.indicator_visibility
                    end,
                    on_set_fn = function(_, _, value)
                        self.indicator_visibility = value
                        local indicators = self.autojoin:GetIndicators()
                        for _, indicator in pairs(indicators) do
                            indicator:Update()
                        end
                    end,
                },
            },
            { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
            {
                type = MOD_DEV_TOOLS.OPTION.CHOICES,
                options = {
                    label = "State",
                    choices = {
                        { name = "Default", value = MOD_AUTO_JOIN.STATE.DEFAULT },
                        { name = "Default (Focus)", value = MOD_AUTO_JOIN.STATE.DEFAULT_FOCUS },
                        { name = "Countdown", value = MOD_AUTO_JOIN.STATE.COUNTDOWN },
                        { name = "Countdown (Focus)", value = MOD_AUTO_JOIN.STATE.COUNTDOWN_FOCUS },
                        { name = "Connect", value = MOD_AUTO_JOIN.STATE.CONNECT },
                        { name = "Connect (Focus)", value = MOD_AUTO_JOIN.STATE.CONNECT_FOCUS },
                    },
                    on_accept_fn = function()
                        self.autojoin:SetState(self.default_state)
                    end,
                    on_get_fn = function()
                        return self.autojoin:GetState()
                    end,
                    on_set_fn = function(_, _, value)
                        self.autojoin:SetState(value)
                    end,
                },
            },
            { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
            {
                type = MOD_DEV_TOOLS.OPTION.NUMERIC,
                options = {
                    label = "Default Refresh Seconds",
                    min = 1,
                    max = 120,
                    on_accept_fn = function()
                        self.autojoin.default_refresh_seconds = self.default_refresh_seconds
                    end,
                    on_get_fn = function()
                        return self.autojoin.default_refresh_seconds
                    end,
                    on_set_fn = function(_, _, value)
                        self.autojoin.default_refresh_seconds = value
                    end,
                },
            },
            {
                type = MOD_DEV_TOOLS.OPTION.NUMERIC,
                options = {
                    label = "Default Seconds",
                    min = 0,
                    max = 99,
                    on_accept_fn = function()
                        self.autojoin.default_seconds = self.default_seconds
                    end,
                    on_get_fn = function()
                        return self.autojoin.default_seconds
                    end,
                    on_set_fn = function(_, _, value)
                        self.autojoin.default_seconds = value
                    end,
                },
            },
            { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
            {
                type = MOD_DEV_TOOLS.OPTION.SUBMENU,
                options = {
                    label = "Indicator", -- label in the menu will be: "Your submenu..."
                    options = function()
                        return {
                            {
                                type = MOD_DEV_TOOLS.OPTION.CHECKBOX,
                                options = {
                                    label = "Toggle Visibility",
                                    on_get_fn = function()
                                        return self.indicator_visibility
                                    end,
                                    on_set_fn = function(_, _, value)
                                        self.indicator_visibility = value
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:Update()
                                        end
                                    end,
                                },
                            },
                            { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
                            {
                                type = MOD_DEV_TOOLS.OPTION.NUMERIC,
                                options = {
                                    label = "Padding",
                                    min = 0,
                                    max = 100,
                                    on_accept_fn = function()
                                        self.indicator_padding = self.default_indicator_padding
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:SetPadding(self.indicator_padding)
                                        end
                                    end,
                                    on_get_fn = function()
                                        return self.indicator_padding
                                    end,
                                    on_set_fn = function(_, _, value)
                                        self.indicator_padding = value
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:SetPadding(value)
                                        end
                                    end,
                                },
                            },
                            {
                                type = MOD_DEV_TOOLS.OPTION.CHOICES,
                                options = {
                                    label = "Position",
                                    choices = {
                                        { name = "Top Left", value = "tl" },
                                        { name = "Top Right", value = "tr" },
                                        { name = "Bottom Right", value = "br" },
                                        { name = "Bottom Left", value = "bl" },
                                    },
                                    on_accept_fn = function()
                                        self.indicator_position = self.default_indicator_position
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:SetScreenPosition(self.indicator_position)
                                        end
                                    end,
                                    on_get_fn = function()
                                        return self.indicator_position
                                    end,
                                    on_set_fn = function(_, _, value)
                                        self.indicator_position = value
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:SetScreenPosition(self.indicator_position)
                                        end
                                    end,
                                },
                            },
                            {
                                type = MOD_DEV_TOOLS.OPTION.NUMERIC,
                                options = {
                                    label = "Scale",
                                    min = 0.5,
                                    max = 5,
                                    step = 0.1,
                                    on_accept_fn = function()
                                        self.indicator_scale = self.default_indicator_scale
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:SetScreenScale(self.indicator_scale)
                                        end
                                    end,
                                    on_get_fn = function()
                                        return self.indicator_scale
                                    end,
                                    on_set_fn = function(_, _, value)
                                        self.indicator_scale = value
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:SetScreenScale(self.indicator_scale)
                                        end
                                    end,
                                },
                            },
                        }
                    end,
                },
            },
        },
    })
end

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam AutoJoin autojoin
-- @usage local devtoolssubmenu = DevToolsSubmenu(autojoin)
local DevToolsSubmenu = Class(function(self, autojoin)
    -- general
    self.autojoin = autojoin
    self.default_refresh_seconds = self.autojoin.default_refresh_seconds
    self.default_seconds = self.autojoin.default_seconds
    self.default_state = self.autojoin.state
    self.is_fake_auto_joining = false

    -- indicator
    self.default_indicator_padding = self.autojoin.config.indicator_padding
    self.default_indicator_position = self.autojoin.config.indicator_position
    self.default_indicator_scale = self.autojoin.config.indicator_scale
    self.indicator_padding = self.autojoin.config.indicator_padding
    self.indicator_position = self.autojoin.config.indicator_position
    self.indicator_scale = self.autojoin.config.indicator_scale
    self.indicator_visibility = false

    -- api
    if KnownModIndex:IsModEnabledAny("dst-mod-dev-tools")
        or KnownModIndex:IsModEnabledAny("workshop-2220506640")
    then
        _API = _G.DevToolsAPI
        if _API and _API:GetAPIVersion() < 1 then
            Add(self)
        end
    end
end)

return DevToolsSubmenu
