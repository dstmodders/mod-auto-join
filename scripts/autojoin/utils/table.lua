----
-- Different table mod utilities.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-auto-join](https://github.com/victorpopkov/dsto-mod-auto-join)
--
-- @module Utils.Table
-- @see Utils
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.8.0
----
local Table = {}

--- Compares two tables if they are the same.
-- @tparam table a Table A
-- @tparam table b Table B
-- @treturn boolean
function Table.Compare(a, b)
    -- basic validation
    if a == b then
        return true
    end

    -- null check
    if a == nil or b == nil then
        return false
    end

    -- validate type
    if type(a) ~= "table" then
        return false
    end

    -- compare meta tables
    local meta_table_a = getmetatable(a)
    local meta_table_b = getmetatable(b)
    if not Table.Compare(meta_table_a, meta_table_b) then
        return false
    end

    -- compare nested tables
    for index, va in pairs(a) do
        local vb = b[index]
        if not Table.Compare(va, vb) then
            return false
        end
    end

    for index, vb in pairs(b) do
        local va = a[index]
        if not Table.Compare(va, vb) then
            return false
        end
    end

    return true
end

return Table
