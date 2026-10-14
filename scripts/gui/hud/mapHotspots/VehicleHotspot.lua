VehicleHotspot = {}
VehicleHotspot.TYPE = {}
VehicleHotspot.TYPE.TRACTOR = 1
VehicleHotspot.TYPE.TRUCK = 2
VehicleHotspot.TYPE.CAR = 3
VehicleHotspot.TYPE.HARVESTER = 4
VehicleHotspot.TYPE.WHEELLOADER = 5
VehicleHotspot.TYPE.TRAILER = 6
VehicleHotspot.TYPE.TOOL = 7
VehicleHotspot.TYPE.TOOL_TRAILED = 8
VehicleHotspot.TYPE.CUTTER = 9
VehicleHotspot.TYPE.OTHER = 10
VehicleHotspot.TYPE.HORSE = 11
VehicleHotspot.TYPE.TRAIN = 12
VehicleHotspot.TYPE.MOTORBIKE = 13
VehicleHotspot.TYPE.WOOD_HARVESTER = 14
VehicleHotspot.TYPE.BOAT = 15
VehicleHotspot.CATEGORY_MAPPING = {}
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.TRACTOR] = MapHotspot.CATEGORY_STEERABLE
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.TRUCK] = MapHotspot.CATEGORY_STEERABLE
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.CAR] = MapHotspot.CATEGORY_STEERABLE
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.HARVESTER] = MapHotspot.CATEGORY_COMBINE
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.WHEELLOADER] = MapHotspot.CATEGORY_STEERABLE
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.TRAILER] = MapHotspot.CATEGORY_TRAILER
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.TOOL] = MapHotspot.CATEGORY_TOOL
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.TOOL_TRAILED] = MapHotspot.CATEGORY_TOOL
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.CUTTER] = MapHotspot.CATEGORY_TOOL
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.OTHER] = MapHotspot.CATEGORY_TOOL
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.HORSE] = MapHotspot.CATEGORY_ANIMAL
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.TRAIN] = MapHotspot.CATEGORY_STEERABLE
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.MOTORBIKE] = MapHotspot.CATEGORY_STEERABLE
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.WOOD_HARVESTER] = MapHotspot.CATEGORY_STEERABLE
VehicleHotspot.CATEGORY_MAPPING[VehicleHotspot.TYPE.BOAT] = MapHotspot.CATEGORY_STEERABLE
VehicleHotspot.SLICE = {}
VehicleHotspot.SLICE[VehicleHotspot.TYPE.TRUCK] = "mapHotspots.truck"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.TRACTOR] = "mapHotspots.tractor"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.HARVESTER] = "mapHotspots.harvester"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.CAR] = "mapHotspots.car"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.WHEELLOADER] = "mapHotspots.wheelLoader"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.OTHER] = "mapHotspots.other"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.CUTTER] = "mapHotspots.header"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.TRAILER] = "mapHotspots.trailer"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.TOOL] = "mapHotspots.tool"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.TOOL_TRAILED] = "mapHotspots.toolTrailed"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.HORSE] = "mapHotspots.horse"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.TRAIN] = "mapHotspots.train"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.MOTORBIKE] = "mapHotspots.motorbike"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.WOOD_HARVESTER] = "mapHotspots.woodHarvester"
VehicleHotspot.SLICE[VehicleHotspot.TYPE.BOAT] = "mapHotspots.ferry"
local refSize = { 100, 100 }
VehicleHotspot.CLICK_AREAS = {}
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.TRACTOR] = MapHotspot.getClickArea({
    29,
    18,
    42,
    64
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.TRUCK] = MapHotspot.getClickArea({
    32,
    5,
    40,
    90
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.CAR] = MapHotspot.getClickArea({
    33,
    23,
    34,
    54
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.HARVESTER] = MapHotspot.getClickArea({
    28,
    3,
    44,
    94
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.WHEELLOADER] = MapHotspot.getClickArea({
    30,
    8,
    40,
    84
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.TRAILER] = MapHotspot.getClickArea({
    15,
    37,
    70,
    26
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.TOOL] = MapHotspot.getClickArea({
    35,
    37,
    30,
    26
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.TOOL_TRAILED] = MapHotspot.getClickArea({
    31,
    18,
    38,
    64
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.CUTTER] = MapHotspot.getClickArea({
    32,
    29,
    36,
    42
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.OTHER] = MapHotspot.getClickArea({
    34,
    34,
    32,
    32
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.HORSE] = MapHotspot.getClickArea({
    30,
    11,
    40,
    78
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.TRAIN] = MapHotspot.getClickArea({
    35,
    6,
    30,
    88
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.MOTORBIKE] = MapHotspot.getClickArea({
    35,
    6,
    30,
    88
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.WOOD_HARVESTER] = MapHotspot.getClickArea({
    28,
    3,
    44,
    94
}, refSize, 0)
VehicleHotspot.CLICK_AREAS[VehicleHotspot.TYPE.BOAT] = MapHotspot.getClickArea({
    29,
    18,
    42,
    64
}, refSize, 0)
local VehicleHotspot_mt = Class(VehicleHotspot, MapHotspot)
function VehicleHotspot.new(customMt)
    -- upvalues: (copy) VehicleHotspot_mt
    local self = MapHotspot.new(customMt or VehicleHotspot_mt)
    if Platform.isMobile then
        self.width, self.height = getNormalizedScreenValues(120, 120)
    else
        self.width, self.height = getNormalizedScreenValues(60, 60)
    end
    self.vehicleType = VehicleHotspot.TYPE.OTHER
    return self
end
function VehicleHotspot:getCategory()
    return VehicleHotspot.CATEGORY_MAPPING[self.vehicleType]
end
function VehicleHotspot:setVehicle(vehicle)
    self.vehicle = vehicle
    if self.icon ~= nil then
        self.icon:delete()
    end
    self.icon = g_overlayManager:createOverlay("mapHotspots.tractor", 0, 0, self.width, self.height)
    self.icon:setColor(unpack(self.color))
    self.icon:setScale(self.scale, self.scale)
    self:setVehicleType(self.vehicleType)
end
function VehicleHotspot:getVehicle()
    return self.vehicle
end
function VehicleHotspot:setVehicleType(vehicleType)
    self.vehicleType = vehicleType
    if self.icon ~= nil then
        local slice = g_overlayManager:getSliceInfoById(VehicleHotspot.SLICE[vehicleType])
        if slice ~= nil then
            self.icon:setUVs(slice.uvs)
        end
    end
    if Platform.isMobile then
        self.clickArea = MapHotspot.getClickCircle(0.5)
    else
        self.clickArea = VehicleHotspot.CLICK_AREAS[vehicleType]
    end
end
function VehicleHotspot:getWorldPosition()
    if self.vehicle == nil or self.vehicle:getIsBeingDeleted() then
        return nil, nil
    end
    local x, _, z = self.vehicle:getMapHotspotPosition()
    return x, z
end
function VehicleHotspot:getWorldRotation()
    return (self.vehicle == nil or self.vehicle:getIsBeingDeleted()) and 0 or self.vehicle:getMapHotspotRotation(false)
end
function VehicleHotspot.getTypeByName(name)
    if name == nil then
        return nil
    end
    name = string.upper(name)
    return VehicleHotspot.TYPE[name]
end
function VehicleHotspot:setOwnerFarmId(farmId)
    MapHotspot.setOwnerFarmId(self, farmId)
    if g_currentMission.missionDynamicInfo.isMultiplayer then
        local farm = g_farmManager:getFarmById(self.ownerFarmId)
        if farm ~= nil then
            local color = Farm.COLORS[farm.color]
            self:setColor(color[1], color[2], color[3])
            return
        end
        self:setColor(1, 1, 1)
    end
end
VehicleHotspot.render = MapHotspot.render
VehicleHotspot.setScale = MapHotspot.setScale
VehicleHotspot.getColor = MapHotspot.getColor