FindOverlayLeaks = {}
FindOverlayLeaks.overlays = {}
FindOverlayLeaks.guiElements = {}
function FindOverlayLeaks.init()
    if StartParams.getIsSet("findOverlayLeaks") then
        local oldOverlayCreate = createImageOverlay
        function createImageOverlay(filename, sliceId, ...)
            -- upvalues: (copy) oldOverlayCreate
            local id = oldOverlayCreate(filename, ...)
            if id ~= 0 then
                local sliceIdText = ""
                if sliceId ~= nil then
                    sliceIdText = " Slice id: " .. sliceId
                end
                FindOverlayLeaks.overlays[id] = filename .. sliceIdText .. "\nTrace:\n" .. debug.traceback()
            end
            return id
        end
        local guiNew = GuiElement.new
        function GuiElement.new(...)
            -- upvalues: (copy) guiNew
            local instance = guiNew(...)
            FindOverlayLeaks.guiElements[instance] = ClassUtil.getClassNameByObject(instance) .. "\nTrace:\n" .. debug.traceback()
            return instance
        end
        local guiDelete = GuiElement.delete
        function GuiElement.delete(instance, ...)
            -- upvalues: (copy) guiDelete
            FindOverlayLeaks.guiElements[instance] = nil
            guiDelete(instance, ...)
        end
        local oldDelete = delete
        function delete(id)
            -- upvalues: (copy) oldDelete
            oldDelete(id)
            FindOverlayLeaks.overlays[id] = nil
        end
        printWarning("Warning: FindOverlayLeaks is active!")
    end
end
function FindOverlayLeaks.printUndeletedOverlays()
    if StartParams.getIsSet("findOverlayLeaks") then
        if next(FindOverlayLeaks.overlays) ~= nil then
            setFileLogPrefixTimestamp(false)
            printError("FindOverlayLeaks: Undeleted overlays\n\n")
            for id, fileNameAndTrace in pairs(FindOverlayLeaks.overlays) do
                print(fileNameAndTrace)
                print("\n\n")
            end
            setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
        end
        if next(FindOverlayLeaks.guiElements) ~= nil then
            setFileLogPrefixTimestamp(false)
            printError("FindOverlayLeaks: Undeleted gui elements\n\n")
            for id, fileNameAndTrace in pairs(FindOverlayLeaks.guiElements) do
                print(fileNameAndTrace)
                print("\n\n")
            end
            setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
        end
    end
end