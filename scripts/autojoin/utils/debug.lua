----
-- Different chain mod utilities.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @module Utils.Debug
-- @see Utils
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.7.0-alpha
----
local Debug = {}

--- Prints the provided error strings.
-- @see Debug.DebugError
-- @tparam string ... Strings
function Debug.Error(...)
    return _G.ModAutoJoinDebug and _G.ModAutoJoinDebug:DebugError(...)
end

--- Prints the provided strings.
-- @see Debug.DebugString
-- @tparam string ... Strings
function Debug.String(...)
    return _G.ModAutoJoinDebug and _G.ModAutoJoinDebug:DebugString(...)
end

--- Adds debug methods to the destination class.
--
-- Checks the global environment if the `Debug` is available and adds the corresponding
-- methods from there. Otherwise, adds all the corresponding functions as empty ones.
--
-- @tparam table dest Destination class
function Debug.AddMethods(dest)
    local methods = {
        "DebugError",
        "DebugInit",
        "DebugString",
        "DebugStringStart",
        "DebugStringStop",
        "DebugTerm",
    }

    if _G.ModAutoJoinDebug then
        for _, v in pairs(methods) do
            dest[v] = function(_, ...)
                if _G.ModAutoJoinDebug and _G.ModAutoJoinDebug[v] then
                    return _G.ModAutoJoinDebug[v](_G.ModAutoJoinDebug, ...)
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

return Debug
