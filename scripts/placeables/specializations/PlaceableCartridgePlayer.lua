PlaceableCartridgePlayer = {}
function PlaceableCartridgePlayer.prerequisitesPresent(specializations)
    return true
end
function PlaceableCartridgePlayer.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "cartridgePlayerTriggerCallback", PlaceableCartridgePlayer.cartridgePlayerTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "activatePlayer", PlaceableCartridgePlayer.activatePlayer)
end
function PlaceableCartridgePlayer.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableCartridgePlayer)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableCartridgePlayer)
end
function PlaceableCartridgePlayer.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("CartridgePlayer")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#itemsNode", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#monitorNode", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#monitorLightNode", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#connectorNode", "")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".cartridgePlayer#triggerNode", "")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".cartridgePlayer.sounds", "play")
    schema:setXMLSpecializationType()
end
function PlaceableCartridgePlayer:onLoad(_)
    local spec = self.spec_cartridgePlayer
    spec.itemsNode = self.xmlFile:getValue("placeable.cartridgePlayer#itemsNode", nil, self.components, self.i3dMappings)
    spec.monitorNode = self.xmlFile:getValue("placeable.cartridgePlayer#monitorNode", nil, self.components, self.i3dMappings)
    spec.monitorLightNode = self.xmlFile:getValue("placeable.cartridgePlayer#monitorLightNode", nil, self.components, self.i3dMappings)
    spec.connectorNode = self.xmlFile:getValue("placeable.cartridgePlayer#connectorNode", nil, self.components, self.i3dMappings)
    spec.triggerNode = self.xmlFile:getValue("placeable.cartridgePlayer#triggerNode", nil, self.components, self.i3dMappings)
    if spec.triggerNode ~= nil then
        if not CollisionFlag.getHasMaskFlagSet(spec.triggerNode, CollisionFlag.PLAYER) then
            Logging.error("Missing collision mask bit \'%d\'. Please add this bit to computer trigger node \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(spec.triggerNode))
            return nil
        end
        addTrigger(spec.triggerNode, "cartridgePlayerTriggerCallback", self)
        spec.activatable = PlaceableCartridgePlayerActivatable.new(self)
    end
    spec.currentItem = 0
    if self.isClient then
        spec.samples = {}
        spec.samples.play = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.cartridgePlayer.sounds", "play", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
    end
    return self
end
function PlaceableCartridgePlayer:onDelete()
    local spec = self.spec_cartridgePlayer
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end
    if self.isClient then
        g_soundManager:deleteSamples(spec.samples)
    end
end
function PlaceableCartridgePlayer:cartridgePlayerTriggerCallback(_, otherId, onEnter, onLeave, _)
    if (onEnter or onLeave) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
        local spec = self.spec_cartridgePlayer
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            return
        end
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end
end
function PlaceableCartridgePlayer:activatePlayer()
    local spec = self.spec_cartridgePlayer
    if spec.currentItem ~= 0 then
        link(getChildAt(spec.itemsNode, spec.currentItem - 1), getChildAt(spec.connectorNode, 0))
        setVisibility(spec.monitorLightNode, false)
        setVisibility(getChildAt(spec.monitorNode, spec.currentItem - 1), false)
    end
    local firstVisibleIndex = 0
    local nextVisibleIndex = 0
    local i = 1
    local isVisible = getNumOfChildren(spec.itemsNode)
    for i = i, isVisible do
        if getVisibility(getChildAt(spec.itemsNode, i - 1)) then
            if firstVisibleIndex == 0 then
                firstVisibleIndex = i
            end
            if nextVisibleIndex == 0 and spec.currentItem < i then
                nextVisibleIndex = i
            end
        end
    end
    if nextVisibleIndex == 0 then
        if firstVisibleIndex == 0 then
            if spec.currentItem == 0 then
                g_currentMission.hud:showInGameMessage(g_i18n:getText("ui_gameComputer"), g_i18n:getText("ui_gameComputerNoCartridges"), -1)
            else
                spec.currentItem = 0
            end
        else
            spec.currentItem = firstVisibleIndex
        end
    else
        spec.currentItem = nextVisibleIndex
    end
    if spec.currentItem ~= 0 then
        link(spec.connectorNode, getChildAt(getChildAt(spec.itemsNode, spec.currentItem - 1), 0))
        setVisibility(spec.monitorLightNode, true)
        setVisibility(getChildAt(spec.monitorNode, spec.currentItem - 1), true)
    end
    if spec.currentItem ~= spec.currentItem and self.isClient then
        g_soundManager:playSample(spec.samples.play, 1)
    end
end
PlaceableCartridgePlayerActivatable = {}
local PlaceableCartridgePlayerActivatable_mt = Class(PlaceableCartridgePlayerActivatable)
function PlaceableCartridgePlayerActivatable.new(placeable)
    -- upvalues: (copy) PlaceableCartridgePlayerActivatable_mt
    local self = setmetatable({}, PlaceableCartridgePlayerActivatable_mt)
    self.placeable = placeable
    self.activateText = g_i18n:getText("action_gameComputerChangeCartridge")
    return self
end
function PlaceableCartridgePlayerActivatable:run()
    self.placeable:activatePlayer()
end