ExtendedWeedControl = {}
ExtendedWeedControl.MOD_NAME = g_currentModName
ExtendedWeedControl.BASE_DIRECTORY = g_currentModDirectory
local ExtendedWeedControl_mt = Class(ExtendedWeedControl)
function ExtendedWeedControl.new(precisionFarming, customMt)
    -- upvalues: (copy) ExtendedWeedControl_mt
    local self = setmetatable({}, customMt or ExtendedWeedControl_mt)
    self.precisionFarming = precisionFarming
    self.lastUseSpotSpraying = false
    self.minOctave1 = 8
    self.numOctave1 = 1
    self.persistence1 = 0.5
    self.minOctave2 = 12
    self.numOctave2 = 1
    self.persistence2 = 0.5
    if g_server ~= nil then
        addConsoleCommand("pfWeedSetNoiseParameters", "Sets current weed noise parameters", "setWeedNoiseParameters", self)
    end
    return self
end
function ExtendedWeedControl:loadFromXML(_, _, _, _, _)
    local noiseFilename = Utils.getFilename("shared/weedNoise.grle", ExtendedWeedControl.BASE_DIRECTORY)
    self.noiseBitVectorMap = createBitVectorMap("weedNoise")
    if not loadBitVectorMapFromFile(self.noiseBitVectorMap, noiseFilename, 1) then
        loadBitVectorMapNew(self.noiseBitVectorMap, 4096, 4096, 1, false)
        Logging.error("Failed to load weed noise map from %s", noiseFilename)
        return false
    end
    self.noiseFilter = DensityMapFilter.new(self.noiseBitVectorMap, 0, 1)
    self.noiseFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
end
function ExtendedWeedControl:unloadMapData()
    self.noiseFilter = nil
    self.weedFilter = nil
    if self.noiseBitVectorMap ~= nil then
        delete(self.noiseBitVectorMap)
        self.noiseBitVectorMap = nil
    end
    if g_server ~= nil then
        removeConsoleCommand("pfWeedSetNoiseParameters")
    end
end
function ExtendedWeedControl:setWeedNoiseParameters(minOctave1, numOctave1, persistence1, minOctave2, numOctave2, persistence2)
    local modifier = tonumber(minOctave1)
    local modifier = tonumber(numOctave1)
    local modifier = tonumber(persistence1)
    local modifier = tonumber(minOctave2)
    local modifier = tonumber(numOctave2)
    local modifier = tonumber(persistence2)
    local modifier = modifier or self.minOctave1
    local perlinNoiseFilter1 = modifier or self.numOctave1
    local perlinNoiseFilter2 = modifier or self.persistence1
    self.minOctave1 = modifier
    self.numOctave1 = perlinNoiseFilter1
    self.persistence1 = perlinNoiseFilter2
    local modifier = modifier or self.minOctave2
    local perlinNoiseFilter1 = modifier or self.numOctave2
    local perlinNoiseFilter2 = modifier or self.persistence2
    self.minOctave2 = modifier
    self.numOctave2 = perlinNoiseFilter1
    self.persistence2 = perlinNoiseFilter2
    log("Weed Noise Parameters:")
    log(string.format("  minOctave1 %.2f, numOctave1 %.2f, persistence1 %.2f", self.minOctave1, self.numOctave1, self.persistence1))
    log(string.format("  minOctave2 %.2f, numOctave2 %.2f, persistence2 %.2f", self.minOctave2, self.numOctave2, self.persistence2))
    loadBitVectorMapNew(self.noiseBitVectorMap, 4096, 4096, 1, false)
    local modifier = DensityMapModifier.new(self.noiseBitVectorMap, 0, 1, g_terrainNode)
    local perlinNoiseFilter1 = PerlinNoiseFilter.new(self.noiseBitVectorMap, self.minOctave1, self.numOctave1, self.persistence1, math.random(0, 1000))
    local perlinNoiseFilter2 = PerlinNoiseFilter.new(self.noiseBitVectorMap, self.minOctave2, self.numOctave2, self.persistence2, math.random(0, 1000))
    local noiseValues = {}
    table.insert(noiseValues, {
        0,
        750,
        0,
        9000
    })
    table.insert(noiseValues, {
        750,
        1500,
        0,
        5000
    })
    table.insert(noiseValues, {
        1500,
        2000,
        0,
        3000
    })
    table.insert(noiseValues, {
        2000,
        3500,
        0,
        2000
    })
    table.insert(noiseValues, {
        3500,
        5000,
        0,
        1000
    })
    table.insert(noiseValues, {
        5000,
        10000,
        0,
        500
    })
    for _, noiseValue in ipairs(noiseValues) do
        perlinNoiseFilter1:setValueCompareParams(DensityValueCompareType.BETWEEN, noiseValue[1], noiseValue[2])
        perlinNoiseFilter2:setValueCompareParams(DensityValueCompareType.BETWEEN, noiseValue[3], noiseValue[4])
        modifier:executeSet(1, perlinNoiseFilter1, perlinNoiseFilter2)
    end
    local path = getUserProfileAppPath() .. "weedNoise.grle"
    saveBitVectorMapToFile(self.noiseBitVectorMap, path)
    Logging.info("Saved weed noise map to %s", path)
end
function ExtendedWeedControl:clearWeedArea(modifier, weedFilter)
    modifier:executeSet(0, self.noiseFilter, weedFilter)
end
function ExtendedWeedControl:getWeedModifier()
    if self.weedModifier == nil then
        local weedSystem = g_currentMission.weedSystem
        if weedSystem:getMapHasWeed() then
            local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
            self.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
            local weedSparseState = weedSystem:getSparseStartState()
            local weedDenseState = weedSystem:getDenseStartState()
            self.weedFilterDense = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
            self.weedFilterDense:setValueCompareParams(DensityValueCompareType.EQUAL, weedDenseState)
            self.weedFilterSparse = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
            self.weedFilterSparse:setValueCompareParams(DensityValueCompareType.EQUAL, weedSparseState)
        end
    end
    return self.weedModifier
end
function ExtendedWeedControl:overwriteGameFunctions(pfModule)
    pfModule:overwriteGameFunction(FSDensityMapUtil, "setSowingWeedArea", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        -- upvalues: (copy) self
        superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
        local weedModifier = self:getWeedModifier()
        if weedModifier ~= nil then
            weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
            self:clearWeedArea(weedModifier, self.weedFilterDense)
            self:clearWeedArea(weedModifier, self.weedFilterSparse)
        end
    end)
    pfModule:overwriteGameFunction(Sprayer, "processSprayerArea", function(superFunc, vehicle, workArea, dt)
        -- upvalues: (copy) self
        self.lastUseSpotSpraying = vehicle.getIsSpotSprayEnabled ~= nil and vehicle:getIsSpotSprayEnabled()
        return superFunc(vehicle, workArea, dt)
    end)
    pfModule:overwriteGameFunction(FSDensityMapUtil, "updateHerbicideArea", function(_, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
        -- upvalues: (copy) self
        local allowPreventiveSpraying = self.lastUseSpotSpraying ~= true
        local weedSystem = g_currentMission.weedSystem
        if not weedSystem:getMapHasWeed() then
            return 0, 0
        end
        local functionData = FSDensityMapUtil.functionCache.updateHerbicideArea
        if functionData == nil then
            FSDensityMapUtil.functionCache.updateHerbicideArea = {
                ["numChangedPixels"] = {},
                ["totalNumPixels"] = {},
                ["multiModifiers"] = {},
                ["defaultMultiModifiers"] = {}
            }
        end
        local label = "sprayedTotal"
        if groundType ~= nil and functionData.multiModifiers[groundType] == nil then
            functionData.multiModifiers[groundType] = {}
        end
        local multiModifier = groundType and functionData.multiModifiers[groundType][allowPreventiveSpraying] or functionData.defaultMultiModifiers[allowPreventiveSpraying]
        if multiModifier == nil then
            multiModifier = DensityMapMultiModifier.new()
            local terrainRootNode = g_terrainNode
            local fieldGroundSystem = g_currentMission.fieldGroundSystem
            local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
            local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
            local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
            local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
            local replacementData = weedSystem:getHerbicideReplacements()
            local replacements = replacementData.weed.replacements
            if replacementData.custom ~= nil then
                for _, data in ipairs(replacementData.custom) do
                    local desc = data.fruitType
                    if desc.terrainDataPlaneId ~= nil then
                        local fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
                        local sourceStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                        for sourceState, targetState in pairs(replacements) do
                            sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
                            multiModifier:addExecuteSetWithStats(label, targetState, fruitModifier, sourceStateFilter)
                        end
                    end
                end
            end
            local sprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
            local weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
            local groundFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
            groundFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
            for fruitModifier, sourceStateFilter in pairs(replacements) do
                if allowPreventiveSpraying or fruitModifier ~= 1 and fruitModifier ~= 2 then
                    local weedFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
                    weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, fruitModifier)
                    for targetState, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
                        if desc.terrainDataPlaneId ~= nil then
                            local fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                            fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, desc.minHarvestingGrowthState - 1)
                            multiModifier:addExecuteSet(groundType, sprayModifier, fruitFilter, weedFilter)
                            multiModifier:addExecuteSetWithStats(label, sourceStateFilter, weedModifier, fruitFilter, weedFilter)
                            local cutFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                            cutFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.cutState + 1)
                            multiModifier:addExecuteSet(groundType, sprayModifier, cutFruitFilter, weedFilter)
                            multiModifier:addExecuteSetWithStats(label, sourceStateFilter, weedModifier, cutFruitFilter, weedFilter)
                            if desc.wheelDestructionState ~= nil and desc.wheelDestructionState ~= desc.cutState + 1 then
                                local wheelDestructionFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
                                wheelDestructionFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.wheelDestructionState)
                                multiModifier:addExecuteSet(groundType, sprayModifier, wheelDestructionFruitFilter, weedFilter)
                                multiModifier:addExecuteSetWithStats(label, sourceStateFilter, weedModifier, wheelDestructionFruitFilter, weedFilter)
                            end
                        end
                    end
                    multiModifier:addExecuteSet(groundType, sprayModifier, groundFilter, weedFilter)
                    multiModifier:addExecuteSetWithStats(label, sourceStateFilter, weedModifier, groundFilter, weedFilter)
                end
            end
            if groundType then
                functionData.multiModifiers[groundType][allowPreventiveSpraying] = multiModifier
            else
                functionData.defaultMultiModifiers[allowPreventiveSpraying] = multiModifier
            end
        end
        local terrainRootNode = functionData.numChangedPixels
        local fieldGroundSystem = functionData.totalNumPixels
        multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
        multiModifier:resetStats()
        multiModifier:execute(nil, terrainRootNode, fieldGroundSystem)
        return terrainRootNode.sprayedTotal + terrainRootNode.sprayed, fieldGroundSystem.sprayedTotal or 0
    end)
    pfModule:overwriteGameFunction(FieldUpdateTask, "prepare", function(superFunc, _self, ...)
        -- upvalues: (copy) self
        superFunc(_self, ...)
        if _self.weedState ~= nil then
            local weedModifier = self:getWeedModifier()
            if weedModifier ~= nil then
                _self.multiModifier:addExecuteSet(0, weedModifier, self.noiseFilter)
            end
        end
    end)
    pfModule:overwriteGameFunction(FieldState, "update", function(superFunc, _self, x, z, ...)
        -- upvalues: (copy) self
        superFunc(_self, x, z, ...)
        local weedSystem = g_currentMission.weedSystem
        if weedSystem:getMapHasWeed() then
            local functionData = self.fieldStateWeedStateData
            if functionData == nil then
                local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
                local factors = weedSystem:getFactors()
                functionData = {
                    ["weedModifier"] = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode),
                    ["weedStateFilters"] = {}
                }
                for state, _ in pairs(factors) do
                    local filter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
                    filter:setValueCompareParams(DensityValueCompareType.EQUAL, state)
                    functionData.weedStateFilters[filter] = state
                end
                self.fieldStateWeedStateData = functionData
            end
            local terrainRootNode = functionData.weedModifier
            local weedMapId = functionData.weedStateFilters
            terrainRootNode:setParallelogramWorldCoords(x - 10, z - 10, x + 10, z - 10, x - 10, z + 10, DensityCoordType.POINT_POINT_POINT)
            for filter, state in pairs(weedMapId) do
                local _, state, _ = terrainRootNode:executeGet(filter)
                if state > 0 then
                    _self.weedState = state
                    _self.weedFactor = weedSystem.factors[state] or 0
                    return
                end
            end
        end
    end)
end