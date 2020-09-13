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
-- @release 0.7.0-alpha
----
require "autojoin/constants"
require "class"

local AutoJoinButton = require "widgets/autojoin/autojoinbutton"
local AutoJoinPasswordScreen = require "screens/autojoinpasswordscreen"
local Data = require "autojoin/data"
local DevToolsSubmenu = require "autojoin/devtoolssubmenu"
local Indicator = require "widgets/autojoin/indicator"
local JoinButton = require "widgets/autojoin/joinbutton"
local PopupDialogScreen = require "screens/redux/popupdialog"
local RejoinButton = require "widgets/autojoin/rejoinbutton"
local Utils = require "autojoin/utils"

local _AUTO_JOIN_THREAD_ID = "mod_auto_join_thread"
local _LAST_JOIN_SERVER

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @usage local autojoin = AutoJoin(modname)
local AutoJoin = Class(function(self, modname)
    self:DoInit(modname)
end)

--- Helpers
-- @section helpers

-- an override for global `JoinServer` function from the networking module
local function JoinServerOverride(self, server_listing, optional_password_override)
    local function OnSuccess(password)
        if server_listing.world_gen_data and server_listing._processed_world_gen_data then
            _LAST_JOIN_SERVER = {
                server_listing = server_listing,
                optional_password_override = optional_password_override,
            }

            self.data:GeneralSet("last_join_server", _LAST_JOIN_SERVER)
            self.data:Save()
        end

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

local function NormalizeKey(key)
    key = (key == KEY_LALT or key == KEY_RALT) and KEY_ALT or key
    key = (key == KEY_LCTRL or key == KEY_RCTRL) and KEY_CTRL or key
    key = (key == KEY_LSHIFT or key == KEY_RSHIFT) and KEY_SHIFT or key
    return key
end

--- Overrides
-- @section overrides

local OldJoinServer = JoinServer
JoinServer = function(server_listing, optional_password_override)
    if server_listing.world_gen_data and server_listing._processed_world_gen_data then
        _LAST_JOIN_SERVER = {
            server_listing = server_listing,
            optional_password_override = optional_password_override,
        }

        AutoJoin.data:GeneralSet("last_join_server", _LAST_JOIN_SERVER)
        AutoJoin.data:Save()
    end
    OldJoinServer(server_listing, optional_password_override)
end

--- General
-- @section general

--- Gets last join server.
-- @treturn table
function AutoJoin:GetLastJoinServer() -- luacheck: only
    return _LAST_JOIN_SERVER
end

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

--- Gets status.
-- @treturn number
function AutoJoin:GetStatus()
    return self.status
end

--- Sets status.
-- @tparam number status
-- @tparam[opt] string message
function AutoJoin:SetStatus(status, message)
    self.status = status
    if message then
        self.status_message = message
    end
    self:UpdateButtonStatus()
    self:UpdateIndicatorsStatus()
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
    if not self.is_fake_joining then
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

    JoinServer = function(server_listing, optional_password_override)
        return JoinServerOverride(self, server_listing, optional_password_override)
    end

    OnNetworkDisconnect = function(message)
        self:DebugString("Disconnected:", message)
        self:SetState(MOD_AUTO_JOIN.STATE.COUNTDOWN)
        self:SetStatus(MOD_AUTO_JOIN.STATUS.UNKNOWN, message)

        if message == "ID_INVALID_PASSWORD" then
            self:SetStatus(MOD_AUTO_JOIN.STATUS.INVALID_PASSWORD)
        elseif message == "ID_CONNECTION_ATTEMPT_FAILED" then
            self:SetStatus(MOD_AUTO_JOIN.STATUS.NOT_RESPONDING)
        elseif message == "ID_DST_NO_FREE_PLAYER_SLOTS" then
            self:SetStatus(MOD_AUTO_JOIN.STATUS.FULL)
        end

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

--- Rejoin
-- @section rejoin

--- Rejoins the last server.
-- @tparam[opt] MultiplayerMainScreen multiplayermainscreen
-- @tparam[opt] number wait
function AutoJoin:Rejoin(multiplayermainscreen, wait)
    local server_listing = Utils.Chain.Get(_LAST_JOIN_SERVER, "server_listing")
    local optional_password_override = Utils.Chain.Get(
        _LAST_JOIN_SERVER,
        "optional_password_override"
    )

    if not server_listing then
        self:DebugError("[rejoin]")
    end

    -- disconnect and search servers
    TheNet:Disconnect(false)
    TheNet:SearchLANServers(TheNet:IsOnlineMode())
    TheNet:SearchServers()

    -- multiplayer main screen
    if multiplayermainscreen then
        self:CancelRejoin(multiplayermainscreen)

        if multiplayermainscreen.mod_auto_join_indicator then
            self:RemoveIndicator(multiplayermainscreen.mod_auto_join_indicator)
        end

        multiplayermainscreen.mod_auto_join_indicator = AutoJoin:AddIndicator(
            multiplayermainscreen.fixed_root,
            function()
                return multiplayermainscreen.mod_auto_join_indicator
            end
        )

        multiplayermainscreen.mod_auto_join_indicator:Show()
    end

    -- start
    self:DebugString("[rejoin]", "Rejoining the last server...")
    self:StartAutoJoining(server_listing, optional_password_override, nil, wait)
end

--- Cancels rejoin.
-- @tparam[opt] MultiplayerMainScreen multiplayermainscreen
function AutoJoin:CancelRejoin(multiplayermainscreen)
    self:DebugString("[rejoin]", "Stopping rejoining...")
    self:StopAutoJoining()
    if multiplayermainscreen and multiplayermainscreen.mod_auto_join_indicator then
        AutoJoin:RemoveIndicator(multiplayermainscreen.mod_auto_join_indicator)
    end
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

--- Auto-Joining
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
-- @tparam[opt] number initial_wait Initial wait in seconds
-- @tparam[opt] number wait Wait in seconds
function AutoJoin:StartAutoJoining(server, password, initial_wait, wait)
    if not self.is_ui_disabled then
        self:Override()
    end

    if self.is_auto_joining then
        self:ClearAutoJoinThread()
    end

    self:StartAutoJoinThread(server, password, initial_wait, wait)
end

--- Stops auto-joining a server.
--
-- Stops the auto-joining thread by calling `ClearAutoJoinThread`, restores previously overridden
-- functions by calling `OverrideRestore` and makes "Auto-Join" button inactive.
function AutoJoin:StopAutoJoining()
    self:ClearAutoJoinThread()
    self:SetState(MOD_AUTO_JOIN.STATE.DEFAULT, true)
    self:SetStatus(nil)

    self.is_auto_joining = false
    self.seconds = self.config.waiting_time

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
-- @tparam[opt] number initial_wait Initial wait in seconds [default: 3 (from configs)]
-- @tparam[opt] number wait Wait in seconds (default: 15 (from configs))
function AutoJoin:StartAutoJoinThread(server, password, initial_wait, wait)
    initial_wait = initial_wait ~= nil and initial_wait or self.config.rejoin_initial_wait
    wait = wait ~= nil and wait or self.config.waiting_time

    if not server then
        return
    end

    local is_initial_join_fired = false
    local is_server_not_listed = false
    local refresh_seconds = self.default_refresh_seconds

    self.auto_join_thread = Utils.Thread.Start(_AUTO_JOIN_THREAD_ID, function()
        if self.elapsed_seconds >= initial_wait then
            if not is_initial_join_fired then
                is_initial_join_fired = true
                self:Join(server, password)
            end

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
                    self.seconds = wait
                    self:Join(server, password)
                end

                self:UpdateButton()
                self:UpdateIndicators()
            end
        end
        self.elapsed_seconds = self.elapsed_seconds + 1
        Sleep(1)
    end, function()
        return self.is_auto_joining
    end, function()
        self.elapsed_seconds = 0
        self.is_auto_joining = true
        self.seconds = wait

        self:SetState(MOD_AUTO_JOIN.STATE.CONNECT, true)
        self:DebugString(string.format("Auto-joining every %d seconds...", self.seconds))
        self:DebugString(string.format("Refreshing every %d seconds...", refresh_seconds))

        if initial_wait > 0 then
            self:DebugString(string.format("Waiting %d seconds before starting...", initial_wait))
        end
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

    if self.rejoin_btn and self.rejoin_btn.inst:IsValid() then
        self.rejoin_btn:SetState(self.state, ignore_focus)
        self.rejoin_btn:SetSeconds(self.seconds)
    end
end

--- Updates auto-join button.
function AutoJoin:UpdateButtonStatus()
    if self.auto_join_btn and self.auto_join_btn.inst:IsValid() then
        self.auto_join_btn:SetStatus(self.status, self.status_message)
    end

    if self.rejoin_btn and self.rejoin_btn.inst:IsValid() then
        self.rejoin_btn:SetStatus(self.status, self.status_message)
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

--- Updates indicators.
function AutoJoin:UpdateIndicatorsStatus()
    for _, v in ipairs(self.indicators) do
        if v.inst:IsValid() then
            v:SetStatus(self.status, self.status_message)
        end
    end
end

--- Multiplayer Main Screen
-- @section multiplayer-main-screen

--- Overrides multiplayer main screen.
-- @tparam MultiplayerMainScreen multiplayermainscreen
function AutoJoin:OverrideMultiplayerMainScreen(multiplayermainscreen)
    local total = multiplayermainscreen.menu:GetNumberOfItems()
    local previous_menu_item_name = multiplayermainscreen.menu.items[total].name
    local previous_menu_item_on_click = multiplayermainscreen.menu.items[total].onclick

    if self.config.rejoin_main_screen_button then
        -- overrides MultiplayerMainScreen:MakeSubMenu()
        multiplayermainscreen.MakeSubMenu = function()
            local server_listing = Utils.Chain.Get(_LAST_JOIN_SERVER, "server_listing")
            local btn = multiplayermainscreen.mod_auto_join_rejoin

            if btn then
                btn:Kill()
                table.remove(multiplayermainscreen.submenu.items, btn.index)
            end

            total = multiplayermainscreen.submenu:GetNumberOfItems()
            if total >= 4 then
                if multiplayermainscreen.submenu.items[total] then
                    multiplayermainscreen.submenu.items[total]:Kill()
                    table.remove(multiplayermainscreen.submenu.items, total)
                end
            end

            if server_listing then
                btn = RejoinButton(self, function()
                    self:Rejoin(multiplayermainscreen)
                end, function()
                    self:CancelRejoin(multiplayermainscreen)
                end)

                local hover_text_options = {
                    colour = UICOLOURS.WHITE,
                    font = NEWFONT_OUTLINE,
                    offset_x = 0,
                    offset_y = 80,
                }

                btn:SetHoverText(server_listing.name, hover_text_options)
                btn.icon:SetHoverText(server_listing.name, hover_text_options)
                btn.image:SetHoverText(server_listing.name, hover_text_options)

                multiplayermainscreen.submenu:AddCustomItem(btn)
                multiplayermainscreen.mod_auto_join_rejoin = btn
                btn.index = multiplayermainscreen.submenu:GetNumberOfItems()
            end
        end
    end

    -- overrides MultiplayerMainScreen:OnHide()
    local OldOnHide = multiplayermainscreen.OnHide
    multiplayermainscreen.OnHide = function()
        self:DebugString(multiplayermainscreen.name, "is hidden")
        OldOnHide(multiplayermainscreen)

        if multiplayermainscreen.mod_auto_join_indicator then
            self:RemoveIndicator(multiplayermainscreen.mod_auto_join_indicator)
            multiplayermainscreen.mod_auto_join_indicator = nil
        end
    end

    -- overrides MultiplayerMainScreen:OnShow()
    local OldOnShow = multiplayermainscreen.OnShow
    multiplayermainscreen.OnShow = function()
        self:DebugString(multiplayermainscreen.name, "is shown")
        OldOnShow(multiplayermainscreen)

        if not multiplayermainscreen.mod_auto_join_indicator then
            multiplayermainscreen.mod_auto_join_indicator = self:AddIndicator(
                multiplayermainscreen.fixed_root,
                function()
                    return multiplayermainscreen.mod_auto_join_indicator
                end
            )
        end

        if self.config.rejoin_main_screen_button then
            multiplayermainscreen:MakeSubMenu()
        end
    end

    -- overrides MultiplayerMainScreen:OnRawKey()
    local OldOnRawKey = multiplayermainscreen.OnRawKey
    multiplayermainscreen.OnRawKey = function(_, key, down)
        OldOnRawKey(multiplayermainscreen, key, down)
        key = NormalizeKey(key)
        if key == self.config.key_rejoin
            and Utils.Chain.Get(_LAST_JOIN_SERVER, "server_listing")
        then
            if down then
                total = multiplayermainscreen.menu:GetNumberOfItems()
                multiplayermainscreen.menu:EditItem(total, nil, nil, function()
                    self:Rejoin(multiplayermainscreen)
                end)
                multiplayermainscreen.menu.items[total]:SetText("Rejoin", true)
            else
                total = multiplayermainscreen.menu:GetNumberOfItems()
                multiplayermainscreen.menu:EditItem(total, nil, nil, previous_menu_item_on_click)
                multiplayermainscreen.menu.items[total]:SetText(previous_menu_item_name, true)
            end
        end
    end

    -- initialize
    multiplayermainscreen.mod_auto_join_indicator = nil

    -- debug
    self:DebugInit(multiplayermainscreen.name)
end

--- Pause Screen
-- @section pause-screen

--- Overrides pause screen.
-- @tparam PauseScreen pausescreen
function AutoJoin:OverridePauseScreen(pausescreen)
    local total = pausescreen.menu:GetNumberOfItems()
    local previous_menu_item_name = pausescreen.menu.items[total - 1].name
    local previous_menu_item_on_click = pausescreen.menu.items[total - 1].onclick

    -- overrides PauseScreen:OnRawKey()
    local OldOnRawKey = pausescreen.OnRawKey
    pausescreen.OnRawKey = function(_, key, down)
        OldOnRawKey(pausescreen, key, down)
        key = NormalizeKey(key)
        if key == self.config.key_rejoin
            and Utils.Chain.Get(_LAST_JOIN_SERVER, "server_listing")
        then
            if down then
                total = pausescreen.menu:GetNumberOfItems()
                pausescreen.menu:EditItem(total - 1, "Rejoin", nil, function()
                    self:Rejoin(nil, 3)
                end)
            else
                total = pausescreen.menu:GetNumberOfItems()
                pausescreen.menu:EditItem(
                    total - 1,
                    previous_menu_item_name,
                    nil,
                    previous_menu_item_on_click
                )
            end
        end
    end

    -- debug
    self:DebugInit(pausescreen.name)
end

--- Server Listing Screen
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

--- Overrides server listing screen.
-- @tparam ServerListingScreen serverlistingscreen
function AutoJoin:OverrideServerListingScreen(serverlistingscreen)
    local server_fn = function()
        return serverlistingscreen.selected_server
    end

    local function OnJoinClick()
        local server = server_fn()
        if server then
            if server.has_password then
                self:DebugString("Joining the password-protected server:", server.name)
            else
                self:DebugString("Joining the server:", server.name)
            end
            self:StopAutoJoining()
            serverlistingscreen:Join(false)
        end
    end

    local function OnAutoJoinSuccess()
        self.server = server_fn()
        serverlistingscreen.server = server_fn()
        serverlistingscreen.servers_scroll_list:RefreshView()
    end

    local function OnAutoJoinCancel()
        self.server = nil
        serverlistingscreen.server = nil
        serverlistingscreen.servers_scroll_list:RefreshView()
    end

    -- overrides ServerListingScreen:SetRowColour()
    local OldSetRowColour = serverlistingscreen.SetRowColour
    serverlistingscreen.SetRowColour = function(_, row_widget, colour)
        OldSetRowColour(serverlistingscreen, row_widget, colour)
        local server = serverlistingscreen.servers[row_widget.unfiltered_index]
        if server and self.server then
            if server.guid == self.server.guid then
                OldSetRowColour(serverlistingscreen, row_widget, UICOLOURS.GOLD)
            end
        end
    end

    -- overrides ServerListingScreen:UpdateServerData()
    local OldUpdateServerData = serverlistingscreen.UpdateServerData
    serverlistingscreen.UpdateServerData = function(_, selected_index_actual)
        OldUpdateServerData(serverlistingscreen, selected_index_actual)

        local selected_server = TheNet:GetServerListingFromActualIndex(selected_index_actual)
        local is_name_and_description_hidden = selected_server
            and ServerPreferences:IsNameAndDescriptionHidden(selected_server)
            or false

        if selected_server
            and (Utils.Table.Compare(selected_server, serverlistingscreen.selected_server) == false
            or serverlistingscreen.details_hidden_name ~= is_name_and_description_hidden)
        then
            serverlistingscreen.auto_join_join_btn:Enable()
            serverlistingscreen.auto_join_auto_join_btn:Enable()
        end
    end

    -- initialize
    self.join_btn = serverlistingscreen.side_panel:AddChild(JoinButton(OnJoinClick))
    self.auto_join_btn = serverlistingscreen.side_panel:AddChild(AutoJoinButton(
        self,
        self:GetBtnOnClickFn(server_fn, OnAutoJoinSuccess, OnAutoJoinCancel),
        self:GetBtnIsActiveFn()
    ))

    serverlistingscreen.auto_join_join_btn = self.join_btn
    serverlistingscreen.auto_join_auto_join_btn = self.auto_join_btn
    serverlistingscreen.join_button:Hide()

    -- debug
    self:DebugInit(serverlistingscreen.name)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
function AutoJoin:DoInit(modname)
    Utils.Debug.AddMethods(self)

    -- general
    self.data = Data(modname)
    self.elapsed_seconds = 0
    self.name = "AutoJoin"
    self.state = MOD_AUTO_JOIN.STATE.DEFAULT
    self.status = nil
    self.status_message = nil

    -- indicators
    self.indicators = {}

    -- server listing screen
    self.auto_join_btn = nil
    self.join_btn = nil

    -- auto-joining
    self.auto_join_thread = nil
    self.is_auto_joining = nil
    self.is_fake_joining = false
    self.is_ui_disabled = false
    self.server = nil

    -- rejoin
    self.rejoin_btn = nil

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
        key_rejoin = KEY_CTRL,
        rejoin_initial_wait = 3,
        rejoin_main_screen_button = true,
        waiting_time = 15,
    }

    self.config_default = shallowcopy(self.config)
    self.seconds = self.config.waiting_time

    -- defaults
    self.default_refresh_seconds = 30

    -- dev tools mod
    self.devtoolssubmenu = DevToolsSubmenu(self)

    -- data
    _LAST_JOIN_SERVER = self.data:GeneralGet("last_join_server")

    -- self
    self:DebugInit(self.name)
end

return AutoJoin
