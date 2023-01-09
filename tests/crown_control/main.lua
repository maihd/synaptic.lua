_G.synaptic = dofile("../../synaptic/init.lua")("../../synaptic")
_G.class = dofile("../../synaptic/utils.lua").class

require "Creature"
require "World"

local world = nil

function love.load()
    math.randomseed(os.clock())
    
    world = World(10, love.graphics.getDimensions())
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    world:draw()
end