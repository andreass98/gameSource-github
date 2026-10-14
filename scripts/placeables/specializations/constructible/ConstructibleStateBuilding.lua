ConstructibleStateBuilding = {}
local ConstructibleStateBuilding_mt = Class(ConstructibleStateBuilding, ConstructibleState)
function ConstructibleStateBuilding.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".mesh(?)#node", "")
    schema:register(XMLValueType.INT, basePath .. ".mesh(?)#indexMin", "")
    schema:register(XMLValueType.INT, basePath .. ".mesh(?)#indexMax", "")
    schema:register(XMLValueType.INT, basePath .. ".mesh(?)#direction", "")
    schema:register(XMLValueType.STRING, basePath .. ".input(?)#fillType", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".input(?)#amount", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".input(?)#usagePerHour", "")
end
function ConstructibleStateBuilding.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".state.input(?)#fillType", "")
    schema:register(XMLValueType.FLOAT, basePath .. ".state.input(?)#remainingAmount", "")
end
function ConstructibleStateBuilding.new(constructible, dirtyFlag, customMt)
    -- upvalues: (copy) ConstructibleStateBuilding_mt
    return ConstructibleState.new(constructible, dirtyFlag, customMt or ConstructibleStateBuilding_mt)
end
function ConstructibleStateBuilding:load(xmlFile, key)
    ConstructibleStateBuilding:superClass().load(self, xmlFile, key)
    self.totalAmount = 0
    self.inputs = {}
    self.hasInputMaterials = true
    for _, inputKey in xmlFile:iterator(key .. ".input") do
        local fillTypeStr = xmlFile:getValue(inputKey .. "#fillType")
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)
        if fillType == nil then
            Logging.xmlWarning(xmlFile, "Unknown fillType \'%s\' in \'%s\'", fillTypeStr, inputKey)
            break
        end
        if not self.constructible:getConstructibleSupportsFillType(fillType.index) then
            Logging.xmlWarning(xmlFile, "Filltype \'%s\' in \'%s\' not supported by storage", fillType.name, inputKey)
            break
        end
        local amount = xmlFile:getValue(inputKey .. "#amount")
        local usagePerSecond = xmlFile:getValue(inputKey .. "#usagePerHour") / 60 / 60
        self.totalAmount = self.totalAmount + amount
        table.insert(self.inputs, {
            ["fillType"] = fillType,
            ["amount"] = amount,
            ["remainingAmount"] = amount,
            ["lastSyncedAmount"] = amount,
            ["usagePerSecond"] = usagePerSecond,
            ["infoTableEntry"] = {
                ["title"] = fillType.title,
                ["text"] = g_i18n:formatVolume(amount)
            }
        })
    end
    self.meshes = {}
    for _, inputKey in xmlFile:iterator(key .. ".mesh") do
        local fillTypeStr = xmlFile:getValue(inputKey .. "#node", nil, self.constructible.components, self.constructible.i3dMappings)
        if fillTypeStr == nil then
            break
        end
        if not getHasClassId(fillTypeStr, ClassIds.SHAPE) then
            Logging.xmlError(xmlFile, "node \'%s\' at \'%s\' is not a shape", getName(fillTypeStr), inputKey)
            break
        end
        if not getHasShaderParameter(fillTypeStr, "hideByIndex") then
            Logging.xmlError(xmlFile, "mesh \'%s\' at \'%s\' does not have required shader parameter \'hideByIndex\'", getName(fillTypeStr), inputKey)
            break
        end
        local fillType = xmlFile:getValue(inputKey .. "#indexMin", 0)
        local amount = xmlFile:getValue(inputKey .. "#indexMax")
        if amount == nil then
            amount = getUserAttribute(fillTypeStr, "hideByIndexMaxIndex")
            if fillType == nil then
                Logging.xmlError(xmlFile, "Cannot retrieve indexMax from shape material and value is also not set in xml at \'%s\'", getName(fillTypeStr), inputKey)
                break
            end
        end
        local usagePerSecond = xmlFile:getValue(inputKey .. "#direction", 1)
        local mesh = {
            ["node"] = fillTypeStr,
            ["childIndex"] = getChildIndex(fillTypeStr),
            ["index"] = #self.meshes + 1,
            ["indexMin"] = fillType,
            ["indexMax"] = amount,
            ["direction"] = usagePerSecond,
            ["lastValue"] = -1,
            ["numBits"] = MathUtil.getNumRequiredBits(amount)
        }
        self:setMeshProgress(mesh, 0)
        table.insert(self.meshes, mesh)
    end
    self.infoBoxRequiredGoods = {
        ["title"] = g_i18n:getText("infohud_requiredMaterialsNextStep"),
        ["accentuate"] = true
    }
end
function ConstructibleStateBuilding:saveToXMLFile(xmlFile, key, _)
    for k, input in ipairs(self.inputs) do
        local inputKey = string.format("%s.state.input(%d)", key, k - 1)
        xmlFile:setValue(inputKey .. "#fillType", input.fillType.name)
        xmlFile:setValue(inputKey .. "#remainingAmount", input.remainingAmount)
    end
end
function ConstructibleStateBuilding:loadFromXMLFile(xmlFile, key)
    for _, inputKey in xmlFile:iterator(key .. ".state.input") do
        local fillType = g_fillTypeManager:getFillTypeByName(xmlFile:getValue(inputKey .. "#fillType"))
        local remainingAmount = xmlFile:getValue(inputKey .. "#remainingAmount")
        for _, input in ipairs(self.inputs) do
            if input.fillType == fillType then
                self:updateRemainingAmount(input, remainingAmount)
            end
        end
    end
end
function ConstructibleStateBuilding:isDone()
    for _, input in ipairs(self.inputs) do
        if input.remainingAmount > 0 then
            return false
        end
    end
    return true
end
function ConstructibleStateBuilding:onReadStream(streamId, _)
    for i, input in ipairs(self.inputs) do
        self:updateRemainingAmount(input, streamReadFloat32(streamId))
    end
    for i, input in ipairs(self.meshes) do
        local hideByIndexValue = streamReadUIntN(streamId, input.numBits)
        local progress = MathUtil.inverseLerp(input.indexMax, input.indexMin, hideByIndexValue)
        if input.direction == -1 then
        end
        self:setMeshProgress(input, progress)
    end
end
function ConstructibleStateBuilding:onWriteStream(streamId, _)
    for i, input in ipairs(self.inputs) do
        streamWriteFloat32(streamId, input.remainingAmount)
    end
    for i, input in ipairs(self.meshes) do
        streamWriteUIntN(streamId, input.lastValue, input.numBits)
    end
end
function ConstructibleStateBuilding:onReadUpdateStream(streamId, _, _)
    for i, input in ipairs(self.inputs) do
        self:updateRemainingAmount(input, streamReadFloat32(streamId))
    end
    for i, input in ipairs(self.meshes) do
        local hideByIndexValue = streamReadUIntN(streamId, input.numBits)
        local progress = MathUtil.inverseLerp(input.indexMax, input.indexMin, hideByIndexValue)
        if input.direction == -1 then
        end
        self:setMeshProgress(input, progress)
    end
end
function ConstructibleStateBuilding:onWriteUpdateStream(streamId, _, _)
    for i, input in ipairs(self.inputs) do
        streamWriteFloat32(streamId, input.remainingAmount)
    end
    for i, input in ipairs(self.meshes) do
        streamWriteUIntN(streamId, input.lastValue, input.numBits)
    end
end
function ConstructibleStateBuilding:raiseActive()
    return self.hasInputMaterials
end
function ConstructibleStateBuilding:getPlaySound()
    return self.hasInputMaterials
end
function ConstructibleStateBuilding:update(dt)
    local usedAmount = 0
    self.hasInputMaterials = false
    for i, input in ipairs(self.inputs) do
        if input.remainingAmount > 0 then
            local delta = self.constructible:removeConstructibleFillLevel(input.fillType.index, input.usagePerSecond / 1000 * (dt * g_currentMission.missionInfo.timeScale))
            if delta > 0 then
                self.hasInputMaterials = true
                self:updateRemainingAmount(input, input.remainingAmount - delta)
                if math.abs(input.remainingAmount - input.lastSyncedAmount) > input.amount / 100 or (input.remainingAmount <= 0.01 or input.remainingAmount == input.amount) then
                    self.constructible:raiseDirtyFlags(self.dirtyFlag)
                    input.lastSyncedAmount = input.remainingAmount
                end
            end
        end
    end
    for i, input in ipairs(self.meshes) do
        self:setMeshProgress(input, usedAmount / self.totalAmount)
    end
    ConstructibleStateBuilding:superClass().update(self, dt)
end
function ConstructibleStateBuilding:deactivate()
    for i, input in ipairs(self.inputs) do
        self:updateRemainingAmount(input, input.amount)
    end
    for i, input in ipairs(self.meshes) do
        self:setMeshProgress(input, 1)
    end
    ConstructibleStateBuilding:superClass().deactivate(self)
end
function ConstructibleStateBuilding:reset()
    for i, input in ipairs(self.inputs) do
        self:updateRemainingAmount(input, input.amount)
    end
    for i, input in ipairs(self.meshes) do
        self:setMeshProgress(input, 0)
    end
    ConstructibleStateBuilding:superClass().reset(self)
end
function ConstructibleStateBuilding:updateInfo(infoTable)
    table.insert(infoTable, self.infoBoxRequiredGoods)
    for i, input in ipairs(self.inputs) do
        if input.remainingAmount > 0.01 then
            table.insert(infoTable, input.infoTableEntry)
        end
    end
end
function ConstructibleStateBuilding.updateRemainingAmount(_, input, amount)
    input.remainingAmount = math.max(0, amount < 0.01 and 0 or amount)
    input.infoTableEntry.text = g_i18n:formatVolume((math.ceil(input.remainingAmount)))
end
function ConstructibleStateBuilding:setMeshProgress(mesh, percentage)
    if mesh ~= nil then
        if mesh.direction == -1 then
        end
        local node = MathUtil.lerp(mesh.indexMax, mesh.indexMin, percentage)
        local hideByIndexValue = math.round(node)
        if hideByIndexValue ~= mesh.lastValue then
            local node = mesh.node
            setVisibility(node, percentage ~= 0)
            mesh.lastValue = hideByIndexValue
            setShaderParameter(node, "hideByIndex", hideByIndexValue, 0, 0, 0, false)
            if self.constructible.isServer then
                self.constructible:raiseDirtyFlags(self.dirtyFlag)
            end
        end
    end
end