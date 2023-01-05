local utils = dofile("../synaptic/utils.lua")

math.randomseed(os.clock())

local TestClass = utils.class("TestClass")

function TestClass:__init__()
    self.value = math.random(0, 100)
end

function TestClass:__deinit__()
    print("This object is deleted!")
end

function TestClass:printValue()
    print(self.value)
end

function TestClass:toString()
    return self.__className .. " " .. self.value 
end

local testObject = TestClass()
testObject:printValue()
print(testObject)

collectgarbage("collect")