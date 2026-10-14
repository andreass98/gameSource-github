TireTrackSystem = {}
local TireTrackSystem_mt = Class(TireTrackSystem)
TireTrackSystem.maxNumTracks = 512
TireTrackSystem.maxNumSegments = 4096
TireTrackSystem.atlasSize = 32
function TireTrackSystem.onCreateTireTrackSystem(_, id)
    if g_currentMission.tireTrackSystem == nil then
        local tireTrackSystem = TireTrackSystem.new()
        if tireTrackSystem:load(id) then
            g_currentMission.tireTrackSystem = tireTrackSystem
        else
            tireTrackSystem:delete()
        end
    else
        return
    end
end
function TireTrackSystem.new(mt)
    -- upvalues: (copy) TireTrackSystem_mt
    local self = setmetatable({}, mt or TireTrackSystem_mt)
    self.tireTrackSystemId = 0
    return self
end
function TireTrackSystem:load(id)
    self.tireTrackSystemId = createTyreTrackSystem(getRootNode(), id, TireTrackSystem.maxNumTracks, TireTrackSystem.maxNumSegments, TireTrackSystem.atlasSize, g_terrainNode)
    if g_addTestCommands then
        addConsoleCommand("gsTireTracksRemoveAll", "Remove all tire tracks from terrain", "TireTrackSystem.consoleCommandRemoveAllTireTracks", nil)
        addConsoleCommand("gsTireTracksDebug", "Toggle tire track debug mode with permanently active and colored tracks", "TireTrackSystem.consoleCommandTireTrackDebug", nil)
    end
    return self.tireTrackSystemId ~= 0
end
function TireTrackSystem:delete()
    if self.tireTrackSystemId ~= 0 then
        delete(self.tireTrackSystemId)
    end
    removeConsoleCommand("gsTireTracksRemoveAll")
    removeConsoleCommand("gsTireTracksDebug")
end
function TireTrackSystem:createTrack(width, atlasIndex)
    return createTrack(self.tireTrackSystemId, width, atlasIndex)
end
function TireTrackSystem:destroyTrack(id)
    destroyTrack(self.tireTrackSystemId, id)
end
function TireTrackSystem:addTrackPoint(id, x, y, z, upX, upY, upZ, r, g, b, a, bumpiness, wheelDirection, renderOnTerrainOnly, colorBlendWithTerrain)
    addTrackPoint(self.tireTrackSystemId, id, x, y, z, upX, upY, upZ, r, g, b, a, bumpiness, wheelDirection, renderOnTerrainOnly, colorBlendWithTerrain)
end
function TireTrackSystem:cutTrack(id)
    cutTrack(self.tireTrackSystemId, id)
end
function TireTrackSystem:eraseParallelogram(x0, z0, dx1, dz1, dx2, dz2)
    eraseParallelogram(self.tireTrackSystemId, x0, z0, dx1, dz1, dx2, dz2)
end
function TireTrackSystem:erasePolygon(vertexPositionsXZ)
    erasePolygon(self.tireTrackSystemId, vertexPositionsXZ)
end
function TireTrackSystem:consoleCommandRemoveAllTireTracks()
    if g_currentMission.tireTrackSystem ~= nil then
        local halfSize = g_currentMission.terrainSize / 2 + 1
        g_currentMission.tireTrackSystem:eraseParallelogram(-halfSize, -halfSize, halfSize, -halfSize, -halfSize, halfSize)
        executeConsoleCommand("vtRedrawAll")
        return "Removed all tiretracks!"
    end
    printError("Error: no tireTrackSystem found!")
end
function TireTrackSystem:consoleCommandTireTrackDebug()
    if g_currentMission.tireTrackSystem == nil then
        return "Error: no tireTrackSystem found!"
    elseif self.addTrackPointFuncBackup == nil then
        self.addTrackPointFuncBackup = addTrackPoint
        function addTrackPoint(tireTrackSystemId, id, x, y, z, upX, upY, upZ, _, _, _, a, bumpiness, wheelDirection, renderOnTerrainOnly, colorBlendWithTerrain)
            -- upvalues: (copy) self
            local r, g, b = DebugUtil.getDebugColor(id):unpack()
            self.addTrackPointFuncBackup(tireTrackSystemId, id, x, y, z, upX, upY, upZ, r, g, b, a, bumpiness, wheelDirection, renderOnTerrainOnly, colorBlendWithTerrain)
        end
        return "Enabled TireTrack debug"
    else
        addTrackPoint = self.addTrackPointFuncBackup
        self.addTrackPointFuncBackup = nil
        return "Disabled TireTrack debug"
    end
end