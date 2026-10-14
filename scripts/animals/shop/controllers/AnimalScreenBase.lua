AnimalScreenBase = {}
AnimalScreenBase.ACTION_TYPE_NONE = 0
AnimalScreenBase.ACTION_TYPE_SOURCE = 1
AnimalScreenBase.ACTION_TYPE_TARGET = 2
local AnimalScreenBase_mt = Class(AnimalScreenBase)
function AnimalScreenBase.new(customMt)
    -- upvalues: (copy) AnimalScreenBase_mt
    local self = setmetatable({}, customMt or AnimalScreenBase_mt)
    self.sourceItems = {}
    self.targetItems = {}
    self.sourceActionText = ""
    self.targetActionText = ""
    self.sourceTitle = ""
    self.targetTitle = ""
    return self
end
function AnimalScreenBase:reset()
    g_messageCenter:unsubscribe(AnimalClusterUpdateEvent, self)
end
function AnimalScreenBase:init()
    g_messageCenter:subscribe(AnimalClusterUpdateEvent, self.onAnimalsChanged, self)
    self:initItems()
end
function AnimalScreenBase:initItems()
    self:initSourceItems()
    self:initTargetItems()
end
function AnimalScreenBase:initSourceItems() end
function AnimalScreenBase:initTargetItems() end
function AnimalScreenBase:getSourceItems(animalTypeIndex)
    return self.sourceItems[animalTypeIndex] or {}
end
function AnimalScreenBase:getSourceData(id) end
function AnimalScreenBase:getSourceAnimalTypes() end
function AnimalScreenBase:getTargetItems()
    table.sort(self.targetItems, function(a, b)
        if a.cluster.subTypeIndex == b.cluster.subTypeIndex then
            return a.cluster.age < b.cluster.age
        else
            return a.cluster.subTypeIndex < b.cluster.subTypeIndex
        end
    end)
    return self.targetItems
end
function AnimalScreenBase:getTargetData() end
function AnimalScreenBase:setAnimalsChangedCallback(callback, target)
    function self.animalsChangedCallback()
        -- upvalues: (copy) callback, (copy) target
        callback(target)
    end
end
function AnimalScreenBase:setActionTypeCallback(callback, target)
    function self.actionTypeCallback(state)
        -- upvalues: (copy) callback, (copy) target
        callback(target, state)
    end
end
function AnimalScreenBase:setErrorCallback(callback, target)
    function self.errorCallback(text)
        -- upvalues: (copy) callback, (copy) target
        callback(target, text)
    end
end
function AnimalScreenBase:setSourceActionFinishedCallback(callback, target)
    function self.sourceActionFinished(isWarning, text)
        -- upvalues: (copy) callback, (copy) target
        callback(target, isWarning, text)
    end
end
function AnimalScreenBase:setTargetActionFinishedCallback(callback, target)
    function self.targetActionFinished(isWarning, text)
        -- upvalues: (copy) callback, (copy) target
        callback(target, isWarning, text)
    end
end
function AnimalScreenBase:onAnimalsChanged() end
function AnimalScreenBase:onAnimalBuyError(errorCode) end
function AnimalScreenBase:getMaxNumAnimals()
    return 250
end
function AnimalScreenBase:getSourceActionText()
    return self.sourceActionText
end
function AnimalScreenBase:getTargetActionText()
    return self.targetActionText
end
function AnimalScreenBase:getSourceName()
    return self.sourceTitle
end
function AnimalScreenBase:getTargetName()
    return self.targetTitle
end
function AnimalScreenBase:getSourceMaxNumAnimals(animalTypeIndex, itemIndex)
    return 0
end
function AnimalScreenBase:getTargetMaxNumAnimals(itemIndex)
    return 0
end
function AnimalScreenBase:setCurrentHusbandry(animalTypeIndex, husbandryIndex) end