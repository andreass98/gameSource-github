Pallet = {}
function Pallet.prerequisitesPresent(specializations)
    return true
end
function Pallet.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Pallet")
    schema:register(XMLValueType.INT, "vehicle.pallet#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet#node", "Root visual pallet node")
    schema:register(XMLValueType.NODE_INDICES, "vehicle.pallet#linkNode", "Link node for externally loaded visual pallet (can be multiple link nodes separated by space)")
    schema:register(XMLValueType.FILENAME, "vehicle.pallet#filename", "Path to visual pallet i3d file to load", "$data/objects/pallets/shared/euroPallet/euroPallet.i3d")
    schema:register(XMLValueType.FILENAME, "vehicle.pallet.texture(?)#diffuse", "Path to the diffuse texture to use (if multiple are defined it will switch between them randomly)")
    schema:register(XMLValueType.INT, "vehicle.pallet.content(?)#fillUnitIndex", "Fill unit index for this content", "pallet#fillUnitIndex")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.content(?).object(?)#node", "Object node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.content(?).object(?)#tensionBeltNode", "Object used for tension belt calculations")
    schema:register(XMLValueType.BOOL, "vehicle.pallet.content(?).object(?)#useAsTensionBeltMesh", "Flag for toggling object node being used as tension belt node", true)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?)#startNode", "Start node of the strap")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?)#endNode", "End node of the strap")
    schema:register(XMLValueType.STRING, "vehicle.pallet.straps.strap(?)#tensionBeltType", "Type of the tension belt to use", "basic")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.pallet.straps.strap(?).intersectionNode(?)#node", "Intersection node")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.pallet.sounds", "unload")
    schema:setXMLSpecializationType()
    Vehicle.xmlSchemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).pallet#age", "Random age of the pallet [0-1]")
end
function Pallet.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onPalletI3DFileLoaded", Pallet.onPalletI3DFileLoaded)
    SpecializationUtil.registerFunction(vehicleType, "getInfoBoxTitle", Pallet.getInfoBoxTitle)
    SpecializationUtil.registerFunction(vehicleType, "collectPalletTensionBeltNodes", Pallet.collectPalletTensionBeltNodes)
    SpecializationUtil.registerFunction(vehicleType, "setPalletTensionBeltNodesDirty", Pallet.setPalletTensionBeltNodesDirty)
    SpecializationUtil.registerFunction(vehicleType, "updatePalletStraps", Pallet.updatePalletStraps)
end
function Pallet.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMeshNodes", Pallet.getMeshNodes)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadComponentFromXML", Pallet.loadComponentFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAutoLoadSize", Pallet.getAutoLoadSize)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "autoLoad", Pallet.autoLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowInVehiclesOverview", Pallet.getShowInVehiclesOverview)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Pallet.getCanBeReset)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Pallet.getIsMapHotspotVisible)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitEmptyOnReset", Pallet.getFillUnitEmptyOnReset)
end
function Pallet.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", Pallet)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Pallet)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Pallet)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Pallet)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Pallet)
end
function Pallet:onPreLoad(_)
    self.isPallet = true
    self.allowsInput = false
end
function Pallet:onLoad(savegame)
    local spec = self.spec_pallet
    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.pallet#fillUnitIndex", 1)
    spec.node = self.xmlFile:getValue("vehicle.pallet#node", nil, self.components, self.i3dMappings)
    if spec.node ~= nil and not getHasClassId(spec.node, ClassIds.SHAPE) then
        Logging.xmlWarning(self.xmlFile, "Pallet node must be a shape in \'vehicle.pallet#node\'")
        spec.node = nil
    end
    spec.nodes = { spec.node }
    spec.tensionBeltNodes = { spec.node }
    spec.linkNodes = self.xmlFile:getValue("vehicle.pallet#linkNode", nil, self.components, self.i3dMappings, true)
    if #spec.linkNodes > 0 then
        spec.filename = self.xmlFile:getValue("vehicle.pallet#filename", "$data/objects/pallets/shared/euroPallet/euroPallet.i3d", self.baseDirectory)
        if spec.filename ~= nil then
            spec.sharedLoadRequestId = self:loadSubSharedI3DFile(spec.filename, true, true, self.onPalletI3DFileLoaded, self)
        end
    end
    spec.textures = {}
    for _, key in self.xmlFile:iterator("vehicle.pallet.texture") do
        local texture = {
            ["diffuse"] = self.xmlFile:getValue(key .. "#diffuse", nil, self.baseDirectory)
        }
        if texture.diffuse ~= nil then
            table.insert(spec.textures, texture)
        end
    end
    if savegame ~= nil then
        spec.palletAge = savegame.xmlFile:getValue(savegame.key .. ".pallet#age")
    end
    if spec.palletAge == nil then
        if self.propertyState == VehiclePropertyState.SHOP_CONFIG then
            spec.palletAge = 0
        else
            spec.palletAge = math.random()
        end
    end
    spec.contents = {}
    for _, key in self.xmlFile:iterator("vehicle.pallet.content") do
        local texture = {
            ["objects"] = {},
            ["fillUnitIndex"] = self.xmlFile:getValue(key .. "#fillUnitIndex", spec.fillUnitIndex)
        }
        for index, key in self.xmlFile:iterator(key .. ".object") do
            local object = {
                ["node"] = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
            }
            if object.node ~= nil then
                object.useAsTensionBeltMesh = self.xmlFile:getValue(key .. "#useAsTensionBeltMesh", true)
                if object.useAsTensionBeltMesh then
                    local tensionBeltNode = self.xmlFile:getValue(key .. "#tensionBeltNode", nil, self.components, self.i3dMappings)
                    if tensionBeltNode == nil then
                        if not getShapeIsCPUMesh(object.node) then
                            Logging.xmlWarning(self.xmlFile, "Shape \'%s\' defined in \'%s\' does not have \'CPU-Mesh\' flag set. Either set the flag on the mesh or add a custom tension belt node using xml attribute \'#tensionBeltNode\'", getName(object.node), key .. "#node")
                        end
                    elseif getShapeIsCPUMesh(tensionBeltNode) then
                        object.tensionBeltNode = tensionBeltNode
                    else
                        Logging.xmlWarning(self.xmlFile, "Shape \'%s\' defined in \'%s\' does not have \'CPU-Mesh\' flag set. Ignoring this node", getName(tensionBeltNode), key .. "#tensionBeltNode")
                    end
                end
                object.isActive = false
                setVisibility(object.node, object.isActive)
                table.insert(texture.objects, object)
            end
        end
        if #texture.objects > 0 then
            texture.numObjects = #texture.objects
            table.insert(spec.contents, texture)
        end
    end
    spec.straps = {}
    for _, key in self.xmlFile:iterator("vehicle.pallet.straps.strap") do
        local texture = {
            ["startNode"] = self.xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings),
            ["endNode"] = self.xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)
        }
        if texture.startNode == nil or texture.endNode == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid strap definition. Both start and end node must be defined")
        else
            local tensionBeltType = self.xmlFile:getValue(key .. "#tensionBeltType", "basic")
            texture.beltData = g_tensionBeltManager:getBeltData(tensionBeltType)
            if texture.beltData == nil then
                Logging.xmlWarning(self.xmlFile, "Invalid tension belt type \'%s\' defined for strap", tensionBeltType)
            else
                texture.intersectionNodes = {}
                for key, object in self.xmlFile:iterator(key .. ".intersectionNode") do
                    local tensionBeltNode = self.xmlFile:getValue(object .. "#node", nil, self.components, self.i3dMappings)
                    if tensionBeltNode ~= nil then
                        table.insert(texture.intersectionNodes, tensionBeltNode)
                    end
                end
                table.insert(spec.straps, texture)
            end
        end
    end
    spec.strapMeshes = {}
    spec.tensionBeltMeshes = {}
    spec.tensionBeltMeshesDirty = true
    if self.isClient then
        spec.samples = {}
        spec.samples.unload = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.pallet.sounds", "unload", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end
    g_currentMission.slotSystem:addLimitedObject(SlotSystem.LIMITED_OBJECT_PALLET, self)
    self.dynamicMountForkXLimit = 0.01
    self.dynamicMountForkYLimit = 0.1
end
function Pallet:onPostLoad(_)
    local spec = self.spec_pallet
    if #spec.nodes > 0 then
        for _, node in ipairs(spec.nodes) do
            local materialId = getMaterial(node, 0)
            local numTextures = #spec.textures
            if numTextures > 0 then
                local materialId
                if numTextures == 1 then
                    materialId = setMaterialDiffuseMapFromFile(materialId, spec.textures[1].diffuse, true, true, false)
                else
                    local alpha = spec.palletAge * (numTextures - 1)
                    local index1 = math.floor(alpha)
                    local index2 = math.ceil(alpha)
                    local materialId = setMaterialDiffuseMapFromFile(materialId, spec.textures[index1 + 1].diffuse, true, true, false)
                    local materialId = setMaterialCustomMapFromFile(materialId, spec.textures[index2 + 1].diffuse, "mCustomDiffuse", true, true, false)
                    materialId = setMaterialCustomParameter(materialId, "blendScale", alpha - index1, 0, 0, 0, false)
                end
                setMaterial(node, materialId, 0)
            end
        end
    end
end
function Pallet:onDelete()
    local spec = self.spec_pallet
    if self.isClient then
        g_soundManager:deleteSamples(spec.samples)
    end
    if spec.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
        spec.sharedLoadRequestId = nil
    end
    g_currentMission.slotSystem:removeLimitedObject(SlotSystem.LIMITED_OBJECT_PALLET, self)
end
function Pallet:saveToXMLFile(xmlFile, key, _)
    xmlFile:setValue(key .. "#age", self.spec_pallet.palletAge)
end
function Pallet:loadComponentFromXML(superFunc, component, xmlFile, key, rootPosition, i)
    if not Platform.gameplay.hasDynamicPallets and getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
        setRigidBodyType(component.node, RigidBodyType.KINEMATIC)
    end
    return superFunc(self, component, xmlFile, key, rootPosition, i)
end
function Pallet:onFillUnitFillLevelChanged(fillUnitIndex, _, _, _, _, _)
    local spec = self.spec_pallet
    local i = 1
    for i = i, #spec.contents do
        local content = spec.contents[i]
        if content.fillUnitIndex == fillUnitIndex then
            local fillLevelPct = self:getFillUnitFillLevelPercentage(fillUnitIndex)
            local visibleIndex = math.floor(content.numObjects * fillLevelPct)
            local visibleIndex = visibleIndex == 0 and fillLevelPct and 1 or visibleIndex
            local j = 1
            for j = j, #content.objects do
                local object = content.objects[j]
                local isActive = j <= visibleIndex
                if object.isActive ~= isActive then
                    local unloading = object.isActive
                    if unloading then
                        unloading = not isActive
                    end
                    if unloading and self.isClient then
                        g_soundManager:playSample(spec.samples.unload)
                    end
                    object.isActive = isActive
                    setVisibility(object.node, object.isActive)
                    self:setPalletTensionBeltNodesDirty()
                end
            end
        end
    end
end
function Pallet:getMeshNodes(superFunc)
    local spec = self.spec_pallet
    if spec.tensionBeltMeshesDirty then
        spec.tensionBeltMeshes = {}
        self:collectPalletTensionBeltNodes(spec.tensionBeltMeshes)
        spec.tensionBeltMeshesDirty = false
    end
    if #spec.tensionBeltMeshes > 0 then
        return spec.tensionBeltMeshes
    else
        return superFunc(self)
    end
end
function Pallet:collectPalletTensionBeltNodes(nodes)
    local spec = self.spec_pallet
    if #spec.tensionBeltNodes > 0 then
        for _, node in ipairs(spec.tensionBeltNodes) do
            table.insert(nodes, node)
        end
    end
    local i = 1
    for i = i, #spec.contents do
        local _ = spec.contents[i]
        local j = 1
        for j = j, #_.objects do
            local object = _.objects[j]
            if object.isActive and object.useAsTensionBeltMesh then
                table.insert(nodes, object.tensionBeltNode or object.node)
            end
        end
    end
    if self.spec_tensionBeltObject ~= nil then
        for _, node in ipairs(self.spec_tensionBeltObject.meshNodes) do
            table.insert(nodes, node)
        end
    end
end
function Pallet:setPalletTensionBeltNodesDirty()
    self.spec_pallet.tensionBeltMeshesDirty = true
end
function Pallet:updatePalletStraps()
    local spec = self.spec_pallet
    local i = #spec.strapMeshes
    local shapes = 1
    for i = i, shapes, -1 do
        delete(spec.strapMeshes[i])
        spec.strapMeshes[i] = nil
    end
    local shapes = self:getMeshNodes()
    for _, strap in ipairs(spec.straps) do
        local tensionBelt = TensionBeltGeometryConstructor.new()
        tensionBelt:setWidth(strap.beltData.width)
        tensionBelt:setMaterial(strap.beltData.material.materialId)
        tensionBelt:setUVscale(strap.beltData.material.uvScale)
        tensionBelt:setMaxEdgeLength(0.1)
        tensionBelt:setFixedPoints(strap.startNode, strap.endNode)
        tensionBelt:setGeometryBias(0.005)
        tensionBelt:setLinkNode(strap.startNode)
        for _, node in pairs(strap.intersectionNodes) do
            local x, y, z = getWorldTranslation(node)
            local dirX, dirY, dirZ = localDirectionToWorld(node, 1, 0, 0)
            tensionBelt:addIntersectionPoint(x, y, z, dirX, dirY, dirZ)
        end
        for _, node in ipairs(shapes) do
            tensionBelt:addShape(node, -100, 100, -100, 100)
        end
        local beltShapeId, _, beltLength = tensionBelt:finalize()
        local _ = 0
        local y = 1
        local node = #strap.intersectionNodes - 1
        local x = 1
        for y = y, node, x do
            _ = _ + calcDistanceFrom(strap.intersectionNodes[y], strap.intersectionNodes[y + 1])
        end
        local _
        if #strap.intersectionNodes > 0 then
            _ = _ + calcDistanceFrom(strap.startNode, strap.intersectionNodes[1]) + calcDistanceFrom(strap.intersectionNodes[#strap.intersectionNodes], strap.endNode)
        else
            _ = calcDistanceFrom(strap.startNode, strap.endNode)
        end
        if beltLength < _ + 0.025 then
            delete(beltShapeId)
        else
            table.insert(spec.strapMeshes, beltShapeId)
        end
    end
end
function Pallet:onPalletI3DFileLoaded(node, failedReason)
    if failedReason == LoadI3DFailedReason.NONE then
        local palletNode = getChildAt(node, 0)
        if getHasClassId(palletNode, ClassIds.SHAPE) then
            for i, linkNode in ipairs(self.spec_pallet.linkNodes) do
                if i == 1 then
                    link(linkNode, palletNode)
                    local tensionBeltNode = spec.nodes
                    table.insert(tensionBeltNode, palletNode)
                    local tensionBeltNode = getChildAt(palletNode, 0)
                    if tensionBeltNode ~= 0 then
                        table.insert(spec.tensionBeltNodes, tensionBeltNode)
                    end
                else
                    local tensionBeltNode = clone(palletNode, false, false, false)
                    link(linkNode, tensionBeltNode)
                    table.insert(spec.nodes, tensionBeltNode)
                    local tensionBeltNode = getChildAt(tensionBeltNode, 0)
                    if tensionBeltNode ~= 0 then
                        table.insert(spec.tensionBeltNodes, tensionBeltNode)
                    end
                end
            end
        end
        delete(node)
    end
end
function Pallet:getInfoBoxTitle()
    return g_i18n:getText("infohud_pallet")
end
function Pallet:getAutoLoadSize(_)
    local size = self.size
    return size.length, size.height, size.width
end
function Pallet:autoLoad(_, autoLoader, node, posX, posZ, sizeX, sizeZ)
    self:mountKinematic(autoLoader, node, posX + sizeX * 0.5, 0, posZ + sizeZ * 0.5, 0, 1.5707963267948966, 0)
    return true
end
function Pallet:getShowInVehiclesOverview(superFunc)
    return false
end
function Pallet:getCanBeReset(superFunc)
    return false
end
function Pallet:getIsMapHotspotVisible(superFunc)
    return false
end
function Pallet:getFillUnitEmptyOnReset(superFunc)
    return false
end