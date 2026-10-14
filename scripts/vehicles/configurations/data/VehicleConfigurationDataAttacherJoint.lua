VehicleConfigurationDataAttacherJoint = {}
function VehicleConfigurationDataAttacherJoint.registerXMLPaths(schema, _, configPath)
    AttacherJoints.registerAttacherJointXMLPaths(schema, configPath)
end
function VehicleConfigurationDataAttacherJoint.onPrePostLoad(vehicle, configItem, _)
    if configItem.configKey ~= "" then
        if vehicle.spec_attacherJoints ~= nil then
            for _, key in vehicle.xmlFile:iterator(configItem.configKey .. ".attacherJoint") do
                local attacherJoint = {}
                if vehicle:loadAttacherJointFromXML(attacherJoint, vehicle.xmlFile, key, 0) then
                    table.insert(vehicle.spec_attacherJoints.attacherJoints, attacherJoint)
                end
            end
        end
    end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataAttacherJoint)