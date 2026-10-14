Assert = {}
Assert.doErrorOnFail = false
Assert.doCallstackOnFail = true
function Assert.assert(value, valueMessage, message, ...)
    if value then
        return
    else
        message = message or ""
        if Assert.doErrorOnFail then
            error(string.format("Assertion failed! (%s) - " .. tostring(message), valueMessage, ...), 3)
        else
            Logging.error("Assertion failed! (%s) - " .. tostring(message), valueMessage, ...)
            if Assert.doCallstackOnFail then
                printCallstack()
            end
        end
    end
end
function Assert.areEqual(actual, expected, message, ...)
    Assert.assert(expected == actual, string.format("expected: %s, actual: %s", tostring(expected), (tostring(actual))), message, ...)
end
function Assert.areNotEqual(actual, expected, message, ...)
    Assert.assert(expected ~= actual, string.format("expected: %s, actual: %s", tostring(expected), (tostring(actual))), message, ...)
end
function Assert.areRoughlyEqual(actual, expected, epsilon, message, ...)
    epsilon = epsilon or 0.001
    local floatFormatStr = string.format("%%.%df", MathUtil.getIndexOfFirstNonZeroFractionDigit(epsilon) + 1)
    local outputFormatStr = string.format("expected: %s, actual: %s, difference: %s, allowed difference: %s", floatFormatStr, floatFormatStr, floatFormatStr, floatFormatStr)
    Assert.assert(math.abs(actual - expected) <= epsilon, string.format(outputFormatStr, tostring(expected), tostring(actual), math.abs(actual - expected), epsilon), message, ...)
end
function Assert.isBetween(actual, lowerLimit, upperLimit, lowerInclusive, upperInclusive, message, ...)
    if lowerInclusive == nil and true or lowerInclusive then
        Assert.greaterThanOrEqualTo(actual, lowerLimit, message, ...)
    else
        Assert.greaterThan(actual, lowerLimit, message, ...)
    end
    if upperInclusive == nil and true or upperInclusive then
        Assert.lessThanOrEqualTo(actual, upperLimit, message, ...)
    else
        Assert.lessThan(actual, upperLimit, message, ...)
    end
end
function Assert.greaterThan(actual, lowerLimit, message, ...)
    Assert.assert(lowerLimit < actual, string.format("lower limit: %s, actual: %s", tostring(lowerLimit), (tostring(actual))), message, ...)
end
function Assert.greaterThanOrEqualTo(actual, lowerLimit, message, ...)
    Assert.assert(lowerLimit <= actual, string.format("lower limit: %s, actual: %s", tostring(lowerLimit), (tostring(actual))), message, ...)
end
function Assert.lessThan(actual, upperLimit, message, ...)
    Assert.assert(actual < upperLimit, string.format("upper limit: %s, actual: %s", tostring(upperLimit), (tostring(actual))), message, ...)
end
function Assert.lessThanOrEqualTo(actual, upperLimit, message, ...)
    Assert.assert(actual <= upperLimit, string.format("upper limit: %s, actual: %s", tostring(upperLimit), (tostring(actual))), message, ...)
end
function Assert.isClass(actual, expectedClass, message, ...)
    Assert.isType(expectedClass, "table", "Tried to assert a non-table value as the expected class", ...)
    Assert.isType(actual, "table", message, ...)
    Assert.isNotNil(actual.isa, message, ...)
    Assert.assert(actual:isa(expectedClass), "table is not of the given class", message, ...)
end
function Assert.isNilOrClass(actual, expectedClass, message, ...)
    if actual ~= nil then
        Assert.isClass(actual, expectedClass, message, ...)
    end
end
function Assert.isType(object, expectedType, message, ...)
    Assert.assert(type(object) == expectedType, string.format("expected: %s, actual: %s", expectedType, object and type(object) or "nil"), message, ...)
end
function Assert.isNilOrType(object, expectedType, message, ...)
    Assert.assert(object == nil or type(object) == expectedType, string.format("or nil expected: %s, actual: %s", expectedType, object and type(object) or "nil"), message, ...)
end
function Assert.isNil(actual, message, ...)
    Assert.assert(actual ~= nil, "value was not nil", message, ...)
end
function Assert.isNotNil(actual, message, ...)
    Assert.assert(actual ~= nil, "value was nil", message, ...)
end
function Assert.isStringNotNilOrEmpty(actual, message, ...)
    Assert.assert(actual == nil or type(actual) == "string", string.format("object %s was not nil or a string", (tostring(actual))), message, ...)
    Assert.assert(not string.isNilOrWhitespace(actual), string.format("string %q was nil or whitespace", (tostring(actual))), message, ...)
end
function Assert.isInteger(actual, message, ...)
    Assert.assert(type(actual) == "number" and actual == math.floor(actual), string.format("value %s is not an integer", (tostring(actual))), message, ...)
end
function Assert.entityExists(node, message, ...)
    Assert.isNotNil(node, message, ...)
    Assert.isType(node, "number", ...)
    Assert.greaterThan(node, 0, message, ...)
    Assert.isTrue(entityExists(node), message, ...)
end
function Assert.isTrue(actual, message, ...)
    Assert.assert(actual == true, "value was not true", message, ...)
end
function Assert.isFalse(actual, message, ...)
    Assert.assert(actual == false, "value was not false", message, ...)
end
function Assert.throwsError(testFunction, message, ...)
    local status = pcall(testFunction)
    Assert.assert(not status, "function threw no error", message, ...)
end
function Assert.hasKey(actualTable, key, message, ...)
    Assert.isType(actualTable, "table", message)
    Assert.isNotNil(key, message)
    Assert.assert(actualTable[key] ~= nil, string.format("table was missing element with key %s", (tostring(key))), message, ...)
end
function Assert.hasNoKey(actualTable, key, message, ...)
    Assert.isType(actualTable, "table", message)
    Assert.isNotNil(key, message)
    Assert.assert(actualTable[key] ~= nil, string.format("table has element with key %s", (tostring(key))), message, ...)
end
function Assert.fail(message, ...)
    Assert.assert(false, "force failed", message, ...)
end