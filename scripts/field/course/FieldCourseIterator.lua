FieldCourseIterator = {}
local FieldCourseIterator_mt = Class(FieldCourseIterator)
function FieldCourseIterator.new(x, z, fieldCourseSettings, func, finishedCallback)
    -- upvalues: (copy) FieldCourseIterator_mt
    local self = setmetatable({}, FieldCourseIterator_mt)
    self.func = func
    self.finishedCallback = finishedCallback
    self.frameBudget = 0.00025
    self.fieldCourseSegmentIndex = 1
    self.fieldCourseSegmentPosIndex = 1
    FieldCourse.generateByFieldPosition(x, z, fieldCourseSettings, function(fieldCourse)
        -- upvalues: (copy) self
        if fieldCourse == nil then
            self:onFinish(false)
        else
            self.fieldCourse = fieldCourse
            g_fieldCourseManager:addUpdateable(self)
        end
    end)
end
function FieldCourseIterator:update(_)
    local startTime = getTimeSec()
    while getTimeSec() - startTime < self.frameBudget do
        local segment = self.fieldCourse.segments[self.fieldCourseSegmentIndex]
        if segment == nil then
            self:onFinish(true)
        else
            local position = segment.positions[self.fieldCourseSegmentPosIndex]
            local nextPosition = segment.positions[self.fieldCourseSegmentPosIndex + 1]
            self.func(position[1], position[2], nextPosition[1], nextPosition[2], segment.length, segment.headlandIndex, segment.islandIndex, self.fieldCourse.totalLength)
            self.fieldCourseSegmentPosIndex = self.fieldCourseSegmentPosIndex + 1
            if self.fieldCourseSegmentPosIndex > #segment.positions - 1 then
                self.fieldCourseSegmentPosIndex = 1
                self.fieldCourseSegmentIndex = self.fieldCourseSegmentIndex + 1
                if self.fieldCourseSegmentIndex > #self.fieldCourse.segments then
                    self:onFinish(true)
                    return
                end
            end
        end
    end
end
function FieldCourseIterator:onFinish(success)
    g_fieldCourseManager:removeUpdateable(self)
    if self.finishedCallback ~= nil then
        self.finishedCallback(success)
    end
end