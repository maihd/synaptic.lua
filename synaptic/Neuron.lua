return function(modulePath)
    local utils = dofile(modulePath .. "/utils.lua")
    local Connection = dofile(modulePath .. "/Connection.lua")(modulePath)

    local Neuron = utils.class("Neuron")

    -- Default squashing functions
    local squash = {
        logistic = function (x, derivate)
            local fx = 1 / (1 + math.exp(-x))
            if not derivate then
                return fx
            else
                return fx * (1 - fx)
            end
        end,

        tanh = function (x, derivate)
            if derivate then
                return 1 - math.pow(math.tanh(x), 2)
            else
                return math.tanh(x)
            end
        end,

        identity = function (x, derivate)
            return (derivate and 1) or x
        end,

        hlim = function (x, derivate)
            return (derivate and 1) or (x > 0 and 1) or 0
        end,

        relu = function (x, derivate)
            if derivate then
                return (x > 0 and 1) or 0
            else
                return (x > 0 and x) or 0
            end
        end
    }

    function Neuron:__init__()
        self.id = Neuron.uid()

        self.connections = {
            inputs = {},
            projected = {},
            gated = {}
        }

        self.error = {
            responsibility = 0,
            projected = 0,
            gated = 0
        }

        self.trace = {
            elegibility = {},
            extended = {},
            influences = {}
        }

        self.state = 0
        self.oldState = 0
        self.activation = 0
        self.selfConnection = Connection(self, self, 0) -- weight = 0 -> not connected
        self.squash = squash.logistic
        self.neighbors = {}
        self.bias = math.random() * 0.2 - 0.1
    end

    -- Activates the neuron
    function Neuron:activate(input)
        -- Activation from the environment (for input neurons)
        if input then
            self.activation = input
            self.derivative = 0
            self.bias = 0
            return self.activation
        end

        -- Local variables for fast accessing
        local selfConnection = self.selfConnection

        -- Restore state
        self.oldState = self.state

        -- Eq. 15
        self.state = selfConnection.gain * selfConnection.weight * self.state + self.bias
        for _, input in pairs(self.connections.inputs) do
            self.state = self.state + input.from.activation * input.weight * input.gain
        end

        -- Eq. 16
        self.activation = self.squash(self.state)

        -- F'(s)
        self.derivative = self.squash(self.state, true)

        -- Update traces
        local influences = {}
        for id, _ in pairs(self.trace.extended) do
            -- Extended elegibility trace
            local neuron = self.neighbors[id]

            -- If gated neuron's selfConnection is gated by this unit, the influence keeps track of the neuron's old state
            local influence = (neuron.selfConnection.gater == self and neuron.oldState) or 0

            -- Index runs over all the incoming connections to the gated neuron that are gated by this unit
            for _, incoming in pairs(self.trace.influences[neuron.id]) do
                influence = influence + incoming.weight * incoming.from.activation
            end

            influences[neuron.id] = influence
        end

        for _, input in pairs(self.connections.inputs) do
            -- Elegibility trace - Eq. 17
            self.trace.elegibility[input.id] = 
                selfConnection.gain * selfConnection.weight * self.trace.elegibility[input.id]
                + input.gain * input.from.activation

            -- Extended elegibility trace
            for id, xtrace in pairs(self.trace.extended) do
                local neuron = self.neighbors[id]
                local influence = influences[neuron.id]

                -- Eq. 18
                xtrace[input.id] = 
                    neuron.selfConnection.weight * neuron.selfConnection.weight * xtrace[input.id]
                    + self.derivative * self.trace.elegibility[input.id] * influence
            end
        end

        -- Update gated connection's gains
        for _, connection in pairs(self.connections.gated) do
            connection.gain = self.activation
        end

        -- Finish
        return self.activation
    end

    -- Back-propagate the error
    function Neuron:propagate(rate, target)
        -- Error accumulator
        local error = 0

        -- Whether or not this neuron is in the output layer
        local isOutput = target ~= nil

        -- Output neurons get their error from the environment
        if isOutput then
            local eq10 = target - self.activation
            self.error.responsibility, self.error.projected = eq10, eq10
        else
            -- The rest of the neuron compute their error responsibility by backpropagation
            -- Error responsibilities from all the connections projected from this neuron
            for _, connection in pairs(self.connections.projected) do
                local neuron = connection.to
                
                -- Eq.21
                error = error + neuron.error.responsibility * connection.gain * connection.weight
            end

            -- Projected error responsibility
            self.error.projected = self.derivative * error

            -- Error responsibilities from all the connections gated by this neuron
            error = 0
            for id, _ in pairs(self.trace.extended) do
                local neuron = self.neighbors[id]

                -- If gated neuron's selfconnection is gated by this neuron
                local influence = (neuron.selfConnections.gater == self and neuron.oldState) or 0

                -- Index runs over all the connections to the gated neuron that are gated by this neuron
                for index, input in pairs(self.trace.influences[id]) do
                    influence = influence + input.weight * self.trace.influences[neuron.id][index].from.activation
                end

                -- Eq. 22
                error = error + neuron.error.responsibility * influence
            end

            -- Gated error responsibility
            self.error.gated = self.derivative * error

            -- Error responsibility - Eq. 23
            self.error.responsibility = self.error.projected + self.error.gated
        end

        -- Learing rate
        local rate = rate or 0.1

        -- Adjust all the neuron's incoming connections
        for _, input in pairs(self.connections.inputs) do
            -- Eq. 24
            local gradient = self.error.projected * self.trace.elegibility[input.id]
            for id, _ in pairs(self.trace.extented) do
                local neuron = self.neighbors[id]
                gradient = gradient + neuron.error.responsibility * self.trace.extended[neuron.id][input.id]
            end

            -- Adjust weights - aka learn
            input.weight = input.weight + rate * gradient
        end

        -- Adjust bias
        self.bias = self.bias + rate * self.error.responsibility
    end

    -- Project this neuron to another neuron
    function Neuron:project(neuron, weight)
        -- Self connection
        if neuron == self then
            self.selfConnection.weight = 1
            return self.selfConnection
        end

        -- Check if connection already exists
        local connected = self:isConnected(neuron)
        if connected and connection.type == "projected" then
            -- Update connection
            if weight then
                connected.connection.weight = weight
            end

            -- Return existing connection
            return connected.connection
        else
            -- Create new connection
            local connection = Connection(self, neuron, weight)

            -- Reference all the connections and traces
            self.connections.projected[connection.id] = connection
            self.neighbors[neuron.id] = neuron

            neuron.connections.inputs[connection.id] = connection
            neuron.trace.elegibility[connection.id] = 0

            for _, trace in pairs(neuron.trace.extended) do
                trace[connection.id] = 0
            end

            return connection
        end
    end

    -- Gate the connection
    function Neuron:gate(connection)
        -- Add connection to gated list
        self.connections.gated[connection.id] = connection

        local neuron = connection.to
        if not self.trace.extended[neuron.id] then
            -- Extended trace
            self.neighbors[neuron.id] = neuron

            local xtrace = {}
            self.trace.extended[neuron.id] = xtrace
            for _, input in pairs(self.connections.inputs) do
                xtrace[input.id] = 0
            end
        end

        -- Keep track
        if self.trace.influences[neuron.id] then
            table.insert(self.trace.influences[neuron.id], connection)
        else
            self.trace.influences[neuron.id] = { connection }
        end

        -- Set gater
        connection.gater = self
    end

    -- Returns true or false whether the neuron is self-connected or not
    function Neuron:isSelfConnected()
        return self.selfConnection.weight ~= 0
    end

    -- Returns true or false whether the neuron is connected to another neuron (parameter)
    function Neuron:isConnected(neuron)
        local result = {
            type = nil,
            connection = false
        }

        if self == neuron then
            if self:isSelfConnected() then
                result.type = "selfConnection"
                result.connection = self.selfConnection
                return result
            end

            return false
        end

        for type, connections in pairs(self.connections) do
            for _, connection in pairs(connections) do
                if connection.to == neuron or connection.from == neuron then
                    result.type = type
                    result.connection = connection
                    return result
                end
            end
        end

        return false
    end

    -- Clear all the traces (the neuron forget it's context, but the connections remains intact)
    function Neuron:clear()
        for trace, _ in pairs(self.trace.elegibility) do
            self.trace.elegibility[trace] = 0
        end

        for trace, _ in pairs(self.trace.extended) do
            for extended, _ in pairs(self.trace.extended[trace]) do
                self.trace.extended[trace][extended] = 0;
            end
        end

        self.error.gated = 0
        self.error.projected = 0
        self.error.responsibility = 0
    end

    -- All the connections are randomized and the traces are cleared
    function Neuron:reset()
        self:clear()

        for _, connections in pairs(self.connections) do
            for _, connection in pairs(connections) do
                connection.weight = math.random() * 0.2 - 0.1
            end
        end

        self.bias = math.random() * 0.2 - 0.1
        self.state = 0
        self.oldState = 0
        self.activation = 0
    end

    -- Static

    Neuron.neurons = 0

    function Neuron.uid()
        local result = Neuron.neurons
        Neuron.neurons = Neuron.neurons + 1
        return result
    end

    function Neuron.quantity()
        return {
            neurons = Neuron.neurons,
            connections = Connection.connections
        }
    end

    -- Exports
    return Neuron
end