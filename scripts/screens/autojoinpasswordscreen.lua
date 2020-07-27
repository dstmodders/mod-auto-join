----
-- Our password screen.
--
-- Screen that extends `InputDialogScreen` and creates a very similar to already existing one in the
-- engine.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod AutoJoinPasswordScreen
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-alpha
----
local InputDialogScreen = require "screens/redux/inputdialog"

local AutoJoinPasswordScreen = Class(InputDialogScreen, function(
    self,
    server,
    success_cb,
    cancel_cb
)
    local function OnSuccess()
        TheFrontEnd:PopScreen()
        if success_cb then
            success_cb(server, self:GetActualString())
        end
    end

    local function OnCancel()
        TheFrontEnd:PopScreen()
        if cancel_cb then
            cancel_cb(server)
        end
    end

    InputDialogScreen._ctor(
        self,
        STRINGS.UI.SERVERLISTINGSCREEN.PASSWORDREQUIRED,
        {
            { text = STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = OnSuccess },
            { text = STRINGS.UI.SERVERLISTINGSCREEN.CANCEL, cb = OnCancel },
        },
        true
    )

    self.edit_text.OnTextEntered = function()
        if self:GetActualString() ~= "" then
            OnSuccess()
        else
            self.edit_text:SetEditing(true)
        end
    end

    if not Profile:GetShowPasswordEnabled() then
        self.edit_text:SetPassword(true)
    end
end)

--
-- States
--

--- State to force input.
function AutoJoinPasswordScreen:ForceInput()
    self.edit_text:SetForceEdit(true)
    self.edit_text:OnControl(CONTROL_ACCEPT, false)
end

return AutoJoinPasswordScreen
