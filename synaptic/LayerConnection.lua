local utils = dofile("utils.lua")

local ConnectionType = {
    ALL_TO_ALL = "ALL TO ALL",
    ONE_TO_ONE = "ONE TO ONE",
    ALL_TO_ELSE = "ALL TO ELSE"
}

-- LayerConnection
-- Represent a connection from one layer to another layers
-- and keeps track of its weight and gain
local LayerConnection = utils.class("LayerConnection")

function LayerConnection:__init__(fromLayer, toLayer, type, weights)
    self.id = LayerConnection.uid()
    self.from = fromLayer
    self.to = toLayer
    self.selfConnection = fromLayer == toLayer
    self.type = type
    self.connections = {}
    self.list = {}
    self.size = 0
    self.gatedFrom = {}

    if type == nil then
        if self.selfConnection then
            self.type = ConnectionType.ONE_TO_ONE
        else 
            self.type = ConnectionType.ALL_TO_ALL
        end
    end

    if type == ConnectionType.ALL_TO_ALL or type == ConnectionType.ALL_TO_ELSE then
        for _, from in pairs(self.from.list) do
            ::continue::
            for _, to in pairs(self.to.list) do
                if type == ConnectionType.ALL_TO_ELSE and from == to then
                    goto continue
                end

                local connection = from.project(to, weights)
                self.connections[connection.id] = connection

                table.insert(self.list, connection)
                self.size = #self.list
            end
        end
    elseif type == ConnectionType.ONE_TO_ONE then
        for neuron, from in pairs(self.from.list) do
            local to = self.to.list[neuron]

            local connection = from.project(to, weights)
            self.connections[connection.id] = connection
            
            table.insert(self.list, connection)
            self.size = #self.list
        end
    else
        error("Invalid connection type")
    end

    fromLayer.connectionTo:insert(self)
end

-- Static

LayerConnection.connections = 0

function LayerConnection.uid()
    local uid = LayerConnection.connections
    LayerConnection.connections = LayerConnection.connections + 1
    return uid
end

-- Exports
LayerConnection.ConnectionType = ConnectionType
return LayerConnection