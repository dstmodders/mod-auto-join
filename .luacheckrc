exclude_files = {
    "scripts/autojoin/sdk/",
    "workshop/",
}

std = {
    max_code_line_length = 100,
    max_comment_line_length = 150,
    max_line_length = 100,
    max_string_line_length = 100,

    -- std.read_globals should include only the "native" Lua-related stuff
    read_globals = {
        "arg",
        "assert",
        "Class",
        "debug",
        "env",
        "getmetatable",
        "ipairs",
        "json",
        "math",
        "next",
        "os",
        "pairs",
        "print",
        "rawset",
        "require",
        "string",
        "table",
        "tonumber",
        "tostring",
        "type",
        "unpack",
    },
}

files["modinfo.lua"] = {
    globals = {
        "all_clients_require_mod",
        "api_version",
        "author",
        "client_only_mod",
        "configuration_options",
        "description",
        "dont_starve_compatible",
        "dst_compatible",
        "folder_name",
        "forumthread",
        "icon_atlas",
        "icon",
        "name",
        "priority",
        "reign_of_giants_compatible",
        "shipwrecked_compatible",
        "version",
    },
}

files["modmain.lua"] = {
    max_code_line_length = 100,
    max_comment_line_length = 250,
    max_line_length = 100,
    max_string_line_length = 100,

    -- globals
    globals = {
        "Assets",
        "GLOBAL",
    },
    read_globals = {
        "AddClassPostConstruct",
        "AddGamePostInit",
        "Asset",
        "GetModConfigData",
        "modname",
    },
}

files["scripts/**/*.lua"] = {
    max_code_line_length = 100,
    max_comment_line_length = 250,
    max_line_length = 100,
    max_string_line_length = 100,

    -- globals
    globals = {
        -- general
        "__STRICT",
        "_G",
        "dumptable",
        "JoinServer",
        "OnNetworkDisconnect",
        "shallowcopy",
        "ShowConnectingToGamePopup",

        -- project
        "Debug",
        "MOD_AUTO_JOIN",
    },
    read_globals = {
        -- general
        "AreAnyClientModsEnabled",
        "DisableAllDLC",
        "DoRestart",
        "IsMigrating",
        "KnownModIndex",
        "Profile",
        "SavePersistentString",
        "ServerPreferences",
        "TheFrontEnd",
        "TheNet",
        "TheSim",
        "TheWorld",
        "TrackedAssert",

        -- constants
        "ANCHOR_BOTTOM",
        "ANCHOR_LEFT",
        "ANCHOR_MIDDLE",
        "ANCHOR_RIGHT",
        "ANCHOR_TOP",
        "BACK_BUTTON_Y",
        "BRANCH",
        "CHATFONT",
        "CONTROL_ACCEPT",
        "ENCODE_SAVES",
        "FRAMES",
        "HEADERFONT",
        "KEY_ALT",
        "KEY_CTRL",
        "KEY_LALT",
        "KEY_LCTRL",
        "KEY_LSHIFT",
        "KEY_RALT",
        "KEY_RCTRL",
        "KEY_RSHIFT",
        "KEY_SHIFT",
        "MOD_DEV_TOOLS",
        "NEWFONT_OUTLINE",
        "PLATFORM",
        "RESOLUTION_X",
        "RESOLUTION_Y",
        "STRINGS",
        "UICOLOURS",
        "USER_HISTORY_EXPIRY_TIME",

        -- threads
        "KillThreadsWithID",
        "scheduler",
        "Sleep",
        "StartThread",
    },
}

files["spec/**/*.lua"] = {
    max_code_line_length = 100,
    max_comment_line_length = 250,
    max_line_length = 100,
    max_string_line_length = 100,

    -- globals
    globals = {
        -- general
        "_G",
        "Class",
        "ClassRegistry",
        "package",
        "TheSim",

        -- project
        "AssertChainNil",
        "AssertGetter",
        "AssertMethodExists",
        "AssertMethodIsMissing",
        "AssertSetter",
        "DebugSpy",
        "DebugSpyAssert",
        "DebugSpyAssertWasCalled",
        "DebugSpyClear",
        "DebugSpyInit",
        "DebugSpyTerm",
        "Empty",
        "ReturnValueFn",
        "ReturnValues",
        "ReturnValuesFn",
    },
    read_globals = {
        "rawget",
        "setmetatable",
    },
}
