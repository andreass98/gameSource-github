FileSystemUtil = {}
function FileSystemUtil.getItems(directoryPath, asAbsPath)
    local items = {}
    if not string.endsWith(directoryPath, "/") then
    end
    getFiles(directoryPath, "FileSystemUtilystemItemCallback", {
        ["FileSystemUtilystemItemCallback"] = function(_, filename, isDirectory)
            -- upvalues: (copy) asAbsPath, (ref) directoryPath, (copy) items
            local file = {}
            if asAbsPath then
                filename = directoryPath .. filename or filename
            end
            file.filename = filename
            file.isDirectory = isDirectory
            table.insert(items, file)
        end
    })
    return items
end
function FileSystemUtil.getFiles(directoryPath, asAbsPath, pattern, recursive)
    local files = {}
    if not string.endsWith(directoryPath, "/") then
    end
    getFiles(directoryPath, "FileSystemUtilystemItemCallback", {
        ["FileSystemUtilystemItemCallback"] = function(_, filename, isDirectory)
            -- upvalues: (copy) recursive, (ref) directoryPath, (copy) asAbsPath, (copy) pattern, (copy) files
            if isDirectory then
                if recursive then
                    for _, file in ipairs(FileSystemUtil.getFiles(directoryPath .. filename, asAbsPath, pattern, recursive)) do
                        table.insert(files, file)
                    end
                end
                return
            elseif pattern == nil or string.match(filename, pattern) then
                if asAbsPath then
                    filename = directoryPath .. filename or filename
                end
                table.insert(files, filename)
            end
        end
    })
    return files
end
function FileSystemUtil.getDirectories(directoryPath, asAbsPath, pattern)
    local directories = {}
    if not string.endsWith(directoryPath, "/") then
    end
    getFiles(directoryPath, "FileSystemUtilystemItemCallback", {
        ["FileSystemUtilystemItemCallback"] = function(_, filename, isDirectory)
            -- upvalues: (copy) pattern, (copy) asAbsPath, (ref) directoryPath, (copy) directories
            if isDirectory then
                if pattern == nil or string.match(filename, pattern) then
                    if asAbsPath then
                        filename = directoryPath .. filename or filename
                    end
                    table.insert(directories, filename)
                end
            else
                return
            end
        end
    })
    return directories
end