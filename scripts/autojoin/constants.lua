----
-- Mod constants.
--
-- **Source Code:** [https://github.com/dstmodders/dst-mod-auto-join](https://github.com/dstmodders/dst-mod-auto-join)
--
-- @module Constants
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.8.0
----

--- Mod constants.
-- @see MOD_AUTO_JOIN.ANCHOR
-- @see MOD_AUTO_JOIN.STATE
-- @see MOD_AUTO_JOIN.STATUS
-- @table MOD_AUTO_JOIN
-- @tfield table ANCHOR
-- @tfield table STATE
-- @tfield table STATUS
MOD_AUTO_JOIN = {
    --- General
    -- @section general

    --- Anchor constants.
    -- @table MOD_AUTO_JOIN.ANCHOR
    -- @tfield number TOP_LEFT
    -- @tfield number TOP_RIGHT
    -- @tfield number BOTTOM_RIGHT
    -- @tfield number BOTTOM_LEFT
    ANCHOR = {
        TOP_LEFT = 1,
        TOP_RIGHT = 2,
        BOTTOM_RIGHT = 3,
        BOTTOM_LEFT = 4,
    },

    --- State constants.
    -- @table MOD_AUTO_JOIN.STATE
    -- @tfield number DEFAULT
    -- @tfield number DEFAULT_FOCUS
    -- @tfield number COUNTDOWN
    -- @tfield number COUNTDOWN_CANCEL
    -- @tfield number CONNECT
    -- @tfield number CONNECT_CANCEL
    STATE = {
        DEFAULT = 1,
        DEFAULT_FOCUS = 2,
        COUNTDOWN = 3,
        COUNTDOWN_FOCUS = 4,
        CONNECT = 5,
        CONNECT_FOCUS = 6,
    },

    --- Status constants.
    -- @table MOD_AUTO_JOIN.STATUS
    -- @tfield number ALREADY_CONNECTED
    -- @tfield number BANNED
    -- @tfield number FULL
    -- @tfield number INVALID_PASSWORD
    -- @tfield number KICKED
    -- @tfield number NOT_RESPONDING
    -- @tfield number UNKNOWN
    STATUS = {
        ALREADY_CONNECTED = 1,
        BANNED = 2,
        FULL = 3,
        INVALID_PASSWORD = 4,
        KICKED = 5,
        NOT_RESPONDING = 6,
        UNKNOWN = 7,
    },
}
