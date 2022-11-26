--[=[

	@class Debug
	Author: Hex (@hexadecagons)

	Utility module for fancier debugging.

	``DebugConfig.lua`` contains the default prefixes used for Print/Warn/Error messages.

	``ExtraArguments`` passed to [Debug:print],[Debug:warn] and [Debug:error] can be:

	| Parameter | Description |
	| ----------- | ----------- |
	| ``string``Prefix | Custom prefix override. |

]=]

-- REFERENCES
local RunService            = game:GetService("RunService")
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local Assets                = ReplicatedStorage:WaitForChild("Assets")

-- DEPENDENCIES
local Enum                  = _G:require("Enum")
local DebugConfig           = _G:require("DebugConfig")

-- VARIABLES
local DebugPart             -- Part for containing attachments used for debugging.
local DebugObjects          = {} -- Table keeping track of spatial debug objects.

-- MODULE
local Debug = {}

--[=[

    @prop Enabled boolean

    @within Debug

    If the debug mode is enabled or not.

    @readonly

]=]
Debug.Enabled = true

--- Equivalent function to print()
function Debug:print(Message: string, ExtraArguments: table)

	self:output(Message,Enum.OutputType.Print,ExtraArguments)
end

--- Equivalent function to warn()
function Debug:warn(Message: string, ExtraArguments: table)

	self:output(Message,Enum.OutputType.Warn,ExtraArguments)
end

--- Equivalent function to error()
function Debug:error(Message: string, ExtraArguments: table)

	self:output(Message,Enum.OutputType.Error,ExtraArguments)
end

--- Set debug mode enabled / disabled.
function Debug:setEnabled(Enabled: boolean)

    self.Enabled = Enabled

    -- Hide/Restore objects.
    if Enabled then

        self:toggleDebugObjects(true)
    else

        self:toggleDebugObjects(false)
    end
end

--[=[

    @param Key -- 'Key' the value is paired to, displayed on HUD.
    @param Object -- Object the element is attached to.
    @param ValueFunction -- Function expected to return the value, called each step.

    Draw a spatial HUD element keeping track of a changing value.

    #### ExtraParameters supported:

    | Parameter | Description |
    | ----------- | ----------- |
    | ``Color3``KeyColor | Color of the text displaying the key. |
    | ``Color3``ValueColor | Color of the text displaying the value. |
    | ``string``Icon | Icon displayed next to the HUD element. |
    | ``Vector3`` Offset | Offset applied to the container for the element. |

]=]
function Debug:drawValue(Key: string, Object: Instance, ValueFunction: Function, ExtraParameters: table)

    -- Make sure UI assets exist.
    if not Assets:FindFirstChild("UI") then self:warn("No Assets/UI path found in the current place.") end

    -- Make sure the specific UI elements exist.
    local ContainerTemplate    = Assets.UI:FindFirstChild("DebugStatContainer")
    local CardTemplate         = Assets.UI:FindFirstChild("DebugStatCard")
    if not ContainerTemplate or not CardTemplate then self:warn("Debug UI is missing in the current place. Make sure DebugStatContainer and DebugStatCard are present.") end

    if ExtraParameters.ValueOnly then

        CardTemplate = Assets.UI:FindFirstChild("DebugStatValueOnlyCard")
    end

    -- Locate existing container or create one!
    local Container = Object:FindFirstChild("DebugStatContainer")
    if not Container then

        -- Create container by cloning template.
        Container = ContainerTemplate:Clone()

        -- Set adornee and parent to the object.
        Container.Adornee = Object
        Container.Parent = Object

        -- Scale from ExtraParameter if given.
        if ExtraParameters and ExtraParameters.Scale then

            Container.Size = UDim2.new(Container.Size.X.Scale*ExtraParameters.Scale,0,Container.Size.Y.Scale*ExtraParameters.Scale,0)
        end

        -- Register the container as a DebugObject.
        table.insert(DebugObjects,Container)

        -- Hide the container if debug is currently disabled.
        if not Debug.Enabled then Container.Enabled = false end
    end

    -- Create the card for our current pairing.
    local Card = CardTemplate:Clone()

    -- Display key.
    if Card:FindFirstChild("Key") then Card.Key.Text = Key end

    -- Create connection to display value.
    local Connection = RunService.Heartbeat:Connect(function()

        -- Don't do anything if debug is disabled.
        if not Debug.Enabled then return end

        Card.Frame.Value.Text = tostring(ValueFunction())
    end)

    -- Display ExtraParameters.
    if ExtraParameters and not ExtraParameters.ValueOnly then

        -- Display key and value text colors.
        Card.Key.TextColor3           = ExtraParameters.KeyColor      or DebugConfig.DEFAULT_KEY_COLOR
        Card.Frame.Value.TextColor3   = ExtraParameters.ValueColor    or DebugConfig.DEFAULT_VALUE_COLOR

        -- Display icon.
        Card.Icon.Image               = ExtraParameters.Icon          or DebugConfig.DEFAULT_KEY_ICON

        -- Apply offset.
        Container.StudsOffsetWorldSpace = ExtraParameters.Offset or Container.StudsOffsetWorldSpace
    end

    -- Parent to the frame inside the container.
    Card.Parent = Container.Frame

    -- Create a light 'class' with a Destroy method to allow the element to be cleaned up.
    local Class = {
        Destroy = function()

            -- Destroy card and disconnect connection.
            Card:Destroy()
            Connection:Disconnect()

            -- Clean up container if it's empty.
            -- Excludes the UIListLayout.
            if #Container.Frame:GetChildren() <= 1 then Container:Destroy() end
        end
    }

    -- Return the class for further manipulation.
    return Class
end

--- Draw a circle to visualize a given radius.
--- @param Origin Vector3 -- Position at which the circle originates at.
--- @param Radius number -- The radius to scale the circle to.
--- @param Color Color3 -- Color of the circle
function Debug:drawRadius(Origin: Vector3, Radius: number, Color: Color3)

    -- Create part representing circle.
    local RadiusPart = Instance.new("Part")
    RadiusPart.Shape = Enum.PartType.Cylinder
    RadiusPart.Anchored = true
    RadiusPart.CanCollide = false
    RadiusPart.Transparency = 0.5

    -- Position at origin and scale.
    RadiusPart.CFrame = CFrame.new(Origin)*CFrame.Angles(0,0,math.rad(90))
    RadiusPart.Size = Vector3.new(0,Radius*2,Radius*2)

    -- Create decal displaying stripes for aesthetics.
    local StripeTexture = Instance.new("Texture")
    StripeTexture.Texture = "http://www.roblox.com/asset/?id=255552105"
    StripeTexture.Parent = RadiusPart
    StripeTexture.Face = Enum.NormalId.Right

    -- Change to desired color.
    RadiusPart.Color = Color

    -- Finally, parent to workspace.
    RadiusPart.Parent = workspace

    -- Register the object so that it can be destroyed later.
    DebugObjects[RadiusPart] = RadiusPart

    -- Return part for further manipulation.
    return RadiusPart
end

--- Draw a beam between two points.
--- @param From Vector3 -- Point to draw from.
--- @param To Vector3 -- Point to draw to.
--- @param Color Color3 -- Color to apply to the ray.
function Debug:drawBeam(From: Vector3, To: Vector3, Color: Color3)

    -- Create attachments for both points.
    local Attachment0 = Instance.new("Attachment")
    Attachment0.Parent = DebugPart
    Attachment0.WorldPosition = From
    local Attachment1 = Instance.new("Attachment")
    Attachment1.Parent = DebugPart
    Attachment1.WorldPosition = To

    -- Create beam between both attachments.
    local Beam = Instance.new("Beam")
    Beam.Parent = DebugPart
    Beam.Attachment0 = Attachment0
    Beam.Attachment1 = Attachment1

    -- Make the beam face camera.
    Beam.FaceCamera = true

    -- Apply color.
    Beam.Color = ColorSequence.new(Color,Color) or ColorSequence(Color3.new(255,255,255),Color3.new(255,255,255))

    -- Register objects so that they can be destroyed later.
    DebugObjects[Beam] = Beam
    DebugObjects[Attachment0] = Attachment0
    DebugObjects[Attachment1] = Attachment1

    -- Return beam for further manipulation.
    return Beam
end

--- Toggle visibility/state of debug objects.
function Debug:toggleDebugObjects(Enabled: boolean)

    for _,Object in pairs(DebugObjects) do

        -- Handle BillboardGui objects.
        if Object:IsA("BillboardGui") then

            Object.Enabled = Enabled

        -- Handle BasePart objects.
        elseif Object:IsA("BasePart") then

            Object:Destroy()
        end
    end
end

--- Clear all of the currently active debug objects.
function Debug:clearDrawings()

    for _,Object in pairs(DebugObjects) do

        Object:Destroy()
    end
end

--- @private
--- Internal output function.
function Debug:output(Message: string, Type: string, ExtraArguments: table)

	-- Get the message given to output, default to "UNDEFINED" if nothing given.
	Message = Message or "UNDEFINED"

	-- Define ExtraArguments as an empty table if none given to prevent errors.
	ExtraArguments = ExtraArguments or {}

	-- Get the name of the script calling our function.
	local CallerName = getfenv(3).script.Name

	-- Determine the function to call and prefix to apply before message.
	-- Defaults to print.
	local Prefix        = DebugConfig.PREFIXES.Print
	local FuncToCall    = print
	if Type == Enum.OutputType.Warn then

		Prefix = DebugConfig.PREFIXES.Warn
		FuncToCall = warn
	elseif Type == Enum.OutputType.Error then

		Prefix = DebugConfig.PREFIXES.Error
		FuncToCall = error
	end

	-- Apply custom prefix override if given.
	if ExtraArguments.Prefix then

		Prefix = ExtraArguments.Prefix
	end

	-- Finally, call the function to write to output.
	FuncToCall(string.format("%s %s : %s",Prefix,CallerName,Message))

	-- Traceback to line:
	if Type == Enum.OutputType.Warn or Type == Enum.OutputType.Error then

		FuncToCall(Prefix.." "..CallerName..".lua, Line "..debug.info(3,"l"))
	end
end

function Debug:__init()

    DebugPart = Instance.new("Part")
    DebugPart.Parent = workspace
end

return Debug