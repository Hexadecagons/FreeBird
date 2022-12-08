-- DEPENDENCIES
local Debug                 = _G:require("Debug")

-- MODULE
local Recycler = {
    Pool = {}
}

--- Generate a pool of a custom object.
--- @param PoolName string -- Name of the pool.
--- @param Object any -- Object to populate the pool with.
--- @param Amount number -- Number of objects in pool.
function Recycler:generatePool(PoolName: string, Object: any, Amount: number)

    -- Instantiate table for the pool.
    local Pool = {}

    -- Assign table to named pool.
    self.Pool[PoolName] = Pool

    -- Populate pool with objects.
    for i = 1, Amount do table.insert(Pool,Object:Clone()) end

    Debug:print("Generated Pool: "..PoolName.." with "..Amount.." objects!",{Prefix = "🏊"})
end

--- Get custom object from pool.
--- @param PoolName string -- Name of pool.
function Recycler:getFromPool(PoolName: string)

    -- Make sure the pool exists.
    local Pool = self.Pool[PoolName]
    if not Pool then Debug:warn("No pool named: "..PoolName) return end

    -- Get object at top of pool.
    local Object = self.Pool[PoolName][1]

    -- Pop the stack.
    table.remove(Pool,1)

    -- Push object back to top of stack.
    table.insert(Pool,#Pool,Object)

    -- Return object
    return Object
end

--- Return all objects in pool.
function Recycler:getObjectsInPool(PoolName: string)

    return self.Pool[PoolName]
end

--- Syntax sugar for just parenting object to nil.
function Recycler:recycle(Instance: Instance)

    Instance.Parent = nil
end

return Recycler