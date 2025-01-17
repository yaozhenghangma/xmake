--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        table.lua
--

-- define module: table
local table = table or {}

-- clear table
if not table.clear then
    if xmake._LUAJIT then
        table.clear = require("table.clear")
    else
        function table.clear(t)
            for k, v in pairs(t) do
                t[k] = nil
            end
        end
    end
end

-- new table
if not table.new then
    if xmake._LUAJIT then
        table.new = require("table.new")
    else
        function table.new(narray, nhash)
            -- TODO
            return {}
        end
    end
end

-- get array length
if not table.getn then
    function table.getn(t)
        return #t
    end
end

-- get array max integer key for lua5.4
if not table.maxn then
    function table.maxn(t)
        local max = 0
        for k, _ in pairs(t) do
            if type(k) == "number" and k > max then
                max = k
            end
        end
        return max
    end
end

-- move values of table(a1) to table(a2)
--
-- disable the builtin implementation for android termux/arm64, it will crash when calling `table.move({1, 1}, 1, 2, 1, {})`
--
-- @see https://github.com/xmake-io/xmake/pull/667#issuecomment-575859604
--
if xmake._ARCH:startswith("arm") then
    function table.move(a1, f, e, t, a2)
        if a2 == nil then a2 = a1 end
        assert(a1)
        assert(a2)
        if e >= f then
            local d = t - f
            if t > e or t <= f or a2 ~= a1 then
                for i = f, e do a2[i + d] = a1[i] end
            else
                for i = e, f, -1 do a2[i + d] = a1[i] end
            end
        end
        return a2
    end
end

-- join all objects and tables
function table.join(...)
    local result = {}
    for _, t in ipairs({...}) do
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(k) == "number" then table.insert(result, v)
                else result[k] = v end
            end
        else
            table.insert(result, t)
        end
    end
    return result
end

-- join all objects and tables to self
function table.join2(self, ...)
    for _, t in ipairs({...}) do
        if type(t) == "table" then
            for k, v in pairs(t) do
                if type(k) == "number" then table.insert(self, v)
                else self[k] = v end
            end
        else
            table.insert(self, t)
        end
    end
    return self
end

-- swap items in array
function table.swap(array, i, j)
    local val = array[i]
    array[i] = array[j]
    array[j] = val
end

-- append all objects to array
function table.append(array, ...)
    for _, value in ipairs({...}) do
        table.insert(array, value)
    end
    return array
end

-- copy the table to self
function table.copy(copied)
    local result = {}
    copied = copied or {}
    for k, v in pairs(table.wrap(copied)) do
        result[k] = v
    end
    return result
end

-- copy the table to self
function table.copy2(self, copied)

    -- clear self first
    table.clear(self)

    -- copy it
    copied = copied or {}
    for k, v in pairs(table.wrap(copied)) do
        self[k] = v
    end
end

-- inherit interfaces and create a new instance
function table.inherit(...)
    local classes = {...}
    local instance = {}
    local metainfo = {}
    for _, clasz in ipairs(classes) do
        for k, v in pairs(clasz) do
            if type(v) == "function" then
                if k:startswith("__") then
                    if metainfo[k] == nil then
                        metainfo[k] = v
                    end
                else
                    if instance[k] == nil then
                        instance[k] = v
                    else
                        instance["_super_" .. k] = v
                    end
                end
            end
        end
    end
    setmetatable(instance, metainfo)
    return instance
end

-- inherit interfaces from the given class
function table.inherit2(self, ...)
    local classes = {...}
    local metainfo = getmetatable(self) or {}
    for _, clasz in ipairs(classes) do
        for k, v in pairs(clasz) do
            if type(v) == "function" then
                if k:startswith("__") then
                    if metainfo[k] == nil then
                        metainfo[k] = v
                    end
                else
                    if self[k] == nil then
                        self[k] = v
                    else
                        self["_super_" .. k] = v
                    end
                end
            end
        end
    end
    return self
end

-- slice table array
function table.slice(self, first, last, step)
    local sliced = {}
    for i = first or 1, last or #self, step or 1 do
        sliced[#sliced + 1] = self[i]
    end
    return sliced
end

-- is array?
function table.is_array(array)
    return type(array) == "table" and array[1] ~= nil
end

-- is dictionary?
function table.is_dictionary(dict)
    return type(dict) == "table" and dict[1] == nil
end

-- does contain the given values in table?
-- contains arg1 or arg2 ...
function table.contains(t, arg1, arg2, ...)
    local found = false
    if arg2 == nil then -- only one value
        if table.is_array(t) then
            for _, v in ipairs(t) do
                if v == arg1 then
                    found = true
                    break
                end
            end
        else
            for _, v in pairs(t) do
                if v == arg1 then
                    found = true
                    break
                end
            end
        end
    else
        local values = {}
        local args = table.pack(arg1, arg2, ...)
        for _, arg in ipairs(args) do
            values[arg] = true
        end
        if table.is_array(t) then
            for _, v in ipairs(t) do
                if values[v] then
                    found = true
                    break
                end
            end
        else
            for _, v in pairs(t) do
                if values[v] then
                    found = true
                    break
                end
            end
        end
    end
    return found
end

-- read data from iterator, push them to an array
-- usage: table.to_array(ipairs("a", "b")) -> {{1,"a",n=2},{2,"b",n=2}},2
-- usage: table.to_array(io.lines("file")) -> {"line 1","line 2", ... , "line n"},n
function table.to_array(iterator, state, var)

    assert(iterator)

    local result = {}
    local count = 0
    while true do
        local data = table.pack(iterator(state, var))
        if data[1] == nil then break end
        var = data[1]

        if data.n == 1 then
            table.insert(result, var)
        else
            table.insert(result, data)
        end
        count = count + 1
    end

    return result, count
end

-- unwrap object if be only one
function table.unwrap(object)
    if type(object) == "table" then
        if #object == 1 then
            return object[1]
        end
    end
    return object
end

-- wrap object to table
function table.wrap(object)

    -- no object?
    if nil == object then
        return {}
    end

    -- wrap it if not table
    if type(object) ~= "table" then
        return {object}
    end

    -- ok
    return object
end

-- remove repeat from the given array
function table.unique(array, barrier)
    if table.is_array(array) then
        if table.getn(array) ~= 1 then
            local exists = {}
            local unique = {}
            for _, v in ipairs(array) do
                -- exists barrier? clear the current existed items
                if barrier and barrier(v) then
                    exists = {}
                end
                -- add unique item
                if not exists[v] then
                    exists[v] = true
                    table.insert(unique, v)
                end
            end
            array = unique
        end
    end
    return array
end

-- reverse to remove repeat from the given array
function table.reverse_unique(array, barrier)
    if table.is_array(array) then
        if table.getn(array) ~= 1 then
            local exists = {}
            local unique = {}
            local n = #array
            for i = 1, n do
                local v = array[n - i + 1]
                -- exists barrier? clear the current existed items
                if barrier and barrier(v) then
                    exists = {}
                end
                -- add unique item
                if not exists[v] then
                    exists[v] = true
                    table.insert(unique, 1, v)
                end
            end
            array = unique
        end
    end
    return array
end

-- pack arguments into a table
-- polyfill of lua 5.2, @see https://www.lua.org/manual/5.2/manual.html#pdf-table.pack
function table.pack(...)
    return { n = select("#", ...), ... }
end

-- table.unpack table values
-- polyfill of lua 5.2, @see https://www.lua.org/manual/5.2/manual.html#pdf-unpack
table.unpack = table.unpack or unpack

-- get keys of a table
function table.keys(tab)

    assert(tab)

    local keyset = {}
    local n = 0
    for k, _ in pairs(tab) do
        n = n + 1
        keyset[n] = k
    end
    return keyset, n
end

-- get order keys of a table
function table.orderkeys(tab)
    local keys = table.keys(tab)
    table.sort(keys)
    return keys
end

-- order key/value iterator
--
-- for k, v in table.orderpairs(t) do
--   TODO
-- end
function table.orderpairs(t)
    local orderkeys = table.orderkeys(t)
    local i = 1
    return function (t, k)
        k = orderkeys[i]
        i = i + 1
        return k, t[k]
    end, t, nil
end

-- get values of a table
function table.values(tab)

    assert(tab)

    local valueset = {}
    local n = 0
    for _, v in pairs(tab) do
        n = n + 1
        valueset[n] = v
    end
    return valueset, n
end

-- map values to a new table
function table.map(tab, mapper)

    assert(tab)
    assert(mapper)

    local newtab = {}
    for k, v in pairs(tab) do
        newtab[k] = mapper(k, v)
    end
    return newtab
end

-- map values to a new array
function table.imap(arr, mapper)

    assert(arr)
    assert(mapper)

    local newarr = {}
    for k, v in ipairs(arr) do
        table.insert(newarr, mapper(k, v))
    end
    return newarr
end

-- reverse table values
function table.reverse(arr)

    assert(arr)

    local revarr = {}
    local l = #arr
    for i = 1, l do
        revarr[i] = arr[l - i + 1]
    end
    return revarr
end

-- return module: table
return table
