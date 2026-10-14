ListenerList = {}
local ListenerList_mt = Class(ListenerList)
function ListenerList.new(ignoreFirstArgument)
    -- upvalues: (copy) ListenerList_mt
    local self = setmetatable({}, ListenerList_mt)
    self.listeners = {}
    self.ignoreFirstArgument = ignoreFirstArgument == true
    return self
end
function ListenerList:registerListener(listenerFunction, targetObject)
    local listener = TargetedFunction.resolveListener(listenerFunction, targetObject)
    table.insert(self.listeners, listener)
end
function ListenerList:invoke(targetObject, ...)
    if self.ignoreFirstArgument then
        for _, listener in ipairs(self.listeners) do
            listener:invoke(...)
        end
    else
        for _, listener in ipairs(self.listeners) do
            listener:invoke(targetObject, ...)
        end
    end
end
function ListenerList_mt.__call(instance, ...)
    return instance:invoke(...)
end