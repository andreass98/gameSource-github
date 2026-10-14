VehicleSchemaOverlayData = {}
local VehicleSchemaOverlayData_mt = Class(VehicleSchemaOverlayData)
function VehicleSchemaOverlayData.new(offsetX, offsetY, schemaName, invisibleBorderRight, invisibleBorderLeft)
    -- upvalues: (copy) VehicleSchemaOverlayData_mt
    local self = setmetatable({}, VehicleSchemaOverlayData_mt)
    self.offsetX = offsetX or 0
    self.offsetY = offsetY or 0
    self.schemaName = schemaName
    self.invisibleBorderRight = invisibleBorderRight or 0.05
    self.invisibleBorderLeft = invisibleBorderLeft or 0.05
    self.attacherJoints = nil
    return self
end
function VehicleSchemaOverlayData:addAttacherJoint(attacherOffsetX, attacherOffsetY, rotation, invertX, liftedOffsetX, liftedOffsetY)
    if not self.attacherJoints then
        self.attacherJoints = {}
    end
    table.insert(self.attacherJoints, {
        ["x"] = attacherOffsetX or 0,
        ["y"] = attacherOffsetY or 0,
        ["rotation"] = rotation or 0,
        ["invertX"] = invertX and true or false,
        ["liftedOffsetX"] = liftedOffsetX or 0,
        ["liftedOffsetY"] = liftedOffsetY or 5
    })
end
VehicleSchemaOverlayData.SCHEMA_OVERLAY = {}
VehicleSchemaOverlayData.SCHEMA_OVERLAY.VEHICLE = "VEHICLE"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.HARVESTER = "HARVESTER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.TRUCK = "TRUCK"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.CAR = "CAR"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.LOADER = "LOADER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.IMPLEMENT = "IMPLEMENT"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.TRAILER = "TRAILER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.COMBINE_HEADER = "COMBINE_HEADER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.FRONTLOADER = "FRONTLOADER"
VehicleSchemaOverlayData.SCHEMA_OVERLAY.MOTORBIKE = "MOTORBIKE"