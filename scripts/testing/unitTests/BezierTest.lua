BezierTest = {}
function BezierTest.test_constructor()
    Assert.throwsError(BezierCurve.new, "Calling constructor with no arguments threw no error.")
    Assert.throwsError(function()
        BezierCurve.new(nil, 0, 0, 0)
    end, "X 1 was allowed to be invalid")
    Assert.throwsError(function()
        BezierCurve.new(0, nil, 0, 0)
    end, "Y 1 was allowed to be invalid")
    Assert.throwsError(function()
        BezierCurve.new(0, 0, nil, 0)
    end, "X 2 was allowed to be invalid")
    Assert.throwsError(function()
        BezierCurve.new(0, 0, 0, nil)
    end, "Y 2 was allowed to be invalid")
end
function BezierTest.test_setters()
    local curve = BezierCurve.new(0.25, 0, 0.75, 1)
    Assert.throwsError(function()
        -- upvalues: (copy) curve
        curve:setPositionX1(nil)
    end, "X 1 was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (copy) curve
        curve:setPositionY1(nil)
    end, "Y 1 was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (copy) curve
        curve:setPositionX2(nil)
    end, "X 2 was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (copy) curve
        curve:setPositionY2(nil)
    end, "Y 2 was allowed to be invalid")
end
function BezierTest.test_solvers()
    local curve = BezierCurve.new(0.25, 0, 0.75, 1)
    Assert.throwsError(function()
        -- upvalues: (ref) curve
        curve:sampleY(nil)
    end, "t was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (ref) curve
        curve:sampleX(nil)
    end, "t was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (ref) curve
        curve:sampleDerivativeX(nil)
    end, "t was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (ref) curve
        curve:solveX(nil)
    end, "t was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (ref) curve
        curve:solveX(0.5, {})
    end, "epsilon was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (ref) curve
        curve:solve(nil)
    end, "t was allowed to be invalid")
    Assert.throwsError(function()
        -- upvalues: (ref) curve
        curve:solve(0.5, {})
    end, "epsilon was allowed to be invalid")
    local curveIndex = 0
    for curveIndex = curveIndex, 100 do
        curve = BezierCurve.new(curveIndex / 100, 0, 1 - curveIndex / 100, 1)
        local sampleIndex = 0
        for sampleIndex = sampleIndex, 100 do
            local value = curve:solve(sampleIndex / 100)
            Assert.lessThanOrEqualTo(value, 1, "Value was greater than 1")
            Assert.greaterThanOrEqualTo(value, 0, "Value was less than 0")
        end
    end
end