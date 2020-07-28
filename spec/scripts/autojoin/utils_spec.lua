require "busted.runner"()

describe("Utils", function()
    -- setup
    local match

    -- before_each initialization
    local Utils

    setup(function()
        -- match
        match = require "luassert.match"

        -- debug
        DebugSpyTerm()
        DebugSpyInit(spy)
    end)

    teardown(function()
        -- debug
        DebugSpyTerm()
    end)

    before_each(function()
        -- initialization
        Utils = require "autojoin/utils"

        -- debug
        DebugSpyClear()
    end)

    describe("chain", function()
        local value, netvar, GetTimeUntilPhase, clock, TheWorld

        before_each(function()
            value = 42
            netvar = { value = spy.new(ReturnValueFn(value)) }
            GetTimeUntilPhase = spy.new(ReturnValueFn(value))

            clock = {
                boolean = true,
                fn = ReturnValueFn(value),
                netvar = netvar,
                number = 1,
                string = "test",
                table = {},
                GetTimeUntilPhase = GetTimeUntilPhase,
            }

            TheWorld = {
                net = {
                    components = {
                        clock = clock,
                    },
                },
            }
        end)

        describe("ChainGet", function()
            describe("when an invalid src is passed", function()
                it("should return nil", function()
                    assert.is_nil(Utils.ChainGet(nil, "net"))
                    assert.is_nil(Utils.ChainGet("nil", "net"))
                    assert.is_nil(Utils.ChainGet(42, "net"))
                    assert.is_nil(Utils.ChainGet(true, "net"))
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(Utils.ChainGet(
                            TheWorld,
                            "net",
                            "components",
                            "clock",
                            "GetTimeUntilPhase"
                        ))
                    end, TheWorld, "net", "components", "clock", "GetTimeUntilPhase")
                end)
            end)

            describe("when the last parameter is true", function()
                it("should return the last field call (function)", function()
                    assert.is_equal(value, Utils.ChainGet(
                        TheWorld,
                        "net",
                        "components",
                        "clock",
                        "fn",
                        true
                    ))
                end)

                it("should return the last field call (table as a function)", function()
                    assert.is_equal(value, Utils.ChainGet(
                        TheWorld,
                        "net",
                        "components",
                        "clock",
                        "GetTimeUntilPhase",
                        true
                    ))

                    assert.spy(GetTimeUntilPhase).was_called(1)
                    assert.spy(GetTimeUntilPhase).was_called_with(match.is_ref(clock))
                end)

                it("should return the last netvar value", function()
                    assert.is_equal(value, Utils.ChainGet(
                        TheWorld,
                        "net",
                        "components",
                        "clock",
                        "netvar",
                        true
                    ))

                    assert.spy(netvar.value).was_called(1)
                    assert.spy(netvar.value).was_called_with(match.is_ref(netvar))
                end)

                local fields = {
                    "boolean",
                    "number",
                    "string",
                    "table",
                }

                for _, field in pairs(fields) do
                    describe("and the previous parameter is a " .. field, function()
                        it("should return nil", function()
                            assert.is_nil(Utils.ChainGet(
                                TheWorld,
                                "net",
                                "components",
                                "clock",
                                field,
                                true
                            ), field)
                        end)
                    end)
                end

                describe("and the previous parameter is a nil", function()
                    it("should return nil", function()
                        assert.is_nil(Utils.ChainGet(
                            TheWorld,
                            "net",
                            "components",
                            "test",
                            true
                        ))
                    end)
                end)
            end)

            it("should return the last field", function()
                assert.is_equal(GetTimeUntilPhase, Utils.ChainGet(
                    TheWorld,
                    "net",
                    "components",
                    "clock",
                    "GetTimeUntilPhase"
                ))

                assert.spy(GetTimeUntilPhase).was_not_called()
            end)
        end)

        describe("ChainValidate", function()
            describe("when an invalid src is passed", function()
                it("should return false", function()
                    assert.is_false(Utils.ChainValidate(nil, "net"))
                    assert.is_false(Utils.ChainValidate("nil", "net"))
                    assert.is_false(Utils.ChainValidate(42, "net"))
                    assert.is_false(Utils.ChainValidate(true, "net"))
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(Utils.ChainValidate(
                            TheWorld,
                            "net",
                            "components",
                            "clock",
                            "GetTimeUntilPhase"
                        ))
                    end, TheWorld, "net", "components", "clock", "GetTimeUntilPhase")
                end)
            end)

            describe("when all chain fields are available", function()
                it("should return true", function()
                    assert.is_true(Utils.ChainValidate(
                        TheWorld,
                        "net",
                        "components",
                        "clock",
                        "GetTimeUntilPhase"
                    ))
                end)
            end)
        end)
    end)

    describe("modmain", function()
        describe("HideChangelog", function()
            before_each(function()
                _G.KnownModIndex = {
                    GetModInfo = spy.new(Empty),
                }
            end)

            after_each(function()
                Utils.HideChangelog(nil, false)
            end)

            teardown(function()
                _G.KnownModIndex = nil
            end)

            describe("when no modname is passed", function()
                describe("and enabling", function()
                    it("shouldn't override KnownModIndex:GetModInfo()", function()
                        local old = _G.KnownModIndex.GetModInfo
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                        Utils.HideChangelog(nil, true)
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    end)

                    it("should return false", function()
                        assert.is_false(Utils.HideChangelog(nil, true))
                    end)
                end)

                describe("and disabling", function()
                    it("shouldn't override KnownModIndex:GetModInfo()", function()
                        local old = _G.KnownModIndex.GetModInfo
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                        Utils.HideChangelog(nil, false)
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    end)

                    it("should return false", function()
                        assert.is_false(Utils.HideChangelog(nil, false))
                    end)
                end)
            end)

            describe("when modname is passed", function()
                local modname

                before_each(function()
                    modname = "dst-mod-auto-join"
                end)

                describe("and enabling", function()
                    it("should override KnownModIndex:GetModInfo()", function()
                        local old = _G.KnownModIndex.GetModInfo
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                        Utils.HideChangelog(modname, true)
                        assert.is_not_equal(old, _G.KnownModIndex.GetModInfo)
                    end)

                    it("should return true", function()
                        assert.is_true(Utils.HideChangelog(modname, true))
                    end)
                end)

                describe("and disabling", function()
                    it("shouldn't override KnownModIndex:GetModInfo()", function()
                        local old = _G.KnownModIndex.GetModInfo
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                        Utils.HideChangelog(modname, false)
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    end)

                    it("should return false", function()
                        assert.is_false(Utils.HideChangelog(modname, false))
                    end)
                end)
            end)
        end)
    end)

    describe("table", function()
        describe("TableCompare", function()
            describe("when both tables have the same reference", function()
                local first

                before_each(function()
                    first = {}
                end)

                it("should return true", function()
                    assert.is_true(Utils.TableCompare(first, first))
                end)
            end)

            describe("when both tables with nested ones are the same", function()
                local first, second

                before_each(function()
                    first = { first = {}, second = { third = {} } }
                    second = { first = {}, second = { third = {} } }
                end)

                it("should return true", function()
                    assert.is_true(Utils.TableCompare(first, second))
                end)
            end)

            describe("when one of the tables is nil", function()
                local first

                before_each(function()
                    first = {}
                end)

                it("should return false", function()
                    assert.is_false(Utils.TableCompare(nil, first))
                    assert.is_false(Utils.TableCompare(first, nil))
                end)
            end)

            describe("when one of the tables is not a table type", function()
                local first

                before_each(function()
                    first = {}
                end)

                it("should return false", function()
                    assert.is_false(Utils.TableCompare("table", first))
                    assert.is_false(Utils.TableCompare(first, "table"))
                end)
            end)

            describe("when both tables with nested ones are not the same", function()
                local first, second

                before_each(function()
                    first = { first = {}, second = { third = {} } }
                    second = { first = {}, second = { third = { "fourth" } } }
                end)

                it("should return false", function()
                    assert.is_false(Utils.TableCompare(first, second))
                end)
            end)
        end)
    end)
end)
