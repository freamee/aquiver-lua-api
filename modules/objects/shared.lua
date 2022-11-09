API.Objects = {}
---@type table<string, SObject|ClientObject>
API.Objects.Entities = {}

API.Objects.exists = function(remoteId)
    if API.Objects.Entities[remoteId] then
        return true
    end
    return false
end

API.Objects.get = function(remoteId)
    if API.Objects.exists(remoteId) then
        return API.Objects.Entities[remoteId]
    end
    return nil
end

API.Objects.getAll = function()
    return API.Objects.Entities
end

API.Objects.atRemoteId = function(remoteId)
    for k, v in pairs(API.Objects.Entities) do
        if v.data.remoteId == remoteId then
            return v
        end
    end
    return nil
end

API.Objects.atMysqlId = function(mysqlId)
    for k, v in pairs(API.Objects.Entities) do
        if v.data.id == mysqlId then
            return v
        end
    end
    return nil
end

API.Objects.GetNearestObject = function(vec3, model, range)
    local rangeMeter = range
    local closest

    if type(vec3) ~= "vector3" then return end

    for k, v in pairs(API.Objects.Entities) do
        if model then
            if v.data.model == model then
                local dist = #(v.GetPositionVector3() - vec3)

                if dist < rangeMeter then
                    rangeMeter = dist
                    closest = v
                end
            end
        else
            local dist = #(v.GetPositionVector3() - vec3)

            if dist < rangeMeter then
                rangeMeter = dist
                closest = v
            end
        end
    end

    return closest
end