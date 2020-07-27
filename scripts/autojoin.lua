local AutoJoinIconIndicator = require "widgets/autojoiniconindicator"
local AutoJoinPasswordScreen = require "screens/autojoinpasswordscreen"
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
    if not self.oldjoinserver then
        self.oldjoinserver = JoinServer
    end

    if not self.oldonnetworkdisconnect then
        self.oldonnetworkdisconnect = OnNetworkDisconnect
    end

    if not self.oldshowconnectingtogamepopup then
        self.oldshowconnectingtogamepopup = ShowConnectingToGamePopup
    end

    if not self.oldjoinserver
        or not self.oldonnetworkdisconnect
        or not self.oldshowconnectingtogamepopup
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

    self.isuidisabled = true

    self:DebugString("JoinServer overridden")
    self:DebugString("OnNetworkDisconnect overridden")
    self:DebugString("ShowConnectingToGamePopup overridden")
end

function AutoJoin:OverrideRestore()
    JoinServer = self.oldjoinserver
    OnNetworkDisconnect = self.oldonnetworkdisconnect
    ShowConnectingToGamePopup = self.oldshowconnectingtogamepopup

    self.isuidisabled = false

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
    local indicator = root:AddChild(AutoJoinIconIndicator(
        self.server,
        self:GetIndicatorOnClickFn(),
        self:GetBtnIsActiveFn(),
        self.configindicatorposition,
        self.configindicatorpadding,
        self.configindicatorscale
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

        self.defaultbtn:Enable()

        if successcb then
            successcb(self)
        end
    end

    local function OnCancel(server)
        self:StopAutoJoining()

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
    return self.isautojoining
end

function AutoJoin:StartAutoJoining(server, password)
    if not self.isuidisabled then
        self:Override()
    end

    self:StartAutoJoinThread(server, password)
end

function AutoJoin:StopAutoJoining()
    self:ClearAutoJoinThread()

    self.isautojoining = false
    TheNet:JoinServerResponse(true)

    if self.isuidisabled then
        self:OverrideRestore()
    end

    if self.iconbtn and self.iconbtn.inst:IsValid() then
        self.iconbtn:Inactive()
    end
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

        self:DebugString("Thread started")
        self:DebugString(string.format("Auto-joining every %d seconds...", seconds))
        self:DebugString(string.format("Refreshing every %d seconds...", refreshseconds))

        self.isautojoining = true

        if self.iconbtn and self.iconbtn.inst:IsValid() then
            self.iconbtn:Active()
        end

        self:Join(server, password)

        while self.isautojoining do
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

            if self.iconbtn and self.iconbtn.inst:IsValid() then
                self.iconbtn:SetSeconds(seconds)
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
    if self.autojointhread then
        self:DebugString("[" .. self.autojointhread.id .. "]", "Thread cleared")
        KillThreadsWithID(self.autojointhread.id)
        self.autojointhread:SetList(nil)
        self.autojointhread = nil
    end
end

--
-- Initialization
--

function AutoJoin:DoInit()
    Utils.AddDebugMethods(self)

    -- config
    self.configindicator = true
    self.configindicatorpadding = 10
    self.configindicatorposition = "tr"
    self.configindicatorscale = 1.3
    self.configwaitingtime = 15

    -- server
    self.serverguid = nil

    -- indicators
    self.indicators = {}

    -- server listing screen
    self.defaultbtn = nil
    self.iconbtn = nil

    -- auto-joining
    self.autojointhread = nil
    self.isautojoining = nil
    self.isuidisabled = false
    self.server = nil

    -- overrides
    self.oldjoinserver = nil
    self.oldonnetworkdisconnect = nil
    self.oldshowconnectingtogamepopup = nil

    self:DebugInit("AutoJoin")
end

return AutoJoin
