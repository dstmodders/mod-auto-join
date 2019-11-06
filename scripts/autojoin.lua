local InputDialogScreen = require "screens/redux/inputdialog"

-- general
local _DEBUG_FN

-- threads
local _AUTO_JOIN_THREAD_ID = "auto_join_thread"

local AutoJoin = Class(function(self)
    self:DoInit()
end)

--
-- Debugging-related
--

function AutoJoin:SetDebugFn(fn)
    _DEBUG_FN = fn
end

local function DebugString(...)
    if _DEBUG_FN then
        _DEBUG_FN(...)
    end
end

local function DebugThreadString(...)
    if _DEBUG_FN then
        local task = scheduler:GetCurrentTask()
        if task then
            _DEBUG_FN("[" .. task.id .. "]", ...)
        end
    end
end

--
-- Initialization
--

function AutoJoin:DoInit()
    -- config
    self.configwaitingtime = 15

    -- server
    self.serverguid = nil

    -- server listing screen
    self.defaultbtn = nil
    self.iconbtn = nil

    -- auto-joining
    self.autojointhread = nil
    self.isautojoining = nil
    self.isuidisabled = false
    self.server = nil

    -- overrides
    self.oldjoinserver = JoinServer
    self.oldonnetworkdisconnect = OnNetworkDisconnect
    self.oldshowconnectingtogamepopup = ShowConnectingToGamePopup

    DebugString("AutoJoin initialized")
end

--
-- General
--

-- an override of the JoinServer() global function from the networking module
local function JoinServerOverride(server_listing, optional_password_override)
    local function send_response(password)
        local start_worked = TheNet:JoinServerResponse(false, server_listing.guid, password)

        if start_worked then
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
        if server_listing.has_password and (optional_password_override == "" or optional_password_override == nil) then
            local password_prompt_screen
            password_prompt_screen = InputDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.PASSWORDREQUIRED,
                {
                    {
                        text = STRINGS.UI.SERVERLISTINGSCREEN.OK,
                        cb = function()
                            TheFrontEnd:PopScreen()
                            send_response(password_prompt_screen:GetActualString())
                        end
                    },
                    {
                        text = STRINGS.UI.SERVERLISTINGSCREEN.CANCEL,
                        cb = function()
                            TheFrontEnd:PopScreen()
                            on_cancelled()
                        end
                    },
                },
                true)
            password_prompt_screen.edit_text.OnTextEntered = function()
                if password_prompt_screen:GetActualString() ~= "" then
                    TheFrontEnd:PopScreen()
                    send_response(password_prompt_screen:GetActualString())
                else
                    password_prompt_screen.edit_text:SetEditing(true)
                end
            end
            if not Profile:GetShowPasswordEnabled() then
                password_prompt_screen.edit_text:SetPassword(true)
            end
            TheFrontEnd:PushScreen(password_prompt_screen)
            password_prompt_screen.edit_text:SetForceEdit(true)
            password_prompt_screen.edit_text:OnControl(CONTROL_ACCEPT, false)
        else
            send_response(optional_password_override or "")
        end
    end

    local function after_client_mod_message()
        after_mod_warning()
    end

    if server_listing.client_mods_disabled and
        not IsMigrating() and
        (server_listing.dedicated or not server_listing.owner) and
        AreAnyClientModsEnabled() then

        local client_mod_msg = PopupDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.CLIENT_MODS_DISABLED_TITLE, STRINGS.UI.SERVERLISTINGSCREEN.CLIENT_MODS_DISABLED_BODY,
            { { text = STRINGS.UI.SERVERLISTINGSCREEN.CONTINUE, cb = function()
                TheFrontEnd:PopScreen()
                after_client_mod_message()
            end } })

        TheFrontEnd:PushScreen(client_mod_msg)
    else
        after_client_mod_message()
    end
end

function AutoJoin:Join(server, password)
    local debug = scheduler:GetCurrentTask() and DebugThreadString or DebugString
    debug("Joining server...")
    JoinServer(server, password)
end

function AutoJoin:Override()
    JoinServer = JoinServerOverride

    OnNetworkDisconnect = function(message)
        DebugString("Disconnected:", message)
        return false
    end

    ShowConnectingToGamePopup = function()
        return false
    end

    self.isuidisabled = true

    local debug = scheduler:GetCurrentTask() and DebugThreadString or DebugString
    debug("OnNetworkDisconnect overridden")
    debug("ShowConnectingToGamePopup overridden")
end

function AutoJoin:OverrideRestore()
    JoinServer = self.oldjoinserver
    OnNetworkDisconnect = self.oldonnetworkdisconnect
    ShowConnectingToGamePopup = self.oldshowconnectingtogamepopup

    self.isuidisabled = false

    local debug = scheduler:GetCurrentTask() and DebugThreadString or DebugString
    debug("OnNetworkDisconnect restored")
    debug("ShowConnectingToGamePopup restored")
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
        self:ClearAutoJoinThread()

        if not self:IsAutoJoining() then
            self:StartAutoJoinThread(server, password)
        end

        self.defaultbtn:Enable()

        if successcb then
            successcb(self)
        end
    end

    local function OnCancel(server)
        self:ClearAutoJoinThread()

        if server then
            self.defaultbtn:Enable()
            self.iconbtn:Enable()
        else
            self.defaultbtn:Disable()
            self.iconbtn:Disable()
        end

        if cancelcb then
            cancelcb(self)
        end
    end

    return function()
        if not self.defaultbtn then
            DebugString("[error] AutoJoin.joinbtn is required")
            return
        end

        local server = serverfn()
        if server and server.has_password and not self:IsAutoJoining() then
            DebugString("Auto-joining the password-protected server:", server.name)
            self:PasswordPrompt(server, Join, OnCancel)
        elseif server and not self:IsAutoJoining() then
            DebugString("Auto-joining the server:", server.name)
            OnCancel(server)
            Join(server)
        elseif self:IsAutoJoining() then
            DebugString("Auto-joining has been cancelled")
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
    return self.isautojoining
end

function AutoJoin:StartAutoJoinThread(server, password)
    if not server then
        return server
    end

    self.autojointhread = StartThread(function()
        local defaultrefreshseconds, defaultseconds
        local refreshseconds, seconds
        local isservernotlisted

        defaultrefreshseconds = 30
        defaultseconds = self.configwaitingtime
        isservernotlisted = false
        refreshseconds = defaultrefreshseconds
        seconds = defaultseconds

        DebugThreadString("Thread started")
        DebugThreadString(string.format("Auto-joining every %d seconds...", seconds))
        DebugThreadString(string.format("Refreshing every %d seconds...", refreshseconds))

        self.isautojoining = true
        self:Override()

        if self.iconbtn and self.iconbtn.inst:IsValid() then
            self.iconbtn:Active()
        end

        self:Join(server, password)

        while self.isautojoining do
            if not self.isuidisabled then
                self:Override()
            end

            if not isservernotlisted
                and not TheNet:IsSearchingServers(PLATFORM ~= "WIN32_RAIL")
                and not IsServerListed(server.guid)
            then
                isservernotlisted = true
                DebugThreadString("Server is not listed")
            end

            if refreshseconds <= 0 then
                if isservernotlisted
                    and not TheNet:IsSearchingServers(PLATFORM ~= "WIN32_RAIL")
                    and not IsServerListed(server.guid)
                then
                    refreshseconds = 30 + 1
                    isservernotlisted = false
                    DebugThreadString("Refreshing the server listing...")
                    TheNet:SearchServers()
                end
            end

            if self.iconbtn and self.iconbtn.inst:IsValid() then
                self.iconbtn:SetSeconds(seconds)
            end

            if seconds < 1 then
                seconds = defaultseconds + 1
                self:Join(server, password)
            end

            seconds = seconds - 1
            refreshseconds = refreshseconds - 1

            Sleep(FRAMES / FRAMES * 1)
        end

        self:ClearFakeEatingThread()
    end, _AUTO_JOIN_THREAD_ID)
end

function AutoJoin:ClearAutoJoinThread()
    if self.autojointhread then
        DebugString("[" .. self.autojointhread.id .. "]", "Thread cleared")
        KillThreadsWithID(self.autojointhread.id)
        self.autojointhread:SetList(nil)
        self.autojointhread = nil

        self.isautojoining = false
        TheNet:JoinServerResponse(true)
        self:OverrideRestore()

        if self.iconbtn and self.iconbtn.inst:IsValid() then
            self.iconbtn:Inactive()
        end
    end
end

function AutoJoin:ToggleAutoJoin(server, password)
    self.isautojoining = not self.isautojoining
    if self.isautojoining then
        self:StartAutoJoinThread(server, password)
    else
        self:ClearAutoJoinThread()
    end
end

function AutoJoin:PasswordPrompt(server, successcb, cancelcb)
    local screen

    local function OnSuccess()
        TheFrontEnd:PopScreen()
        if successcb then
            successcb(server, screen:GetActualString())
        end
    end

    screen = InputDialogScreen(STRINGS.UI.SERVERLISTINGSCREEN.PASSWORDREQUIRED,
        {
            {
                text = STRINGS.UI.SERVERLISTINGSCREEN.OK,
                cb = OnSuccess
            },
            {
                text = STRINGS.UI.SERVERLISTINGSCREEN.CANCEL,
                cb = function()
                    TheFrontEnd:PopScreen()
                    if cancelcb then
                        cancelcb(server)
                    end
                end
            },
        },
        true)

    screen.edit_text.OnTextEntered = function()
        if screen:GetActualString() ~= "" then
            OnSuccess()
        else
            screen.edit_text:SetEditing(true)
        end
    end

    if not Profile:GetShowPasswordEnabled() then
        screen.edit_text:SetPassword(true)
    end

    TheFrontEnd:PushScreen(screen)
    screen.edit_text:SetForceEdit(true)
    screen.edit_text:OnControl(CONTROL_ACCEPT, false)

    DebugString("Prompting password...")
end

return AutoJoin
