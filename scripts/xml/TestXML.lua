TestXML = {}
function TestXML.init()
    local xmlFile = nil
    local time = nil
    local output = nil
    xmlFile = XMLFile.load("testXml", "../tools/studio/Farming_Simulator_25_Dev.xml")
    time = 0
    output = {}
    for i = 0, 200 do
        local timer = openIntervalTimer()
        xmlFile:iterate("scriptBinding.function", function(_, functionPath)
            -- upvalues: (ref) output, (ref) xmlFile
            table.insert(output, xmlFile:getString(functionPath .. "#name"))
            xmlFile:iterate(functionPath .. ".input.param", function(_, paramPath)
                -- upvalues: (ref) output, (ref) xmlFile
                table.insert(output, xmlFile:getString(paramPath .. "#type"))
            end)
        end)
        time = time + readIntervalTimerMs(timer)
        closeIntervalTimer(timer)
    end
    log(time, "closure", "numOuputs", #output)
    xmlFile:delete()
    xmlFile = XMLFile.load("testXml", "../tools/studio/Farming_Simulator_25_Dev.xml")
    time = 0
    output = {}
    for i = 0, 200 do
        local timer = openIntervalTimer()
        for _, functionPath in xmlFile:iterator("scriptBinding.function") do
            local paramPath = functionPath .. "#name"
            table.insert(output, xmlFile:getString(paramPath))
            for _, paramPath in xmlFile:iterator(functionPath .. ".input.param") do
                table.insert(output, xmlFile:getString(paramPath .. "#type"))
            end
        end
        time = time + readIntervalTimerMs(timer)
        closeIntervalTimer(timer)
    end
    log(time, "iterator", "numOuputs", #output)
    xmlFile:delete()
    xmlFile = XMLFile.load("testXml", "../tools/studio/Farming_Simulator_25_Dev.xml")
    time = 0
    output = {}
    for i = 0, 200 do
        local timer = openIntervalTimer()
        for _, functionPath, elementName in xmlFile:iteratorChildren("scriptBinding") do
            if elementName == "function" then
                local paramPath = functionPath .. "#name"
                table.insert(output, xmlFile:getString(paramPath))
                for paramPath, paramPath, elementName in xmlFile:iteratorChildren(functionPath .. ".input") do
                    table.insert(output, xmlFile:getString(paramPath .. "#type"))
                end
            end
        end
        time = time + readIntervalTimerMs(timer)
        closeIntervalTimer(timer)
    end
    log(time, "iteratorChildren", "numOuputs", #output)
    xmlFile:delete()
end
function TestXML.update(dt) end
function TestXML.draw() end
function TestXML.mouseEvent(posX, posY, isDown, isUp, button) end
function TestXML.keyEvent(unicode, sym, modifier, isDown) end