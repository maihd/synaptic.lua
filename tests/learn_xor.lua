local synaptic = dofile("../synaptic/init.lua")("../synaptic")

local input = synaptic.Layer(2)
local hidden = synaptic.Layer(3)
local output = synaptic.Layer(1)

input:project(hidden)
hidden:project(output)

local network = synaptic.Network({
    input = input,
    hidden = { hidden },
    output = output
})

-- Train the network - leanr XOR
local learningRate = 0.3

for i = 1, 20000 do
    -- 0,0 => 0
    network:activate({ 0, 0 })
    network:propagate(learningRate, { 0 })

    -- 0,1 => 1  
    network:activate({ 0, 1 })
    network:propagate(learningRate, { 1 })

    -- 1,0 => 1  
    network:activate({ 1, 0 })
    network:propagate(learningRate, { 1 })

    -- 1,1 => 0  
    network:activate({ 1, 1 }) 
    network:propagate(learningRate, { 0 })
end

print(network:activate({ 0, 0 })[1]) 
-- -> [0.015020775950893527]

print(network:activate({ 0, 1 })[1])
-- -> [0.9815816381088985]

print(network:activate({ 1, 0 })[1])
-- ->  [0.9871822457132193]

print(network:activate({ 1, 1 })[1])
-- -> [0.012950087641929467]