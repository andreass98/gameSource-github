RTKStation = {}
function RTKStation.prerequisitesPresent(specializations)
    return true
end
function RTKStation.registerFunctions(placeableType) end
function RTKStation.registerOverwrittenFunctions(placeableType) end
function RTKStation.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", RTKStation)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", RTKStation)
end
function RTKStation.registerXMLPaths(schema, basePath) end
function RTKStation:onFinalizePlacement(_)
    if g_precisionFarming ~= nil then
        g_precisionFarming.aiExtension:registerRTKStation(self)
    end
end
function RTKStation:onDelete()
    if g_precisionFarming ~= nil then
        g_precisionFarming.aiExtension:unregisterRTKStation(self)
    end
end