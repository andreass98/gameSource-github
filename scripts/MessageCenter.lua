MessageCenter = {}
local MessageCenter_mt = Class(MessageCenter)
source("dataS/scripts/MessageType.lua")
function MessageCenter.new(customMt)
    -- upvalues: (copy) MessageCenter_mt
    local self = setmetatable({}, MessageCenter_mt)
    self.subscribers = {}
    self.queue = {}
    return self
end
function MessageCenter:delete() end
function MessageCenter:update(_)
    if #self.queue > 0 then
        local index = 1
        while true do
            local message = self.queue[index]
            if message == nil then
                break
            end
            if message.targetUpdateLoopIndex == nil or g_updateLoopIndex >= message.targetUpdateLoopIndex then
                self:publish(message.messageType, unpack(message.arguments))
                table.remove(self.queue, index)
            end
        end
    end
end
function MessageCenter:subscribe(messageType, callback, callbackTarget, argument, isOneShot)
    if messageType == nil then
        Logging.warning("Tried subscribing to a message with a nil-value message type. Check subscribe() function call arguments at:")
        printCallstack()
        return
    elseif callback == nil then
        Logging.warning("Tried subscribing to a message with a nil-value callback. Check subscribe() function call arguments at:")
        printCallstack()
    else
        local subscribers = assertWithCallstack
        subscribers(type(callback) == "function", "Error: MessageCenter:subscribe(): given argument \'callback\' is not a function")
        local subscribers = self.subscribers[messageType]
        if subscribers == nil then
            self.subscribers[messageType] = {}
        end
        table.insert(subscribers, {
            ["callback"] = callback,
            ["callbackTarget"] = callbackTarget,
            ["argument"] = argument,
            ["isOneShot"] = Utils.getNoNil(isOneShot, false)
        })
    end
end
function MessageCenter:subscribeOneshot(messageType, callback, callbackTarget, argument)
    self:subscribe(messageType, callback, callbackTarget, argument, true)
end
function MessageCenter:unsubscribe(messageType, callbackTarget, callback)
    local subscribers = self.subscribers[messageType]
    if subscribers ~= nil then
        local i = #subscribers
        for i = i, 1, -1 do
            local info = subscribers[i]
            if info.callbackTarget == callbackTarget and (callback == nil or info.callback == callback) then
                table.remove(subscribers, i)
            end
        end
        if #subscribers == 0 then
            self.subscribers[messageType] = nil
        end
    end
end
function MessageCenter:unsubscribeAll(callbackTarget)
    for k, subscribers in pairs(self.subscribers) do
        local i = #subscribers
        for i = i, 1, -1 do
            if subscribers[i].callbackTarget == callbackTarget then
                table.remove(subscribers, i)
            end
        end
        if #subscribers == 0 then
            self.subscribers[k] = nil
        end
    end
end
function MessageCenter:publish(messageType, ...)
    if messageType == nil then
        Logging.warning("Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
        printCallstack()
    else
        local subscribers = self.subscribers[messageType]
        if subscribers ~= nil then
            local i = 1
            while true do
                local info = subscribers[i]
                if info == nil then
                    break
                end
                if info.callbackTarget == nil then
                    if info.argument == nil then
                        info.callback(...)
                    else
                        info.callback(info.argument, ...)
                    end
                elseif info.argument == nil then
                    info.callback(info.callbackTarget, ...)
                else
                    info.callback(info.callbackTarget, info.argument, ...)
                end
                if info.isOneShot then
                    table.remove(subscribers, i)
                end
            end
        end
    end
end
function MessageCenter:publishDelayed(messageType, ...)
    if messageType == nil then
        Logging.warning("Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
        printCallstack()
    else
        self:publishDelayedAfterFrames(messageType, 1, ...)
    end
end
function MessageCenter:publishDelayedAfterFrames(messageType, numFrames, ...)
    if messageType == nil then
        Logging.warning("Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
        printCallstack()
    else
        table.insert(self.queue, {
            ["messageType"] = messageType,
            ["targetUpdateLoopIndex"] = g_updateLoopIndex + numFrames,
            ["arguments"] = { ... }
        })
    end
end
function MessageCenter:drawDebug()
    for messageName, time in pairs(self.debugLastMessages) do
        if time + 5000 < g_time then
            self.debugLastMessages[messageName] = nil
        end
    end
    local sorted = table.toList(self.debugLastMessages)
    table.sort(sorted, function(a, b)
        -- upvalues: (copy) self
        return self.debugLastMessages[a] > self.debugLastMessages[b]
    end)
    setTextBold(true)
    renderText(0.5, 0.8, 0.016, "recently published messages:")
    setTextBold(false)
    for i, messageName in ipairs(sorted) do
        local yOffset = 0.8 - i * 0.016
        renderText(0.45, yOffset, 0.016, messageName)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(0.44, yOffset, 0.016, string.format("%d", g_time - self.debugLastMessages[messageName]))
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end
function MessageCenter:consoleCommandPrintActiveSubscribers()
    local messageCount = 0
    local subscriberCount = 0
    for messageType, subscribers in pairs(self.subscribers) do
        local messageName = nil
        if type(messageType) == "number" then
            for k, v in pairs(MessageType) do
                if v == messageType then
                    messageName = k
                    break
                end
            end
            if messageName == nil then
                for k, v in pairs(MessageType.SETTING_CHANGED) do
                    if v == messageType then
                        for name, setting in pairs(GameSettings.SETTING) do
                            if k == setting then
                                messageName = name
                                break
                            end
                        end
                        break
                    end
                end
            end
        else
            messageName = ClassUtil.getClassName(messageType)
        end
        if messageName == nil then
            messageName = type(messageType) .. " " .. tostring(messageType)
        end
        log("Message Subscribers for \'" .. messageName .. "\':")
        for k, v in ipairs(subscribers) do
            local target = v.callbackTarget
            if target ~= nil then
                target = ClassUtil.getClassNameByObject(target)
            end
            log("    ", target or (v.callback or "Unknown"))
        end
    end
    log("\n Total Messages:" .. messageCount)
    log("Total Subscribers: " .. subscriberCount)
end
function MessageCenter:consoleCommandDrawMessages()
    self.debugDrawLastMessages = not self.debugDrawLastMessages
    if self.debugDrawLastMessages then
        self.debugLastMessages = {}
        g_debugManager:addDrawable(self)
    else
        g_debugManager:removeDrawable(self)
        self.debugLastMessages = nil
    end
    return string.format("drawLastMessages=%s", self.debugDrawLastMessages)
end