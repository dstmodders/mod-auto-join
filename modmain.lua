----
-- Modmain.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0
----
local _G = GLOBAL
local require = _G.require

local AutoJoin = require "autojoin"
local AutoJoinButton = require "widgets/autojoin/autojoinbutton"
local JoinButton = require "widgets/autojoin/joinbutton"
local Utils = require "autojoin/utils"

--- Globals
-- @section globals

local TheNet = _G.TheNet

--- Assets
-- @section assets

Assets = {
    Asset("ATLAS", "images/auto_join_icons.xml"),
    Asset("IMAGE", "images/auto_join_icons.tex"),
}

--- Debugging
-- @section debugging

local Debug

if GetModConfigData("debug") then
    Debug = require "autojoin/debug"
    Debug:DoInit(modname)
    Debug:SetIsEnabled(true)
    Debug:DebugModConfigs()
end

_G.ModAutoJoinDebug = Debug

local function DebugString(...)
    return Debug and Debug:DebugString(...)
end

local function DebugInit(...)
    return Debug and Debug:DebugInit(...)
end

--- Initialization
-- @section initialization

AutoJoin:DoInit()

-- GetModConfigData
local configs = {
    "indicator",
    "indicator_padding",
    "indicator_position",
    "indicator_scale",
    "waiting_time",
}

for _, config in ipairs(configs) do
    AutoJoin.config[config] = GetModConfigData(config)
end

--- Server Listing Screen
-- @section server-listing-screen

local function ServerListingScreenPostInit(_self)
    local ServerPreferences = _G.ServerPreferences

    --
    -- Buttons
    --

    local server_fn = function()
        return _self.selected_server
    end

    local function OnJoinClick()
        local server = server_fn()
        if server then
            if server.has_password then
                DebugString("Joining the password-protected server:", server.name)
            else
                DebugString("Joining the server:", server.name)
            end

            AutoJoin:StopAutoJoining()
            _self:Join(false)
        end
    end

    local function OnAutoJoinSuccess(self)
        self.server = server_fn()
        _self.servers_scroll_list:RefreshView()
    end

    local function OnAutoJoinCancel(self)
        self.server = nil
        _self.servers_scroll_list:RefreshView()
    end

    AutoJoin.join_btn = _self.side_panel:AddChild(JoinButton(OnJoinClick))
    AutoJoin.auto_join_btn = _self.side_panel:AddChild(AutoJoinButton(
        AutoJoin:GetBtnOnClickFn(server_fn, OnAutoJoinSuccess, OnAutoJoinCancel),
        AutoJoin:GetBtnIsActiveFn()
    ))

    _self.auto_join_join_btn = AutoJoin.join_btn
    _self.auto_join_auto_join_btn = AutoJoin.auto_join_btn
    _self.join_button:Hide()

    --
    -- Overrides
    --

    local OldSetRowColour = _self.SetRowColour
    _self.SetRowColour = function(self, row_widget, colour)
        OldSetRowColour(self, row_widget, colour)

        local server = self.servers[row_widget.unfiltered_index]
        local auto_join_server = AutoJoin.server

        if server and auto_join_server then
            if self.servers[row_widget.unfiltered_index].guid == auto_join_server.guid then
                OldSetRowColour(self, row_widget, _G.UICOLOURS.GOLD)
            end
        end
    end

    local OldUpdateServerData = _self.UpdateServerData
    _self.UpdateServerData = function(self, selected_index_actual)
        OldUpdateServerData(self, selected_index_actual)

        local selected_server = TheNet:GetServerListingFromActualIndex(selected_index_actual)
        local is_name_and_description_hidden = selected_server
            and ServerPreferences:IsNameAndDescriptionHidden(selected_server)
            or false

        if selected_server
            and (Utils.TableCompare(selected_server, self.selected_server) == false
            or self.details_hidden_name ~= is_name_and_description_hidden)
        then
            _self.auto_join_join_btn:Enable()
            _self.auto_join_auto_join_btn:Enable()
        end
    end

    DebugInit("ServerListingScreenPostInit")
end

AddClassPostConstruct("screens/redux/serverlistingscreen", ServerListingScreenPostInit)

--- Indicator
-- @section indicator

local function IndicatorScreenPostInit(_self)
    _self.mod_auto_join_indicator = nil
    if not _self.mod_auto_join_indicator then
        _self.mod_auto_join_indicator = AutoJoin:AddIndicator(_self)
    end

    local OldOnDestroy = _self.OnDestroy
    _self.OnDestroy = function(self)
        DebugString(self.name, "destroyed")
        OldOnDestroy(self)
        if self.mod_auto_join_indicator then
            AutoJoin:RemoveIndicator(self.mod_auto_join_indicator)
            self.mod_auto_join_indicator = nil
        end
    end

    DebugInit(_self.name)
end

local function MultiplayerMainScreenPostInit(_self)
    _self.mod_auto_join_indicator = nil

    local OldOnHide = _self.OnHide
    _self.OnHide = function(self)
        DebugString(self.name, "is hidden")
        OldOnHide(self)
        if self.mod_auto_join_indicator then
            AutoJoin:RemoveIndicator(self.mod_auto_join_indicator)
            self.mod_auto_join_indicator = nil
        end
    end

    local OldOnShow = _self.OnShow
    _self.OnShow = function(self)
        DebugString(self.name, "is shown")
        OldOnShow(self)
        if not self.mod_auto_join_indicator then
            self.mod_auto_join_indicator = AutoJoin:AddIndicator(self.fixed_root, function()
                return self.mod_auto_join_indicator
            end)
        end
    end

    DebugInit(_self.name)
end

if GetModConfigData("indicator") then
    AddClassPostConstruct("screens/redux/multiplayermainscreen", MultiplayerMainScreenPostInit) -- Main Screen

    -- Main Screen
    AddClassPostConstruct("screens/redux/servercreationscreen", IndicatorScreenPostInit) -- Host Game
    AddClassPostConstruct("screens/redux/playersummaryscreen", IndicatorScreenPostInit) -- Item Collection
    AddClassPostConstruct("screens/redux/compendiumscreen", IndicatorScreenPostInit) -- Compendium
    AddClassPostConstruct("screens/redux/optionsscreen", IndicatorScreenPostInit) -- Options
    AddClassPostConstruct("screens/redux/modsscreen", IndicatorScreenPostInit) -- Mods
    AddClassPostConstruct("screens/redux/modconfigurationscreen", IndicatorScreenPostInit) -- Mods (Configuration)

    -- Item Collection
    AddClassPostConstruct("screens/redux/collectionscreen", IndicatorScreenPostInit) -- Curio Cabinet
    AddClassPostConstruct("screens/redux/mysteryboxscreen", IndicatorScreenPostInit) -- Treasury
    AddClassPostConstruct("screens/tradescreen", IndicatorScreenPostInit) -- Trade Inn
    AddClassPostConstruct("screens/crowgamescreen", IndicatorScreenPostInit) -- Trade Inn (Crow Game)
    AddClassPostConstruct("screens/redbirdgamescreen", IndicatorScreenPostInit) -- Trade Inn (Red Bird Game)
    AddClassPostConstruct("screens/snowbirdgamescreen", IndicatorScreenPostInit) -- Trade Inn (Snow Bird Game)
    AddClassPostConstruct("screens/redeemdialog", IndicatorScreenPostInit) -- Redeem Codes
    AddClassPostConstruct("screens/redux/purchasepackscreen", IndicatorScreenPostInit) -- Shop
    AddClassPostConstruct("screens/redux/achievementspopup", IndicatorScreenPostInit) -- Achievements
    AddClassPostConstruct("screens/redux/wardrobescreen", IndicatorScreenPostInit) -- Wardrobe

    -- Compendium
    AddClassPostConstruct("screens/redux/characterbioscreen", IndicatorScreenPostInit) -- Survivors
end

--- KnownModIndex
-- @section knownmodindex

if GetModConfigData("hide_changelog") then
    Utils.HideChangelog(modname, true)
end
