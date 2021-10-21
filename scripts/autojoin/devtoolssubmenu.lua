----
-- Dev Tools mod submenu.
--
-- Includes submenu for the "Dev Tools" mod.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-auto-join](https://github.com/dstmodders/dst-mod-auto-join)
--
-- @classmod DevToolsSubmenu
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2019
-- @license MIT
-- @release 0.9.0-alpha
----
require "class"

local _API

--- Helpers
-- @section helpers

local function ToggleAutoJoinCheckbox(self, name, field)
    return {
        type = MOD_DEV_TOOLS.OPTION.CHECKBOX,
        options = {
            label = "Toggle " .. name,
            on_accept_fn = function()
                return self.defaults[field]
            end,
            on_get_fn = function()
                return self.autojoin[field]
            end,
            on_set_fn = function(_, _, value)
                self.autojoin[field] = value
            end,
        },
    }
end

local function ToggleIndicatorVisibility(self, name)
    return {
        type = MOD_DEV_TOOLS.OPTION.CHECKBOX,
        on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD,
        options = {
            label = name,
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
    }
end

local function NumericConfigOption(self, name, min, max, field, on_add_to_root_fn)
    return {
        type = MOD_DEV_TOOLS.OPTION.NUMERIC,
        on_add_to_root_fn = on_add_to_root_fn,
        options = {
            label = name,
            min = min,
            max = max,
            on_accept_fn = function()
                local value = self.autojoin.config_default[field]
                self.autojoin.config[field] = value
            end,
            on_get_fn = function()
                return self.autojoin.config[field]
            end,
            on_set_fn = function(_, _, value)
                self.autojoin.config[field] = value
            end,
        },
    }
end

local function NumericIndicatorConfigOption(self, name, min, max, step, field, setter_name)
    return {
        type = MOD_DEV_TOOLS.OPTION.NUMERIC,
        options = {
            label = name,
            min = min,
            max = max,
            step = step,
            on_accept_fn = function()
                local value = self.autojoin.config_default[field]
                print(self.autojoin.config[field], value)
                self.autojoin.config[field] = value
                local indicators = self.autojoin:GetIndicators()
                for _, indicator in pairs(indicators) do
                    indicator[setter_name](indicator, self.autojoin.config[field])
                end
            end,
            on_get_fn = function()
                return self.autojoin.config[field]
            end,
            on_set_fn = function(_, _, value)
                self.autojoin.config[field] = value
                local indicators = self.autojoin:GetIndicators()
                for _, indicator in pairs(indicators) do
                    indicator[setter_name](indicator, value)
                end
            end,
        },
    }
end

local function Add(self)
    _API:AddSubmenu({
        label = "Auto Join",
        name = "AutoJoinSubmenu",
        options = {
            ToggleAutoJoinCheckbox(self, "Fake Joining", "is_fake_joining"),
            {
                type = MOD_DEV_TOOLS.OPTION.CHECKBOX,
                options = {
                    label = "Toggle Global AutoJoin",
                    on_get_fn = function()
                        return self.is_global_autojoin
                    end,
                    on_set_fn = function(_, _, value)
                        self.is_global_autojoin = value
                        __STRICT = false
                        _G.AutoJoin = value and self.autojoin or nil
                        __STRICT = true
                    end,
                },
            },
            ToggleIndicatorVisibility(self, "Toggle Indicator Visibility"),
            {
                type = MOD_DEV_TOOLS.OPTION.DIVIDER,
                on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD,
            },
            {
                type = MOD_DEV_TOOLS.OPTION.CHOICES,
                on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD,
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
                        self.autojoin:SetState(self.defaults.state)
                    end,
                    on_get_fn = function()
                        return self.autojoin:GetState()
                    end,
                    on_set_fn = function(_, _, value)
                        self.autojoin:SetState(value)
                    end,
                },
            },
            {
                type = MOD_DEV_TOOLS.OPTION.CHOICES,
                on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD,
                options = {
                    label = "Status",
                    choices = {
                        { name = "Default", value = "nil" },
                        {
                            name = "Already Connected",
                            value = MOD_AUTO_JOIN.STATUS.ALREADY_CONNECTED,
                        },
                        { name = "Banned", value = MOD_AUTO_JOIN.STATUS.BANNED },
                        { name = "Full", value = MOD_AUTO_JOIN.STATUS.FULL },
                        {
                            name = "Invalid Password",
                            value = MOD_AUTO_JOIN.STATUS.INVALID_PASSWORD,
                        },
                        { name = "Kicked", value = MOD_AUTO_JOIN.STATUS.KICKED },
                        { name = "Not Responding", value = MOD_AUTO_JOIN.STATUS.NOT_RESPONDING },
                        { name = "Unknown", value = MOD_AUTO_JOIN.STATUS.UNKNOWN },
                    },
                    on_get_fn = function()
                        local value = self.autojoin:GetStatus()
                        return value == nil and "nil" or value
                    end,
                    on_set_fn = function(_, _, value)
                        self.autojoin:SetStatus(value)
                    end,
                },
            },
            {
                type = MOD_DEV_TOOLS.OPTION.DIVIDER,
                on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD,
            },
            {
                type = MOD_DEV_TOOLS.OPTION.NUMERIC,
                on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD,
                options = {
                    label = "Default Refresh Seconds",
                    min = 1,
                    max = 120,
                    on_accept_fn = function()
                        local value = self.defaults.default_refresh_seconds
                        self.autojoin.default_refresh_seconds = value
                    end,
                    on_get_fn = function()
                        return self.autojoin.default_refresh_seconds
                    end,
                    on_set_fn = function(_, _, value)
                        self.autojoin.default_refresh_seconds = value
                    end,
                },
            },
            NumericConfigOption(
                self,
                "Default Rejoin Initial Wait",
                0,
                15,
                "rejoin_initial_wait",
                MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD
            ),
            NumericConfigOption(
                self,
                "Default Waiting Time",
                0,
                99,
                "waiting_time",
                MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD
            ),
            {
                type = MOD_DEV_TOOLS.OPTION.DIVIDER,
                on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD,
            },
            {
                type = MOD_DEV_TOOLS.OPTION.SUBMENU,
                options = {
                    label = "Indicator", -- label in the menu will be: "Your submenu..."
                    on_add_to_root_fn = MOD_DEV_TOOLS.ON_ADD_TO_ROOT_FN.IS_NO_WORLD,
                    options = function()
                        return {
                            ToggleIndicatorVisibility(self, "Toggle Visibility"),
                            { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
                            NumericIndicatorConfigOption(
                                self,
                                "Padding",
                                0,
                                100,
                                1,
                                "indicator_padding",
                                "SetPadding"
                            ),
                            {
                                type = MOD_DEV_TOOLS.OPTION.CHOICES,
                                options = {
                                    label = "Position",
                                    choices = {
                                        { name = "Top Left", value = 1 },
                                        { name = "Top Right", value = 2 },
                                        { name = "Bottom Right", value = 3 },
                                        { name = "Bottom Left", value = 4 },
                                    },
                                    on_accept_fn = function()
                                        local v = self.autojoin.config_default.indicator_position
                                        self.autojoin.config.indicator_position = v
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:SetScreenPosition(
                                                self.autojoin.config.indicator_position
                                            )
                                        end
                                    end,
                                    on_get_fn = function()
                                        return self.autojoin.config.indicator_position
                                    end,
                                    on_set_fn = function(_, _, value)
                                        self.autojoin.config.indicator_position = value
                                        local indicators = self.autojoin:GetIndicators()
                                        for _, indicator in pairs(indicators) do
                                            indicator:SetScreenPosition(
                                                self.autojoin.config.indicator_position
                                            )
                                        end
                                    end,
                                },
                            },
                            NumericIndicatorConfigOption(
                                self,
                                "Scale",
                                0.5,
                                5,
                                0.1,
                                "indicator_scale",
                                "SetScreenScale"
                            ),
                        }
                    end,
                },
            },
            { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
            {
                type = MOD_DEV_TOOLS.OPTION.ACTION,
                options = {
                    label = "Dump Last Join Server",
                    on_accept_fn = function()
                        dumptable(self.autojoin:GetLastJoinServer())
                    end,
                },
            },
            {
                type = MOD_DEV_TOOLS.OPTION.ACTION,
                options = {
                    label = "Dump Stored Data",
                    on_accept_fn = function()
                        dumptable(self.autojoin.data:GetPersistData())
                    end,
                },
            },
            { type = MOD_DEV_TOOLS.OPTION.DIVIDER },
            {
                type = MOD_DEV_TOOLS.OPTION.ACTION,
                options = {
                    label = "Clear Stored Data",
                    on_accept_fn = function()
                        local data = self.autojoin.data
                        data.original_persist_data = nil
                        data.persist_data = nil
                        data.dirty = true
                        data:Save()
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
    self.is_global_autojoin = false

    -- defaults
    self.defaults = {
        default_refresh_seconds = self.autojoin.default_refresh_seconds,
        is_fake_joining = self.autojoin.is_fake_joining,
        state = self.autojoin.state,
    }

    -- api
    if getmetatable(_G).__declared.DevToolsAPI then
        _API = _G.DevToolsAPI
        if _API and _API:GetAPIVersion() < 1 then
            Add(self)
        end
    end
end)

return DevToolsSubmenu
