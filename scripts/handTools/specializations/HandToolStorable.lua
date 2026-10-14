HandToolStorable = {}
function HandToolStorable.registerXMLPaths(xmlSchema)
    xmlSchema:setXMLSpecializationType("HandToolStorable")
    xmlSchema:register(XMLValueType.STRING, "handTool.storable.holderType(?)#type", "The type of holder that can be used", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.storable.holderType(?)#node", "The node used to orient the tool in the holder")
    xmlSchema:setXMLSpecializationType()
end
function HandToolStorable.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "getHolsterNodeByType", HandToolStorable.getHolsterNodeByType)
end
function HandToolStorable.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolStorable)
end
function HandToolStorable.prerequisitesPresent(specializations)
    return true
end
function HandToolStorable:onLoad(xmlFile)
    local spec = self.spec_storable
    spec.holderHolsterNodes = {}
    for _, key in xmlFile:iterator("handTool.storable.holderType") do
        local holderType = xmlFile:getValue(key .. "#type", nil)
        if holderType == nil then
            Logging.xmlError(xmlFile, "HandToolStorable has a holder type with a missing type!")
        else
            spec.holderHolsterNodes[holderType] = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings) or spec.holderHolsterNodes[holderType]
        end
    end
end
function HandToolStorable:getHolsterNodeByType(typeName)
    local spec = self.spec_storable
    if spec.holderHolsterNodes == nil then
        return nil
    else
        return spec.holderHolsterNodes[typeName]
    end
end