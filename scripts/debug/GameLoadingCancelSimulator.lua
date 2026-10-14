GameLoadingCancelSimulator = {}
GameLoadingCancelSimulator.ACTIVE = false
function GameLoadingCancelSimulator.init()
    local cancelStep = StartParams.getValue("gameLoadingCancelSimulator")
    if cancelStep ~= nil then
        GameLoadingCancelSimulator.ACTIVE = true
        StartParams.setValue("autoStartSavegameId", 1)
        local cancelStep = tonumber(cancelStep) or 1
        local startStep = cancelStep
        local stepIndex = 0
        local lastMemCycle = 0
        function cancel()
            -- upvalues: (ref) cancelStep, (ref) stepIndex, (ref) lastMemCycle
            cancelStep = cancelStep + 1
            stepIndex = 0
            g_mpLoadingScreen:cancelLoading(false)
            local mem = collectgarbage("count")
            collectgarbage("collect")
            local memAfter = collectgarbage("count")
            log(string.format(" -- CANCEL (%d) -- Collected %.1f kB -- Increase: %.1f kB", cancelStep, mem - memAfter, memAfter - lastMemCycle))
            if g_pendingRestartData == nil then
                autoStartLocalSavegame(1)
            end
        end
        local oldRun = AsyncTaskManager.runLambda
        function AsyncTaskManager:runLambda(lambda)
            -- upvalues: (ref) stepIndex, (copy) oldRun, (ref) cancelStep
            stepIndex = stepIndex + 1
            oldRun(self, lambda)
            if cancelStep < stepIndex then
                cancel()
            end
        end
        local oldDraw = draw
        function draw()
            -- upvalues: (copy) oldDraw, (copy) startStep, (ref) cancelStep, (ref) stepIndex
            oldDraw()
            local text = string.format("GameLoadingCancelSimulator\nStart Step: %d\nCancel Step: %d\nCurrent Step: %d", startStep, cancelStep, stepIndex)
            setTextAlignment(RenderText.ALIGN_CENTER)
            setTextColor(0, 0, 0, 1)
            renderText(0.5, 0.5, 0.05, text)
            setTextColor(1, 1, 1, 1)
            renderText(0.5 + 2 * g_pixelSizeX, 0.5 + 2 * g_pixelSizeY, 0.05, text)
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
        local oldRestart = doRestart
        function doRestart(restartProcess, args)
            -- upvalues: (copy) oldRestart, (ref) cancelStep
            oldRestart(restartProcess, args)
            g_pendingRestartData.args = string.format("-gameLoadingCancelSimulator %d", cancelStep)
        end
    end
end