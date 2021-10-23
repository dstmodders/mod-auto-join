--
-- Packages
--

package.path = "./scripts/?.lua;" .. package.path

local preloads = {
    class = "autojoin/sdk/spec/class",
    ["autojoin/debug"] = "autojoin/sdk/spec/empty",
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
    modname = "dst-mod-auto-join",
    AddPrefabPostInit = function() end
}, "autojoin/sdk")

_G.SDK = SDK

--
-- General
--

function ReturnValues(...)
    return ...
end

function AssertMethodExists(class, fn_name)
    local assert = require "busted".assert
    local classname = class.name ~= nil and class.name or "Class"
    assert.is_not_nil(
        class[fn_name],
        string.format("Function %s:%s() is missing", classname, fn_name)
    )
end

function AssertMethodIsMissing(class, fn_name)
    local assert = require "busted".assert
    local classname = class.name ~= nil and class.name or "Class"
    assert.is_nil(class[fn_name], string.format("Function %s:%s() exists", classname, fn_name))
end

function AssertGetter(class, field, fn_name, test_data)
    test_data = test_data ~= nil and test_data or "test"

    local assert = require "busted".assert
    AssertMethodExists(class, fn_name)
    local classname = class.name ~= nil and class.name or "Class"
    local fn = class[fn_name]

    local msg = string.format(
        "Getter %s:%s() doesn't return the %s.%s value",
        classname,
        fn_name,
        classname,
        field
    )

    assert.is_equal(class[field], fn(class), msg)
    class[field] = test_data
    assert.is_equal(test_data, fn(class), msg)
end

function AssertSetter(class, field, fn_name, test_data)
    test_data = test_data ~= nil and test_data or "test"

    local assert = require "busted".assert
    AssertMethodExists(class, fn_name)
    local classname = class.name ~= nil and class.name or "Class"
    local fn = class[fn_name]

    local msg = string.format(
        "Setter %s:%s() doesn't set the %s.%s value",
        classname,
        fn_name,
        classname,
        field
    )

    fn(class, test_data)
    assert.is_equal(test_data, class[field], msg)
end
