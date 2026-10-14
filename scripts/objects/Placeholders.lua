Placeholders = {}
function Placeholders.onCreate(_, node)
    local i = getNumOfChildren(node) - 1
    for i = i, 0, -1 do
        delete(getChildAt(node, i))
    end
end