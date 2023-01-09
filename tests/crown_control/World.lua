World = class("World")

function World:__init__(creatureCount, width, height)
    self.creatureCount = creatureCount

    self.width = width
    self.height = height

    self.creatures = {}
    for i = 1, creatureCount do
        local x = math.random() * width
		local y = math.random() * height

        local creature = Creature(self, x, y)
        
        local direction = math.random() * math.pi * 2
        creature.velocity.x = math.cos(direction) * creature.maxSpeed
        creature.velocity.y = math.sin(direction) * creature.maxSpeed

        table.insert(self.creatures, creature)
    end
end

function World:update(dt)
    for _, creature in pairs(self.creatures) do
        creature:update(dt)
    end
end

function World:draw()
    for _, creature in pairs(self.creatures) do
        creature:draw()
    end
end

function World:getTargetX(creature)
    local cohesion = creature:cohesion(self.creatures)
    return cohesion.x / self.width
end

function World:getTargetY(creature)
    local cohesion = creature:cohesion(self.creatures)
    return cohesion.y / self.height
end

function World:getTargetAngle(creature)
    local alignment = creature:align(self.creatures)
    local angle = math.atan2(alignment.y, alignment.x)
    return (angle + math.pi) / (math.pi * 2)
end