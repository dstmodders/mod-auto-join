--
-- Packages
--

package.path = "./scripts/?.lua;" .. package.path

local preloads = {
    class = "autojoin/sdk/spec/class",
}

for k, v in pairs(preloads) do
    package.preload[k] = function()
        return require(v)
    end
end

--
-- SDK
--

local SDK

SDK = require "autojoin/sdk/sdk/sdk"
SDK.SetIsSilent(true).Load({
    modname = "mod-auto-join",
    AddPrefabPostInit = function() end
}, "autojoin/sdk")

_G.SDK = SDK
