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
print("testObject is instance of TestClass: " .. tostring(TestClass.is(testObject)))

local TestClass2 = utils.class("TestClass2")
print("testObject is instance of TestClass2: " .. tostring(TestClass2.is(testObject)))

testObject = nil

collectgarbage("collect") -- why TestClass.__gc is not called?
collectgarbage("collect") -- why TestClass.__gc is not called?