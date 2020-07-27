----
-- Auto-join.
--
-- Includes auto-joining features/functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod AutoJoin
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-alpha
----
local AutoJoinPasswordScreen = require "screens/autojoinpasswordscreen"
local Indicator = require "widgets/autojoin/indicator"
local PopupDialogScreen = require "screens/redux/popupdialog"
local Utils = require "autojoin/utils"

local _AUTO_JOIN_THREAD_ID = "auto_join_thread"

local AutoJoin = Class(function(self)
    self:DoInit()
end)

--
-- General
--

-- an override of the JoinServer() global function from the networking module
local function JoinServerOverride(server_listing, optional_password_override)
    local function send_response(password)
        if TheNet:JoinServerResponse(false, server_listing.guid, password) then
            DisableAllDLC()
        end
        ShowConnectingToGamePopup()
    end

    local function on_cancelled()
        TheNet:JoinServerResponse(true)
        local screen = TheFrontEnd:GetActiveScreen()
        if screen ~= nil and screen.name == "ConnectingToGamePopup" then
            screen:Close()
        end
    end

    local function after_mod_warning()
        if server_listing.has_password
            and (optional_password_override == "" or optional_password_override == nil)
        then
            local screen = AutoJoinPasswordScreen(nil, function(_, string)
                send_response(string)
            end, function()
                on_cancelled()
            end)

            TheFrontEnd:PushScreen(screen)
            screen:ForceInput()
        else
            send_response(optional_password_override or "")
        end
    end

    local function after_client_mod_message()
        after_mod_warning()
    end

    if server_listing.client_mods_disabled
        and not IsMigrating()
        and (server_listing.dedicated or not server_listing.owner)
        and AreAnyClientModsEnabled()
    then
        TheFrontEnd:PushScreen(PopupDialogScreen(
            STRINGS.UI.SERVERLISTINGSCREEN.CLIENT_MODS_DISABLED_TITLE,
            STRINGS.UI.SERVERLISTINGSCREEN.CLIENT_MODS_DISABLED_BODY,
            {
                {
                    text = STRINGS.UI.SERVERLISTINGSCREEN.CONTINUE,
                    cb = function()
                        TheFrontEnd:PopScreen()
                        after_client_mod_message()
                    end
                }
            }
        ))
    else
        after_client_mod_message()
    end
end

function AutoJoin:Join(server, password)
    self:DebugString("Joining server...")
    JoinServer(server, password)
end

function AutoJoin:Override()
    if not self.old_join_server_fn then
        self.old_join_server_fn = JoinServer
    end

    if not self.old_on_network_disconnect_fn then
        self.old_on_network_disconnect_fn = OnNetworkDisconnect
    end

    if not self.old_show_connecting_to_game_popup_fn then
        self.old_show_connecting_to_game_popup_fn = ShowConnectingToGamePopup
    end

    if not self.old_join_server_fn
        or not self.old_on_network_disconnect_fn
        or not self.old_show_connecting_to_game_popup_fn
    then
        self:DebugError("AutoJoin:Override() has failed storing one of the functions")
        return
    end

    JoinServer = JoinServerOverride

    OnNetworkDisconnect = function(message)
        self:DebugString("Disconnected:", message)
        return false
    end

    ShowConnectingToGamePopup = function()
        return false
    end

    self.is_ui_disabled = true

    self:DebugString("JoinServer overridden")
    self:DebugString("OnNetworkDisconnect overridden")
    self:DebugString("ShowConnectingToGamePopup overridden")
end

function AutoJoin:OverrideRestore()
    JoinServer = self.old_join_server_fn
    OnNetworkDisconnect = self.old_on_network_disconnect_fn
    ShowConnectingToGamePopup = self.old_show_connecting_to_game_popup_fn

    self.is_ui_disabled = false

    self:DebugString("JoinServer restored")
    self:DebugString("OnNetworkDisconnect restored")
    self:DebugString("ShowConnectingToGamePopup restored")
end

--
-- Indicators
--

function AutoJoin:GetIndicatorOnClickFn(cancelcb)
    return function()
        self:DebugString("Auto-joining has been cancelled")
        self:StopAutoJoining()
        self:RemoveAllIndicators()
        if cancelcb then
            cancelcb(self)
        end
    end
end

function AutoJoin:AddIndicator(root)
    local indicator = root:AddChild(Indicator(
        self.server,
        self:GetIndicatorOnClickFn(),
        self:GetBtnIsActiveFn(),
        self.config.indicator_position,
        self.config.indicator_padding,
        self.config.indicator_scale
    ))
    table.insert(self.indicators, indicator)
    return indicator
end

function AutoJoin:RemoveIndicator(indicator)
    for k, v in ipairs(self.indicators) do
        if indicator.inst.GUID == v.inst.GUID then
            v:Kill()
            table.remove(self.indicators, k)
        end
    end
end

function AutoJoin:RemoveAllIndicators()
    for _, v in ipairs(self.indicators) do
        v:Kill()
    end
    self.indicators = {}
end

function AutoJoin:SetIndicatorsSeconds(seconds)
    for _, v in ipairs(self.indicators) do
        if v.inst:IsValid() then
            v:SetSeconds(seconds)
        end
    end
end

--
-- Server Listing Screen
--

function AutoJoin:GetBtnIsActiveFn()
    return function()
        return self:IsAutoJoining()
    end
end

function AutoJoin:GetBtnOnClickFn(serverfn, successcb, cancelcb)
    local function Join(server, password)
        self:StopAutoJoining()

        if not self:IsAutoJoining() then
            self:StartAutoJoining(server, password)
        end

        self.join_btn:Enable()

        if successcb then
            successcb(self)
        end
    end

    local function OnCancel(server)
        self:StopAutoJoining()

        if server then
            self.join_btn:Enable()
            self.auto_join_btn:Enable()
        else
            self.join_btn:Disable()
            self.auto_join_btn:Disable()
        end

        if cancelcb then
            cancelcb(self)
        end
    end

    return function()
        if not self.join_btn then
            self:DebugError("AutoJoin.joinbtn is required")
            return
        end

        local server = serverfn()
        if server and server.has_password and not self:IsAutoJoining() then
            self:DebugString("Auto-joining the password-protected server:", server.name)
            self:DebugString("Prompting password...")
            local screen = AutoJoinPasswordScreen(server, Join, OnCancel)
            TheFrontEnd:PushScreen(screen)
            screen:ForceInput()
        elseif server and not self:IsAutoJoining() then
            self:DebugString("Auto-joining the server:", server.name)
            OnCancel(server)
            Join(server)
        elseif self:IsAutoJoining() then
            self:DebugString("Auto-joining has been cancelled")
            OnCancel(server)
        end
    end
end

--
-- Auto-joining
--

local function IsServerListed(guid)
    local servers = TheNet:GetServerListings()
    if servers and #servers > 0 then
        for _, v in ipairs(servers) do
            if v.guid == guid then
                return true
            end
        end
    end
    return false
end

function AutoJoin:IsAutoJoining()
    return self.is_auto_joining
end

function AutoJoin:StartAutoJoining(server, password)
    if not self.is_ui_disabled then
        self:Override()
    end

    self:StartAutoJoinThread(server, password)
end

function AutoJoin:StopAutoJoining()
    self:ClearAutoJoinThread()

    self.is_auto_joining = false
    TheNet:JoinServerResponse(true)

    if self.is_ui_disabled then
        self:OverrideRestore()
    end

    if self.auto_join_btn and self.auto_join_btn.inst:IsValid() then
        self.auto_join_btn:Inactive()
    end
end

function AutoJoin:StartAutoJoinThread(server, password)
    if not server then
        return server
    end

    self.auto_join_thread = StartThread(function()
        local defaultrefreshseconds, defaultseconds
        local refreshseconds, seconds
        local isservernotlisted

        defaultrefreshseconds = 30
        defaultseconds = self.config.waiting_time
        isservernotlisted = false
        refreshseconds = defaultrefreshseconds
        seconds = defaultseconds

        self:DebugString("Thread started")
        self:DebugString(string.format("Auto-joining every %d seconds...", seconds))
        self:DebugString(string.format("Refreshing every %d seconds...", refreshseconds))

        self.is_auto_joining = true

        if self.auto_join_btn and self.auto_join_btn.inst:IsValid() then
            self.auto_join_btn:Active()
        end

        self:Join(server, password)

        while self.is_auto_joining do
            if not isservernotlisted
                and not TheNet:IsSearchingServers(PLATFORM ~= "WIN32_RAIL")
                and not IsServerListed(server.guid)
            then
                isservernotlisted = true
                self:DebugString("Server is not listed")
            end

            if refreshseconds <= 0 then
                if isservernotlisted
                    and not TheNet:IsSearchingServers(PLATFORM ~= "WIN32_RAIL")
                    and not IsServerListed(server.guid)
                then
                    refreshseconds = 30 + 1
                    isservernotlisted = false
                    self:DebugString("Refreshing the server listing...")
                    TheNet:SearchServers()
                end
            end

            if self.auto_join_btn and self.auto_join_btn.inst:IsValid() then
                self.auto_join_btn:SetSeconds(seconds)
            end

            self:SetIndicatorsSeconds(seconds)

            if seconds < 1 then
                seconds = defaultseconds + 1
                self:Join(server, password)
            end

            seconds = seconds - 1
            refreshseconds = refreshseconds - 1

            Sleep(FRAMES / FRAMES * 1)
        end

        self:ClearAutoJoinThread()
    end, _AUTO_JOIN_THREAD_ID)
end

function AutoJoin:ClearAutoJoinThread()
    if self.auto_join_thread then
        self:DebugString("[" .. self.auto_join_thread.id .. "]", "Thread cleared")
        KillThreadsWithID(self.auto_join_thread.id)
        self.auto_join_thread:SetList(nil)
        self.auto_join_thread = nil
    end
end

--
-- Initialization
--

function AutoJoin:DoInit()
    Utils.AddDebugMethods(self)

    -- indicators
    self.indicators = {}

    -- server listing screen
    self.auto_join_btn = nil
    self.join_btn = nil

    -- auto-joining
    self.auto_join_thread = nil
    self.is_auto_joining = nil
    self.is_ui_disabled = false
    self.server = nil

    -- overrides
    self.old_join_server_fn = nil
    self.old_on_network_disconnect_fn = nil
    self.old_show_connecting_to_game_popup_fn = nil

    -- config
    self.config = {
        indicator = true,
        indicator_padding = 10,
        indicator_position = "tr",
        indicator_scale = 1.3,
        waiting_time = 15,
    }

    self:DebugInit("AutoJoin")
end

return AutoJoin
