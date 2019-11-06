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

            AutoJoin:ClearAutoJoinThread()
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

    AutoJoin.joinbtn = _self.side_panel:AddChild(AutoJoinDefaultButton(OnJoinClick))
    AutoJoin.autojoinbtn = _self.side_panel:AddChild(AutoJoinIconButton(
        AutoJoin:GetBtnOnClickFn(serverfn, OnAutoJoinSuccess, OnAutoJoinCancel),
        AutoJoin:GetBtnIsActiveFn()
    ))

    _self.autojoindefaultbtn = AutoJoin.joinbtn
    _self.autojoiniconbtn = AutoJoin.autojoinbtn
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
-- AutoJoin
--

AutoJoin:SetDebugFn(DebugFn)

-- config
AutoJoin.configwaitingtime = GetModConfigData("waiting_time")

DebugConfigString("Waiting time:", "waiting_time")
