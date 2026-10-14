ColorTest = {}
function ColorTest.test_constructor()
    Assert.throwsError(function()
        Color.new({}, 0, 0, 0)
    end, "Red channel accepted invalid type!")
    Assert.throwsError(function()
        Color.new(0, {}, 0, 0)
    end, "Green channel accepted invalid type!")
    Assert.throwsError(function()
        Color.new(0, 0, {}, 0)
    end, "Blue channel accepted invalid type!")
    Assert.throwsError(function()
        Color.new(0, 0, 0, {})
    end, "Alpha channel accepted invalid type!")
    Assert.throwsError(function()
        Color.new(-1, 0, 0, 0)
    end, "Red channel accepted out of range value!")
    Assert.throwsError(function()
        Color.new(2, 0, 0, 0)
    end, "Red channel accepted out of range value!")
    Assert.throwsError(function()
        Color.new(0, -1, 0, 0)
    end, "Green channel accepted out of range value!")
    Assert.throwsError(function()
        Color.new(0, 2, 0, 0)
    end, "Green channel accepted out of range value!")
    Assert.throwsError(function()
        Color.new(0, 0, -1, 0)
    end, "Blue channel accepted out of range value!")
    Assert.throwsError(function()
        Color.new(0, 0, 2, 0)
    end, "Blue channel accepted out of range value!")
    Assert.throwsError(function()
        Color.new(0, 0, 0, -1)
    end, "Alpha channel accepted out of range value!")
    Assert.throwsError(function()
        Color.new(0, 0, 0, 2)
    end, "Alpha channel accepted out of range value!")
end
function ColorTest.test_copy()
    for presetName, preset in pairs(Color.PRESETS) do
        local colorCopy = preset:copy()
        ColorTest.assertColorMatch(colorCopy, preset)
        Assert.areNotEqual(tostring(colorCopy), tostring(preset), "Color was not copied, but rather returned as-is!")
    end
end
function ColorTest.test_presetNames()
    for presetName, preset in pairs(Color.PRESETS) do
        Assert.areEqual(preset, Color.fromPresetName(presetName), "Preset with name %s could not be found using fromPresetName!", presetName)
        Assert.areEqual(preset, Color.fromPresetName(string.lower(presetName)), "Preset with name %s could not be found using fromPresetName!", presetName)
    end
end
function ColorTest.test_packedValue()
    local testPackedValue = Color.fromPackedValue(4294965488):toPackedValue()
    Assert.areEqual(testPackedValue, 4294965488, "Unpacked and packed values do not match!")
    for presetName, preset in pairs(Color.PRESETS) do
        local presetPackedValue = preset:toPackedValue()
        local presetCopy = Color.fromPackedValue(presetPackedValue)
        Assert.areEqual(presetCopy:toPackedValue(), presetPackedValue, "Unpacked and packed values do not match on preset %s!", presetName)
    end
end
function ColorTest.test_hex()
    for presetName, preset in pairs(Color.PRESETS) do
        local presetHex = preset:toHex()
        local testColor = Color.fromHex(presetHex)
        ColorTest.assertColorMatch(testColor, preset)
    end
end
function ColorTest.test_vector4()
    for presetName, preset in pairs(Color.PRESETS) do
        local colorVector4 = preset:toVector4()
        local testColor = Color.fromVector(colorVector4)
        ColorTest.assertColorMatch(testColor, preset)
        local r, g, b, a = testColor:unpack()
        Assert.areEqual(r, preset.r, "Red channel mismatch!")
        Assert.areEqual(g, preset.g, "Green channel mismatch!")
        Assert.areEqual(b, preset.b, "Blue channel mismatch!")
        Assert.areEqual(a, preset.a, "Alpha channel mismatch!")
    end
end
function ColorTest.test_RGBA()
    for presetName, preset in pairs(Color.PRESETS) do
        local vectorRGBA = preset:toVectorRGBA()
        local r, g, b, a = preset:unpackRGBA()
        local testColor = Color.fromVectorRGBA(vectorRGBA)
        ColorTest.assertColorMatch(testColor, preset)
        Assert.areEqual(r, vectorRGBA[1], "Red channel mismatch!")
        Assert.areEqual(g, vectorRGBA[2], "Green channel mismatch!")
        Assert.areEqual(b, vectorRGBA[3], "Blue channel mismatch!")
        Assert.areEqual(a, vectorRGBA[4], "Alpha channel mismatch!")
    end
end
function ColorTest.test_parseFromString()
    for presetName, preset in pairs(Color.PRESETS) do
        local parsedColor = Color.parseFromString(string.format("%f %f %f %f", preset:unpack()))
        Assert.areRoughlyEqual(parsedColor.r, preset.r)
        Assert.areRoughlyEqual(parsedColor.g, preset.g)
        Assert.areRoughlyEqual(parsedColor.b, preset.b)
        Assert.areRoughlyEqual(parsedColor.a, preset.a)
        local parsedColor = Color.parseFromString("#" .. preset:toHex())
        Assert.areRoughlyEqual(parsedColor.r, preset.r)
        Assert.areRoughlyEqual(parsedColor.g, preset.g)
        Assert.areRoughlyEqual(parsedColor.b, preset.b)
        Assert.areRoughlyEqual(parsedColor.a, preset.a)
    end
    Assert.isNil(Color.parseFromString("0 0"))
    Assert.throwsError(function()
        Color.parseFromString("1.1 0 0")
    end)
    Assert.throwsError(function()
        Color.parseFromString("1 1 1 -0.1")
    end)
end
function ColorTest.test_indexing()
    local testColor = Color.new(0.2, 0.6, 0.1, 1)
    Assert.areEqual(testColor[1], 0.2, "Red channel mismatch!")
    Assert.areEqual(testColor[2], 0.6, "Green channel mismatch!")
    Assert.areEqual(testColor[3], 0.1, "Blue channel mismatch!")
    Assert.areEqual(testColor[4], 1, "Alpha channel mismatch!")
end
function ColorTest.test_swizzling()
    local testColor = Color.new(0.2, 0.6, 0.1, 1)
    local allRed = testColor.rrr
    Assert.areEqual(allRed[1], testColor.r, "Red channel mismatch!")
    Assert.areEqual(allRed[2], testColor.r, "Red channel mismatch!")
    Assert.areEqual(allRed[3], testColor.r, "Red channel mismatch!")
    local allGreen = testColor.ggg
    Assert.areEqual(allGreen[1], testColor.g, "Green channel mismatch!")
    Assert.areEqual(allGreen[2], testColor.g, "Green channel mismatch!")
    Assert.areEqual(allGreen[3], testColor.g, "Green channel mismatch!")
    local allBlue = testColor.bbb
    Assert.areEqual(allBlue[1], testColor.b, "Blue channel mismatch!")
    Assert.areEqual(allBlue[2], testColor.b, "Blue channel mismatch!")
    Assert.areEqual(allBlue[3], testColor.b, "Blue channel mismatch!")
    local allAlpha = testColor.aaa
    Assert.areEqual(allAlpha[1], testColor.a, "Alpha channel mismatch!")
    Assert.areEqual(allAlpha[2], testColor.a, "Alpha channel mismatch!")
    Assert.areEqual(allAlpha[3], testColor.a, "Alpha channel mismatch!")
    local colorVector4 = testColor:toVector4()
    ColorTest.assertColorVectorVectorMatch(colorVector4, testColor.rgba)
end
function ColorTest.test_multiplication()
    local testColor = Color.new(0.5, 0.5, 0, 1)
    Assert.throwsError(function()
        -- upvalues: (copy) testColor
        local _ = testColor * {}
    end, "Invalid color multiplication threw no error!")
    Assert.throwsError(function()
        -- upvalues: (copy) testColor
        local _ = {} * testColor
    end, "Invalid color multiplication threw no error!")
    Assert.throwsError(function()
        -- upvalues: (copy) testColor
        local _ = testColor * ""
    end, "Invalid color multiplication threw no error!")
    Assert.throwsError(function()
        -- upvalues: (copy) testColor
        local _ = "" * testColor
    end, "Invalid color multiplication threw no error!")
    Assert.throwsError(function()
        -- upvalues: (copy) testColor
        local _ = testColor * nil
    end, "Invalid color multiplication threw no error!")
    Assert.throwsError(function()
        -- upvalues: (copy) testColor
        local _ = nil * testColor
    end, "Invalid color multiplication threw no error!")
    for presetName, preset in pairs(Color.PRESETS) do
        local vectorValue = {
            0.5,
            0.2,
            0.7,
            1
        }
        ColorTest.assertColorRGBAMatch(preset * 0.75, preset.r * 0.75, preset.g * 0.75, preset.b * 0.75, preset.a * 0.75)
        ColorTest.assertColorRGBAMatch(preset * vectorValue, preset.r * vectorValue[1], preset.g * vectorValue[2], preset.b * vectorValue[3], preset.a * vectorValue[4])
        ColorTest.assertColorRGBAMatch(0.75 * preset, preset.r * 0.75, preset.g * 0.75, preset.b * 0.75, preset.a * 0.75)
        ColorTest.assertColorRGBAMatch(vectorValue * preset, preset.r * vectorValue[1], preset.g * vectorValue[2], preset.b * vectorValue[3], preset.a * vectorValue[4])
    end
end
function ColorTest.assertColorMatch(actual, expected)
    Assert.isNotNil(actual, "Color was nil!")
    Assert.areRoughlyEqual(actual.r, expected.r, nil, "Red channel mismatch!")
    Assert.areRoughlyEqual(actual.g, expected.g, nil, "Green channel mismatch!")
    Assert.areRoughlyEqual(actual.b, expected.b, nil, "Blue channel mismatch!")
    Assert.areRoughlyEqual(actual.a, expected.a, nil, "Alpha channel mismatch!")
end
function ColorTest.assertColorVectorVectorMatch(actualVector, expectedVector)
    Assert.isNotNil(actualVector, "Color vector was nil!")
    Assert.areRoughlyEqual(actualVector[1], expectedVector[1], nil, "Red channel mismatch!")
    Assert.areRoughlyEqual(actualVector[2], expectedVector[2], nil, "Green channel mismatch!")
    Assert.areRoughlyEqual(actualVector[3], expectedVector[3], nil, "Blue channel mismatch!")
    Assert.areRoughlyEqual(actualVector[4], expectedVector[4], nil, "Alpha channel mismatch!")
end
function ColorTest.assertColorVectorMatch(actual, expectedVector)
    Assert.isNotNil(actual, "Color was nil!")
    Assert.areRoughlyEqual(actual.r, expectedVector[1], nil, "Red channel mismatch!")
    Assert.areRoughlyEqual(actual.g, expectedVector[2], nil, "Green channel mismatch!")
    Assert.areRoughlyEqual(actual.b, expectedVector[3], nil, "Blue channel mismatch!")
    Assert.areRoughlyEqual(actual.a, expectedVector[4], nil, "Alpha channel mismatch!")
end
function ColorTest.assertColorRGBAMatch(actual, expectedR, expectedG, expectedB, expectedA)
    Assert.isNotNil(actual, "Color was nil!")
    Assert.areRoughlyEqual(actual.r, expectedR, nil, "Red channel mismatch!")
    Assert.areRoughlyEqual(actual.g, expectedG, nil, "Green channel mismatch!")
    Assert.areRoughlyEqual(actual.b, expectedB, nil, "Blue channel mismatch!")
    Assert.areRoughlyEqual(actual.a, expectedA, nil, "Alpha channel mismatch!")
end