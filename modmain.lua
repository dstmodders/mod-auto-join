--
-- Globals
--

local _G = GLOBAL
local require = _G.require
local TheNet = _G.TheNet

--
-- Requires
--

local AutoJoin = require "autojoin"
local AutoJoinDefaultButton = require "widgets/autojoindefaultbutton"
local AutoJoinIconButton = require "widgets/autojoiniconbutton"

--
-- Assets
--

Assets = {
    Asset("ATLAS", "images/auto_join_icons.xml"),
    Asset("IMAGE", "images/auto_join_icons.tex"),
}

--
-- GetModConfigData-related
--

local _DEBUG = GetModConfigData("debug")
local _INDICATOR = GetModConfigData("indicator")

--
-- Debugging-related
--

local DebugFn = _DEBUG and function(...)
    local msg = string.format("[%s]", modname)
    for i = 1, arg.n do
        msg = msg .. " " .. tostring(arg[i])
    end
    print(msg)
end or function()
    --nil
end

local function DebugString(...)
    DebugFn(...)
end

local function DebugConfigString(description, name)
    DebugFn("[config]", description .. ":", GetModConfigData(name))
end

--
-- Server Listing Screen
--

local function ServerListingScreenPostInit(_self)
    local getmetatable = _G.getmetatable
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

    AutoJoin.defaultbtn = _self.side_panel:AddChild(AutoJoinDefaultButton(OnJoinClick))
    AutoJoin.iconbtn = _self.side_panel:AddChild(AutoJoinIconButton(
        AutoJoin:GetBtnOnClickFn(serverfn, OnAutoJoinSuccess, OnAutoJoinCancel),
        AutoJoin:GetBtnIsActiveFn()
    ))

    _self.autojoindefaultbtn = AutoJoin.defaultbtn
    _self.autojoiniconbtn = AutoJoin.iconbtn
    _self.join_button:Hide()

    --
    -- Overrides
    --

    local OldUpdateServerData = _self.UpdateServerData
    local OldSetRowColour = _self.SetRowColour

    local function NewUpdateServerData(self, selected_index_actual)
        OldUpdateServerData(self, selected_index_actual)

        local selectedserver = TheNet:GetServerListingFromActualIndex(selected_index_actual)
        local isnamehidden = selectedserver and ServerPreferences:IsNameAndDescriptionHidden(selectedserver) or false
        if selectedserver
            and (CompareTable(selectedserver, self.selected_server) == false
            or self.details_hidden_name ~= isnamehidden)
        then
            _self.autojoiniconbtn:Enable()
            _self.autojoindefaultbtn:Enable()
        end
    end

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

    _self.UpdateServerData = NewUpdateServerData
    _self.SetRowColour = NewSetRowColour

    DebugString("ServerListingScreen initialized")
end

AddClassPostConstruct("screens/redux/serverlistingscreen", ServerListingScreenPostInit)

--
-- Indicators
--

local function IndicatorScreenPostInit(_self)
    _self.autojoinindicator = nil

    if not _self.autojoinindicator then
        _self.autojoinindicator = AutoJoin:AddIndicator(_self)
    end

    --
    -- Overrides
    --

    local OldOnDestroy = _self.OnDestroy

    local function NewOnDestroy(self)
        DebugString(self.name, "destroyed")
        OldOnDestroy(self)
        if self.autojoinindicator then
            AutoJoin:RemoveIndicator(self.autojoinindicator)
            self.autojoinindicator = nil
        end
    end

    _self.OnDestroy = NewOnDestroy

    DebugString(_self.name, "initialized")
end

local function MultiplayerMainScreenPostInit(_self)
    _self.autojoinindicator = nil

    --
    -- Overrides
    --

    local OldOnHide = _self.OnHide
    local OldOnShow = _self.OnShow

    local function NewOnShow(self)
        DebugString(self.name, "is shown")
        OldOnShow(self)
        if not self.autojoinindicator then
            self.autojoinindicator = AutoJoin:AddIndicator(self.fixed_root, function()
                return self.autojoinindicator
            end)
        end
    end

    local function NewOnHide(self)
        DebugString(self.name, "is hidden")
        OldOnHide(self)
        if self.autojoinindicator then
            AutoJoin:RemoveIndicator(self.autojoinindicator)
            self.autojoinindicator = nil
        end
    end

    _self.OnHide = NewOnHide
    _self.OnShow = NewOnShow

    DebugString(_self.name, "initialized")
end

if _INDICATOR then
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
-- AutoJoin
--

AutoJoin:SetDebugFn(DebugFn)
AutoJoin:DoInit()

-- config
AutoJoin.configindicator = GetModConfigData("indicator")
AutoJoin.configindicatorpadding = GetModConfigData("indicator_padding")
AutoJoin.configindicatorposition = GetModConfigData("indicator_position")
AutoJoin.configindicatorscale = GetModConfigData("indicator_scale")
AutoJoin.configwaitingtime = GetModConfigData("waiting_time")

DebugConfigString("Indicator padding:", "indicator_padding")
DebugConfigString("Indicator position:", "indicator_position")
DebugConfigString("Indicator scale:", "indicator_scale")
DebugConfigString("Indicator:", "indicator")
DebugConfigString("Waiting time:", "waiting_time")
