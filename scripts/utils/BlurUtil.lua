BlurUtil = {}
function BlurUtil.stackBlur(dataGetter, dataSetter, width, height, radius)
    BlurUtil.stackBlurHorizontal(dataGetter, dataSetter, width, height, radius)
    BlurUtil.stackBlurVertical(dataGetter, dataSetter, width, height, radius)
end
function BlurUtil.stackBlurAsync(dataGetter, dataSetter, width, height, radius, asyncManager, callback)
    asyncManager = asyncManager or g_asyncTaskManager
    local y = 1
    for y = y, height do
        asyncManager:addTask(function()
            -- upvalues: (copy) dataGetter, (copy) dataSetter, (copy) width, (copy) radius, (copy) y
            BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, y)
        end)
    end
    local y = 1
    for y = y, width do
        asyncManager:addTask(function()
            -- upvalues: (copy) dataGetter, (copy) dataSetter, (copy) height, (copy) radius, (copy) y, (copy) width, (copy) callback
            BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, y)
            if y == width then
                callback()
            end
        end)
    end
end
function BlurUtil.stackBlurHorizontal(dataGetter, dataSetter, width, height, radius)
    local y = 1
    for y = y, height do
        BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, y, {})
    end
end
function BlurUtil.stackBlurVertical(dataGetter, dataSetter, width, height, radius)
    local x = 1
    for x = x, width do
        BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, x, {})
    end
end
function BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, y, queue)
    local kernelSize = radius * 2 + 1
    local edgeValue = queue or {}
    local edgeValue = dataGetter(1, y)
    local sum, inSum, outSum = BlurUtil.recalculateBlurQueueAndSums(edgeValue, kernelSize, radius, edgeValue)
    local x = 1
    for x = x, width do
        sum, inSum, outSum, radius = BlurUtil.iterateStackBlur(function(x, y)
            -- upvalues: (copy) dataGetter, (copy) radius, (copy) width
            return dataGetter(math.min(x + radius, width), y)
        end, dataSetter, edgeValue, kernelSize, radius * (radius + 2) + 1, radius, sum, inSum, outSum, radius, x, y)
    end
end
function BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, x, queue)
    local kernelSize = radius * 2 + 1
    local edgeValue = queue or {}
    local edgeValue = dataGetter(x, 1)
    local sum, inSum, outSum = BlurUtil.recalculateBlurQueueAndSums(edgeValue, kernelSize, radius, edgeValue)
    local y = 1
    for y = y, height do
        sum, inSum, outSum, radius = BlurUtil.iterateStackBlur(function(x, y)
            -- upvalues: (copy) dataGetter, (copy) radius, (copy) height
            return dataGetter(x, (math.min(y + radius, height)))
        end, dataSetter, edgeValue, kernelSize, radius * (radius + 2) + 1, radius, sum, inSum, outSum, radius, x, y)
    end
end
function BlurUtil.recalculateBlurQueueAndSums(queue, kernelSize, radius, edgeValue)
    local sum = 0
    local inSum = 0
    local outSum = 0
    local i = 1
    for i = i, kernelSize do
        if i <= radius + 1 then
        end
        queue[i] = edgeValue
    end
    return sum, inSum, outSum
end
function BlurUtil.iterateStackBlur(dataGetter, dataSetter, queue, kernelSize, stackSize, radius, sum, inSum, outSum, queueCounter, x, y)
    dataSetter(x, y, sum / stackSize)
    local queuePosition = queueCounter + kernelSize - radius
    if kernelSize <= queuePosition then
    end
    local currentDatum = dataGetter(x, y)
    queue[queuePosition + 1] = currentDatum
    inSum = inSum + currentDatum
    queueCounter = queueCounter + 1
    queueCounter = kernelSize <= queueCounter and 0 or queueCounter
    return sum - outSum + inSum, inSum - queue[queueCounter + 1], outSum - queue[queuePosition + 1] + queue[queueCounter + 1], queueCounter
end