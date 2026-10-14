Profiler = {}
Profiler.IS_INITIALIZED = false
Profiler.IS_READY = false
Profiler.IS_GRID_INITIALIZED = false
Profiler.IS_GRID_FINISHED = false
Profiler.IS_FINISHED = false
Profiler.IS_GPU_BENCHMARK_MODE = false
Profiler.MAP = ""
Profiler.MAP_FILENAME = ""
Profiler.OUTPUT_FILENAME = ""
Profiler.SAMPLING_GRID_SIZE = -1
Profiler.SAMPLING_CUSTOM_NODE = ""
Profiler.MAP_ROOT_NODE = {}
Profiler.PROFILING_ROOT_NODE = {}
Profiler.CURRENT_NODE_ID = 0
Profiler.NUM_NODES = 0
Profiler.GRID_CURRENT_X = 0
Profiler.GRID_CURRENT_Z = 0
Profiler.GRID_CURRENT_ROTATION = 0
Profiler.GRID_ROTATION_DELTA = 1.5707963267948966
Profiler.GRID_ROTATION_NUM_STEPS = 4
Profiler.CAMERA = nil
Profiler.FRAME_COUNT = 0
Profiler.INITIAL_FRAMES_PAUSED = 0
Profiler.STARTUP_FRAME_PAUSE = 500
Profiler.FRAMES_BETWEEN_SAMPLES = 20
Profiler.SAVEGAME_NUMBER = 3
Profiler.MAP_SIZE = 0
function Profiler.init()
    if Profiler.IS_INITIALIZED then
        return
    end
    if not StartParams.getIsSet("profilerStatsMap") then
        return
    end
    if not StartParams.getIsSet("profilerStatsOutputPath") then
        return
    end
    local filename = Profiler
    if StartParams.getIsSet("profilerStatsSavegameSlot") then
        dedicatedVramInMB = tonumber(StartParams.getValue("profilerStatsSavegameSlot"))
        if dedicatedVramInMB then
            goto l9
        end
    end
    local dedicatedVramInMB = Profiler.SAVEGAME_NUMBER
    ::l9::
    filename.SAVEGAME_NUMBER = dedicatedVramInMB
    Profiler.OUTPUT_DIRECTORY = StartParams.getValue("profilerStatsOutputPath")
    Profiler.IS_GPU_BENCHMARK_MODE = StartParams.getIsSet("profilerGpuBenchmarkMode")
    if Profiler.IS_GPU_BENCHMARK_MODE then
        Profiler.GRID_ROTATION_DELTA = 0.02617993877991494
        Profiler.GRID_ROTATION_NUM_STEPS = 240
        local filename = StartParams.getValue("gpuBenchmarkOutputFile")
        Profiler.OUTPUT_FILENAME = Profiler.OUTPUT_DIRECTORY .. "/" .. filename
        if StartParams.getIsSet("profilerGpuBenchmarOnly6GBVram") then
            local dedicatedVramInMB = profilerGetCurrentGpuVRAM()
            if dedicatedVramInMB > 0 and dedicatedVramInMB < 5120 then
                Logging.info("Skip benchmark, " .. getGPUName() .. " do not have 6GB ore more VRAM ")
                profilerWriteGpuBenchmarkStats(Profiler.OUTPUT_FILENAME)
                doExit()
            end
        end
        if StartParams.getIsSet("gpuBenchmarkMinSpecsGpu") and profilerGetGpuPerformanceRating(getGPUName()) < profilerGetGpuPerformanceRating(StartParams.getValue("gpuBenchmarkMinSpecsGpu")) then
            Logging.info("Skip benchmark, " .. getGPUName() .. " is bellow the min specs GPU " .. StartParams.getValue("gpuBenchmarkMinSpecsGpu"))
            profilerWriteGpuBenchmarkStats(Profiler.OUTPUT_FILENAME)
            doExit()
            return
        end
    end
    if folderExists(Profiler.OUTPUT_DIRECTORY) then
        Profiler.MAP = StartParams.getValue("profilerStatsMap")
        Profiler.MAP_FILENAME = StartParams.getValue("profilerStatsMapFilename") or "default"
        local filename = false
        if StartParams.getIsSet("profilerStatsSamplingGridSize") then
            local dedicatedVramInMB = tonumber(StartParams.getValue("profilerStatsSamplingGridSize"))
            if dedicatedVramInMB == nil or dedicatedVramInMB <= 0 then
                Logging.error("Invalid \'profilerStatsSamplingGridSize\' parameter")
                return
            end
            local gridSizeBest = nil
            local delta = math.huge
            local i = 4
            for i = i, 15 do
                local deltaNew = math.pow(2, i)
                local deltaNew = math.abs(dedicatedVramInMB - deltaNew)
                if deltaNew < delta then
                    gridSizeBest = deltaNew
                    delta = deltaNew
                end
            end
            if delta ~= 0 then
                Logging.warning("Grid size \'%s\' was not a power of 2, changed to \'%s\'!", dedicatedVramInMB, gridSizeBest)
            end
            Profiler.SAMPLING_GRID_SIZE = gridSizeBest
            filename = true
        end
        if StartParams.getIsSet("profilerStatsSamplingCustomNode") then
            Profiler.SAMPLING_CUSTOM_NODE = StartParams.getValue("profilerStatsSamplingCustomNode")
            filename = true
        end
        if filename then
            Profiler.CAMERA = createCamera("cameraProfiler", 1.0471975511965976, 1, 10000)
            g_cameraManager:addCamera(Profiler.CAMERA, nil, false)
            link(getRootNode(), Profiler.CAMERA)
            Logging.info("Profiler initialized successfully")
            Profiler.IS_INITIALIZED = true
        else
            Logging.error("Profiler needs \'profilerStatsSamplingGridSize\' or \'profilerStatsSamplingCustomNode\' parameter set")
        end
    else
        Logging.error("Unable to write to profilerStatsOutputPath %q. Is it an absolute path and does the directory exist?", getAppBasePath() .. Profiler.OUTPUT_DIRECTORY)
        return
    end
end
function Profiler.delete()
    if Profiler.CAMERA ~= nil then
        if g_cameraManager:getActiveCamera() == Profiler.CAMERA then
            g_cameraManager:setDefaultCamera()
        end
        g_cameraManager:removeCamera(Profiler.CAMERA)
        delete(Profiler.CAMERA)
        Profiler.CAMERA = nil
    end
end
function Profiler.startProfiler()
    if Profiler.IS_INITIALIZED then
        Logging.info("######################### Starting Profiler #########################")
        g_gui:setIsMultiplayer(false)
        g_gui:showGui("CareerScreen")
    end
end
function Profiler.setMapRootNode(node)
    Profiler.MAP_ROOT_NODE = node
    if Profiler.SAMPLING_CUSTOM_NODE ~= "" then
        Profiler.PROFILING_ROOT_NODE = getChild(node, Profiler.SAMPLING_CUSTOM_NODE)
        if Profiler.PROFILING_ROOT_NODE == 0 then
            Profiler.IS_INITIALIZED = false
            Logging.error("Profiler SamplingCustomNode \'%s\' not found", Profiler.SAMPLING_CUSTOM_NODE)
            return
        end
        Profiler.NUM_NODES = getNumOfChildren(Profiler.PROFILING_ROOT_NODE)
    end
    if Profiler.IS_GPU_BENCHMARK_MODE or not Profiler.IS_INITIALIZED then
        return
    elseif profilerStatsExportInit() then
        local mapName = ""
        if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil then
            mapName = tostring(g_currentMission.missionInfo.mapId)
        end
        local profileName = Utils.getDirectoryName(getUserProfileAppPath())
        profilerStatsExportAddMetadata("map", mapName)
        profilerStatsExportAddMetadata("mapWidth", (tostring(g_currentMission.mapWidth)))
        profilerStatsExportAddMetadata("mapHeight", (tostring(g_currentMission.mapHeight)))
        profilerStatsExportAddMetadata("date", getDate("%Y-%m-%dT%H:%M:%SZ"))
        profilerStatsExportAddMetadata("revision", getEngineRevision())
        profilerStatsExportAddMetadata("defaultNodeType", "grid")
        profilerStatsExportAddMetadata("appName", profileName)
        Profiler.OUTPUT_FILENAME = Profiler.OUTPUT_DIRECTORY .. "/" .. getDate("%Y-%m-%d_%H-%M-%S") .. "_" .. profileName .. "_" .. mapName .. ".json"
    else
        Logging.error("Profiler stats export could not be initialized engine side")
        Profiler.IS_INITIALIZED = false
    end
end
function Profiler.setIsReady()
    Profiler.IS_READY = true
end
function Profiler.update(dt)
    if Profiler.IS_READY then
        setFramerateLimiter(false, Platform.defaultFrameLimit)
        if Profiler.IS_GRID_INITIALIZED then
            if Profiler.INITIAL_FRAMES_PAUSED <= Profiler.STARTUP_FRAME_PAUSE then
                Profiler.INITIAL_FRAMES_PAUSED = Profiler.INITIAL_FRAMES_PAUSED + 1
                return
            end
            if Profiler.IS_GRID_FINISHED or (Profiler.FRAME_COUNT <= Profiler.FRAMES_BETWEEN_SAMPLES or Profiler.SAMPLING_GRID_SIZE <= 0) then
                if Profiler.FRAME_COUNT > Profiler.FRAMES_BETWEEN_SAMPLES and Profiler.NUM_NODES > 0 then
                    if Profiler.CURRENT_NODE_ID == Profiler.NUM_NODES then
                        Profiler.finish()
                    else
                        if Profiler.CURRENT_NODE_ID > 0 and not Profiler.IS_GPU_BENCHMARK_MODE then
                            local x, z, rotY = getRotation(Profiler.CAMERA)
                            profilerStatsExportAddSampleBegin()
                            profilerStatsExportAddSampleData("rotX", (tostring(x * 180 / 3.141592653589793)))
                            profilerStatsExportAddSampleData("rotY", (tostring(z * 180 / 3.141592653589793)))
                            profilerStatsExportAddSampleData("rotZ", (tostring(rotY * 180 / 3.141592653589793)))
                            profilerStatsExportAddSampleData("type", "custom")
                            profilerStatsExportAddSampleEnd()
                        end
                        local x = getChildAt(Profiler.PROFILING_ROOT_NODE, Profiler.CURRENT_NODE_ID)
                        local z, rotY, y = getWorldTranslation(x)
                        local rotX, rotY, rotZ = getWorldRotation(x)
                        setTranslation(Profiler.CAMERA, z, rotY, y)
                        setRotation(Profiler.CAMERA, rotX, rotY, rotZ)
                        Profiler.CURRENT_NODE_ID = Profiler.CURRENT_NODE_ID + 1
                        Profiler.FRAME_COUNT = 0
                    end
                elseif Profiler.IS_GRID_FINISHED and Profiler.NUM_NODES == 0 then
                    Profiler.finish()
                else
                    Profiler.FRAME_COUNT = Profiler.FRAME_COUNT + 1
                end
            end
            if not Profiler.IS_GPU_BENCHMARK_MODE then
                profilerStatsExportAddSampleBegin()
                profilerStatsExportAddSampleData("rotY", (tostring(Profiler.GRID_CURRENT_ROTATION * 90)))
                profilerStatsExportAddSampleEnd()
            end
            local x = Profiler.GRID_CURRENT_X - Profiler.MAP_SIZE * 0.5
            local z = Profiler.GRID_CURRENT_Z - Profiler.MAP_SIZE * 0.5
            local rotY = Profiler.GRID_CURRENT_ROTATION * Profiler.GRID_ROTATION_DELTA
            if Profiler.IS_GPU_BENCHMARK_MODE then
                profilerGpuBenchmarkSample()
            end
            local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 1.8
            setTranslation(Profiler.CAMERA, x, y, z)
            setRotation(Profiler.CAMERA, 0, rotY, 0)
            Profiler.GRID_CURRENT_ROTATION = Profiler.GRID_CURRENT_ROTATION + 1
            if Profiler.GRID_CURRENT_ROTATION == Profiler.GRID_ROTATION_NUM_STEPS then
                Profiler.GRID_CURRENT_ROTATION = 0
                Profiler.GRID_CURRENT_X = Profiler.GRID_CURRENT_X + Profiler.SAMPLING_GRID_SIZE
                if Profiler.GRID_CURRENT_X > Profiler.MAP_SIZE then
                    Profiler.GRID_CURRENT_X = Profiler.SAMPLING_GRID_SIZE * 0.5
                    Profiler.GRID_CURRENT_Z = Profiler.GRID_CURRENT_Z + Profiler.SAMPLING_GRID_SIZE
                    if Profiler.GRID_CURRENT_Z > Profiler.MAP_SIZE then
                        if not Profiler.IS_GPU_BENCHMARK_MODE then
                            profilerStatsExportAddSampleBegin()
                            profilerStatsExportAddSampleData("rotY", (tostring(Profiler.GRID_CURRENT_ROTATION * 90)))
                            profilerStatsExportAddSampleEnd()
                        end
                        Profiler.IS_GRID_FINISHED = true
                    end
                end
                if Profiler.IS_GPU_BENCHMARK_MODE then
                    Profiler.FRAME_COUNT = 0
                    g_currentMission.environment:consoleCommandSetDayTime(8, true)
                end
            end
            if not Profiler.IS_GPU_BENCHMARK_MODE then
                Profiler.FRAME_COUNT = 0
                return
            end
        else
            g_cameraManager:setActiveCamera(Profiler.CAMERA)
            Profiler.MAP_SIZE = g_currentMission.mapHeight
            if Profiler.IS_GPU_BENCHMARK_MODE then
                Profiler.MAP_SIZE = Profiler.MAP_SIZE * 0.666
            end
            if Profiler.SAMPLING_GRID_SIZE > 0 then
                Profiler.GRID_CURRENT_X = Profiler.SAMPLING_GRID_SIZE * 0.5
                Profiler.GRID_CURRENT_Z = Profiler.SAMPLING_GRID_SIZE * 0.5
                local x = Profiler.GRID_CURRENT_X - Profiler.MAP_SIZE * 0.5
                local z = Profiler.GRID_CURRENT_Z - Profiler.MAP_SIZE * 0.5
                local rotY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 1.8
                setTranslation(Profiler.CAMERA, x, rotY, z)
                setRotation(Profiler.CAMERA, 0, 0, 0)
                Profiler.IS_GRID_INITIALIZED = true
            end
            Profiler.IS_READY = true
        end
    end
end
function Profiler.finish()
    Profiler.IS_FINISHED = true
    if not Profiler.IS_GPU_BENCHMARK_MODE and profilerStatsExportFinalize(Profiler.OUTPUT_FILENAME) then
        Logging.info("saved profiler output to %q", getAppBasePath() .. Profiler.OUTPUT_FILENAME)
    end
    if Profiler.IS_GPU_BENCHMARK_MODE and profilerWriteGpuBenchmarkStats(Profiler.OUTPUT_FILENAME) then
        Logging.info("saved GPU benchmark output to %q", getAppBasePath() .. Profiler.OUTPUT_FILENAME)
    end
    Logging.info("######################### Profiler Finished #########################")
    doExit()
end