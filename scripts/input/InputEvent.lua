InputEvent = {}
local InputEvent_mt = Class(InputEvent)
function InputEvent.new(actionName, targetObject, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, orderValue)
    -- upvalues: (copy) InputEvent_mt
    local self = setmetatable({}, InputEvent_mt)
    self.actionName = actionName
    self.targetObject = targetObject
    self.callback = callback
    self.triggerDown = triggerDown
    self.triggerUp = triggerUp
    self.triggerAlways = triggerAlways
    self.callbackState = callbackState
    self.orderValue = orderValue
    self.id = self:makeId()
    self.ignoreComboMask = false
    self.isActive = startActive
    self.contextDisplayText = nil
    self.contextDisplayIconName = nil
    self.displayIsVisible = true
    self.displayPriority = GS_PRIO_VERY_LOW
    self.hasFrameTriggered = false
    return self
end
function InputEvent:setIgnoreComboMask(ignoreComboMask)
    self.ignoreComboMask = ignoreComboMask
end
function InputEvent:getIgnoreComboMask()
    return self.ignoreComboMask
end
function InputEvent:notifyInput(binding, isReset)
    local triggerUp = self.triggerUp and binding.isUpFlank
    if triggerUp then
        triggerUp = binding.recievedDownFlankInCurrentContext
    end
    local triggerDown = self.triggerDown and (binding.isDownFlank and not self.triggerAlways)
    if triggerDown then
        triggerDown = not binding.enteredNewContextThisFrame
    end
    local triggerPressed = self.triggerDown and (self.triggerAlways and binding.isPressed)
    if triggerPressed then
        triggerPressed = binding.recievedDownFlankInCurrentContext
    end
    local triggerContinuous = not self.triggerDown
    if triggerContinuous then
        triggerContinuous = self.triggerAlways
    end
    if not self.hasFrameTriggered and (triggerUp or (triggerDown or (triggerPressed or triggerContinuous))) then
        self.hasFrameTriggered = true
        binding:setFrameTriggered(not triggerContinuous)
        self.callback(self.targetObject, self.actionName, binding.inputValue, self.callbackState, binding.isAnalog, binding.isMouse, binding.deviceCategory, binding, isReset)
    end
end
function InputEvent:frameReset()
    self.hasFrameTriggered = false
end
function InputEvent:makeId()
    return string.format("%s|%s|%d", tostring(self.actionName), tostring(self.targetObject), self:getTriggerCode())
end
function InputEvent:getTriggerCode()
    return (self.triggerDown and 1 or 0) + (self.triggerUp and 2 or 0) + (self.triggerAlways and 4 or 0)
end
function InputEvent:initializeDisplayText(inputAction)
    self.contextDisplayText = inputAction.displayNamePositive
end
function InputEvent:toString()
    return string.format("[%s: target=%s, triggerUp=%s, triggerDown=%s, triggerAlways=%s, isActive=%s, isVisible=%s, hasFrameTriggered=%s]", self.actionName, self.targetObject, self.triggerUp, self.triggerDown, self.triggerAlways, self.isActive, self.displayIsVisible, self.hasFrameTriggered)
end
InputEvent_mt.__tostring = InputEvent.toString
InputEvent.NO_EVENT = InputEvent.new("", {}, function() end, false, false, false, false, 0, 0)