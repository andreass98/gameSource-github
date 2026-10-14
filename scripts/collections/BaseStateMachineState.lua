BaseStateMachineState = {}
local BaseStateMachineState_mt = Class(BaseStateMachineState)
function BaseStateMachineState.registerXMLPaths(xmlSchema, baseKey)
    xmlSchema:register(XMLValueType.FLOAT, baseKey .. "#debugPositionX", "The x position of the state when debug-drawn, in screen-space", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, baseKey .. "#debugPositionY", "The y position of the state when debug-drawn, in screen-space", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, baseKey .. "#debugWidth", "The width of the state when debug-drawn, in screen-space", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, baseKey .. "#debugHeight", "The height of the state when debug-drawn, in screen-space", nil, false)
end
function BaseStateMachineState.new(stateMachine, custom_mt)
    -- upvalues: (copy) BaseStateMachineState_mt
    local self = setmetatable({}, custom_mt or BaseStateMachineState_mt)
    self.stateMachine = stateMachine
    self.transitions = {}
    self.debugPositionX = nil
    self.debugPositionY = nil
    self.debugWidth = nil
    self.debugHeight = nil
    return self
end
function BaseStateMachineState:loadDebugInfoFromXMLFile(xmlFile, baseKey)
    self.debugPositionX = xmlFile:getValue(baseKey .. "#debugPositionX")
    self.debugPositionY = xmlFile:getValue(baseKey .. "#debugPositionY")
    self.debugWidth = xmlFile:getValue(baseKey .. "#debugWidth")
    self.debugHeight = xmlFile:getValue(baseKey .. "#debugHeight")
end
function BaseStateMachineState:trySwitchToValidTransition()
    for state, binding in pairs(self.transitions) do
        if binding.conditionFunction(binding.context) then
            self.stateMachine:changeState(state)
            return state
        end
    end
    return nil
end
function BaseStateMachineState:createTransitions() end
function BaseStateMachineState:addTransition(conditionFunction, targetState, contextObject)
    self.transitions[targetState] = {
        ["context"] = contextObject or targetState,
        ["conditionFunction"] = conditionFunction
    }
    return self.transitions[targetState]
end
function BaseStateMachineState:calculateIfShouldBeForced()
    return false
end
function BaseStateMachineState:calculateIfValidEntryState()
    return false
end
function BaseStateMachineState:onStateEntered(previousState) end
function BaseStateMachineState:onStateExited(nextState) end
function BaseStateMachineState:updateAsCurrent(_)
    if not self.stateMachine:getIsPassive() then
        self:trySwitchToValidTransition()
    end
end
function BaseStateMachineState:updateAsInactive(dt) end
function BaseStateMachineState:caclulateDebugScreenBounds(x, y, width, height)
    if self.debugPositionX == nil or (self.debugPositionY == nil or (self.debugWidth == nil or self.debugHeight == nil)) then
        return nil, nil, nil, nil
    else
        return x + self.debugPositionX * width, y + self.debugPositionY * height, self.debugWidth * width, self.debugHeight * height
    end
end
function BaseStateMachineState:debugDraw(x, y, width, height, _, color)
    local frameX, frameY, frameWidth, frameHeight = self:caclulateDebugScreenBounds(x, y, width, height)
    if frameX == nil then
        return nil, nil, nil, nil
    end
    if color == nil then
        color = self.stateMachine.currentState == self and Color.PRESETS.GREEN or Color.PRESETS.GRAY
    end
    drawFilledRect(frameX, frameY, frameWidth, frameHeight, color:unpack())
    return frameX, frameY, frameWidth, frameHeight
end
function BaseStateMachineState:debugDrawTransitions(x, y, width, height, activatedColor, wouldBeActivatedColor, unactivatedColor)
    local frameX, frameY, frameWidth, frameHeight = self:caclulateDebugScreenBounds(x, y, width, height)
    if frameX ~= nil then
        for targetState, condition in pairs(self.transitions) do
            local targetFrameX, targetFrameY, targetFrameWidth, targetFrameHeight = targetState:caclulateDebugScreenBounds(x, y, width, height)
            if targetFrameX ~= nil then
                local lineStartX
                if condition.conditionFunction(condition.context) then
                    if self.stateMachine.currentState == self then
                        lineStartX = activatedColor or Color.PRESETS.GREEN
                    else
                        lineStartX = wouldBeActivatedColor or Color.PRESETS.GOLD
                    end
                else
                    lineStartX = unactivatedColor or Color.PRESETS.RED
                end
                local lineStartX = frameX + frameWidth / 2
                local lineStartY = frameY + frameHeight / 2
                local lineEndX = targetFrameX + targetFrameWidth / 2
                local lineEndY = targetFrameY + targetFrameHeight / 2
                local lineLength = MathUtil.vector2Length(lineStartX - lineEndX, lineStartY - lineEndY)
                local lineDirectionX = (lineEndX - lineStartX) / lineLength
                local lineDirectionY = (lineEndY - lineStartY) / lineLength
                local lineAngle = math.atan2(lineDirectionY, lineDirectionX)
                local lineCentreX = lineStartX + lineDirectionX * lineLength * 0.5
                local lineCentreY = lineStartY + lineDirectionY * lineLength * 0.5
                local arrowDirectionX = math.cos(lineAngle + 2.0734511513692637)
                local arrowDirectionY = math.sin(lineAngle + 2.0734511513692637)
                drawLine2D(lineCentreX, lineCentreY, lineCentreX + arrowDirectionX * 0.01, lineCentreY + arrowDirectionY * 0.01, 0.001, lineStartX:unpack())
                local arrowDirectionX = math.cos(lineAngle - 2.0734511513692637)
                local arrowDirectionY = math.sin(lineAngle - 2.0734511513692637)
                drawLine2D(lineCentreX, lineCentreY, lineCentreX + arrowDirectionX * 0.01, lineCentreY + arrowDirectionY * 0.01, 0.001, lineStartX:unpack())
                drawLine2D(lineStartX, lineStartY, lineEndX, lineEndY, 0.001, lineStartX:unpack())
            end
        end
    end
end