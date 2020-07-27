----
-- Modmain.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-alpha
----
local _G = GLOBAL
local require = _G.require

local AutoJoin = require "autojoin"
local AutoJoinButton = require "widgets/autojoin/autojoinbutton"
local JoinButton = require "widgets/autojoin/joinbutton"
local Utils = require "autojoin/utils"

--
-- Globals
--

local TheNet = _G.TheNet
local getmetatable = _G.getmetatable

--
-- Assets
--

Assets = {
    Asset("ATLAS", "images/auto_join_icons.xml"),
    Asset("IMAGE", "images/auto_join_icons.tex"),
}

--
-- Debugging
--

local Debug

if GetModConfigData("debug") then
    Debug = require "autojoin/debug"
    Debug:DoInit(modname)
    Debug:SetIsEnabled(true)
    Debug:DebugModConfigs()
end

_G.AutoJoinDebug = Debug

local function DebugString(...)
    return Debug and Debug:DebugString(...)
end

local function DebugInit(...)
    return Debug and Debug:DebugInit(...)
end

--
-- Initialization
--

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

if Debug then
    Debug:DebugModConfigs()
end

--
-- Server Listing Screen
--

local function ServerListingScreenPostInit(_self)
    local ServerPreferences = _G.ServerPreferences

    local function CompareTable(a, b)
        -- basic validation
        if a == b then
            return true
        end

        -- null check
        if a == nil or b == nil then
            return false
        end

        -- validate type
        if type(a) ~= "table" then
            return false
        end

        -- compare meta tables
        local meta_table_a = getmetatable(a)
        local meta_table_b = getmetatable(b)
        if not CompareTable(meta_table_a, meta_table_b) then
            return false
        end

        -- compare nested tables
        for index, va in pairs(a) do
            local vb = b[index]
            if not CompareTable(va, vb) then
                return false
            end
        end
        for index, vb in pairs(b) do
            local va = a[index]
            if not CompareTable(va, vb) then
                return false
            end
        end

        return true
    end

    --
    -- Buttons
    --

    local serverfn = function()
        return _self.selected_server
    end

    local function OnJoinClick()
        local server = serverfn()
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
        self.server = serverfn()
        _self.servers_scroll_list:RefreshView()
    end

    local function OnAutoJoinCancel(self)
        self.server = nil
        _self.servers_scroll_list:RefreshView()
    end

    AutoJoin.join_btn = _self.side_panel:AddChild(JoinButton(OnJoinClick))
    AutoJoin.auto_join_btn = _self.side_panel:AddChild(AutoJoinButton(
        AutoJoin:GetBtnOnClickFn(serverfn, OnAutoJoinSuccess, OnAutoJoinCancel),
        AutoJoin:GetBtnIsActiveFn()
    ))

    _self.auto_join_join_btn = AutoJoin.join_btn
    _self.auto_join_auto_join_btn = AutoJoin.auto_join_btn
    _self.join_button:Hide()

    --
    -- Overrides
    --

    local OldSetRowColour = _self.SetRowColour
    local OldUpdateServerData = _self.UpdateServerData

    local function NewSetRowColour(self, row_widget, colour)
        OldSetRowColour(self, row_widget, colour)

        local server = self.servers[row_widget.unfiltered_index]
        local autojoinserver = AutoJoin.server

        if server and autojoinserver then
            if self.servers[row_widget.unfiltered_index].guid == AutoJoin.server.guid then
                OldSetRowColour(self, row_widget, _G.UICOLOURS.GOLD)
            end
        end
    end

    local function NewUpdateServerData(self, selected_index_actual)
        OldUpdateServerData(self, selected_index_actual)

        local selectedserver = TheNet:GetServerListingFromActualIndex(selected_index_actual)
        local isnamehidden = selectedserver
            and ServerPreferences:IsNameAndDescriptionHidden(selectedserver)
            or false

        if selectedserver
            and (CompareTable(selectedserver, self.selected_server) == false
            or self.details_hidden_name ~= isnamehidden)
        then
            _self.auto_join_join_btn:Enable()
            _self.auto_join_auto_join_btn:Enable()
        end
    end

    _self.SetRowColour = NewSetRowColour
    _self.UpdateServerData = NewUpdateServerData

    DebugInit("ServerListingScreenPostInit")
end

AddClassPostConstruct("screens/redux/serverlistingscreen", ServerListingScreenPostInit)

--
-- Indicator
--

local function IndicatorScreenPostInit(_self)
    _self.auto_join_indicator = nil

    if not _self.auto_join_indicator then
        _self.auto_join_indicator = AutoJoin:AddIndicator(_self)
    end

    --
    -- Overrides
    --

    local OldOnDestroy = _self.OnDestroy

    local function NewOnDestroy(self)
        DebugString(self.name, "destroyed")
        OldOnDestroy(self)
        if self.auto_join_indicator then
            AutoJoin:RemoveIndicator(self.auto_join_indicator)
            self.auto_join_indicator = nil
        end
    end

    _self.OnDestroy = NewOnDestroy

    DebugInit(_self.name)
end

local function MultiplayerMainScreenPostInit(_self)
    _self.auto_join_indicator = nil

    --
    -- Overrides
    --

    local OldOnHide = _self.OnHide
    local OldOnShow = _self.OnShow

    local function NewOnShow(self)
        DebugString(self.name, "is shown")
        OldOnShow(self)
        if not self.auto_join_indicator then
            self.auto_join_indicator = AutoJoin:AddIndicator(self.fixed_root, function()
                return self.auto_join_indicator
            end)
        end
    end

    local function NewOnHide(self)
        DebugString(self.name, "is hidden")
        OldOnHide(self)
        if self.auto_join_indicator then
            AutoJoin:RemoveIndicator(self.auto_join_indicator)
            self.auto_join_indicator = nil
        end
    end

    _self.OnHide = NewOnHide
    _self.OnShow = NewOnShow

    DebugInit(_self.name)
end

if GetModConfigData("indicator") then
    AddClassPostConstruct("screens/redux/multiplayermainscreen", MultiplayerMainScreenPostInit) -- Main Screen

    -- Main Screen
    AddClassPostConstruct("screens/redux/servercreationscreen", IndicatorScreenPostInit) -- Host Game
    AddClassPostConstruct("screens/redux/playersummaryscreen", IndicatorScreenPostInit) -- Item Collection
    AddClassPostConstruct("screens/redux/optionsscreen", IndicatorScreenPostInit) -- Options
    AddClassPostConstruct("screens/redux/modsscreen", IndicatorScreenPostInit) -- Mods
    AddClassPostConstruct("screens/redux/modconfigurationscreen", IndicatorScreenPostInit) -- Mods (Configuration)

    -- Item Collection
    AddClassPostConstruct("screens/redux/collectionscreen", IndicatorScreenPostInit) -- Curio Cabinet
    AddClassPostConstruct("screens/redux/mysteryboxscreen", IndicatorScreenPostInit) -- Treasury
    AddClassPostConstruct("screens/redux/morguescreen", IndicatorScreenPostInit) -- History
    AddClassPostConstruct("screens/tradescreen", IndicatorScreenPostInit) -- Trade Inn
    AddClassPostConstruct("screens/crowgamescreen", IndicatorScreenPostInit) -- Trade Inn (Crow Game)
    AddClassPostConstruct("screens/redeemdialog", IndicatorScreenPostInit) -- Redeem Codes
    AddClassPostConstruct("screens/redux/purchasepackscreen", IndicatorScreenPostInit) -- Shop
    AddClassPostConstruct("screens/redux/achievementspopup", IndicatorScreenPostInit) -- Achievements
end

--
-- KnownModIndex
--

if GetModConfigData("hide_changelog") then
    Utils.HideChangelog(modname, true)
end
