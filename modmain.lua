----
-- Modmain.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-auto-join](https://github.com/dstmodders/dst-mod-auto-join)
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2019
-- @license MIT
-- @release 0.9.0-alpha
----
local _G = GLOBAL
local require = _G.require

--- Globals
-- @section globals

local shallowcopy = _G.shallowcopy

--- SDK
-- @section sdk

local SDK

SDK = require "autojoin/sdk/sdk/sdk"
SDK.Load(env, "autojoin/sdk", {
    "Debug",
    "PersistentData",
    "Thread",
})

--- Assets
-- @section assets

Assets = {
    -- animations
    Asset("ANIM", "anim/auto_join_states.zip"),

    -- images
    Asset("ATLAS", "images/auto_join_statuses.xml"),
    Asset("IMAGE", "images/auto_join_statuses.tex"),
}

--- Debugging
-- @section debugging

SDK.Debug.SetIsEnabled(GetModConfigData("debug") and true or false)
SDK.Debug.ModConfigs()

--- Helpers
-- @section helpers

local function GetKeyFromConfig(config)
    local key = GetModConfigData(config)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

--- Initialization
-- @section initialization

local AutoJoin = require "autojoin"

AutoJoin:DoInit()

-- GetModConfigData
local configs = {
    "indicator",
    "indicator_padding",
    "indicator_position",
    "indicator_scale",
    "rejoin_initial_wait",
    "rejoin_main_screen_button",
    "rejoin_pause_screen_button",
    "waiting_time",
    "disable_music",
    "notification_sound",
}

for _, config in ipairs(configs) do
    AutoJoin.config[config] = GetModConfigData(config)
end

AutoJoin.config["key_rejoin"] = GetKeyFromConfig("key_rejoin")
AutoJoin.config_default = shallowcopy(AutoJoin.config)

--- Music Disabler
-- @section music disabler

if GetModConfigData("disable_music") then
    AddGamePostInit(function()
        local TheFrontEnd = _G.TheFrontEnd
        local SoundManager = TheFrontEnd:GetSound()
        local SoundManager_mt = _G.getmetatable(SoundManager)
        local __index = SoundManager_mt.__index
        local old_PlaySound = __index.PlaySound
        local old_KillSound = __index.KillSound
        TheFrontEnd.autojoin_FEMusic = _G.FE_MUSIC

        -- overrides TheFrontEnd:GetSound():PlaySound()
        __index.PlaySound = function(self, theme, name, ...)
            if name == "FEMusic" then
                TheFrontEnd.autojoin_FEMusic = theme
                if AutoJoin:IsAutoJoining() then
                    return nil
                end
            end
            return old_PlaySound(self, theme, name, ...)
        end

        -- overrides TheFrontEnd:GetSound():KillSound()
        __index.KillSound = function(self, name, ...)
            if AutoJoin:IsAutoJoining() and name == "FEMusic" then
                TheFrontEnd.autojoin_FEMusic = nil
            end
            return old_KillSound(self, name, ...)
        end
    end)
end

--- Notification Sound
-- @section notification sound

if GetModConfigData("notification_sound") then
    local old_StartNextInstance = _G.StartNextInstance

    -- overrides StartNextInstance()
    _G.StartNextInstance = function(in_params, ...)
        local params = in_params or {}
        if AutoJoin:IsAutoJoining() then
            params.autojoin_giveNotification = true
        end
        return old_StartNextInstance(params, ...)
    end

    AddClassPostConstruct("widgets/redux/loadingwidget", function()
        if _G.Settings.autojoin_giveNotification then
            _G.Settings.autojoin_giveNotification = nil
            _G.TheFrontEnd:GetSound():PlaySound(GetModConfigData("notification_sound"))
        end
    end)
end

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
        SDK.Debug.Term(self.name)
        OldOnDestroy(self)
        if self.mod_auto_join_indicator then
            AutoJoin:RemoveIndicator(self.mod_auto_join_indicator)
            self.mod_auto_join_indicator = nil
        end
    end

    SDK.Debug.Init(screen.name)
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

--- Pause Screen
-- @section pause-screen

AddClassPostConstruct("screens/redux/pausescreen", function(pausescreen)
    AutoJoin:OverridePauseScreen(pausescreen)
end)

--- Server Listing Screen
-- @section server-listing-screen

AddClassPostConstruct("screens/redux/serverlistingscreen", function(serverlistingscreen)
    AutoJoin:OverrideServerListingScreen(serverlistingscreen)
end)
