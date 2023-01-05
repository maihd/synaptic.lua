local utils = dofile("utils.lua")

-- Layer<T>
-- Use generic type to prevent circle deps
return function (LayerConnection, Neuron, Network)
    local LayerConnection = LayerConnection or dofile("LayerConnection.lua")
    -- local Neuron = Neuron or dofile("Neuron.lua") -- Neuron.lua is not implemented
    -- local Network = Network or dofile("Network.lua") -- Network.lua is not implemented

    -- GateType
    -- Types of gates
    local GateType = {
        INPUT = "INPUT",
        OUTPUT = "OUTPUT",
        ONE_TO_ONE = "ONE_TO_ONE"
    }

    local Layer = utils.class("Layer")

    function Layer:__init__(size)
        self.size = size
        self.list = {}

        self.connectedTo = {}

        for _=0, size do
            local neuron = Neuron()
            table.insert(self.list, neuron)
        end
    end

    -- Activate all the neurons in the layer
    function Layer:activate(input)
        local activations = {}
        
        if input then
            if #input ~= self.size then
                error("INPUT size and LAYER size must be the same to activate!")
            end

            for id, neuron in pairs(self.list) do
                local activation = neuron:activate(input[id])
                table.insert(activations, activation)
            end
        else
            for _, neuron in pairs(self.list) do
                local activation = neuron:activate()
                table.insert(activations, activation)
            end
        end

        return activations
    end

    -- Propagates the error on all the neurons of the layer
    function Layer:propagate(rate, target)
        if target then
            if #target ~= self.size then
                error("TARGET size and LAYER size must be the same to propagate!")
            end

            for id = self.size, 1, -1 do
                local neuron = self.list[id]
                neuron:propagate(rate, target[id])
            end
        else
            for id = self.size, 1, -1 do
                local neuron = self.list[id]
                neuron:propagate(rate)
            end
        end
    end

    -- Projects a connection from this layer to another one 
    function Layer:project(layerOrNetwork, type, weights)
        local layer = layerOrNetwork

        if Network.is(layerOrNetwork) then
            layer = layerOrNetwork.layers.input
        end

        if Layer.is(layer) then
            if not self:isConnected(layer) then
                return LayerConnection(self, layer, type, weights)
            end
        else
            error("Invalid argument, you can only project connections to LAYERS and NETWORKS!")
        end
    end

    -- Gates a connection between two layers
    function Layer:gate(connection, type)
        if type == GateType.INPUT then
            if connection.to.size ~= self.size then
                error("GATER layer and CONNECTION.TO layer must be the same size in order to gate!")    
            end

            for id, neuron in pairs(connection.list) do
                local gater = self.list[id]
                for _, gated in pairs(neuron.connections.inputs) do
                    if connection.connections[gated.id] then
                        gater:gate(gated)
                    end
                end
            end
        elseif type == GateType.OUTPUT then
            if connection.from.size ~= self.size then
                error("GATER layer and CONNECTION.FROM layer must be the same size in order to gate!")    
            end

            for id, neuron in pairs(connection.list) do
                local gater = self.list[id]
                for _, gated in pairs(neuron.connections.projected) do
                    if connection.connections[gated.id] then
                        gater:gate(gated)
                    end
                end
            end
        elseif type == GateType.ONE_TO_ONE then
            if connection.size ~= self.size then
                error("The number of GATER UNITS must be the same as the number of CONNECTIONS to gate!")    
            end

            for id, gated in pairs(connection.list) do
                local gater = self.list[id]
                gater:gate(gated)
            end
        else
            error("Invalid gate type!")
        end

        table.insert(connection.gatedFrom, {
            layer = self,
            type = type
        })
    end

    -- true of false whether the whole layer is self-connected or not
    function Layer:isSelfConnected()
        for _, neuron in pairs(self.list) do
            if not neuron:isSelfConnected() then
                return false
            end
        end

        return true
    end

    -- Get the connection type of this layer to target layer
    function Layer:getConnectionType(layer)
        -- Check if ALL_TO_ALL connection
        local connections = 0
        for _, from in pairs(self.list) do
            for _, to in pairs(layer.list) do
                local connected = from:isConnected(to)
                if connected.type == "projected" then
                    connections = connections + 1
                end
            end
        end

        if connections == self.size * layer.size then
            return LayerConnection.ConnectionType.ALL_TO_ALL
        end

        -- Check if ONE_TO_ONE connection
        local connections = 0
        for id, from in pairs(self.list) do
            local to = layer.list[id]
            local connected = from:isConnected(to)
            if connected.type == "projected" then
                connections = connections + 1
            end
        end

        if connections == self.size then
            return LayerConnection.ConnectionType.ONE_TO_ONE
        end

        -- No connection
        return nil
    end

    -- true of false whether the layer is connected to another layer (parameter) or not
    function Layer:isConnected(layer)
        return self:getConnectionType(layer) ~= nil
    end

    -- Clears all the neurons in the layer
    function Layer:clear()
        for _, neuron in pairs(self.list) do
            neuron:clear()
        end
    end

    -- Resets all the neurons in the layer
    function Layer:reset()
        for _, neuron in pairs(self.list) do
            neuron:reset()
        end
    end

    -- Returns all the neurons in the layer (in array)
    function Layer:getNeurons()
        return self.list
    end

    -- Adds a neuron to the layer
    function Layer:addNeuron(neuron)
        table.insert(self.list, neuron or Neuron())
        self.size = #self.list
    end

    -- Set options to all neurons
    function Layer:setOptions(options)
        local options = options or {}
        for _, neuron in pairs(self.list) do 
            if options.label then
                neuron.label = options.label .. "_" .. neuron.id
            end

            if options.squash then
                neuron.squash = options.squash
            end

            if options.bias then
                neuron.bias = options.bias
            end
        end
    end

    -- Exports
    Layer.GateType = GateType
    return Layer
end