ShipSystem = {}
local ShipSystem_mt = Class(ShipSystem)
function ShipSystem.new(customMt)
    -- upvalues: (copy) ShipSystem_mt
    local self = setmetatable({}, customMt or ShipSystem_mt)
    self.splines = {}
    self.crossingNodes = {}
    return self
end
function ShipSystem:delete() end
function ShipSystem:addCrossingNode(owner, node)
    if self.crossingNodes[node] == nil then
        self.crossingNodes[node] = {}
        self:updateSplineCrossing(owner, node)
    end
end
function ShipSystem:removeCrossingNode(_, node)
    self.crossingNodes[node] = nil
end
function ShipSystem:updateSplineCrossing(owner, node)
    if self.crossingNodes[node] ~= nil then
        local splines = {}
        local wx, wy, wz = getWorldTranslation(node)
        for _, data in ipairs(self.splines) do
            if data.owner ~= owner then
                local x, y, z, time = getClosestSplinePosition(data.spline, wx, wy, wz, 0.01)
                local isValid = MathUtil.vector3Length(x - wx, y - wy, z - wz) < 1
                if isValid then
                    table.insert(splines, {
                        ["owner"] = data.owner,
                        ["spline"] = data.spline,
                        ["time"] = time
                    })
                end
            end
        end
        self.crossingNodes[node] = splines
    end
end
function ShipSystem:getIsShipCrossingPoint(node, duration)
    local splines = self.crossingNodes[node]
    if splines == nil then
        return false
    end
    for _, data in ipairs(splines) do
        if data.owner:getIsShipCrossingPoint(data.spline, data.time, duration) then
            return true
        end
    end
    return false
end
function ShipSystem:addSpline(splineNode, owner)
    if splineNode == nil then
        Logging.warning("No spline node given")
        return
    elseif getHasClassId(getGeometry(splineNode), ClassIds.SPLINE) then
        table.addElement(self.splines, {
            ["spline"] = splineNode,
            ["owner"] = owner
        })
        for node, _ in pairs(self.crossingNodes) do
            self:updateSplineCrossing(node)
        end
    else
        Logging.warning("Given node \'%s\' is not a spline", getName(splineNode))
    end
end
function ShipSystem:removeSpline(splineNode, _)
    if splineNode == nil then
        Logging.warning("No spline node given")
        return
    end
    if not getHasClassId(getGeometry(splineNode), ClassIds.SPLINE) then
        Logging.warning("Given node \'%s\' is not a spline", getName(splineNode))
        return
    end
    for k, data in ipairs(self.splines) do
        if data.spline == splineNode then
            table.remove(self.splines, k)
            break
        end
    end
    for k, data in pairs(self.crossingNodes) do
        self:updateSplineCrossing(k)
    end
end