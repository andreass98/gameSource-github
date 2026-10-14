TireTracks = {}
TireTracks.MAX_CREATION_DISTANCE = 75
function TireTracks.prerequisitesPresent(specializations)
    return true
end
function TireTracks.initSpecialization() end
function TireTracks.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getAllowTireTracks", TireTracks.getAllowTireTracks)
    SpecializationUtil.registerFunction(vehicleType, "addTireTrackNode", TireTracks.addTireTrackNode)
    SpecializationUtil.registerFunction(vehicleType, "removeTireTrackNode", TireTracks.removeTireTrackNode)
    SpecializationUtil.registerFunction(vehicleType, "updateTireTrackNode", TireTracks.updateTireTrackNode)
end
function TireTracks.registerOverwrittenFunctions(vehicleType) end
function TireTracks.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", TireTracks)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TireTracks)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TireTracks)
end
function TireTracks:onPreLoad(_)
    local spec = self.spec_tireTracks
    spec.tireTrackNodes = {}
    spec.hasTireTrackNodes = false
    spec.segmentsCoeff = getTyreTracksSegmentsCoeff()
    spec.tireTrackSystem = g_currentMission.tireTrackSystem
end
function TireTracks:onDelete()
    local spec = self.spec_tireTracks
    if spec.tireTrackNodes ~= nil then
        for _, tireTrackNode in pairs(spec.tireTrackNodes) do
            spec.tireTrackSystem:destroyTrack(tireTrackNode.tireTrackIndex)
        end
    end
end
function TireTracks:onUpdate(_, _, _, _)
    if self.isActive then
        local spec = self.spec_tireTracks
        if spec.hasTireTrackNodes then
            local allowTireTracks = self:getAllowTireTracks()
            for _, tireTrackNode in pairs(spec.tireTrackNodes) do
                self:updateTireTrackNode(tireTrackNode, allowTireTracks)
            end
        end
    end
end
function TireTracks:getAllowTireTracks()
    return self.currentUpdateDistance < TireTracks.MAX_CREATION_DISTANCE and self.spec_tireTracks.segmentsCoeff > 0
end
function TireTracks:addTireTrackNode(wheel, parent, linkNode, tireTrackAtlasIndex, width, radius, inverted, activeFunc)
    local spec = self.spec_tireTracks
    if spec.tireTrackSystem ~= nil then
        ({
            ["wheel"] = wheel,
            ["parent"] = parent,
            ["linkNode"] = linkNode,
            ["tireTrackAtlasIndex"] = tireTrackAtlasIndex,
            ["width"] = width,
            ["radius"] = radius,
            ["inverted"] = inverted,
            ["activeFunc"] = activeFunc
        }).tireTrackIndex = spec.tireTrackSystem:createTrack(width, tireTrackAtlasIndex)
        if tireTrackNode.tireTrackIndex ~= nil then
            table.insert(spec.tireTrackNodes, tireTrackNode)
            spec.hasTireTrackNodes = next(spec.tireTrackNodes) ~= nil
            return #spec.tireTrackNodes
        end
    end
    return nil
end
function TireTracks:removeTireTrackNode(tireTrackNodeIndex)
    local spec = self.spec_tireTracks
    spec.tireTrackNodes[tireTrackNodeIndex] = nil
    spec.hasTireTrackNodes = next(spec.tireTrackNodes) ~= nil
end
function TireTracks:updateTireTrackNode(tireTrackNode, allowTireTracks)
    if allowTireTracks then
        if tireTrackNode.activeFunc == nil or tireTrackNode.activeFunc() then
            local wx, wy, wz = worldToLocal(tireTrackNode.parent, getWorldTranslation(tireTrackNode.linkNode))
            local r, g, b = localToWorld(tireTrackNode.parent, wx, wy - tireTrackNode.radius, wz)
            local b = getTerrainHeightAtWorldPos
            local groundDepth = g_terrainNode
            local r = math.max(g, b(groundDepth, r, g, b))
            if tireTrackNode.wheel.physics.contact == WheelContactType.NONE or not tireTrackNode.wheel.physics.lastContactObjectAllowsTireTracks then
                self.spec_tireTracks.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
                return
            else
                local r, g, b, groundDepth, t, dirtAmount, colorBlendWithTerrain = wheel.physics:getGroundAttributes()
                if dirtAmount > 0 then
                    local ux, uy, uz = localDirectionToWorld(wheel.node, -wheel.physics.directionX, -wheel.physics.directionY, -wheel.physics.directionZ)
                    local tireDirection = self.movingDirection
                    if tireTrackNode.inverted then
                    end
                    spec.tireTrackSystem:addTrackPoint(tireTrackNode.tireTrackIndex, r, r, b, ux, uy, uz, r, g, b, dirtAmount, groundDepth, tireDirection, wheel.physics.contact ~= WheelContactType.OBJECT, colorBlendWithTerrain)
                else
                    spec.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
                end
            end
        else
            spec.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
            return
        end
    else
        spec.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
        return
    end
end