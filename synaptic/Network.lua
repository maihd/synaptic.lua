-- Network<T>
-- Use generic type for prevent cyclic import
return function (modulePath, Layer)
    local utils = dofile(modulePath .. "/utils.lua")
    local Network = utils.class("Network")

    function Network:__init__(layers)
        self.layers = {
            input = layers.input or nil,
            hidden = layers.hidden or {},
            output = layers.output or nil
        }
    end

    -- Feed-forward activation of all the layers to produce an output 
    function Network:activate(input)
        self.layers.input:activate(input)
        for _, layer in pairs(self.layers.hidden) do
            layer:activate()
        end

        return self.layers.output:activate()
    end

    -- Back-propagate the error through the network
    function Network:propagate(rate, target)
        self.layers.output:propagate(rate, target);
        for _, layer in pairs(self.layers.hidden) do
            layer:propagate(rate)
        end
    end

    -- Project a connection to another unit (either a network or a layer)
    function Network:project(unit, type, weights)
        if Network.is(unit) then
            return self.layers.output:project(unit.layers.input, type, weights)
        end

        if Layer.is(unit) then
            return self.layers.output:project(unit, type, weights)
        end

        error("Invalid argument, you can only project connections to LAYERS and NETWORKS!");
    end

    -- Let this network gate a connection
    function Network:gate(connection, type)
        self.layers.output.gate(connection, type)
    end

    -- Clear all elegibility traces and extended elegibility traces
    -- (the network forgets its context, but not what was trained)
    function Network:clear()
        self:restore()

        local input = self.layers.input
        local output = self.layers.output

        input:clear()
        for _, layer in self.layers.hidden do
            layer:clear()
        end
        output:clear()
    end

    -- Restore all the values from the optimized network the their respective 
    -- objects in order to manipulate the network
    function Network:restore()
        -- noops because of optimization support now!
    end

    -- Exports
    return Network
end