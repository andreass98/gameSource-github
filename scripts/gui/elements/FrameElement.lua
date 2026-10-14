FrameElement = {}
local FrameElement_mt = Class(FrameElement, GuiElement)
local function NO_CALLBACK() end
function FrameElement.new(target, customMt)
    -- upvalues: (copy) FrameElement_mt, (copy) NO_CALLBACK
    local self = GuiElement.new(target, customMt or FrameElement_mt)
    self.controlIDs = {}
    self.changeScreenCallback = NO_CALLBACK
    self.toggleCustomInputContextCallback = NO_CALLBACK
    self.playSampleCallback = NO_CALLBACK
    self.hasCustomInputContext = false
    self.time = 0
    self.inputDisableTime = 0
    self.playHoverSoundOnFocus = false
    return self
end
function FrameElement:clone(parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    local ret = FrameElement:superClass().clone(self, parent, includeId, suppressOnCreate, blockFocusHandlingReload)
    ret:exposeControlsAsFields(self.name)
    ret.changeScreenCallback = self.changeScreenCallback
    ret.toggleCustomInputContextCallback = self.toggleCustomInputContextCallback
    ret.playSampleCallback = self.playSampleCallback
    ret.hasCustomInputContext = self.hasCustomInputContext
    return ret
end
function FrameElement:copyAttributes(src)
    FrameElement:superClass().copyAttributes(self, src)
    for k, _ in pairs(src.controlIDs) do
        self.controlIDs[k] = false
    end
end
function FrameElement:delete()
    FrameElement:superClass().delete(self)
    for k, _ in pairs(self.controlIDs) do
        self.controlIDs[k] = nil
        self[k] = nil
    end
end
function FrameElement:getRootElement()
    if #self.elements > 0 then
        return self.elements[1]
    end
    local newRoot = GuiElement.new()
    self:addElement(newRoot)
    return newRoot
end
function FrameElement:exposeControlsAsFields(viewName)
    local allChildren = self:getDescendants()
    for _, element in pairs(allChildren) do
        if element.id and element.id ~= "" then
            local index, varName = GuiElement.extractIndexAndNameFromID(element.id)
            if index then
                if not self[varName] then
                    self[varName] = {}
                end
                self[varName][index] = element
            else
                self[varName] = element
            end
            self.controlIDs[varName] = true
        end
    end
    if self.debugEnabled or g_uiDebugEnabled then
        for _, element in pairs(self.controlIDs) do
            if not element then
                Logging.warning("FrameElement for GUI view \'%s\' could not resolve registered control element ID \'%s\'. Check configuration.", tostring(viewName), (tostring(_)))
            end
        end
    end
end
function FrameElement:disableInputForDuration(duration)
    self.inputDisableTime = math.clamp(duration, 0, 10000)
end
function FrameElement:isInputDisabled()
    return self.inputDisableTime > 0
end
function FrameElement:update(dt)
    FrameElement:superClass().update(self, dt)
    self.time = self.time + dt
    if self.inputDisableTime > 0 then
        self.inputDisableTime = self.inputDisableTime - dt
    end
end
function FrameElement:setChangeScreenCallback(callback)
    -- upvalues: (copy) NO_CALLBACK
    self.changeScreenCallback = callback or NO_CALLBACK
end
function FrameElement:setInputContextCallback(callback)
    -- upvalues: (copy) NO_CALLBACK
    self.toggleCustomInputContextCallback = callback or NO_CALLBACK
end
function FrameElement:setPlaySampleCallback(callback)
    -- upvalues: (copy) NO_CALLBACK
    self.playSampleCallback = callback or NO_CALLBACK
end
function FrameElement:changeScreen(targetScreenClass, returnScreenClass)
    self.changeScreenCallback(self, targetScreenClass, returnScreenClass)
end
function FrameElement:toggleCustomInputContext(isContextActive, contextName)
    if self.hasCustomInputContext and not isContextActive or not self.hasCustomInputContext and isContextActive then
        self.toggleCustomInputContextCallback(isContextActive, contextName)
        self.hasCustomInputContext = isContextActive
    end
end
function FrameElement:playSample(sampleName)
    if not self:getSoundSuppressed() then
        self.playSampleCallback(sampleName)
    end
end