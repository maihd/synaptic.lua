Creature = class("Creature")

function Creature:__init__(world, x, y)
    self.world = world
    self.mass = 0.3
    self.maxSpeed = 100
    self.maxForce =  15
    self.lookRange = self.mass * 200
    self.length = self.mass * 10
    self.base = self.length * 0.5
    self.size = 5

    self.position       = { x = x, y = y }
    self.velocity       = { x = 0, y = 0 }
    self.acceleration   = { x = 0, y = 0 }

    local inputLayer = synaptic.Layer(world.creatureCount * 4)
    local hiddenLayer = synaptic.Layer(world.creatureCount * 2 + 5)
    local outputLayer = synaptic.Layer(3)

    inputLayer:project(hiddenLayer)
    hiddenLayer:project(outputLayer)
    
    self.network = synaptic.Network({
        input = inputLayer,
        hidden = { hiddenLayer },
        output = outputLayer
    })
end

function Creature:update(dt)
    -- Movement
    local input = {}
    for _, other in pairs(self.world.creatures) do
        table.insert(input, other.position.x)
        table.insert(input, other.position.y)
        table.insert(input, other.velocity.x)
        table.insert(input, other.velocity.y)
    end

    local output = self.network:activate(input)
    self:moveTo(output)
    
    -- Learning
    local learningRate = 0.3
    local target = { 
        self.world:getTargetX(self), 
        self.world:getTargetY(self), 
        self.world:getTargetAngle(self) 
    }
    self.network:propagate(learningRate, target)

    -- Update position
    self:boundaries()

    self.velocity.x = self.velocity.x + self.acceleration.x * dt
    self.velocity.y = self.velocity.y + self.acceleration.y * dt

    if self.velocity.x * self.velocity.x + self.velocity.y * self.velocity.y > self.maxSpeed * self.maxSpeed then
        local angle = math.atan2(self.velocity.y, self.velocity.x)
        self.velocity.x = math.cos(angle) * self.maxSpeed
        self.velocity.y = math.sin(angle) * self.maxSpeed
    end

    self.position.x = self.position.x + self.velocity.x * dt
    self.position.y = self.position.y + self.velocity.y * dt

    self.acceleration.x = self.acceleration.x * (1 - 10 * dt)
    self.acceleration.y = self.acceleration.y * (1 - 10 * dt)
end

function Creature:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", self.position.x, self.position.y, self.radius)
end

function Creature:moveTo(output)
    local force = { x = 0, y = 0 }

    local target = { x = output[1] * self.world.width, y = output[2] * self.world.height }
    local angle = math.pi * (output[2] * 2 - 1)

    local separation = self:seperate(self.world.creatures)
    local alignment = self:align(self.world.creatures)
    local cohesion = self:cohesion(self.world.creatures)

    force.x = separation.x + alignment.x + cohesion.x
    force.y = separation.y + alignment.y + cohesion.y

    self:applyForce(force)
end

function Creature:applyForce(force)
    self.acceleration.x = self.acceleration.x + force.x
    self.acceleration.y = self.acceleration.y + force.y
end

function Creature:boundaries()
    if self.position.x < self.radius * 0.5 then
        self:applyForce({ x =  self.maxForce * 2, y = 0 })
    end

    if self.position.x > self.world.width - self.radius * 0.5 then
        self:applyForce({ x = -self.maxForce * 2, y = 0 })
    end

    if self.position.y < self.radius * 0.5 then
        self:applyForce({ x = 0, y =  self.maxForce * 2 })
    end

    if self.position.y > self.world.height - self.radius * 0.5 then
        self:applyForce({ x = 0, y = -self.maxForce * 2 })
    end
end

function Creature:seek(target)
    local delta = {
        x = target.x - self.position.x,
        y = target.y - self.position.y
    }

    local angle = math.atan2(delta.y, delta.x)
    local seek = {
        x = math.cos(angle) * self.maxSpeed - self.velocity.x,
        y = math.sin(angle) * self.maxSpeed - self.velocity.y
    }

    if seek.x * seek.x + seek.y * seek.y > 0.3 * 0.3 then
        angle = math.atan2(delta.y, delta.x)
        seek.x = math.cos(angle) * 0.3
        seek.y = math.sin(angle) * 0.3
    end

    return seek
end

function Creature:seperate(neighbors)
    local sum = { x = 0, y = 0 }
    local count = 0

    for _, neighbor in pairs(neighbors) do
        if neighbor ~= self then
            local delta = { 
                x = self.position.x - neighbor.position.x,
                y = self.position.y - neighbor.position.y
            }
            local distance = math.sqrt(delta.x * delta.x + delta.y * delta.y)
            if distance < 24 and distance > 0 then
                local angle = math.atan2(delta.y, delta.x)
                sum.x = sum.x + math.cos(angle) / distance
                sum.y = sum.y + math.sin(angle) / distance
                count = count + 1
            end
        end
    end

    if count == 0 then
        return sum
    end

    local angle = math.atan2(sum.y, sum.x)
    
    sum.x = math.cos(angle) * self.maxSpeed - self.velocity.x
    sum.y = math.sin(angle) * self.maxSpeed - self.velocity.y

    if sum.x * sum.x + sum.y * sum.y > self.maxForce * self.maxForce then
        angle = math.atan2(sum.y, sum.x)
        sum.x = math.cos(angle) * self.maxForce
        sum.y = math.sin(angle) * self.maxForce
    end

    sum.x = sum.x * 2
    sum.y = sum.y * 2

    return sum
end

function Creature:align(neighbors)
    local sum = { x = 0, y = 0 }
    local count = 0

    for _, neighbor in pairs(neighbors) do
        if neighbor ~= self then
            sum.x = sum.x + neighbor.velocity.x
            sum.y = sum.y + neighbor.velocity.y
            count = count + 1
        end
    end

    if count == 0 then
        return sum
    end

    local angle = math.atan2(sum.y, sum.x)
    
    sum.x = math.cos(angle) * self.maxSpeed - self.velocity.x
    sum.y = math.sin(angle) * self.maxSpeed - self.velocity.y

    if sum.x * sum.x + sum.y * sum.y > self.maxSpeed * self.maxSpeed then
        angle = math.atan2(sum.y, sum.x)
        sum.x = math.cos(angle) * self.maxSpeed
        sum.y = math.sin(angle) * self.maxSpeed
    end

    if sum.x * sum.x + sum.y * sum.y > 0.1 * 0.1 then
        angle = math.atan2(sum.y, sum.x)
        sum.x = math.cos(angle) * 0.1
        sum.y = math.sin(angle) * 0.1
    end

    return sum
end

function Creature:cohesion(neighbors)
    local sum = { x = 0, y = 0 }
    local count = 0

    for _, neighbor in pairs(neighbors) do
        if neighbor ~= self then
            sum.x = sum.x + neighbor.position.x
            sum.y = sum.y + neighbor.position.y
            count = count + 1
        end
    end

    sum.x = sum.x / count
    sum.y = sum.y / count

    return sum
end