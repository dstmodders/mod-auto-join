----
-- Debugging.
--
-- Includes different debugging-related features/functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @classmod Debug
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0-alpha
----
require "class"

local Debug = Class(function(self, modname)
    self:DoInit(modname)
end)

--
-- General
--

--- Checks if the debugging is enabled.
-- @treturn boolean
function Debug:IsEnabled()
    return self.isenabled
end

--- Sets the debugging.
-- @tparam boolean value
function Debug:SetIsEnabled(value)
    self.isenabled = value
end

--- Enables the debugging.
function Debug:Enable()
    self.isenabled = true
end

--- Disables the debugging.
function Debug:Disable()
    self.isenabled = false
end

--- Checks if name is in the debugging.
-- @tparam string name
-- @treturn boolean
function Debug:IsDebug(name)
    return self.isdebug[name] and true or false
end

--- Adds the name to the debugging.
-- @tparam string name
-- @tparam boolean boolean
function Debug:SetIsDebug(name, boolean)
    boolean = boolean and true or false
    self.isdebug[name] = boolean
end

--- Prints the provided strings.
-- @tparam string ... Strings
function Debug:DebugString(...) -- luacheck: only
    if self.isenabled then
        local task = scheduler:GetCurrentTask()
        local msg = string.format("[%s]", self.modname)

        if task then
            msg = msg .. " [" .. task.id .. "]"
        end

        for i = 1, arg.n do
            msg = msg .. " " .. tostring(arg[i])
        end

        print(msg)
    end
end

--- Prints the provided strings.
--
-- Unlike the `DebugString` it also starts the timer which later can be stopped using the
-- corresponding `DebugStringStop` method.
--
-- @tparam string ... Strings
function Debug:DebugStringStart(...)
    self.starttime = os.clock()
    self:DebugString(...)
end

--- Prints the provided strings.
--
-- Stops the timer started earlier by the `DebugStringStart` method and prints the provided strings
-- alongside with the time.
--
-- @tparam string ... Strings
function Debug:DebugStringStop(...)
    local arg = { ... }
    local last = string.gsub(arg[#arg], "%.$", "") .. "."
    arg[#arg] = last
    table.insert(arg, string.format("Time: %0.4f", os.clock() - self.starttime))
    self:DebugString(unpack(arg))
    self.starttime = nil
end

--- Prints an initialized method name.
-- @tparam string name Method name
function Debug:DebugInit(name)
    self:DebugString("[life_cycle]", "Initialized", name)
end

--- Prints an initialized method name.
-- @tparam string name Method name
function Debug:DebugTerm(name)
    self:DebugString("[life_cycle]", "Terminated", name)
end

--- Prints an error strings.
--
-- Acts just like the `DebugString` but also prepends the "[error]" string.
--
-- @tparam string ... Strings
function Debug:DebugError(...)
    self:DebugString("[error]", ...)
end

--- Prints all mod configurations.
--
-- Should be used to debug mod configurations.
function Debug:DebugModConfigs()
    local config = KnownModIndex:GetModConfigurationOptions_Internal(self.modname, false)
    if config and type(config) == "table" then
        for _, v in pairs(config) do
            if v.name == "" then
                self:DebugString("[config]", "[section]", v.label)
            else
                self:DebugString(
                    "[config]",
                    v.label .. ":",
                    v.saved == nil and v.default or v.saved
                )
            end
        end
    end
end

--
-- Initialization
--

--- Initializes.
--
-- Sets empty fields and adds debug functions.
--
-- @tparam string modname
function Debug:DoInit(modname)
    -- general
    self.isdebug = {}
    self.isenabled = false
    self.modname = modname
    self.starttime = nil

    -- other
    self:DebugInit("Debug")
end

return Debug
