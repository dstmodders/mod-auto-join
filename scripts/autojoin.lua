local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local InputDialogScreen = require "screens/redux/inputdialog"

-- general
local _DEBUG_FN

-- threads
local _AUTO_JOIN_THREAD_ID = "auto_join_thread"

local AutoJoin = Class(function(self)
    self:Init()
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

function AutoJoin:Init()
    -- config
    self.configwaitingtime = 15

    -- server
    self.serverguid = nil

    -- server listing screen
    self.autojoinbtn = nil
    self.joinbtn = nil

    -- auto-joining
    self.autojointhread = nil
    self.isautojoining = nil
    self.isuidisabled = false

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

function AutoJoin:CompareTable(a, b)
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
    if not self:CompareTable(meta_table_a, meta_table_b) then
        return false
    end

    -- compare nested tables
    for index, va in pairs(a) do
        local vb = b[index]
        if not self:CompareTable(va, vb) then
            return false
        end
    end
    for index, vb in pairs(b) do
        local va = a[index]
        if not self:CompareTable(va, vb) then
            return false
        end
    end

    return true
end

--
-- Server Listing Screen
--

local function MakeButton(onclick, text, size)
    local prefix = "button_carny_long"
    if size and #size == 2 then
        local ratio = size[1] / size[2]
        if ratio > 4 then
            prefix = "button_carny_xlong"
        elseif ratio < 1.1 then
            prefix = "button_carny_square"
        end
    end

    local btn = ImageButton("images/global_redux.xml",
        prefix .. "_normal.tex",
        prefix .. "_hover.tex",
        prefix .. "_disabled.tex",
        prefix .. "_down.tex")

    btn:SetOnClick(onclick)
    btn:SetText(text)
    btn:SetFont(CHATFONT)
    btn:SetDisabledFont(CHATFONT)

    if size then
        btn:ForceImageSize(unpack(size))
        btn:SetTextSize(math.ceil(size[2] * .45))
    end

    return btn
end

function AutoJoin:MakeAutoJoinButton(parent, serverfn, successcb, cancelcb)
    local btn

    local function Join(server, password)
        if self:IsAutoJoining() then
            self:ClearAutoJoinThread()
            self.joinbtn:Enable()
        else
            self:ClearAutoJoinThread()
            self:StartAutoJoinThread(server, password)
            self.joinbtn:Enable()
        end

        if successcb then
            successcb()
        end
    end

    local function OnCancel(server)
        self:ClearAutoJoinThread()

        if server then
            self.autojoinbtn:Enable()
            self.joinbtn:Enable()
        else
            self.autojoinbtn:Disable()
            self.joinbtn:Disable()
        end

        if cancelcb then
            cancelcb()
        end
    end

    local function OnClick()
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

    btn = parent:AddChild(MakeButton(OnClick, nil, { 60, 60 }))
    btn:SetPosition(120, -RESOLUTION_Y * .5 + BACK_BUTTON_Y - 15)
    btn:SetScale(1.4)

    btn:SetDisabledFont(HEADERFONT)
    btn:SetFont(HEADERFONT)
    btn:SetText(nil)
    btn:SetTextSize(18)
    btn.text:SetPosition(.5, -.5)

    local width = 28

    btn.icon = btn:AddChild(Image("images/auto_join_icons.xml", "clock.tex"))
    btn.icon:ScaleToSize(width, width)
    btn.icon:SetPosition(.5, 0)
    btn.icon:Show()

    btn.circle = btn:AddChild(Image("images/auto_join_icons.xml", "circle.tex"))
    btn.circle:ScaleToSize(width, width)
    btn.circle:SetPosition(.5, 0)
    btn.circle:Hide()

    btn:SetHoverText("Auto-Join", {
        font = NEWFONT_OUTLINE,
        offset_x = 0,
        offset_y = 70,
        colour = UICOLOURS.WHITE,
        bg = nil
    })

    if self:IsAutoJoining() then
        btn:Enable()
    else
        btn:Disable()
    end

    self.autojoinbtn = btn

    DebugString("Auto-Join button initialized")

    return btn
end

function AutoJoin:MakeJoinButton(parent, onclick)
    local btn
    local spacing = 10
    local width = 240

    btn = parent:AddChild(MakeButton(onclick, STRINGS.UI.SERVERLISTINGSCREEN.JOIN, { width - 60 - spacing, 60 }))
    btn:SetPosition(-30 - spacing, -RESOLUTION_Y * .5 + BACK_BUTTON_Y - 15)
    btn:SetScale(1.45)
    btn:Disable()

    self.joinbtn = btn

    DebugString("Join button initialized")

    return btn
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
        local defaultseconds, refreshseconds, seconds
        local isservernotlisted

        defaultseconds = self.configwaitingtime
        isservernotlisted = false
        refreshseconds = 30
        seconds = defaultseconds

        DebugThreadString("Thread started")
        DebugThreadString(string.format("Auto-joining every %d seconds...", seconds))
        DebugThreadString(string.format("Refreshing every %d seconds...", refreshseconds))

        self.isautojoining = true
        self:Override()

        if self.autojoinbtn and self.autojoinbtn.inst:IsValid() then
            self.autojoinbtn.circle:Show()
            self.autojoinbtn.icon:Hide()
        end

        local function Join()
            DebugThreadString("Joining server...")
            JoinServer(server, password)
        end

        Join()

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
                    refreshseconds = 30
                    isservernotlisted = false
                    DebugThreadString("Refreshing the server listing...")
                    TheNet:SearchServers()
                end
            end

            if self.autojoinbtn and self.autojoinbtn.inst:IsValid() then
                self.autojoinbtn:SetText(seconds)
                if seconds > 10 then
                    self.autojoinbtn:SetTextSize(16)
                else
                    self.autojoinbtn:SetTextSize(18)
                end

                self.autojoinbtn.circle:Show()
                self.autojoinbtn.icon:Hide()
            end

            if seconds <= 1 then
                seconds = defaultseconds + 1
                Join()
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

        if self.autojoinbtn and self.autojoinbtn.inst:IsValid() then
            self.autojoinbtn.circle:Hide()
            self.autojoinbtn.icon:Show()
            self.autojoinbtn:SetText(nil)
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
