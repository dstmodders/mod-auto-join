----
-- Modmain.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.6.0-alpha
----
local _G = GLOBAL
local require = _G.require

local AutoJoin = require "autojoin"
local Utils = require "autojoin/utils"

--- Assets
-- @section assets

Assets = {
    Asset("ANIM", "anim/auto_join_states.zip"),
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

--- Helpers
-- @section helpers

local function GetKeyFromConfig(config)
    local key = GetModConfigData(config)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

--- Initialization
-- @section initialization

AutoJoin:DoInit(modname)

-- GetModConfigData
local configs = {
    "indicator",
    "indicator_padding",
    "indicator_position",
    "indicator_scale",
    "main_screen_button",
    "rejoin_initial_wait",
    "waiting_time",
}

for _, config in ipairs(configs) do
    AutoJoin.config[config] = GetModConfigData(config)
end

AutoJoin.config["key_rejoin"] = GetKeyFromConfig("key_rejoin")

--- Indicator
-- @section indicator

local function IndicatorScreenPostInit(screen)
    screen.mod_auto_join_indicator = nil
    if not screen.mod_auto_join_indicator then
        screen.mod_auto_join_indicator = AutoJoin:AddIndicator(screen)
    end

    -- overrides Screen:OnDestroy()
    local OldOnDestroy = screen.OnDestroy
    screen.OnDestroy = function(self)
        DebugString(self.name, "destroyed")
        OldOnDestroy(self)
        if self.mod_auto_join_indicator then
            AutoJoin:RemoveIndicator(self.mod_auto_join_indicator)
            self.mod_auto_join_indicator = nil
        end
    end

    -- self
    DebugInit(screen.name)
end

if GetModConfigData("indicator") then
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

--- Multiplayer Main Screen
-- @section multiplayer-main-screen

AddClassPostConstruct("screens/redux/multiplayermainscreen", function(multiplayermainscreen)
    AutoJoin:OverrideMultiplayerMainScreen(multiplayermainscreen)
end)

--- Server Listing Screen
-- @section server-listing-screen

AddClassPostConstruct("screens/redux/serverlistingscreen", function(serverlistingscreen)
    AutoJoin:OverrideServerListingScreen(serverlistingscreen)
end)

--- KnownModIndex
-- @section knownmodindex

if GetModConfigData("hide_changelog") then
    Utils.Modmain.HideChangelog(modname, true)
end
