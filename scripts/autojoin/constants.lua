----
-- Mod constants.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @module Constants
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.7.0-alpha
----

--- Mod constants.
-- @see MOD_AUTO_JOIN.INDICATOR
-- @see MOD_AUTO_JOIN.STATE
-- @table MOD_AUTO_JOIN
-- @tfield table INDICATOR
-- @tfield table STATE
MOD_AUTO_JOIN = {
    --- General
    -- @section general

    --- Indicator constants.
    -- @table MOD_AUTO_JOIN.INDICATOR
    -- @tfield table ANCHOR
    INDICATOR = {
        --- Indicator anchor constants.
        -- @table MOD_AUTO_JOIN.INDICATOR.ANCHOR
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
}
