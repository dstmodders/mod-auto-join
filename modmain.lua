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
-- Player-related
--

local function ServerListingScreenPostInit(_self)
    local ServerPreferences = _G.ServerPreferences

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

    _self.autojoinbtn = AutoJoin:MakeAutoJoinButton(_self.side_panel, serverfn, OnAutoJoinSuccess, OnAutoJoinCancel)
    _self.autojoindefaultbtn = AutoJoin:MakeJoinButton(_self.side_panel, OnJoinClick)
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
            and (AutoJoin:CompareTable(selectedserver, self.selected_server) == false
            or self.details_hidden_name ~= isnamehidden)
        then
            _self.autojoinbtn:Enable()
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
AutoJoin:Init()

-- config
AutoJoin.configwaitingtime = GetModConfigData("waiting_time")

DebugConfigString("Waiting time:", "waiting_time")
