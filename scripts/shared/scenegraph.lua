function translate(name, dx, dy, dz)
    local x, y, z = getTranslation(name)
    setTranslation(name, x + dx, y + dy, z + dz)
end
function rotate(name, dx, dy, dz)
    local x, y, z = getRotation(name)
    setRotation(name, (x + dx) % 6.283185307179586, (y + dy) % 6.283185307179586, (z + dz) % 6.283185307179586)
end
function toggleVisibility(name)
    local state = getVisibility(name)
    setVisibility(name, not state)
end
function printScenegraph(node, visibleOnly)
    printScenegraphRec(node, 0, visibleOnly)
end
function printScenegraphRec(node, level, visibleOnly)
    local ident = ""
    local i = 1
    for i = i, level do

    end
    if visibleOnly == nil or (not visibleOnly or visibleOnly and getVisibility(node)) then
        print(string.format("%s%s(%d) | %s", ident, getName(node), node, (tostring(getVisibility(node)))))
        local i = 0
        local i = 1
        for i = i, getNumOfChildren(node) - 1, i do
            printScenegraphRec(getChildAt(node, i), level + 1)
        end
    end
end
function getNodeClassNamesString(node)
    local className = nil
    for classNameToCheck, classId in pairs(ClassIds) do
        if getHasClassId(node, classId) then
            if className == nil then
                className = classNameToCheck
            end
        end
    end
    return className
end
function printNodeInfo(node)
    if node == nil or (node == 0 or not entityExists(node)) then
        print("printNodeInfo: invalid node")
        return
    else
        local classNames = getNodeClassNamesString(node)
        if classNames == nil then
            print("printNodeInfo: invalid node")
        else
            local transX, transY, transZ = getTranslation(node)
            local worldTransX, worldTransY, worldTransZ = getWorldTranslation(node)
            local rotX, rotY, rotZ = getRotation(node)
            local scaleX = math.deg(rotX)
            local scaleX = math.deg(rotY)
            local scaleX = math.deg(rotZ)
            local scaleX, scaleY, scaleZ = getScale(node)
            local visibility = getVisibility(node)
            local effectiveVisibility = getEffectiveVisibility(node)
            print(string.format("Node info for \'%s\' (%d):", getName(node), node))
            print(string.format("  Type(s):             %s", classNames))
            print(string.format("  Path:                %s", getNodeFullPath(node)))
            if getParent(node) == getRootNode() then
                print(string.format("  Translation (world): %.4f %.4f %.4f", worldTransX, worldTransY, worldTransZ))
            else
                print(string.format("  Translation:         %.4f %.4f %.4f", transX, transY, transZ))
                print(string.format("  Translation (world): %.4f %.4f %.4f", worldTransX, worldTransY, worldTransZ))
            end
            print(string.format("  Rotation (deg):      %.4f %.4f %.4f", scaleX, scaleX, scaleX))
            print(string.format("  Scale:               %.4f %.4f %.4f", scaleX, scaleY, scaleZ))
            print(string.format("  Visibility:          %s%s", tostring(visibility), visibility and not effectiveVisibility and " (overall: false)" or ""))
        end
    end
end
function printNodeInfoShort(node)
    if node == nil or (node == 0 or not entityExists(node)) then
        print("NODEINFO|invalid")
        return
    else
        local classNames = getNodeClassNamesString(node)
        if classNames == nil then
            print("NODEINFO|invalid")
        else
            local transX, transY, transZ = getTranslation(node)
            local worldTransX, worldTransY, worldTransZ = getWorldTranslation(node)
            local rotX, rotY, rotZ = getRotation(node)
            local scaleX = math.deg(rotX)
            local scaleX = math.deg(rotY)
            local scaleX = math.deg(rotZ)
            local scaleX, scaleY, scaleZ = getScale(node)
            local visibility = getVisibility(node)
            local effectiveVisibility = getEffectiveVisibility(node)
            local path = string.gsub(getNodeFullPath(node), "|", ",")
            local info = ((((("NODEINFO" .. string.format("|id=%d", node)) .. string.format("|name=%s", getName(node))) .. string.format("|type=%s", classNames)) .. string.format("|path=%s", path)) .. string.format("|translation=%.4f,%.4f,%.4f", transX, transY, transZ)) .. string.format("|worldTranslation=%.4f,%.4f,%.4f", worldTransX, worldTransY, worldTransZ)
            local info = ((((info .. string.format("|parentToWorld=%s", (tostring(getParent(node) == getRootNode())))) .. string.format("|rotation=%.4f,%.4f,%.4f", scaleX, scaleX, scaleX)) .. string.format("|scale=%.4f,%.4f,%.4f", scaleX, scaleY, scaleZ)) .. string.format("|visibility=%s", (tostring(visibility)))) .. string.format("|effectiveVisibility=%s", (tostring(effectiveVisibility)))
            print(info)
        end
    end
end
function printFullPath(node, str)
    str = string.format("|%s%s", getName(node), getVisibility(node) and "" or "(hidden)") .. (str or "")
    if getParent(node) == 0 then
        print(str)
    else
        printFullPath(getParent(node), str)
    end
end
function getNodeFullPath(node, str)
    str = "|" .. getName(node) .. (str or "")
    local parent = getParent(node)
    if parent == 0 then
        return str
    else
        return getNodeFullPath(parent, str)
    end
end
function exportScenegraphToGraphviz(node, filename)
    if node ~= nil and node ~= 0 then
        if filename == nil then
            filename = string.format("%s_output.gv", getName(node))
        end
        local fileId = createFile(filename, FileAccess.WRITE)
        local result = string.format("%s// Start Node is \'%s_(%d)\'\n", "// Scenegraph export for Graphviz\n", getName(node), node)
        local result = string.format("%sdigraph G {\n", result)
        local result = string.format("%s%s_%d  [shape=box,color=red,style=filled]\n", result, getName(node), node)
        local result = exportScenegraphToGraphvizRec(node, result)
        local result = string.format("%s\n}", result)
        fileWrite(fileId, result)
        delete(fileId)
    end
end
function exportScenegraphToGraphvizRec(node, result)
    local i = 0
    for i = i, getNumOfChildren(node) - 1 do
        local child = getChildAt(node, i)
        result = string.format("%s %s_%d -> %s_%d\n", result, string.gsub(getName(node), "[%(%)]", "_"), node, string.gsub(getName(child), "[%(%)]", "_"), child)
        result = exportScenegraphToGraphvizRec(getChildAt(node, i), result)
    end
    return result
end