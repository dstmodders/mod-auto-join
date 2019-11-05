local ImageButton = require "widgets/imagebutton"

local AutoJoinButton = Class(ImageButton, function(self, text, onclick, size)
    local prefix = "button_carny_long"
    if size and #size == 2 then
        local ratio = size[1] / size[2]
        if ratio > 4 then
            prefix = "button_carny_xlong"
        elseif ratio < 1.1 then
            prefix = "button_carny_square"
        end
    end

    ImageButton._ctor(
        self,
        "images/global_redux.xml",
        prefix .. "_normal.tex",
        prefix .. "_hover.tex",
        prefix .. "_disabled.tex",
        prefix .. "_down.tex"
    )

    self:SetDisabledFont(CHATFONT)
    self:SetFont(CHATFONT)
    self:SetOnClick(onclick)
    self:SetText(text)

    if size then
        self:ForceImageSize(unpack(size))
        self:SetTextSize(math.ceil(size[2] * .45))
    end
end)

return AutoJoinButton
