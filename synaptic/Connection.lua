return function(modulePath)
    local utils = dofile(modulePath .. "/utils.lua")

    local Connection = utils.class("Connection")

    function Connection:__init__(from, to, weight)
        if not from or not to then
            error("Connection Error: Invalid neurons")
        end

        self.id     = Connection.uid()
        self.from   = from
        self.to     = to
        self.weight = weight or (math.random() * 0.2 - 0.1)
        self.gain   = 1
        self.gater  = nil
    end

    -- Static
    Connection.connections = 0
    function Connection.uid()
        local id = Connection.connections
        Connection.connections = Connection.connections + 1
        return id
    end

    -- Exports
    return Connection
end