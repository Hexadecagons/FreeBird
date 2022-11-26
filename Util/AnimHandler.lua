--[=[

    @class AnimHandler
    Author: Hex (@hexadecagons)

    Class for handling groups of animations conveniently.

]=]

-- DEPENDENCIES
local Maid                  = _G:require("Maid")
local Debug                 = _G:require("Debug")

-- MODULE
local AnimHandler = {}
AnimHandler.__index = AnimHandler

--- Constructs a new AnimHandler.
--- @param BaseController AnimationController | Humanoid -- The base AnimationController/Humanoid to extend.
function AnimHandler.new(BaseController: AnimationController | Humanoid)

    local self = setmetatable({},AnimHandler)

    self.BaseController                 = BaseController                    -- The base controller we'll be extending.
    self.Animations                     = {}                                -- Table containing all animations.
    self.Maid                           = Maid.new()                        -- Maid used to clean animations up on deconstruction.

    return self
end

--- Load a given animation into the controller.
function AnimHandler:loadAnimation(Animation: Animation)

    -- Warn about overwrite.
    if self.Animations[Animation.Name] then Debug:warn("Animation of same name already loaded, overwriting. | "..Animation.Name) end

    -- Load the actual animation and add to table.
    local LoadedAnimation = self.BaseController:LoadAnimation(Animation)
    self.Animations[Animation.Name] = LoadedAnimation

    -- Make sure that the maid will clean up the animation later on.
    self.Maid:giveTask(function()

        -- Stop the animation just in case it's playing before we destroy it.
        if LoadedAnimation.isPlaying then LoadedAnimation:Stop() end

        LoadedAnimation:Destroy()
    end)
end

--- Loads all animations present in folder into the controller.
function AnimHandler:loadFolder(Folder: Folder)

    for _,Child in pairs(Folder:GetDescendants()) do

        if Child:IsA("Animation") then

            self:loadAnimation(Child)
        end
    end
end

-- Get a given animation.
-- Extra parameters can be passed to manipulate the animation for convenience.
--[[
    Parameters:
        number Speed : Speed applied to animation by :AdjustSpeed()
        number Duration : Alternative to Speed, adjusts speed so that the animation lasts the given duration
        number TimePosition : The position in time to start the animation at.
        number PercentPosition : Alternative to TimePosition, sets the TimePosition as a percent of the animation's length between 0 and 1.
        boolean Looped : If the animation is looped or not.
        AnimationPriority Priority : The priority of the animation.
--]]
function AnimHandler:getAnimation(Name: string, Parameters: table)

    -- Default if no parameters given.
    if not Parameters then Parameters = {} end

    -- Attempt to locate the animation.
    local Animation = self.Animations[Name]

    -- Animation doesn't exist.
    if not Animation then Debug:warn("Animation not found: "..Name) return end

    -- Apply Speed parameter.
    if Parameters.Speed then

        Animation:AdjustSpeed(Parameters.Speed)
    end

    -- Apply Duration parameter.
    if Parameters.Duration then

        Animation:AdjustSpeed(Animation.Length / Parameters.Duration)
    end

    -- Apply looped.
    if Parameters.Looped == true or Parameters.Looped == false then

        Animation.Looped = Parameters.Looped
    end

    -- Apply parameters we can easily write to.
    Animation.TimePosition              = Parameters.TimePosition or Animation.TimePosition
    Animation.Priority                  = Parameters.Priority or Animation.Priority

    -- Return the animation for further manipulation.
    return Animation
end

-- Syntax sugar for quickly playing animations, goes through :get()
function AnimHandler:playAnimation(Name: string, Parameters: table)

    local Anim = self:getAnimation(Name,Parameters)

    -- Make sure the animation exists before attempting to play.
    if Anim then Anim:Play() end

    -- Return the animation anyway for convenience.
    return Anim
end

-- Get all animations.
function AnimHandler:getAllAnimations()

    return self.Animations
end

--- Stop all currently playing animations.
function AnimHandler:stopAnimations()

    for _,Animation in pairs(self.Animations) do

        if Animation.IsPlaying then

            Animation:Stop()
        end
    end
end

--- Deconstructor.
function AnimHandler:Destroy()

    -- Let the maid just clean everything up.
    self.Maid:cleanup()
end

return AnimHandler