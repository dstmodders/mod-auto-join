----
-- Different global utilities.
--
-- Most of them are expected to be used in the gameplay console.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @module Utils
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-beta
----
local Utils = {}

-- base (to store original functions after overrides)
local BaseGetModInfo

--
-- Helpers
--

local function DebugString(...)
    return _G.AutoJoinDebug and _G.AutoJoinDebug:DebugString(...)
end

--
-- Debugging
--

--- Adds debug methods to the destination class.
--
-- Checks the global environment if the `AutoJoinDebug` (`Debug`) is available and adds the
-- corresponding methods from there. Otherwise, adds all the corresponding functions as empty ones.
--
-- @tparam table dest Destination class
function Utils.AddDebugMethods(dest)
    local methods = {
        "DebugError",
        "DebugInit",
        "DebugString",
        "DebugStringStart",
        "DebugStringStop",
        "DebugTerm",
    }

    if _G.AutoJoinDebug then
        for _, v in pairs(methods) do
            dest[v] = function(_, ...)
                if _G.AutoJoinDebug and _G.AutoJoinDebug[v] then
                    return _G.AutoJoinDebug[v](_G.AutoJoinDebug, ...)
                end
            end
        end
    else
        for _, v in pairs(methods) do
            dest[v] = function()
            end
        end
    end
end

--
-- Chain
--

--- Gets chained field.
--
-- Simplifies the last chained field retrieval like:
--
--    return TheWorld
--        and TheWorld.net
--        and TheWorld.net.components
--        and TheWorld.net.components.shardstate
--        and TheWorld.net.components.shardstate.GetMasterSessionId
--        and TheWorld.net.components.shardstate:GetMasterSessionId
--
-- Or it's value:
--
--    return TheWorld
--        and TheWorld.net
--        and TheWorld.net.components
--        and TheWorld.net.components.shardstate
--        and TheWorld.net.components.shardstate.GetMasterSessionId
--        and TheWorld.net.components.shardstate:GetMasterSessionId()
--
-- It also supports net variables and tables acting as functions.
--
-- @usage Utils.ChainGet(TheWorld, "net", "components", "shardstate", "GetMasterSessionId") -- (function) 0x564445367790
-- @usage Utils.ChainGet(TheWorld, "net", "components", "shardstate", "GetMasterSessionId", true) -- (string) D000000000000000
-- @tparam table src
-- @tparam string|boolean ...
-- @treturn function|userdata|table
function Utils.ChainGet(src, ...)
    if src and (type(src) == "table" or type(src) == "userdata") then
        local args = { ... }
        local execute = false

        if args[#args] == true then
            table.remove(args, #args)
            execute = true
        end

        local previous = src
        for i = 1, #args do
            if src[args[i]] then
                previous = src
                src = src[args[i]]
            else
                return
            end
        end

        if execute and previous then
            if type(src) == "function" then
                return src(previous)
            elseif type(src) == "userdata" or type(src) == "table" then
                if type(src.value) == "function" then
                    -- netvar
                    return src:value()
                elseif getmetatable(src.value) and getmetatable(src.value).__call then
                    -- netvar (for testing)
                    return src.value(src)
                elseif getmetatable(src) and getmetatable(src).__call then
                    -- table acting as a function
                    return src(previous)
                end
            end
            return
        end

        return src
    end
end

--- Validates chained fields.
--
-- Simplifies the chained fields checking like below:
--
--    return TheWorld
--        and TheWorld.net
--        and TheWorld.net.components
--        and TheWorld.net.components.shardstate
--        and TheWorld.net.components.shardstate.GetMasterSessionId
--        and true
--        or false
--
-- @usage Utils.ChainValidate(TheWorld, "net", "components", "shardstate", "GetMasterSessionId") -- (boolean) true
-- @tparam table src
-- @tparam string|boolean ...
-- @treturn boolean
function Utils.ChainValidate(src, ...)
    return Utils.ChainGet(src, ...) and true or false
end

--
-- Modmain
--

--- Hide the modinfo changelog.
--
-- Overrides the global `KnownModIndex.GetModInfo` to hide the changelog if it's included in the
-- description.
--
-- @tparam string modname
-- @tparam boolean enable
-- @treturn boolean
function Utils.HideChangelog(modname, enable)
    if modname and enable and not BaseGetModInfo then
        BaseGetModInfo =  _G.KnownModIndex.GetModInfo
        _G.KnownModIndex.GetModInfo = function(_self, _modname)
            if _modname == modname
                and _self.savedata
                and _self.savedata.known_mods
                and _self.savedata.known_mods[modname]
            then
                local TrimString = _G.TrimString
                local modinfo = _self.savedata.known_mods[modname].modinfo
                if modinfo and type(modinfo.description) == "string" then
                    local changelog = modinfo.description:find("v" .. modinfo.version, 0, true)
                    if type(changelog) == "number" then
                        modinfo.description = TrimString(modinfo.description:sub(1, changelog - 1))
                    end
                end
            end
            return BaseGetModInfo(_self, _modname)
        end
        return true
    elseif BaseGetModInfo then
        _G.KnownModIndex.GetModInfo = BaseGetModInfo
        BaseGetModInfo = nil
    end
    return false
end

--
-- Table
--

--- Compares two tables if they are the same.
-- @tparam table a Table A
-- @tparam table b Table B
-- @treturn boolean
function Utils.TableCompare(a, b)
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
    if not Utils.TableCompare(meta_table_a, meta_table_b) then
        return false
    end

    -- compare nested tables
    for index, va in pairs(a) do
        local vb = b[index]
        if not Utils.TableCompare(va, vb) then
            return false
        end
    end

    for index, vb in pairs(b) do
        local va = a[index]
        if not Utils.TableCompare(va, vb) then
            return false
        end
    end

    return true
end

--
-- Thread
--

--- Starts a new thread.
--
-- Just a convenience wrapper for the `StartThread`.
--
-- @tparam string id Thread ID
-- @tparam function fn Thread function
-- @tparam function whl While function
-- @tparam[opt] function init Initialization function
-- @tparam[opt] function term Termination function
-- @treturn table
function Utils.ThreadStart(id, fn, whl, init, term)
    return StartThread(function()
        DebugString("Thread started")
        if init then
            init()
        end
        while whl() do
            fn()
        end
        if term then
            term()
        end
        Utils.ThreadClear()
    end, id)
end

--- Clears a thread.
-- @tparam table thread Thread
function Utils.ThreadClear(thread)
    local task = scheduler:GetCurrentTask()
    if thread or task then
        if thread and not task then
            DebugString("[" .. thread.id .. "]", "Thread cleared")
        else
            DebugString("Thread cleared")
        end

        thread = thread ~= nil and thread or task
        KillThreadsWithID(thread.id)
        thread:SetList(nil)
        thread = nil -- luacheck: only
    end
end

return Utils
