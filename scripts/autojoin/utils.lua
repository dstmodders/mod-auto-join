----
-- Different mod utilities.
--
-- Includes different utilities used throughout the whole mod.
--
-- In order to become an utility the solution should either:
--
-- 1. Be a non-mod specific and isolated which can be reused in my other mods.
-- 2. Be a mod specific and isolated which can be used between classes/modules.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @module Utils
-- @see Utils.Chain
-- @see Utils.Debug
-- @see Utils.Modmain
-- @see Utils.Table
-- @see Utils.Thread
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.5.0
----
local Utils = {}

Utils.Chain = require "autojoin/utils/chain"
Utils.Debug = require "autojoin/utils/debug"
Utils.Modmain = require "autojoin/utils/modmain"
Utils.Table = require "autojoin/utils/table"
Utils.Thread = require "autojoin/utils/thread"

return Utils
