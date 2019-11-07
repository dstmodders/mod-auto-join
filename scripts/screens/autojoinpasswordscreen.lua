local InputDialogScreen = require "screens/redux/inputdialog"

local AutoJoinPasswordScreen = Class(InputDialogScreen, function(self, server, successcb, cancelcb)
    local function OnSuccess()
        TheFrontEnd:PopScreen()
        if successcb then
            successcb(server, self:GetActualString())
        end
    end

    local function OnCancel()
        TheFrontEnd:PopScreen()
        if cancelcb then
            cancelcb(server)
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

function AutoJoinPasswordScreen:ForceInput()
    self.edit_text:SetForceEdit(true)
    self.edit_text:OnControl(CONTROL_ACCEPT, false)
end

return AutoJoinPasswordScreen
