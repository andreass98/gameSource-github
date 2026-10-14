CylinderedFoldable = {}
function CylinderedFoldable.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Cylindered, specializations) and SpecializationUtil.hasSpecialization(Foldable, specializations)
end
function CylinderedFoldable.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("CylinderedFoldable")
    schema:register(XMLValueType.BOOL, "vehicle.cylindered#loadMovingToolStatesAfterFolding", "Load moving tool states after folding state was loaded", false)
    schema:register(XMLValueType.FLOAT, "vehicle.cylindered#loadMovingToolStatesFoldTime", "Fold time in which moving tool states should be loaded")
    schema:setXMLSpecializationType()
end
function CylinderedFoldable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", CylinderedFoldable)
    SpecializationUtil.registerEventListener(vehicleType, "onPreInitComponentPlacement", CylinderedFoldable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CylinderedFoldable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CylinderedFoldable)
end
function CylinderedFoldable:onLoad(_)
    local spec = self.spec_cylinderedFoldable
    spec.loadMovingToolStatesAfterFolding = self.xmlFile:getValue("vehicle.cylindered#loadMovingToolStatesAfterFolding", false)
    spec.loadMovingToolStatesFoldTime = self.xmlFile:getValue("vehicle.cylindered#loadMovingToolStatesFoldTime")
end
function CylinderedFoldable:onPreInitComponentPlacement(savegame)
    local spec = self.spec_cylinderedFoldable
    if spec.loadMovingToolStatesAfterFolding then
        local targetFoldTime = spec.loadMovingToolStatesFoldTime
        if targetFoldTime == nil or self:getFoldAnimTime() == targetFoldTime then
            Cylindered.onPostLoad(self, savegame)
        end
    end
end
function CylinderedFoldable:onReadStream(streamId, connection)
    AnimatedVehicle.updateAnimations(self, 9999999)
    if streamReadBool(streamId) then
        Cylindered.onReadStream(self, streamId, connection)
    end
    if connection:getIsServer() then
        local i = 1
        for i = i, #self.spec_cylindered.movingTools do
            local tool = self.spec_cylindered.movingTools[i]
            if tool.dirtyFlag ~= nil then
                self:updateDependentAnimations(tool, 9999)
            end
        end
    end
end
function CylinderedFoldable:onWriteStream(streamId, connection)
    local spec = self.spec_cylinderedFoldable
    if streamWriteBool(streamId, spec.loadMovingToolStatesFoldTime == nil or self:getFoldAnimTime() == spec.loadMovingToolStatesFoldTime) then
        Cylindered.onWriteStream(self, streamId, connection)
    end
end