ChainsawUtil = {}
function ChainsawUtil.cutSplitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId)
    local splitTypeName = ""
    local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(shape))
    if splitType ~= nil then
        splitTypeName = splitType.name
    end
    if getRigidBodyType(shape) == RigidBodyType.STATIC then
        g_densityMapHeightManager:setCollisionMapAreaDirty(x - 5, z - 5, x + 5, z + 5, true)
        g_currentMission.aiSystem:setAreaDirty(x - 5, x + 5, z - 5, z + 5)
    end
    local range = g_farmManager:getFarmById(farmId)
    if math.abs(ny) < 0.866 then
        ChainsawUtil.curSplitShapes = {}
        g_currentMission:removeKnownSplitShape(shape)
        ChainsawUtil.shapeBeingCut = shape
        local split0 = ChainsawUtil
        local split1 = getRigidBodyType(shape) == RigidBodyType.STATIC
        split0.fromTree = split1
        splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "ChainsawUtil.cutSplitShapeCallback", nil)
        g_treePlantManager:removingSplitShape(shape)
        if #ChainsawUtil.curSplitShapes == 2 then
            local split0 = ChainsawUtil.curSplitShapes[1]
            local split1 = ChainsawUtil.curSplitShapes[2]
            local type0 = getRigidBodyType(split0.shape)
            local type1 = getRigidBodyType(split1.shape)
            local isTree = false
            if type0 == RigidBodyType.STATIC and type1 == RigidBodyType.DYNAMIC then
                isTree = true
                split0 = split1
            elseif type1 == RigidBodyType.STATIC and type0 == RigidBodyType.DYNAMIC then
                isTree = true
            else
                split0 = nil
            end
            if isTree then
                if range ~= nil then
                    local cutTreeCount = range.stats:updateStats("cutTreeCount", 1)
                    g_achievementManager:tryUnlock("CutTreeFirst", cutTreeCount)
                    g_achievementManager:tryUnlock("CutTree", cutTreeCount)
                    if splitTypeName ~= "" then
                        range.stats:updateTreeTypesCut(splitTypeName)
                    end
                end
                local cutTreeCount = g_currentMission.cuttingSounds.tree
                local sizeX, sizeY, sizeZ, _, _ = getSplitShapeStats(split0.shape)
                local bvVolume = 0
                if sizeX ~= nil then
                    bvVolume = sizeX * sizeY * sizeZ
                end
                if cutTreeCount ~= nil and (cutTreeCount.soundNode ~= nil and bvVolume > 1) then
                    g_soundManager:playSample(cutTreeCount)
                    setTranslation(cutTreeCount.soundNode, x, y, z)
                    return
                end
            end
        end
    else
        ChainsawUtil.curSplitShapes = {}
        g_currentMission:removeKnownSplitShape(shape)
        ChainsawUtil.shapeBeingCut = shape
        local split0 = ChainsawUtil
        local split1 = getRigidBodyType(shape) == RigidBodyType.STATIC
        split0.fromTree = split1
        splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "ChainsawUtil.cutSplitShapeCallback", nil)
        g_treePlantManager:removingSplitShape(shape)
        if #ChainsawUtil.curSplitShapes == 2 then
            local split0 = ChainsawUtil.curSplitShapes[1]
            local split1 = ChainsawUtil.curSplitShapes[2]
            local type0 = getRigidBodyType(split0.shape)
            local type1 = getRigidBodyType(split1.shape)
            local cutTreeCount = false
            if type0 == RigidBodyType.STATIC and type1 == RigidBodyType.DYNAMIC then
                cutTreeCount = true
            elseif type1 == RigidBodyType.STATIC and type0 == RigidBodyType.DYNAMIC then
                cutTreeCount = true
            else
                split0 = nil
                split1 = nil
            end
            if cutTreeCount then
                local sizeX = g_currentMission.cuttingSounds.tree
                local sizeY, sizeZ, _, _, bvVolume = getSplitShapeStats(split0.shape)
                local bvVolume = 0
                if sizeY ~= nil then
                    bvVolume = sizeY * sizeZ * _
                end
                if sizeX ~= nil and (sizeX.soundNode ~= nil and bvVolume > 1) then
                    g_soundManager:playSample(sizeX)
                    setTranslation(sizeX.soundNode, x, y, z)
                end
            end
            if split0 ~= nil then
                local sizeX = split0.minY + (split0.maxY - split0.minY) * 0.75
                local sizeY = (split0.minZ + split0.maxZ) * 0.5
                local sizeZ, _, _ = MathUtil.crossProduct(nx, ny, nz, yx, yy, yz)
                local scale1 = 0.6427876096865393
                if split0.isBelow then
                end
                local nx2 = nx * 0.7659825218948272 + yx * scale1
                local ny2 = ny * 0.7659825218948272 + yy * scale1
                local nz2 = nz * 0.7659825218948272 + yz * scale1
                local yx2, yy2, yz2 = MathUtil.crossProduct(sizeZ, _, _, nx2, ny2, nz2)
                g_currentMission:removeKnownSplitShape(split1.shape)
                ChainsawUtil.shapeBeingCut = split1.shape
                splitShape(split1.shape, x + yx * sizeX - yx2 * cutSizeY * 0.1, y + yy * sizeX - yy2 * cutSizeY * 0.1, z + yz * sizeX - yz2 * cutSizeY * 0.1, nx2, ny2, nz2, yx2, yy2, yz2, cutSizeY * 1.1, cutSizeZ, "ChainsawUtil.cutSplitShapeCallbackCutJoint", nil)
                g_treePlantManager:removingSplitShape(split1.shape)
                local jx = x + yx * sizeX + sizeZ * sizeY
                local jy = y + yy * sizeX + _ * sizeY
                local jz = z + yz * sizeX + _ * sizeY
                local constr = JointConstructor.new()
                constr:setActors(0, split0.shape)
                constr:setJointWorldAxes(nx, ny, nz, nx, ny, nz)
                constr:setJointWorldNormals(yx, yy, yz, yx, yy, yz)
                constr:setJointWorldPositions(jx, jy, jz, jx, jy, jz)
                constr:setRotationLimit(0, 0, 0)
                constr:setTranslationLimit(0, false, 0, 0)
                constr:setEnableCollision(true)
                local jointIndex = constr:finalize()
                local ax, ay, az = MathUtil.crossProduct(0, 0.8, 0, yx, yy, yz)
                setAngularVelocity(split0.shape, ax, ay, az)
                g_treePlantManager:addTreeCutJoint(jointIndex, split0.shape, nx, ny, nz, 0.7853981633974483, 2000)
                if range ~= nil then
                    local cutTreeCount = range.stats:updateStats("cutTreeCount", 1)
                    g_achievementManager:tryUnlock("CutTreeFirst", cutTreeCount)
                    g_achievementManager:tryUnlock("CutTree", cutTreeCount)
                    if splitTypeName ~= "" then
                        range.stats:updateTreeTypesCut(splitTypeName)
                    end
                end
            end
        end
    end
end
function ChainsawUtil.cutSplitShapeCallback(_, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    g_currentMission:addKnownSplitShape(shape)
    g_treePlantManager:addingSplitShape(shape, ChainsawUtil.shapeBeingCut, ChainsawUtil.fromTree)
    table.insert(ChainsawUtil.curSplitShapes, {
        ["shape"] = shape,
        ["isBelow"] = isBelow,
        ["isAbove"] = isAbove,
        ["minY"] = minY,
        ["maxY"] = maxY,
        ["minZ"] = minZ,
        ["maxZ"] = maxZ
    })
end
function ChainsawUtil.cutSplitShapeCallbackCutJoint(_, shape, _, _, _, _, _, _)
    g_currentMission:addKnownSplitShape(shape)
    g_treePlantManager:addingSplitShape(shape, ChainsawUtil.shapeBeingCut, true)
end