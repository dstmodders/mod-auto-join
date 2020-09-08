----
-- Auto-join.
--
-- Entry point for all mod-related features which is initialized as soon as the mod loads. Holds
-- auto-joining state and functionality by overriding some global functions.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod AutoJoin
-- @see screens.AutoJoinPasswordScreen
-- @see widgets.Indicator
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.6.0-alpha
----
require "autojoin/constants"
require "class"

local AutoJoinPasswordScreen = require "screens/autojoinpasswordscreen"
local DevToolsSubmenu = require "autojoin/devtoolssubmenu"
local Indicator = require "widgets/autojoin/indicator"
local PopupDialogScreen = require "screens/redux/popupdialog"
local Utils = require "autojoin/utils"

local _AUTO_JOIN_THREAD_ID = "auto_join_thread"

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @usage local autojoin = AutoJoin()
local AutoJoin = Class(function(self)
    self:DoInit()
end)

--- Helpers
-- @section helpers

-- an override for global `JoinServer` function from the networking module
local function JoinServerOverride(self, server_listing, optional_password_override)
    local function OnSuccess(password)
        self:SetState(MOD_AUTO_JOIN.STATE.CONNECT, true)
        if TheNet:JoinServerResponse(false, server_listing.guid, password) then
            DisableAllDLC()
        end
        ShowConnectingToGamePopup()
    end

    local function OnCancel()
        self:SetState(MOD_AUTO_JOIN.STATE.DEFAULT, true)
        TheNet:JoinServerResponse(true)
        local screen = TheFrontEnd:GetActiveScreen()
        if screen ~= nil and screen.name == "ConnectingToGamePopup" then
            screen:Close()
        end
    end

    local function AfterModWarning()
        if server_listing.has_password
            and (optional_password_override == "" or optional_password_override == nil)
        then
            local screen = AutoJoinPasswordScreen(nil, function(_, string)
                OnSuccess(string)
            end, function()
                OnCancel()
            end)

            TheFrontEnd:PushScreen(screen)
            screen:ForceInput()
        else
            OnSuccess(optional_password_override or "")
        end
    end

    local function AfterClientModMessage()
        AfterModWarning()
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
                        AfterClientModMessage()
                    end
                }
            }
        ))
    else
        AfterClientModMessage()
    end
end

--- General
-- @section general

--- Gets state.
-- @treturn number
function AutoJoin:GetState()
    return self.state
end

--- Sets state.
-- @tparam number state
-- @tparam boolean ignore_focus
function AutoJoin:SetState(state, ignore_focus)
    self.state = state
    self:UpdateButton(ignore_focus)
    self:UpdateIndicators()
end

--- Joins a server.
--
-- Just a convenience wrapper for `JoinServer`.
--
-- @tparam table server Server data
-- @tparam string password Server password
function AutoJoin:Join(server, password)
    self:DebugString("Joining server...")
    self:SetState(MOD_AUTO_JOIN.STATE.CONNECT, true)

    if not self.devtoolssubmenu.is_fake_auto_joining then
        JoinServer(server, password)
    else
        if self.auto_join_btn and self.auto_join_btn.inst:IsValid() then
            self.auto_join_btn.inst:DoTaskInTime(2, function()
                self:SetState(MOD_AUTO_JOIN.STATE.COUNTDOWN)
            end)
        else
            for _, v in ipairs(self.indicators) do
                v.inst:DoTaskInTime(2, function()
                    self:SetState(MOD_AUTO_JOIN.STATE.COUNTDOWN)
                end)
            end
        end
    end
end

--- Overrides global functions.
--
-- Overrides all corresponding global functions so that the joining process would become "silent".
-- Also, stores the previous functions respectively so that they could be restored later by calling
-- `OverrideRestore`.
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

    JoinServer = function(...)
        return JoinServerOverride(self, ...)
    end

    OnNetworkDisconnect = function(message)
        self:DebugString("Disconnected:", message)
        self:SetState(MOD_AUTO_JOIN.STATE.COUNTDOWN)
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

--- Restores overridden global functions.
--
-- Restores all corresponding global functions previously overridden by `Override`.
function AutoJoin:OverrideRestore()
    JoinServer = self.old_join_server_fn
    OnNetworkDisconnect = self.old_on_network_disconnect_fn
    ShowConnectingToGamePopup = self.old_show_connecting_to_game_popup_fn

    self.is_ui_disabled = false

    self:DebugString("JoinServer restored")
    self:DebugString("OnNetworkDisconnect restored")
    self:DebugString("ShowConnectingToGamePopup restored")
end

--- Indicators
-- @section indicators

--- Gets an indicator on-click function.
--
-- Returns a function for a corner indicator on-click action which stops auto-joining and removes
-- all existing indicators.
--
-- @tparam[opt] function cancel_cb Callback function on cancel
-- @treturn function
function AutoJoin:GetIndicatorOnClickFn(cancel_cb)
    return function()
        self:DebugString("Auto-joining has been cancelled")
        self:StopAutoJoining()
        self:RemoveAllIndicators()
        if cancel_cb then
            cancel_cb(self)
        end
    end
end

--- Gets indicators.
-- @treturn table
function AutoJoin:GetIndicators()
    return self.indicators
end

--- Creates and adds an indicator.
--
-- Creates a corner indicator and adds it to the table where all indicators are stored.
--
-- @tparam table root Parent widget
-- @treturn widgets.Indicator
function AutoJoin:AddIndicator(root)
    local indicator = root:AddChild(Indicator(
        self,
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

--- Removes an indicator.
--
-- Kills a corner indicator and removes it from the table where all indicators are stored.
--
-- @tparam widgets.Indicator indicator
-- @treturn boolean
function AutoJoin:RemoveIndicator(indicator)
    for k, v in ipairs(self.indicators) do
        if indicator.inst.GUID == v.inst.GUID then
            v:Kill()
            table.remove(self.indicators, k)
            return true
        end
    end
    return false
end

--- Removes all indicators.
--
-- Kills all corner indicators and resets the storage table.
function AutoJoin:RemoveAllIndicators()
    for _, v in ipairs(self.indicators) do
        v:Kill()
    end
    self.indicators = {}
end

--- Server listing screen
-- @section server-listing-screen

--- Gets an auto-joining state function.
--
-- Returns a function for checking if auto-joining is active or not.
--
-- @treturn function
function AutoJoin:GetBtnIsActiveFn()
    return function()
        return self:IsAutoJoining()
    end
end

--- Gets a button on-click function.
--
-- Returns a function for the "Auto-Join" button on-click action for both joining and cancelling.
-- Creates an `screens.AutoJoinPasswordScreen` screen and prompts for password if the server has
-- one.
--
-- @tparam function server_fn Function to return a server table
-- @tparam[opt] function success_cb Callback function on success
-- @tparam[opt] function cancel_cb Callback function on cancel
-- @treturn function
function AutoJoin:GetBtnOnClickFn(server_fn, success_cb, cancel_cb)
    local function OnJoin(server, password)
        self:StopAutoJoining()

        if not self:IsAutoJoining() then
            self:StartAutoJoining(server, password)
        end

        self.join_btn:Enable()

        if success_cb then
            success_cb(self)
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

        if cancel_cb then
            cancel_cb(self)
        end
    end

    return function()
        if not self.join_btn then
            self:DebugError("AutoJoin.join_btn is required")
            return
        end

        local server = server_fn()
        if server and server.has_password and not self:IsAutoJoining() then
            self:DebugString("Auto-joining the password-protected server:", server.name)
            self:DebugString("Prompting password...")
            local screen = AutoJoinPasswordScreen(server, OnJoin, OnCancel)
            TheFrontEnd:PushScreen(screen)
            screen:ForceInput()
        elseif server and not self:IsAutoJoining() then
            self:DebugString("Auto-joining the server:", server.name)
            OnCancel(server)
            OnJoin(server)
        elseif self:IsAutoJoining() then
            self:DebugString("Auto-joining has been cancelled")
            OnCancel(server)
        end
    end
end

--- Auto-joining
-- @section auto-joining

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

--- Starts auto-joining a server.
--
-- Overrides some functions by calling `Override` and starts the auto-joining thread by calling
-- `StartAutoJoinThread`.
--
-- @tparam table server Server data
-- @tparam[opt] string password Server password
function AutoJoin:StartAutoJoining(server, password)
    if not self.is_ui_disabled then
        self:Override()
    end
    self:StartAutoJoinThread(server, password)
end

--- Stops auto-joining a server.
--
-- Stops the auto-joining thread by calling `ClearAutoJoinThread`, restores previously overridden
-- functions by calling `OverrideRestore` and makes "Auto-Join" button inactive.
function AutoJoin:StopAutoJoining()
    self:ClearAutoJoinThread()
    self:SetState(MOD_AUTO_JOIN.STATE.DEFAULT, true)

    self.is_auto_joining = false
    self.seconds = self.default_seconds

    TheNet:JoinServerResponse(true)

    if self.is_ui_disabled then
        self:OverrideRestore()
    end
end

--- Gets the auto-joining state.
-- @treturn boolean
function AutoJoin:IsAutoJoining()
    return self.is_auto_joining
end

--- Starts the auto-joining thread.
--
-- Starts the thread to auto-join the provided server.
--
-- @tparam table server Server data
-- @tparam[opt] string password Server password
function AutoJoin:StartAutoJoinThread(server, password)
    if not server then
        return
    end

    local is_server_not_listed = false
    local refresh_seconds = self.default_refresh_seconds

    self.auto_join_thread = Utils.Thread.Start(_AUTO_JOIN_THREAD_ID, function()
        if not is_server_not_listed
            and not TheNet:IsSearchingServers(PLATFORM ~= "WIN32_RAIL")
            and not IsServerListed(server.guid)
        then
            is_server_not_listed = true
            self:DebugString("Server is not listed")
        end

        if refresh_seconds <= 0 then
            if is_server_not_listed
                and not TheNet:IsSearchingServers(PLATFORM ~= "WIN32_RAIL")
                and not IsServerListed(server.guid)
            then
                refresh_seconds = self.default_refresh_seconds + 1
                is_server_not_listed = false
                self:DebugString("Refreshing the server listing...")
                TheNet:SearchServers()
            end
        end

        if self.state == MOD_AUTO_JOIN.STATE.COUNTDOWN then
            self.seconds = self.seconds - 1
            refresh_seconds = refresh_seconds - 1

            if self.seconds < 1 then
                self.seconds = self.default_seconds
                self:Join(server, password)
            end

            self:UpdateButton()
            self:UpdateIndicators()
        end

        Sleep(1)
    end, function()
        return self.is_auto_joining
    end, function()
        self:DebugString(string.format("Auto-joining every %d seconds...", self.seconds))
        self:DebugString(string.format("Refreshing every %d seconds...", refresh_seconds))

        self.is_auto_joining = true

        self:Join(server, password)
    end, function()
        self.is_auto_joining = false
    end)
end

--- Stops the auto-joining thread.
--
-- Stops the thread started earlier by `StartAutoJoinThread`.
function AutoJoin:ClearAutoJoinThread()
    return Utils.Thread.Clear(self.auto_join_thread)
end

--- Update
-- @section update

--- Updates auto-join button.
-- @tparam boolean ignore_focus
function AutoJoin:UpdateButton(ignore_focus)
    if self.auto_join_btn and self.auto_join_btn.inst:IsValid() then
        self.auto_join_btn:SetState(self.state, ignore_focus)
        self.auto_join_btn:SetSeconds(self.seconds)
    end
end

--- Updates indicators.
function AutoJoin:UpdateIndicators()
    for _, v in ipairs(self.indicators) do
        if v.inst:IsValid() then
            v:SetState(self.state)
            v:SetSeconds(self.seconds)
        end
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
function AutoJoin:DoInit()
    Utils.Debug.AddMethods(self)

    -- general
    self.default_refresh_seconds = 30
    self.name = "AutoJoin"
    self.state = MOD_AUTO_JOIN.STATE.DEFAULT

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

    self.default_seconds = self.config.waiting_time
    self.seconds = self.default_seconds

    -- dev tools mod
    self.devtoolssubmenu = DevToolsSubmenu(self)

    -- self
    self:DebugInit(self.name)
end

return AutoJoin
