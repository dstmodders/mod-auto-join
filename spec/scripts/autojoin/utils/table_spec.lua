require "busted.runner"()
require "class"
require "autojoin/utils"

describe("Utils.Table", function()
    -- before_each initialization
    local Table

    before_each(function()
        Table = require "autojoin/utils/table"
    end)

    describe("TableCompare", function()
        it("should return true when both tables have the same reference", function()
            local test = {}
            assert.is_true(Table.Compare(test, test))
        end)

        it("should return true when both tables with nested ones are the same", function()
            local first = { first = {}, second = { third = {} } }
            local second = { first = {}, second = { third = {} } }
            assert.is_true(Table.Compare(first, second))
        end)

        it("should return false when one of the tables is nil", function()
            local test = {}
            assert.is_false(Table.Compare(nil, test))
            assert.is_false(Table.Compare(test, nil))
        end)

        it("should return false when one of the tables is not a table type", function()
            local test = {}
            assert.is_false(Table.Compare("table", test))
            assert.is_false(Table.Compare(test, "table"))
        end)

        it("should return false when both tables with nested ones are not the same", function()
            local first = { first = {}, second = { third = {} } }
            local second = { first = {}, second = { third = { "fourth" } } }
            assert.is_false(Table.Compare(first, second))
        end)
    end)
end)
