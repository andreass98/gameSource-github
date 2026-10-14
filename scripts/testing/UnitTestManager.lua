UnitTestManager = {}
UnitTestManager.UNIT_TESTS_DIRECTORY = "dataS/scripts/testing/unitTests/"
UnitTestManager.TEST_FUNCTION_PREFIX = "test_"
function UnitTestManager.testAll()
    executeConsoleCommand("debuggerPopups false", true)
    Assert.doErrorOnFail = true
    Assert.doCallstackOnFail = false
    print("\n Beginning unit tests:")
    local totalRunClassesCount = 0
    local passedClassesCount = 0
    local failedClassesCount = 0
    local files = Files.new(UnitTestManager.UNIT_TESTS_DIRECTORY)
    for _, file in pairs(files.files) do
        if not file.isDirectory then
            local className, extension = Utils.getFilenameInfo(file.filename)
            if extension == "lua" then
                source(UnitTestManager.UNIT_TESTS_DIRECTORY .. file.filename)
                local targetTestClass = string.sub(className, 1, #className - 4)
                local succeeded = UnitTestManager.testClass(targetTestClass, _G[className])
                if succeeded then
                end
            else
                Logging.warning("Cannot test non-lua file: %s", file.filename)
            end
        end
    end
    (failedClassesCount <= 0 and UnitTestManager.logTotalSuccess or UnitTestManager.logTotalFailure)(totalRunClassesCount, passedClassesCount, failedClassesCount)
    Assert.doErrorOnFail = Assert.doErrorOnFail
    Assert.doCallstackOnFail = Assert.doCallstackOnFail
end
function UnitTestManager.testClass(className, class)
    print(string.format("  Testing %s class: ", className))
    local startTime = getTimeSec()
    local totalRunFunctionsCount = 0
    local passedFunctionsCount = 0
    local failedFunctionsCount = 0
    for memberName, member in pairs(class) do
        if type(member) == "function" and string.startsWith(memberName, UnitTestManager.TEST_FUNCTION_PREFIX) then
            local functionName = string.sub(memberName, #UnitTestManager.TEST_FUNCTION_PREFIX + 1)
            if xpcall(member, function(message)
                -- upvalues: (copy) functionName
                UnitTestManager.logFunctionFailure(functionName, message)
            end) then
                UnitTestManager.logFunctionSuccess(functionName)
            end
        end
    end
    local succeeded = failedFunctionsCount <= 0
    (succeeded and UnitTestManager.logClassSuccess or UnitTestManager.logClassFailure)(totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount, (getTimeSec() - startTime) * 1000)
    return succeeded
end
function UnitTestManager.logTotalSuccess(totalRunClassesCount, passedClassesCount, failedClassesCount)
    print(string.format("\226\156\148 Finished %d class tests. (%d passed, %d failed)\n", totalRunClassesCount, passedClassesCount, failedClassesCount))
end
function UnitTestManager.logTotalFailure(totalRunClassesCount, passedClassesCount, failedClassesCount)
    printError(string.format("\226\157\140 Finished %d class tests. (%d passed, %d failed)\n", totalRunClassesCount, passedClassesCount, failedClassesCount))
end
function UnitTestManager.logClassSuccess(totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount, elapsedMilliSeconds)
    print(string.format("  \226\156\148 Finished %d tests for %s class in %dms. (%d passed, %d failed)\n", totalRunFunctionsCount, className, elapsedMilliSeconds, passedFunctionsCount, failedFunctionsCount))
end
function UnitTestManager.logClassFailure(totalRunFunctionsCount, className, passedFunctionsCount, failedFunctionsCount, elapsedMilliSeconds)
    printError(string.format("  \226\157\140 Finished %d tests for %s class in %dms. (%d passed, %d failed)\n", totalRunFunctionsCount, className, elapsedMilliSeconds, passedFunctionsCount, failedFunctionsCount))
end
function UnitTestManager.logFunctionSuccess(functionName)
    print(string.format("     \226\156\148 %s passed", functionName))
end
function UnitTestManager.logFunctionFailure(functionName, message)
    printError(string.format("     \226\157\140 %s failed: ", functionName))
    print("       " .. message)
    printCallstack()
end