-- Make dofile is only call once, should comment when checked
-- if _G.imported then 
--     error("utils.lua is imported")
-- end
-- _G.imported = true

-- Create new class
local function class(name, ...)
    local supers = { ... }

    local class = {}

    -- Inherit fields from supers
    for _, super in pairs(supers) do
        for key, value in pairs(super) do
            class[key] = value
        end
    end

    -- Default fields
    class.__name = name
    class.__className = name
    class.__index = class
    class.__class = class
    class.__super = supers[1]
    class.__supers = supers

    -- Create constructor
    setmetatable(class, {
        __call = function (self, ...)
            local object = setmetatable({}, self)
            object:__init__(...)
            return object
        end
    })

    -- Helpers
    function class.is(object)
        return object and object.__class == class 
    end

    -- Default metamethods
    if not class.__gc then
        class.__gc = function (self)
            self:__deinit__()
        end
    end

    if not class.__tostring then
        class.__tostring = function (self)
            return self:toString()
        end
    end

    -- Default methods
    if not class.__init__ then
        class.__init__ = function (self, ...)
            -- noops
        end
    end

    if not class.__deinit__ then
        class.__deinit__ = function (self)
            -- noops
        end
    end

    if not class.toString then 
        class.toString = function (self)
            return self.__name
        end
    end

    return class
end

-- Exports
return {
    class = class
}