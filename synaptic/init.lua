return function (modulePath)
    local Layer = dofile(modulePath .. "/Layer.lua")
    local Neuron = dofile(modulePath .. "/Neuron.lua")
    local Network = dofile(modulePath .. "/Network.lua")
    local LayerConnection = dofile(modulePath .. "/LayerConnection.lua")
    
    local LayerClass = Layer(modulePath, LayerConnection(modulePath), Neuron(modulePath))
    local NetworkClass = Network(modulePath, LayerClass)
    
    function LayerClass.isNetwork(unit)
        return NetworkClass.is(unit)
    end

    local exports = {
        Layer = LayerClass,
        Network = NetworkClass
    }
    
    return exports
end