io = {}
local io_mt = Class(io)
function io.open(filename, options)
    -- upvalues: (copy) io_mt
    if options ~= "w" then
        printWarning("Warning: io.open, only write mode (\'w\') is allowed")
    end
    local fileId = createFile(filename, FileAccess.WRITE)
    if fileId == 0 then
        return nil
    end
    local self = setmetatable({}, io_mt)
    self.fileId = fileId
    return self
end
function io:close()
    delete(self.fileId)
    self.fileId = 0
end
function io:write(...)
    local i = 1
    for i = i, select("#", ...) do
        fileWrite(self.fileId, (tostring(select(i, ...))))
    end
end
function io:flush() end