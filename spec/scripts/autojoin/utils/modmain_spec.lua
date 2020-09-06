require "busted.runner"()
require "class"
require "autojoin/utils"

describe("Utils.Entity", function()
    -- before_each initialization
    local Modmain

    before_each(function()
        Modmain = require "autojoin/utils/modmain"
    end)

    describe("HideChangelog", function()
        before_each(function()
            _G.KnownModIndex = {
                GetModInfo = spy.new(Empty),
            }
        end)

        after_each(function()
            Modmain.HideChangelog(nil, false)
        end)

        teardown(function()
            _G.KnownModIndex = nil
        end)

        describe("when no modname is passed", function()
            describe("and enabling", function()
                it("shouldn't override KnownModIndex:GetModInfo()", function()
                    local old = _G.KnownModIndex.GetModInfo
                    assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    Modmain.HideChangelog(nil, true)
                    assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                end)

                it("should return false", function()
                    assert.is_false(Modmain.HideChangelog(nil, true))
                end)
            end)

            describe("and disabling", function()
                it("shouldn't override KnownModIndex:GetModInfo()", function()
                    local old = _G.KnownModIndex.GetModInfo
                    assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    Modmain.HideChangelog(nil, false)
                    assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                end)

                it("should return false", function()
                    assert.is_false(Modmain.HideChangelog(nil, false))
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
                    Modmain.HideChangelog(modname, true)
                    assert.is_not_equal(old, _G.KnownModIndex.GetModInfo)
                end)

                it("should return true", function()
                    assert.is_true(Modmain.HideChangelog(modname, true))
                end)
            end)

            describe("and disabling", function()
                it("shouldn't override KnownModIndex:GetModInfo()", function()
                    local old = _G.KnownModIndex.GetModInfo
                    assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    Modmain.HideChangelog(modname, false)
                    assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                end)

                it("should return false", function()
                    assert.is_false(Modmain.HideChangelog(modname, false))
                end)
            end)
        end)
    end)
end)
