SpecializationUtil = {}
function SpecializationUtil.raiseAsyncEvent(object, eventName, ...)
    if object.eventListeners[eventName] == nil then
        printError(string.format("Error: Event %q is not registered for type %q!", eventName, object.type and object.type.name or "<unknown>"))
        printCallstack()
    else
        local typeName = { ... }
        for _, spec in ipairs(object.eventListeners[eventName]) do
            local spec
            object:addAsyncTask(function()
                -- upvalues: (copy) spec, (copy) eventName, (copy) object, (copy) typeName
                spec[eventName](object, unpack(typeName))
            end, spec.className, false)
        end
    end
end
function SpecializationUtil.raiseEvent(object, eventName, ...)
    if object.eventListeners[eventName] == nil then
        printError(string.format("Error: Event %q is not registered for type %q!", eventName, object.type and object.type.name or "<unknown>"))
        printCallstack()
    else
        for _, spec in ipairs(object.eventListeners[eventName]) do
            spec[eventName](object, ...)
        end
    end
end
function SpecializationUtil.registerFunction(objectType, funcName, func)
    if string.isNilOrWhitespace(funcName) then
        Logging.error("Given function name is is \'nil\' or empty!")
        printCallstack()
        return
    elseif func == nil then
        Logging.error("Given reference for Function \'%s\' is \'nil\'!", funcName)
        printCallstack()
        return
    elseif objectType.functions[funcName] == nil then
        if objectType.events[funcName] == nil then
            objectType.functions[funcName] = func
        else
            Logging.error("Function \'%s\' already registered as event in type \'%s\'!", funcName, objectType.name)
            printCallstack()
        end
    else
        Logging.error("Function \'%s\' already registered as function in type \'%s\'!", funcName, objectType.name)
        printCallstack()
        return
    end
end
function SpecializationUtil.registerOverwrittenFunction(objectType, funcName, func)
    if string.isNilOrWhitespace(funcName) then
        Logging.error("Given function name is is \'nil\' or empty!")
        printCallstack()
        return
    elseif func == nil then
        Logging.error("Given reference for OverwrittenFunction \'%s\' is \'nil\'!", funcName)
        printCallstack()
    elseif objectType.functions[funcName] ~= nil then
        objectType.functions[funcName] = Utils.overwrittenFunction(objectType.functions[funcName], func)
    end
end
function SpecializationUtil.registerEvent(objectType, eventName)
    if string.isNilOrWhitespace(eventName) then
        Logging.error("Given name for event is \'nil\' or empty!")
        printCallstack()
        return
    elseif objectType.functions[eventName] == nil then
        if objectType.events[eventName] == nil then
            objectType.events[eventName] = eventName
            objectType.eventListeners[eventName] = {}
        else
            Logging.error("Event \'%s\' already registered as event in type \'%s\'!", eventName, objectType.name)
            printCallstack()
        end
    else
        Logging.error("Event \'%s\' already registered as function in type \'%s\'!", eventName, objectType.name)
        printCallstack()
        return
    end
end
function SpecializationUtil.registerEventListener(objectType, eventName, specClass)
    if string.isNilOrWhitespace(eventName) then
        Logging.error("Given event name is is \'nil\' or empty!")
        printCallstack()
        return
    end
    if objectType.eventListeners == nil then
        Logging.error("Invalid type for specialization \'%s\'!", specClass.className)
        printCallstack()
        return
    end
    if specClass[eventName] == nil then
        Logging.error("Event listener function \'%s\' not defined in specialization \'%s\'!", eventName, className)
        printCallstack()
        return
    end
    if objectType.eventListeners[eventName] == nil then
        return
    end
    local found = false
    for _, registeredSpec in pairs(objectType.eventListeners[eventName]) do
        if registeredSpec == specClass then
            found = true
            break
        end
    end
    if found then
        Logging.error("Event listener for \'%s\' already registered in specialization \'%s\'!", eventName, className)
        printCallstack()
    else
        table.insert(objectType.eventListeners[eventName], specClass)
    end
end
function SpecializationUtil.removeEventListener(object, eventName, specClass)
    local listeners = object.eventListeners[eventName]
    if listeners ~= nil then
        local i = #listeners
        for i = i, 1, -1 do
            if listeners[i] == specClass then
                table.remove(listeners, i)
            end
        end
    end
end
function SpecializationUtil.hasSpecialization(spec, specializations)
    for _, v in pairs(specializations) do
        if v == spec then
            return true
        end
    end
    return false
end
function SpecializationUtil.initSpecializationsIntoTypeClass(_, typeDef, target)
    target.type = typeDef
    target.typeName = typeDef.name
    target.specializations = typeDef.specializations
    target.specializationNames = typeDef.specializationNames
    target.specializationsByName = typeDef.specializationsByName
    target.eventListeners = table.clone(typeDef.eventListeners, 2)
    return typeDef
end
function SpecializationUtil.copyTypeFunctionsInto(typeDef, target)
    for funcName, func in pairs(typeDef.functions) do
        target[funcName] = func
    end
end
function SpecializationUtil.createSpecializationEnvironments(target, failureCallback)
    local i = 1
    for i = i, #target.specializations do
        local specEntryName = "spec_" .. target.specializationNames[i]
        if target[specEntryName] == nil then
            local stopLoading = setmetatable({}, {
                ["__index"] = target
            })
            stopLoading.actionEvents = {}
            target[specEntryName] = stopLoading
        elseif failureCallback(target.specializationNames[i], specEntryName) then
            return false
        end
    end
    return true
end
function SpecializationUtil.createLoadingTask(typeClass, target)
    local task = {
        ["target"] = target
    }
    table.insert(typeClass.loadingTasks, task)
    return task
end
function SpecializationUtil.finishLoadingTask(typeClass, task)
    if not table.removeElement(typeClass.loadingTasks, task) then
        Logging.warning("Loading task was marked as finished, but was never added in the first place. Ensure that every finishLoadingTask call uses a task given from the createLoadingTask function.")
    end
    if typeClass.readyForFinishLoading and #typeClass.loadingTasks == 0 then
        typeClass:onFinishedLoading()
    end
end
function SpecializationUtil.setLoadingStep(typeClass, loadingStep)
    if SpecializationUtil.getIsValidLoadingStep(loadingStep) then
        typeClass.loadingStep = loadingStep
    else
        printCallstack()
        Logging.error("Invalid loading step \'%s\'!", loadingStep)
    end
end
function SpecializationUtil.getIsValidLoadingStep(loadingStep)
    for _, value in pairs(SpecializationLoadStep) do
        if value == loadingStep then
            return true
        end
    end
    return false
end
function SpecializationUtil.getLoadingStepName(loadingStep)
    for name, value in pairs(SpecializationLoadStep) do
        if value == loadingStep then
            return name
        end
    end
    return nil
end