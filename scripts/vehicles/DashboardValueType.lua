DashboardValueType = {}
local DashboardValueType_mt = Class(DashboardValueType)
function DashboardValueType.new(specName, name, customMt)
    -- upvalues: (copy) DashboardValueType_mt
    local self = setmetatable({}, customMt or DashboardValueType_mt)
    self.specName = specName
    self.name = name
    self.fullName = specName .. "." .. name
    self.pollUpdate = true
    self.valueObject = nil
    self.loadFunction = nil
    self.stateFunction = nil
    self.valueFactor = 1
    self.valueCompare = nil
    self.idleValue = nil
    self.getSourceValue = self.getDefaultValue
    self.getMinValue = self.getDefaultValue
    self.getMaxValue = self.getDefaultValue
    self.getCenterValue = self.getDefaultValue
    self.getInterpolationSpeed = self.getDefaultValue
    return self
end
function DashboardValueType:setXMLKey(xmlKey)
    self.xmlKey = xmlKey
end
function DashboardValueType:loadFromXML(xmlFile, vehicle)
    if self.xmlKey == nil then
        vehicle:loadDashboardsFromXML(xmlFile, xmlFile:getRootName() .. "." .. self.specName .. ".dashboards", self)
    else
        vehicle:loadDashboardsFromXML(xmlFile, self.xmlKey, self)
    end
end
function DashboardValueType:setPollUpdate(pollUpdate)
    self.pollUpdate = pollUpdate
end
function DashboardValueType:setAdditionalFunctions(loadFunction, stateFunction)
    self.loadFunction = loadFunction
    self.stateFunction = stateFunction
end
function DashboardValueType:setValueFactor(valueFactor)
    self.valueFactor = valueFactor
end
function DashboardValueType:setValueCompare(...)
    self.valueCompare = {}
    local i = 1
    for i = i, select("#", ...) do
        self.valueCompare[select(i, ...)] = true
    end
end
function DashboardValueType:setIdleValue(idleValue)
    self.idleValue = idleValue
end
function DashboardValueType:setValue(object, func)
    self.valueObject = object
    self:setFunction("getSourceValue", object, func)
end
function DashboardValueType:setCenter(centerFunc)
    self:setFunction("getCenterValue", self.valueObject, centerFunc)
end
function DashboardValueType:setRange(min, max)
    self:setFunction("getMinValue", self.valueObject, min)
    self:setFunction("getMaxValue", self.valueObject, max)
end
function DashboardValueType:setInterpolationSpeed(interpolationSpeed)
    self:setFunction("getInterpolationSpeed", self.valueObject, interpolationSpeed)
end
function DashboardValueType:getValue(dashboard)
    local value = self:getSourceValue(dashboard)
    if self.valueCompare ~= nil then
    end
    local isNumber = type(value) == "number"
    local min = nil
    local max = nil
    local center = nil
    if isNumber then
        if self.valueFactor ~= nil then
        end
        min = self:getMinValue(dashboard)
        max = self:getMaxValue(dashboard)
        center = self:getCenterValue(dashboard)
    end
    return value, min, max, center, isNumber
end
function DashboardValueType:setFunction(funcName, object, value)
    local func = nil
    if type(value) == "number" or type(value) == "boolean" then
        func = function(_self)
            -- upvalues: (copy) value
            return value
        end
    elseif type(value) == "function" then
        func = function(_, dashboard)
            -- upvalues: (copy) value, (copy) object
            return value(object, dashboard)
        end
    elseif type(value) == "string" then
        if type(object[value]) ~= "number" then
            if type(object[value]) ~= "boolean" then
                func = type(object[value]) == "function" and function(_, dashboard)
                    -- upvalues: (copy) object, (copy) value
                    return object[value](object, dashboard)
                end or func
                goto l4
            end
        end
        func = function(_self)
            -- upvalues: (copy) object, (copy) value
            return object[value]
        end
    end
    ::l4::
    if func ~= nil then
        self[funcName] = func
    end
end
function DashboardValueType:getDefaultValue()
    return nil
end