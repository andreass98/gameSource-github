TableTest = {}
function TableTest.test_addElement()
    Assert.throwsError(function()
        table.addElement(nil, 1)
    end, "Nil as table argument does not raise an error")
    for _, valueToAdd in ipairs({
        true,
        false,
        -1,
        0,
        1,
        math.huge,
        "",
        " ",
        "\n",
        "1",
        {}
    }) do
        local tbl = {}
        local success, index = table.addElement(tbl, valueToAdd)
        Assert.isTrue(success, "element \'%s\' of type %s was not added to the table", valueToAdd, (type(valueToAdd)))
        Assert.areEqual(index, 1)
        local success, index = table.addElement(tbl, valueToAdd)
        Assert.isFalse(success)
        Assert.areEqual(index, 1)
    end
    local tbl = {}
    table.addElement(tbl, "test")
    table.clear(tbl)
    local success, _ = table.addElement(tbl, "test")
    Assert.isTrue(success)
    Assert.areEqual(_, 1)
end
function TableTest.test_removeElement()
    Assert.throwsError(function()
        table.removeElement(nil, 1)
    end, "Nil as table argument does not raise an error")
    Assert.isFalse(table.removeElement({}, "element"))
    local tbl = { "element", "element" }
    Assert.isTrue(table.removeElement(tbl, "element"))
    Assert.isTrue(table.removeElement(tbl, "element"))
    Assert.isFalse(table.removeElement(tbl, "element"))
    for _, valueToAdd in ipairs({
        true,
        false,
        -1,
        0,
        1,
        math.huge,
        "",
        " ",
        "\n",
        "1",
        {}
    }) do
        local tbl = {}
        table.addElement(tbl, valueToAdd)
        Assert.isTrue(table.removeElement(tbl, valueToAdd))
    end
end
function TableTest.test_hasElement()
    Assert.throwsError(function()
        table.hasElement(nil, 1)
    end, "Nil as table argument does not raise an error")
    Assert.isFalse(table.hasElement({}, "element"))
    Assert.isFalse(table.hasElement({ "a" }, "b"))
    local tbl = { "element", "element" }
    Assert.isTrue(table.hasElement(tbl, "element"))
    table.remove(tbl, 1)
    Assert.isTrue(table.hasElement(tbl, "element"))
    table.remove(tbl, 1)
    Assert.isFalse(table.hasElement(tbl, "element"))
end
function TableTest.test_isList()
    Assert.throwsError(function()
        table.isList(nil)
    end, "Nil as table argument does not raise an error")
    Assert.isTrue(table.isList({}))
    Assert.isTrue(table.isList({ "a", "b", "c" }))
    Assert.isFalse(table.isList({
        ["a"] = "a",
        "b",
        "c"
    }))
    Assert.isFalse(table.isList({
        [0] = "a",
        [1] = "b",
        [2] = "c"
    }))
    Assert.isFalse(table.isList({
        [2] = "a",
        [3] = "b",
        [4] = "c"
    }))
    Assert.isFalse(table.isList({
        [1] = "a",
        [3] = "b",
        [4] = "c"
    }))
    Assert.isFalse(table.isList({
        "a",
        "b",
        "c",
        [2] = nil
    }))
    local tbl = { "a", "b", "c" }
    table.remove(tbl, 1)
    Assert.isTrue(table.isList(tbl))
end
function TableTest.test_clone()
    Assert.throwsError(function()
        table.clone(nil)
    end, "Nil as table argument does not raise an error")
    local tblIn = {}
    Assert.areNotEqual(table.clone(tblIn), tblIn)
    local tblOut = {
        ["innerTbl"] = {}
    }
    local tblOut = table.clone(tblOut)
    Assert.areEqual(tblOut.innerTbl, tblOut.innerTbl)
    local tvlOutDeep = table.clone(tblOut, 2)
    Assert.areNotEqual(tvlOutDeep.innerTbl, tblOut.innerTbl)
    local values = {
        true,
        false,
        -1,
        0,
        1,
        math.huge,
        "",
        " ",
        "\n",
        "1",
        {}
    }
    local valuesCloned = table.clone(values, 1)
    for k, v in ipairs(values) do
        Assert.areEqual(valuesCloned[k], v, "cloned value \'%s\' is not equal to source \'%s\'", valuesCloned[k], v)
    end
    local tbl = table.clone(tblOut, math.huge)
    Assert.areNotEqual(tbl.innerTbl, tblOut.innerTbl, "sub tables of clone are identical with source when depth=math.huge")
    Assert.throwsError(function()
        table.clone({}, true)
    end, "Boolean depth argument does not raise an error")
    Assert.throwsError(function()
        table.clone({}, -1)
    end, "Negative depth argument does not raise an error")
    local tbl = {
        ["a"] = {}
    }
    Assert.throwsError(function()
        -- upvalues: (copy) tbl
        table.clone(tbl, true)
    end, "Boolean value for \'depth\' argument does not raise an error")
    Assert.throwsError(function()
        -- upvalues: (copy) tbl
        table.clone(tbl, {})
    end, "Table value for \'depth\' argument does not raise an error")
    Assert.throwsError(function()
        -- upvalues: (copy) tbl
        table.clone(tbl, "yes")
    end, "String value for \'depth\' argument does not raise an error")
end
function TableTest.test_size()
    Assert.throwsError(function()
        table.size(nil)
    end, "Nil as table argument does not raise an error")
    Assert.areEqual(table.size({}), 0)
    Assert.areEqual(table.size({ "a" }), 1)
    Assert.areEqual(table.size({ nil }), 0)
    Assert.areEqual(table.size({
        ["a"] = "a"
    }), 1)
    Assert.areEqual(table.size({
        ["a"] = "a",
        "b"
    }), 2)
end
function TableTest.test_getRandomElement()
    Assert.throwsError(function()
        table.getRandomElement(nil)
    end, "Nil as table argument does not raise an error")
    Assert.isNil(table.getRandomElement({}))
    Assert.areEqual(table.getRandomElement({ "a" }), "a")
    local tblA = {
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g"
    }
    for _, v in ipairs(tblA) do
        ({})[v] = true
    end
    local i = 1
    for i = i, 100000 do
        tblB[table.getRandomElement(tblA)] = nil
        if table.size(tblB) == 0 then
            break
        end
        if i == 10000 then
            Assert.areEqual(table.size(tblB), 0)
        end
    end
end
function TableTest.test_copyIndex()
    Assert.throwsError(function()
        table.copyIndex(nil)
    end, "Nil as table argument does not raise an error")
    local input = {
        ["a"] = 1,
        ["b"] = 2
    }
    local output = table.copyIndex(input)
    Assert.areEqual(#output, 0)
    Assert.areNotEqual(#output, table.size(input))
    Assert.isTrue(table.isList(output))
    local input = { "a", "b", "c" }
    local output = table.copyIndex(input)
    Assert.areEqual(#input, #output)
    Assert.isTrue(table.isList(output))
    local input = {
        "a",
        "b",
        "c",
        ["test"] = 4
    }
    local output = table.copyIndex(input)
    Assert.areEqual(#input, #output)
    Assert.areNotEqual(#output, table.size(input))
    Assert.isTrue(table.isList(output))
end
function TableTest.test_toList()
    Assert.throwsError(function()
        table.toList(nil)
    end, "Nil as table argument does not raise an error")
    local set = {
        ["a"] = "",
        ["b"] = "",
        ["c"] = ""
    }
    local list = table.toList(set)
    Assert.areEqual(table.size(set), #list)
    for k in pairs(set) do
        Assert.isTrue(table.hasElement(list, k))
    end
end
function TableTest.test_toSet()
    Assert.throwsError(function()
        table.toSet(nil)
    end, "Nil as table argument does not raise an error")
    local list = { "a", "b", "c" }
    local set = table.toSet(list)
    Assert.areEqual(table.size(set), #list)
    for k in pairs(set) do
        Assert.isTrue(table.hasElement(list, k))
    end
    local set = table.toSet({
        "a",
        "b",
        "a",
        "c",
        "c"
    })
    Assert.areEqual(table.size(set), 3)
end
function TableTest.test_ifilter()
    Assert.throwsError(function()
        table.ifilter(nil, function(val)
            return val
        end)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.ifilter({}, nil)
    end, "Nil as closure argument does not raise an error")
    local tbl = {
        "a",
        "b",
        "c",
        "d"
    }
    local tblFiltered = table.ifilter(tbl, function(value, _)
        return value ~= "b"
    end)
    Assert.areEqual(#tblFiltered, 3)
    Assert.isFalse(table.hasElement(tblFiltered, "b"))
    Assert.areEqual(#tbl, 4)
    Assert.isTrue(table.hasElement(tbl, "b"))
    local empty = table.ifilter(tbl, function()
        return false
    end)
    Assert.areEqual(#empty, 0)
    local all = table.ifilter(tbl, function()
        return true
    end)
    Assert.areEqual(#all, #tbl)
    local tblMixed = {
        "a",
        "b",
        "c",
        ["c"] = true,
        ["key1"] = "a",
        ["key2"] = "b"
    }
    local tblMixedFiltered = table.ifilter(tblMixed, function(value, _)
        return value ~= "b"
    end)
    Assert.areEqual(#tblMixedFiltered, 2)
    Assert.areEqual(table.size(tblMixedFiltered), #tblMixedFiltered)
    Assert.isFalse(table.hasElement(tblMixedFiltered, "b"))
    local all = table.ifilter(tblMixed, function()
        return true
    end)
    Assert.areEqual(#all, #tblMixed)
    Assert.areNotEqual(#all, table.size(tblMixed))
end
function TableTest.test_filter()
    Assert.throwsError(function()
        table.filter(nil, function(val)
            return val
        end)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.filter({}, nil)
    end, "Nil as closure argument does not raise an error")
    local tbl = {
        "a",
        "b",
        "c",
        ["c"] = true
    }
    local tblFiltered = table.filter(tbl, function(value, _)
        return value ~= "b"
    end)
    Assert.areEqual(table.size(tblFiltered), 3)
    Assert.isNil(tblFiltered.b)
    Assert.areEqual(table.size(tbl), 4)
    Assert.isTrue(table.hasElement(tbl, "b"))
    local empty = table.filter(tbl, function()
        return false
    end)
    Assert.areEqual(table.size(empty), 0)
    local all = table.filter(tbl, function()
        return true
    end)
    Assert.areEqual(table.size(all), table.size(tbl))
    local tblMixed = {
        "a",
        "b",
        "c",
        ["c"] = true,
        ["key1"] = "a",
        ["key2"] = "b"
    }
    local tblMixedFiltered = table.filter(tblMixed, function(value, _)
        return value ~= "b"
    end)
    Assert.areEqual(table.size(tblMixedFiltered), 4)
    Assert.isFalse(table.hasElement(tblMixedFiltered, "b"))
    Assert.isNil(tblMixedFiltered.b)
    local all = table.filter(tblMixed, function()
        return true
    end)
    Assert.areEqual(table.size(all), table.size(tblMixed))
end
function TableTest.test_concatKeys()
    Assert.throwsError(function()
        table.concatKeys(nil)
    end, "Nil as table argument does not raise an error")
    Assert.areEqual(table.concatKeys({}), "")
    Assert.areEqual(table.concatKeys({}, "sep"), "")
    local tbl = {
        ["a"] = 1,
        ["b"] = 2,
        ["cd"] = 3
    }
    local str = table.concatKeys(tbl)
    local strConcat = ""
    for k in pairs(tbl) do

    end
    Assert.areEqual(str, strConcat)
    local separtor = { "a", "b", "c" }
    local separtor = table.concatKeys(separtor)
    local strConcat = ""
    for k in pairs(separtor) do

    end
    Assert.areEqual(separtor, strConcat)
    table.concatKeys({
        [{}] = true,
        [{}] = true,
        [{}] = true,
        ["a"] = false,
        [2] = true
    })
    table.concatKeys({
        ["a"] = 1,
        ["b"] = 2,
        ["cd"] = 3
    }, nil)
    local keys = {
        ["a"] = 1,
        ["b"] = 2,
        ["cd"] = 3
    }
    local keys = table.concatKeys(keys, "<sep>")
    local strConcat = ""
    for k in pairs(keys) do
        if strConcat ~= "" then
        end
        strConcat = strConcat .. k
    end
    Assert.areEqual(keys, strConcat)
    Assert.throwsError(function()
        table.concatKeys({}, {})
    end, "table value for separator does not raise an error")
    Assert.throwsError(function()
        table.concatKeys({}, true)
    end, "boolean value for separator does not raise an error")
    Assert.areEqual(table.concatKeys({
        ["a"] = true,
        ["b"] = true
    }, 2), "a2b")
    local keys = {}
    local numChars = 0
    local k = 256
    local k = 1
    for numChars = numChars, k, k do
        local key = ""
        while numChars > 0 do
            key = key .. string.sub(getMD5((tostring(numChars))), 0, numChars)
            numChars = numChars - 32
        end
        keys[key] = true
    end
    table.concatKeys(keys, ", ")
    table.concatKeys(keys, "")
    table.concatKeys(keys, "\n")
    table.concatKeys(keys, "                            ")
end
function TableTest.test_equalLists()
    Assert.throwsError(function()
        table.equalLists(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.equalLists({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.equalLists(nil, {})
    end, "Nil as table argument does not raise an error")
    local listA = {}
    local listB = {}
    Assert.isTrue(table.equalLists(listA, listB))
    Assert.isTrue(table.equalLists(listA, listB, true))
    local listA = { "A", "B", "C" }
    local listB = { "A", "B", "C" }
    Assert.isTrue(table.equalLists(listA, listB))
    Assert.isTrue(table.equalLists(listA, listB, true))
    local listA = {}
    local listB = { "A" }
    Assert.isFalse(table.equalLists(listA, listB))
    Assert.isFalse(table.equalLists(listA, listB, true))
    local listA = { "A" }
    local listB = {}
    Assert.isFalse(table.equalLists(listA, listB))
    Assert.isFalse(table.equalLists(listA, listB, true))
    local listA = { "A", "B", "C" }
    local listB = { "A", "C", "B" }
    Assert.isFalse(table.equalLists(listA, listB))
    Assert.isTrue(table.equalLists(listA, listB, true))
    Assert.throwsError(function()
        table.equalLists({
            ["a"] = 1
        }, {
            ["a"] = 1
        }, 1)
    end, "number for orderIndependent argument does not raise an error")
    Assert.throwsError(function()
        table.equalLists({
            ["a"] = 1
        }, {
            ["a"] = 1
        }, "")
    end, "string for orderIndependent argument does not raise an error")
end
function TableTest.test_equalSets()
    Assert.throwsError(function()
        table.equalSets(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.equalSets({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.equalSets(nil, {})
    end, "Nil as table argument does not raise an error")
    Assert.isTrue(table.equalSets({}, {}))
    Assert.isTrue(table.equalSets({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }))
    Assert.isFalse(table.equalSets({}, {
        ["a"] = true
    }))
    Assert.isFalse(table.equalSets({
        ["a"] = true
    }, {}))
    Assert.isFalse(table.equalSets({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = true,
        ["b"] = true,
        ["c"] = true,
        ["d"] = true
    }))
    Assert.isFalse(table.equalSets({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true,
        ["d"] = true
    }, {
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }))
    Assert.isTrue(table.equalSets({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = true,
        ["c"] = true,
        ["b"] = true
    }))
    Assert.isFalse(table.equalSets({
        true,
        ["a"] = true
    }, {
        ["a"] = true
    }))
end
function TableTest.test_getListUnion()
    Assert.throwsError(function()
        table.getListUnion(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getListUnion({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getListUnion(nil, {})
    end, "Nil as table argument does not raise an error")
    Assert.areEqual(#table.getListUnion({}, {}), 0)
    local listA = { "A", "B", "C" }
    local listB = { "A", "B", "C" }
    Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
    local listA = { "A", "B", "C" }
    local listB = { "D", "E", "F" }
    Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
    local listA = {}
    local listB = { "A", "B", "C" }
    Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
    local listA = { "A", "B", "C" }
    local listB = {}
    Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
    local listA = {
        "A",
        "B",
        "C",
        ["key"] = "D"
    }
    local listB = {
        ["key"] = "E"
    }
    Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
    Assert.areEqual(#table.getListUnion(listA, listB), 3)
end
function TableTest.test_getSetUnion()
    Assert.throwsError(function()
        table.getSetUnion(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getSetUnion({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getSetUnion(nil, {})
    end, "Nil as table argument does not raise an error")
    Assert.areEqual(table.size(table.getSetUnion({}, {})), 0)
    Assert.areEqual(table.size(table.getSetUnion({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    })), 3)
    Assert.areEqual(table.size(table.getSetUnion({}, {
        ["a"] = true
    })), 1)
    Assert.areEqual(table.size(table.getSetUnion({
        ["a"] = true
    }, {})), 1)
    Assert.areEqual(table.size(table.getSetUnion({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["d"] = true,
        ["e"] = true,
        ["f"] = true
    })), 6)
    Assert.areEqual(table.size(table.getSetUnion({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = true,
        ["b"] = true,
        ["d"] = true
    })), 4)
end
function TableTest.test_getTableUnion()
    Assert.throwsError(function()
        table.getTableUnion(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getTableUnion({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getTableUnion(nil, {})
    end, "Nil as table argument does not raise an error")
    local union = table.getTableUnion({}, {})
    Assert.areEqual(table.size(union), 0)
    local setB = {
        ["a"] = 4,
        ["b"] = 5,
        ["c"] = 6
    }
    local union = table.getTableUnion({
        ["a"] = 1,
        ["b"] = 2,
        ["c"] = 3
    }, setB)
    Assert.areEqual(table.size(union), 3)
    Assert.areEqual(union.a, setB.a)
    Assert.areEqual(union.b, setB.b)
    Assert.areEqual(union.c, setB.c)
    local union = table.getTableUnion({}, {
        ["a"] = 1
    })
    Assert.areEqual(table.size(union), 1)
    local union = table.getTableUnion({
        ["a"] = 1
    }, {})
    Assert.areEqual(table.size(union), 1)
    local setA = {
        ["a"] = 1,
        ["b"] = 2,
        ["c"] = 3
    }
    local setB = {
        ["d"] = 4,
        ["e"] = 5,
        ["f"] = 6
    }
    local union = table.getTableUnion(setA, setB)
    Assert.areEqual(table.size(union), 6)
    Assert.areEqual(union.a, setA.a)
    Assert.areEqual(union.b, setA.b)
    Assert.areEqual(union.c, setA.c)
    Assert.areEqual(union.d, setB.d)
    Assert.areEqual(union.e, setB.e)
    Assert.areEqual(union.f, setB.f)
    local setA = {
        ["a"] = 1,
        ["b"] = 2,
        ["c"] = 3
    }
    local setB = {
        ["a"] = 4,
        ["b"] = 5,
        ["d"] = 6
    }
    local union = table.getTableUnion(setA, setB)
    Assert.areEqual(table.size(union), 4)
    Assert.areEqual(union.a, setB.a)
    Assert.areEqual(union.b, setB.b)
    Assert.areEqual(union.c, setA.c)
    Assert.areEqual(union.d, setB.d)
end
function TableTest.test_getSetSubtraction()
    Assert.throwsError(function()
        table.getSetSubtraction(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getSetSubtraction({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getSetSubtraction(nil, {})
    end, "Nil as table argument does not raise an error")
    local function validateSubtraction(setA, setB, subtraction)
        for k in pairs(setA) do
            if setB[k] == nil then
                Assert.isNotNil(subtraction[k])
            else
                Assert.isNil(subtraction[k])
            end
        end
    end
    Assert.areEqual(table.size(table.getSetSubtraction({}, {})), 0)
    local subtraction = {
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }
    Assert.areEqual(table.size(table.getSetSubtraction(subtraction, {})), table.size(subtraction))
    local subtraction = {
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }
    local subtraction = {
        ["d"] = false
    }
    local subtraction = table.getSetSubtraction(subtraction, subtraction)
    validateSubtraction(subtraction, subtraction, subtraction)
    Assert.areEqual(table.size(subtraction), table.size(subtraction))
    local setA = {
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }
    local setB = {
        ["a"] = false,
        ["b"] = false
    }
    local subtraction = table.getSetSubtraction(setA, setB)
    validateSubtraction(setA, setB, subtraction)
    Assert.areEqual(table.size(subtraction), 1)
    local subtraction = table.getSetSubtraction({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false,
        ["c"] = false
    })
    Assert.areEqual(table.size(subtraction), 0)
end
function TableTest.test_getSetIntersection()
    Assert.throwsError(function()
        table.getSetIntersection(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getSetIntersection({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getSetIntersection(nil, {})
    end, "Nil as table argument does not raise an error")
    Assert.areEqual(table.size(table.getSetIntersection({}, {})), 0)
    Assert.areEqual(table.size(table.getSetIntersection({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {})), 0)
    Assert.areEqual(table.size(table.getSetIntersection({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["d"] = false
    })), 0)
    Assert.areEqual(table.size(table.getSetIntersection({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false
    })), 2)
    Assert.areEqual(table.size(table.getSetIntersection({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false,
        ["c"] = false
    })), 3)
end
function TableTest.test_hasSetIntersection()
    Assert.throwsError(function()
        table.hasSetIntersection(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.hasSetIntersection({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.hasSetIntersection(nil, {})
    end, "Nil as table argument does not raise an error")
    Assert.isFalse(table.hasSetIntersection({}, {}))
    Assert.isFalse(table.hasSetIntersection({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {}))
    Assert.isFalse(table.hasSetIntersection({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["d"] = false
    }))
    Assert.isTrue(table.hasSetIntersection({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false
    }))
    Assert.isTrue(table.hasSetIntersection({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false,
        ["c"] = false
    }))
end
function TableTest.test_isSubset()
    Assert.throwsError(function()
        table.isSubset(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.isSubset({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.isSubset(nil, {})
    end, "Nil as table argument does not raise an error")
    Assert.isTrue(table.isSubset({}, {}))
    Assert.isTrue(table.isSubset({}, {
        ["a"] = true
    }))
    Assert.isFalse(table.isSubset({
        ["a"] = true
    }, {}))
    Assert.isFalse(table.isSubset({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["d"] = false
    }))
    Assert.isFalse(table.isSubset({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false
    }))
    Assert.isTrue(table.isSubset({
        ["a"] = true,
        ["b"] = true
    }, {
        ["a"] = false,
        ["b"] = false,
        ["c"] = true
    }))
    Assert.isTrue(table.isSubset({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false,
        ["c"] = false
    }))
end
function TableTest.test_isProperSubset()
    Assert.throwsError(function()
        table.isProperSubset(nil, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.isProperSubset({}, nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.isProperSubset(nil, {})
    end, "Nil as table argument does not raise an error")
    Assert.isFalse(table.isProperSubset({}, {}))
    Assert.isTrue(table.isProperSubset({}, {
        ["a"] = true
    }))
    Assert.isFalse(table.isProperSubset({
        ["a"] = true
    }, {}))
    Assert.isFalse(table.isProperSubset({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["d"] = false
    }))
    Assert.isFalse(table.isProperSubset({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false
    }))
    Assert.isTrue(table.isProperSubset({
        ["a"] = true,
        ["b"] = true
    }, {
        ["a"] = false,
        ["b"] = false,
        ["c"] = true
    }))
    Assert.isFalse(table.isProperSubset({
        ["a"] = true,
        ["b"] = true,
        ["c"] = true
    }, {
        ["a"] = false,
        ["b"] = false,
        ["c"] = false
    }))
end
function TableTest.test_getndebug()
    Assert.throwsError(function()
        table.getndebug(nil)
    end, "Nil as table argument does not raise an error")
    Assert.throwsError(function()
        table.getndebug({
            ["a"] = 2
        })
    end, "Set as table argument does not raise an error")
    Assert.throwsError(function()
        table.getndebug({
            [1] = "A",
            [3] = "B"
        })
    end, "table with gaps does not raise an error")
    local tbl = { "a", "b", "c" }
    Assert.areEqual(table.getndebug(tbl), #tbl)
    Assert.areEqual(table.getndebug(tbl), 3)
    local tbl = {}
    Assert.areEqual(table.getndebug(tbl), #tbl)
    Assert.areEqual(table.getndebug(tbl), 0)
end
for k in pairs(table) do
    if TableTest["test_" .. k] == nil and ({
        ["getn"] = true,
        ["remove"] = true,
        ["unpack"] = true,
        ["move"] = true,
        ["insert"] = true,
        ["find"] = true,
        ["maxn"] = true,
        ["concat"] = true,
        ["foreachi"] = true,
        ["foreach"] = true,
        ["sort"] = true,
        ["freeze"] = true,
        ["clear"] = true,
        ["pack"] = true,
        ["create"] = true,
        ["isfrozen"] = true
    })[k] == nil then
        printWarning("Warning: no test function for function table." .. k)
    end
end