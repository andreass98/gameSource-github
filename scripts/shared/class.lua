function Class(...)
    local numParameters = select("#", ...)
    local members = select(1, ...)
    local baseClass = nil
    if numParameters > 1 then
        baseClass = select(2, ...)
        if baseClass == nil then
            printError("Error: Given base class is not defined")
            printCallstack()
        end
    end
    local members = members or {}
    local mt = {
        ["__metatable"] = members,
        ["__index"] = members
    }
    if baseClass ~= nil then
        setmetatable(members, {
            ["__index"] = baseClass
        })
    end
    function members:class()
        -- upvalues: (ref) members
        return members
    end
    function members:superClass()
        -- upvalues: (ref) baseClass
        return baseClass
    end
    function members.isa(_, other)
        -- upvalues: (ref) members
        local curClass = members
        while curClass ~= nil do
            if curClass == other then
                return true
            end
            curClass = curClass:superClass()
        end
        return false
    end
    members.new = members.new or function(_, init)
        -- upvalues: (copy) mt
        return setmetatable(init or {}, mt)
    end
    members.copy = members.copy or function(obj, ...)
        local newobj = obj.new(...)
        for n, v in pairs(obj) do
            newobj[n] = v
        end
        return newobj
    end
    return mt
end