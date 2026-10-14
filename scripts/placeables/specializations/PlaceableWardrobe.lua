PlaceableWardrobe = {}
source("dataS/scripts/placeables/specializations/activatables/WardrobeActivatable.lua")
function PlaceableWardrobe.prerequisitesPresent(specializations)
    return true
end
function PlaceableWardrobe.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "wardrobeTriggerCallback", PlaceableWardrobe.wardrobeTriggerCallback)
end
function PlaceableWardrobe.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWardrobe)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWardrobe)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableWardrobe)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableWardrobe)
end
function PlaceableWardrobe.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Wardrobe")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".wardrobe#triggerNode", "Wardrobe trigger node for player")
    schema:register(XMLValueType.BOOL, basePath .. ".wardrobe#isFreeForAll", "Allow any farm not just the owner to access the wardrobe", "false if owned by a specific farm, true otherwise")
    schema:setXMLSpecializationType()
end
function PlaceableWardrobe.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Wardrobe")
    schema:register(XMLValueType.BOOL, basePath .. "#isFreeForAll", "Allow any farm not just the owner to access the wardrobe")
    schema:setXMLSpecializationType()
end
function PlaceableWardrobe:onLoad(_)
    local spec = self.spec_wardrobe
    spec.activatable = WardrobeActivatable.new(self)
    spec.wardrobeTrigger = self.xmlFile:getValue("placeable.wardrobe#triggerNode", nil, self.components, self.i3dMappings)
    if spec.wardrobeTrigger ~= nil then
        if not CollisionFlag.getHasMaskFlagSet(spec.wardrobeTrigger, CollisionFlag.PLAYER) then
            Logging.warning("%s wardrobe trigger \'%s\' does not have \'TRIGGER_PLAYER\' bit (%s) set", self.configFileName, "placeable.wardrobe#triggerNode", CollisionFlag.getBit(CollisionFlag.PLAYER))
        end
        addTrigger(spec.wardrobeTrigger, "wardrobeTriggerCallback", self)
    end
    spec.isFreeForAll = self.xmlFile:getValue("placeable.wardrobe#isFreeForAll", false)
end
function PlaceableWardrobe:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_wardrobe
    spec.isFreeForAll = xmlFile:getValue(key .. "#isFreeForAll") or spec.isFreeForAll
end
function PlaceableWardrobe:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#isFreeForAll", self.spec_wardrobe.isFreeForAll)
end
function PlaceableWardrobe:onDelete()
    local spec = self.spec_wardrobe
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    if spec.wardrobeTrigger ~= nil then
        removeTrigger(spec.wardrobeTrigger)
    end
end
function PlaceableWardrobe:onReadStream(streamId, _)
    self.spec_wardrobe.isFreeForAll = streamReadBool(streamId)
end
function PlaceableWardrobe:onWriteStream(streamId, _)
    streamWriteBool(streamId, self.spec_wardrobe.isFreeForAll)
end
function PlaceableWardrobe:wardrobeTriggerCallback(_, otherActorId, onEnter, onLeave, _, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
        local spec = self.spec_wardrobe
        if spec.isFreeForAll or self:getOwnerFarmId() == g_localPlayer.farmId then
            if onEnter then
                g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
                return
            end
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end