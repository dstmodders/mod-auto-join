----
-- Different thread mod utilities.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-auto-join](https://github.com/dstmodders/dst-mod-auto-join)
--
-- @module Utils.Thread
-- @see Utils
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2019
-- @license MIT
-- @release 0.9.0-alpha
----
local Thread = {}

local Debug = require "autojoin/utils/debug"

--- Starts a new thread.
--
-- Just a convenience wrapper for the `StartThread`.
--
-- @tparam string id Thread ID
-- @tparam function fn Thread function
-- @tparam[opt] function whl While function
-- @tparam[opt] function init Initialization function
-- @tparam[opt] function term Termination function
-- @treturn table
function Thread.Start(id, fn, whl, init, term)
    whl = whl ~= nil and whl or function()
        return true
    end

    return StartThread(function()
        Debug.String("Thread started")
        if init then
            init()
        end
        while whl() do
            fn()
        end
        if term then
            term()
        end
        Thread.Clear()
    end, id)
end

--- Clears a thread.
-- @tparam table thread Thread
function Thread.Clear(thread)
    local task = scheduler:GetCurrentTask()
    if thread or task then
        if thread and not task then
            Debug.String("[" .. thread.id .. "]", "Thread cleared")
        else
            Debug.String("Thread cleared")
        end
        thread = thread ~= nil and thread or task
        KillThreadsWithID(thread.id)
        thread:SetList(nil)
    end
end

return Thread
