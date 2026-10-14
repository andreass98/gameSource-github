g_currentTest = nil
local tests = {
    ["TestAnimalCluster"] = {
        ["className"] = "TestAnimalCluster",
        ["filename"] = "dataS/scripts/animals/husbandry/cluster/TestAnimalCluster.lua"
    },
    ["TestI3DManager"] = {
        ["className"] = "TestI3DManager",
        ["filename"] = "dataS/scripts/i3d/TestI3DManager.lua"
    },
    ["TestDebugElements"] = {
        ["className"] = "TestDebugElements",
        ["filename"] = "dataS/scripts/debug/TestDebugElements.lua"
    },
    ["TestXML"] = {
        ["className"] = "TestXML",
        ["filename"] = "dataS/scripts/xml/TestXML.lua"
    },
    ["TestPolygon"] = {
        ["className"] = "TestPolygon",
        ["filename"] = "dataS/scripts/collections/TestPolygon.lua"
    },
    ["TestMathUtil"] = {
        ["className"] = "TestMathUtil",
        ["filename"] = "dataS/scripts/utils/TestMathUtil.lua"
    }
}
function initTesting()
    -- upvalues: (copy) tests
    local testName = StartParams.getValue("test")
    if testName ~= nil then
        local data = tests[testName]
        if data ~= nil then
            source(data.filename)
            g_currentTest = ClassUtil.getClassObject(data.className)
            if g_currentTest ~= nil then
                g_currentTest.init()
                Logging.info("Started test \'%s\'", testName)
                return true
            end
            Logging.error("Test \'%s\' not defined", testName)
        end
    end
    return false
end