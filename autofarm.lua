local function h(mod, metadata)
    return {
        mod = mod,
        height = metadata
    }
end

local function r(mod, crop, seed)
    return {
        mod = mod,
        crop = crop,
        seed = seed,
    }
end

local function f(mod, item, fuel)
    return {
        mod = mod,
        item = item,
        fuel = fuel
    }
end

Harvest = {
    h("magicalcrops", 7)
}

Replace = {
    r("magicalcrops", "MinicioCrop", "MinicioSeeds"),
}

Fuel = {
    f("minecraft", "coal", 80),
    f("minecraft", "lava_bucket", 1000)
}

RefillChest = {
    mod = "EnderStorage",
    item = "enderChest"
}

Turn = {
    right = "minecraft:stone_slab",
    left = "minecraft:wooden_slab",
    reset = "minecraft:stone"
}

Movement = {
    x = 0,
    z = 0
}

VelocityX = 1

Resetting = false

local function splitName(fullname)
    local s, e = string.find(fullname, ":")
    return string.sub(fullname, 1, s-1), string.sub(fullname, s+1)
end

local function findItem(mod, name)
    local slot = turtle.getSelectedSlot()

    for i = 1, 16, 1 do
        turtle.select(i)
        local data = turtle.getItemDetail()
        if data then
            local rmod, rname = splitName(data.name)
            if rmod == mod and rname == name then
                return true
            end
        end
    end

    turtle.select(slot)
    return false
end

local function harvest(mod, crop)
    for _, rep in pairs(Replace) do
        if rep.mod == mod and rep.crop == crop then
            turtle.digDown()
            if findItem(mod, rep.seed) then
                turtle.placeDown()
                return true
            end
            break
        end
    end

    return false
end

local function farm()
    local data = turtle.inspectDown()
    if not data then return false end

    local name = data.name
    local growth = data.metadata

    local mod, cropname = splitName(name)

    for _, crop in pairs(Harvest) do
        if crop.mod == mod and crop.height == growth then
            return harvest(mod, cropname)
        end
    end

    return false
end

local function refuel()
    local max = turtle.getFuelLimit()
    local current = turtle.getFuelLevel()

    for _, f in pairs(Fuel) do
        local newfuel = current + f.fuel
        if newfuel <= max and findItem(f.mod, f.item) then
            return turtle.refuel()
        end
    end

    return false
end

local function replenishLava()
    local function holdingLavaBucket()
        local data = turtle.getItemDetail()
        if data then
            return data.name == "minecraft:lava_bucket"
        end
        return false
    end

    if findItem("minecraft", "bucket") then
        local bucket = turtle.getSelectedSlot()
        if findItem(RefillChest.mod, RefillChest.item) then
            local chest = turtle.getSelectedSlot()
            turtle.placeUp()

            turtle.select(bucket)
            while not holdingLavaBucket() do
                turtle.dropUp()
                sleep(1)
                turtle.suckDown()
            end

            turtle.select(chest)
            turtle.digUp()
        end
    end
end

function step()
    turtle.forward()
    Movement.x = Movement.x + VelocityX
    local data = turtle.inspectDown()
    if not data then return false end

    if data.name == Turn.left then
        turtle.turnLeft()
        turtle.forward()
        turtle.turnLeft()
        turtle.forward()
        Movement.z = Movement.z + 1
    elseif data.name == Turn.right then
        turtle.turnRight()
        turtle.forward()
        turtle.turnRight()
        turtle.forward()
        Movement.z = Movement.z + 1
    elseif data.name == Turn.reset then
        turtle.turnLeft()
        turtle.turnLeft()
        Resetting = true
        VelocityX = -VelocityX
    end
end

function resetStep()
    if Movement.x > 0 then
        turtle.forward()
        Movement.x = Movement.x - 1
        if Movement.x == 0 then
            if VelocityX == 1 then
                turtle.turnLeft()
            else
                turtle.turnRight()
            end
        end
    elseif Movement.z > 0 then
        turtle.forward()
        Movement.z = Movement.z - 1
        if Movement.z == 0 then
            if VelocityX == 1 then
                turtle.turnLeft()
            else
                turtle.turnRight()
            end
            Resetting = false
        end
    end
end

function loop()
    while true do
        if not Resetting then
            farm()
        end
        refuel()
        replenishLava()

        if Resetting then
            resetStep()
        else
            step()
        end
    end
end