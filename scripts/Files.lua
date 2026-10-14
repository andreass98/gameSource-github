Files = {}
local Files_mt = Class(Files)
function Files.new(path)
    -- upvalues: (copy) Files_mt
    local self = setmetatable({}, Files_mt)
    self.path = path
    self.files = {}
    getFiles(path, "fileCallbackFunction", self)
    return self
end
function Files:fileCallbackFunction(filename, isDirectory)
    table.insert(self.files, {
        ["path"] = self.path .. "/" .. filename,
        ["filename"] = filename,
        ["isDirectory"] = isDirectory
    })
end
function Files.getFilesRecursive(path)
    local files = Files.new(path).files
    local i = #files
    for i = i, 1, -1 do
        local file = files[i]
        if file.isDirectory then
            local subFiles = Files.getFilesRecursive(file.path)
            for _, subFile in ipairs(subFiles) do
                table.insert(files, subFile)
            end
        end
    end
    return files
end